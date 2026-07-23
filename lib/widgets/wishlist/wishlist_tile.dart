import 'package:brokkerspot/models/announcement_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One square photo tile in the wishlist grid, with the saved heart pinned to
/// the top-right corner.
///
/// Shared so the broker-side wishlist can render the same grid.
class WishlistTile extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  /// Fires when the heart itself is tapped. Leave null to render the heart as
  /// a plain indicator (taps fall through to [onTap]).
  final VoidCallback? onHeartTap;

  const WishlistTile({
    super.key,
    required this.announcement,
    this.onTap,
    this.onHeartTap,
  });

  String? get _imageUrl {
    final thumb = announcement.propertyMedia?.thumbnail;
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final images = announcement.imageUrls;
    if (images != null && images.isNotEmpty) return images.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Spec fill for an empty tile: #00000021 (13% black).
    final placeholderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0x21000000);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(placeholderColor),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: onHeartTap,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.favorite,
                  size: 26.sp,
                  color: Colors.red.shade400,
                  shadows: const [
                    Shadow(color: Color(0x40000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Color placeholderColor) {
    final url = _imageUrl;
    if (url == null) {
      return ColoredBox(
        color: placeholderColor,
        child: Icon(
          Icons.home_outlined,
          size: 28.sp,
          color: Colors.grey.shade500,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(color: placeholderColor),
      errorWidget: (_, __, ___) => ColoredBox(
        color: placeholderColor,
        child: Icon(
          Icons.home_outlined,
          size: 28.sp,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
