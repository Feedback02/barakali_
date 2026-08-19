import 'dart:typed_data';

import '../models/offer.dart';

abstract class OfferRepository {
  /// All offers owned by [merchantId], newest first.
  Future<List<Offer>> fetchMyOffers(String merchantId);

  /// Creates an offer. [quantity] seeds both quantity_total and
  /// quantity_remaining server-side — the client never sets them apart.
  /// [publish] true => status 'active' (requires an approved merchant, enforced
  /// by the check_merchant_approved trigger); false => 'draft'.
  Future<Offer> createOffer({
    required String merchantId,
    required String title,
    String? description,
    required OfferCategory category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    String? imageUrl,
    required List<String> dietaryTags,
    required bool publish,
  });

  /// Updates an existing offer the caller owns (RLS enforces ownership).
  /// [publish] true => status 'active' (approved merchant required), false =>
  /// 'draft'. [quantity] re-seeds both quantity columns (see impl note).
  Future<Offer> updateOffer({
    required String offerId,
    required String title,
    String? description,
    required OfferCategory category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    String? imageUrl,
    required List<String> dietaryTags,
    required bool publish,
  });

  /// Sets only the lifecycle status of an offer the caller owns (e.g. publish,
  /// deactivate to draft, cancel). Server re-checks approval for 'active'.
  Future<void> setOfferStatus({
    required String offerId,
    required OfferStatus status,
  });

  /// Permanently deletes an offer the caller owns (RLS enforces ownership).
  Future<void> deleteOffer(String offerId);

  /// Uploads [bytes] (already compressed + EXIF-stripped) under the merchant's
  /// own folder and returns the public URL. Storage RLS rejects writes outside
  /// `{merchantId}/...`.
  Future<String> uploadOfferImage({
    required String merchantId,
    required Uint8List bytes,
    required String ext,
  });
}
