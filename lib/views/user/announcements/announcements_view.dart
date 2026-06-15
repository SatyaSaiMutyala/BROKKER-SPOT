import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/announcements/announcement_card_skeleton.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  final _controller = AnnouncementListController.to;
  final _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer until after the first frame so loadAll()'s synchronous cache
    // read (which mutates allAnnouncements before its first await) can't
    // trigger an Obx rebuild while the framework is still building widgets
    // up the tree — the post-login transition was hitting that exact race.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.loadAll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Pre-fetch the next page when we're within 300dp of the end so the new
    // cards are usually ready by the time the user reaches the bottom.
    if (pos.pixels >= pos.maxScrollExtent - 300 && _controller.hasMoreAll) {
      _controller.loadMoreAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'ANNOUNCEMENTS',
              leading: GestureDetector(
                onTap: () {},
                child:
                    Icon(Icons.search, size: 36.sp, color: AppColors.primary),
              ),
              trailing: GestureDetector(
                onTap: () => Get.to(() => const CreateAnnouncementView()),
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),
            Expanded(
              child: Obx(() {
                // Full-screen spinner only on the very first load (nothing cached yet).
                // During pull-to-refresh the list stays visible with its own indicator.
                if (_controller.isLoadingAll.value &&
                    _controller.allAnnouncements.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _controller.loadAll(force: true),
                  child: _buildList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    // Error state — still scrollable so pull-to-refresh works.
    if (_controller.allError.value != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.allError.value!,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => _controller.loadAll(force: true),
                  child: Text('Retry',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // Empty state — scrollable so the user can still pull to refresh.
    if (_controller.allAnnouncements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Text(
              'No announcements yet',
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }
    final loadingMore = _controller.isLoadingMoreAll.value;
    final length = _controller.allAnnouncements.length;
    return NotificationListener<ScrollNotification>(
      // The video-player gate stays shut during scroll and opens INSTANTLY on
      // ScrollEndNotification — no debounce wait, the card starts loading
      // the moment your finger lifts.
      onNotification: (n) {
        CachedVideoPlayer.notifyScroll(n);
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        // 400 dp = roughly one extra card in cache. Was 1200dp which kept
        // ~3 heavy cards (with their PageViews, image carousels, and
        // potentially video controllers) mounted off-screen and was a major
        // OOM contributor on low-RAM devices.
        // ignore: deprecated_member_use
        cacheExtent: 400,
        // +1 row when the next page is fetching → renders the skeleton.
        itemCount: length + (loadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index >= length) {
          return const AnnouncementCardSkeleton();
        }
        final a = _controller.allAnnouncements[index];
        // RepaintBoundary stops one card's video / image fades from forcing
        // sibling cards to repaint on every frame during scroll.
        return RepaintBoundary(
          child: AnnouncementPropertyCard(
            announcement: a,
            index: index,
            onTap: () async {
              await Get.to(() => AnnouncementDetailView(
                    announcement: a,
                    isOwner: false,
                  ));
            },
            onWishlistTap: () {},
            onLocationTap: () {},
            onChatTap: () => AnnouncementChatView.open(
              announcementId: a.id ?? '',
              brokerName: a.ownerName ?? 'Owner',
              brokerAvatar: a.ownerAvatarUrl,
              peerUserId: a.userId,
            ),
          ),
        );
        },
      ),
    );
  }
}
