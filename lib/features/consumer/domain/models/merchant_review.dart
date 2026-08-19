/// A single public review shown on the offer-detail trust block. Built from the
/// `get_merchant_reviews` RPC, which returns ONLY these three fields — never the
/// rating's id / consumer_id / order_id (no PII, no transaction linkage). The
/// reviewer stays anonymous in the UI by design.
class MerchantReview {
  const MerchantReview({
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final int score;
  final String comment;
  final DateTime createdAt;

  factory MerchantReview.fromJson(Map<String, dynamic> json) => MerchantReview(
    score: (json['score'] as num).toInt(),
    // The RPC only ever returns non-empty comments, but tolerate null/empty so
    // a future filter change can't crash the whole fetch inside `rows.map(...)`.
    comment: (json['comment'] as String?) ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
