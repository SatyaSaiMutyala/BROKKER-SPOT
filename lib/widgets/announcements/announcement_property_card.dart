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
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onCallTap;
  final VoidCallback? onChatTap;

  static const List<String> _avatarAssets = [
    'assets/images/story1.png',
    'assets/images/story2.png',
  ];

  const AnnouncementPropertyCard({
    super.key,
    required this.announcement,
    this.showWishlist = true,
    this.showStatusBadge = false,
    this.showBrokerAvatar = false,
    this.index = 0,
    this.onTap,
    this.onWishlistTap,
    this.onLocationTap,
    this.onCallTap,
    this.onChatTap,
  });

  @override
  State<AnnouncementPropertyCard> createState() =>
      _AnnouncementPropertyCardState();
}

class _AnnouncementPropertyCardState extends State<AnnouncementPropertyCard> {
  int _currentImageIndex = 0;

  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

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
    final hasImages = (a.imageUrls?.length ?? 0) > 0;
    final images = hasImages ? a.imageUrls! : _fallbackImages;
    final totalDots = images.length;

    return Stack(
      children: [
        // Image carousel
        SizedBox(
          height: 200.h,
          width: double.infinity,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) => hasImages
                ? Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : Image.asset(
                    images[i],
                    fit: BoxFit.cover,
                  ),
          ),
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
                width: 55.w,
                height: 55.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    AnnouncementPropertyCard._avatarAssets[widget.index %
                        AnnouncementPropertyCard._avatarAssets.length],
                    width: 55.w,
                    height: 55.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                a.ownerName ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 18.h,
          right: 14.w,
          child: GestureDetector(
            onTap: widget.onWishlistTap,
            child: Image.asset(
              'assets/images/like_icon.png',
              width: 42.sp,
              height: 42.sp,
              color: Colors.white,
            ),
          ),
        ),

        // Listing type badge (bottom right)
        if (a.listingType != null && a.listingType!.isNotEmpty)
          Positioned(
            bottom: 0.h,
            right: 0.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                ),
              ),
              child: Text(
                a.listingType!,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
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
          // Price row
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
            ],
          ),
          SizedBox(height: 6.h),
          // Property name
          Text(
            a.propertyName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          // Bedrooms + Sqft
          Row(
            children: [
              Icon(Icons.bed_outlined, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 4.w),
              Text(
                '${a.bedrooms ?? 0} Bedroom',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.square_foot, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 4.w),
              Text(
                '${a.sqft ?? 0} / Sqft',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          // Location + heart
          GestureDetector(
            onTap: widget.onLocationTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    a.location ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 22.sp, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Call / Chat buttons ───
  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 0.8),
          bottom: BorderSide(color: AppColors.primary, width: 0.8),
          left: BorderSide(color: AppColors.primary, width: 0.8),
          right: BorderSide(color: AppColors.primary, width: 0.8),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onCallTap,
                child: Container(
                  height: 44.h,
                  alignment: Alignment.center,
                  child: Text(
                    'Call',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 0.8, color: AppColors.primary),
            Expanded(
              child: GestureDetector(
                onTap: widget.onChatTap,
                child: Container(
                  height: 44.h,
                  alignment: Alignment.center,
                  child: Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
