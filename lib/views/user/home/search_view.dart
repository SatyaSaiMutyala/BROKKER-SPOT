import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
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

  static const _propertyTypes = [
    'Apartment',
    'Villa',
    'Studio',
    'Penthouse',
    'Townhouse',
    'Office',
  ];

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
      list =
          list.where((a) => a.listingType == _selectedListingType).toList();
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
            _buildHeader(theme, isDark),
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
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // ── Search bar + filter button ──────────────────────────────────
            _buildSearchRow(theme, isDark),
            SizedBox(height: 10.h),

            // ── Filter chips ────────────────────────────────────────────────
            _buildFilterChips(theme, isDark),
            SizedBox(height: 12.h),

            // ── Results list ────────────────────────────────────────────────
            Expanded(child: _buildResults(isDark)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF2F2F2),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 17.w),
          Text(
            'Search',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search input + filter icon ─────────────────────────────────────────────

  Widget _buildSearchRow(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          // Search field — gold border
          Expanded(
            child: Container(
              height: 45.h,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border:
                    Border.all(color: AppColors.primary, width: 1),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12.w),
                  Image.asset(
                    'assets/images/search_icon.png',
                    width: 18.w,
                    height: 18.w,
                    color: AppColors.primary,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'City, Area or Building...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
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
          SizedBox(width: 6.w),
          // Filter button — gold border
          Container(
            width: 45.w,
            height: 45.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/filter_icon.png',
                width: 22.w,
                height: 22.w,
                color: AppColors.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips: listing type + property types ────────────────────────────

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    final listingLabel = _selectedListingType == null
        ? 'All'
        : _selectedListingType == 'Sell'
            ? 'Buy'
            : 'Rent';

    return SizedBox(
      height: 39.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _chip(
            label: listingLabel,
            isSelected: _selectedListingType != null,
            isDark: isDark,
            hasDropdown: true,
            onTap: () => setState(() {
              if (_selectedListingType == null) {
                _selectedListingType = 'Sell';
              } else if (_selectedListingType == 'Sell') {
                _selectedListingType = 'Rent';
              } else {
                _selectedListingType = null;
              }
            }),
          ),
          ..._propertyTypes.map((type) {
            final isSelected = _selectedPropertyType == type;
            return Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _chip(
                label: type,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => setState(() {
                  _selectedPropertyType = isSelected ? null : type;
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool hasDropdown = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.black87,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            if (hasDropdown) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14.sp,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.black87,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

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
    final color =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;
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
