import 'dart:math' show Random, max;
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/notifications/notifications_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/home/more_property_view.dart'; // ignore: unused_import — used by the parked carousels
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
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
  final _notificationCtrl = NotificationListController.to;
  final _scrollController = ScrollController();

  /// Side gutter for every row on this screen — header, stories, search,
  /// filters and cards all line up against it.
  double get _gutter => 10.w;

  // Pinned-header heights. Built from the same tokens as the children they
  // wrap, since a persistent header can't measure its child.
  // HomeAppBar's tallest children are the 42.h action pill and the 41.w
  // avatar; .w and .h scale independently, so take whichever wins.
  double get _appBarExtent => max(42.h, 41.w) + 12.h;
  double get _searchFilterExtent =>
      12.h + 45.h + 12.h + 39.h + 16.h; // gap + search + gap + chips + gap

  String? _selectedListingType; // null = all, 'Sell' = Buy, 'Rent' = Rent
  String? _selectedPropertyType; // null = all

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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Pulls the next page in once the user is within a screenful of the end.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400 && _announcementCtrl.hasMoreAll) {
      _announcementCtrl.loadMoreAll();
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
                      padding: EdgeInsets.fromLTRB(_gutter, 0, _gutter, 12.h),
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
                          readOnly: true,
                          horizontalPadding: _gutter,
                          onTap: () => Get.to(() => const SearchView()),
                          onFilterTap: () => Get.to(() => const SearchView()),
                        ),
                        SizedBox(height: 12.h),
                        _buildFilterBar(),
                        SizedBox(height: 16.h),
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
    return AnnouncementFilterBar(
      horizontalPadding: _gutter,
      selectedListingType: _selectedListingType,
      selectedPropertyType: _selectedPropertyType,
      onListingTypeChanged: (val) => setState(() => _selectedListingType = val),
      onPropertyTypeChanged: (type) =>
          setState(() => _selectedPropertyType = type),
    );
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

  // ── Announcements feed ──────────────────────────────────────────────────────

  /// The feed portion of the scroll view: cards plus whichever state slot
  /// applies (first-load skeletons, error, empty, next-page skeleton).
  List<Widget> _buildFeedSlivers() {
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

    final items = _filtered(ctrl.allAnnouncements.toList());
    if (items.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmptyState())];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: _gutter),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: 16.h),
          itemBuilder: (_, i) {
            final a = items[i];
            return RepaintBoundary(
              child: Material(
                color: Colors.transparent,
                child: HomeAnnouncementCard(
                  announcement: a,
                  index: i,
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
