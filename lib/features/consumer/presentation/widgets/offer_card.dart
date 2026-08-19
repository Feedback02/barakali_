import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/theme/brand_colors.dart';
import 'package:barakali/core/utils/contrast.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_chip.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/core/widgets/barakali_price_tag.dart';
import 'package:barakali/core/widgets/barakali_rating_stars.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import '../../domain/models/offer_with_merchant.dart';
import '../offer_labels.dart';

/// An offer is flagged "ending soon" when its pickup window closes within the
/// next two hours (and hasn't already closed). A static cue, not a live
/// countdown (the ticking countdown lives in [BarakaliCountdown]).
const _endingSoonWindow = Duration(hours: 2);

bool _isEndingSoon(DateTime pickupEnd) {
  final remaining = pickupEnd.toLocal().difference(DateTime.now());
  return remaining > Duration.zero && remaining <= _endingSoonWindow;
}

/// A browse/offer-list banner card: a fixed-height photo with overlaid
/// savings / quantity / urgency / sold-out badges, then merchant + offer
/// details. Tapping opens the offer detail screen. Shared by the home browse
/// list and the merchant screen; pass [distanceKm] to show a distance chip
/// (the merchant screen omits it).
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.item, this.distanceKm});

  final OfferWithMerchant item;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offer = item.offer;
    final soldOut = offer.effectiveStatus == OfferStatus.soldOut;
    final savings = offer.originalPrice > 0
        ? (((offer.originalPrice - offer.discountedPrice) /
                      offer.originalPrice) *
                  100)
              .round()
        : 0;
    final endingSoon = !soldOut && _isEndingSoon(offer.pickupEnd);

    return _EntranceFade(
      child: BarakaliCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/offer/${offer.id}', extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image with overlaid badges. Fixed height (no IntrinsicHeight)
            // so the double.infinity width resolves to the card width without an
            // unbounded-height layout. The card itself clips the top corners.
            Stack(
              children: [
                Hero(
                  tag: 'offer-image-${offer.id}',
                  child: BarakaliImage(
                    url: offer.imageUrl,
                    width: double.infinity,
                    height: 150,
                    borderRadius: 0,
                  ),
                ),
                if (savings > 0 && !soldOut)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _OverlayPill(
                      label: l10n.offerSavingsBadge(savings),
                      background: kBrandGreen,
                      bold: true,
                    ),
                  ),
                if (!soldOut)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _OverlayPill(
                      label: l10n.offerLeftShort(offer.quantityRemaining),
                      background: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                if (endingSoon)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _OverlayPill(
                      label: l10n.offerEndingSoon,
                      background: darkenForWhiteText(kBrandTerracotta),
                      icon: Icons.schedule_rounded,
                      bold: true,
                    ),
                  ),
                if (soldOut)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: Center(
                        child: _OverlayPill(
                          label: l10n.offerStatusSoldOut,
                          background: Colors.black.withValues(alpha: 0.7),
                          bold: true,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              // Sold-out rows still render (the offer is briefly visible until the
              // expiry cron flips it) but read as inactive.
              child: Opacity(
                opacity: soldOut ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.merchant.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BarakaliRatingStars(
                          rating: item.merchant.rating,
                          totalRatings: item.merchant.totalRatings,
                          size: 15,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    BarakaliPriceTag(
                      originalPrice: offer.originalPrice,
                      discountedPrice: offer.discountedPrice,
                    ),
                    const SizedBox(height: 8),
                    // Wrap (not Row): the category chip + distance can exceed the
                    // card width when the distance string is long (far user) or in
                    // a longer locale; Wrap reflows to a second line instead.
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        BarakaliChip(
                          label: offerCategoryLabel(l10n, offer.category),
                          icon: Icons.local_offer_outlined,
                        ),
                        if (item.merchant.isHalal)
                          BarakaliChip(
                            label: DietaryOption.halal.label(l10n),
                            icon: DietaryOption.halal.icon,
                          ),
                        for (final tag in DietaryOption.offerTags)
                          if (offer.dietaryOptions.contains(tag))
                            BarakaliChip(
                              label: tag.label(l10n),
                              icon: tag.icon,
                            ),
                        if (distanceKm != null)
                          BarakaliChip(
                            label: l10n.distanceKm(
                              distanceKm!.toStringAsFixed(1),
                            ),
                            icon: Icons.near_me_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            formatPickupWindow(
                              context,
                              offer.pickupStart,
                              offer.pickupEnd,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts a card into place on first build. Because the tween is
/// constant it animates once on mount (and re-animates as a card scrolls into
/// view in a lazy list) rather than on every rebuild.
class _EntranceFade extends StatelessWidget {
  const _EntranceFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
    );
  }
}

/// A compact white-on-color pill overlaid on the card image (savings, quantity,
/// urgency, sold-out). White text clears WCAG AA on the brand green and the dark
/// scrim; the terracotta urgency pill is darkened first (see
/// [_darkenForWhiteText]) because the raw hue falls just short.
class _OverlayPill extends StatelessWidget {
  const _OverlayPill({
    required this.label,
    required this.background,
    this.icon,
    this.bold = false,
  });

  final String label;
  final Color background;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
