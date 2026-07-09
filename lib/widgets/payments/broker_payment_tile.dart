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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            _buildAvatarStack(isDark),
            SizedBox(width: 12.w),
            Expanded(child: _buildNameColumn(isDark)),
            _buildAmount(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(bool isDark) {
    final smallBorder = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SizedBox(
      width: 56.w,
      height: 56.w,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  payment.avatarUrl ?? 'assets/images/story1.png',
                  fit: BoxFit.cover,
                  width: 48.w,
                  height: 48.w,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/story1.png',
                    fit: BoxFit.cover,
                    width: 48.w,
                    height: 48.w,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: smallBorder, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  payment.secondAvatarUrl ?? 'assets/images/story2.png',
                  fit: BoxFit.cover,
                  width: 26.w,
                  height: 26.w,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/story2.png',
                    fit: BoxFit.cover,
                    width: 26.w,
                    height: 26.w,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameColumn(bool isDark) {
    final nameColor = isDark ? Colors.white : AppColors.textBlack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payment.brokerName ?? '',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: nameColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          payment.projectName ?? '',
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildAmount(bool isDark) {
    return Text(
      'AED $formattedAmount',
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}
