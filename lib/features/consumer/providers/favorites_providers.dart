import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import '../data/favorites_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';
import 'merchant_providers.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The set of merchant ids the current consumer follows. Toggled optimistically
/// from the offer detail screen; reverts if the write fails.
final favoriteMerchantIdsProvider =
    AsyncNotifierProvider<FavoriteMerchantIdsNotifier, Set<String>>(
      FavoriteMerchantIdsNotifier.new,
    );

class FavoriteMerchantIdsNotifier extends AsyncNotifier<Set<String>> {
  // Merchant ids with a write in flight — guards against a double-tap race
  // where overlapping toggles' revert snapshots would desync the heart.
  final Set<String> _inFlight = {};

  @override
  Future<Set<String>> build() async {
    return ref.read(favoritesRepositoryProvider).fetchFavoriteMerchantIds();
  }

  /// Optimistically flips the favorite state for [merchantId]. Returns true on
  /// success, false if the write failed (the optimistic change is reverted), or
  /// null if the tap was ignored because a write for [merchantId] is already in
  /// flight. The UI shows a result message only for a non-null result.
  Future<bool?> toggle(String merchantId) async {
    if (!_inFlight.add(merchantId)) return null;
    try {
      final current = state.value ?? <String>{};
      final wasFavorite = current.contains(merchantId);
      final updated = {...current};
      if (wasFavorite) {
        updated.remove(merchantId);
      } else {
        updated.add(merchantId);
      }
      state = AsyncData(updated);

      try {
        final repo = ref.read(favoritesRepositoryProvider);
        if (wasFavorite) {
          await repo.removeFavorite(merchantId);
        } else {
          await repo.addFavorite(merchantId);
        }
        log.i('Favorite toggled (favorited=${!wasFavorite})');
        // The Favorites list is a separate query (favoriteMerchantsProvider);
        // invalidate it so unfollowing here (or from offer detail) doesn't leave
        // a removed merchant lingering until a manual refresh.
        ref.invalidate(favoriteMerchantsProvider);
        return true;
      } catch (_) {
        state = AsyncData(current);
        log.w('Favorite toggle failed');
        return false;
      }
    } finally {
      _inFlight.remove(merchantId);
    }
  }
}
