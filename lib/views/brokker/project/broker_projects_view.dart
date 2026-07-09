import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/core/common_widget/cached_video_player.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_card_skeleton.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:get/get.dart';

/// Broker-side Announcements screen. Shares the exact visual language of the
/// user-side [AnnouncementsView] (dark full-bleed cards, header, filter bar)
/// via [HomeAnnouncementCard] and [AnnouncementFilterBar] — the only broker-
/// specific addition is the brokerage strip on each card, plus a tab
/// switcher between the public feed and the broker's own posts.
class BrokerProjectsView extends StatefulWidget {
  const BrokerProjectsView({super.key});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  final _controller = AnnouncementListController.to;
  final _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final _scrollController = ScrollController();

  int _selectedTab = 0;
  final _tabs = const ['User Announcement', 'My Announcement'];

  String? _selectedListingType; // null = all, 'Sell' = Buy, 'Rent' = Rent
  String? _selectedPropertyType; // null = all

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer so the sync cache-read inside loadAll/loadBrokerMine can't
    // mutate Rx state while an ancestor is still mid-build (setState-
    // during-build crash on post-login tab insert).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.loadAll();
      _controller.loadBrokerMine();
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

  List<AnnouncementModel> _filtered(List<AnnouncementModel> all) {
    var list = all;
    if (_selectedListingType != null) {
      list = list.where((a) => a.listingType == _selectedListingType).toList();
    }
    if (_selectedPropertyType != null) {
      list = list
          .where((a) =>
              a.propertyType?.toLowerCase() ==
              _selectedPropertyType!.toLowerCase())
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F5F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 12.h),
            _buildTabBar(theme),
            SizedBox(height: 12.h),
            AnnouncementFilterBar(
              selectedListingType: _selectedListingType,
              selectedPropertyType: _selectedPropertyType,
              onListingTap: () => setState(() {
                if (_selectedListingType == null) {
                  _selectedListingType = 'Sell';
                } else if (_selectedListingType == 'Sell') {
                  _selectedListingType = 'Rent';
                } else {
                  _selectedListingType = null;
                }
              }),
              onPropertyTypeChanged: (type) =>
                  setState(() => _selectedPropertyType = type),
            ),
            SizedBox(height: 12.h),
            Expanded(child: _buildContent(theme)),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
      child: Row(
        children: [
          Text(
            'Announcements',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.to(() => const SearchView()),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 35.w,
              height: 35.w,
              child: Image.asset(
                'assets/images/search_icon.png',
                width: 35.w,
                height: 35.w,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // New announcements auto-refresh the cached list via the
          // controller's mutation hook, so just navigate.
          GestureDetector(
            onTap: () =>
                Get.to(() => const CreateAnnouncementView(fromBroker: true)),
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              'assets/images/home_add_icon.png',
              width: 35.w,
              height: 35.w,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────

  Widget _buildTabBar(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────

  Widget _buildContent(ThemeData theme) {
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
      final rawList = isMine
          ? _controller.brokerMineAnnouncements.toList()
          : _controller.allAnnouncements
              .where((a) => a.userId != myId)
              .toList();
      final announcements = _filtered(rawList);

      Future<void> refresh() => isMine
          ? _controller.loadBrokerMine(force: true)
          : _controller.loadAll(force: true);

      // First-load shimmer only when nothing is cached yet.
      if (isLoading && announcements.isEmpty) {
        return _buildShimmer();
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
            physics: const AlwaysScrollableScrollPhysics(),
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
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
            itemCount: itemCount,
            itemBuilder: (_, i) {
              if (i == headerIdx) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildSectionHeader(theme, _tabs[_selectedTab],
                      '${announcements.length} announcements'),
                );
              }
              if (i >= cardStart && i < cardEnd) {
                final idx = i - cardStart;
                final a = announcements[idx];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: RepaintBoundary(
                    child: HomeAnnouncementCard(
                      announcement: a,
                      index: idx,
                      cardWidth: 344.w,
                      cardHeight: 263.h,
                      showBrokerageRow: true,
                      onTap: () => Get.to(
                          () => BrokerAnnouncementDetailView(announcement: a)),
                    ),
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

  Widget _buildShimmer() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: 2,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => Container(
        width: double.infinity,
        height: 263.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface),
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
