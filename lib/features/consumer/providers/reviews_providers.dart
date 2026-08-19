import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import '../data/merchant_reviews_repository_impl.dart';
import '../domain/models/merchant_review.dart';
import '../domain/repositories/merchant_reviews_repository.dart';

final merchantReviewsRepositoryProvider = Provider<MerchantReviewsRepository>((
  ref,
) {
  return MerchantReviewsRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Recent written reviews for one merchant, for the offer-detail trust block.
/// Keyed by merchantId. A failure here must never break the detail screen — the
/// UI renders the reviews section only on `data`, silently hiding it on error.
final merchantReviewsProvider =
    FutureProvider.family<List<MerchantReview>, String>((ref, merchantId) {
      return ref
          .read(merchantReviewsRepositoryProvider)
          .fetchRecentReviews(merchantId);
    });
