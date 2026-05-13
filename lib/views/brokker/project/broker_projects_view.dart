import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/projects/premium_lock_banner.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:get/get.dart';

class BrokerProjectsView extends StatefulWidget {
  const BrokerProjectsView({super.key});

  @override
  State<BrokerProjectsView> createState() => _BrokerProjectsViewState();
}

class _BrokerProjectsViewState extends State<BrokerProjectsView> {
  final _repo = AnnouncementRepository();
  List<AnnouncementModel> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchAllAnnouncements();
      if (mounted)
        setState(() {
          _announcements = result.items;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'Projects'),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
      return Center(
        child: Text('No announcements',
            style: GoogleFonts.inter(
                fontSize: 14.sp, color: Colors.grey.shade400)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildSectionHeader(
                'Announcement', '${_announcements.length} announcements'),
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
