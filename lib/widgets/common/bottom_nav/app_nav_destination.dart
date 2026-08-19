import 'package:flutter/foundation.dart';

/// One tab slot in an [AppBottomNavBar].
///
/// Icons come from the app's PNG asset set. [activeIconAsset] falls back to
/// [iconAsset] when a tab has no dedicated selected artwork — both states are
/// tinted by the nav bar, so a single glyph still reads as selected.
class AppNavDestination {
  final String iconAsset;
  final String? activeIconAsset;

  /// Optional caption under the glyph. Left null for the icon-only design.
  final String? label;

  /// Announced by screen readers; falls back to [label].
  final String? semanticLabel;

  /// Rendered box for the glyph, in logical pixels before screen scaling.
  /// Defaults to [AppBottomNavBar.defaultIconSize].
  ///
  /// Artwork does not carry a consistent amount of transparent margin: the
  /// user set's glyphs fill ~90% of their canvas while the broker set's fill
  /// only ~66%, so drawing both into the same box makes the broker icons read
  /// as visibly smaller. Padded assets can size up here to match optically
  /// without anyone having to redraw them.
  final double? iconSize;

  const AppNavDestination({
    required this.iconAsset,
    this.activeIconAsset,
    this.label,
    this.semanticLabel,
    this.iconSize,
  });

  String assetFor({required bool isSelected}) =>
      isSelected ? (activeIconAsset ?? iconAsset) : iconAsset;
}

/// The circular action button pinned to the middle of an [AppBottomNavBar].
///
/// It is not a tab — tapping it never changes the current index, it just fires
/// [onTap] (e.g. "create announcement").
class AppNavCenterAction {
  final VoidCallback onTap;

  /// Optional custom artwork. Defaults to a drawn plus glyph.
  final String? iconAsset;
  final String? semanticLabel;

  const AppNavCenterAction({
    required this.onTap,
    this.iconAsset,
    this.semanticLabel,
  });
}
