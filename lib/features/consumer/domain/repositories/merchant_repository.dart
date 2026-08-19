import '../models/merchant_public.dart';

abstract class MerchantRepository {
  /// A single public merchant by [merchantId] (only approved + active merchants
  /// are exposed by the `merchants_public` view), or null if it is not
  /// publicly visible.
  Future<MerchantPublic?> fetchMerchant(String merchantId);

  /// The public profiles of the merchants the current consumer follows. RLS
  /// scopes the `favorites` read to their own rows; a followed merchant that is
  /// no longer approved/active simply drops out (the view filters it).
  Future<List<MerchantPublic>> fetchFavoriteMerchants();
}
