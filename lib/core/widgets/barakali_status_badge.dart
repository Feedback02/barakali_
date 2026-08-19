import 'package:flutter/material.dart';

/// A small status pill (colored label on a 12%-tint background). Shared by the
/// order / merchant-moderation / support-ticket status badges — each computes
/// its own label + color and delegates the chrome here.
class BarakaliStatusBadge extends StatelessWidget {
  const BarakaliStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _readableText(color, Theme.of(context).brightness),
        ),
      ),
    );
  }

  /// The pill background is a 12% tint of [color]. In light mode that tint is
  /// near-white, so the raw brand color as text can fail WCAG AA (amber
  /// `#D4A843` is ~1.9:1) — darken the hue until legible. In dark mode the same
  /// tint sits over a near-black surface, so darkening would be dark-on-dark;
  /// lighten instead. Either way the hue is preserved (green stays green, etc.).
  static Color _readableText(Color color, Brightness brightness) {
    final hsl = HSLColor.fromColor(color);
    final lightness = brightness == Brightness.dark
        ? (hsl.lightness + 0.32).clamp(0.45, 0.85)
        : (hsl.lightness - 0.28).clamp(0.0, 1.0);
    return hsl
        .withLightness(lightness)
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor();
  }
}
