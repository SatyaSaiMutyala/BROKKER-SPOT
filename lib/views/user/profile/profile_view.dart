import 'dart:math';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _VerifiedArcPainter extends CustomPainter {
  final bool isVerified;
  _VerifiedArcPainter({required this.isVerified});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVerified) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Green arc from ~120° (bottom-right) to ~340° (top-right)
    // In canvas: 0°=right, 90°=bottom, 180°=left, 270°=top
    const startAngle = 120 * pi / 180; // ~4-5 o'clock
    const endAngle = 340 * pi / 180; // ~1 o'clock
    const sweepAngle = endAngle - startAngle; // ~220°

    // Draw thick green arc band
    final arcPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw each letter of "Verified" along the arc
    const text = 'V e r i f i e d';
    final letters = text.split('');
    // Place text in the middle portion of the arc
    final textStartAngle = startAngle + sweepAngle * 0.25;
    final textSweep = sweepAngle * 0.55;

    for (int i = 0; i < letters.length; i++) {
      final letterAngle =
          textStartAngle + (i / (letters.length - 1)) * textSweep;

      final tp = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      canvas.save();
      final x = center.dx + radius * cos(letterAngle);
      final y = center.dy + radius * sin(letterAngle);
      canvas.translate(x, y);
      // Rotate letter to follow the arc tangent
      canvas.rotate(letterAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Gold circle badge with white star at the end of arc (~340°)
    final badgeAngle = endAngle;
    final badgeX = center.dx + radius * cos(badgeAngle);
    final badgeY = center.dy + radius * sin(badgeAngle);
    final badgeCenter = Offset(badgeX, badgeY);
    const badgeRadius = 10.0;

    // Gold circle background
    final badgeBgPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBgPaint);

    // White star inside the badge
    _drawStar(canvas, badgeCenter, 6.0, Paint()..color = Colors.white);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = -pi / 2 + (i * pi / points);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VerifiedArcPainter oldDelegate) =>
      oldDelegate.isVerified != isVerified;
}

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'My Account',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_outlined,
                size: 22.sp, color: AppColors.primary),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              _buildProfileHeader(),
              SizedBox(height: 24.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 20.h),
              _buildInfoSection(
                'Areas',
                controller.dealingAreas.isNotEmpty
                    ? controller.dealingAreas.join(', ')
                    : 'Not added yet',
              ),
              SizedBox(height: 20.h),
              _buildInfoSection(
                'Language',
                controller.knownLanguages.isNotEmpty
                    ? controller.knownLanguages.join(', ')
                    : 'Not added yet',
              ),
              SizedBox(height: 20.h),
              _buildInfoSection(
                'About me',
                controller.profileData.value?['aboutMe'] ??
                    'No description added yet.',
              ),
              SizedBox(height: 24.h),
              _buildBoostSection(),
              SizedBox(height: 30.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader() {
    final bool isVerified =
        controller.profileData.value?['isEmailVerified'] == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Avatar + Name
        Column(
          children: [
            // Profile image with verified arc + star
            SizedBox(
              width: 110.w,
              height: 110.w,
              child: CustomPaint(
                painter: _VerifiedArcPainter(isVerified: isVerified),
                child: Center(
                  child: Container(
                    width: 84.w,
                    height: 84.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: ClipOval(
                      child: controller.profileImage.value.isNotEmpty
                          ? Image.network(
                              controller.profileImage.value,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 38.sp,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 38.sp,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            // Name
            Text(
              controller.userName.value.isNotEmpty
                  ? controller.userName.value
                  : '-',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),

        SizedBox(width: 16.w),

        // Right: Experience, Following, License with BRN/ORN columns
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Experience & Following row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        'Experience',
                        controller.profileData.value?['experience'] ?? '-',
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        'Following',
                        controller.profileData.value?['following']
                                ?.toString() ??
                            '0',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // License label
                Text(
                  'License',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                // BRN under Experience, ORN under Following
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BRN : ${controller.profileData.value?['brn'] ?? '-'}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'ORN : ${controller.profileData.value?['orn'] ?? '-'}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBoostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Boost Your Profile For 7 days',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.info_outline,
              size: 16.sp,
              color: Colors.green,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'AED  20',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
