import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/create_announcement_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
class ContractAcceptedView extends StatelessWidget {
  final String? propertyName;
  final String? location;
  final int? brokeragePercent;
  final String? contractId;
  final String? announcementId;

  const ContractAcceptedView({
    super.key,
    this.propertyName,
    this.location,
    this.brokeragePercent,
    this.contractId,
    this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(
              title: 'Contract Accepted',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 28.h),
                    // Success icon
                    Container(
                      width: 88.w,
                      height: 88.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.check_rounded,
                          color: Colors.white, size: 48.sp),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Contract Accepted!',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        'You have successfully accepted the broker mandate agreement.',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    _buildDetailsCard(isDark, dateStr),
                    SizedBox(height: 16.h),
                    _buildMarketingBanner(),
                    SizedBox(height: 14.h),
                    _buildViewContractButton(isDark),
                    SizedBox(height: 28.h),
                  ],
                ),
              ),
            ),
            _buildAnnounceButton(isDark, bottomPad),
          ],
        ),
      ),
    );
  }



  // ── Details card ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard(bool isDark, String dateStr) {
    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFEDEDED);

    final rows = <_DetailRow>[
      _DetailRow('Property',
          propertyName?.isNotEmpty == true
              ? propertyName!
              : 'N/A'),
      _DetailRow('Location',
          location?.isNotEmpty == true ? location! : 'N/A'),
      _DetailRow('Brokerage',
          brokeragePercent != null ? '$brokeragePercent%' : 'N/A'),
      _DetailRow('Contract ID',
          contractId?.isNotEmpty == true ? contractId! : 'N/A'),
      _DetailRow('Date', dateStr),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100.w,
                      child: Text(
                        row.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade500,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(height: 1, thickness: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Marketing banner ──────────────────────────────────────────────────────

  Widget _buildMarketingBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E13),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF2D6A34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16.sp, color: const Color(0xFF4CAF50)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'You can now start marketing this property',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── View contract button ──────────────────────────────────────────────────

  Widget _buildViewContractButton(bool isDark) {
    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFEDEDED);
    final textColor =
        isDark ? Colors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 22.sp, color: AppColors.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'View Contract (PDF)',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 22.sp, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // ── Announce Now button ───────────────────────────────────────────────────

  Widget _buildAnnounceButton(bool isDark, double bottomPad) {
    return Container(
      color:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      padding: EdgeInsets.fromLTRB(
          20.w, 12.h, 20.w, 12.h + bottomPad),
      child: GestureDetector(
        onTap: () => Get.to(
            () => const CreateAnnouncementView(fromBroker: true)),
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: const Color(0xFF2E2E2E)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined,
                  size: 22.sp, color: AppColors.primary),
              SizedBox(width: 10.w),
              Text(
                'Announce Now',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _DetailRow {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
}
