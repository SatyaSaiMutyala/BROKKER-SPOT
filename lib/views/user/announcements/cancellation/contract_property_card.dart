import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/cancellation_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thumbnail + name + address of the property a contract covers, with the
/// contract's own state as a coloured label underneath.
///
/// [announcement] is null while the detail request is still out; the card then
/// renders its own skeleton so the surrounding layout does not jump.
class ContractPropertyCard extends StatelessWidget {
  final AnnouncementModel? announcement;
  final String statusLabel;
  final Color statusColor;
  final bool isDark;

  const ContractPropertyCard({
    super.key,
    required this.announcement,
    required this.statusLabel,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final thumb = a?.propertyMedia?.thumbnail ?? '';
    final address = [a?.propertyAddress, a?.propertyCity, a?.propertyCountry]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: CancelTheme.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: CancelTheme.hairline(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 58.w,
              height: 58.w,
              child: thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a?.propertyName?.trim().isNotEmpty == true
                      ? a!.propertyName!
                      : (a == null ? 'Loading…' : 'Property'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: CancelTheme.title(isDark),
                  ),
                ),
                if (address.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w300,
                      height: 1.35,
                      color: CancelTheme.body(isDark),
                    ),
                  ),
                ],
                SizedBox(height: 5.h),
                Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: isDark ? const Color(0xFF23262E) : Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.home_outlined,
          size: 22.sp,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      );
}
