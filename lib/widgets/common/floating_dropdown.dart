import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A dropdown that opens as a floating overlay anchored to itself — it does
/// not push sibling widgets down.
///
/// Use a [GlobalKey<FloatingDropdownState>] to call [FloatingDropdownState.close]
/// from outside (e.g., to close one dropdown when another opens).
///
/// Example:
/// ```dart
/// final _key = GlobalKey<FloatingDropdownState>();
///
/// FloatingDropdown(
///   key: _key,
///   hint: 'Select',
///   value: _selected,
///   items: const ['Monthly', 'Yearly'],
///   isDark: isDark,
///   onSelect: (v) => setState(() => _selected = v),
///   onBeforeOpen: () => _otherKey.currentState?.close(),
/// )
/// ```
class FloatingDropdown extends StatefulWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final bool isLoading;
  final bool enabled;
  final IconData? prefixIcon;
  final VoidCallback? onBeforeOpen;

  /// Draws the border red to flag a required selection the user hasn't made.
  final bool hasError;

  const FloatingDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.isDark,
    required this.onSelect,
    this.isLoading = false,
    this.enabled = true,
    this.prefixIcon,
    this.onBeforeOpen,
    this.hasError = false,
  });

  @override
  State<FloatingDropdown> createState() => FloatingDropdownState();
}

class FloatingDropdownState extends State<FloatingDropdown> {
  bool _isOpen = false;
  OverlayEntry? _overlay;
  Offset _triggerOffset = Offset.zero;
  Size _triggerSize = Size.zero;

  @override
  void didUpdateWidget(FloatingDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _overlay?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void close() {
    if (!_isOpen) return;
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _open() {
    widget.onBeforeOpen?.call();

    final box = context.findRenderObject() as RenderBox;
    _triggerOffset = box.localToGlobal(Offset.zero);
    _triggerSize = box.size;

    final isDark = widget.isDark;
    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // Full-screen dismiss layer — translucent so the tap still reaches
          // whatever was actually tapped (date picker, another field, etc.).
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => close(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
        left: _triggerOffset.dx,
        top: _triggerOffset.dy + _triggerSize.height,
        width: _triggerSize.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.map((item) {
                  final sel = widget.value == item;
                  return InkWell(
                    onTap: () {
                      close();
                      widget.onSelect(item);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 13.h),
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white70
                                  : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_isOpen) {
      close();
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Error wins over the enabled/disabled pair — a required field the user must
    // still fill matters more than showing it as inert.
    final borderColor = widget.hasError
        ? Colors.red.shade400
        : widget.enabled
            ? (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300)
            : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.enabled
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    final hintColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: _isOpen
              ? BorderRadius.vertical(top: Radius.circular(6.r))
              : BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon,
                  size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                widget.value ?? widget.hint,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: widget.value != null ? textColor : hintColor,
                ),
              ),
            ),
            if (widget.isLoading)
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
