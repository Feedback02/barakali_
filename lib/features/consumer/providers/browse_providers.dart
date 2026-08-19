import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/core/utils/distance.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import '../data/consumer_offer_repository_impl.dart';
import '../domain/models/offer_with_merchant.dart';
import '../domain/repositories/consumer_offer_repository.dart';
import 'location_providers.dart';

final consumerOfferRepositoryProvider = Provider<ConsumerOfferRepository>((
  ref,
) {
  return ConsumerOfferRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Currently-claimable offers for the consumer browse list (active + pickup
/// window still open), soonest pickup first. Pull-to-refresh / re-navigation
/// re-runs the query via [ref.invalidate].
final browseOffersProvider =
    AsyncNotifierProvider<BrowseOffersNotifier, List<OfferWithMerchant>>(
      BrowseOffersNotifier.new,
    );

class BrowseOffersNotifier extends AsyncNotifier<List<OfferWithMerchant>> {
  @override
  Future<List<OfferWithMerchant>> build() async {
    final offers = await ref
        .read(consumerOfferRepositoryProvider)
        .fetchBrowseOffers();
    log.i('Browse offers loaded (count=${offers.length})');
    return offers;
  }
}

/// A single offer for the detail screen, fetched by id. Used as a fallback when
/// the screen is deep-linked without a list row to carry in. Null => the offer
/// is no longer claimable (expired/withdrawn/merchant unapproved).
final offerByIdProvider = FutureProvider.family<OfferWithMerchant?, String>((
  ref,
  offerId,
) {
  return ref.read(consumerOfferRepositoryProvider).fetchOfferById(offerId);
});

/// A browse row decorated with the distance (km) from the user, or null when
/// the user's location or the merchant's coordinates are unknown.
typedef BrowseItem = ({OfferWithMerchant offer, double? distanceKm});

/// How the browse list is ordered. `nearest` needs the user's location; when it
/// is unknown it falls back to the soonest-pickup order (so picking it never
/// blocks or empties the list).
enum BrowseSort { nearest, endingSoon, priceLow }

/// Selected browse sort. Defaults to [BrowseSort.nearest] (which degrades to
/// soonest-pickup until a location is granted).
final browseSortProvider = NotifierProvider<BrowseSortNotifier, BrowseSort>(
  BrowseSortNotifier.new,
);

class BrowseSortNotifier extends Notifier<BrowseSort> {
  @override
  BrowseSort build() => BrowseSort.nearest;

  void set(BrowseSort sort) => state = sort;
}

/// [browseOffersProvider] decorated with distance and ordered per the selected
/// [browseSortProvider] (nearest-first only once the user's location is known;
/// otherwise soonest-pickup). Loading/error propagate from
/// [browseOffersProvider]; an unresolved location never blocks the list.
final browseListProvider = Provider<AsyncValue<List<BrowseItem>>>((ref) {
  final offersAsync = ref.watch(browseOffersProvider);
  final coords = ref.watch(userLocationProvider).value;
  final sort = ref.watch(browseSortProvider);

  return offersAsync.whenData((offers) {
    final items = [
      for (final o in offers)
        (
          offer: o,
          distanceKm:
              (coords != null &&
                  o.merchant.latitude != null &&
                  o.merchant.longitude != null)
              ? haversineKm(
                  coords.lat,
                  coords.lng,
                  o.merchant.latitude!,
                  o.merchant.longitude!,
                )
              : null,
        ),
    ];

    int byPickupEnd(BrowseItem a, BrowseItem b) =>
        a.offer.offer.pickupEnd.compareTo(b.offer.offer.pickupEnd);

    switch (sort) {
      case BrowseSort.nearest:
        // Nearest first; null distances (merchant without coords, or no user
        // location) sink to the end and tie-break by soonest pickup, so the
        // order stays deterministic and matches the default when location is
        // unknown.
        if (coords != null) {
          items.sort((a, b) {
            final da = a.distanceKm;
            final db = b.distanceKm;
            if (da != null && db != null && da != db) return da.compareTo(db);
            if (da == null && db != null) return 1;
            if (da != null && db == null) return -1;
            return byPickupEnd(a, b);
          });
        } else {
          items.sort(byPickupEnd);
        }
      case BrowseSort.endingSoon:
        items.sort(byPickupEnd);
      case BrowseSort.priceLow:
        items.sort((a, b) {
          final c = a.offer.offer.discountedPrice.compareTo(
            b.offer.offer.discountedPrice,
          );
          return c != 0 ? c : byPickupEnd(a, b);
        });
    }
    return items;
  });
});

/// Consumer browse filter state. All filtering is client-side over the already
/// loaded [browseListProvider] (instant, no extra queries, no user-input ever
/// reaches a query — so no injection surface). Server-side search/filtering is
/// a future enhancement for when the catalog outgrows the [browseOffersProvider]
/// fetch cap.
class BrowseFilter {
  const BrowseFilter({
    this.query = '',
    this.categories = const {},
    this.dietaryPrefs = const {},
    this.maxKm,
  });

  /// Free-text matched against offer title + merchant name (case-insensitive).
  final String query;

  /// Selected offer categories (multi-select). Empty = all categories.
  final Set<OfferCategory> categories;

  /// Required dietary attributes (halal + offer tags). Empty = no dietary
  /// filter. An offer must satisfy every one (see [offerSatisfiesDietary]).
  final Set<DietaryOption> dietaryPrefs;

  /// Maximum distance in km, or null for "any". Only meaningful when the user's
  /// location is known (offers with unknown distance are excluded when set).
  final double? maxKm;

  bool get isActive =>
      query.isNotEmpty ||
      categories.isNotEmpty ||
      dietaryPrefs.isNotEmpty ||
      maxKm != null;

  BrowseFilter copyWith({
    String? query,
    Set<OfferCategory>? categories,
    Set<DietaryOption>? dietaryPrefs,
    double? maxKm,
    bool clearMaxKm = false,
  }) => BrowseFilter(
    query: query ?? this.query,
    categories: categories ?? this.categories,
    dietaryPrefs: dietaryPrefs ?? this.dietaryPrefs,
    maxKm: clearMaxKm ? null : (maxKm ?? this.maxKm),
  );
}

final browseFilterProvider =
    NotifierProvider<BrowseFilterNotifier, BrowseFilter>(
      BrowseFilterNotifier.new,
    );

class BrowseFilterNotifier extends Notifier<BrowseFilter> {
  bool _dietarySeeded = false;

  @override
  BrowseFilter build() {
    // A new signed-in user must re-seed from their OWN standing preference and
    // must not inherit the previous user's filter (logout->login without an app
    // restart). Reset the seed + filter on any auth transition; the Home/Map
    // seeding then re-applies the new user's dietary_prefs.
    ref.listen(authStateProvider, (_, _) {
      _dietarySeeded = false;
      state = const BrowseFilter();
    });
    return const BrowseFilter();
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  /// Adds/removes [category] from the multi-select set.
  void toggleCategory(OfferCategory category) {
    final next = {...state.categories};
    if (!next.add(category)) next.remove(category);
    state = state.copyWith(categories: next);
  }

  /// Clears the category selection (= "all").
  void clearCategories() => state = state.copyWith(categories: const {});

  /// Adds/removes [option] from the dietary requirement set. A manual edit locks
  /// out any later profile-based seeding.
  void toggleDietary(DietaryOption option) {
    _dietarySeeded = true;
    final next = {...state.dietaryPrefs};
    if (!next.add(option)) next.remove(option);
    state = state.copyWith(dietaryPrefs: next);
  }

  /// Seeds the dietary chips from the consumer's standing preference exactly
  /// once (on first profile load), and never overrides a manual edit.
  void seedDietary(Set<DietaryOption> prefs) {
    if (_dietarySeeded) return;
    _dietarySeeded = true;
    if (prefs.isEmpty) return;
    state = state.copyWith(dietaryPrefs: prefs);
  }

  /// Overwrites the dietary chips (used when the consumer saves a new standing
  /// preference so the live browse/map filter stays in sync).
  void setDietary(Set<DietaryOption> prefs) {
    _dietarySeeded = true;
    state = state.copyWith(dietaryPrefs: {...prefs});
  }

  void setMaxKm(double? maxKm) =>
      state = state.copyWith(maxKm: maxKm, clearMaxKm: maxKm == null);

  void clear() {
    _dietarySeeded = true;
    state = const BrowseFilter();
  }
}

/// [browseListProvider] with the active [BrowseFilter] applied (preserving the
/// nearest-first order). Loading/error propagate from the underlying list.
final filteredBrowseProvider = Provider<AsyncValue<List<BrowseItem>>>((ref) {
  final listAsync = ref.watch(browseListProvider);
  final filter = ref.watch(browseFilterProvider);

  return listAsync.whenData((items) {
    if (!filter.isActive) return items;
    final query = filter.query.trim().toLowerCase();
    return [
      for (final item in items)
        if (_matchesFilter(item, filter, query)) item,
    ];
  });
});

bool _matchesFilter(BrowseItem item, BrowseFilter filter, String query) {
  final offer = item.offer.offer;
  if (filter.categories.isNotEmpty &&
      !filter.categories.contains(offer.category)) {
    return false;
  }
  if (filter.dietaryPrefs.isNotEmpty &&
      !offerSatisfiesDietary(
        prefs: filter.dietaryPrefs,
        offerTags: offer.dietaryOptions,
        merchantIsHalal: item.offer.merchant.isHalal,
      )) {
    return false;
  }
  if (filter.maxKm != null) {
    final d = item.distanceKm;
    if (d == null || d > filter.maxKm!) return false;
  }
  if (query.isNotEmpty) {
    final inTitle = offer.title.toLowerCase().contains(query);
    final inMerchant = item.offer.merchant.name.toLowerCase().contains(query);
    if (!inTitle && !inMerchant) return false;
  }
  return true;
}
