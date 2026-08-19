import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_rating_stars.dart';
import '../domain/models/merchant_public.dart';
import '../providers/merchant_providers.dart';
import 'offer_labels.dart';

/// The merchants the consumer follows. Tapping one opens its profile + current
/// bags.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(favoriteMerchantsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: AsyncRefreshList<MerchantPublic>(
        async: async,
        onRefresh: () => ref.refresh(favoriteMerchantsProvider.future),
        emptyIcon: Icons.favorite_border_rounded,
        emptyTitle: l10n.favoritesEmptyTitle,
        emptyMessage: l10n.favoritesEmptyBody,
        errorTitle: l10n.favoritesErrorTitle,
        builder: (_, merchants) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: merchants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _FavoriteMerchantCard(merchant: merchants[i]),
        ),
      ),
    );
  }
}

class _FavoriteMerchantCard extends StatelessWidget {
  const _FavoriteMerchantCard({required this.merchant});

  final MerchantPublic merchant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BarakaliCard(
      onTap: () => context.push('/shop/${merchant.id}'),
      child: Row(
        children: [
          BarakaliImage(
            url: merchant.logoUrl,
            width: 56,
            height: 56,
            borderRadius: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  merchantCategoryLabel(l10n, merchant.category),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                BarakaliRatingStars(
                  rating: merchant.rating,
                  totalRatings: merchant.totalRatings,
                  size: 15,
                  compact: true,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
