import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';

class MyAnnouncementsView extends StatelessWidget {
  const MyAnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = _mockMyAnnouncements();

    return Scaffold(
      backgroundColor: AppColors.tealLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Divider(height: 1.h, color: Colors.grey.shade200),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: announcements.length,
                    itemBuilder: (_, index) {
                      return AnnouncementPropertyCard(
                        announcement: announcements[index],
                        showWishlist: false,
                        showStatusBadge: true,
                        showBrokerAvatar: true,
                        onTap: () {},
                        onLocationTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
            // Create Announcement FAB
            Positioned(
              right: 20.w,
              bottom: 24.h,
              child: _buildCreateFab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(
              Icons.chevron_left,
              size: 28.sp,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'MY ANNOUNCEMENTS',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.search,
              size: 24.sp,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFab() {
    return GestureDetector(
      onTap: () {
        Get.to(() => const CreateAnnouncementView());
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Announcement',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add_home_outlined,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  List<AnnouncementModel> _mockMyAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        ownerName: 'Aman',
        listingType: 'For Rent',
        price: 1000000,
        propertyName: 'Wooden Home',
        bedrooms: 2,
        sqft: 847,
        location: 'Abu Dhabi | United Arab Emirates',
        status: 'Active',
        proposalCount: 5,
      ),
    ];
  }
}
