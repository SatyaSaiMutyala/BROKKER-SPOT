import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_model.dart';

class MeetingTile extends StatelessWidget {
  final MeetingModel meeting;
  final String formattedAmount;
  final VoidCallback? onTap;

  const MeetingTile({
    super.key,
    required this.meeting,
    required this.formattedAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            SizedBox(width: 12.w),
            Expanded(child: _buildInfo()),
            _buildRight(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldAccent, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          (meeting.clientName ?? 'U')[0].toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meeting.clientName ?? '',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          meeting.projectName ?? '',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.people_outline, size: 14.sp, color: AppColors.goldAccent),
            SizedBox(width: 4.w),
            Text(
              'From AED ',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppColors.goldAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              meeting.fromAmount ?? '99 0000',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppColors.goldAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Amount
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '€ $formattedAmount*',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        // Message count badge
        if (meeting.messageCount != null && meeting.messageCount! > 0)
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldAccent.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                '${meeting.messageCount}',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ),
        SizedBox(height: 4.h),
        // Time ago
        Text(
          meeting.timeAgo ?? '',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
