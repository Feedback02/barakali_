import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/features/consumer/domain/models/offer_with_merchant.dart';
import 'package:barakali/features/consumer/domain/repositories/consumer_offer_repository.dart';
import 'package:barakali/features/consumer/providers/browse_providers.dart';
import 'package:barakali/features/consumer/providers/location_providers.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConsumerOfferRepository implements ConsumerOfferRepository {
  _FakeConsumerOfferRepository(this.offers);
  final List<OfferWithMerchant> offers;

  @override
  Future<List<OfferWithMerchant>> fetchBrowseOffers({int limit = 100}) async =>
      offers;

  @override
  Future<OfferWithMerchant?> fetchOfferById(String offerId) async => null;

  @override
  Future<List<OfferWithMerchant>> fetchMerchantOffers(
    String merchantId,
  ) async => offers.where((o) => o.offer.merchantId == merchantId).toList();
}

OfferWithMerchant _make({
  required String id,
  required String title,
  required OfferCategory category,
  required String merchantName,
  double? lat,
  double? lng,
  List<String> dietaryTags = const [],
  bool isHalal = false,
}) {
  final now = DateTime.parse('2026-06-10T10:00:00Z');
  return OfferWithMerchant(
    offer: Offer(
      id: id,
      merchantId: 'm-$id',
      title: title,
      category: category,
      originalPrice: 80000,
      discountedPrice: 40000,
      quantityTotal: 5,
      quantityRemaining: 3,
      pickupStart: now,
      pickupEnd: now.add(const Duration(hours: 4)),
      status: OfferStatus.active,
      dietaryTags: dietaryTags,
      createdAt: now,
      updatedAt: now,
    ),
    merchant: MerchantSummary(
      name: merchantName,
      rating: 4.5,
      totalRatings: 10,
      category: 'bakery',
      address: 'addr',
      isHalal: isHalal,
      latitude: lat,
      longitude: lng,
    ),
  );
}

void main() {
  final offers = [
    _make(
      id: 'o1',
      title: 'Bread bag',
      category: OfferCategory.bakery,
      merchantName: 'Paul Bakery',
      lat: 41.31,
      lng: 69.28,
    ),
    _make(
      id: 'o2',
      title: 'Plov box',
      category: OfferCategory.meal,
      merchantName: 'Osh Markazi',
      lat: 41.35,
      lng: 69.34,
    ),
    _make(
      id: 'o3',
      title: 'Grocery rescue',
      category: OfferCategory.grocery,
      merchantName: 'Korzinka',
    ),
  ];

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer(
      overrides: [
        consumerOfferRepositoryProvider.overrideWithValue(
          _FakeConsumerOfferRepository(offers),
        ),
        userLocationProvider.overrideWith(
          (ref) async => (lat: 41.31, lng: 69.28),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(browseOffersProvider.future);
    await container.read(userLocationProvider.future);
    return container;
  }

  List<String> ids(ProviderContainer c) => c
      .read(filteredBrowseProvider)
      .value!
      .map((e) => e.offer.offer.id)
      .toList();

  group('filteredBrowseProvider', () {
    test('no filter returns all offers, nearest-first', () async {
      final c = await boot();
      // o1 (~0km), o2 (~6.5km), o3 (no coords) sinks last.
      expect(ids(c), ['o1', 'o2', 'o3']);
    });

    test('category filter keeps only the selected category', () async {
      final c = await boot();
      c.read(browseFilterProvider.notifier).toggleCategory(OfferCategory.meal);
      expect(ids(c), ['o2']);
    });

    test('category filter is multi-select (OR across categories)', () async {
      final c = await boot();
      c.read(browseFilterProvider.notifier)
        ..toggleCategory(OfferCategory.meal)
        ..toggleCategory(OfferCategory.bakery);
      expect(ids(c), ['o1', 'o2']);
    });

    test('toggling a category off removes it from the filter', () async {
      final c = await boot();
      final notifier = c.read(browseFilterProvider.notifier)
        ..toggleCategory(OfferCategory.meal);
      expect(ids(c), ['o2']);
      notifier.toggleCategory(OfferCategory.meal);
      expect(ids(c), ['o1', 'o2', 'o3']);
    });

    test('search matches merchant name or offer title', () async {
      final c = await boot();
      c.read(browseFilterProvider.notifier).setQuery('osh');
      expect(ids(c), ['o2']);

      c.read(browseFilterProvider.notifier).setQuery('bread');
      expect(ids(c), ['o1']);
    });

    test(
      'distance radius excludes farther and unknown-distance offers',
      () async {
        final c = await boot();
        c.read(browseFilterProvider.notifier).setMaxKm(3);
        expect(ids(c), ['o1']); // o2 ~6.5km out; o3 has no coords
      },
    );

    test('clear resets all filters', () async {
      final c = await boot();
      final notifier = c.read(browseFilterProvider.notifier)
        ..toggleCategory(OfferCategory.bakery)
        ..setQuery('paul');
      expect(ids(c), ['o1']);
      notifier.clear();
      expect(ids(c), ['o1', 'o2', 'o3']);
    });
  });

  group('filteredBrowseProvider dietary filter', () {
    final dietaryOffers = [
      _make(
        id: 'da',
        title: 'Vegan bowl',
        category: OfferCategory.meal,
        merchantName: 'Green Kitchen',
        dietaryTags: const ['vegan'],
        isHalal: true,
      ),
      _make(
        id: 'db',
        title: 'Veggie box',
        category: OfferCategory.meal,
        merchantName: 'Osh Markazi',
        dietaryTags: const ['vegetarian'],
      ),
      _make(
        id: 'dc',
        title: 'Mixed rescue',
        category: OfferCategory.mixed,
        merchantName: 'Korzinka',
        isHalal: true,
      ),
    ];

    Future<ProviderContainer> bootDietary() async {
      final container = ProviderContainer(
        overrides: [
          consumerOfferRepositoryProvider.overrideWithValue(
            _FakeConsumerOfferRepository(dietaryOffers),
          ),
          // No location, so ordering falls back to soonest-pickup = insertion
          // order (all offers share a pickup window).
          userLocationProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      await container.read(browseOffersProvider.future);
      return container;
    }

    test('vegan requirement keeps only vegan-tagged offers', () async {
      final c = await bootDietary();
      c.read(browseFilterProvider.notifier).toggleDietary(DietaryOption.vegan);
      expect(ids(c), ['da']);
    });

    test('vegetarian requirement is satisfied by a vegan tag', () async {
      final c = await bootDietary();
      c
          .read(browseFilterProvider.notifier)
          .toggleDietary(DietaryOption.vegetarian);
      expect(ids(c), ['da', 'db']);
    });

    test('halal requirement keys off the merchant flag', () async {
      final c = await bootDietary();
      c.read(browseFilterProvider.notifier).toggleDietary(DietaryOption.halal);
      expect(ids(c), ['da', 'dc']);
    });

    test('multiple requirements are ANDed', () async {
      final c = await bootDietary();
      c.read(browseFilterProvider.notifier)
        ..toggleDietary(DietaryOption.halal)
        ..toggleDietary(DietaryOption.vegan);
      expect(ids(c), ['da']); // da is the only halal AND vegan offer
    });

    test('setDietary overwrites and toggling off clears the filter', () async {
      final c = await bootDietary();
      final notifier = c.read(browseFilterProvider.notifier)
        ..setDietary({DietaryOption.vegan});
      expect(ids(c), ['da']);
      notifier.toggleDietary(DietaryOption.vegan);
      expect(ids(c), ['da', 'db', 'dc']);
    });
  });
}
