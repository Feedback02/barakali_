import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import '../data/merchant_repository_impl.dart';
import '../domain/models/merchant_public.dart';
import '../domain/models/offer_with_merchant.dart';
import '../domain/repositories/merchant_repository.dart';
import 'browse_providers.dart';

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The public profiles of the merchants the current consumer follows, for the
/// Favorites view. Re-runs on pull-to-refresh / invalidation.
final favoriteMerchantsProvider =
    AsyncNotifierProvider<FavoriteMerchantsNotifier, List<MerchantPublic>>(
      FavoriteMerchantsNotifier.new,
    );

class FavoriteMerchantsNotifier extends AsyncNotifier<List<MerchantPublic>> {
  @override
  Future<List<MerchantPublic>> build() async {
    final merchants = await ref
        .read(merchantRepositoryProvider)
        .fetchFavoriteMerchants();
    log.i('Favorite merchants loaded (count=${merchants.length})');
    return merchants;
  }
}

/// A single public merchant by id, for the merchant screen reached from
/// Favorites. Null => not publicly visible (unapproved/deactivated).
final merchantByIdProvider = FutureProvider.family<MerchantPublic?, String>((
  ref,
  merchantId,
) {
  return ref.read(merchantRepositoryProvider).fetchMerchant(merchantId);
});

/// The currently-claimable offers for one merchant, for the merchant screen.
final merchantOffersProvider =
    FutureProvider.family<List<OfferWithMerchant>, String>((ref, merchantId) {
      return ref
          .read(consumerOfferRepositoryProvider)
          .fetchMerchantOffers(merchantId);
    });
