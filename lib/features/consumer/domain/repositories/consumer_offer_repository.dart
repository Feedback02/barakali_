import '../models/offer_with_merchant.dart';

abstract class ConsumerOfferRepository {
  /// Offers a consumer can currently claim: `status = 'active'` AND the pickup
  /// window has not ended (`pickup_end > now()`), joined to their approved,
  /// active merchant. Sorted by soonest pickup end. Capped at [limit].
  ///
  /// The `pickup_end > now()` filter is applied server-side — the client
  /// `Offer.effectiveStatus` getter only closes the UI gap for the merchant's
  /// own dashboard; the auto-expiry cron lags up to 5 min, so the browse query
  /// must exclude past-window offers itself.
  Future<List<OfferWithMerchant>> fetchBrowseOffers({int limit = 100});

  /// A single claimable offer by [offerId] (active + approved/active merchant),
  /// or null if it's no longer available to a consumer. Used when deep-linking
  /// straight to the detail screen (no list row to carry in).
  Future<OfferWithMerchant?> fetchOfferById(String offerId);

  /// The currently-claimable offers for one merchant (same active + open-window
  /// gate as [fetchBrowseOffers]), soonest pickup first. Used by the merchant
  /// screen reached from Favorites. Empty when the merchant has none right now.
  Future<List<OfferWithMerchant>> fetchMerchantOffers(String merchantId);
}
