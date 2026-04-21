import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';

class MyAnnouncementsTabView extends StatefulWidget {
  const MyAnnouncementsTabView({super.key});

  @override
  State<MyAnnouncementsTabView> createState() => _MyAnnouncementsTabViewState();
}

class _MyAnnouncementsTabViewState extends State<MyAnnouncementsTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = ['All', 'Active', 'Pending', 'Rejected', 'Draft'];

  final _allAnnouncements = _mockAnnouncements();

  List<AnnouncementModel> get _filtered {
    final tab = _tabs[_tabController.index];
    if (tab == 'All') return _allAnnouncements;
    return _allAnnouncements
        .where((a) => a.status?.toLowerCase() == tab.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'ANNOUNCEMENTS',
              showBackButton: true,
              trailing: GestureDetector(
                onTap: () => Get.to(() => const CreateAnnouncementView()),
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),

            // ── Tab bar ──
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isSelected = _tabController.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(i),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.primary, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _tabs[i],
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── List ──
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No announcements',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, color: Colors.grey.shade400),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _filtered.length,
                      itemBuilder: (_, index) {
                        final a = _filtered[index];
                        return _CardWithStatusBadge(
                          announcement: a,
                          index: index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static List<AnnouncementModel> _mockAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        ownerName: 'Rachid',
        listingType: 'Rent',
        price: 3740000,
        propertyName: 'Apartment',
        bedrooms: 2,
        sqft: 815,
        location: 'DAMAC Sun City, Dubailand, Dubai',
        timeAgo: '2 Days ago',
        isWishlisted: false,
        status: 'Active',
      ),
      AnnouncementModel(
        id: '2',
        ownerName: 'Rachid',
        listingType: 'Sell',
        price: 1125000,
        propertyName: 'Villa',
        bedrooms: 2,
        sqft: 815,
        location: 'DAMAC Sun City, Dubailand, Dubai',
        timeAgo: '5 Days ago',
        isWishlisted: false,
        status: 'Rejected',
      ),
      AnnouncementModel(
        id: '3',
        ownerName: 'Rachid',
        listingType: 'Rent',
        price: 2500000,
        propertyName: 'Studio',
        bedrooms: 1,
        sqft: 600,
        location: 'Downtown Dubai',
        timeAgo: '1 Day ago',
        isWishlisted: false,
        status: 'Pending',
      ),
      AnnouncementModel(
        id: '4',
        ownerName: 'Rachid',
        listingType: 'Sell',
        price: 980000,
        propertyName: 'Office Space',
        bedrooms: 0,
        sqft: 1200,
        location: 'Business Bay, Dubai',
        timeAgo: '3 Days ago',
        isWishlisted: false,
        status: 'Draft',
      ),
    ];
  }
}

class _CardWithStatusBadge extends StatelessWidget {
  final AnnouncementModel announcement;
  final int index;

  const _CardWithStatusBadge({required this.announcement, required this.index});

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':   return Colors.green.shade500;
      case 'rejected': return Colors.red.shade500;
      case 'pending':  return Colors.orange.shade500;
      case 'draft':    return Colors.grey.shade500;
      default:         return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnnouncementPropertyCard(
          announcement: announcement,
          index: index,
          showWishlist: false,
          showActionButtons: false,
          showBrokerProfiles: true,
          squareRightSide: false,
          onTap: () => Get.to(() => AnnouncementDetailView(announcement: announcement)),
          onLocationTap: () {},
        ),
        // Status badge – flush to card's right edge
        Positioned(
          top: 24.h,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.only(left: 12.w, right: 10.w, top: 5.h, bottom: 5.h),
            decoration: BoxDecoration(
              color: _statusColor(announcement.status),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                bottomLeft: Radius.circular(20.r),
              ),
            ),
            child: Text(
              announcement.status ?? '',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
