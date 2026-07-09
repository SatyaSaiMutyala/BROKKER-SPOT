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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          _buildPropertyImage(),
          SizedBox(width: 12.w),
          Expanded(child: _buildProjectInfo(isDark)),
          _buildAvatarStack(isDark),
        ],
      ),
    );
  }

  Widget _buildPropertyImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 70.w,
        height: 70.w,
        child: Image.asset(
          deal.imageUrl ?? 'assets/images/room.png',
          fit: BoxFit.cover,
          width: 70.w,
          height: 70.w,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/room.png',
            fit: BoxFit.cover,
            width: 70.w,
            height: 70.w,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfo(bool isDark) {
    final bool isSuccess = deal.status?.toLowerCase() == 'successfully';
    final Color statusColor =
        isSuccess ? const Color(0xFF6CBB1D) : const Color(0xFFD4A017);
    final String statusText = isSuccess ? 'Successfully' : 'Inprocess';
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deal.projectName ?? '',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.bed_outlined, size: 14.sp, color: subtitleColor),
            SizedBox(width: 4.w),
            Text(
              deal.propertyType ?? '',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: subtitleColor,
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

  Widget _buildAvatarStack(bool isDark) {
    final smallBorder = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  deal.brokerAvatarUrl ?? 'assets/images/story1.png',
                  fit: BoxFit.cover,
                  width: 42.w,
                  height: 42.w,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/story1.png',
                    fit: BoxFit.cover,
                    width: 42.w,
                    height: 42.w,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: smallBorder, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  deal.imageUrl ?? 'assets/images/story2.png',
                  fit: BoxFit.cover,
                  width: 24.w,
                  height: 24.w,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/story2.png',
                    fit: BoxFit.cover,
                    width: 24.w,
                    height: 24.w,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
