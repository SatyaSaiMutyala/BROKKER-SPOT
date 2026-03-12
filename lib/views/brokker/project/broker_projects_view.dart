import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_model.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/projects/tab_toggle.dart';
import 'package:brokkerspot/widgets/projects/project_grid_card.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/brokker/project/project_detail_view.dart';

class BrokerProjectsView extends StatefulWidget {
  const BrokerProjectsView({super.key});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Projects',
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.goldAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/search_icon.png', width: 16.sp, height: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      'Search..',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Tab Toggle
            TabToggle(
              tabs: const ['Primary', 'Secondary'],
              selectedIndex: _selectedTab,
              onTabChanged: (index) {
                setState(() => _selectedTab = index);
              },
            ),
            SizedBox(height: 16.h),
            // Content
            Expanded(
              child: _selectedTab == 0
                  ? _buildPrimaryTab()
                  : _buildSecondaryTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRIMARY TAB ====================
  Widget _buildPrimaryTab() {
    final projects = _mockProjects();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Developer header
          _buildSectionHeader('DAMAC', '15 min ago updated'),
          SizedBox(height: 12.h),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.99,
            ),
            itemCount: projects.length,
            itemBuilder: (_, index) {
              return ProjectGridCard(
                project: projects[index],
                onTap: () {
                  Get.to(() => ProjectDetailView(project: projects[index]));
                },
              );
            },
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ==================== SECONDARY TAB ====================
  Widget _buildSecondaryTab() {
    final announcements = _mockSecondaryAnnouncements();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildSectionHeader('Announcement', '15 min ago updated'),
          ),
          SizedBox(height: 8.h),
          // Announcement cards
          ...announcements.asMap().entries.map(
            (entry) => AnnouncementPropertyCard(
              announcement: entry.value,
              index: entry.key,
              onTap: () {},
            ),
          ),
          SizedBox(height: 8.h),
          // Premium banner
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: PremiumLockBanner(
              onTap: () {
                // Handle premium purchase
              },
            ),
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
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 6.w),
        Container(
          width: 8.w,
          height: 8.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen,
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

  List<ProjectModel> _mockProjects() {
    return [
      ProjectModel(
        id: '1',
        name: 'AL JAWHARAH',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/room.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
      ProjectModel(
        id: '2',
        name: 'CAVALLI TOWER',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/rent1.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
      ProjectModel(
        id: '3',
        name: 'AL JAWHARAH',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/rent2.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
      ProjectModel(
        id: '4',
        name: 'AVANTI',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/room.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
      ProjectModel(
        id: '5',
        name: 'AL JAWHARAH',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/rent1.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
      ProjectModel(
        id: '6',
        name: 'AL JAWHARAH',
        developer: 'DAMAC',
        location: 'Dubai | United Arab...',
        imageUrl: 'assets/images/rent2.png',
        price: 1000000,
        brokerage: 65000,
        units: 5,
      ),
    ];
  }

  List<AnnouncementModel> _mockSecondaryAnnouncements() {
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
