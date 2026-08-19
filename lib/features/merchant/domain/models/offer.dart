import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:barakali/core/models/dietary.dart';

part 'offer.freezed.dart';
part 'offer.g.dart';

/// A surplus food offer published by a merchant. Prices are integer UZS
/// (no minor unit); mirrors the `public.offers` table.
@freezed
abstract class Offer with _$Offer {
  const factory Offer({
    required String id,
    @JsonKey(name: 'merchant_id') required String merchantId,
    required String title,
    String? description,
    required OfferCategory category,
    @JsonKey(name: 'original_price') required int originalPrice,
    @JsonKey(name: 'discounted_price') required int discountedPrice,
    @JsonKey(name: 'quantity_total') required int quantityTotal,
    @JsonKey(name: 'quantity_remaining') required int quantityRemaining,
    @JsonKey(name: 'pickup_start') required DateTime pickupStart,
    @JsonKey(name: 'pickup_end') required DateTime pickupEnd,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'dietary_tags')
    @Default(<String>[])
    List<String> dietaryTags,
    required OfferStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Offer;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
}

extension OfferLifecycle on Offer {
  /// UI-facing status that anticipates the server-side auto-expiry sweep
  /// (`expire_offers()` on a 5-min pg_cron schedule). An active offer reads as
  /// expired/soldOut immediately rather than lingering "active" in the
  /// up-to-5-min gap before the cron flips the real row. Read-only/derived —
  /// it never changes the value written to the DB.
  OfferStatus get effectiveStatus {
    if (status == OfferStatus.active) {
      if (pickupEnd.toUtc().isBefore(DateTime.now().toUtc())) {
        return OfferStatus.expired;
      }
      if (quantityRemaining <= 0) return OfferStatus.soldOut;
    }
    return status;
  }

  /// The offer's dietary tags parsed to the shared enum (unknown values dropped).
  Set<DietaryOption> get dietaryOptions => DietaryOption.parse(dietaryTags);
}

/// Allowed offer categories (matches the DB CHECK constraint).
enum OfferCategory {
  @JsonValue('meal')
  meal,
  @JsonValue('bakery')
  bakery,
  @JsonValue('grocery')
  grocery,
  @JsonValue('mixed')
  mixed,
  @JsonValue('other')
  other;

  /// The wire value stored in the DB.
  String get value => name;
}

/// Offer lifecycle states (matches the DB CHECK constraint).
enum OfferStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('active')
  active,
  @JsonValue('sold_out')
  soldOut,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled;

  /// The wire value stored in the DB (snake_case for `sold_out`).
  String get value => switch (this) {
    OfferStatus.soldOut => 'sold_out',
    _ => name,
  };
}
