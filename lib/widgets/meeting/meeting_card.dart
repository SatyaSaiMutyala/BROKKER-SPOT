import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF232323);

    final a = meeting.announcement;
    final thumb = a.propertyMedia?.thumbnail ?? '';
    final isRent = (a.listingType ?? '').toLowerCase() == 'rent';
    final forLabel = isRent ? 'For RENT' : 'For SELL';
    final period = (a.rentPeriod ?? '').isNotEmpty
        ? ' ${a.rentPeriod!.toLowerCase()}'
        : '';

    final first =
        meeting.chatProfiles.isNotEmpty ? meeting.chatProfiles.first : null;
    final second =
        meeting.chatProfiles.length > 1 ? meeting.chatProfiles[1] : null;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 89.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              _PropertyThumb(url: thumb),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Property type
                    Text(
                      a.propertyType ?? 'Property',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                    // OWN (gold) + For RENT/SELL
                    RichText(
                      text: TextSpan(
                        children: [
                          if (isOwn)
                            TextSpan(
                              text: 'OWN ',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                          TextSpan(
                            text: forLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AED [price gradient] [period]
                    Row(
                      children: [
                        Text(
                          '${a.currency ?? 'AED'} ',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                            height: 1.0,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFCBAB52), Color(0xB2DBC483)],
                          ).createShader(bounds),
                          child: Text(
                            _formatPrice(a.price),
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        if (period.isNotEmpty)
                          Text(
                            period,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              height: 1.0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _AvatarCluster(
                first: first,
                second: second,
                count: meeting.chatProfilesCount,
              ),
            ],
          ),
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

// ── Property thumbnail ────────────────────────────────────────────────────────

class _PropertyThumb extends StatelessWidget {
  final String url;

  const _PropertyThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 65.w,
      height: 65.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
                placeholder: (_, __) => _placeholder(isDark),
                errorWidget: (_, __, ___) => _placeholder(isDark),
              )
            : _placeholder(isDark),
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
        child: Icon(
          Icons.home_outlined,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );
}

// ── Overlapping broker avatars + count badge ──────────────────────────────────

class _AvatarCluster extends StatelessWidget {
  final ChatProfileSummary? first;
  final ChatProfileSummary? second;
  final int count;

  const _AvatarCluster({
    required this.first,
    required this.second,
    required this.count,
  });

  // User-side meetings always have brokers in chat_profiles — always show
  // the broker profile photo.
  String? _imgUrl(ChatProfileSummary? p) =>
      p?.brokerProfileImageUrl ?? p?.profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showTwo = second != null && count > 1;

    return SizedBox(
      width: 47.w,
      height: 46.h,
      child: Stack(
        children: [
          if (showTwo)
            Positioned(
              bottom: 0,
              right: 0,
              child: _circle(_imgUrl(second), isDark),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _circle(_imgUrl(first), isDark),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: 0,
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circle(String? url, bool isDark) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
                placeholder: (_, __) => _fallback(isDark),
                errorWidget: (_, __, ___) => _fallback(isDark),
              )
            : _fallback(isDark),
      ),
    );
  }

  Widget _fallback(bool isDark) => Container(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
        child: Icon(
          Icons.person_outline,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          size: 16,
        ),
      );
}
