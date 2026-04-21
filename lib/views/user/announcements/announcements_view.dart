import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
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
            CustomHeader(
              title: 'ANNOUNCEMENTS',
              leading: GestureDetector(
                onTap: () {},
                child: Icon(Icons.search, size: 36.sp, color: AppColors.primary),
              ),
              trailing: GestureDetector(
                onTap: () => Get.to(() => const CreateAnnouncementView()),
                child: Image.asset('assets/images/home_add_icon.png', width: 50.w, height: 50.w),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: announcements.length,
                itemBuilder: (_, index) {
                  return AnnouncementPropertyCard(
                    announcement: announcements[index],
                    index: index,
                    onTap: () {},
                    onWishlistTap: () {},
                    onLocationTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AnnouncementModel> _mockAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        ownerName: 'Hemant',
        listingType: 'Rent',
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
        listingType: 'sell',
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
