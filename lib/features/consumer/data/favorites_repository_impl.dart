import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not authenticated');
    return id;
  }

  @override
  Future<Set<String>> fetchFavoriteMerchantIds() async {
    final rows = await _client.from('favorites').select('merchant_id');
    return rows.map((r) => r['merchant_id'] as String).toSet();
  }

  @override
  Future<void> addFavorite(String merchantId) async {
    // Composite PK (consumer_id, merchant_id); ignore a re-follow. consumer_id
    // is set to the caller (RLS WITH CHECK also requires consumer_id = uid).
    await _client
        .from('favorites')
        .upsert(
          {'consumer_id': _uid, 'merchant_id': merchantId},
          onConflict: 'consumer_id,merchant_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> removeFavorite(String merchantId) async {
    // RLS already scopes deletes to the caller; the explicit consumer_id keeps
    // the statement self-evidently owner-scoped.
    await _client
        .from('favorites')
        .delete()
        .eq('consumer_id', _uid)
        .eq('merchant_id', merchantId);
  }
}
