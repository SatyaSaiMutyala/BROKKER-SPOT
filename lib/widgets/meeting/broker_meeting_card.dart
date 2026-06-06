import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Broker-side row on the Meeting list.
///
/// Matches the original broker design: a stacked avatar (big peer photo on
/// the left, small property thumbnail overlapping bottom-right), then peer
/// name + property name + price, with a gold "amount" pill and the
/// chat-profiles count badge on the right.
class BrokerMeetingCard extends StatelessWidget {
  final MeetingItem meeting;
  final VoidCallback onTap;

  const BrokerMeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = meeting.announcement;
    final peer = meeting.chatProfiles.isNotEmpty
        ? meeting.chatProfiles.first
        : null;
    final peerName = peer?.name ?? a.propertyType ?? 'User';
    final projectName = a.propertyName?.trim().isNotEmpty == true
        ? a.propertyName!
        : (a.propertyType ?? 'Property');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            _AvatarStack(
              peerImageUrl: peer?.profileImageUrl,
              propertyImageUrl: a.propertyMedia?.thumbnail,
              fallbackInitial: (peerName.isNotEmpty ? peerName[0] : 'U')
                  .toUpperCase(),
            ),
            SizedBox(width: 12.w),
            Expanded(child: _Info(peerName: peerName, projectName: projectName)),
            _RightSide(
              currency: a.currency ?? 'AED',
              price: a.price,
              messageCount: meeting.chatProfilesCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final String? peerImageUrl;
  final String? propertyImageUrl;
  final String fallbackInitial;

  const _AvatarStack({
    required this.peerImageUrl,
    required this.propertyImageUrl,
    required this.fallbackInitial,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62.w,
      height: 62.w,
      child: Stack(
        children: [
          // Big avatar — the person you're chatting with.
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldAccent, width: 2),
              ),
              child: ClipOval(child: _peer()),
            ),
          ),
          // Small avatar — the property thumbnail tucked into the corner.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: AppColors.goldAccent.withValues(alpha: 0.15),
              ),
              child: ClipOval(child: _property()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _peer() {
    final url = peerImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        // Down-sample once; the on-screen size is ~54dp.
        memCacheWidth: 162,
        memCacheHeight: 162,
        maxWidthDiskCache: 300,
        maxHeightDiskCache: 300,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, __) => _peerFallback(),
        errorWidget: (_, __, ___) => _peerFallback(),
      );
    }
    return _peerFallback();
  }

  Widget _peerFallback() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(
          fallbackInitial,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );

  Widget _property() {
    final url = propertyImageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 84,
        memCacheHeight: 84,
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
        fadeInDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        placeholder: (_, __) => _propertyFallback(),
        errorWidget: (_, __, ___) => _propertyFallback(),
      );
    }
    return _propertyFallback();
  }

  Widget _propertyFallback() => Container(
        color: AppColors.goldAccent.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Icon(Icons.home_outlined,
            size: 14.sp, color: AppColors.goldAccent),
      );
}

class _Info extends StatelessWidget {
  final String peerName;
  final String projectName;

  const _Info({required this.peerName, required this.projectName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          peerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textBlack.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          projectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _RightSide extends StatelessWidget {
  final String currency;
  final double? price;
  final int messageCount;

  const _RightSide({
    required this.currency,
    required this.price,
    required this.messageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Price pill in gold.
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '$currency ${_format(price)}',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        if (messageCount > 0)
          Container(
            width: 20.w,
            height: 20.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              messageCount > 9 ? '9+' : '$messageCount',
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
          ),
      ],
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
