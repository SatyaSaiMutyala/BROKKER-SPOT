import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class BrokerReviewSheet extends StatefulWidget {
  final String brokerName;
  final String? brokerAvatarUrl;

  const BrokerReviewSheet({
    super.key,
    required this.brokerName,
    this.brokerAvatarUrl,
  });

  @override
  State<BrokerReviewSheet> createState() => _BrokerReviewSheetState();
}

class _BrokerReviewSheetState extends State<BrokerReviewSheet> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Broker review',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 22.sp, color: Colors.red.shade300),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Avatar + name
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: widget.brokerAvatarUrl != null
                  ? Image.asset(widget.brokerAvatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, size: 32.sp, color: Colors.grey))
                  : Icon(Icons.person, size: 32.sp, color: Colors.grey),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.brokerName,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20.h),
          // Rate label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rate to broker',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Stars
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 32.sp,
                    color: AppColors.goldAccent,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 20.h),
          // Review text label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rate to broker',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Text area
          Container(
            height: 100.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Write here',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    counterText: '',
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  right: 14.w,
                  child: Text(
                    '${_reviewController.text.length}/100',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'rating': _rating,
                'review': _reviewController.text,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'SUBMIT',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
