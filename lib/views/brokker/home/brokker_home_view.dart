import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerHomeView extends StatefulWidget {
  const BrokerHomeView({super.key});

  @override
  State<BrokerHomeView> createState() => _BrokerHomeViewState();
}

class _BrokerHomeViewState extends State<BrokerHomeView> {
  int _bannerPage = 0;
  final PageController _bannerController = PageController();

  final List<Map<String, String>> _stories = [
    {'name': 'Brokkerspot', 'image': 'assets/images/realestate_logo.png'},
    {'name': 'Rachid', 'image': 'assets/images/story1.png'},
    {'name': 'Nisha', 'image': 'assets/images/story2.png'},
    {'name': 'Joya', 'image': 'assets/images/story3.png'},
    {'name': 'Aman', 'image': 'assets/images/story4.png'},
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              _buildHeader(),
              SizedBox(height: 14.h),
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
              SizedBox(height: 8.h),
              _buildStoriesSection(),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 16.h),
              _buildGridCards(),
              SizedBox(height: 16.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 16.h),
              _buildBoostBanner(),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader() {
    final profileCtrl = Get.put(ProfileController());
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Profile avatar
          Obx(() {
            final image = profileCtrl.profileImage.value;
            return Container(
              width: 50.w,
              height: 50.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/story1.png',
                          width: 50.w,
                          height: 50.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/story1.png',
                        width: 50.w,
                        height: 50.w,
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }),
          SizedBox(width: 10.w),
          // Name + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              Row(
                children: [
                  Obx(() => Text(
                    profileCtrl.userName.value.isNotEmpty
                        ? profileCtrl.userName.value
                        : 'Guest User',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  )),
                  if (LocalStorageService.isLoggedIn()) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'In Process',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          // Notification bell with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, size: 28.sp, color: AppColors.primary),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Text(
                      '1',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── STORIES SECTION ───
  Widget _buildStoriesSection() {
    return Column(
      children: [
        // All Story + Filter row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                'All Story',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(Icons.keyboard_arrow_down, size: 20.sp, color: Colors.black),
              const Spacer(),
              Text(
                '3 Filter',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Story circles
        SizedBox(
          height: 95.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _stories.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            itemBuilder: (_, index) {
              final story = _stories[index];
              final isFirst = index == 0;
              return SizedBox(
                width: 64.w,
                child: Column(
                  children: [
                    Container(
                      width: 62.w,
                      height: 62.w,
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldAccent,
                          width: 2.w,
                        ),
                      ),
                      child: ClipOval(
                        child: isFirst
                            ? Container(
                                color: Colors.white,
                                padding: EdgeInsets.all(8.w),
                                child: Image.asset(
                                  story['image']!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                story['image']!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      story['name']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── GRID CARDS ───
  Widget _buildGridCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoCard(
                title: 'LEADS',
                items: ['Brokkersopt\nBuyers', 'Your Own\nBuyers'],
              ),
              SizedBox(width: 12.w),
              _buildInfoCard(
                title: 'PROJECT',
                items: ['Completed\nDeals', 'Deal Started'],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildInfoCard(
                title: 'ANNOUNCEMENT',
                items: ['Your Own', 'Owner'],
              ),
              SizedBox(width: 12.w),
              _buildInfoCard(
                title: 'YOUR COMMISSION',
                items: ['Received', 'Incoming'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<String> items}) {
    return Expanded(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title badge - full card width, no padding
            Container(
              padding: EdgeInsets.symmetric(vertical: 7.h),
              color: const Color(0xFF6B6B6B),
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Items with overlapping circles
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: SizedBox(
                height: 80.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Second row (bottom) - rendered first so it's behind
                    Positioned(
                      top: 36.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          _goldCircle(opacity: 0.6),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              items[1],
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // First row (top) - rendered last so it's on top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          _goldCircle(),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              items[0],
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _goldCircle({double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldAccent,
            AppColors.goldAccent.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '-',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
      ),
    );
  }

  // ─── BOOST BANNER ───
  Widget _buildBoostBanner() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8EC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Left text content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BROKKERSPOT BOOSTS',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'YOUR BUSINESS',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _buildBoostItem('STORY & ANNOUNCEMENTS'),
                      _buildBoostItem('BROKER COMMUNITY'),
                      _buildBoostItem('PLATFORM LEADS', ),
                      _buildBoostItem('OWNER ANNOUNCEMENTS', hasNew: true),
                    ],
                  ),
                ),
                // Right image placeholder
                Expanded(
                  flex: 2,
                  child: Image.asset(
                    'assets/images/broker_boost_icon.png',
                    height: 100.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _bannerPage
                      ? Colors.grey.shade800
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostItem(String text, {bool hasNew = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Image.asset(
            'assets/images/cup_icon.png',
            width: 14.sp,
            height: 14.sp,
          ),
          SizedBox(width: 6.w),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              if (hasNew)
                Positioned(
                  top: -6.h,
                  right: -24.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.poppins(
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
