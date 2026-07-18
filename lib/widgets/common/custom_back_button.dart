import 'dart:math' show pi;
import 'dart:ui' as ui;
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Generic circle icon button with the same gradient + arc-highlight effect.
///
/// Light mode: solid [AppColors.backBtnLightBg] fill.
/// Dark mode: LinearGradient fill + two 90° sweep-gradient arc highlights.
class CustomIconButton extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final double size;
  final VoidCallback? onTap;

  const CustomIconButton({
    super.key,
    required this.isDark,
    required this.child,
    this.size = 38,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = isDark
        ? SizedBox(
            width: size.w,
            height: size.w,
            child: CustomPaint(
              painter: const _BackBtnPainter(),
              child: Center(child: child),
            ),
          )
        : Container(
            width: size.w,
            height: size.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backBtnLightBg,
            ),
            child: Center(child: child),
          );

    if (onTap == null) return visual;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: visual,
    );
  }
}

/// Reusable back button using [CustomIconButton] with a back arrow icon.
class CustomBackButton extends StatelessWidget {
  final bool isDark;
  final Color iconColor;
  final VoidCallback? onTap;

  const CustomBackButton({
    super.key,
    required this.isDark,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomIconButton(
      isDark: isDark,
      size: 38,
      onTap: onTap,
      child: Icon(Icons.arrow_back_ios_new, size: 14.sp, color: iconColor),
    );
  }
}

class _BackBtnPainter extends CustomPainter {
  const _BackBtnPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    // ── Gradient fill ──────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backBtnDarkFillTop,
            AppColors.backBtnDarkFillBottom,
          ],
        ).createShader(bounds),
    );

    // ── Arc border highlights ──────────────────────────────────────────────
    // 90° arcs with sweep-gradient shader: transparent → peak → transparent.
    final arcRect = Rect.fromCircle(center: center, radius: radius - 0.5);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const peak = Color(0x90FFFFFF);
    const fade = Color(0x00FFFFFF);

    // Top-left: 180° → 270° (9 o'clock → 12 o'clock)
    arcPaint.shader = ui.Gradient.sweep(
      center, [fade, peak, fade], [0.0, 0.5, 1.0],
      TileMode.clamp, pi, 3 * pi / 2,
    );
    canvas.drawArc(arcRect, pi, pi / 2, false, arcPaint);

    // Bottom-right: 0° → 90° (3 o'clock → 6 o'clock)
    arcPaint.shader = ui.Gradient.sweep(
      center, [fade, peak, fade], [0.0, 0.5, 1.0],
      TileMode.clamp, 0, pi / 2,
    );
    canvas.drawArc(arcRect, 0, pi / 2, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _BackBtnPainter old) => false;
}
