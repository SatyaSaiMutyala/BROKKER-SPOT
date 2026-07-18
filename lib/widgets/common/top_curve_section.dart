import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopCurveSection extends StatelessWidget {
  final VoidCallback onBack;
  final double? sectionHeight;
  final double? curveTop;
  final double? curveRight;
  final double? curveWidth;
  final double? backButtonTop;

  const TopCurveSection({
    super.key,
    required this.onBack,
    this.sectionHeight,
    this.curveTop,
    this.curveRight,
    this.curveWidth,
    this.backButtonTop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backIconColor = isDark ? Colors.white : Colors.black87;
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: (sectionHeight ?? 220).h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: (curveTop ?? -100).h,
            right: (curveRight ?? -10).w,
            child: Image.asset(
              'assets/images/top_curve2.png',
              width: (curveWidth ?? 300).w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: backButtonTop ?? (topPadding + 10.h),
            left: 20.w,
            child: CustomBackButton(
              isDark: isDark,
              iconColor: backIconColor,
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
