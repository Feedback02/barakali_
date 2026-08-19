import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/format.dart';

/// Discounted price (brand green) with the original price struck through, and
/// an optional "-NN%" savings badge. Prices are integer UZS.
class BarakaliPriceTag extends StatelessWidget {
  const BarakaliPriceTag({
    super.key,
    required this.originalPrice,
    required this.discountedPrice,
    this.showSavings = false,
  });

  final int originalPrice;
  final int discountedPrice;
  final bool showSavings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final savings = originalPrice > 0
        ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
        : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.priceUzs(groupThousands(discountedPrice)),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          groupThousands(originalPrice),
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        if (showSavings && savings > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.offerSavingsBadge(savings),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
