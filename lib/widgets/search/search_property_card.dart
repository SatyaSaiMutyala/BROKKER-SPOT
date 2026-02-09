import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

class SearchPropertyCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? timeAgo;
  final String? badge;
  final int? unitsLeft;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onChatTap;

  const SearchPropertyCard({
    super.key,
    required this.announcement,
    this.ownerName,
    this.ownerAvatarUrl,
    this.timeAgo,
    this.badge,
    this.unitsLeft,
    this.onTap,
    this.onWishlistTap,
    this.onCallTap,
    this.onChatTap,
  });

  @override
  State<SearchPropertyCard> createState() => _SearchPropertyCardState();
}

class _SearchPropertyCardState extends State<SearchPropertyCard> {
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
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(a),
            _buildInfoSection(a),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Image carousel with owner overlay ───
  Widget _buildImageSection(AnnouncementModel a) {
    final imageCount = a.imageUrls?.length ?? 0;
    final totalDots = imageCount > 0 ? imageCount : 6;

    return Stack(
      children: [
        // Image carousel
        SizedBox(
          height: 200.h,
          width: double.infinity,
          child: imageCount > 0
              ? PageView.builder(
                  itemCount: imageCount,
                  onPageChanged: (i) =>
                      setState(() => _currentImageIndex = i),
                  itemBuilder: (_, i) => Image.asset(
                    a.imageUrls![i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
                )
              : _imagePlaceholder(),
        ),

        // Dark gradient overlay at top for readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 70.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Owner avatar + name (top left)
        Positioned(
          top: 14.h,
          left: 14.w,
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  color: Colors.grey.shade300,
                ),
                child: ClipOval(
                  child: widget.ownerAvatarUrl != null
                      ? Image.asset(
                          widget.ownerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 18.sp,
                              color: Colors.grey),
                        )
                      : Icon(Icons.person,
                          size: 18.sp, color: Colors.grey),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                widget.ownerName ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Time ago (top right)
        if (widget.timeAgo != null)
          Positioned(
            top: 18.h,
            right: 14.w,
            child: Text(
              widget.timeAgo!,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),

        // Badge (bottom right, e.g. "RENT")
        if (widget.badge != null)
          Positioned(
            bottom: 24.h,
            right: 14.w,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                widget.badge!,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Dot indicators (bottom center)
        Positioned(
          bottom: 10.h,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalDots,
              (i) => Container(
                width: 7.w,
                height: 7.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentImageIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Price, name, location ───
  Widget _buildInfoSection(AnnouncementModel a) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price + units left
          Row(
            children: [
              Text(
                'AED ',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                _formatPrice(a.price ?? 0),
                style: GoogleFonts.inter(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                ),
              ),
              const Spacer(),
              if (widget.unitsLeft != null)
                Text(
                  '${widget.unitsLeft} Unit Left',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.goldAccent,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          // Property name + wishlist
          Row(
            children: [
              Expanded(
                child: Text(
                  a.propertyName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Location + heart
          Row(
            children: [
              Expanded(
                child: Text(
                  a.location ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onWishlistTap,
                child: Icon(
                  a.isWishlisted == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 22.sp,
                  color: a.isWishlisted == true
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Call / Chat buttons ───
  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 14.h),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: 'Call',
              onTap: widget.onCallTap,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _actionButton(
              label: 'Chat',
              onTap: widget.onChatTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.goldAccent, width: 1.2),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(Icons.home_outlined, size: 48.sp, color: Colors.grey),
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
