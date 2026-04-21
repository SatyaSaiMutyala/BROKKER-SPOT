import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class AnnouncementChatView extends StatefulWidget {
  final String brokerName;
  final String brokerAvatar;

  const AnnouncementChatView({
    super.key,
    required this.brokerName,
    required this.brokerAvatar,
  });

  @override
  State<AnnouncementChatView> createState() => _AnnouncementChatViewState();
}

class _AnnouncementChatViewState extends State<AnnouncementChatView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.teal,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // teal scaffold bg = status bar area is teal
        backgroundColor: AppColors.teal,
        body: Column(
          children: [
            // Top safe area — stays teal (scaffold bg)
            SizedBox(height: topPadding),

            // ── Teal header ──
            Container(
              color: AppColors.teal,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 20.sp, color: Colors.white),
                  ),
                  SizedBox(width: 20.w),
                  ClipOval(
                    child: Image.asset(
                      widget.brokerAvatar,
                      width: 40.w,
                      height: 40.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.brokerName,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(Icons.videocam_outlined,
                      color: Colors.white, size: 22.sp),
                  SizedBox(width: 16.w),
                  Icon(Icons.call_outlined, color: Colors.white, size: 22.sp),
                  SizedBox(width: 16.w),
                  Icon(Icons.more_vert, color: Colors.white, size: 22.sp),
                ],
              ),
            ),

            // ── Messages — white background ──
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  children: [
                    // Date separator
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // Received text bubble
                    _receivedBubble(
                      'Hi ${widget.brokerName}, It\'s Rachid um is simply dummy'
                      ' text of the printing and typesetting industryIpsum is'
                      ' simply dummy text of the printing and typesetting'
                      ' industry. LoremIpsum has been of the printing.',
                      '11:02 pm',
                    ),
                    SizedBox(height: 12.h),

                    // Received image + link bubble
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 260.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomRight: Radius.circular(16.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/rent1.png',
                              width: double.infinity,
                              height: 150.h,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 4.h),
                              child: GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse('http://ajknjkn/#005rachid');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Text(
                                  '//http:ajknjkn/#005rachid',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: AppColors.teal,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.teal,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 10.w, bottom: 8.h, left: 10.w),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '11:02 pm',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Sent bubble
                    _sentBubble('Hi...', '11:02'),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // ── Input bar — white background ──
            Material(
              color: Colors.white,
              elevation: 0,
              child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  12.w, 10.h, 12.w, 10.h + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Say Somthing...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 30.sp),
                    ),
                  ),
                ],
              ),
            ),
            ), // closes Material
          ],
        ),
      ),
    );
  }

  Widget _receivedBubble(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 260.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message,
                style:
                    GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87)),
            SizedBox(height: 4.h),
            Text(time,
                style: GoogleFonts.inter(
                    fontSize: 10.sp, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _sentBubble(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(minWidth: 90.w, maxWidth: 220.w),
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
              ),
              SizedBox(height: 4.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
