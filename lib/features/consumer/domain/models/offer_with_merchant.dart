import 'package:barakali/features/merchant/domain/models/offer.dart';

/// A browse-list row: an [Offer] joined with a public summary of its merchant.
/// Built from a PostgREST embedded select (`offers` + `merchant:merchants(...)`).
/// Plain immutable class (not freezed) because it composes the existing freezed
/// [Offer] with a nested embed that doesn't map cleanly through generated JSON.
class OfferWithMerchant {
  const OfferWithMerchant({required this.offer, required this.merchant});

  final Offer offer;
  final MerchantSummary merchant;

  factory OfferWithMerchant.fromSupabase(Map<String, dynamic> json) {
    final merchantJson = json['merchant'] as Map<String, dynamic>;
    return OfferWithMerchant(
      // Offer.fromJson ignores the extra nested `merchant` key.
      offer: Offer.fromJson(json),
      merchant: MerchantSummary.fromJson(merchantJson),
    );
  }
}

/// Public-facing subset of a merchant, denormalized onto a browse row. Only the
/// fields a consumer needs to render a card/detail — no owner/contact PII.
class MerchantSummary {
  const MerchantSummary({
    required this.name,
    required this.rating,
    required this.totalRatings,
    required this.category,
    required this.address,
    this.isHalal = false,
    this.latitude,
    this.longitude,
    this.logoUrl,
  });

  final String name;
  final double rating;
  final int totalRatings;
  final String category;
  final String address;
  final bool isHalal;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;

  factory MerchantSummary.fromJson(Map<String, dynamic> json) =>
      MerchantSummary(
        name: json['business_name'] as String,
        rating: (json['rating'] as num).toDouble(),
        totalRatings: json['total_ratings'] as int,
        category: json['category'] as String,
        address: json['address'] as String,
        isHalal: (json['is_halal'] as bool?) ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        logoUrl: json['logo_url'] as String?,
      );
}
