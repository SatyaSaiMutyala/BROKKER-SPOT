import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String experience;
  final String following;
  final String brn;
  final String orn;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.experience,
    required this.following,
    required this.brn,
    required this.orn,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        SizedBox(width: 20.w),
        Expanded(child: _buildStats()),
      ],
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(avatarUrl!, fit: BoxFit.cover)
                    : Icon(Icons.person, size: 40.sp, color: Colors.grey),
              ),
            ),
            // Star badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldAccent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.star,
                  size: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        // Experience & Following row
        Row(
          children: [
            _buildStatColumn('Experience', experience),
            SizedBox(width: 24.w),
            _buildStatColumn('Following', following),
          ],
        ),
        SizedBox(height: 12.h),
        // License
        Text(
          'License',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              'BRN : ',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              brn,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'ORN : ',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              orn,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
