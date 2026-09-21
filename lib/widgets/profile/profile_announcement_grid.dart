import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// The square photo tiles under someone's profile.
///
/// Fed by `announcements/fetch-media`, which carries the images and nothing
/// else — so a tile shows a picture and how long the listing has been up, and
/// tapping it opens the detail screen, which fetches the rest by id.
class ProfileAnnouncementGrid extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final bool isDark;

  /// Rows scroll with whatever is around them; the grid never scrolls itself.
  const ProfileAnnouncementGrid({
    super.key,
    required this.announcements,
    required this.isDark,
  });

  static const double _spacing = 8;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: announcements.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: _spacing.w,
        mainAxisSpacing: _spacing.h,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) => ProfileAnnouncementTile(
        announcement: announcements[i],
        isDark: isDark,
      ),
    );
  }
}

class ProfileAnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isDark;

  const ProfileAnnouncementTile({
    super.key,
    required this.announcement,
    required this.isDark,
  });

  /// How long the listing has been up, in the short form the design uses —
  /// "1 Day", "25 Day", "3 Month".
  ///
  /// Null when the listing carries no date, and then no badge is drawn: an
  /// empty pill reads worse than none. `fetch-media` does not currently send
  /// `created_at`, so the badge appears as soon as the server includes it.
  static String? ageLabel(String? createdAt, {DateTime? now}) {
    if (createdAt == null || createdAt.isEmpty) return null;
    final posted = DateTime.tryParse(createdAt)?.toLocal();
    if (posted == null) return null;

    final days = (now ?? DateTime.now()).difference(posted).inDays;
    if (days < 1) return 'Today';
    if (days < 30) return '$days Day';
    if (days < 365) return '${days ~/ 30} Month';
    return '${days ~/ 365} Year';
  }

  /// The picture for a tile: the thumbnail the owner chose, else the first
  /// image they uploaded.
  static String? imageFor(AnnouncementModel a) {
    final thumb = a.propertyMedia?.thumbnail;
    if (thumb != null && thumb.trim().isNotEmpty) return thumb;
    final images = a.propertyMedia?.images ?? const [];
    for (final url in images) {
      if (url.trim().isNotEmpty) return url;
    }
    return null;
  }

  void _open() {
    if (announcement.id == null || announcement.id!.isEmpty) return;
    // The detail screen refetches by id, so the media-only model is enough
    // to start it — its pictures fill the gallery on the first frame.
    Get.to(
      () => AnnouncementDetailView(
        announcement: announcement,
        isOwner: false,
      ),
      preventDuplicates: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = imageFor(announcement);
    final age = ageLabel(announcement.createdAt);
    final placeholder = isDark ? const Color(0xFF242833) : Colors.grey.shade200;

    return GestureDetector(
      onTap: _open,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: placeholder),
                errorWidget: (_, __, ___) => Container(
                  color: placeholder,
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 24.sp,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              )
            else
              Container(
                color: placeholder,
                child: Icon(
                  Icons.apartment_rounded,
                  size: 24.sp,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            if (age != null)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    age,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Six tiles' worth of shimmer, laid out exactly as the grid, so nothing
/// moves when the pictures land.
class ProfileAnnouncementGridShimmer extends StatelessWidget {
  final bool isDark;
  final int itemCount;

  const ProfileAnnouncementGridShimmer({
    super.key,
    required this.isDark,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF242833) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF2F3440) : Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
