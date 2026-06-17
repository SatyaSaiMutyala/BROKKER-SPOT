import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/services/presence_service.dart';
import 'package:brokkerspot/models/chat_message.dart';
import 'package:brokkerspot/views/user/announcements/chat/chat_controller.dart';
import 'package:brokkerspot/views/user/announcements/publish_announcement_view.dart';

class AnnouncementChatView extends StatefulWidget {
  final String announcementId;
  final String brokerName;
  final String brokerAvatar;

  /// The other user's id — used to show their online/offline status.
  final String? peerUserId;

  /// Chat-context role for the socket user: 1=user/owner side, 2=broker side.
  /// Passed to ChatController and included in socket events so the server's
  /// directional history lookup works when the announcement owner is the one
  /// opening chat (e.g. user replies to a broker who initiated).
  final int? userRole;

  const AnnouncementChatView({
    super.key,
    required this.announcementId,
    required this.brokerName,
    required this.brokerAvatar,
    this.peerUserId,
    this.userRole,
  });

  /// Reusable entry point — call this from anywhere chat is opened.
  static Future<void> open({
    required String announcementId,
    required String brokerName,
    String? brokerAvatar,
    String? peerUserId,
    int? userRole,
  }) async {
    // Empty (not just null) avatar strings would crash Image.asset(''), so
    // normalize to the fallback asset here.
    final avatar = (brokerAvatar != null && brokerAvatar.trim().isNotEmpty)
        ? brokerAvatar
        : 'assets/images/story1.png';
    // Wrap the navigation: on some devices (seen on Samsung) a synchronous
    // throw during route push (theme/MediaQuery edge cases) would otherwise
    // tear the app down. Show a toast instead.
    try {
      // No `!` — Get.to can return null; that must never crash the tap.
      await Get.to(() => AnnouncementChatView(
            announcementId: announcementId,
            brokerName: brokerName.isNotEmpty ? brokerName : 'Chat',
            brokerAvatar: avatar,
            peerUserId: peerUserId,
            userRole: userRole,
          ));
    } catch (e) {
      Get.snackbar('Chat', "Couldn't open chat. Please try again.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  State<AnnouncementChatView> createState() => _AnnouncementChatViewState();
}

class _AnnouncementChatViewState extends State<AnnouncementChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatController _chat;
  late final String _tag;
  // Saved so we can dispose them — leaked Workers fire on disposed State on
  // some devices (Samsung in particular) and crash with "setState on disposed".
  Worker? _msgsWorker;
  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();
    final recipientId = widget.peerUserId ?? '';
    // One controller per conversation (announcement + peer), so chats don't clash.
    _tag = '${widget.announcementId}:$recipientId';
    // Force-delete any stale controller with this tag. After a logout/login the
    // old controller's socket listeners point to the disposed socket — if GetX
    // returns it via Get.put() instead of creating a fresh one, onInit() never
    // re-runs so no listeners are registered on the new connection and every
    // history request times out silently.
    if (Get.isRegistered<ChatController>(tag: _tag)) {
      Get.delete<ChatController>(tag: _tag, force: true);
    }
    _chat = Get.put(
      ChatController(
        announcementId: widget.announcementId,
        recipientId: recipientId,
        peerName: widget.brokerName,
        peerAvatar: widget.brokerAvatar,
        userRole: widget.userRole,
      ),
      tag: _tag,
    );
    // Watch the other user's online/offline presence.
    if (recipientId.isNotEmpty) {
      PresenceService.to.watch(recipientId);
    }
    // Auto-scroll to the newest message whenever the list grows.
    _msgsWorker = ever(_chat.messages, (_) {
      if (!mounted) return;
      _scrollToBottom();
    });
    // Surface send/history errors.
    _errorWorker = ever(_chat.error, (msg) {
      if (msg.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
        );
      }
    });
    // Load older messages when scrolled to the top.
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Guard against the listener firing before/after the controller is attached
    // to a scrollable — accessing .position without this throws on some devices.
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 40 && _chat.hasMore) {
      _chat.loadMore();
    }
  }

  @override
  void dispose() {
    _msgsWorker?.dispose();
    _errorWorker?.dispose();
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    Get.delete<ChatController>(tag: _tag);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _chat.sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.teal,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.teal,
        body: Column(
          children: [
            SizedBox(height: topPadding),
            _buildHeader(),
            Obx(() => _buildProposalBanner()),
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Obx(() {
                  final msgs = _chat.messages;
                  if (_chat.isLoadingHistory.value && msgs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (msgs.isEmpty && _chat.error.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Couldn't load message history.\nYou can still send a new message below.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 13.sp, color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 12.h),
                            TextButton.icon(
                              onPressed: _chat.reloadHistory,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text('Retry',
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hello 👋',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: Colors.grey.shade500),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: m.isMine
                            ? _sentBubble(m.text, _time(m))
                            : _receivedBubble(m.text, _time(m)),
                      );
                    },
                  );
                }),
              ),
            ),
            _buildInputBar(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ── Proposal banner ──
  Widget _buildProposalBanner() {
    final status = _chat.proposalStatus.value;
    if (status == null) return const SizedBox.shrink();

    final isOwner = (widget.userRole ?? 1) == 1;

    String text;
    Widget? button;

    if (isOwner) {
      switch (status) {
        case 0:
          text = 'Authorize a broker to advertise your property.';
          button = _bannerButton(
            icon: Icons.article_outlined,
            label: 'View Contract',
            onTap: () => _showTermsDialog(onAccept: _chat.approveProposal),
            filled: false,
          );
        case 1:
          text = 'Signed by you. Awaiting broker signature.';
          button = _bannerButton(
            icon: Icons.check_circle_outline,
            label: 'Awaiting',
            onTap: null,
            color: AppColors.primary,
            filled: true,
          );
        case 2:
          text = 'You declined this proposal.';
          button = null;
        case 3:
          text = 'Contract signed. The broker can now advertise your property.';
          button = _bannerButton(
            icon: Icons.article_outlined,
            label: 'Information',
            onTap: _openAgreement,
            color: Colors.green.shade700,
            filled: true,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (status) {
        case 0:
          text = 'Awaiting owner approval of your proposal.';
          button = null;
        case 1:
          text = 'Owner approved your proposal. Sign to confirm.';
          button = _bannerButton(
            icon: Icons.draw_outlined,
            label: 'Sign & Accept',
            onTap: () => _showTermsDialog(
              onAccept: _chat.brokerAcceptProposal,
              bodyText: 'By signing this contract, you agree to advertise this '
                  'property on BrokerSpot under the terms set by the owner. '
                  'You confirm that you are a verified broker authorized to '
                  'act on this proposal.\n\n'
                  'You agree to negotiate with potential buyers and tenants '
                  'in good faith and within the parameters agreed upon with '
                  'the owner. BrokerSpot acts solely as an intermediary '
                  'platform and is not a party to any agreement between you '
                  'and the owner.\n\n'
                  'This authorization remains valid until either party '
                  'withdraws it or the listing period expires.\n\n'
                  'BrokerSpot reserves the right to remove listings that '
                  'violate platform policies. Both parties are responsible '
                  'for compliance with applicable real estate laws and '
                  'regulations.',
            ),
            color: Colors.green.shade700,
            filled: true,
          );
        case 2:
          text = 'Owner declined this proposal.';
          button = null;
        case 3:
          text = 'Contract signed. You can now advertise this property.';
          button = _bannerButton(
            icon: Icons.campaign_outlined,
            label: 'Publish',
            onTap: () => Get.to(() => PublishAnnouncementView(
                  announcementId: widget.announcementId,
                )),
            color: Colors.green.shade700,
            filled: true,
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return Container(
      width: double.infinity,
      color: AppColors.backgroundDark,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.white),
            ),
          ),
          if (button != null) ...[SizedBox(width: 12.w), button],
        ],
      ),
    );
  }

  Widget _bannerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.white,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: Border.all(color: filled ? color : Colors.white70),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog({required VoidCallback onAccept, String? bodyText}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Image.asset('assets/images/appLogo.png',
                    height: 44.h,
                    errorBuilder: (_, __, ___) => Text('brokker',
                        style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold))),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'BrokerSpot Terms & conditions.',
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    bodyText ??
                        'By authorizing a broker to advertise your property on BrokerSpot, '
                            'you agree that the broker may list and promote your property to '
                            'potential buyers and tenants through the platform. You confirm that '
                            'you are the authorized owner or representative of the property and '
                            'that all information provided is accurate.\n\n'
                            'The broker is authorized to negotiate on your behalf within the '
                            'parameters you have agreed upon. BrokerSpot acts solely as an '
                            'intermediary platform and is not a party to any agreement between '
                            'you and the broker.\n\n'
                            'This authorization remains valid until you withdraw it or the '
                            'listing period expires. You may revoke this authorization at any '
                            'time by contacting BrokerSpot support or through the app settings.\n\n'
                            'BrokerSpot reserves the right to remove listings that violate '
                            'platform policies. Both parties are responsible for compliance '
                            'with applicable real estate laws and regulations.',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, color: Colors.white70, height: 1.6),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onAccept();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'I Accept',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: Colors.white54),
                    children: [
                      const TextSpan(
                          text:
                              'By clicking on I Accept button, you agree to brokkerspot '),
                      TextSpan(
                        text: 'Terms & conditions',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAgreement() async {
    final url = _chat.agreementUrl.value;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agreement document not available yet.')));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      color: AppColors.teal,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new,
                size: 20.sp, color: Colors.white),
          ),
          SizedBox(width: 20.w),
          ClipOval(child: _headerAvatar()),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.brokerName,
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                Obx(() {
                  final peerId = widget.peerUserId ?? '';
                  final String label;
                  if (_chat.peerTyping.value) {
                    label = 'typing…';
                  } else if (peerId.isNotEmpty) {
                    // Real presence of the other user.
                    label = PresenceService.to.isOnline(peerId)
                        ? 'Online'
                        : 'Offline';
                  } else {
                    // No peer id — fall back to our own socket state.
                    label =
                        _chat.isConnected.value ? 'Connected' : 'Connecting…';
                  }
                  return Text(
                    label,
                    style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.8)),
                  );
                }),
              ],
            ),
          ),
          Icon(Icons.videocam_outlined, color: Colors.white, size: 22.sp),
          SizedBox(width: 16.w),
          Icon(Icons.call_outlined, color: Colors.white, size: 22.sp),
          SizedBox(width: 16.w),
          Icon(Icons.more_vert, color: Colors.white, size: 22.sp),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() => Image.asset('assets/images/story1.png',
      width: 40.w, height: 40.w, fit: BoxFit.cover);

  Widget _headerAvatar() {
    final a = widget.brokerAvatar;
    if (a.trim().isEmpty) return _fallbackAvatar();
    if (a.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: a,
        width: 40.w,
        height: 40.w,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackAvatar(),
      );
    }
    // Local asset — guard with errorBuilder so a bad path can't crash the build.
    return Image.asset(
      a,
      width: 40.w,
      height: 40.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackAvatar(),
    );
  }

  // ── Input bar ──
  Widget _buildInputBar(double bottomPadding) {
    return Material(
      color: Colors.white,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h + bottomPadding),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(fontSize: 14.sp),
                textInputAction: TextInputAction.send,
                // Capitalize the first letter of each sentence (matches
                // WhatsApp-style behavior).
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _chat.notifyTyping(),
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Say Somthing...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp, color: AppColors.textHint),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide:
                        BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46.w,
                height: 46.w,
                decoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
                child:
                    Icon(Icons.send_rounded, color: Colors.white, size: 30.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(ChatMessage m) {
    final dt = m.createdAt;
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$mm $ampm';
  }

  Widget _receivedBubble(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 260.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message,
                style:
                    GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87)),
            if (time.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(time,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, color: Colors.grey.shade400)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sentBubble(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(minWidth: 90.w, maxWidth: 220.w),
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: Colors.black87)),
              if (time.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(time,
                      style: GoogleFonts.inter(
                          fontSize: 10.sp, color: Colors.grey.shade500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
