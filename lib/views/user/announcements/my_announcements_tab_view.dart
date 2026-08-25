import 'dart:math' show pi;
import 'dart:ui' as ui;
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card.dart';
import 'package:brokkerspot/widgets/home/home_announcement_card_shimmer.dart';
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

  final _tabs = [
    'All',
    'Pending',
    'Shared Broker',
    'Rejected',
    'Draft',
    'Live'
  ];

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
      case 5:
        return 4; // Live — published announcements
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
    if (result == true) {
      _controller.loadMine(status: _currentStatus, force: true);
    }
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
                  style: GoogleFonts.poppins(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () =>
                      _controller.loadMine(status: _currentStatus, force: true),
                  child: Text('Retry',
                      style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                  fontSize: 14.sp, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final inactiveTabText =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'My Announcements',
              showBackButton: true,
              trailing: GestureDetector(
                onTap: () => Get.to(() => const CreateAnnouncementView()),
                child: Image.asset(
                  'assets/images/home_add_icon.png',
                  width: 50.w,
                  height: 50.w,
                ),
              ),
            ),

            // ── Tab bar (horizontally scrollable) ────────────────────────────
            Container(
              color: tabBarBg,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isSelected = _tabController.index == i;
                    return GestureDetector(
                      onTap: () => _onTabSelected(i),
                      child: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _tabs[i],
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : inactiveTabText,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
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
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        // These are the account's own listings, so the real cards carry no
        // owner avatar — the placeholder shouldn't either.
        child: HomeAnnouncementCardShimmer(
          cardHeight: 263.h,
          showAvatar: false,
        ),
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

  Color _dotColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green.shade500;
      case 'live':
        return AppColors.primary;
      case 'rejected':
        return Colors.red.shade500;
      case 'submitted':
      case 'pending':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final proposals = a.latestProposals ?? [];
    final count = a.proposalCount ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              HomeAnnouncementCard(
                announcement: a,
                index: index,
                cardWidth: constraints.maxWidth,
                cardHeight: 263.h,
                showAvatar: false,
                onTap: onTap,
              ),

              // ── Status + time pill — above AED text ──────────────────────
              if (a.status != null)
                Positioned(
                  left: 14.w,
                  bottom: 130.h,
                  child: CustomPaint(
                    painter: const _StatusPillPainter(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 12.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dotColor(a.status),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            (a.status ?? '').toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          if (a.timeAgo != null) ...[
                            Text(
                              ' • ',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.white70,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              a.timeAgo!.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFCFCFCF),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Stacked broker avatars + count badge — top right ────────
              if (count > 0)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: _buildBrokerStack(proposals, count),
                ),
            ],
          );
        },
      ),
    );
  }

  // Stacked avatars: up to 4 overlapping circles + count badge at top-right
  Widget _buildBrokerStack(List<ProposalBroker> proposals, int count) {
    const double avatarSize = 42;
    const double step = 5; // only 5px of each back avatar peeks out
    const double badgeSize = 24;
    const double badgeHalf = badgeSize / 2;
    final int n = proposals.length.clamp(1, 4);

    // Total width: main avatar + tiny slivers of back avatars + badge overflow
    final double totalW = avatarSize + (n - 1) * step + badgeHalf;
    // Total height: avatar height + badge overflow at top
    const double totalH = avatarSize + badgeHalf;

    return SizedBox(
      width: totalW.w,
      height: totalH.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render right-to-left so index 0 (main) is on top
          for (int i = n - 1; i >= 0; i--)
            Positioned(
              left: (i * step).w,
              bottom: 0,
              child: _buildSingleAvatar(
                  proposals[i].brokerProfileImage, avatarSize.w),
            ),
          // Count badge — top-right, partially outside the avatar
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: badgeSize.w,
              height: badgeSize.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAvatar(String? imgUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1.5),
        color: const Color(0xFF2A2A2A),
      ),
      child: ClipOval(
        child: imgUrl != null && imgUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF2A2A2A),
        child: Icon(Icons.person, size: 20.sp, color: Colors.white54),
      );
}

class _StatusPillPainter extends CustomPainter {
  const _StatusPillPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Gradient fill
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
        ).createShader(rect),
    );

    // Sweep gradient border highlights at top-left (225°) and bottom-right (45°)
    const peak = Color(0x90FFFFFF);
    const fade = Color(0x00FFFFFF);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        Radius.circular(radius - 0.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = ui.Gradient.sweep(
          center,
          [fade, peak, fade, fade, peak, fade, fade],
          [0.0, 0.125, 0.25, 0.5, 0.625, 0.75, 1.0],
          TileMode.clamp,
          0,
          2 * pi,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _StatusPillPainter old) => false;
}
