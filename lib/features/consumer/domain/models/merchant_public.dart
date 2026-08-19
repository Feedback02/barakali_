/// Public-facing merchant profile, read from the `merchants_public` projection
/// view (no owner/contact PII; the view exposes only approved + active
/// merchants). Carries the `id` so a row can be navigated to / favorited,
/// unlike the leaner [MerchantSummary] denormalized onto a browse offer.
class MerchantPublic {
  const MerchantPublic({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.rating,
    required this.totalRatings,
    required this.totalBagsSaved,
    this.isHalal = false,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final double rating;
  final int totalRatings;
  final int totalBagsSaved;
  final bool isHalal;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;

  factory MerchantPublic.fromJson(Map<String, dynamic> json) => MerchantPublic(
    id: json['id'] as String,
    name: json['business_name'] as String,
    category: json['category'] as String,
    address: json['address'] as String,
    rating: (json['rating'] as num).toDouble(),
    totalRatings: json['total_ratings'] as int,
    totalBagsSaved: (json['total_bags_saved'] as num?)?.toInt() ?? 0,
    isHalal: (json['is_halal'] as bool?) ?? false,
    description: json['description'] as String?,
    logoUrl: json['logo_url'] as String?,
    coverImageUrl: json['cover_image_url'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}
