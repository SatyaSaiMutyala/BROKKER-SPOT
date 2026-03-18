import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class HomeAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;
  final bool showAvatar;
  final int index;

  const HomeAnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.showAvatar = true,
    this.index = 0,
  });

  static const List<String> _avatarAssets = [
    'assets/images/announcement_proffile_icon.png',
    'assets/images/story1.png',
    'assets/images/story2.png',
  ];

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 330.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(a),
              _buildInfoSection(a),
              
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildImageSection(AnnouncementModel a) {
    return SizedBox(
      height: 215.h,
      child: Stack(
        children: [
          // Property image - full height
          Positioned.fill(
            bottom: 22.h,
            child: (a.imageUrls != null && a.imageUrls!.isNotEmpty)
                ? Image.asset(
                    a.imageUrls!.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          // "For Rent" badge - top left
          if (a.listingType != null)
            Positioned(
              top: 26.h,
              left: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                ),
                child: Text(
                  a.listingType!,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Owner avatar - bottom left
          if (showAvatar)
            Positioned(
              bottom: 10.h,
              left: 14.w,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: a.ownerAvatarUrl != null && a.ownerAvatarUrl!.isNotEmpty
                      ? Image.network(a.ownerAvatarUrl!, fit: BoxFit.cover)
                      : Image.asset(
                          _avatarAssets[index % _avatarAssets.length],
                          fit: BoxFit.cover,
                          width: 44.w,
                          height: 44.w,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AnnouncementModel a) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 6.h, 8.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price row + time
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'AED ',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
              ),
              Text(
                _formatPrice(a.price ?? 0),
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' yearly',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                a.timeAgo ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.textBlack.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Property name
          Text(
            a.propertyName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          // Divider
          // Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
          // SizedBox(height: 8.h),
          // Location row
          Row(
            children: [
              Expanded(
                child: Text(
                  a.location ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.home_outlined, size: 40.sp, color: Colors.grey),
      ),
    );
  }

  String _formatPrice(double price) {
    String str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
