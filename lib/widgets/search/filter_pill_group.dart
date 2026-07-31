import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single-select row of rounded pills — the gold-fill segmented control used
/// on the Filter screen for *Property For* (All / Buy / Rent) and the
/// contextual *Property* sub-toggle (Ready / Off Plan, Yearly / Monthly).
///
/// The selected pill fills with [AppColors.primary]; the rest are neutral
/// outlined chips. Set [expand] to stretch the pills to fill the row evenly
/// (used for the 3-up *Property For* row); leave it false to size each pill to
/// its label (used for the 2-up sub-toggle).
class FilterPillGroup extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final bool expand;

  const FilterPillGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final pill = _pill(context, options[i]);
      children.add(expand ? Expanded(child: pill) : pill);
      if (i != options.length - 1) children.add(SizedBox(width: 12.w));
    }
    return Row(
      mainAxisAlignment:
          expand ? MainAxisAlignment.start : MainAxisAlignment.start,
      children: children,
    );
  }

  Widget _pill(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: expand ? 8.w : 22.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF0EEE9),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
      ),
    );
  }
}
