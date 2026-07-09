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
/// Commission). 171×141, translucent grey card, gold-gradient title, and a
/// gold circle badge per row — data-driven so all four cards share one
/// implementation.
class StatInfoCard extends StatelessWidget {
  final String title;
  final List<StatInfoCardRow> rows;

  const StatInfoCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 141.h,
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: const Color(0x33BEBEBE),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDBC483), Color(0xFFB08E32)],
            ).createShader(bounds),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          for (final row in rows) _StatRow(row: row),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final StatInfoCardRow row;

  const _StatRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 39.w,
          height: 39.w,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xCCC8AF69),
          ),
          child: Text(
            row.value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          row.label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w300,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}
