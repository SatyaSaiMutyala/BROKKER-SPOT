import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/meeting/chat_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetingView extends StatefulWidget {
  const MeetingView({super.key});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  bool isBookingSelected = true;
  int _selectedAnnouncementFilter = 0;

  final List<String> _announcementFilters = ['ALL', 'BUY', 'RENT', 'OWN'];

  // Dummy data
  final List<Map<String, String>> bookingList = [
    {
      'name': 'Aman',
      'subtitle': 'SAFA/TWO\nFrom AED 99,000',
      'time': '2 min ago',
    }
  ];

  final List<Map<String, dynamic>> announcementList = [
    {
      'propertyType': 'Apartment',
      'listingType': 'OWN',
      'forType': 'For RENT',
      'price': '3,740,000',
      'avatar': 'assets/images/story1.png',
      'propertyImage': 'assets/images/rent1.png',
      'badgeCount': 2,
    },
    {
      'propertyType': 'Villa',
      'listingType': '',
      'forType': 'For RENT',
      'price': '6,580,000',
      'avatar': 'assets/images/story2.png',
      'propertyImage': 'assets/images/rent2.png',
      'badgeCount': 1,
    },
    {
      'propertyType': 'Apartment',
      'listingType': '',
      'forType': 'For RENT',
      'price': '3,740,000',
      'avatar': 'assets/images/story1.png',
      'propertyImage': 'assets/images/rent1.png',
      'badgeCount': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'Meeting'),
            // Tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: CustomPrimaryButton(
                      title: 'Booking',
                      defaultColor:
                          isBookingSelected ? Colors.white : Colors.black,
                      backgroundColor: isBookingSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      fontWeight: isBookingSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      onPressed: () {
                        setState(() => isBookingSelected = true);
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomPrimaryButton(
                      title: 'Announcement',
                      defaultColor:
                          !isBookingSelected ? Colors.white : Colors.black,
                      backgroundColor: !isBookingSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      fontWeight: !isBookingSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      onPressed: () {
                        setState(() => isBookingSelected = false);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (isBookingSelected)
              Expanded(
                child: bookingList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: bookingList.length,
                        itemBuilder: (context, index) {
                          final item = bookingList[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/rent1.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              item['name']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item['subtitle']!),
                            trailing: Text(item['time']!),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ChatView()),
                              );
                            },
                          );
                        },
                      ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Sub-filter chips
                    _buildAnnouncementFilterChips(),
                    // Announcement list
                    Expanded(
                      child: announcementList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: announcementList.length,
                              itemBuilder: (context, index) {
                                final item = announcementList[index];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Divider(
                                      height: 1.5,
                                      thickness: 2,
                                      color: Colors.grey.shade200,
                                      indent: 16.w,
                                      endIndent: 16.w,
                                    ),
                                    _buildAnnouncementItem(item, index),
                                    if (index == announcementList.length - 1)
                                      Divider(
                                        height: 1.5,
                                        thickness: 2,
                                        color: Colors.grey.shade200,
                                        indent: 16.w,
                                        endIndent: 16.w,
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Announcement sub-filter chips ───
  Widget _buildAnnouncementFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: List.generate(_announcementFilters.length, (index) {
          final isSelected = _selectedAnnouncementFilter == index;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedAnnouncementFilter = index),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _announcementFilters[index],
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Announcement list item ───
  Widget _buildAnnouncementItem(Map<String, dynamic> item, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatView()),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Property image (circular)
            Container(
              width: 60.w,
              height: 60.w,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  item['propertyImage'] as String,
                  width: 60.w,
                  height: 60.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['propertyType'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if ((item['listingType'] as String).isNotEmpty) ...[
                        Text(
                          item['listingType'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        item['forType'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        'AED ',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        item['price'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        ' yearly',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Avatar with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      item['avatar'] as String,
                      width: 46.w,
                      height: 46.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if ((item['badgeCount'] as int) > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Center(
                        child: Text(
                          '${item['badgeCount']}',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.info_outline, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No data found",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
