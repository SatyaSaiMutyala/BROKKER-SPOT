import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/brokerage_payment_model.dart';

class DealCard extends StatelessWidget {
  final DealModel deal;
  final VoidCallback? onChevronTap;

  const DealCard({
    super.key,
    required this.deal,
    this.onChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildPropertyImage(),
          SizedBox(width: 12.w),
          Expanded(child: _buildProjectInfo()),
          _buildRightSection(),
        ],
      ),
    );
  }

  Widget _buildPropertyImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 70.w,
        height: 70.w,
        color: Colors.grey.shade300,
        child: Icon(
          Icons.apartment,
          size: 32.sp,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    final bool isSuccess = deal.status?.toLowerCase() == 'successfully';
    final Color statusColor = isSuccess ? AppColors.successGreen : AppColors.primary;
    final String statusText = isSuccess ? 'Successfully' : 'Inprocess';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deal.projectName ?? '',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.bed_outlined, size: 14.sp, color: Colors.grey),
            SizedBox(width: 4.w),
            Text(
              deal.propertyType ?? '',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              deal.referenceId ?? '',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onChevronTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14.sp,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.goldAccent, width: 2),
          color: Colors.grey.shade200,
        ),
        child: Icon(Icons.person, size: 18.sp, color: Colors.grey),
      ),
    );
  }
}
