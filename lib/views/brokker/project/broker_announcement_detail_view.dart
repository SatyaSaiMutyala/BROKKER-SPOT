import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/models/announcement_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class BrokerAnnouncementDetailView extends StatefulWidget {
  final AnnouncementModel announcement;

  const BrokerAnnouncementDetailView({
    super.key,
    required this.announcement,
  });

  @override
  State<BrokerAnnouncementDetailView> createState() =>
      _BrokerAnnouncementDetailViewState();
}

class _BrokerAnnouncementDetailViewState
    extends State<BrokerAnnouncementDetailView> {
  static const List<String> _fallbackImages = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
  ];

  String _formatPrice(double price) {
    String str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  void _showProposalSheet() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
        child: _ProposalSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final images =
        (a.imageUrls?.isNotEmpty ?? false) ? a.imageUrls! : _fallbackImages;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              CustomHeader(
                title: 'Details',
                showBackButton: true,
                trailing: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  child: Text(
                    a.listingType ?? 'For Rent',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              // ── Scrollable content ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with View All
                      _buildImageSection(images),

                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price row + Interested button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Price on the left
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'AED ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _formatPrice(a.price ?? 0),
                                          style: GoogleFonts.poppins(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' Yearly',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w300,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Interested button on the right
                                GestureDetector(
                                  onTap: _showProposalSheet,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(16.r),
                                    ),
                                    child: Text(
                                      'Interested',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),

                            // Property name
                            Text(
                              a.propertyName ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Divider(
                              height: 1,
                              thickness: 0.8,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 8.h),

                            // Property Info section
                            _sectionTitle('Property Info'),
                            SizedBox(height: 10.h),
                            _infoRow('Apartment'),
                            _infoRow('${a.sqft ?? 847} sqft / ${((a.sqft ?? 847) * 0.0929).toStringAsFixed(0)} sqm Property size'),
                            _infoRow('${a.bedrooms ?? 2} Bedroom'),
                            _infoRow('1 Bathroom'),
                            SizedBox(height: 16.h),

                            // Description section
                            _sectionTitle('Description'),
                            SizedBox(height: 8.h),
                            Text(
                              'Lorem ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen.',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: AppColors.textHint,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Location section
                            _sectionTitle('Location'),
                            SizedBox(height: 8.h),
                            _buildMapBox(a.location ?? ''),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 220.h,
          width: double.infinity,
          child: Image.asset(
            images.first,
            fit: BoxFit.cover,
          ),
        ),
        // View All pill
        Positioned(
          bottom: 12.h,
          right: 12.w,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColors.textWhite,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }

  Widget _buildMapBox(String location) {
    return GestureDetector(
      onTap: () async {
        final query = Uri.encodeComponent(location);
        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 160.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Map grid background
            CustomPaint(
              size: Size(double.infinity, 160.h),
              painter: _MapGridPainter(),
            ),
            // Center pin
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on,
                      size: 36.sp, color: Colors.red.shade600),
                  Container(
                    width: 8.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            // Address bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                color: Colors.white.withValues(alpha: 0.92),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14.sp, color: AppColors.teal),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new,
                        size: 13.sp, color: AppColors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proposal bottom sheet ──
class _ProposalSheet extends StatefulWidget {
  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  final TextEditingController _controller = TextEditingController();
  final int _maxLength = 50;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitted = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
      child: _submitted
          ? _buildSuccess()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Write Proposal Message To Buyer',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 14.h),

                // Text area
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: _maxLength,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxLength),
                    ],
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write Here...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ),

                // Character counter
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      '$charCount/$_maxLength',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Send Proposal Request',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.h),
        Container(
          width: 60.w,
          height: 60.w,
          decoration: const BoxDecoration(
            color: AppColors.successGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: Colors.white, size: 32.sp),
        ),
        SizedBox(height: 12.h),
        Text(
          'Proposal Sent!',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your proposal has been sent to the buyer.',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Light background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EFF4),
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;

    final minorPaint = Paint()
      ..color = const Color(0xFFD6E0E8)
      ..strokeWidth = 1;

    // Horizontal roads
    for (double y = 30; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Vertical roads
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    // Minor grid lines
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }

    // A couple of block fills to look like buildings
    final blockPaint = Paint()..color = const Color(0xFFCDD8E0);
    canvas.drawRect(Rect.fromLTWH(10, 40, 50, 30), blockPaint);
    canvas.drawRect(Rect.fromLTWH(80, 10, 40, 40), blockPaint);
    canvas.drawRect(Rect.fromLTWH(145, 55, 55, 25), blockPaint);
    canvas.drawRect(Rect.fromLTWH(220, 15, 35, 45), blockPaint);
    canvas.drawRect(Rect.fromLTWH(10, 90, 60, 35), blockPaint);
    canvas.drawRect(Rect.fromLTWH(90, 85, 45, 30), blockPaint);
    canvas.drawRect(Rect.fromLTWH(160, 90, 50, 28), blockPaint);
    canvas.drawRect(Rect.fromLTWH(230, 80, 40, 35), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
