import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSectionTile extends StatelessWidget {
  final String title;
  final bool isRequired;
  final bool enabled;
  final Widget? leading;
  final Widget? trailing;
  final String? selectedValue;
  final VoidCallback? onTap;

  const FormSectionTile({
    super.key,
    required this.title,
    this.isRequired = false,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.selectedValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = enabled ? Colors.black87 : Colors.grey.shade400;
    final Color iconColor = enabled ? Colors.grey.shade400 : Colors.grey.shade300;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Optional leading (e.g. check icon)
            if (leading != null) ...[
              enabled ? leading! : SizedBox(width: 16.sp, height: 16.sp),
              SizedBox(width: 8.w),
            ],
            // Title with optional asterisk
            RichText(
              text: TextSpan(
                text: title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                children: isRequired
                    ? [
                        TextSpan(
                          text: '*',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: enabled ? Colors.red : Colors.grey.shade400,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
            const Spacer(),
            // Selected value text
            if (selectedValue != null && enabled)
              Text(
                selectedValue!,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            // Trailing widget (chevron or switch)
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 22.sp,
                  color: iconColor,
                ),
          ],
        ),
      ),
    );
  }
}
