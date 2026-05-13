import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
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
  late AnnouncementController _controller;

  final _tabs = ['All', 'Draft', 'Submitted', 'Approved', 'Rejected'];

  List<AnnouncementModel> get _filtered {
    final tab = _tabs[_tabController.index];
    if (tab == 'All') return _controller.announcements;
    return _controller.announcements
        .where((a) => a.status?.toLowerCase() == tab.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _controller = Get.put(AnnouncementController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAnnouncements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<AnnouncementController>();
    super.dispose();
  }

  Future<void> _openDetail(AnnouncementModel a) async {
    final result = await Get.to(() => AnnouncementDetailView(announcement: a));
    // Refresh list if detail view deleted or edited the announcement
    if (result == true) _controller.fetchAnnouncements();
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
                onTap: () async {
                  await Get.to(() => const CreateAnnouncementView());
                  _controller.fetchAnnouncements();
                },
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
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
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
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.errorMessage.value != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.errorMessage.value!,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        TextButton(
                          onPressed: _controller.fetchAnnouncements,
                          child: Text('Retry',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }
                final list = _filtered;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No announcements',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.grey.shade400),
                    ),
                  );
                }
                return ListView.builder(
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
              }),
            ),
          ],
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
