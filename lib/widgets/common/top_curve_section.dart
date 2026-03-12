
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
            top: (backButtonTop ?? 20).h,
            left: 20.w,
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
