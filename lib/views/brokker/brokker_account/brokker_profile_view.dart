import 'dart:math';
import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/session_cleanup.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_my_information_view.dart';
import 'package:brokkerspot/views/brokker/project/broker_projects_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
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

/// Broker "Account" tab — profile header (avatar + verified ribbon, name,
/// email) followed by a menu list. Every action from the old stats screen
/// and the settings sub-menu lives here now, just restyled into one dark
/// card list instead of two separate screens.
class BrokerProfileView extends StatelessWidget {
  BrokerProfileView({super.key});

  final ProfileController controller = Get.put(ProfileController());

  static const _avatarSize = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Text(
                'Account',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 24.h),
                      _buildProfileHeader(theme),
                      SizedBox(height: 28.h),
                      _buildCardGroup(theme, [
                        _menuItem(
                          theme,
                          'assets/images/broker_my_profile_icon.png',
                          'Manage Profile',
                          () => Get.to(() => const BrokerMyInformationView()),
                        ),
                        _menuItem(
                          theme,
                          'assets/images/broker_announcement.png',
                          'My Announcements',
                          () => Get.to(() =>
                              const BrokerProjectsView(showMineOnly: true)),
                        ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/broker_mydeal_icon.png',
                        //   'My Deals',
                        //   () {},
                        // ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/broker_bank_icon.png',
                        //   'My Bank Account Details',
                        //   () {},
                        // ),
                        _menuItem(
                          theme,
                          'assets/images/broker_wishlist_icon.png',
                          'Wishlist',
                          () {},
                        ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/subscription_icon.png',
                        //   'My Subscription',
                        //   () {},
                        // ),
                        _menuItem(
                          theme,
                          'assets/images/broker_settings_icon.png',
                          'Setting',
                          () => Get.to(() => SettingsView(side: 'broker')),
                          showDivider: false,
                        ),
                      ]),
                      SizedBox(height: 16.h),
                      _buildCardGroup(theme, [
                        _menuItem(
                          theme,
                          'assets/images/switch_to_user_icon.png',
                          'Switch to User side',
                          () => _switchToUser(),
                          showDivider: false,
                        ),
                      ]),
                      SizedBox(height: 30.h),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchToUser() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final ok = await controller.switchRole(1);
    if (Get.isDialogOpen ?? false) Get.back();
    if (ok) {
      LocalStorageService.saveLastSide('user');
      // Wipe broker-side cached data so the user side opens with fresh
      // role-correct responses, not stale broker-side payloads.
      await clearRoleScopedCache();
      Get.offAll(() => const DashboardView());
    }
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final data = controller.profileData.value;
    final bool isVerified = data?['verificationStatus'] == 'approved';
    const arcPad = 28.0;

    return Column(
      children: [
        GestureDetector(
          onTap: () => FullScreenImageView.show(
            imageUrl: controller.brokerProfileImage.value.isNotEmpty
                ? controller.brokerProfileImage.value
                : null,
            assetPath: controller.brokerProfileImage.value.isEmpty
                ? 'assets/images/profile.jpg'
                : null,
          ),
          child: SizedBox(
            width: (_avatarSize + arcPad).w,
            height: (_avatarSize + arcPad).w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isVerified)
                  CustomPaint(
                    size: Size(
                        (_avatarSize + arcPad).w, (_avatarSize + arcPad).w),
                    painter: _VerifiedArcPainter(isVerified: isVerified),
                  ),
                Container(
                  width: _avatarSize.w,
                  height: _avatarSize.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: ClipOval(
                    child: controller.brokerProfileImage.value.isNotEmpty
                        ? Image.network(
                            controller.brokerProfileImage.value,
                            fit: BoxFit.cover,
                            width: _avatarSize.w,
                            height: _avatarSize.w,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/profile.jpg',
                              fit: BoxFit.cover,
                              width: _avatarSize.w,
                              height: _avatarSize.w,
                            ),
                          )
                        : Image.asset(
                            'assets/images/profile.jpg',
                            fit: BoxFit.cover,
                            width: _avatarSize.w,
                            height: _avatarSize.w,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          controller.userName.value.isNotEmpty
              ? controller.userName.value
              : '-',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          controller.userEmail.value.isNotEmpty
              ? controller.userEmail.value
              : '-',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGroup(ThemeData theme, List<Widget> children) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    ThemeData theme,
    String assetPath,
    String title,
    VoidCallback onTap, {
    bool showDivider = true,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.goldAccent, width: 1),
                  ),
                  child: Image.asset(assetPath, width: 18.w, height: 18.w),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
      ],
    );
  }
}
