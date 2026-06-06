import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One row on the Meeting → Announcement list.
class MeetingCard extends StatelessWidget {
  final MeetingItem meeting;
  final bool isOwn;
  final VoidCallback onTap;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.isOwn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = meeting.announcement;
    final thumb = a.propertyMedia?.thumbnail ?? '';
    // listingType is the display string ('Rent' | 'Sell'); fall back to Sell.
    final isRent = (a.listingType ?? '').toLowerCase() == 'rent';
    final forLabel = isRent ? 'For RENT' : 'For SELL';
    final period = (a.rentPeriod ?? '').toLowerCase();
    final peer = meeting.chatProfiles.isNotEmpty
        ? meeting.chatProfiles.first
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Property image (circular).
            ClipOval(
              child: thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                      memCacheWidth: 180,
                      memCacheHeight: 180,
                      maxWidthDiskCache: 360,
                      maxHeightDiskCache: 360,
                      fadeInDuration: Duration.zero,
                      placeholderFadeInDuration: Duration.zero,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image_outlined,
                            color: Colors.grey.shade400),
                      ),
                    )
                  : Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.home_outlined,
                          color: Colors.grey.shade400),
                    ),
            ),
            SizedBox(width: 12.w),
            // Title + tags + price.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.propertyType ?? 'Property',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (isOwn) ...[
                        Text(
                          'OWN',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        forLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        '${a.currency ?? 'AED'} ',
                        style: GoogleFonts.poppins(
                            fontSize: 13.sp, color: Colors.black),
                      ),
                      Text(
                        _formatPrice(a.price),
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (period.isNotEmpty)
                        Text(
                          ' $period',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Peer avatar + chat-profile-count badge.
            _AvatarWithBadge(
              imageUrl: peer?.profileImageUrl,
              count: meeting.chatProfilesCount,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(num? price) {
    if (price == null) return '-';
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}

class _AvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final int count;

  const _AvatarWithBadge({required this.imageUrl, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 46.w,
                  height: 46.w,
                  fit: BoxFit.cover,
                  memCacheWidth: 138,
                  memCacheHeight: 138,
                  maxWidthDiskCache: 280,
                  maxHeightDiskCache: 280,
                  fadeInDuration: Duration.zero,
                  placeholderFadeInDuration: Duration.zero,
                  errorWidget: (_, __, ___) => _fallback(),
                  placeholder: (_, __) => _fallback(),
                )
              : _fallback(),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: BoxConstraints(minWidth: 18.w),
              height: 18.w,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback() => Container(
        width: 46.w,
        height: 46.w,
        color: Colors.grey.shade200,
        child: Icon(Icons.person_outline, color: Colors.grey.shade400),
      );
}
