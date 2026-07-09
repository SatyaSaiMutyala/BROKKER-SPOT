import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/views/user/home/search_view.dart';
import 'package:brokkerspot/widgets/announcements/announcement_filter_bar.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  final _controller = AnnouncementListController.to;
  final _scrollController = ScrollController();

  String? _selectedListingType; // null = all, 'Sell' = Buy, 'Rent' = Rent
  String? _selectedPropertyType; // null = all

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.loadAll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && _controller.hasMoreAll) {
      _controller.loadMoreAll();
    }
  }

  List<AnnouncementModel> _filtered(List<AnnouncementModel> all) {
    var list = all;
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
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F5F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: 12.h),
            _buildFilterBar(theme),
            SizedBox(height: 12.h),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 0),
      child: Row(
        children: [
          Text(
            'Announcements',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.to(() => const SearchView()),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 35.w,
              height: 35.w,
              child: Image.asset(
                'assets/images/search_icon.png',
                width: 35.w,
                height: 35.w,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────────

  Widget _buildFilterBar(ThemeData theme) {
    return AnnouncementFilterBar(
      selectedListingType: _selectedListingType,
      selectedPropertyType: _selectedPropertyType,
      onListingTap: () => setState(() {
        if (_selectedListingType == null) {
          _selectedListingType = 'Sell';
        } else if (_selectedListingType == 'Sell') {
          _selectedListingType = 'Rent';
        } else {
          _selectedListingType = null;
        }
      }),
      onPropertyTypeChanged: (type) =>
          setState(() => _selectedPropertyType = type),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody(ThemeData theme) {
    return Obx(() {
      if (_controller.isLoadingAll.value &&
          _controller.allAnnouncements.isEmpty) {
        return _buildShimmer();
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _controller.loadAll(force: true),
        child: _buildList(theme),
      );
    });
  }

  Widget _buildList(ThemeData theme) {
    final all = _controller.allAnnouncements.toList();

    if (_controller.allError.value != null && all.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.allError.value!,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => _controller.loadAll(force: true),
                  child: Text('Retry',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final items = _filtered(all);

    if (items.isEmpty && !_controller.isLoadingAll.value) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Text(
              'No announcements',
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }

    final loadingMore = _controller.isLoadingMoreAll.value;
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: items.length + (loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, index) {
        if (index >= items.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final a = items[index];
        return RepaintBoundary(
          child: HomeAnnouncementCard(
            announcement: a,
            index: index,
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
  }

  Widget _buildShimmer() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      itemCount: 2,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => Container(
        width: double.infinity,
        height: 263.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
    );
  }
}
