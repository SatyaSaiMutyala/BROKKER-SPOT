import 'dart:math' show Random, max;
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/notifications/notifications_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/views/user/home/controller/property_search_controller.dart';
import 'package:brokkerspot/views/user/home/filter_view.dart';
import 'package:brokkerspot/views/user/home/more_property_view.dart'; // ignore: unused_import — used by the parked carousels
import 'package:brokkerspot/widgets/announcements/home_filter_bar.dart';
import 'package:brokkerspot/widgets/common/app_search_bar.dart';
import 'package:brokkerspot/widgets/common/pinned_header_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/home/story_circle.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/widgets/home/home_app_bar.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:brokkerspot/core/common_widget/shimmer_box.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onAccountTap;
  const HomeView({super.key, this.onAccountTap});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _profileCtrl = Get.put(ProfileController());
  final _announcementCtrl = AnnouncementListController.to;
  final _searchCtrl = PropertySearchController.to;
  final _notificationCtrl = NotificationListController.to;
  final _scrollController = ScrollController();
  final _searchTextCtrl = TextEditingController();

  /// Side gutter for every row on this screen — header, stories, search,
  /// filters and cards all line up against it.
  double get _gutter => 10.w;

  /// Breathing room between the status bar and the header.
  ///
  /// [SafeArea] only reserves the physical status-bar inset. On iOS that inset
  /// is tall (notch / Dynamic Island) so the header already clears it
  /// comfortably; Android's is roughly half as tall, leaving the header flush
  /// against the clock. So top up whatever the inset is short of an iOS-like
  /// total rather than hardcoding `Platform.isAndroid` — this also covers
  /// Android devices with tall punch-hole insets, which need no extra gap.
  ///
  /// Raw logical pixels, not `.h`: it is compared against a device inset, which
  /// ScreenUtil does not scale.
  double get _headerTopGap =>
      max(0.0, 44.0 - MediaQuery.viewPaddingOf(context).top);

  // Pinned-header heights. Built from the same tokens as the children they
  // wrap, since a persistent header can't measure its child.
  // HomeAppBar's tallest children are the 42.h action pill and the 41.w
  // avatar; .w and .h scale independently, so take whichever wins.
  double get _appBarExtent => max(42.h, 41.w) + 12.h + _headerTopGap;
  double get _searchFilterExtent =>
      12.h + 45.h + 12.h + 33.h + 10.h; // gap + search + gap + chips + gap

  static const _stories = [
    {'name': 'Brokkerspot', 'image': 'assets/images/brocker-icon.png'},
    {'name': 'Rachid', 'image': 'assets/images/story1.png'},
    {'name': 'Nisha', 'image': 'assets/images/story2.png'},
    {'name': 'Joya', 'image': 'assets/images/story3.png'},
    {'name': 'Aman', 'image': 'assets/images/story4.png'},
    {'name': 'Sara', 'image': 'assets/images/story1.png'},
    {'name': 'Ali', 'image': 'assets/images/story2.png'},
    {'name': 'Riya', 'image': 'assets/images/story3.png'},
    {'name': 'Omar', 'image': 'assets/images/story4.png'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _announcementCtrl.loadAll();
    _notificationCtrl.load();
  }

  /// True when the user has typed a search query or applied filter facets.
  /// Drives which data source the feed shows.
  bool get _isFiltering => !_searchCtrl.filter.value.isEmpty;

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchTextCtrl.dispose();
    super.dispose();
  }

  /// Pulls the next page in once the user is within a screenful of the end.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      if (_isFiltering) {
        _searchCtrl.loadMore();
      } else if (_announcementCtrl.hasMoreAll) {
        _announcementCtrl.loadMoreAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090B11) : Colors.white;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        // One Obx around the whole scroll view: slivers can't be wrapped
        // individually (Obx yields a box widget, not a sliver) and this keeps
        // the list lazy as pages pile up.
        child: Obx(
          () => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _announcementCtrl.loadAll(force: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App bar stays put …
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedHeaderDelegate(
                    extent: _appBarExtent,
                    backgroundColor: bg,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          _gutter, _headerTopGap, _gutter, 12.h),
                      child: _buildHeader(theme),
                    ),
                  ),
                ),
                // … stories are the only row that scrolls away …
                SliverToBoxAdapter(child: _buildStoryRow()),
                // … then search + filters park under the app bar.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedHeaderDelegate(
                    extent: _searchFilterExtent,
                    backgroundColor: bg,
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        AppSearchBar(
                          controller: _searchTextCtrl,
                          horizontalPadding: _gutter,
                          filterBadgeCount: _searchCtrl.filter.value.activeCount,
                          onChanged: _searchCtrl.onSearchChanged,
                          onFilterTap: () async {
                            final result = await Get.to<PropertyFilter>(
                              () => FilterView(
                                initial: _searchCtrl.filter.value,
                              ),
                            );
                            if (result != null) {
                              _searchCtrl.applyFacets(result);
                            }
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildFilterBar(),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
                ..._buildFeedSlivers(),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),

                // ── Parked for later ───────────────────────────────────────
                // Banner + the two horizontal carousels. Keep these — the
                // home feed is a single vertical list for now.
                //
                // _buildBannerImage(),
                // _buildSectionHeader(
                //   theme: theme,
                //   title: 'Announcements',
                //   onMore: () => Get.to(() => const MorePropertyView()),
                // ),
                // _buildSectionHeader(
                //   theme: theme,
                //   title: 'Popular Announcements',
                //   onMore: () => Get.to(() => const MorePropertyView()),
                // ),
                // _buildPopularList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Obx(() {
      final isProfileLoading =
          _profileCtrl.isLoading.value && !_profileCtrl.isGuest;
      return HomeAppBar(
        avatarUrl: _profileCtrl.profileImage.value.trim(),
        isAvatarLoading: isProfileLoading,
        greetingName: _profileCtrl.isGuest
            ? 'Guest'
            : _profileCtrl.userName.value.split(' ').first,
        isGreetingLoading: isProfileLoading,
        location: 'Dubai',
        notificationCount: _notificationCtrl.unseenCount.value,
        onAvatarTap: () => widget.onAccountTap?.call(),
        onLocationTap: () => Get.to(() => SettingsView()),
        onNotificationTap: () => Get.to(() => const NotificationsView()),
        onSearchTap: () => Get.to(() => const SearchView()),
      );
    });
  }

  // ── Stories ──────────────────────────────────────────────────────────────────

  Widget _buildStoryRow() {
    return SizedBox(
      height: 94.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: _gutter),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => StoryCircle(
          name: _stories[i]['name']!,
          imageUrl: _stories[i]['image'],
        ),
      ),
    );
  }

  // ── Banner ───────────────────────────────────────────────────────────────────

  // ignore: unused_element — parked, see build()
  Widget _buildBannerImage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gutter),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Image.asset(
          'assets/images/banner-img.png',
          width: double.infinity,
          height: 101.h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 101.h,
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────────

  // ignore: unused_element — parked, see build()
  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required VoidCallback onMore,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gutter),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onMore,
            child: Text(
              'More',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ───────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return HomeFilterBar(
      horizontalPadding: _gutter,
      filter: _searchCtrl.filter.value,
      onFilterChanged: _searchCtrl.applyFacets,
      onResetAll: () {
        _searchTextCtrl.clear();
        _searchCtrl.resetAll();
      },
    );
  }

  // ── Announcements feed ──────────────────────────────────────────────────────

  List<Widget> _buildSearchFeedSlivers() {
    final ctrl = _searchCtrl;
    if (ctrl.isLoading.value && ctrl.results.isEmpty) {
      return [_skeletonSliver(count: 3)];
    }
    if (ctrl.error.value != null && ctrl.results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _buildErrorState(onRetry: ctrl.refreshResults),
        ),
      ];
    }
    final items = ctrl.results.toList();
    if (items.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState())];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: _gutter),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (_, i) {
            final a = items[i];
            return RepaintBoundary(
              child: Material(
                color: Colors.transparent,
                child: HomeAnnouncementCard(
                  announcement: a,
                  index: i,
                  cardWidth: double.infinity,
                  cardHeight: 263.h,
                  onTap: () => Get.to(() => AnnouncementDetailView(
                        announcement: a,
                        isOwner: false,
                      )),
                ),
              ),
            );
          },
        ),
      ),
      if (ctrl.isLoadingMore.value)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _skeletonCard(),
          ),
        ),
    ];
  }

  /// The feed portion of the scroll view: cards plus whichever state slot
  /// applies (first-load skeletons, error, empty, next-page skeleton).
  /// Interleaves the promo banners into the announcement list: banner 1 after
  /// the 5th card, banner 2 after the 10th. Guarded by `>` so a banner only
  /// appears when there's a card after it — they stay in the middle of the
  /// feed, never dangling at the end, and never repeat on later pages.
  List<_FeedEntry> _buildFeedEntries(List<AnnouncementModel> items) {
    final entries = <_FeedEntry>[];
    for (var i = 0; i < items.length; i++) {
      entries.add(_FeedEntry.card(items[i], i));
      if (i == 4 && items.length > 5) {
        entries.add(const _FeedEntry.banner('assets/images/home_banner1.png'));
      }
      if (i == 9 && items.length > 10) {
        entries.add(const _FeedEntry.banner('assets/images/home_banner2.png'));
      }
    }
    return entries;
  }

  Widget _buildFeedBanner(String asset) {
    // Assets are 1408×465 (~3.03:1). Reserve that ratio so the row always has
    // height, and show a placeholder rather than vanishing if it can't load.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: AspectRatio(
        aspectRatio: 1408 / 465,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF20242C),
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined,
                size: 28.sp, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedSlivers() {
    if (_isFiltering) return _buildSearchFeedSlivers();

    final ctrl = _announcementCtrl;

    if (ctrl.isLoadingAll.value && ctrl.allAnnouncements.isEmpty) {
      return [_skeletonSliver(count: 3)];
    }
    if (ctrl.allError.value != null && ctrl.allAnnouncements.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _buildErrorState(onRetry: () => ctrl.loadAll(force: true)),
        ),
      ];
    }

    final items = ctrl.allAnnouncements.toList();
    if (items.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState())];
    }

    final entries = _buildFeedEntries(items);

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: _gutter),
        sliver: SliverList.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (_, i) {
            final entry = entries[i];
            if (entry.banner != null) return _buildFeedBanner(entry.banner!);

            final a = entry.announcement!;
            return RepaintBoundary(
              child: Material(
                color: Colors.transparent,
                child: HomeAnnouncementCard(
                  announcement: a,
                  index: entry.index,
                  // Fill the gutter-to-gutter width instead of a fixed size, so
                  // cards stay flush with the header and filter rows.
                  cardWidth: double.infinity,
                  cardHeight: 263.h,
                  onTap: () => Get.to(() => AnnouncementDetailView(
                        announcement: a,
                        isOwner: false,
                      )),
                ),
              ),
            );
          },
        ),
      ),
      // Next page on the way — one more skeleton below the last card.
      if (ctrl.isLoadingMoreAll.value)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _skeletonCard(),
          ),
        ),
    ];
  }

  // ── Popular list (mock) ───────────────────────────────────────────────────────

  // ignore: unused_element — parked, see build()
  Widget _buildPopularList() {
    return Obx(() {
      final all = _announcementCtrl.homeAnnouncements.toList();
      if (all.isEmpty) return const SizedBox.shrink();
      final rng = Random();
      final pool = List<AnnouncementModel>.from(all)..shuffle(rng);
      final items = pool.take(5).toList();
      return Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 263.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _gutter),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) => HomeAnnouncementCard(
              announcement: items[i],
              index: i,
              showAvatar: false,
              onTap: () => Get.to(() => AnnouncementDetailView(
                    announcement: items[i],
                    isOwner: false,
                  )),
            ),
          ),
        ),
      );
    });
  }

  // ── States ──────────────────────────────────────────────────────────────────

  /// A single card-shaped skeleton, matching the real card's footprint so the
  /// list doesn't jump when the data lands.
  Widget _skeletonCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: ShimmerBox(width: double.infinity, height: 263.h),
    );
  }

  Widget _skeletonSliver({required int count}) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _gutter),
      sliver: SliverList.separated(
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gutter, vertical: 24.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load announcements.",
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gutter, vertical: 32.h),
      child: Center(
        child: Text(
          'No announcements yet',
          style:
              GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

/// One row in the home feed: either an announcement card or a promo banner.
class _FeedEntry {
  final AnnouncementModel? announcement;

  /// Original position in the announcement list — passed to the card so its
  /// per-index styling is unaffected by interleaved banners.
  final int index;
  final String? banner;

  const _FeedEntry.card(this.announcement, this.index) : banner = null;
  const _FeedEntry.banner(this.banner)
      : announcement = null,
        index = -1;
}
