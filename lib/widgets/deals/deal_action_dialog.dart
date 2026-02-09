import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/project_deal_model.dart';

/// Reusable bottom dialog for deal tracking actions:
/// - Booking confirmation
/// - E-Signature confirmation
/// - SPA document confirmation
/// - Down payment confirmation
class DealActionDialog extends StatefulWidget {
  final ProjectDealModel deal;
  final String questionPrefix;
  final String highlightText;
  final String questionSuffix;
  final DealActionType actionType;

  const DealActionDialog({
    super.key,
    required this.deal,
    required this.questionPrefix,
    required this.highlightText,
    this.questionSuffix = '',
    required this.actionType,
  });

  @override
  State<DealActionDialog> createState() => _DealActionDialogState();
}

enum DealActionType { booking, eSignature, spaDocument, downPayment }

class _DealActionDialogState extends State<DealActionDialog> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final isYesNo = widget.actionType == DealActionType.eSignature ||
        widget.actionType == DealActionType.spaDocument;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property info row
          _buildPropertyInfo(),
          SizedBox(height: 18.h),
          // Checkbox question
          _buildCheckboxRow(),
          SizedBox(height: 18.h),
          // Action button(s)
          if (isYesNo) _buildYesNoButtons() else _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildPropertyInfo() {
    final d = widget.deal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AED ',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _formatPrice(d.price ?? 0),
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(
                    d.propertyName ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '#B277FHB',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                d.location ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // Broker avatar
        Column(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: d.brokerAvatarUrl != null
                    ? Image.asset(d.brokerAvatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, size: 22.sp, color: Colors.grey))
                    : Icon(Icons.person, size: 22.sp, color: Colors.grey),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              d.brokerName ?? '',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckboxRow() {
    return GestureDetector(
      onTap: () => setState(() => _isChecked = !_isChecked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: _isChecked ? AppColors.goldAccent : Colors.grey.shade400,
                width: 1.5,
              ),
              color: _isChecked
                  ? AppColors.goldAccent.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: _isChecked
                ? Icon(Icons.check, size: 16.sp, color: AppColors.goldAccent)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: widget.questionPrefix),
                  TextSpan(
                    text: widget.highlightText,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  TextSpan(text: widget.questionSuffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
        onPressed: _isChecked ? () => Navigator.pop(context, true) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isChecked ? AppColors.goldAccent : Colors.grey.shade200,
          foregroundColor: _isChecked ? Colors.white : Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: _isChecked
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          'Upload Booking Proof',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildYesNoButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isChecked ? () => Navigator.pop(context, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isChecked ? AppColors.goldAccent : Colors.grey.shade100,
                foregroundColor: _isChecked ? Colors.white : Colors.black54,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'NO',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    String str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(' ');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
