import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';

class AnnouncementsView extends StatelessWidget {
  const AnnouncementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = _mockAnnouncements();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: announcements.length,
                itemBuilder: (_, index) {
                  return AnnouncementPropertyCard(
                    announcement: announcements[index],
                    showWishlist: true,
                    showStatusBadge: false,
                    showBrokerAvatar: false,
                    onTap: () {
                      // Handle card tap
                    },
                    onWishlistTap: () {
                      // Handle wishlist
                    },
                    onLocationTap: () {
                      // Handle location
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Handle search
            },
            child: Icon(
              Icons.search,
              size: 26.sp,
              color: AppColors.teal,
            ),
          ),
          const Spacer(),
          Text(
            'ANNOUNCEMENTS',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Get.to(() => const CreateAnnouncementView());
            },
            child: Icon(
              Icons.add_home_outlined,
              size: 26.sp,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  List<AnnouncementModel> _mockAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        ownerName: 'Hemant',
        listingType: 'For Rent',
        price: 1000000,
        propertyName: 'Wooden Home',
        bedrooms: 2,
        sqft: 847,
        location: 'Abu Dhabi | United Arab Emirates',
        timeAgo: '15 min ago',
        isWishlisted: false,
      ),
      AnnouncementModel(
        id: '2',
        ownerName: 'Neha',
        listingType: 'For sell',
        price: 850000,
        propertyName: 'Modern Villa',
        bedrooms: 3,
        sqft: 1200,
        location: 'Dubai | United Arab Emirates',
        timeAgo: '30 min ago',
        isWishlisted: true,
      ),
    ];
  }
}
