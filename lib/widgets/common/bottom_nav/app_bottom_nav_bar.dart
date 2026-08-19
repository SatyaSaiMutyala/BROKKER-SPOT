import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_bottom_nav_bar_theme.dart';
import 'app_nav_destination.dart';

/// Flat, surface-coloured bottom navigation shared by the user and broker
/// dashboards.
///
/// Destinations render the app's PNG icons, tinted gold when selected. An
/// optional [centerAction] is dropped into the middle of the row as a circular
/// button — it is an action, not a tab, so it never becomes the selection.
class AppBottomNavBar extends StatelessWidget {
  static const Duration _transition = Duration(milliseconds: 220);

  /// Glyph box used when a destination doesn't override it, sized for the
  /// user set's artwork. See [AppNavDestination.iconSize].
  static const double defaultIconSize = 26;

  /// Padding kept under the row. The home-indicator inset is capped so the bar
  /// does not grow a band of empty space beneath the icons.
  static const double _maxBottomInset = 12;

  final List<AppNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppNavCenterAction? centerAction;

  const AppBottomNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.centerAction,
  }) : assert(destinations.length > 1, 'A nav bar needs at least 2 tabs');

  /// Slot the center action is inserted at — the exact middle for an even
  /// number of destinations, just past the middle otherwise.
  int get _centerSlot => (destinations.length / 2).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = AppBottomNavBarTheme.of(context);
    final bottomInset = math.min(
      MediaQuery.paddingOf(context).bottom,
      _maxBottomInset.h,
    );

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(top: BorderSide(color: theme.border)),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 62.h,
        child: Row(children: _buildSlots(theme)),
      ),
    );
  }

  List<Widget> _buildSlots(AppBottomNavBarTheme theme) {
    final slots = <Widget>[
      for (var i = 0; i < destinations.length; i++)
        Expanded(
          child: _DestinationSlot(
            destination: destinations[i],
            isSelected: i == currentIndex,
            theme: theme,
            transition: _transition,
            onTap: () => onDestinationSelected(i),
          ),
        ),
    ];

    if (centerAction != null) {
      slots.insert(
        _centerSlot,
        Expanded(child: _CenterActionSlot(action: centerAction!, theme: theme)),
      );
    }
    return slots;
  }
}

class _DestinationSlot extends StatelessWidget {
  final AppNavDestination destination;
  final bool isSelected;
  final AppBottomNavBarTheme theme;
  final Duration transition;
  final VoidCallback onTap;

  const _DestinationSlot({
    required this.destination,
    required this.isSelected,
    required this.theme,
    required this.transition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? theme.activeIcon : theme.inactiveIcon;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.semanticLabel ?? destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32.r,
        containedInkWell: false,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A short scale pop marks the selection without shifting layout.
            AnimatedScale(
              scale: isSelected ? 1.08 : 1,
              duration: transition,
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: transition,
                builder: (context, animatedColor, _) => Image.asset(
                  destination.assetFor(isSelected: isSelected),
                  width: (destination.iconSize ??
                          AppBottomNavBar.defaultIconSize)
                      .w,
                  height: (destination.iconSize ??
                          AppBottomNavBar.defaultIconSize)
                      .w,
                  color: animatedColor ?? color,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            if (destination.label != null) ...[
              SizedBox(height: 4.h),
              Text(
                destination.label!,
                style: TextStyle(
                  fontSize: 10.sp,
                  height: 1.2,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CenterActionSlot extends StatelessWidget {
  final AppNavCenterAction action;
  final AppBottomNavBarTheme theme;

  const _CenterActionSlot({required this.action, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.semanticLabel,
      child: Center(
        child: InkResponse(
          onTap: action.onTap,
          radius: 28.r,
          containedInkWell: false,
          highlightColor: Colors.transparent,
          child: Container(
            width: 48.w,
            height: 48.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.centerButtonBackground,
              shape: BoxShape.circle,
            ),
            child: action.iconAsset != null
                ? Image.asset(
                    action.iconAsset!,
                    width: 24.w,
                    height: 24.w,
                    color: theme.centerButtonIcon,
                    colorBlendMode: BlendMode.srcIn,
                  )
                : Icon(
                    Icons.add_rounded,
                    size: 28.sp,
                    color: theme.centerButtonIcon,
                  ),
          ),
        ),
      ),
    );
  }
}
