import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import '../data/offer_repository_impl.dart';
import '../domain/models/offer.dart';
import '../domain/repositories/offer_repository.dart';
import '../presentation/utils/offer_image.dart';
import 'merchant_providers.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The current merchant's offers, newest first (empty if not a merchant).
final myOffersProvider = AsyncNotifierProvider<MyOffersNotifier, List<Offer>>(
  MyOffersNotifier.new,
);

class MyOffersNotifier extends AsyncNotifier<List<Offer>> {
  @override
  Future<List<Offer>> build() async {
    final merchant = await ref.watch(myMerchantProvider.future);
    if (merchant == null) return const [];
    return ref.read(offerRepositoryProvider).fetchMyOffers(merchant.id);
  }
}

/// CPU-bound image processing (EXIF strip + compress) off the UI thread on
/// mobile, then upload under the merchant's folder. Returns null for [bytes]
/// null (no new photo picked); throws [FormatException] on an unusable image.
Future<String?> _processAndUpload(
  Ref ref,
  String merchantId,
  Uint8List? bytes,
) async {
  if (bytes == null) return null;
  final processed = await compute(processOfferImage, bytes);
  if (processed == null) throw const FormatException('Unsupported image');
  return ref
      .read(offerRepositoryProvider)
      .uploadOfferImage(merchantId: merchantId, bytes: processed, ext: 'jpg');
}

/// Drives the create/edit/duplicate offer form (image processing + upload +
/// insert or update). [submitCreate] is used by both create and duplicate.
final offerFormProvider = AsyncNotifierProvider<OfferFormNotifier, void>(
  OfferFormNotifier.new,
);

class OfferFormNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitCreate({
    required String title,
    String? description,
    required OfferCategory category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    Uint8List? imageBytes,
    String? existingImageUrl,
    required List<String> dietaryTags,
    required bool publish,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final merchant = await ref.read(myMerchantProvider.future);
      if (merchant == null) throw StateError('No merchant record');
      final repo = ref.read(offerRepositoryProvider);

      final uploaded = await _processAndUpload(ref, merchant.id, imageBytes);

      await repo.createOffer(
        merchantId: merchant.id,
        title: title,
        description: description,
        category: category,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
        imageUrl: uploaded ?? existingImageUrl,
        dietaryTags: dietaryTags,
        publish: publish,
      );
      log.i('Offer created (publish=$publish)');
      ref.invalidate(myOffersProvider);
    });
  }

  Future<void> submitUpdate({
    required String offerId,
    required String title,
    String? description,
    required OfferCategory category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    Uint8List? imageBytes,
    String? existingImageUrl,
    required List<String> dietaryTags,
    required bool publish,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final merchant = await ref.read(myMerchantProvider.future);
      if (merchant == null) throw StateError('No merchant record');
      final repo = ref.read(offerRepositoryProvider);

      final uploaded = await _processAndUpload(ref, merchant.id, imageBytes);

      await repo.updateOffer(
        offerId: offerId,
        title: title,
        description: description,
        category: category,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
        imageUrl: uploaded ?? existingImageUrl,
        dietaryTags: dietaryTags,
        publish: publish,
      );
      log.i('Offer updated (id=$offerId, publish=$publish)');
      ref.invalidate(myOffersProvider);
    });
  }
}

/// Dashboard quick actions (status change, delete). Kept separate from
/// [offerFormProvider] so the card menu's loading/error state is independent
/// of the form.
final manageOffersProvider = AsyncNotifierProvider<ManageOffersNotifier, void>(
  ManageOffersNotifier.new,
);

class ManageOffersNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setStatus(String offerId, OfferStatus status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(offerRepositoryProvider)
          .setOfferStatus(offerId: offerId, status: status);
      log.i('Offer status set (id=$offerId, status=${status.value})');
      ref.invalidate(myOffersProvider);
    });
  }

  Future<void> delete(String offerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(offerRepositoryProvider).deleteOffer(offerId);
      log.i('Offer deleted (id=$offerId)');
      ref.invalidate(myOffersProvider);
    });
  }
}
