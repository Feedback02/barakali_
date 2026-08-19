import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/merchant_review.dart';
import '../domain/repositories/merchant_reviews_repository.dart';

class MerchantReviewsRepositoryImpl implements MerchantReviewsRepository {
  MerchantReviewsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MerchantReview>> fetchRecentReviews(
    String merchantId, {
    int limit = 3,
  }) async {
    // SECURITY DEFINER RPC returns only score/comment/created_at for commented
    // ratings (no consumer_id/order_id), newest first. The function clamps the
    // limit server-side.
    final rows = await _client.rpc(
      'get_merchant_reviews',
      params: {'p_merchant_id': merchantId, 'p_limit': limit},
    );
    return (rows as List<dynamic>)
        .map((r) => MerchantReview.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
