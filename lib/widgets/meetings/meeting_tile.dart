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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            _buildAvatarStack(),
            SizedBox(width: 12.w),
            Expanded(child: _buildInfo()),
            _buildRight(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 62.w,
      height: 62.w,
      child: Stack(
        children: [
          // Main large avatar
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
              ),
              child: ClipOval(
                child: meeting.avatarUrl != null && meeting.avatarUrl!.isNotEmpty
                    ? Image.asset(
                        meeting.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text(
                            (meeting.clientName ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // Small overlapping avatar at bottom-right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.goldAccent.withValues(alpha: 0.15),
              ),
              child: ClipOval(
                child: meeting.secondAvatarUrl != null && meeting.secondAvatarUrl!.isNotEmpty
                    ? Image.asset(
                        meeting.secondAvatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.goldAccent.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.person,
                          size: 14.sp,
                          color: AppColors.goldAccent,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meeting.clientName ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textBlack.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          meeting.projectName ?? '',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              'From AED ',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              meeting.fromAmount ?? '99 0000',
              style: GoogleFonts.poppins(
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '€ $formattedAmount*',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
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
              color: AppColors.primary,
            ),
            child: Center(
              child: Text(
                '${meeting.messageCount}',
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ),
        SizedBox(height: 4.h),
        // Time ago
        Text(
          meeting.timeAgo ?? '',
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
