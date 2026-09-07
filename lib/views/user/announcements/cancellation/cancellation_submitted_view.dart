import 'dart:math' as math;

import 'package:brokkerspot/views/user/announcements/cancellation/cancellation_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Confirmation shown straight after the server accepts a cancellation
/// request — the contract is now at status 5 with the 48-hour clock running.
///
/// [onGoToContract] pops this screen and opens the contract details, where the
/// countdown and the withdraw button live. Close just pops back to the chat.
class CancellationSubmittedView extends StatelessWidget {
  final VoidCallback onGoToContract;

  const CancellationSubmittedView({super.key, required this.onGoToContract});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CancelTheme.scaffold(isDark),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 26.w),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const _SuccessMark(),
              SizedBox(height: 34.h),
              Text(
                'Cancellation request submitted',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: CancelTheme.title(isDark),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Your contract cancellation request has been submitted. '
                'The contract will remain active for the next 48 hours.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  height: 1.6,
                  color: CancelTheme.body(isDark),
                ),
              ),
              SizedBox(height: 24.h),
              CancelTheme.notice(
                'You can withdraw the cancellation request at any time '
                'during this period.',
                isDark,
              ),
              const Spacer(flex: 4),
              CancelTheme.primaryButton(
                label: 'Go to Contract',
                onPressed: onGoToContract,
              ),
              SizedBox(height: 6.h),
              TextButton(
                onPressed: Get.back,
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: CancelTheme.body(isDark),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// The green tick, ringed by the scattered confetti dots from the design.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  /// Dots as (angle in degrees, distance from centre as a fraction of the
  /// radius, diameter, colour) — placed rather than randomised so the mark
  /// looks identical on every build.
  static const List<(double, double, double, Color)> _dots = [
    (-100, 1.34, 7, Color(0xFFE8B84B)),
    (-38, 1.30, 8, Color(0xFF4B9BE8)),
    (18, 1.42, 6, Color(0xFFE85B5B)),
    (74, 1.28, 9, Color(0xFF6FCF7B)),
    (128, 1.38, 6, Color(0xFFE8B84B)),
    (168, 1.26, 8, Color(0xFFE85B5B)),
    (212, 1.44, 5, Color(0xFF4B9BE8)),
    (256, 1.30, 7, Color(0xFF6FCF7B)),
  ];

  @override
  Widget build(BuildContext context) {
    final ring = 108.w;
    final box = ring * 1.85;

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (angle, distance, size, color) in _dots)
            Align(
              alignment: Alignment(
                math.cos(angle * math.pi / 180) * distance * 0.5,
                math.sin(angle * math.pi / 180) * distance * 0.5,
              ),
              child: Container(
                width: size.w,
                height: size.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          Container(
            width: ring,
            height: ring,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6EC),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: ring * 0.62,
              height: ring * 0.62,
              decoration: const BoxDecoration(
                color: CancelTheme.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: (ring * 0.36).sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
