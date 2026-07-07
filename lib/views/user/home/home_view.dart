import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/notifications/notifications_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/profile/profile_view.dart';
import 'package:brokkerspot/views/user/home/more_property_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/home/story_circle.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/views/user/home/property_detail_view.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/core/common_widget/shimmer_box.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _profileCtrl = Get.put(ProfileController());
  final _announcementCtrl = AnnouncementListController.to;
  final _notificationCtrl = NotificationListController.to;

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
    _announcementCtrl.loadHome();
    _notificationCtrl.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _announcementCtrl.loadHome(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildHeader(theme),
                ),
                SizedBox(height: 16.h),
                _buildStoryRow(),
                SizedBox(height: 6.h),
                _buildBannerImage(),
                SizedBox(height: 16.h),
                _buildSectionHeader(
                  theme: theme,
                  title: 'Announcements',
                  onMore: () => Get.to(() => const MorePropertyView()),
                ),
                SizedBox(height: 12.h),
                _buildAnnouncementsList(),
                SizedBox(height: 16.h),
                _buildSectionHeader(
                  theme: theme,
                  title: 'Popular Announcements',
                  onMore: () => Get.to(
                      () => MorePropertyView(staticList: _getMockPopular())),
                ),
                SizedBox(height: 12.h),
                _buildPopularList(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Avatar + greeting
        GestureDetector(
          onTap: () {
            if (!_profileCtrl.isGuest) Get.to(() => ProfileView());
          },
          child: Obx(() {
            final imgUrl = _profileCtrl.profileImage.value.trim();
            final isLoading =
                _profileCtrl.isLoading.value && !_profileCtrl.isGuest;
            return Row(
              children: [
                // Avatar — 41×41 with 1px #DBC483 border
                Container(
                  width: 41.w,
                  height: 41.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDBC483),
                      width: 1,
                    ),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipOval(
                    child: isLoading
                        ? ShimmerCircle(radius: 19.w)
                        : imgUrl.isNotEmpty
                            ? Image.network(
                                imgUrl,
                                key: ValueKey(imgUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder(),
                  ),
                ),
                SizedBox(width: 12.w),
                // Greeting + location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading) ...[
                      ShimmerBox(
                          width: 120.w,
                          height: 18.h,
                          borderRadius: BorderRadius.circular(4.r)),
                      SizedBox(height: 4.h),
                      ShimmerBox(
                          width: 80.w,
                          height: 14.h,
                          borderRadius: BorderRadius.circular(4.r)),
                    ] else ...[
                      Text(
                        'Hi, ${_profileCtrl.isGuest ? 'Guest' : _profileCtrl.userName.value.split(' ').first}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 14 * 0.075,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12.sp, color: AppColors.primary),
                          SizedBox(width: 2.w),
                          Text(
                            'Dubai',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w300,
                              color: theme.colorScheme.onSurface,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),
        ),

        const Spacer(),

        // Notification + Search — single pill (#FAF7F1, 91×41, r:39)
        Container(
          width: 91.w,
          height: 41.h,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFFAF7F1),
            borderRadius: BorderRadius.circular(39.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notification bell — outline, 1.5px stroke #343434
              GestureDetector(
                onTap: () => Get.to(() => const NotificationsView()),
                behavior: HitTestBehavior.opaque,
                child: Obx(() {
                  final count = _notificationCtrl.unseenCount.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 22.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 14.w,
                            height: 14.w,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.red),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: GoogleFonts.inter(
                                    fontSize: 7.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              // Search icon — asset, 20×20
              GestureDetector(
                onTap: () => Get.to(() => const SearchView()),
                behavior: HitTestBehavior.opaque,
                child: Image.asset(
                  'assets/images/search_icon.png',
                  width: 20.w,
                  height: 20.w,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 22.sp, color: Colors.grey),
    );
  }

  // ── Stories ──────────────────────────────────────────────────────────────────

  Widget _buildStoryRow() {
    return SizedBox(
      height: 94.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => StoryCircle(
          name: _stories[i]['name']!,
          imageUrl: _stories[i]['image'],
        ),
      ),
    );
  }

  // ── Banner ───────────────────────────────────────────────────────────────────

  Widget _buildBannerImage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 19.w),
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

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required VoidCallback onMore,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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

  // ── Announcements list ───────────────────────────────────────────────────────

  Widget _buildAnnouncementsList() {
    return Obx(() {
      final ctrl = _announcementCtrl;
      if (ctrl.isLoadingHome.value && ctrl.homeAnnouncements.isEmpty) {
        return _buildShimmerList();
      }
      if (ctrl.homeError.value != null && ctrl.homeAnnouncements.isEmpty) {
        return _buildErrorState(onRetry: () => ctrl.loadHome(force: true));
      }
      if (ctrl.homeAnnouncements.isEmpty) {
        return _buildEmptyState();
      }
      return SizedBox(
        height: 273.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: ctrl.homeAnnouncements.length,
          separatorBuilder: (_, __) => SizedBox(width: 14.w),
          itemBuilder: (_, i) {
            final a = ctrl.homeAnnouncements[i];
            return HomeAnnouncementCard(
              announcement: a,
              index: i,
              onTap: () => Get.to(() => AnnouncementDetailView(
                    announcement: a,
                    isOwner: false,
                  )),
            );
          },
        ),
      );
    });
  }

  // ── Popular list (mock) ───────────────────────────────────────────────────────

  Widget _buildPopularList() {
    final items = _getMockPopular();
    return SizedBox(
      height: 273.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (_, i) => HomeAnnouncementCard(
          announcement: items[i],
          index: i,
          showAvatar: false,
          onTap: () => Get.to(() => PropertyDetailView(
                announcement: items[i],
                sectionTitle: items[i].propertyName ?? '',
              )),
        ),
      ),
    );
  }

  // ── States ──────────────────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    return SizedBox(
      height: 273.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (_, __) => Container(
          width: 329.w,
          height: 263.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: ShimmerBox(width: 280.w, height: 400.h),
        ),
      ),
    );
  }

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      child: Center(
        child: Text(
          'No announcements yet',
          style:
              GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  // ── Mock data ────────────────────────────────────────────────────────────────

  List<AnnouncementModel> _getMockPopular() => [
        AnnouncementModel(
          listingType: 'Sell',
          propertyType: 'Villa',
          imageUrls: ['assets/images/room.png'],
          price: 1000000,
          currency: 'AED',
          propertyName: 'SAFA TWO de GRISOGONO',
          location: 'Dubai, United Arab Emirates',
          timeAgo: '15 min ago',
        ),
        AnnouncementModel(
          listingType: 'Rent',
          propertyType: 'Apartment',
          imageUrls: ['assets/images/room.png'],
          price: 1200000,
          currency: 'AED',
          propertyName: 'DAMAC LAGOONS',
          location: 'Dubai, United Arab Emirates',
          timeAgo: '3 hr ago',
        ),
      ];
}
