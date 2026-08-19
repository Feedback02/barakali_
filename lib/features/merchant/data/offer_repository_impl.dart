import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/offer.dart';
import '../domain/repositories/offer_repository.dart';

class OfferRepositoryImpl implements OfferRepository {
  OfferRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _bucket = 'offer-images';

  @override
  Future<List<Offer>> fetchMyOffers(String merchantId) async {
    final rows = await _client
        .from('offers')
        .select()
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);

    return rows.map(Offer.fromJson).toList();
  }

  @override
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
  }) async {
    final row = await _client
        .from('offers')
        .insert({
          'merchant_id': merchantId,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'category': category.value,
          'original_price': originalPrice,
          'discounted_price': discountedPrice,
          'quantity_total': quantity,
          'quantity_remaining': quantity,
          'pickup_start': pickupStart.toUtc().toIso8601String(),
          'pickup_end': pickupEnd.toUtc().toIso8601String(),
          'image_url': ?imageUrl,
          'dietary_tags': dietaryTags,
          'status': publish
              ? OfferStatus.active.value
              : OfferStatus.draft.value,
        })
        .select()
        .single();

    return Offer.fromJson(row);
  }

  @override
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
  }) async {
    final row = await _client
        .from('offers')
        .update({
          'title': title,
          'description': ?description,
          'category': category.value,
          'original_price': originalPrice,
          'discounted_price': discountedPrice,
          // Both quantity columns are reset to the new total. Reservations
          // decrement quantity_remaining, so an edit made while orders are in
          // flight hands back stock that is already spoken for; a correct edit
          // has to recompute quantity_remaining as (total - reserved).
          'quantity_total': quantity,
          'quantity_remaining': quantity,
          'pickup_start': pickupStart.toUtc().toIso8601String(),
          'pickup_end': pickupEnd.toUtc().toIso8601String(),
          'image_url': ?imageUrl,
          'dietary_tags': dietaryTags,
          'status': publish
              ? OfferStatus.active.value
              : OfferStatus.draft.value,
        })
        .eq('id', offerId)
        .select()
        .single();

    return Offer.fromJson(row);
  }

  @override
  Future<void> setOfferStatus({
    required String offerId,
    required OfferStatus status,
  }) async {
    // .select() so an RLS-filtered (0-row) write surfaces as an error instead
    // of a silent success the UI would report as "Status updated".
    final rows = await _client
        .from('offers')
        .update({'status': status.value})
        .eq('id', offerId)
        .select('id');
    if (rows.isEmpty) throw StateError('Offer not found or not owned');
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    final rows = await _client
        .from('offers')
        .delete()
        .eq('id', offerId)
        .select('id');
    if (rows.isEmpty) throw StateError('Offer not found or not owned');
  }

  @override
  Future<String> uploadOfferImage({
    required String merchantId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final path = '$merchantId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
