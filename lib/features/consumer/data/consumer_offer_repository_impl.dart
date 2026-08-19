import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/offer_with_merchant.dart';
import '../domain/repositories/consumer_offer_repository.dart';

class ConsumerOfferRepositoryImpl implements ConsumerOfferRepository {
  ConsumerOfferRepositoryImpl(this._client);

  final SupabaseClient _client;

  // Embed the `merchants_public` projection view (public business fields only —
  // no owner user_id / phone PII; base `merchants` is owner/admin-only). The
  // view bakes in `is_approved AND is_active`, so `!inner` drops any active
  // offer whose merchant isn't approved+active without an explicit filter, and
  // a merchant's own pending/deactivated offers can't leak through the base
  // table's owner branch (the embed never touches the base table).
  static const _select =
      '*, merchant:merchants_public!inner('
      'business_name, rating, total_ratings, category, is_halal, '
      'latitude, longitude, address, logo_url)';

  @override
  Future<List<OfferWithMerchant>> fetchBrowseOffers({int limit = 100}) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('offers')
        .select(_select)
        .eq('status', 'active')
        .gt('pickup_end', nowUtc)
        .order('pickup_end', ascending: true)
        .limit(limit);

    return rows.map(OfferWithMerchant.fromSupabase).toList();
  }

  @override
  Future<OfferWithMerchant?> fetchOfferById(String offerId) async {
    // Same claimability gate as fetchBrowseOffers (incl. pickup_end > now() —
    // a just-expired-but-still-active row the cron hasn't flipped must not
    // render as claimable); the `merchants_public` inner-join enforces
    // approved+active. A filtered-out offer comes back null.
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final row = await _client
        .from('offers')
        .select(_select)
        .eq('id', offerId)
        .eq('status', 'active')
        .gt('pickup_end', nowUtc)
        .maybeSingle();
    if (row == null) return null;
    return OfferWithMerchant.fromSupabase(row);
  }

  @override
  Future<List<OfferWithMerchant>> fetchMerchantOffers(String merchantId) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('offers')
        .select(_select)
        .eq('merchant_id', merchantId)
        .eq('status', 'active')
        .gt('pickup_end', nowUtc)
        .order('pickup_end', ascending: true);

    return rows.map(OfferWithMerchant.fromSupabase).toList();
  }
}
