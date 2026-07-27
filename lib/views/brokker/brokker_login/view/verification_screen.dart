import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/services/device_service.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/views/user/announcements/my_announcements_tab_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationScreen extends StatefulWidget {
  final bool isAnnouncement;
  final bool fromBroker;
  const VerificationScreen({
    super.key,
    this.isAnnouncement = false,
    this.fromBroker = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  void initState() {
    super.initState();
    // The announcement variant is a terminal screen the user dismisses via its
    // own buttons — only the account-verification variant auto-advances.
    if (widget.isAnnouncement) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      DeviceService.registerDevice();
      Get.offAll(() => BrokerDashBoardView(showLocationPicker: true));
    });
  }

  void _goToMyAnnouncements() {
    if (widget.fromBroker) {
      // Broker dashboard's Announcement tab.
      Get.offAll(
        () => BrokerDashBoardView(initialIndex: 1),
        transition: Transition.noTransition,
        duration: Duration.zero,
      );
      return;
    }

    Get.offAll(
      () => const DashboardView(initialIndex: 3),
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => const MyAnnouncementsTabView());
    });
  }

  void _startNewAnnouncement() {
    Get.offAll(
      () => widget.fromBroker
          ? BrokerDashBoardView(initialIndex: 0)
          : const DashboardView(initialIndex: 0),
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => CreateAnnouncementView(fromBroker: widget.fromBroker));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      // Intercept the system back / swipe so it starts a new announcement
      // instead of popping back onto the submitted form.
      canPop: !widget.isAnnouncement,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.isAnnouncement) _startNewAnnouncement();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = MediaQuery.of(context).size.width * 0.55;
                          return Image.asset(
                            'assets/images/wait_image.png',
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (widget.isAnnouncement)
                    Column(
                      children: [
                        Text(
                          'Congratulations!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB8963E),
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _bulletPoint(
                          '1. Your announcement is now visible to the Brokker Community.',
                          textColor,
                        ),
                        SizedBox(height: 10.h),
                        _bulletPoint(
                          '2. Interested brokers may contact you for approval to share your announcement with their clients.',
                          textColor,
                        ),
                      ],
                    )
                  else
                    Text(
                      'Your Account Is In Under Verification Process, Please Wait We Will Activate Your Account Soon.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  if (widget.isAnnouncement) ...[
                    SizedBox(height: 32.h),
                    _actionButton(
                      label: 'Continue',
                      filled: true,
                      onTap: _goToMyAnnouncements,
                    ),
                  ],
                ],
              ),
            ),
            // Last in the Stack so it paints and hit-tests above the centred
            // content, which fills the whole area.
            if (widget.isAnnouncement)
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _startNewAnnouncement,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100,
                        ),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 14.sp, color: textColor),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bulletPoint(String text, Color textColor) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.6,
      ),
    );
  }

  /// Filled = primary action, outlined = secondary. Both read correctly in light
  /// and dark, so no theme flag is needed.
  Widget _actionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          border: filled ? null : Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(38.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
