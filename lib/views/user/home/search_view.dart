import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/common/app_search_bar.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchCtrl = TextEditingController();
  final _announcementCtrl = AnnouncementListController.to;

  String? _selectedListingType; // null=all, 'Sell'=Buy, 'Rent'=Rent
  String? _selectedPropertyType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _announcementCtrl.allAnnouncements.isEmpty) {
        _announcementCtrl.loadAll();
      }
    });
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AnnouncementModel> _filtered(List<AnnouncementModel> all) {
    var list = all;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) {
        return (a.location?.toLowerCase().contains(q) ?? false) ||
            (a.propertyName?.toLowerCase().contains(q) ?? false) ||
            (a.propertyType?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_selectedListingType != null) {
      list = list.where((a) => a.listingType == _selectedListingType).toList();
    }
    if (_selectedPropertyType != null) {
      list = list
          .where((a) =>
              a.propertyType?.toLowerCase() ==
              _selectedPropertyType!.toLowerCase())
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            const CustomHeader(title: 'Search', showBackButton: true),
            SizedBox(height: 14.h),

            // ── Banner image ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 11.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.asset(
                  'assets/images/banner-img.png',
                  width: double.infinity,
                  height: 101.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 101.h,
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // ── Search bar + filter button ──────────────────────────────────
            AppSearchBar(controller: _searchCtrl),
            SizedBox(height: 12.h),

            // ── Filter chips ────────────────────────────────────────────────
            AnnouncementFilterBar(
              selectedListingType: _selectedListingType,
              selectedPropertyType: _selectedPropertyType,
              onListingTypeChanged: (val) =>
                  setState(() => _selectedListingType = val),
              onPropertyTypeChanged: (type) =>
                  setState(() => _selectedPropertyType = type),
            ),
            SizedBox(height: 12.h),

            // ── Results list ────────────────────────────────────────────────
            Expanded(child: _buildResults(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return Obx(() {
      final all = _announcementCtrl.allAnnouncements.toList();
      if (_announcementCtrl.isLoadingAll.value && all.isEmpty) {
        return _buildShimmer(isDark);
      }
      final items = _filtered(all);
      if (items.isEmpty) {
        return Center(
          child: Text(
            'No results found',
            style: GoogleFonts.poppins(
                fontSize: 14.sp, color: Colors.grey.shade400),
          ),
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, i) {
          final a = items[i];
          return RepaintBoundary(
            child: HomeAnnouncementCard(
              announcement: a,
              index: i,
              cardWidth: 344.w,
              cardHeight: 263.h,
              onTap: () => Get.to(() => AnnouncementDetailView(
                    announcement: a,
                    isOwner: false,
                  )),
            ),
          );
        },
      );
    });
  }

  Widget _buildShimmer(bool isDark) {
    final color = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => Container(
        height: 263.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }
}
