import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Broker-side row on the Meeting list: property thumbnail (left), listing
/// details (middle), and the client's avatar + unread-chat count (right).
class BrokerMeetingCard extends StatelessWidget {
  final MeetingItem meeting;
  final bool isOwn;
  final VoidCallback onTap;

  const BrokerMeetingCard({
    super.key,
    required this.meeting,
    required this.isOwn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = meeting.announcement;
    final peer =
        meeting.chatProfiles.isNotEmpty ? meeting.chatProfiles.first : null;
    final listingWord = a.listingType == 'Sell' ? 'BUY' : 'RENT';
    final showPeriod = a.listingType == 'Rent' &&
        a.rentPeriod != null &&
        a.rentPeriod!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            _PropertyThumb(imageUrl: a.propertyMedia?.thumbnail),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.propertyType ?? 'Property',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        if (isOwn)
                          TextSpan(
                            text: 'OWN ',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        TextSpan(
                          text: 'For $listingWord',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${a.currency ?? 'AED'} ',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: _format(a.price),
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (showPeriod)
                          TextSpan(
                            text: ' ${a.rentPeriod!.toLowerCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _ClientAvatar(
              imageUrl: peer?.profileImageUrl,
              fallbackInitial:
                  ((peer?.name?.isNotEmpty == true ? peer!.name![0] : 'U'))
                      .toUpperCase(),
              count: meeting.chatProfilesCount,
            ),
          ],
        ),
      ),
    );
  }

  static String _format(num? n) {
    if (n == null) return '-';
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }
}

class _PropertyThumb extends StatelessWidget {
  final String? imageUrl;

  const _PropertyThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62.w,
      height: 62.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldAccent, width: 2),
      ),
      child: ClipOval(child: _image()),
    );
  }

  Widget _image() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 186,
        memCacheHeight: 186,
        maxWidthDiskCache: 300,
        maxHeightDiskCache: 300,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        color: AppColors.goldAccent.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Icon(Icons.home_outlined,
            size: 24.sp, color: AppColors.goldAccent),
      );
}

class _ClientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final int count;

  const _ClientAvatar({
    required this.imageUrl,
    required this.fallbackInitial,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54.w,
      height: 54.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldAccent, width: 2),
            ),
            child: ClipOval(child: _image()),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _image() {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 138,
        memCacheHeight: 138,
        maxWidthDiskCache: 250,
        maxHeightDiskCache: 250,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(
          fallbackInitial,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );
}
