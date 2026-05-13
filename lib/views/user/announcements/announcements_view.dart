import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
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
  late final AnnouncementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AnnouncementController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllAnnouncements();
    });
  }

  @override
  void dispose() {
    Get.delete<AnnouncementController>();
    super.dispose();
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
                child: Icon(Icons.search, size: 36.sp, color: AppColors.primary),
              ),
              trailing: GestureDetector(
                onTap: () async {
                  await Get.to(() => const CreateAnnouncementView());
                  _controller.fetchAnnouncements();
                },
                child: Image.asset('assets/images/home_add_icon.png',
                    width: 50.w, height: 50.w),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.allAnnouncementsError.value != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.allAnnouncementsError.value!,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        TextButton(
                          onPressed: _controller.fetchAllAnnouncements,
                          child: Text('Retry',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }
                if (_controller.allAnnouncements.isEmpty) {
                  return Center(
                    child: Text(
                      'No announcements yet',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.grey.shade400),
                    ),
                  );
                }
                return ListView.builder(
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
              }),
            ),
          ],
        ),
      ),
    );
  }
}
