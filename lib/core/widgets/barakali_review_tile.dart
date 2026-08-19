import 'package:flutter/material.dart';

import 'barakali_rating_stars.dart';

/// One anonymous review in the offer-detail trust block: the score as small
/// stars, a muted short date, and the comment. The reviewer is intentionally
/// unnamed (the backing RPC returns no identity).
class BarakaliReviewTile extends StatelessWidget {
  const BarakaliReviewTile({
    super.key,
    required this.score,
    required this.comment,
    required this.date,
  });

  final int score;
  final String comment;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortDate = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(date.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BarakaliRatingStars(rating: score.toDouble(), size: 15),
            const Spacer(),
            Text(
              shortDate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          comment,
          style: theme.textTheme.bodyMedium,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
