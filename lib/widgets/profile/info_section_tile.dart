import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoSectionTile extends StatelessWidget {
  final String title;
  final String content;
  final bool showDivider;

  const InfoSectionTile({
    super.key,
    required this.title,
    required this.content,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        if (showDivider) ...[
          SizedBox(height: 12.h),
          Divider(height: 1.h, color: Colors.grey.shade200),
        ],
      ],
    );
  }
}
