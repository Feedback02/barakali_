import 'package:barakali/features/consumer/domain/repositories/favorites_repository.dart';
import 'package:barakali/features/consumer/providers/favorites_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  _FakeFavoritesRepository(Set<String> initial) : _ids = {...initial};

  final Set<String> _ids;
  bool failNextWrite = false;
  final List<String> added = [];
  final List<String> removed = [];

  @override
  Future<Set<String>> fetchFavoriteMerchantIds() async => {..._ids};

  @override
  Future<void> addFavorite(String merchantId) async {
    if (failNextWrite) throw Exception('write failed');
    added.add(merchantId);
  }

  @override
  Future<void> removeFavorite(String merchantId) async {
    if (failNextWrite) throw Exception('write failed');
    removed.add(merchantId);
  }
}

void main() {
  group('FavoriteMerchantIdsNotifier.toggle', () {
    test('adds a merchant optimistically and persists it', () async {
      final repo = _FakeFavoritesRepository({});
      final container = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(favoriteMerchantIdsProvider.future);

      final ok = await container
          .read(favoriteMerchantIdsProvider.notifier)
          .toggle('m1');

      expect(ok, isTrue);
      expect(container.read(favoriteMerchantIdsProvider).value, {'m1'});
      expect(repo.added, ['m1']);
    });

    test('removes an already-favorited merchant', () async {
      final repo = _FakeFavoritesRepository({'m1'});
      final container = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(favoriteMerchantIdsProvider.future);

      final ok = await container
          .read(favoriteMerchantIdsProvider.notifier)
          .toggle('m1');

      expect(ok, isTrue);
      expect(container.read(favoriteMerchantIdsProvider).value, isEmpty);
      expect(repo.removed, ['m1']);
    });

    test(
      'reverts the optimistic change and returns false on write failure',
      () async {
        final repo = _FakeFavoritesRepository({})..failNextWrite = true;
        final container = ProviderContainer(
          overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        await container.read(favoriteMerchantIdsProvider.future);

        final ok = await container
            .read(favoriteMerchantIdsProvider.notifier)
            .toggle('m1');

        expect(ok, isFalse);
        expect(container.read(favoriteMerchantIdsProvider).value, isEmpty);
        expect(repo.added, isEmpty);
      },
    );
  });
}
