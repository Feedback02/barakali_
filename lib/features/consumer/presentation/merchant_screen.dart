import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/utils/maps_launcher.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_rating_stars.dart';
import '../domain/models/merchant_public.dart';
import '../domain/models/offer_with_merchant.dart';
import '../providers/favorites_providers.dart';
import '../providers/merchant_providers.dart';
import 'offer_labels.dart';
import 'widgets/offer_card.dart';

/// A followed (or otherwise reached) merchant's public profile plus the bags it
/// currently has available. Reached from the Favorites list and from a new-bag
/// notification.
class MerchantScreen extends ConsumerWidget {
  const MerchantScreen({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(merchantByIdProvider(merchantId));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: BarakaliEmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.browseErrorTitle,
        ),
      ),
      data: (merchant) => merchant == null
          ? Scaffold(
              appBar: AppBar(),
              body: BarakaliEmptyState(
                icon: Icons.storefront_outlined,
                title: l10n.merchantNotFound,
              ),
            )
          : _MerchantContent(merchant: merchant),
    );
  }
}

class _MerchantContent extends ConsumerWidget {
  const _MerchantContent({required this.merchant});

  final MerchantPublic merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offersAsync = ref.watch(merchantOffersProvider(merchant.id));

    final favorites = ref.watch(favoriteMerchantIdsProvider).value;
    final isFavorite = favorites?.contains(merchant.id) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          merchant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? theme.colorScheme.error : null,
            ),
            onPressed: () => _toggleFavorite(context, ref, isFavorite),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(merchantOffersProvider(merchant.id).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _MerchantHeader(merchant: merchant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.merchantOffersTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            offersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: BarakaliEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.browseErrorTitle,
                ),
              ),
              data: (offers) => offers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: BarakaliEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: l10n.merchantNoOffersTitle,
                        message: l10n.merchantNoOffersBody,
                      ),
                    )
                  : _OffersList(offers: offers),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool wasFavorite,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(favoriteMerchantIdsProvider.notifier)
        .toggle(merchant.id);
    if (!context.mounted || result == null) return;
    final msg = !result
        ? l10n.favoriteError
        : (wasFavorite ? l10n.favoriteRemoved : l10n.favoriteAdded);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _MerchantHeader extends StatelessWidget {
  const _MerchantHeader({required this.merchant});

  final MerchantPublic merchant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = merchant.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (merchant.coverImageUrl != null &&
            merchant.coverImageUrl!.isNotEmpty)
          BarakaliImage(
            url: merchant.coverImageUrl,
            width: double.infinity,
            height: 160,
            borderRadius: 0,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          style: theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          merchantCategoryLabel(l10n, merchant.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BarakaliRatingStars(
                rating: merchant.rating,
                totalRatings: merchant.totalRatings,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MerchantBadge(
                    icon: Icons.verified_rounded,
                    label: l10n.merchantVerifiedBadge,
                  ),
                  if (merchant.isHalal)
                    _MerchantBadge(
                      icon: DietaryOption.halal.icon,
                      label: l10n.merchantHalalBadge,
                      tooltip: l10n.merchantHalalBadgeHint,
                    ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      merchant.address,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => openDirections(
                    latitude: merchant.latitude,
                    longitude: merchant.longitude,
                    address: merchant.address,
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(l10n.offerGetDirections),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small icon+label trust pill (verified / halal) shown in the merchant
/// header. An optional [tooltip] carries the "merchant-declared" nuance for the
/// self-declared halal claim.
class _MerchantBadge extends StatelessWidget {
  const _MerchantBadge({required this.icon, required this.label, this.tooltip});

  final IconData icon;
  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final message = tooltip;
    return message == null ? badge : Tooltip(message: message, child: badge);
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({required this.offers});

  final List<OfferWithMerchant> offers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Nested in the outer scroll view; never scrolls on its own.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: offers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => OfferCard(item: offers[i]),
    );
  }
}
