import 'package:barakali/features/consumer/domain/models/offer_with_merchant.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';

import 'order.dart';

/// An [Order] joined with the offer it's for and a public summary of the
/// merchant, for the orders list/detail. Built from a PostgREST embedded select
/// (`orders` + `offer:offers(*)` + `merchant:merchants(...)`).
///
/// [offer] and [merchant] are nullable: a merchant can delete an offer (FK
/// `ON DELETE SET NULL`), leaving an order whose offer is gone — the UI shows a
/// fallback rather than crashing.
/// The consumer's rating for an order (if they've rated it).
typedef OrderRating = ({int score, String? comment});

class OrderWithDetails {
  const OrderWithDetails({
    required this.order,
    required this.offer,
    required this.merchant,
    this.rating,
  });

  final Order order;
  final Offer? offer;
  final MerchantSummary? merchant;

  /// The rating left for this order, or null if not yet rated (one per order).
  final OrderRating? rating;

  factory OrderWithDetails.fromSupabase(Map<String, dynamic> json) {
    final offerJson = json['offer'] as Map<String, dynamic>?;
    final merchantJson = json['merchant'] as Map<String, dynamic>?;
    // PostgREST embeds `ratings` as a to-ONE object (a Map when present, null
    // when not) — NOT a list — because `ratings.order_id` is UNIQUE, so the
    // planner sees a one-to-one relationship. Tolerate a list too in case the
    // cardinality ever changes. (Casting this as a List crashed the whole
    // orders fetch the moment any order had a rating.)
    final ratingRaw = json['rating'];
    final ratingJson = switch (ratingRaw) {
      final Map<String, dynamic> m => m,
      final List<dynamic> l when l.isNotEmpty =>
        l.first as Map<String, dynamic>,
      _ => null,
    };
    return OrderWithDetails(
      order: Order.fromJson(json),
      offer: offerJson == null ? null : Offer.fromJson(offerJson),
      merchant: merchantJson == null
          ? null
          : MerchantSummary.fromJson(merchantJson),
      rating: ratingJson == null
          ? null
          : (
              score: ratingJson['score'] as int,
              comment: ratingJson['comment'] as String?,
            ),
    );
  }
}
