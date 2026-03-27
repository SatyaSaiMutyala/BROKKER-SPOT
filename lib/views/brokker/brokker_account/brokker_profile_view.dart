import 'dart:math';
import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_account_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
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
    final radius = size.width / 2 - 6;

    // Arc from 6 o'clock to 3 o'clock going SHORT way (bottom-right quarter)
    // 6 o'clock = 90° canvas, 3 o'clock = 0°/360° canvas
    // Sweep: from 90° going NEGATIVE (counter-clockwise) 90° to reach 0°
    const startAngle = 90 * pi / 180; // 6 o'clock (bottom)
    const sweepAngle = -(90 * pi / 180); // 90° counter-clockwise to 3 o'clock
    // Badge will be at 0° (3 o'clock / right side)

    // Draw thick green arc band
    final arcPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw each letter of "Verified" along the arc
    // Arc goes from 90° (6 o'clock) to 0° (3 o'clock) counter-clockwise
    // "V" near 6 o'clock, "d" near 3 o'clock — so letters go from high angle to low
    const letters = ['V', 'e', 'r', 'i', 'f', 'i', 'e', 'd'];
    const textPadding = 0.1; // 10% padding from edges
    final arcStart = startAngle + sweepAngle * textPadding; // near 6 o'clock
    final arcTextSweep = sweepAngle * (1 - 2 * textPadding);

    for (int i = 0; i < letters.length; i++) {
      final letterAngle = arcStart + (i / (letters.length - 1)) * arcTextSweep;

      final tp = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
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
      // Rotate letter: tangent direction is letterAngle - pi/2 for counter-clockwise
      canvas.rotate(letterAngle - pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Gold circle badge with white star at 3 o'clock (right side)
    const badgeAngle = 0.0;
    final badgeX = center.dx + radius * cos(badgeAngle);
    final badgeY = center.dy + radius * sin(badgeAngle);
    final badgeCenter = Offset(badgeX, badgeY);
    const badgeRadius = 12.0;

    // Gold circle background
    final badgeBgPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(badgeCenter, badgeRadius, badgeBgPaint);

    // White star inside the badge
    _drawStar(canvas, badgeCenter, 7.0, Paint()..color = Colors.white);
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

class BrokerProfileView extends StatelessWidget {
  BrokerProfileView({super.key});

  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'My Account',
              trailing: GestureDetector(
                onTap: () {
                  Get.to(() => AccountMenuView());
                },
                child: Icon(
                  Icons.settings_outlined,
                  size: 22.sp,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
            Expanded(child: Obx(() {
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
      })),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final data = controller.profileData.value;
    final bool isVerified = data?['verificationStatus'] == 'approved';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Avatar + Name
        Column(
          children: [
            // Profile image with verified arc + star
            GestureDetector(
              onTap: () => FullScreenImageView.show(
                imageUrl: controller.profileImage.value.isNotEmpty
                    ? controller.profileImage.value
                    : null,
                assetPath: controller.profileImage.value.isEmpty
                    ? 'assets/images/profile.jpg'
                    : null,
              ),
              child: SizedBox(
                width: 110.w,
                height: 110.w,
                child: CustomPaint(
                  foregroundPainter:
                      _VerifiedArcPainter(isVerified: isVerified),
                child: Center(
                  child: Container(
                    width: 96.w,
                    height: 96.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: ClipOval(
                      child: controller.profileImage.value.isNotEmpty
                          ? Image.network(
                              controller.profileImage.value,
                              fit: BoxFit.cover,
                              width: 96.w,
                              height: 96.w,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/profile.jpg',
                                fit: BoxFit.cover,
                                width: 96.w,
                                height: 96.w,
                              ),
                            )
                          : Image.asset(
                              'assets/images/profile.jpg',
                              fit: BoxFit.cover,
                              width: 96.w,
                              height: 96.w,
                            ),
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

        SizedBox(width: 36.w),

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
                        data?['experience']?.toString() ?? '-',
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        'Following',
                        data?['following']?.toString() ?? '0',
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
                        'BRN : ${data?['bnrNumber'] ?? '-'}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'ORN : ${data?['orn'] ?? '-'}',
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
