import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/announcements/my_announcements_tab_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationScreen extends StatefulWidget {
  final bool isAnnouncement;
  const VerificationScreen({super.key, this.isAnnouncement = false});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (widget.isAnnouncement) {
        // Clear entire stack, put DashboardView(AccountTab) at bottom
        // with no transition, then push MyAnnouncementsTabView on top.
        // Back from MyAnnouncementsTabView will then land on AccountView.
        Get.offAll(
          () => const DashboardView(initialIndex: 3),
          transition: Transition.noTransition,
          duration: Duration.zero,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to(() => const MyAnnouncementsTabView());
        });
      } else {
        Get.offAll(() => BrokerDashBoardView());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
                    color: Colors.black87,
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
                      text: ' shortly, please wait for a few minutes while we are verifying your announcement.',
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
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
