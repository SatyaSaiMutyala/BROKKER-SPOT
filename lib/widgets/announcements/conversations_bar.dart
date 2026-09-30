import 'dart:ui';

import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// The pill at the bottom of a broker's own announcement: who has written to
/// them about it, and the way into those conversations.
///
/// The broker-side twin of the owner's "Interested Brokers" bar on
/// AnnouncementDetailView — same size, same glass, same avatar stack — so the
/// two detail screens end the same way.
///
/// [count] comes with the announcement itself and is known straight away;
/// [people] arrives afterwards over the socket. Until it does, the count is
/// shown on its own rather than holding the bar back.
class ConversationsBar extends StatelessWidget {
  final int count;
  final List<ChatProfileSummary> people;
  final VoidCallback onTap;
  final bool isDark;

  const ConversationsBar({
    super.key,
    required this.count,
    required this.people,
    required this.onTap,
    required this.isDark,
  });

  static const String title = 'Interested Clients';
  static const String subtitle = 'Select and start chat';

  /// "9+" past nine, the same cap the meeting cards use.
  static String countLabel(int count) => count > 9 ? '9+' : '$count';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(77.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 67.h,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0x80333333) : const Color(0x80E1E1E1),
              borderRadius: BorderRadius.circular(77.r),
            ),
            padding: EdgeInsets.fromLTRB(19.w, 0, 11.w, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primary,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xFF6C6C6C),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                people.isEmpty ? _countOnly() : _avatarStack(),
                SizedBox(width: 7.w),
                Icon(Icons.chevron_right, size: 16.sp, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shown while the people behind the count are still on their way.
  Widget _countOnly() {
    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: Text(
        countLabel(count),
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _avatarStack() {
    const double sz = 49.0;
    // Left edges of up to three overlapping avatars, as on the owner's bar.
    const List<double> offsets = [0.0, 12.0, 22.0];
    final shown = people.take(3).toList();
    final totalW = offsets[shown.length - 1] + sz;

    return SizedBox(
      width: totalW.w,
      height: sz.h,
      child: Stack(
        children: [
          // Back to front, so the first person sits on top.
          for (int i = shown.length - 1; i >= 0; i--)
            Positioned(left: offsets[i].w, child: _avatar(shown[i], sz)),
          // A lone avatar already says "one"; the number only adds something
          // once there is more than one person behind it.
          if (count > 1)
            Positioned(
              left: (offsets[shown.length - 1] + 1).w,
              top: (sz - 21) / 2,
              child: Text(
                countLabel(count),
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatar(ChatProfileSummary person, double sz) {
    // These are the broker's clients, so their own photo comes first.
    final url = person.profileImageUrl?.isNotEmpty == true
        ? person.profileImageUrl
        : person.brokerProfileImageUrl;

    return Container(
      width: sz.w,
      height: sz.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3A3A3A),
        border: Border.all(color: const Color(0x6BDBC483), width: 1),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() =>
      Icon(Icons.person, size: 22.sp, color: Colors.white54);
}
