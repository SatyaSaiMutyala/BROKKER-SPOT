import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/brokerage_payment_model.dart';

class BrokerPaymentTile extends StatelessWidget {
  final BrokerPaymentModel payment;
  final bool isSelected;
  final VoidCallback onTap;
  final String formattedAmount;

  const BrokerPaymentTile({
    super.key,
    required this.payment,
    required this.isSelected,
    required this.onTap,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1)
              : null,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            SizedBox(width: 12.w),
            Expanded(child: _buildNameColumn()),
            _buildAmount(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldAccent, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(
          (payment.brokerName ?? 'B')[0].toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildNameColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payment.brokerName ?? '',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          payment.projectName ?? '',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return Text(
      'AED $formattedAmount',
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: isSelected ? AppColors.primary : Colors.black87,
      ),
    );
  }
}
