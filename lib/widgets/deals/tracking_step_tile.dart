import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_deal_model.dart';

class TrackingStepTile extends StatelessWidget {
  final TrackingStepModel step;
  final bool isLast;
  final VoidCallback? onAction;

  const TrackingStepTile({
    super.key,
    required this.step,
    this.isLast = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.status != StepStatus.pending &&
        step.status != StepStatus.notSignedYet &&
        step.status != StepStatus.notStarted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column (dot + line)
          SizedBox(
            width: 40.w,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.goldAccent
                        : Colors.grey.shade300,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                      : null,
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isCompleted
                                ? AppColors.goldAccent.withValues(alpha: 0.4)
                                : Colors.grey.shade300,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.goldAccent
                                : Colors.black87,
                          ),
                        ),
                        if (step.date != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            step.date!,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (step.subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            step.subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status / action
                  _buildStatusAction(isCompleted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(bool isCompleted) {
    // Completed steps show green check + label
    if (isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14.sp, color: AppColors.activeGreen),
          SizedBox(width: 4.w),
          Text(
            step.statusLabel,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.activeGreen,
            ),
          ),
        ],
      );
    }

    // Booking link type -> gold button
    if (step.type == StepType.bookingLink &&
        step.status == StepStatus.pending) {
      return GestureDetector(
        onTap: onAction,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.goldAccent,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            'Booking Link',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Payment proof / down payment -> upload button
    if ((step.type == StepType.paymentProof ||
            step.type == StepType.downPayment) &&
        step.status == StepStatus.pending) {
      return GestureDetector(
        onTap: onAction,
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 28.sp, color: AppColors.goldAccent),
            Text(
              'Upload Payment Slip',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Not signed yet / not started
    if (step.status == StepStatus.notSignedYet ||
        step.status == StepStatus.notStarted) {
      return Text(
        step.statusLabel,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          color: Colors.grey.shade400,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
