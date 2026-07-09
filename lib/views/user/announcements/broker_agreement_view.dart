import 'dart:math';

import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/contract_accepted_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BrokerAgreementView extends StatefulWidget {
  final String announcementId;
  final VoidCallback onAccept;
  final String? propertyName;
  final String? location;
  final int? brokeragePercent;
  final String? agreementUrl;

  const BrokerAgreementView({
    super.key,
    required this.announcementId,
    required this.onAccept,
    this.propertyName,
    this.location,
    this.brokeragePercent,
    this.agreementUrl,
  });

  @override
  State<BrokerAgreementView> createState() => _BrokerAgreementViewState();
}

class _BrokerAgreementViewState extends State<BrokerAgreementView> {
  int _step = 2;
  bool _agreed = false;
  bool _isLoading = false;

  String get _userName {
    if (Get.isRegistered<ProfileController>()) {
      final name = Get.find<ProfileController>().userName.value;
      if (name.isNotEmpty) return name;
    }
    return 'Your Name';
  }

  static const _stepLabels = ['Proposal\nAccepted', 'Agreement', 'Acceptance'];

  static const _terms = [
    _TermItem(Icons.home_outlined, 'Property Details',
        'Information about the property owner'),
    _TermItem(Icons.local_offer_outlined, 'Brokerage & Commission',
        'Your commission and payment terms'),
    _TermItem(Icons.calendar_today_outlined, 'Payment Terms',
        'When and how you will be paid'),
    _TermItem(Icons.people_outline, 'Responsibilities',
        'Duties of both parties'),
    _TermItem(Icons.shield_outlined, 'Legal Terms',
        'Governing law and dispute resolution'),
  ];

  Future<void> _onNextOrAccept() async {
    if (_step == 2) {
      setState(() => _step = 3);
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please confirm that you agree to the terms.',
            style: GoogleFonts.inter(fontSize: 13.sp)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      widget.onAccept();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final contractId =
          'BRK-${DateTime.now().year}-${widget.announcementId.substring(0, min(6, widget.announcementId.length)).toUpperCase()}';
      Get.off(() => ContractAcceptedView(
            propertyName: widget.propertyName,
            location: widget.location,
            brokeragePercent: widget.brokeragePercent,
            contractId: contractId,
            announcementId: widget.announcementId,
          ));
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Broker Agreement',
              showBackButton: true,
              trailing: Text(
                '$_step/3',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8.h),
                    _buildStepIndicator(isDark),
                    SizedBox(height: 28.h),
                    _buildCenterIcon(isDark),
                    SizedBox(height: 16.h),
                    Text(
                      _step == 2 ? 'Broker Agreement Summary' : 'Almost There!',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _step == 2
                          ? 'Please review the key terms of the agreement.'
                          : 'Please confirm your acceptance and sign.',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),
                    _step == 2 ? _buildStep2Content(isDark) : _buildStep3Content(isDark),
                    SizedBox(height: 20.h),
                    _buildInfoBanner(),
                    SizedBox(height: 14.h),
                    _buildViewContractButton(isDark),
                    SizedBox(height: 28.h),
                  ],
                ),
              ),
            ),
            _buildBottomButton(isDark),
          ],
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepNode(n: 1, isDone: true, label: _stepLabels[0]),
        Expanded(child: _stepConnector(isGold: true)),
        _stepNode(n: 2, isDone: _step > 2, isCurrent: _step == 2, label: _stepLabels[1]),
        Expanded(child: _stepConnector(isGold: _step > 2)),
        _stepNode(n: 3, isDone: false, isCurrent: _step == 3, label: _stepLabels[2]),
      ],
    );
  }

  Widget _stepNode({
    required int n,
    bool isDone = false,
    bool isCurrent = false,
    required String label,
  }) {
    final isActive = isDone || isCurrent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.transparent,
            border: isActive
                ? null
                : Border.all(color: Colors.grey.shade600, width: 1.5),
          ),
          alignment: Alignment.center,
          child: isDone
              ? Icon(Icons.check_rounded,
                  color: Colors.white, size: 18.sp)
              : Text(
                  '$n',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey.shade500,
                    height: 1.0,
                  ),
                ),
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: 70.w,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.grey.shade400,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector({required bool isGold}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30.h),
      child: Center(
        child: Container(
          height: 2,
          color: isGold ? AppColors.primary : Colors.grey.shade700,
        ),
      ),
    );
  }

  // ── Center icon ───────────────────────────────────────────────────────────

  Widget _buildCenterIcon(bool isDark) {
    final circleBg = isDark ? const Color(0xFF252525) : const Color(0xFF2A2A2A);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88.w,
          height: 88.w,
          decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(Icons.description_outlined, color: Colors.white, size: 44.sp),
        ),
        if (_step == 2)
          Positioned(
            right: -4.w,
            bottom: -4.h,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: circleBg, width: 2),
              ),
              child: Icon(Icons.shield_outlined,
                  color: Colors.white, size: 16.sp),
            ),
          )
        else
          Positioned(
            right: -4.w,
            bottom: -4.h,
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: circleBg, width: 2),
              ),
              child: Icon(Icons.check_rounded,
                  color: Colors.white, size: 16.sp),
            ),
          ),
      ],
    );
  }

  // ── Step 2 content: term list ─────────────────────────────────────────────

  Widget _buildStep2Content(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = Colors.grey.shade500;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(
        children: _terms.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252525)
                            : const Color(0xFFF0ECD5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(item.icon,
                          size: 20.sp, color: AppColors.primary),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                  height: 1.2)),
                          SizedBox(height: 2.h),
                          Text(item.subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: subtitleColor,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _terms.length - 1)
                Divider(height: 1, thickness: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Step 3 content: checkbox + signature ──────────────────────────────────

  Widget _buildStep3Content(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox card
        GestureDetector(
          onTap: () => setState(() => _agreed = !_agreed),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                  color: _agreed ? AppColors.primary : border, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22.w,
                  height: 22.w,
                  margin: EdgeInsets.only(top: 2.h),
                  decoration: BoxDecoration(
                    color: _agreed ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(5.r),
                    border: Border.all(
                      color: _agreed ? AppColors.primary : Colors.grey.shade500,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _agreed
                      ? Icon(Icons.check_rounded,
                          size: 14.sp, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'I confirm that i have read and understood the broker mandate agreement and agree to the terms and conditions.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 22.h),
        // Signature section
        Text(
          'Your signature',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          height: 130.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          alignment: Alignment.center,
          child: Text(
            _userName,
            style: GoogleFonts.pacifico(
              fontSize: 32.sp,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 13.sp, color: Colors.grey.shade500),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'Your signature is secure and legally binding.',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    const bannerBg = Color(0xFF0F2E13);
    const bannerBorder = Color(0xFF2D6A34);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16.sp, color: const Color(0xFF4CAF50)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _step == 2
                  ? 'By accepting you agree to the full broker mandate agreement.'
                  : 'Your signed agreement will be securely stored and sent to the property owner.',
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

  // ── View Contract button ──────────────────────────────────────────────────

  Widget _buildViewContractButton(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEDEDED);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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

  // ── Bottom button ─────────────────────────────────────────────────────────

  Widget _buildBottomButton(bool isDark) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final label = _step == 2 ? 'NEXT' : 'I Accept';
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFF3A3A3A);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + bottomPad),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: GestureDetector(
          onTap: _isLoading ? null : _onNextOrAccept,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28.r),
            ),
            alignment: Alignment.center,
            child: _isLoading
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _TermItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TermItem(this.icon, this.title, this.subtitle);
}
