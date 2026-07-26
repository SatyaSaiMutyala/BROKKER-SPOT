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

  /// Continue → the announcement list. Same destinations this screen used to
  /// jump to on its own.
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
    // Clear the stack, seat DashboardView(Account tab) at the bottom, then push
    // the list on top — so Back from the list lands on Account, not here.
    Get.offAll(
      () => const DashboardView(initialIndex: 3),
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => const MyAnnouncementsTabView());
    });
  }

  /// Back to Home → bottom-nav index 0 on whichever side the user came from.
  void _goHome() {
    Get.offAll(
      () => widget.fromBroker
          ? BrokerDashBoardView(initialIndex: 0)
          : const DashboardView(initialIndex: 0),
      transition: Transition.noTransition,
      duration: Duration.zero,
    );
  }

  /// Back icon / system back → start a brand-new announcement.
  ///
  /// The stack is cleared first because the CreateAnnouncementView we arrived
  /// from still holds its completed step state; returning to it would show a
  /// finished form for an announcement already submitted. Home is seated
  /// underneath so Back from the new form has somewhere to go instead of
  /// leaving the app.
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
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'In Process to be live on '),
                          TextSpan(
                            text: 'broker platform',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB8963E),
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' shortly, please wait for a few minutes while we are verifying your announcement.',
                          ),
                        ],
                      ),
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
                    SizedBox(height: 12.h),
                    _actionButton(
                      label: 'Back to Home',
                      filled: false,
                      onTap: _goHome,
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
