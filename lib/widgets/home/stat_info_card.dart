import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One value+label row inside a [StatInfoCard], e.g. `25` / `OWN`.
class StatInfoCardRow {
  final String value;
  final String label;

  const StatInfoCardRow({required this.value, required this.label});
}

/// Broker home dashboard stat card (Leads / Story / Announcements /
/// Commission). A titled header band sits on top of a raised body panel that
/// lists one gold circle badge per row — data-driven so all four cards share
/// one implementation.
class StatInfoCard extends StatelessWidget {
  /// How much each badge is pulled toward its neighbour, in design px.
  static const double _badgeOverlap = 7;

  final String title;
  final List<StatInfoCardRow> rows;

  const StatInfoCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(12.r);

    return Container(
      width: double.infinity,
      height: 141.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242833) : Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x14000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // Painted over the child so the header band can't cover the hairline.
      foregroundDecoration: isDark
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: const Color(0xFF3B404B), width: 1),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36.h,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2F3440) : const Color(0xFF7A7575),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            // ANNOUNCEMENTS is the longest title — shrink rather than clip.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isDark
                      ? const Color(0xFFC9AE6A)
                      : const Color(0xFFF6F1E6),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                // Laid out bottom-up so the rows are listed in reverse. A
                // Column paints in list order, so the upper badge paints last
                // and stays fully visible where the two overlap.
                verticalDirection: VerticalDirection.up,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = rows.length - 1; i >= 0; i--)
                    // The badges are stacked flush by layout, so pull them
                    // into each other with a symmetric shift — that tightens
                    // the gap without moving the group off centre.
                    Transform.translate(
                      offset: Offset(
                        0,
                        (i - (rows.length - 1) / 2) * -_badgeOverlap.h,
                      ),
                      child: _StatRow(
                        row: rows[i],
                        // Light theme fades every row after the first; dark
                        // theme keeps them all solid gold.
                        badgeColor: isDark || i == 0
                            ? const Color(0xFFC8AF69)
                            : const Color(0xFFE3D6B2),
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final StatInfoCardRow row;
  final Color badgeColor;
  final bool isDark;

  const _StatRow({
    required this.row,
    required this.badgeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor,
          ),
          child: Text(
            row.value,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Flexible(
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF3C3C3C),
            ),
          ),
        ),
      ],
    );
  }
}
