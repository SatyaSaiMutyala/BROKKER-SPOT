import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class TabToggle extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const TabToggle({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 6.w : 0,
                right: index < tabs.length - 1 ? 6.w : 0,
              ),
              child: GestureDetector(
                onTap: () => onTabChanged(index),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.goldAccent : Colors.black26,
                    borderRadius: BorderRadius.circular(26.r),
                    border: Border.all(
                      color: isSelected ? AppColors.goldAccent : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
