import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_deal_model.dart';

class DealPropertyHeader extends StatelessWidget {
  final ProjectDealModel deal;
  final String? nextAction;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  const DealPropertyHeader({
    super.key,
    required this.deal,
    this.nextAction,
    this.onCall,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property info row
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SizedBox(
                    width: 65.w,
                    height: 65.w,
                    child: deal.imageUrl != null
                        ? Image.asset(deal.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${deal.currency ?? '€'} ${_formatPrice(deal.price ?? 0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        deal.propertyName ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        deal.location ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Broker
                _buildBrokerBadge(),
              ],
            ),
          ),
          // Details row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Icon(Icons.bed_outlined, size: 16.sp, color: Colors.grey.shade500),
                SizedBox(width: 4.w),
                Text('${deal.bedrooms ?? 0} Bedroom',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600)),
                SizedBox(width: 14.w),
                Icon(Icons.square_foot, size: 16.sp, color: Colors.grey.shade500),
                SizedBox(width: 4.w),
                Text('${deal.sqft ?? 0} / Sqft',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600)),
                if (deal.uid != null) ...[
                  SizedBox(width: 14.w),
                  Text('UID', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.goldAccent)),
                  SizedBox(width: 4.w),
                  Text(deal.uid!, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          // Next action text
          if (nextAction != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Next : ',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    TextSpan(
                      text: nextAction,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 10.h),
          // Call / Chat buttons
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Row(
              children: [
                Expanded(child: _actionBtn(Icons.phone, 'CALL', onCall)),
                SizedBox(width: 10.w),
                Expanded(child: _actionBtn(Icons.chat_bubble, 'CHAT', onChat)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: AppColors.goldAccent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerBadge() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipOval(
                child: deal.brokerAvatarUrl != null
                    ? Image.asset(deal.brokerAvatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.person, size: 18.sp, color: Colors.grey))
                    : Icon(Icons.person, size: 18.sp, color: Colors.grey),
              ),
            ),
            if (deal.brokerRating != null)
              Positioned(
                bottom: -5.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      deal.brokerRating!.toStringAsFixed(1),
                      style: GoogleFonts.inter(fontSize: 8.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(deal.brokerName ?? '', style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.home_outlined, size: 28.sp, color: Colors.grey),
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
        buffer.write(' ');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
