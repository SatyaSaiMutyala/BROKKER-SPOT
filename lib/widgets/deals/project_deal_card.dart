import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_deal_model.dart';

class ProjectDealCard extends StatelessWidget {
  final ProjectDealModel deal;
  final VoidCallback? onTrackStatus;
  final bool showUid;
  final bool showTrackStatus;

  const ProjectDealCard({
    super.key,
    required this.deal,
    this.onTrackStatus,
    this.showUid = true,
    this.showTrackStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Date header
          _buildDateHeader(),
          // Card body
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                _buildPropertyRow(),
                SizedBox(height: 10.h),
                _buildDetailsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      color: AppColors.goldAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            deal.date ?? '',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (showTrackStatus)
            GestureDetector(
              onTap: onTrackStatus,
              child: Text(
                'Track Status',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property image
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: SizedBox(
            width: 70.w,
            height: 70.w,
            child: deal.imageUrl != null
                ? Image.asset(
                    deal.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
        ),
        SizedBox(width: 12.w),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price
              Text(
                '${deal.currency ?? '€'} ${_formatPrice(deal.price ?? 0)}',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              SizedBox(height: 3.h),
              // Name
              Text(
                deal.propertyName ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 3.h),
              // Location
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
        // Broker avatar + name
        _buildBrokerBadge(),
      ],
    );
  }

  Widget _buildBrokerBadge() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipOval(
                child: deal.brokerAvatarUrl != null
                    ? Image.asset(
                        deal.brokerAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, size: 20.sp, color: Colors.grey),
                      )
                    : Icon(Icons.person, size: 20.sp, color: Colors.grey),
              ),
            ),
            if (deal.brokerRating != null)
              Positioned(
                bottom: -6.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      deal.brokerRating!.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          deal.brokerName ?? '',
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow() {
    return Row(
      children: [
        Icon(Icons.bed_outlined, size: 16.sp, color: Colors.grey.shade500),
        SizedBox(width: 4.w),
        Text(
          '${deal.bedrooms ?? 0} Bedroom',
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(width: 14.w),
        Icon(Icons.square_foot, size: 16.sp, color: Colors.grey.shade500),
        SizedBox(width: 4.w),
        Text(
          '${deal.sqft ?? 0} / Sqft',
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        if (showUid && deal.uid != null) ...[
          SizedBox(width: 14.w),
          Text(
            'UID',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            deal.uid!,
            style:
                GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _imagePlaceholder() {
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
