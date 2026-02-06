import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class AnnouncementPropertyCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool showWishlist;
  final bool showStatusBadge;
  final bool showBrokerAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onLocationTap;

  const AnnouncementPropertyCard({
    super.key,
    required this.announcement,
    this.showWishlist = true,
    this.showStatusBadge = false,
    this.showBrokerAvatar = false,
    this.onTap,
    this.onWishlistTap,
    this.onLocationTap,
  });

  @override
  State<AnnouncementPropertyCard> createState() =>
      _AnnouncementPropertyCardState();
}

class _AnnouncementPropertyCardState extends State<AnnouncementPropertyCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner row
            _buildOwnerRow(a),
            // Image carousel
            _buildImageCarousel(a),
            // Details
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRow(a),
                  SizedBox(height: 4.h),
                  _buildPropertyName(a),
                  SizedBox(height: 6.h),
                  _buildPropertyDetails(a),
                  SizedBox(height: 8.h),
                  _buildLocationRow(a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRow(AnnouncementModel a) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipOval(
              child: a.ownerAvatarUrl != null && a.ownerAvatarUrl!.isNotEmpty
                  ? Image.network(a.ownerAvatarUrl!, fit: BoxFit.cover)
                  : Icon(Icons.person, size: 20.sp, color: Colors.grey),
            ),
          ),
          SizedBox(width: 10.w),
          // Name
          Text(
            a.ownerName ?? '',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Listing type
          Text(
            a.listingType ?? '',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(AnnouncementModel a) {
    final imageCount = a.imageUrls?.length ?? 0;
    final totalDots = imageCount > 0 ? imageCount : 6;

    return Stack(
      children: [
        // Image
        SizedBox(
          height: 180.h,
          width: double.infinity,
          child: imageCount > 0
              ? PageView.builder(
                  itemCount: imageCount,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (_, index) => Image.network(
                    a.imageUrls![index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
                )
              : _imagePlaceholder(),
        ),
        // Wishlist heart
        if (widget.showWishlist)
          Positioned(
            top: 12.h,
            right: 14.w,
            child: GestureDetector(
              onTap: widget.onWishlistTap,
              child: Icon(
                a.isWishlisted == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.white,
                size: 26.sp,
              ),
            ),
          ),
        // Status badge
        if (widget.showStatusBadge && a.status != null)
          Positioned(
            top: 12.h,
            right: 14.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.activeGreen,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                a.status!,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Dot indicators
        Positioned(
          bottom: 10.h,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalDots,
              (index) => Container(
                width: 7.w,
                height: 7.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? AppColors.teal
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.home_outlined,
        size: 48.sp,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildPriceRow(AnnouncementModel a) {
    return Row(
      children: [
        Text(
          'AED ',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          _formatPrice(a.price ?? 0),
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.teal,
          ),
        ),
        const Spacer(),
        if (!widget.showBrokerAvatar)
          Text(
            a.timeAgo ?? '',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade500,
            ),
          ),
        // Broker avatar with badge
        if (widget.showBrokerAvatar) _buildBrokerBadge(a),
      ],
    );
  }

  Widget _buildBrokerBadge(AnnouncementModel a) {
    return Stack(
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
            child: Icon(Icons.person, size: 20.sp, color: Colors.grey),
          ),
        ),
        if (a.proposalCount != null && a.proposalCount! > 0)
          Positioned(
            top: -4.h,
            right: -4.w,
            child: Container(
              width: 18.w,
              height: 18.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal,
              ),
              child: Center(
                child: Text(
                  '${a.proposalCount}',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyName(AnnouncementModel a) {
    return Text(
      a.propertyName ?? '',
      style: GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPropertyDetails(AnnouncementModel a) {
    return Row(
      children: [
        Icon(Icons.bed_outlined, size: 16.sp, color: Colors.grey.shade600),
        SizedBox(width: 4.w),
        Text(
          '${a.bedrooms ?? 0} Bedroom',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(width: 16.w),
        Icon(Icons.square_foot, size: 16.sp, color: Colors.grey.shade600),
        SizedBox(width: 4.w),
        Text(
          '${a.sqft ?? 0} / Sqft',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(AnnouncementModel a) {
    return GestureDetector(
      onTap: widget.onLocationTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              a.location ?? '',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20.sp,
            color: AppColors.teal,
          ),
        ],
      ),
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
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
