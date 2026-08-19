import 'package:flutter/material.dart';

/// Darkens a brand color so white text/icon on it clears WCAG AA. The raw
/// terracotta `#C45B3A` is only ~4.28:1 against white (below the 4.5:1
/// normal-text bar); dropping its HSL lightness lifts white-on-fill pills over
/// the line while staying on-brand. Used for image-overlay pills and map
/// markers (both carry white text on a brand fill).
Color darkenForWhiteText(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
}
