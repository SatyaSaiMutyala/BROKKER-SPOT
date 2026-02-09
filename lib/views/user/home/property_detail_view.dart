import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class PropertyDetailView extends StatelessWidget {
  final AnnouncementModel announcement;
  final String sectionTitle;

  const PropertyDetailView({
    super.key,
    required this.announcement,
    this.sectionTitle = 'DAMAC',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          sectionTitle,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 20.h),
            // First description paragraph
            _buildParagraph(
              'DAMAC Properties is part of DAMAC Group that has been shaping the Middle East\'s luxury real estate market since 1982, delivering iconic residential, commercial and leisure properties across the region and beyond.',
            ),
            SizedBox(height: 20.h),
            // Main image
            _buildMainImage(),
            SizedBox(height: 20.h),
            // Second description paragraph
            _buildParagraph(
              'DAMAC adds vibrancy to the cities in which its projects are located, with a huge and diverse portfolio that includes skyscrapers, communities and branded residences. To date DAMAC has delivered c. 42,000 quality homes, with c. 28,000 more under way.',
            ),
            SizedBox(height: 28.h),
            // Stats section with person image
            _buildStatsSection(),
            SizedBox(height: 28.h),
            // Bottom long description
            _buildParagraph(
              'DAMAC adds vibrancy to the cities in which its projects are located, with a huge and diverse portfolio that includes skyscrapers, communities and branded residences. To date DAMAC has delivered c. 42,000 quality homes, with c. 28,000 more under way.DAMAC adds vibrancy to the cities in which its projects are located, with a huge and diverse portfolio that includes skyscrapers, communities and branded residences. To date DAMAC has delivered c. 42,000 quality homes, with c. 28,000 more under way.',
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          height: 180.h,
          width: double.infinity,
          child: (announcement.imageUrls != null &&
                  announcement.imageUrls!.isNotEmpty)
              ? Image.asset(
                  announcement.imageUrls!.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Person image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 130.w,
              height: 140.h,
              child: Image.asset(
                'assets/images/profile.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.person, size: 48.sp, color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(width: 20.w),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 42,000
                Text(
                  '42,000',
                  style: GoogleFonts.inter(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 40.w,
                  height: 2.h,
                  color: AppColors.goldAccent,
                ),
                SizedBox(height: 6.h),
                Text(
                  'HOMES DELIVERED*',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 20.h),
                // 28,000
                Text(
                  '28,000',
                  style: GoogleFonts.inter(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  width: 40.w,
                  height: 2.h,
                  color: AppColors.goldAccent,
                ),
                SizedBox(height: 6.h),
                Text(
                  'IN PLANNING AND PROGRESS*',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.home_outlined, size: 48.sp, color: Colors.grey),
      ),
    );
  }
}
