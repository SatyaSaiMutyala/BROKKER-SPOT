import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_model.dart';

class ProjectGridCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onTap;

  const ProjectGridCard({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with overlays
          _buildImage(),
          SizedBox(height: 6.h),
          // Name
          Text(
            project.name ?? '',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          // Location
          Text(
            project.location ?? '',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        height: 120.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder image
            Container(
              color: Colors.grey.shade300,
              child: Icon(
                Icons.apartment,
                size: 36.sp,
                color: Colors.grey.shade400,
              ),
            ),
            // Brokerage banner (top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldAccent.withValues(alpha: 0.85),
                      AppColors.goldAccent.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Text(
                  '€ ${_formatAmount(project.brokerage ?? 0)} Brokerage',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Bottom info bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    Text(
                      '€ ${_formatAmount(project.price ?? 0)}',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      width: 1,
                      height: 10.h,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${project.units ?? 0} UNITS',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    String str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(' ');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
