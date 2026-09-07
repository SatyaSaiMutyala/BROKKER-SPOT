import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours and small pieces shared by the three contract-cancellation screens,
/// so the flow reads as one thing rather than three separate designs.
class CancelTheme {
  CancelTheme._();

  /// Same green the chat banner uses for a live agreement.
  static const Color green = Color(0xFF159D37);
  static const Color greenDeep = Color(0xFF1B7F3B);

  /// The "pending / act now" amber of the notice pills.
  static const Color amber = Color(0xFFB7791F);
  static const Color amberBg = Color(0xFFFDF6E7);
  static const Color amberBorder = Color(0xFFF2DFB4);

  /// Cancellation red.
  static const Color red = Color(0xFFD64545);
  static const Color redBg = Color(0xFFFDECEC);

  static Color surface(bool isDark) =>
      isDark ? const Color(0xFF15171F) : Colors.white;

  static Color scaffold(bool isDark) =>
      isDark ? const Color(0xFF090B11) : Colors.white;

  static Color hairline(bool isDark) =>
      isDark ? const Color(0xFF262932) : const Color(0xFFEAEAEA);

  static Color title(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF16181F);

  static Color body(bool isDark) =>
      isDark ? Colors.grey.shade400 : const Color(0xFF6B6F7A);

  /// The amber "you can still withdraw" notice used on several screens.
  static Widget notice(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF251F0F) : amberBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3C18) : amberBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.access_time_rounded, size: 16.sp, color: amber),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: isDark ? const Color(0xFFD9BE7C) : amber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width pill button used as the primary action on every screen here.
  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    Color color = greenDeep,
    bool busy = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Label + value row of the contract summary card.
  static Widget detailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: body(isDark)),
          SizedBox(width: 10.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: body(isDark),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: valueColor ?? title(isDark),
                height: 1.4,
              ),
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, size: 17.sp, color: body(isDark)),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
