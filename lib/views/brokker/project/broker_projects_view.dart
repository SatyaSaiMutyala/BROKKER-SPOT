import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_card_skeleton.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:get/get.dart';

class BrokerProjectsView extends StatefulWidget {
  const BrokerProjectsView({super.key});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerShimmerList extends StatelessWidget {
  const _BrokerShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const _BrokerShimmerCard(),
      ),
    );
  }
}

class _BrokerShimmerCard extends StatelessWidget {
  const _BrokerShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner row
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100.w, height: 10.h, color: Colors.white),
                  SizedBox(height: 4.h),
                  Container(width: 60.w, height: 8.h, color: Colors.white),
                ],
              ),
              const Spacer(),
              Container(
                  width: 60.w,
                  height: 22.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  )),
            ],
          ),
          SizedBox(height: 8.h),
          // Image area
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 10.h),
          // Price row
          Container(width: 120.w, height: 14.h, color: Colors.white),
          SizedBox(height: 6.h),
          // Property name
          Container(width: 200.w, height: 12.h, color: Colors.white),
          SizedBox(height: 6.h),
          // Bedroom / sqft row
          Row(
            children: [
              Container(width: 50.w, height: 10.h, color: Colors.white),
              SizedBox(width: 12.w),
              Container(width: 50.w, height: 10.h, color: Colors.white),
            ],
          ),
          SizedBox(height: 6.h),
          Divider(color: Colors.grey.shade200, thickness: 1),
          SizedBox(height: 4.h),
          // Location row
          Container(width: 160.w, height: 10.h, color: Colors.white),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  final _controller = AnnouncementListController.to;
  final _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final _scrollController = ScrollController();

  int _selectedTab = 0;
  final _tabs = const ['User Announcement', 'My Announcement'];

  @override
  void initState() {
    super.initState();
    // Both tabs are cache-first; each is a no-op if already loaded.
    _controller.loadAll();
    _controller.loadBrokerMine();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Pagination only applies to the public-feed tab today (My Announcement
    // is not paginated server-side here).
    if (_selectedTab != 0) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && _controller.hasMoreAll) {
      _controller.loadMoreAll();
    }
  }

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    // Lazy-load "My Announcement" the first time it's opened.
    if (i == 1) _controller.loadBrokerMine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Projects',
              trailing: GestureDetector(
                // New announcements auto-refresh the cached list via the
                // controller's mutation hook, so just navigate.
                onTap: () => Get.to(
                    () => const CreateAnnouncementView(fromBroker: true)),
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),
            _buildTabBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      final isMine = _selectedTab == 1;

      // Each tab reads from its own slot. "User Announcement" keeps the
      // existing public feed; "My Announcement" hits /user/announcements/fetch
      // (backend filters by role → broker's own posts).
      final isLoading = isMine
          ? _controller.isLoadingBrokerMine.value
          : _controller.isLoadingAll.value;
      final error = isMine
          ? _controller.brokerMineError.value
          : _controller.allError.value;
      final myId = _profileCtrl.currentUserId;
      final announcements = isMine
          ? _controller.brokerMineAnnouncements.toList()
          : _controller.allAnnouncements
              .where((a) => a.userId != myId)
              .toList();

      Future<void> refresh() => isMine
          ? _controller.loadBrokerMine(force: true)
          : _controller.loadAll(force: true);

      // First-load shimmer only when nothing is cached yet.
      if (isLoading && announcements.isEmpty) {
        return _BrokerShimmerList();
      }
      if (error != null && announcements.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: refresh,
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }

      if (announcements.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: ListView(
            children: [
              SizedBox(height: 200.h),
              Center(
                child: Text(
                    isMine
                        ? 'You have no announcements yet'
                        : 'No announcements',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: Colors.grey.shade400)),
              ),
            ],
          ),
        );
      }

      // Only the User Announcement tab paginates; on My Announcement we
      // hide the loading-more skeleton since there's no next page to fetch.
      final showLoadingMore = !isMine && _controller.isLoadingMoreAll.value;
      // Lazy list: header at 0, then cards, then optional skeleton, then
      // banner. SingleChildScrollView built ALL cards up-front which was the
      // main cause of scroll jank on this heavy card.
      final headerIdx = 0;
      final cardStart = 1;
      final cardEnd = cardStart + announcements.length; // exclusive
      final skeletonIdx = showLoadingMore ? cardEnd : -1;
      final bannerIdx = cardEnd + (showLoadingMore ? 1 : 0);
      final itemCount = bannerIdx + 1;

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: refresh,
        child: NotificationListener<ScrollNotification>(
          // The video-player gate stays shut during scroll and opens
          // INSTANTLY on ScrollEndNotification — the visible card starts
          // loading the moment the scroll ends, no debounce wait.
          onNotification: (n) {
            CachedVideoPlayer.notifyScroll(n);
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // 400 dp = roughly one extra card in cache. Larger values
            // (we had 1200) kept multiple heavy cards mounted off-screen
            // which caused OOM on low-RAM devices.
            // ignore: deprecated_member_use
            cacheExtent: 400,
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i == headerIdx) {
                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: _buildSectionHeader(_tabs[_selectedTab],
                      '${announcements.length} announcements'),
                );
              }
              if (i >= cardStart && i < cardEnd) {
                final idx = i - cardStart;
                final a = announcements[idx];
                return RepaintBoundary(
                  child: AnnouncementPropertyCard(
                    announcement: a,
                    index: idx,
                    showWishlist: false,
                    showActionButtons: false,
                    ownerRowAboveImage: true,
                    onTap: () => Get.to(
                        () => BrokerAnnouncementDetailView(announcement: a)),
                  ),
                );
              }
              if (i == skeletonIdx) {
                return const AnnouncementCardSkeleton();
              }
              // Footer (banner + trailing spacer).
              return Padding(
                padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
                child: PremiumLockBanner(onTap: () {}),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(i),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                padding: EdgeInsets.symmetric(vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.primary, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black),
        ),
        SizedBox(width: 6.w),
        Container(
          width: 18.w,
          height: 18.w,
          decoration: const BoxDecoration(
              color: AppColors.goldAccent, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('!',
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const Spacer(),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 11.sp, color: Colors.grey.shade500)),
      ],
    );
  }
}
