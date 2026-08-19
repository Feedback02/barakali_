import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/merchant_public.dart';
import '../domain/repositories/merchant_repository.dart';

class MerchantRepositoryImpl implements MerchantRepository {
  MerchantRepositoryImpl(this._client);

  final SupabaseClient _client;

  // Public business fields only — no owner user_id / phone PII. The
  // `merchants_public` view bakes in `is_approved AND is_active`, so an
  // unapproved/deactivated merchant is simply absent (returns null / drops out).
  static const _select =
      'id, business_name, description, address, latitude, longitude, '
      'logo_url, cover_image_url, category, rating, total_ratings, '
      'total_bags_saved, is_halal';

  @override
  Future<MerchantPublic?> fetchMerchant(String merchantId) async {
    final row = await _client
        .from('merchants_public')
        .select(_select)
        .eq('id', merchantId)
        .maybeSingle();
    if (row == null) return null;
    return MerchantPublic.fromJson(row);
  }

  @override
  Future<List<MerchantPublic>> fetchFavoriteMerchants() async {
    // Two steps rather than a favorites->merchants_public embed: PostgREST
    // can't reliably infer a FK relationship to a view, and the favorite-id set
    // is small. RLS scopes the favorites read to the caller.
    final favRows = await _client.from('favorites').select('merchant_id');
    final ids = favRows.map((r) => r['merchant_id'] as String).toList();
    if (ids.isEmpty) return [];

    final rows = await _client
        .from('merchants_public')
        .select(_select)
        .inFilter('id', ids)
        .order('business_name', ascending: true);
    return rows.map(MerchantPublic.fromJson).toList();
  }
}
