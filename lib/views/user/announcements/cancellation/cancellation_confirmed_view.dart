import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/cancellation_theme.dart';
import 'package:brokkerspot/views/user/announcements/cancellation/contract_property_card.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Terminal screen of the cancellation flow: the 48 hours elapsed, the server
/// cron moved the proposal to status 6 and took the broker's listing down.
///
/// Reached from the contract details screen once it observes status 6 — there
/// is nothing left to act on here, only the record of what happened.
class CancellationConfirmedView extends StatelessWidget {
  final AnnouncementModel? announcement;
  final String? contractId;
  final DateTime? contractStart;
  final String? reason;

  const CancellationConfirmedView({
    super.key,
    this.announcement,
    this.contractId,
    this.contractStart,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CancelTheme.scaffold(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 20.h),
                children: [
                  const Center(child: _CancelledMark()),
                  SizedBox(height: 30.h),
                  Text(
                    'Contract Cancellation Confirmed',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: CancelTheme.title(isDark),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'The 48-hour withdrawal period has ended.\n'
                    'The contract has been canceled.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w300,
                      height: 1.6,
                      color: CancelTheme.body(isDark),
                    ),
                  ),
                  SizedBox(height: 26.h),
                  ContractPropertyCard(
                    announcement: announcement,
                    statusLabel: 'Canceled',
                    statusColor: CancelTheme.red,
                    isDark: isDark,
                  ),
                  SizedBox(height: 6.h),
                  // Rows the record does not carry are left out rather than
                  // shown empty — see ContractDetailsView for the same rule.
                  if (contractStart != null)
                    CancelTheme.detailRow(
                      icon: Icons.event_outlined,
                      label: 'Contract Start Date',
                      value: _formatDate(contractStart!),
                      isDark: isDark,
                    ),
                  if (contractId != null && contractId!.isNotEmpty)
                    CancelTheme.detailRow(
                      icon: Icons.description_outlined,
                      label: 'Contract ID',
                      value: contractId!,
                      isDark: isDark,
                    ),
                  if (reason != null && reason!.trim().isNotEmpty)
                    CancelTheme.detailRow(
                      icon: Icons.info_outline,
                      label: 'Reason',
                      value: reason!.trim(),
                      isDark: isDark,
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, 16.h),
              child: CancelTheme.primaryButton(
                label: 'Back to Home',
                // Everything below this screen describes a contract that no
                // longer exists — the chat banner, the details screen — so the
                // stack is dropped rather than popped back through.
                onPressed: () => Get.offAll(() => const DashboardView()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// The red document mark, ringed by the same confetti dots as the success
/// screen so the two endings of the flow are visibly a pair.
class _CancelledMark extends StatelessWidget {
  const _CancelledMark();

  @override
  Widget build(BuildContext context) {
    final ring = 96.w;

    return SizedBox(
      width: ring * 1.7,
      height: ring * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ring,
            height: ring,
            decoration: const BoxDecoration(
              color: CancelTheme.redBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.assignment_late_outlined,
              size: (ring * 0.44).sp,
              color: CancelTheme.red,
            ),
          ),
        ],
      ),
    );
  }
}
