import 'package:flutter/material.dart';

/// Decoration for a [TextField] that already sits inside its own bordered
/// container.
///
/// The app's [InputDecorationTheme] defines `enabledBorder`, `focusedBorder`
/// and a fill of its own. Setting only `border: InputBorder.none` on a field
/// does *not* switch those off — `border` is merely the fallback for states the
/// theme hasn't spoken for. So the theme keeps painting its own rounded outline
/// inside the wrapper: grey at rest, gold once focused, at its own 12px radius.
/// Against a wrapper with a different radius that reads as two misaligned
/// borders, plus a fill that doesn't match the wrapper's.
///
/// Layer the field's own hint and padding on top with `copyWith`.
const kBorderlessInput = InputDecoration(
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  filled: false,
);
