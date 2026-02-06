import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class AnnouncementCard extends StatelessWidget {
  final String? imageUrl;
  final String badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    this.imageUrl,
    required this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = badgeColor ?? AppColors.goldAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110.w,
        height: 140.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.grey.shade200,
          image: imageUrl != null && imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Placeholder icon when no image
            if (imageUrl == null || imageUrl!.isEmpty)
              Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 32.sp,
                  color: Colors.grey.shade400,
                ),
              ),
            // Badge
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
