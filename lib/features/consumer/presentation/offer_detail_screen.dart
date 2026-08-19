import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/utils/distance.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/utils/maps_launcher.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_chip.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_price_tag.dart';
import 'package:barakali/core/widgets/barakali_rating_stars.dart';
import 'package:barakali/core/widgets/barakali_review_tile.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import 'package:barakali/features/orders/domain/order_errors.dart';
import 'package:barakali/features/orders/presentation/order_labels.dart';
import 'package:barakali/features/orders/providers/order_providers.dart';
import '../domain/models/merchant_review.dart';
import '../domain/models/offer_with_merchant.dart';
import '../providers/browse_providers.dart';
import '../providers/favorites_providers.dart';
import '../providers/location_providers.dart';
import '../providers/reviews_providers.dart';
import 'offer_labels.dart';

/// Full detail for one offer. Carries [initial] in when pushed from the list;
/// falls back to fetching by [offerId] when deep-linked.
class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offerId, this.initial});

  final String offerId;
  final OfferWithMerchant? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (initial != null) return _DetailContent(item: initial!);

    final async = ref.watch(offerByIdProvider(offerId));
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
      data: (item) => item == null
          ? Scaffold(
              appBar: AppBar(),
              body: BarakaliEmptyState(
                icon: Icons.remove_shopping_cart_outlined,
                title: l10n.offerUnavailable,
              ),
            )
          : _DetailContent(item: item),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.item});

  final OfferWithMerchant item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offer = item.offer;
    final merchant = item.merchant;

    final favorites = ref.watch(favoriteMerchantIdsProvider).value;
    final isFavorite = favorites?.contains(offer.merchantId) ?? false;

    final coords = ref.watch(userLocationProvider).value;
    final distanceKm =
        (coords != null &&
            merchant.latitude != null &&
            merchant.longitude != null)
        ? haversineKm(
            coords.lat,
            coords.lng,
            merchant.latitude!,
            merchant.longitude!,
          )
        : null;

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
      body: ListView(
        children: [
          Hero(
            tag: 'offer-image-${offer.id}',
            child: BarakaliImage(
              url: offer.imageUrl,
              width: double.infinity,
              height: 220,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        merchant.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BarakaliRatingStars(
                      rating: merchant.rating,
                      totalRatings: merchant.totalRatings,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Every offer that reaches the consumer comes through the
                // `merchants_public` view, which bakes in `is_approved` — so a
                // browseable/deep-linked merchant is always approved; the badge
                // is an unconditional trust cue, not a conditional state.
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _VerifiedBadge(),
                    if (merchant.isHalal) const _HalalBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    BarakaliChip(
                      label: offerCategoryLabel(l10n, offer.category),
                      icon: Icons.local_offer_outlined,
                    ),
                    BarakaliChip(
                      label: l10n.offerQuantityLeft(offer.quantityRemaining),
                      icon: Icons.shopping_bag_outlined,
                    ),
                    for (final tag in DietaryOption.offerTags)
                      if (offer.dietaryOptions.contains(tag))
                        BarakaliChip(label: tag.label(l10n), icon: tag.icon),
                    if (distanceKm != null)
                      BarakaliChip(
                        label: l10n.distanceKm(distanceKm.toStringAsFixed(1)),
                        icon: Icons.near_me_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(offer.title, style: theme.textTheme.titleMedium),
                if (offer.description != null &&
                    offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    offer.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const _SurpriseBoxExplainer(),
                const SizedBox(height: 16),
                BarakaliPriceTag(
                  originalPrice: offer.originalPrice,
                  discountedPrice: offer.discountedPrice,
                  showSavings: true,
                ),
                const SizedBox(height: 12),
                _FreeCancellationNote(),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: l10n.offerPickupWindowLabel,
                  value: formatPickupWindow(
                    context,
                    offer.pickupStart,
                    offer.pickupEnd,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: l10n.merchantAddressLabel,
                  value: merchant.address,
                ),
                const SizedBox(height: 8),
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
                _ReviewsSection(merchantId: offer.merchantId),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _ReserveBar(item: item),
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
        .toggle(item.offer.merchantId);
    if (!context.mounted || result == null) return;
    final msg = !result
        ? l10n.favoriteError
        : (wasFavorite ? l10n.favoriteRemoved : l10n.favoriteAdded);
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// "Verified by Barakali" trust pill, shown for every merchant a consumer can
/// reach (all are admin-approved — see the call site).
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_rounded,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          l10n.merchantVerifiedBadge,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Merchant self-declared halal pill. The label carries a "merchant-declared"
/// tooltip so the claim never reads as an official certification (that is a
/// future admin-verified upgrade).
class _HalalBadge extends StatelessWidget {
  const _HalalBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Tooltip(
      message: l10n.merchantHalalBadgeHint,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            DietaryOption.halal.icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.merchantHalalBadge,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains the variable-contents nature of a surprise bag — the core piece of
/// the prepayment trust block.
class _SurpriseBoxExplainer extends StatelessWidget {
  const _SurpriseBoxExplainer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offerSurpriseBoxTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.offerSurpriseBoxBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line reassurance that cancellation is free, shown above the Reserve CTA.
class _FreeCancellationNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.offerFreeCancellation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

/// Recent written reviews for the merchant. Renders nothing until reviews load
/// and only when at least one exists — a failure or empty result silently hides
/// the section rather than showing an empty box that erodes trust.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reviews =
        ref.watch(merchantReviewsProvider(merchantId)).value ??
        const <MerchantReview>[];
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(l10n.offerReviewsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < reviews.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          BarakaliReviewTile(
            score: reviews[i].score,
            comment: reviews[i].comment,
            date: reviews[i].createdAt,
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Reserve CTA. Creates a reservation via [reserveControllerProvider] then
/// navigates to the new order; disabled with a "sold out" label when the offer
/// is no longer claimable.
class _ReserveBar extends ConsumerWidget {
  const _ReserveBar({required this.item});

  final OfferWithMerchant item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offer = item.offer;

    // Already have an active (reserved/paid) order for this offer? Send the user
    // to it instead of letting them stack a duplicate reservation.
    final existingOrderId = ref.watch(activeOrderIdForOfferProvider(offer.id));
    if (existingOrderId != null) {
      return BarakaliButton(
        label: l10n.orderViewExisting,
        onPressed: () => context.push('/order/$existingOrderId'),
      );
    }

    final claimable =
        offer.quantityRemaining > 0 &&
        offer.effectiveStatus == OfferStatus.active;
    if (!claimable) {
      return BarakaliButton(label: l10n.reserveSoldOut, onPressed: null);
    }

    final reserving = ref.watch(reserveControllerProvider).isLoading;
    return BarakaliButton(
      label: l10n.offerReserve,
      isLoading: reserving,
      onPressed: () => _reserve(context, ref, l10n),
    );
  }

  Future<void> _reserve(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reservation = await ref
        .read(reserveControllerProvider.notifier)
        .reserve(item.offer.id);
    if (!context.mounted) return;
    if (reservation != null) {
      context.push('/order/${reservation.orderId}');
    } else {
      final err = ref.read(reserveControllerProvider).error;
      final code = err is OrderException ? err.code : OrderErrorCode.unknown;
      messenger.showSnackBar(
        SnackBar(content: Text(orderErrorMessage(l10n, code))),
      );
    }
  }
}
