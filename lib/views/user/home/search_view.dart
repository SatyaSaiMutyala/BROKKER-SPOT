import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/home/new_launch_banner.dart';
import 'package:brokkerspot/widgets/search/filter_chip_bar.dart';
import 'package:brokkerspot/widgets/search/search_property_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;

  final List<String> _filters = [
    'BUY',
    'New Projects',
    'Commercial',
    'Ready For Move-in',
    'Off-Plan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, size: 20.sp, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Search',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14.h),
                  // Banner
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: NewLaunchBanner(
                      title: 'New Launch',
                      subtitle: 'CANAL\nHEIGHTS',
                      timeLeft: '15:45',
                      imageUrl: 'assets/images/banner.png',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Search input
                  _buildSearchInput(),
                  SizedBox(height: 14.h),
                  // Filter chips
                  FilterChipBar(
                    filters: _filters,
                    selectedIndex: _selectedFilter,
                    onSelected: (i) =>
                        setState(() => _selectedFilter = i),
                  ),
                  SizedBox(height: 8.h),
                  // Property results
                  ..._getMockResults().map(
                    (item) => SearchPropertyCard(
                      announcement: item['announcement'] as AnnouncementModel,
                      ownerName: item['ownerName'] as String?,
                      ownerAvatarUrl: item['ownerAvatar'] as String?,
                      timeAgo: item['timeAgo'] as String?,
                      badge: item['badge'] as String?,
                      unitsLeft: item['unitsLeft'] as int?,
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  SizedBox(width: 14.w),
                  Icon(Icons.search, size: 22.sp, color: Colors.grey),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'City, Area or Building...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Filter icon button
          Container(
            width: 46.h,
            height: 46.h,
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 22.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockResults() {
    return [
      {
        'announcement': AnnouncementModel(
          imageUrls: ['assets/images/room.png'],
          price: 100000,
          propertyName: 'SAFA TWO de GRISOGONO',
          location: 'Dubai | United Arab Emirates',
        ),
        'ownerName': 'Aman',
        'ownerAvatar': 'assets/images/story.png',
        'timeAgo': '15 min ago',
        'badge': 'RENT',
        'unitsLeft': 80,
      },
      {
        'announcement': AnnouncementModel(
          imageUrls: ['assets/images/room.png'],
          price: 250000,
          propertyName: 'MARINA BAY TOWERS',
          location: 'Dubai | United Arab Emirates',
        ),
        'ownerName': 'Aman',
        'ownerAvatar': 'assets/images/story.png',
        'timeAgo': '15 min ago',
        'badge': 'RENT',
        'unitsLeft': 45,
      },
    ];
  }
}
