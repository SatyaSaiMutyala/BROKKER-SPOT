import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_list_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/announcements/announcement_property_card.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  final _controller = AnnouncementListController.to;

  @override
  void initState() {
    super.initState();
    // Loads only if not cached yet — re-entering this tab won't re-hit the API.
    _controller.loadAll();
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
              leading: GestureDetector(
                onTap: () {},
                child:
                    Icon(Icons.search, size: 36.sp, color: AppColors.primary),
              ),
              trailing: GestureDetector(
                onTap: () => Get.to(() => const CreateAnnouncementView()),
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),
            Expanded(
              child: Obx(() {
                // Full-screen spinner only on the very first load (nothing cached yet).
                // During pull-to-refresh the list stays visible with its own indicator.
                if (_controller.isLoadingAll.value &&
                    _controller.allAnnouncements.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _controller.loadAll(force: true),
                  child: _buildList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    // Error state — still scrollable so pull-to-refresh works.
    if (_controller.allError.value != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
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
                SizedBox(height: 12.h),
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
    // Empty state — scrollable so the user can still pull to refresh.
    if (_controller.allAnnouncements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Text(
              'No announcements yet',
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
      itemCount: _controller.allAnnouncements.length,
      itemBuilder: (_, index) {
        final a = _controller.allAnnouncements[index];
        return AnnouncementPropertyCard(
          announcement: a,
          index: index,
          onTap: () async {
            await Get.to(() => AnnouncementDetailView(
                  announcement: a,
                  isOwner: false,
                ));
          },
          onWishlistTap: () {},
          onLocationTap: () {},
        );
      },
    );
  }
}
