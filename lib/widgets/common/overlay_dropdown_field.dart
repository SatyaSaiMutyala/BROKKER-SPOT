import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A select field whose options list opens as a floating overlay anchored to
/// the field — instead of expanding inline and pushing everything below it
/// down. The panel auto-flips upward when there isn't enough room below.
class OverlayDropdownField extends StatefulWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onSelect;
  final IconData? prefixIcon;
  final double maxPanelHeight;

  const OverlayDropdownField({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onSelect,
    this.prefixIcon,
    this.maxPanelHeight = 220,
  });

  @override
  State<OverlayDropdownField> createState() => _OverlayDropdownFieldState();
}

class _OverlayDropdownFieldState extends State<OverlayDropdownField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;
  bool _openUpward = false;

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    FocusScope.of(context).unfocus();
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final spaceBelow =
        media.size.height - media.padding.bottom - position.dy - size.height;
    final itemsHeight = (widget.items.length * 44.0);
    final desiredHeight = itemsHeight.clamp(0.0, widget.maxPanelHeight);
    final spaceAbove = position.dy - media.padding.top;
    _openUpward = spaceBelow < desiredHeight + 12 && spaceAbove > spaceBelow;

    _overlay =
        OverlayEntry(builder: (_) => _buildOverlay(size, desiredHeight, isDark));
    overlay.insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  Widget _buildOverlay(Size fieldSize, double panelHeight, bool isDark) {
    final panelBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final normalText = isDark ? Colors.white70 : Colors.black87;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: _openUpward
              ? Offset(0, -panelHeight - 4)
              : Offset(0, fieldSize.height + 4),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(6.r),
            color: panelBg,
            child: SizedBox(
              width: fieldSize.width,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: panelHeight),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: widget.items.length,
                  itemBuilder: (_, i) {
                    final item = widget.items[i];
                    final isSelected = widget.value == item;
                    return InkWell(
                      onTap: () {
                        widget.onSelect(item);
                        _close();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 11.h),
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : null,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                isSelected ? AppColors.primary : normalText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = widget.value;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final chevronColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 10.w),
              ],
              Expanded(
                child: Text(
                  value ?? widget.hint,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: value != null ? textColor : hintColor,
                  ),
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: chevronColor,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
