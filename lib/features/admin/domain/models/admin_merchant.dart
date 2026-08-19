/// The moderation state of a merchant, derived from the server-owned flags
/// `is_approved` / `is_active` plus `rejected_at`. These four states are
/// mutually exclusive and drive both the admin queue tabs and the row chip.
enum MerchantModerationState {
  /// Applied, never reviewed: is_approved = false AND rejected_at IS NULL.
  pending,

  /// Approved and live: is_approved = true AND is_active = true.
  approved,

  /// Approved then turned off by an admin: is_approved = true AND is_active = false.
  suspended,

  /// Reviewed and declined: is_approved = false AND rejected_at IS NOT NULL.
  rejected,
}

/// A merchant record as the admin console sees it — the full business row
/// including the server-owned moderation/metrics columns the consumer/merchant
/// facing [Merchant] model deliberately omits. Read-only projection; all writes
/// go through the admin-gated RPCs (approve/reject/set_merchant_active).
class AdminMerchant {
  const AdminMerchant({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.address,
    required this.phone,
    required this.category,
    required this.isApproved,
    required this.isActive,
    required this.rating,
    required this.totalRatings,
    required this.totalBagsSaved,
    required this.createdAt,
    this.isHalal = false,
    this.platformFee,
    this.description,
    this.latitude,
    this.longitude,
    this.approvedAt,
    this.rejectedAt,
    this.suspendedAt,
    this.moderationNote,
  });

  final String id;
  final String userId;
  final String businessName;
  final String address;
  final String phone;
  final String category;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final int totalBagsSaved;
  final DateTime createdAt;

  /// Merchant self-declared halal establishment flag. Merchant-writable (not a
  /// guarded column); an admin can also set it via the `set_merchant_halal` RPC.
  final bool isHalal;

  /// Per-merchant platform fee override in integer UZS; null = use the platform
  /// default (`platform_config.bag_fee`). Only an admin can set it (via the
  /// `set_merchant_fee` RPC); the merchant cannot change its own.
  final int? platformFee;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? suspendedAt;
  final String? moderationNote;

  MerchantModerationState get state {
    if (isApproved) {
      return isActive
          ? MerchantModerationState.approved
          : MerchantModerationState.suspended;
    }
    return rejectedAt == null
        ? MerchantModerationState.pending
        : MerchantModerationState.rejected;
  }

  factory AdminMerchant.fromJson(Map<String, dynamic> json) => AdminMerchant(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    businessName: json['business_name'] as String,
    address: json['address'] as String,
    phone: json['phone'] as String,
    category: json['category'] as String,
    isApproved: json['is_approved'] as bool,
    isActive: json['is_active'] as bool,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    totalRatings: (json['total_ratings'] as int?) ?? 0,
    totalBagsSaved: (json['total_bags_saved'] as int?) ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    isHalal: (json['is_halal'] as bool?) ?? false,
    platformFee: json['platform_fee'] as int?,
    description: json['description'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    approvedAt: _parseTs(json['approved_at']),
    rejectedAt: _parseTs(json['rejected_at']),
    suspendedAt: _parseTs(json['suspended_at']),
    moderationNote: json['moderation_note'] as String?,
  );

  static DateTime? _parseTs(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
