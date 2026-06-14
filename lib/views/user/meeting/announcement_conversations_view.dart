import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/conversation_model.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/meeting/controller/announcement_conversations_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/meeting/conversation_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Middle screen between the Meeting list and 1:1 chat.
///
/// Shows the people who've messaged about a specific announcement (driven by
/// the `chat:announcement:conversations` socket event). Tapping a row opens
/// the existing [AnnouncementChatView] for that peer.
class AnnouncementConversationsView extends StatefulWidget {
  final MeetingItem meeting;
  const AnnouncementConversationsView({super.key, required this.meeting});

  @override
  State<AnnouncementConversationsView> createState() =>
      _AnnouncementConversationsViewState();
}

class _AnnouncementConversationsViewState
    extends State<AnnouncementConversationsView> {
  late final AnnouncementConversationsController _ctrl;
  late final String _tag;
  Worker? _precacheWorker;

  @override
  void initState() {
    super.initState();
    _tag = widget.meeting.announcementId;
    // Force-delete any stale controller with this tag. After logout/login the
    // old controller's socket listeners point to the disposed socket. GetX may
    // return the stale instance via Get.put() instead of creating a fresh one,
    // causing conversations to never load (onInit() doesn't re-run).
    if (Get.isRegistered<AnnouncementConversationsController>(tag: _tag)) {
      Get.delete<AnnouncementConversationsController>(tag: _tag, force: true);
    }
    _ctrl = Get.put(
      AnnouncementConversationsController(
        announcementId: widget.meeting.announcementId,
        // Pass the profiles the meetings API already gave us; the controller
        // uses them to enrich the socket payload so all internal lookups
        // match correctly (prevents the duplicate-row flash after sending
        // a message).
        knownProfiles: widget.meeting.chatProfiles,
      ),
      tag: _tag,
    );
    // Warm avatars we already know about (from the meetings response) right
    // away — by the time the socket replies the images are ready to paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAvatars(
          widget.meeting.chatProfiles.map((p) => p.profileImageUrl));
    });
    // And any new ones the socket surfaces (e.g. a brand-new conversation
    // arriving live).
    _precacheWorker = ever(_ctrl.conversations, (_) {
      _precacheAvatars(_ctrl.conversations.map((c) => c.user.profileImageUrl));
    });
  }

  @override
  void dispose() {
    _precacheWorker?.dispose();
    Get.delete<AnnouncementConversationsController>(tag: _tag);
    super.dispose();
  }

  void _precacheAvatars(Iterable<String?> urls) {
    if (!mounted) return;
    for (final u in urls) {
      if (u == null || u.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(u), context).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Announcement',
              showBackButton: true,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.conversations.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (_ctrl.error.value != null && _ctrl.conversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  _ctrl.error.value!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: _ctrl.reload,
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
      if (_ctrl.conversations.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _ctrl.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 200.h),
              Center(
                child: Text(
                  'No conversations yet',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _ctrl.reload,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _ctrl.conversations.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (_, i) {
            // Controller already enriches with known chat_profiles at
            // ingest, so what's in _ctrl.conversations is render-ready.
            final c = _ctrl.conversations[i];
            return ConversationTile(
              conversation: c,
              onTap: () => _openChat(c),
            );
          },
        ),
      );
    });
  }

  Future<void> _openChat(ConversationItem c) async {
    final peer = c.user;
    final peerId = peer.id ?? '';
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ?? '';

    debugPrint('💬 [Conversations] _openChat ann=${widget.meeting.announcementId}');
    debugPrint('💬 [Conversations]   myId=$myId  peerId=$peerId  peerName=${peer.name}');
    debugPrint('💬 [Conversations]   ann.userId=${widget.meeting.announcement.userId}');

    if (peerId.isEmpty) {
      debugPrint('💬 [Conversations]   ✗ peerId empty, aborting');
      return;
    }
    if (myId.isNotEmpty && peerId == myId) {
      debugPrint('💬 [Conversations]   ✗ self-chat detected: peer==me=$myId');
      // This means chat:announcement:conversations returned our own profile —
      // we are NOT the announcement owner. The owner path should have been
      // taken instead; this is a routing bug upstream.
      return;
    }
    // Use the user_role stored on the last_message if the server gave us one
    // — that's the exact value chat:history needs for a first-attempt hit.
    // Fall back to computing from the announcement role.
    final isOwner = myId.isNotEmpty && widget.meeting.announcement.userId == myId;
    final annRole = widget.meeting.announcement.userRole ?? 2;
    final computedRole = isOwner ? annRole : (3 - annRole);
    final chatUserRole = c.lastMessageUserRole ?? computedRole;
    debugPrint('💬 [Conversations]   chatUserRole=$chatUserRole (lmRole=${c.lastMessageUserRole} computed=$computedRole)');
    // Clear the unread badge immediately for snappy UX.
    _ctrl.markRead(peerId);
    await AnnouncementChatView.open(
      announcementId: widget.meeting.announcementId,
      brokerName: peer.name ?? 'User',
      brokerAvatar: peer.profileImageUrl,
      peerUserId: peerId,
      userRole: chatUserRole,
    );
    if (!mounted) return;
    // Tiny delay so the server has time to persist the just-sent message
    // before we re-fetch — without this the response can race in with the
    // pre-message order, leaving the just-chatted row in its old position.
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _ctrl.reload();
  }

}
