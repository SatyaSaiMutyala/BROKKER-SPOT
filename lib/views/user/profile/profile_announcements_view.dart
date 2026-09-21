import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/profile/controller/user_profile_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/profile/profile_announcement_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every listing on someone's profile — what "More" opens.
///
/// Reads the same controller the profile screen already filled, so the
/// pictures are on screen the moment it opens rather than fetched again.
class ProfileAnnouncementsView extends StatelessWidget {
  final UserProfileController controller;
  final String title;

  const ProfileAnnouncementsView({
    super.key,
    required this.controller,
    this.title = 'All Announcement',
  });

  static Future<void> open(UserProfileController controller, String title) =>
      Get.to(
        () => ProfileAnnouncementsView(controller: controller, title: title),
        preventDuplicates: false,
      )!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(title: title, showBackButton: true),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadAnnouncements,
                child: Obx(() {
                  final List<AnnouncementModel> items =
                      controller.announcements;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
                    children: [
                      if (items.isEmpty &&
                          controller.announcementsLoading.value)
                        ProfileAnnouncementGridShimmer(
                            isDark: isDark, itemCount: 9)
                      else if (items.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 60.h),
                          child: Text(
                            'No announcements yet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        )
                      else
                        ProfileAnnouncementGrid(
                          announcements: items,
                          isDark: isDark,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
