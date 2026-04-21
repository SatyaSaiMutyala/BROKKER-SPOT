import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:get/get.dart';

class BrokerProjectsView extends StatelessWidget {
  const BrokerProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Projects',
              // trailing: Container(
              //   padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(20.r),
              //     border: Border.all(color: AppColors.goldAccent),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Image.asset('assets/images/search_icon.png',
              //           width: 18.sp, height: 18.sp),
              //       SizedBox(width: 4.w),
              //       Text(
              //         'Search..',
              //         style: GoogleFonts.inter(
              //           fontSize: 14.sp,
              //           color: Colors.grey.shade400,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ),
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final announcements = _mockAnnouncements();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildSectionHeader('Announcement', '15 min ago updated'),
          ),
          ...announcements.asMap().entries.map(
                (entry) => AnnouncementPropertyCard(
                  announcement: entry.value,
                  index: entry.key,
                  showWishlist: false,
                  showActionButtons: false,
                  ownerRowAboveImage: true,
                  onTap: () => Get.to(() => BrokerAnnouncementDetailView(
                        announcement: entry.value,
                      )),
                ),
              ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: PremiumLockBanner(onTap: () {}),
          ),
          SizedBox(height: 24.h),
        ],
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
            color: Colors.black,
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            color: AppColors.goldAccent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '!',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  List<AnnouncementModel> _mockAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        ownerName: 'He---',
        listingType: 'For Rent',
        price: 5000,
        propertyName: 'Wooden Home',
        bedrooms: 2,
        sqft: 847,
        location: 'Abu Dhabi | United Arab Emirates',
        timeAgo: '15 min ago',
      ),
      AnnouncementModel(
        id: '2',
        ownerName: 'Ne--',
        listingType: 'For sell',
        price: 8000,
        propertyName: 'Modern Villa',
        bedrooms: 3,
        sqft: 1200,
        location: 'Dubai | United Arab Emirates',
        timeAgo: '20 min ago',
      ),
    ];
  }
}
