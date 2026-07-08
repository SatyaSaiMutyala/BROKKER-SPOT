import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';

/// Full-image dark overlay property card used on the Home and More screens.
class HomeAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;
  final bool showAvatar;
  final int index;
  /// Override card width (defaults to 329.w for horizontal home cards).
  final double? cardWidth;
  /// Override card height (defaults to 263.h for horizontal home cards).
  final double? cardHeight;

  const HomeAnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.showAvatar = true,
    this.index = 0,
    this.cardWidth,
    this.cardHeight,
  });

  static const _fallbackAvatars = [
    'assets/images/announcement_proffile_icon.png',
    'assets/images/story1.png',
    'assets/images/story2.png',
  ];

  String get _listingBadge {
    if (announcement.listingType == 'Sell') return 'FOR SELL';
    if (announcement.listingType == 'Rent') return 'FOR RENT';
    return announcement.listingType ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final imgCount = a.imageUrls?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth ?? 329.w,
        height: cardHeight ?? 263.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed property image
            _buildImage(
              a.imageUrls?.isNotEmpty == true ? a.imageUrls!.first : null,
            ),

            // Gradient: rgba(39,39,39,0.05) at 55.32% → #000000 at 100%
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0D272727), // rgba(39,39,39,0.05)
                    Colors.black,
                  ],
                  stops: [0.5532, 1.0],
                ),
              ),
            ),

            // "FOR SELL / FOR RENT" badge — flush left, right-rounded only
            if (_listingBadge.isNotEmpty)
              Positioned(
                top: 21.h,
                left: 0,
                child: Container(
                  width: 64.w,
                  height: 27.h,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xDBDBC483),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                  ),
                  child: Text(
                    _listingBadge,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),

            // Owner avatar — top right, 41×41, 1px #D0D0D0 border, no inner gap
            if (showAvatar)
              Positioned(
                top: 14.h,
                right: 10.w,
                child: Container(
                  width: 41.w,
                  height: 41.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD0D0D0),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(child: _buildAvatar(a)),
                ),
              ),

            // Bottom info block
            Positioned(
              left: 14.w,
              right: 10.w,
              bottom: 16.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AED label
                  Text(
                    a.currency ?? 'AED',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 9.h),
                  // Price row — gold price + optional rent period suffix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(a.price ?? 0),
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDBC483),
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                      ),
                      if (a.rentPeriod != null && a.listingType == 'Rent') ...[
                        SizedBox(width: 6.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            a.rentPeriod!.substring(0, 1).toUpperCase() +
                                a.rentPeriod!.substring(1).toLowerCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Type row: "For Sell • Apartment" left | pill + circle right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "For Sell • " (#C8C8C8) + "Apartment" (white)
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              if (a.listingType != null)
                                TextSpan(
                                  text: 'For ${a.listingType} • ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w300,
                                    color: const Color(0xFFC8C8C8),
                                    height: 1.0,
                                    letterSpacing: 0,
                                  ),
                                ),
                              if (a.propertyType != null)
                                TextSpan(
                                  text: a.propertyType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    height: 1.0,
                                    letterSpacing: 0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Time-ago pill
                      if (a.timeAgo != null) ...[
                        SizedBox(width: 6.w),
                        _pill(a.timeAgo!.toUpperCase()),
                      ],
                      // Image count circle
                      if (imgCount > 1) ...[
                        SizedBox(width: 6.w),
                        _imageCountCircle(imgCount),
                      ],
                    ],
                  ),
                  // Location
                  if (a.location != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 12.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            a.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w300,
                              color: const Color(0xFF9E9E9E),
                              height: 1.0,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time-ago pill — 76×27, r26, Poppins Medium 500 10sp #CFCFCF
  Widget _pill(String text) {
    return Container(
      width: 76.w,
      height: 27.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFCFCFCF),
          height: 1.0,
          letterSpacing: 0,
        ),
      ),
    );
  }

  // Image count circle — 36×36, 1px #DBC483AB border
  Widget _imageCountCircle(int count) {
    return Container(
      width: 36.w,
      height: 36.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: const Color(0xABDBC483),
          width: 1,
        ),
      ),
      child: Text(
        count > 9 ? '9+' : '$count+',
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildAvatar(AnnouncementModel a) {
    if (a.ownerAvatarUrl != null && a.ownerAvatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: a.ownerAvatarUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackAvatar(),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Image.asset(
      _fallbackAvatars[index % _fallbackAvatars.length],
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade700,
        child: Icon(Icons.person, size: 20.sp, color: Colors.white54),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) return _imagePlaceholder();
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xFF2A2A2A)),
        errorWidget: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child:
            Icon(Icons.home_outlined, size: 40.sp, color: Colors.grey.shade600),
      ),
    );
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
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
