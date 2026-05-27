import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
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
import 'package:brokkerspot/widgets/home/new_launch_banner.dart';
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
  final ProfileController profileController = Get.put(ProfileController());
  final AnnouncementListController _announcementController =
      AnnouncementListController.to;

  @override
  void initState() {
    super.initState();
    // Loads only if not cached yet — fetches just 5 records for the home feed.
    _announcementController.loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _announcementController.loadHome(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
              // Header
              Padding(
                padding: EdgeInsets.only(left: 16.h, bottom: 16.h, top: 4.h),
                child: _buildHeader(),
              ),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // New Launch Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: NewLaunchBanner(
                  title: 'New Launch',
                  subtitle: 'CANAL\nHEIGHTS',
                  timeLeft: '15:00',
                  imageUrl: 'assets/images/banner-img.png',
                ),
              ),
              SizedBox(height: 14.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 8.h),
              // All Story section
              _buildStorySection(),
              SizedBox(height: 14.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 6.h),
              // Announcements section
              _buildAnnouncementsSection(),
              SizedBox(height: 20.h),
              // DAMAC section
              _buildDamacSection(),
              SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────── HEADER ───────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Profile avatar + greeting (tappable)
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!profileController.isGuest) {
                Get.to(() => ProfileView());
              }
            },
            child: Row(
              children: [
                Obx(() {
                  final isLoading = profileController.isLoading.value;
                  final imgUrl = profileController.profileImage.value.trim();
                  if (isLoading && !profileController.isGuest) {
                    return ShimmerCircle(radius: 23.w);
                  }
                  Widget placeholder = Center(
                    child: Icon(
                      Icons.person,
                      size: 24.w,
                      color: Colors.grey,
                    ),
                  );
                  return Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: ClipOval(
                        child: imgUrl.isNotEmpty
                            ? Image.network(imgUrl,
                                key: ValueKey(imgUrl),
                                fit: BoxFit.cover,
                                width: 46.w,
                                height: 46.w,
                                errorBuilder: (_, __, ___) => placeholder)
                            : placeholder),
                  );
                }),
                SizedBox(width: 10.w),
                Expanded(
                  child: Obx(() {
                    final isLoading = profileController.isLoading.value;
                    final name = profileController.userName.value;
                    if (isLoading && !profileController.isGuest) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 40.w, height: 12.h, borderRadius: BorderRadius.circular(4.r)),
                          SizedBox(height: 6.h),
                          ShimmerBox(width: 120.w, height: 18.h, borderRadius: BorderRadius.circular(4.r)),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          profileController.isGuest
                              ? 'Guest User'
                              : name.isNotEmpty
                                  ? name
                                  : '...',
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 10.w),
        // Search box
        _buildSearchBox(),
        SizedBox(width: 10.w),
        // Notification bell
        _buildNotificationBell(),
        SizedBox(width: 6.w),
      ],
    );
  }

  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: () => Get.to(() => const SearchView()),
      child: Container(
        height: 38.h,
        width: 120.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/search_icon.png',
              width: 18.sp,
              height: 18.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Search...',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.w,
          child: Icon(
            Icons.notifications_none_rounded,
            size: 28.sp,
            color: AppColors.goldAccent,
          ),
        ),
        Positioned(
          right: 0,
          top: -2,
          child: Container(
            width: 18.w,
            height: 18.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: Center(
              child: Text(
                '5',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────── STORIES ───────────
  Widget _buildStorySection() {
    final stories = [
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                'All Story',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 20.w,
                height: 20.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 95.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: stories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              return StoryCircle(
                name: stories[index]['name']!,
                imageUrl: stories[index]['image'],
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────── ANNOUNCEMENTS ───────────
  Widget _buildAnnouncementsSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'Announcements',
                  style: GoogleFonts.carlito(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    final items = _announcementController.homeAnnouncements;
                    if (items.isEmpty) return;
                    Get.to(() => AnnouncementDetailView(
                          announcement: items.first,
                          isOwner: false,
                        ));
                  },
                  borderRadius: BorderRadius.circular(9.r),
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        'i',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Get.to(() => MorePropertyView(
                      announcements:
                          _announcementController.homeAnnouncements.toList())),
                  child: Text(
                    'More',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Obx(() {
            final ctrl = _announcementController;
            // First load — nothing cached yet.
            if (ctrl.isLoadingHome.value && ctrl.homeAnnouncements.isEmpty) {
              return _buildAnnouncementsShimmer();
            }
            if (ctrl.homeError.value != null && ctrl.homeAnnouncements.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Couldn't load announcements. Please try again.",
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      TextButton(
                        onPressed: () => ctrl.loadHome(force: true),
                        child: Text('Retry',
                            style: GoogleFonts.inter(
                                fontSize: 13.sp, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (ctrl.homeAnnouncements.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
                child: Center(
                  child: Text('No announcements yet',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, color: Colors.grey.shade400)),
                ),
              );
            }
            return SizedBox(
              height: 325.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: ctrl.homeAnnouncements.length,
                separatorBuilder: (_, __) => SizedBox(width: 14.w),
                itemBuilder: (_, index) {
                  final a = ctrl.homeAnnouncements[index];
                  return HomeAnnouncementCard(
                    announcement: a,
                    index: index,
                    onTap: () => Get.to(() => AnnouncementDetailView(
                          announcement: a,
                          isOwner: false,
                        )),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────── ANNOUNCEMENTS SHIMMER ───────────
  Widget _buildAnnouncementsShimmer() {
    return SizedBox(
      height: 325.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (_, __) => _announcementShimmerCard(),
      ),
    );
  }

  Widget _announcementShimmerCard() {
    return Container(
      width: 330.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image block
          ShimmerBox(width: 330.w, height: 193.h),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price line
                ShimmerBox(
                    width: 160.w,
                    height: 18.h,
                    borderRadius: BorderRadius.circular(4.r)),
                SizedBox(height: 10.h),
                // Property name line
                ShimmerBox(
                    width: 220.w,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4.r)),
                SizedBox(height: 10.h),
                // Location line
                ShimmerBox(
                    width: 180.w,
                    height: 14.h,
                    borderRadius: BorderRadius.circular(4.r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── DAMAC SECTION ───────────
  Widget _buildDamacSection() {
    final damacAnnouncements = _getMockDamacAnnouncements();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'DAMAC',
                  style: GoogleFonts.carlito(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () => Get.to(() => PropertyDetailView(
                        announcement: damacAnnouncements.first,
                        sectionTitle: 'DAMAC',
                      )),
                  borderRadius: BorderRadius.circular(9.r),
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        'i',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Get.to(() =>
                      MorePropertyView(announcements: damacAnnouncements)),
                  child: Text(
                    'More',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 325.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: damacAnnouncements.length,
              separatorBuilder: (_, __) => SizedBox(width: 14.w),
              itemBuilder: (_, index) {
                return HomeAnnouncementCard(
                  announcement: damacAnnouncements[index],
                  showAvatar: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── MOCK DATA ───────────
  List<AnnouncementModel> _getMockDamacAnnouncements() {
    return [
      AnnouncementModel(
        listingType: '80 UNITS',
        imageUrls: ['assets/images/room.png'],
        price: 1000000,
        propertyName: 'SAFA TWO de GRISOGONO',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '15 min ago',
      ),
      AnnouncementModel(
        listingType: '45 UNITS',
        imageUrls: ['assets/images/room.png'],
        price: 1200000,
        propertyName: 'DAMAC LAGOONS',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '3 hr ago',
      ),
    ];
  }
}
