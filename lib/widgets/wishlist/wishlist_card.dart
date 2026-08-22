import 'package:brokkerspot/core/common_widget/shimmer_box.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// 1234567 → "1,234,567".
///
/// Written out rather than pulling in `intl`, which nothing else in the app
/// depends on and which would be a package added for one call site.
String _grouped(num value) {
  final digits = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// A saved listing in the wishlist grid — photo, price, name, location and the
/// bed/bath/size stats, two to a row.
///
/// Shared by the user and broker wishlists so both render identically; the
/// wishlist endpoint returns the same full announcement for either side.
/// Pair it with [WishlistCardShimmer], which mirrors this layout so the grid
/// keeps its shape while loading.
class WishlistCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  /// Fires when the heart is tapped. Null renders it as a plain indicator and
  /// lets the tap fall through to [onTap].
  final VoidCallback? onHeartTap;

  const WishlistCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.onHeartTap,
  });

  /// Photo aspect inside the card. Kept as a constant so the shimmer can build
  /// the same shape without duplicating the number.
  static const double photoAspect = 1.35;

  String? get _imageUrl {
    final thumb = announcement.propertyMedia?.thumbnail;
    if (thumb != null && thumb.trim().isNotEmpty) return thumb;
    final images = announcement.imageUrls;
    if (images != null && images.isNotEmpty) return images.first;
    return null;
  }

  /// "AED 1.2M" / "AED 850K" / "AED 4,500" — compact so two cards fit a row
  /// without the price wrapping.
  String get _priceLabel {
    final price = announcement.price;
    if (price == null || price <= 0) return '—';
    final currency = (announcement.currency ?? 'AED').trim();
    if (price >= 1000000) {
      final m = price / 1000000;
      final text = m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1);
      return '$currency ${text.replaceAll('.0', '')}M';
    }
    if (price >= 1000) {
      final k = price / 1000;
      final text = k >= 100 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '$currency ${text.replaceAll('.0', '')}K';
    }
    return '$currency ${_grouped(price)}';
  }

  String get _location {
    final parts = [announcement.propertyArea, announcement.propertyCity]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  /// Rent listings read as a period price; sales just show the figure.
  String? get _priceSuffix {
    if ((announcement.listingType ?? '').toLowerCase() != 'rent') return null;
    final period = announcement.rentPeriod?.trim();
    if (period == null || period.isEmpty) return null;
    return '/${period.toLowerCase() == 'monthly' ? 'mo' : 'yr'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF141720) : Colors.white;
    final border =
        isDark ? const Color(0xFF252836) : const Color(0xFFEDEDED);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Clip so the photo's corners follow the card's.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _photo(isDark),
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 9.h, 10.w, 11.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _price(titleColor, subColor),
                    SizedBox(height: 5.h),
                    Text(
                      (announcement.propertyName ?? '').trim().isEmpty
                          ? 'Property'
                          : announcement.propertyName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 11.sp, color: AppColors.primary),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w300,
                              color: subColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _stats(border, subColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Photo + overlays ───────────────────────────────────────────────────────

  Widget _photo(bool isDark) {
    final placeholder = isDark ? const Color(0xFF20232E) : const Color(0x14000000);
    final url = _imageUrl;

    return AspectRatio(
      aspectRatio: photoAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: placeholder),
              errorWidget: (_, __, ___) => _photoFallback(placeholder),
            )
          else
            _photoFallback(placeholder),

          // Keeps the listing-type chip legible over a bright photo.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          if ((announcement.listingType ?? '').trim().isNotEmpty)
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  // The model stores 'Sell'; "For Sale" reads better on a card.
                  (announcement.listingType ?? '').toLowerCase() == 'rent'
                      ? 'For Rent'
                      : 'For Sale',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 6.h,
            right: 6.w,
            child: GestureDetector(
              onTap: onHeartTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: Icon(Icons.favorite,
                    size: 15.sp, color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback(Color bg) => Container(
        color: bg,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined,
            size: 24.sp, color: Colors.grey.shade500),
      );

  // ── Price ──────────────────────────────────────────────────────────────────

  Widget _price(Color titleColor, Color subColor) {
    final suffix = _priceSuffix;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            _priceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
        ),
        if (suffix != null)
          Text(
            suffix,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: subColor,
              height: 1.1,
            ),
          ),
      ],
    );
  }

  // ── Bed / bath / size ──────────────────────────────────────────────────────

  Widget _stats(Color border, Color subColor) {
    final beds = announcement.bedrooms;
    final baths = announcement.bathrooms;
    final sqft = announcement.propertySize?.sqft ?? announcement.sqft?.toDouble();

    final items = <({IconData icon, String label})>[
      if (beds != null) (icon: Icons.bed_outlined, label: '$beds'),
      if (baths != null) (icon: Icons.bathtub_outlined, label: '$baths'),
      if (sqft != null && sqft > 0)
        (
          icon: Icons.square_foot_rounded,
          label: _grouped(sqft)
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Equal columns rather than a left-packed run: the stats used to
            // sit bunched against the left edge with dead space to the right.
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: border,
                  indent: 1.h,
                  endIndent: 1.h,
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].icon, size: 12.sp, color: subColor),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: subColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder in the shape of a [WishlistCard], so the grid holds its layout
/// while the wishlist loads instead of resizing when the data lands.
class WishlistCardShimmer extends StatelessWidget {
  const WishlistCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF141720) : Colors.white;
    final border =
        isDark ? const Color(0xFF252836) : const Color(0xFFEDEDED);

    Widget bar(double w, double h) => ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: ShimmerBox(width: w, height: h),
        );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AspectRatio(
              aspectRatio: WishlistCard.photoAspect,
              child: ShimmerBox(width: double.infinity, height: double.infinity),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 9.h, 10.w, 11.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar(70.w, 14.h), // price
                  SizedBox(height: 7.h),
                  bar(double.infinity, 10.h), // name
                  SizedBox(height: 6.h),
                  bar(90.w, 9.h), // location
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.only(top: 8.h),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: border)),
                    ),
                    // Three equal columns, matching the real card's stats row.
                    child: Row(
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) SizedBox(width: 1.w),
                          Expanded(child: Center(child: bar(24.w, 9.h))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
