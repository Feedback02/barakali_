import '../models/merchant_review.dart';

abstract class MerchantReviewsRepository {
  /// Recent written reviews for [merchantId], newest first, capped at [limit].
  /// Backed by the `get_merchant_reviews` SECURITY DEFINER RPC, which returns
  /// only `score`/`comment`/`created_at` for ratings that carry a non-empty
  /// comment — no reviewer identity reaches the client.
  Future<List<MerchantReview>> fetchRecentReviews(
    String merchantId, {
    int limit = 3,
  });
}
