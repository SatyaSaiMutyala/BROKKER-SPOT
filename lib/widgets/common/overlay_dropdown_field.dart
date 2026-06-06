import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A select field whose options list opens as a floating overlay anchored to
/// the field — instead of expanding inline and pushing everything below it
/// down. The panel auto-flips upward when there isn't enough room below.
///
/// Use this for any compact dropdown (property type, bedroom count, etc.) on
/// a long form where keeping the layout stable matters.
class OverlayDropdownField extends StatefulWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onSelect;

  /// Hard cap so very long lists don't dominate the screen. Internal scroll
  /// takes over past this.
  final double maxPanelHeight;

  const OverlayDropdownField({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onSelect,
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
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final spaceBelow =
        media.size.height - media.padding.bottom - position.dy - size.height;
    final itemsHeight = (widget.items.length * 44.0);
    final desiredHeight = itemsHeight.clamp(0.0, widget.maxPanelHeight);
    // Flip up only when below is genuinely cramped — and only if there IS
    // more room above. Otherwise stick to below (scrolls internally).
    final spaceAbove = position.dy - media.padding.top;
    _openUpward = spaceBelow < desiredHeight + 12 && spaceAbove > spaceBelow;

    _overlay = OverlayEntry(builder: (_) => _buildOverlay(size, desiredHeight));
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

  Widget _buildOverlay(Size fieldSize, double panelHeight) {
    return Stack(
      children: [
        // Tap-outside dismisser.
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
            color: Colors.white,
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
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : null,
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black87,
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
    final value = widget.value;
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          // Matches the Material TextField height used elsewhere on the form
          // (Property Name etc.) — InputDecorator adds intrinsic baseline
          // slack that a plain Container doesn't, so we add a few more dp
          // here to keep the row of fields visually aligned.
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? widget.hint,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: value != null
                        ? Colors.black87
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
