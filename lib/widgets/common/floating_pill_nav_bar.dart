import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One icon slot in a [FloatingPillNavBar].
class PillNavItem {
  final String iconAsset;
  final String activeIconAsset;

  const PillNavItem({required this.iconAsset, required this.activeIconAsset});
}

/// Frosted-glass floating nav pill shared by the user and broker dashboards,
/// so both flows keep the exact same look. Pass [trailing] (e.g. a create
/// button) for flows that need an action outside the pill.
class FloatingPillNavBar extends StatelessWidget {
  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget? trailing;

  const FloatingPillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        trailing != null ? 37.w : 16.w,
        0,
        trailing != null ? 38.w : 16.w,
        bottomInset + 10.h,
      ),
      child: Row(
        children: [
          Expanded(child: _buildPill(context)),
          if (trailing != null) ...[
            SizedBox(width: 12.w),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0x99000000) : const Color(0x99DBDBDB);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 50.h,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              items.length,
              (i) => _navItem(context, i, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, bool isDark) {
    final item = items[index];
    final isActive = index == currentIndex;
    final iconSize = isActive ? 30.w : 25.w;
    final inactiveColor =
        isDark ? const Color(0xFFBBBBBB) : const Color(0xFF6E6E6E);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 50.h,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 59.w : 35.w,
            height: isActive ? 38.h : 35.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE0C78E) : Colors.transparent,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Image.asset(
              isActive ? item.activeIconAsset : item.iconAsset,
              width: iconSize,
              height: iconSize,
              color: isActive ? Colors.white : inactiveColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
