import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class DealTabToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const DealTabToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 44.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: trackColor,
      ),
      child: Row(
        children: [
          _tab('CURRENT DEALS', 0, isDark),
          _tab('COMPLETED DEALS', 1, isDark),
        ],
      ),
    );
  }

  Widget _tab(String label, int index, bool isDark) {
    final isActive = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
