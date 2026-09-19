import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/utils/brokerage_label.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// The broker's "Send Proposal to Owner" bar on a property's detail screen.
///
/// With a fee on the listing, a card: what the broker earns on the left, the
/// pill on the right. Without one, the pill on its own.
///
/// Laid out to fit any width rather than to a fixed design size: the pill is
/// capped at a share of the space and its label scales down inside it, and
/// the commission text does the same on its side — so a narrow phone shrinks
/// the text instead of overflowing, and a tablet doesn't stretch the pill.
class SendProposalBar extends StatelessWidget {
  /// What the broker earns, or null when the listing pays no fee.
  final double? commission;
  final String currency;
  final String? ownerAvatarUrl;
  final VoidCallback onTap;

  const SendProposalBar({
    super.key,
    required this.commission,
    required this.currency,
    required this.ownerAvatarUrl,
    required this.onTap,
  });

  /// Widest the pill gets on its own — past this it just looks stretched.
  static const double _maxPillWidth = 360;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = commission;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      if (amount == null) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width.isFinite
                  ? width.clamp(0, _maxPillWidth).toDouble()
                  : _maxPillWidth,
            ),
            child: _pill(),
          ),
        );
      }

      // Room for the card's own padding and the divider, then the pill takes
      // up to 62% of what is left and the commission gets the rest.
      final inner = (width.isFinite ? width : 400.0) - 16.w - 8.w - 25.w;
      final pillMax = (inner * 0.62).clamp(0.0, _maxPillWidth).toDouble();

      return Container(
        padding: EdgeInsets.fromLTRB(16.w, 8.r, 8.w, 8.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(child: _commission(amount, isDark)),
            Container(
              width: 1,
              height: 44.r,
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              color: isDark ? Colors.white12 : const Color(0xFFE3E3E3),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: pillMax),
              child: _pill(),
            ),
          ],
        ),
      );
    });
  }

  Widget _commission(double amount, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Broker Commission',
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF555555),
            ),
          ),
        ),
        SizedBox(height: 4.r),
        // Large amounts shrink rather than wrap or clip.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$currency ${groupedPrice(amount)}',
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF444444),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill() {
    // Sized off .r — the smaller of the width and height scales — so the
    // round photo stays round and in proportion on tall phones and tablets.
    final avatarSize = 52.r;
    final avatar = ownerAvatarUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: avatarSize + 8.r,
        padding: EdgeInsets.fromLTRB(16.w, 4.r, 4.r, 4.r),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(avatarSize),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Paper plane, pointing up and right.
            Transform.rotate(
              angle: -0.6,
              child: Icon(Icons.send_outlined,
                  size: 24.r, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            // Gives way first when the pill is capped: the label scales down,
            // the photo and the icon keep their size.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Send Proposal\nto Owner',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9E1CC),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: avatar != null && avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.person,
                            size: 28.r, color: Colors.white),
                      )
                    : Icon(Icons.person, size: 28.r, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
