import 'package:flutter/material.dart';

/// Sticks a fixed-height [child] to the top of a [CustomScrollView].
///
/// Use with `SliverPersistentHeader(pinned: true, ...)`. Several pinned
/// headers in one scroll view stack in order, so a later one parks directly
/// beneath an earlier one instead of scrolling past it.
///
/// [extent] must match the child's real height — a persistent header cannot
/// measure its child, so an undersized value overflows. Compose it from the
/// same tokens the child uses rather than hardcoding a number.
class PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  /// Opaque fill, so content scrolling underneath does not show through.
  final Color? backgroundColor;

  const PinnedHeaderDelegate({
    required this.extent,
    required this.child,
    this.backgroundColor,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: extent,
      color: backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent ||
      oldDelegate.child != child ||
      oldDelegate.backgroundColor != backgroundColor;
}
