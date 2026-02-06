import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_account_view.dart';
import 'package:brokkerspot/widgets/profile/profile_header_card.dart';
import 'package:brokkerspot/widgets/profile/info_section_tile.dart';
import 'package:brokkerspot/widgets/profile/boost_banner.dart';
import 'package:brokkerspot/widgets/profile/announcement_card.dart';

class BrokerProfileView extends StatelessWidget {
  const BrokerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Divider(height: 1.h, color: Colors.grey.shade200),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    // Profile Header
                    const ProfileHeaderCard(
                      name: 'John',
                      experience: '5 Year',
                      following: '20',
                      brn: '18566',
                      orn: '21556',
                    ),
                    SizedBox(height: 20.h),
                    Divider(height: 1.h, color: Colors.grey.shade200),
                    // Areas
                    const InfoSectionTile(
                      title: 'Areas',
                      content: 'Downtown, Business Bay, Merina',
                    ),
                    // Language
                    const InfoSectionTile(
                      title: 'Language',
                      content: 'English, French, Hindi, Urdu',
                    ),
                    // About me
                    InfoSectionTile(
                      title: 'About me',
                      content:
                          'Ipsum is simply dummytext of the printing and typesettin industryIpsum is simply dummy text of the printing and ti esetting industry. LoremIpsum has been...',
                      showDivider: false,
                    ),
                    SizedBox(height: 20.h),
                    // Boost Banner
                    BoostBanner(
                      duration: '7 days',
                      price: 'AED  20',
                      onTap: () {
                        // Handle boost
                      },
                    ),
                    SizedBox(height: 24.h),
                    // Announcement Timeline
                    _buildTimelineHeader(),
                    SizedBox(height: 12.h),
                    _buildAnnouncementTimeline(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'My Account',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Get.to(() => const AccountMenuView());
            },
            child: Icon(
              Icons.settings_outlined,
              size: 22.sp,
              color: AppColors.goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Row(
      children: [
        Text(
          'All Announcement  Timeline',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 4.w),
        Icon(Icons.keyboard_arrow_down, size: 18.sp, color: Colors.black),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // Handle more
          },
          child: Text(
            'More',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementTimeline() {
    return SizedBox(
      height: 140.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, index) {
          final badges = ['25\nDay', '25\nDay', '1\nMonth'];
          final colors = [
            AppColors.goldAccent,
            AppColors.goldAccent,
            AppColors.successGreen,
          ];
          return AnnouncementCard(
            badgeText: badges[index],
            badgeColor: colors[index],
            onTap: () {
              // Handle card tap
            },
          );
        },
      ),
    );
  }
}
