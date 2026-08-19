import 'package:flutter_test/flutter_test.dart';

import 'package:barakali/features/merchant/domain/models/offer.dart';

void main() {
  Offer build({
    required OfferStatus status,
    required DateTime pickupEnd,
    int quantityRemaining = 5,
  }) {
    final now = DateTime.now().toUtc();
    return Offer(
      id: 'o1',
      merchantId: 'm1',
      title: 'Box',
      category: OfferCategory.bakery,
      originalPrice: 30000,
      discountedPrice: 10000,
      quantityTotal: 5,
      quantityRemaining: quantityRemaining,
      pickupStart: now.subtract(const Duration(hours: 2)),
      pickupEnd: pickupEnd,
      status: status,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    );
  }

  group('Offer.effectiveStatus', () {
    final future = DateTime.now().toUtc().add(const Duration(hours: 2));
    final past = DateTime.now().toUtc().subtract(const Duration(minutes: 10));

    test('active + past pickup window reads as expired', () {
      expect(
        build(status: OfferStatus.active, pickupEnd: past).effectiveStatus,
        OfferStatus.expired,
      );
    });

    test('active + no stock (window still open) reads as soldOut', () {
      expect(
        build(
          status: OfferStatus.active,
          pickupEnd: future,
          quantityRemaining: 0,
        ).effectiveStatus,
        OfferStatus.soldOut,
      );
    });

    test('expiry wins over sold-out when the window has also passed', () {
      expect(
        build(
          status: OfferStatus.active,
          pickupEnd: past,
          quantityRemaining: 0,
        ).effectiveStatus,
        OfferStatus.expired,
      );
    });

    test('active + open window + stock stays active', () {
      expect(
        build(status: OfferStatus.active, pickupEnd: future).effectiveStatus,
        OfferStatus.active,
      );
    });

    test(
      'non-active statuses pass through unchanged even if window passed',
      () {
        for (final s in [
          OfferStatus.draft,
          OfferStatus.cancelled,
          OfferStatus.soldOut,
          OfferStatus.expired,
        ]) {
          expect(
            build(
              status: s,
              pickupEnd: past,
              quantityRemaining: 0,
            ).effectiveStatus,
            s,
            reason: '$s must not be auto-derived away',
          );
        }
      },
    );
  });
}
