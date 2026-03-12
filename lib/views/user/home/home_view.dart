import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
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

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  final imgUrl = profileController.profileImage.value;
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
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              width: 46.w,
                              height: 46.w,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/home-profile-icon.jpg',
                                fit: BoxFit.cover,
                                width: 46.w,
                                height: 46.w,
                              ),
                            )
                          : Image.asset(
                              'assets/images/home-profile-icon.jpg',
                              fit: BoxFit.cover,
                              width: 46.w,
                              height: 46.w,
                            ),
                    ),
                  );
                }),
                SizedBox(width: 10.w),
                Expanded(
                  child: Obx(() {
                    final name = profileController.userName.value;
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
          height: 85.h,
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
    final announcements = _getMockAnnouncements();

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
                  onTap: () => Get.to(() => PropertyDetailView(
                        announcement: announcements.first,
                        sectionTitle:
                            announcements.first.propertyName ?? 'Details',
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
                  onTap: () => Get.to(
                      () => MorePropertyView(announcements: announcements)),
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
              itemCount: announcements.length,
              separatorBuilder: (_, __) => SizedBox(width: 14.w),
              itemBuilder: (_, index) {
                return HomeAnnouncementCard(
                  announcement: announcements[index],
                  index: index,
                );
              },
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
                    style: GoogleFonts.carlito(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
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
  List<AnnouncementModel> _getMockAnnouncements() {
    return [
      AnnouncementModel(
        listingType: 'For Rent',
        imageUrls: ['assets/images/room.png'],
        price: 10000,
        propertyName: 'SAFA TWO de GRISOGONO',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '15 min ago',
      ),
      AnnouncementModel(
        listingType: 'For Rent',
        imageUrls: ['assets/images/room.png'],
        price: 15000,
        propertyName: 'MARINA BAY TOWERS',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '30 min ago',
      ),
      AnnouncementModel(
        listingType: 'For sell',
        imageUrls: ['assets/images/room.png'],
        price: 850000,
        propertyName: 'BURJ VISTA HEIGHTS',
        location: 'Abu Dhabi | UAE',
        timeAgo: '1 hr ago',
      ),
    ];
  }

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
