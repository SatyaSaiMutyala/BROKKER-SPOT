import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

class BrokerProjectsView extends StatefulWidget {
  const BrokerProjectsView({super.key});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerShimmerList extends StatelessWidget {
  const _BrokerShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => const _BrokerShimmerCard(),
      ),
    );
  }
}

class _BrokerShimmerCard extends StatelessWidget {
  const _BrokerShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner row
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 100.w, height: 10.h, color: Colors.white),
                  SizedBox(height: 4.h),
                  Container(
                      width: 60.w, height: 8.h, color: Colors.white),
                ],
              ),
              const Spacer(),
              Container(
                  width: 60.w,
                  height: 22.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  )),
            ],
          ),
          SizedBox(height: 8.h),
          // Image area
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 10.h),
          // Price row
          Container(width: 120.w, height: 14.h, color: Colors.white),
          SizedBox(height: 6.h),
          // Property name
          Container(width: 200.w, height: 12.h, color: Colors.white),
          SizedBox(height: 6.h),
          // Bedroom / sqft row
          Row(
            children: [
              Container(width: 50.w, height: 10.h, color: Colors.white),
              SizedBox(width: 12.w),
              Container(width: 50.w, height: 10.h, color: Colors.white),
            ],
          ),
          SizedBox(height: 6.h),
          Divider(color: Colors.grey.shade200, thickness: 1),
          SizedBox(height: 4.h),
          // Location row
          Container(width: 160.w, height: 10.h, color: Colors.white),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  final _repo = AnnouncementRepository();

  // Static cache — survives navigation, cleared only on pull-to-refresh
  static List<AnnouncementModel>? _cache;

  List<AnnouncementModel> _announcements = [];
  bool _loading = false;
  String? _error;
  int _selectedTab = 0;
  final _tabs = const ['User Announcement', 'Your Announcement'];

  @override
  void initState() {
    super.initState();
    if (_cache != null) {
      // Show cached data instantly — no API call
      _announcements = _cache!;
    } else {
      _fetchAnnouncements();
    }
  }

  Future<void> _fetchAnnouncements({bool isRefresh = false}) async {
    if (isRefresh) _cache = null;
    setState(() {
      _loading = _announcements.isEmpty;
      _error = null;
    });
    try {
      final result = await _repo.fetchAllAnnouncements();
      if (mounted) {
        _cache = result.items;
        setState(() {
          _announcements = result.items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _announcements.isEmpty ? e.toString() : null;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Projects',
              trailing: GestureDetector(
                onTap: () async {
                  await Get.to(
                      () => const CreateAnnouncementView(fromBroker: true));
                  _fetchAnnouncements(isRefresh: true);
                },
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),
            _buildTabBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _BrokerShimmerList();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: _fetchAnnouncements,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
    if (_announcements.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchAnnouncements(isRefresh: true),
        child: ListView(
          children: [
            SizedBox(height: 200.h),
            Center(
              child: Text('No announcements',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade400)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchAnnouncements(isRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: _buildSectionHeader(
                  _tabs[_selectedTab], '${_announcements.length} announcements'),
            ),
            ..._announcements.asMap().entries.map(
                  (entry) => AnnouncementPropertyCard(
                    announcement: entry.value,
                    index: entry.key,
                    showWishlist: false,
                    showActionButtons: false,
                    ownerRowAboveImage: true,
                    onTap: () => Get.to(() =>
                        BrokerAnnouncementDetailView(announcement: entry.value)),
                  ),
                ),
            SizedBox(height: 8.h),
            PremiumLockBanner(onTap: () {}),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                padding: EdgeInsets.symmetric(vertical: 7.h),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
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
              color: Colors.black),
        ),
        SizedBox(width: 6.w),
        Container(
          width: 18.w,
          height: 18.w,
          decoration: const BoxDecoration(
              color: AppColors.goldAccent, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('!',
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        const Spacer(),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 11.sp, color: Colors.grey.shade500)),
      ],
    );
  }
}
