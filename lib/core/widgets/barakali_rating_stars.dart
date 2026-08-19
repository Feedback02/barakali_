import 'package:flutter/material.dart';

/// A star rating display in the brand amber, with an optional rating count.
///
/// Two forms:
/// - default: a 5-star row (full / half / empty) — for detail screens.
/// - [compact]: a single star + the numeric rating (e.g. "★ 3.5 (41)") — for
///   tight rows like list cards, where 5 stars steal width from the title. When
///   compact and there are no ratings yet it renders nothing, so the title gets
///   the full width.
class BarakaliRatingStars extends StatelessWidget {
  const BarakaliRatingStars({
    super.key,
    required this.rating,
    this.totalRatings,
    this.size = 16,
    this.compact = false,
  });

  final double rating;
  final int? totalRatings;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    final hasRatings = totalRatings != null && totalRatings! > 0;

    if (compact) {
      if (!hasRatings) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: size, color: color),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($totalRatings)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: color,
          ),
        if (hasRatings) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
