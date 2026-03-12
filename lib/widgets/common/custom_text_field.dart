import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final bool isDark;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.suffixIcon,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onSuffixTap,
    this.onChanged,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textWhite : Colors.black87;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.grey;
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.5)
        : const Color(0xFFB5B5B5);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.primary;

    Widget? suffix;
    if (suffixWidget != null) {
      suffix = suffixWidget;
    } else if (suffixIcon != null) {
      suffix = GestureDetector(
        onTap: onSuffixTap,
        child: Icon(suffixIcon, color: iconColor, size: 22.sp),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: textColor, fontSize: 15.sp,),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: isDark ? 0 : 12.w),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
