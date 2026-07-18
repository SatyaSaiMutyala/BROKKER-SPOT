import 'dart:ui' show ImageFilter;
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

  /// Broker-side feeds append a "Brokerage X% ~ CUR amount" strip along the
  /// bottom edge, computed from [AnnouncementModel.brokkeragePercent] and
  /// price. Off by default so the Home/user-side card is unaffected.
  final bool showBrokerageRow;

  final bool isWishlisted;
  final VoidCallback? onWishlistTap;

  const HomeAnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.showAvatar = true,
    this.index = 0,
    this.cardWidth,
    this.cardHeight,
    this.showBrokerageRow = false,
    this.isWishlisted = false,
    this.onWishlistTap,
  });

  static const _brokerageRowHeight = 57.0;
  // The strip's top 20px sits over the image's own bottom edge (per the
  // Figma spec: card height 263, strip top at 243) instead of the card
  // growing by the strip's full height — only the un-overlapped remainder
  // adds new space below the photo.
  static const _brokerageOverlap = 20.0;

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

    final brokerageExtra =
        showBrokerageRow ? (_brokerageRowHeight - _brokerageOverlap).h : 0.0;
    final imageCardHeight = cardHeight ?? 263.h;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth ?? 329.w,
        height: imageCardHeight + brokerageExtra,
        child: Stack(
          children: [
            // Brokerage strip sits behind the photo card, bottom-anchored,
            // so it peeks out from under the photo's own rounded corners.
            if (showBrokerageRow && a.brokkeragePercent != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _brokerageRowHeight.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFB29C61),
                        Color(0x7A756846), // rgba(117,104,70,0.48)
                      ],
                    ),
                  ),
                  child: Text(
                    'Brokerage ${a.brokkeragePercent}% ~ ${a.currency ?? 'AED'} '
                    '${_formatPrice((a.price ?? 0) * a.brokkeragePercent! / 100)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),

            // Photo card — its own fully-rounded rect (drawn on top), so its
            // bottom corners cut away to reveal the brokerage strip behind
            // it instead of running flush into it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageCardHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Full-bleed property image
                    _buildImage(
                      a.imageUrls?.isNotEmpty == true
                          ? a.imageUrls!.first
                          : null,
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
                          width: 70.w,
                          height: 32.h,
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
                              fontSize: 11.sp,
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Text(
                                a.currency ?? 'AED',
                                style: GoogleFonts.poppins(
                                  fontSize: 19.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  height: 1.0,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 1.h),
                          // Price row — gold price + optional rent period suffix
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatPrice(a.price ?? 0),
                                style: GoogleFonts.poppins(
                                  fontSize: 27.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDBC483),
                                  height: 1.0,
                                  letterSpacing: 0,
                                ),
                              ),
                              if (a.rentPeriod != null &&
                                  a.listingType == 'Rent') ...[
                                SizedBox(width: 6.w),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 2.h),
                                  child: Text(
                                    a.rentPeriod!
                                            .substring(0, 1)
                                            .toUpperCase() +
                                        a.rentPeriod!
                                            .substring(1)
                                            .toLowerCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.sp,
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
                          Transform.translate(
                            offset: Offset(0, -7.h),
                            child: Row(
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
                                              fontSize: 17.sp,
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
                                              fontSize: 17.sp,
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
                          ),
                          // Location
                          if (a.location != null)
                            Transform.translate(
                              offset: Offset(0, -18.h),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 14.sp, color: AppColors.primary),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      a.location!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xFF9E9E9E),
                                        height: 1.0,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return CustomPaint(
      painter: const _PillPainter(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFCFCFCF),
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _imageCountCircle(int count) {
    return SizedBox(
      width: 42.w,
      height: 42.w,
      child: CustomPaint(
        painter: const _CircleCountPainter(),
        child: Center(
          child: Text(
            count > 7 ? '7+' : '$count+',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.0,
            ),
          ),
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

class _PillPainter extends CustomPainter {
  const _PillPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Gradient fill — lighter top-left → darker bottom-right
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x503A3A3C), Color(0x501C1C1E)],
        ).createShader(rect),
    );

    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius - 0.5),
    );

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0x55FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _PillPainter old) => false;
}

class _CircleCountPainter extends CustomPainter {
  const _CircleCountPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    // Gradient fill — lighter top-left → darker bottom-right (semi-transparent)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x503A3A3C), Color(0x501C1C1E)],
        ).createShader(bounds),
    );

    canvas.drawCircle(
      center,
      radius - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x55FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _CircleCountPainter old) => false;
}
