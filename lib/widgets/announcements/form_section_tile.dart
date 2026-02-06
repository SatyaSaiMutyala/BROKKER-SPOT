import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class FormSectionTile extends StatelessWidget {
  final String title;
  final bool isRequired;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FormSectionTile({
    super.key,
    required this.title,
    this.isRequired = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Title with optional asterisk
            RichText(
              text: TextSpan(
                text: title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                children: isRequired
                    ? [
                        TextSpan(
                          text: '*',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
            const Spacer(),
            // Trailing widget (chevron or switch)
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 22.sp,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
    );
  }
}
