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
  const HomeView({super.key});

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
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildHeader(),
              ),
              SizedBox(height: 16.h),
              // New Launch Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: NewLaunchBanner(
                  title: 'New Launch',
                  subtitle: 'CANAL\nHEIGHTS',
                  timeLeft: '15:45',
                  imageUrl: 'assets/images/banner.png',
                ),
              ),
              SizedBox(height: 20.h),
              // All Story section
              _buildStorySection(),
              SizedBox(height: 20.h),
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
        // Profile avatar
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: 24.sp,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // Greeting text
        Column(
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
              'Rachid',
              style: GoogleFonts.inter(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Search box
        _buildSearchBox(),
        SizedBox(width: 10.w),
        // Notification bell
        _buildNotificationBell(),
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
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18.sp, color: Colors.grey),
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
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldAccent.withValues(alpha: 0.15),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 24.sp,
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
      {'name': 'Brokkerspot', 'image': 'assets/images/story.png'},
      {'name': 'Rachid', 'image': 'assets/images/story.png'},
      {'name': 'Nisha', 'image': 'assets/images/story.png'},
      {'name': 'Joya', 'image': 'assets/images/story.png'},
      {'name': 'Aman', 'image': 'assets/images/story.png'},
      {'name': 'Sara', 'image': 'assets/images/story.png'},
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
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.activeGreen,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                'Announcements',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.activeGreen,
                ),
              ),
              const Spacer(),
              Text(
                'More',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 260.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: announcements.length,
            separatorBuilder: (_, __) => SizedBox(width: 14.w),
            itemBuilder: (_, index) {
              return HomeAnnouncementCard(
                announcement: announcements[index],
                onTap: () => Get.to(() => PropertyDetailView(
                      announcement: announcements[index],
                      sectionTitle: announcements[index].propertyName ?? 'Details',
                    )),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────── DAMAC SECTION ───────────
  Widget _buildDamacSection() {
    final damacAnnouncements = _getMockDamacAnnouncements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                'DAMAC',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.activeGreen,
                ),
              ),
              const Spacer(),
              Text(
                'More',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 260.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: damacAnnouncements.length,
            separatorBuilder: (_, __) => SizedBox(width: 14.w),
            itemBuilder: (_, index) {
              return HomeAnnouncementCard(
                announcement: damacAnnouncements[index],
                onTap: () => Get.to(() => PropertyDetailView(
                      announcement: damacAnnouncements[index],
                      sectionTitle: 'DAMAC',
                    )),
              );
            },
          ),
        ),
      ],
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
        listingType: 'For Rent',
        imageUrls: ['assets/images/room.png'],
        price: 25000,
        propertyName: 'DAMAC HILLS VILLA',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '2 hr ago',
      ),
      AnnouncementModel(
        listingType: 'For sell',
        imageUrls: ['assets/images/room.png'],
        price: 1200000,
        propertyName: 'DAMAC LAGOONS',
        location: 'Dubai | United Arab Emirates',
        timeAgo: '3 hr ago',
      ),
    ];
  }
}
