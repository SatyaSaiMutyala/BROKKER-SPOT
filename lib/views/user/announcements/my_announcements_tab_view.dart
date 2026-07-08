import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
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
  final _controller = AnnouncementListController.to;

  final _tabs = ['All', 'Pending', 'Active', 'Rejected', 'Draft'];

  int? _statusForTab(int i) {
    switch (i) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 0;
      default:
        return null;
    }
  }

  int? get _currentStatus => _statusForTab(_tabController.index);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _controller.loadMine(force: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int i) {
    _tabController.animateTo(i);
    _controller.loadMine(status: _statusForTab(i));
  }

  Future<void> _openDetail(AnnouncementModel a) async {
    final result = await Get.to(() => AnnouncementDetailView(announcement: a));
    if (result == true)
      _controller.loadMine(status: _currentStatus, force: true);
  }

  Widget _buildList() {
    if (_controller.myError.value != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.myError.value!,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () =>
                      _controller.loadMine(status: _currentStatus, force: true),
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
    final list = _controller.myAnnouncements;
    if (list.isEmpty) {
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
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: list.length,
      itemBuilder: (_, index) {
        final a = list[index];
        return _CardWithStatusBadge(
          announcement: a,
          index: index,
          onTap: () => _openDetail(a),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'ANNOUNCEMENTS',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const CreateAnnouncementView()),
            child: Image.asset('assets/images/home_add_icon.png',
                width: 50.w, height: 50.w),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final inactiveTabText =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),

            // ── Tab bar ──────────────────────────────────────────────────────
            Container(
              color: tabBarBg,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isSelected = _tabController.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabSelected(i),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
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
                            color: isSelected ? Colors.white : inactiveTabText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (_controller.isLoadingMine.value &&
                    _controller.myAnnouncements.isEmpty) {
                  return const _ShimmerCardList();
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      _controller.loadMine(status: _currentStatus, force: true),
                  child: _buildList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCardList extends StatelessWidget {
  const _ShimmerCardList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: 4,
        itemBuilder: (_, __) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200.h,
            width: double.infinity,
            color: blockColor,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 120.w, height: 16.h, color: blockColor),
                    const Spacer(),
                    Container(width: 60.w, height: 14.h, color: blockColor),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(width: 180.w, height: 16.h, color: blockColor),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Container(width: 90.w, height: 14.h, color: blockColor),
                    SizedBox(width: 20.w),
                    Container(width: 80.w, height: 14.h, color: blockColor),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark
                        ? const Color(0xFF2E2E2E)
                        : Colors.grey.shade200),
                SizedBox(height: 10.h),
                Container(width: 150.w, height: 14.h, color: blockColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardWithStatusBadge extends StatelessWidget {
  final AnnouncementModel announcement;
  final int index;
  final VoidCallback onTap;

  const _CardWithStatusBadge({
    required this.announcement,
    required this.index,
    required this.onTap,
  });

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green.shade500;
      case 'rejected':
        return Colors.red.shade500;
      case 'submitted':
        return Colors.orange.shade500;
      case 'draft':
        return Colors.grey.shade500;
      default:
        return Colors.grey.shade500;
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
          onTap: onTap,
          onLocationTap: () {},
        ),
        Positioned(
          top: 24.h,
          right: 16.w,
          child: Container(
            padding:
                EdgeInsets.only(left: 12.w, right: 10.w, top: 5.h, bottom: 5.h),
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
