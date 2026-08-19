/// A merchant business record. Coordinates are nullable — they are set by an
/// admin at approval time, not captured during self-service registration.
class Merchant {
  const Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.address,
    required this.phone,
    required this.category,
    required this.isApproved,
    required this.isActive,
    this.isHalal = false,
    this.description,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String userId;
  final String businessName;
  final String address;
  final String phone;
  final String category;
  final bool isApproved;
  final bool isActive;
  final bool isHalal;
  final String? description;
  final double? latitude;
  final double? longitude;

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    businessName: json['business_name'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    category: json['category'] as String,
    isApproved: json['is_approved'] as bool,
    isActive: json['is_active'] as bool,
    isHalal: (json['is_halal'] as bool?) ?? false,
    description: json['description'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

/// The allowed merchant business categories (matches the DB CHECK constraint).
enum MerchantCategory {
  restaurant,
  cafe,
  bakery,
  supermarket,
  other;

  String get value => name;
}
