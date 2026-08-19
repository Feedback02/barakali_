import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Barakali wordmark, presented as a rounded badge. The logo art is a brand
/// asset with a baked-in cream (#FAF8F5) background, which blends invisibly into
/// the light theme's cream surface but reads as a stray white rectangle on a
/// dark surface. Wrapping it in a rounded, softly-shadowed badge makes it a
/// deliberate brand mark in both themes (and matches the cream-background app
/// launcher icon).
class BarakaliLogo extends StatelessWidget {
  const BarakaliLogo({super.key, this.width = 200, this.semanticsLabel});

  final double width;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    const radius = 28.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SvgPicture.asset(
          'assets/images/barakali_logo.svg',
          width: width,
          semanticsLabel: semanticsLabel,
        ),
      ),
    );
  }
}
