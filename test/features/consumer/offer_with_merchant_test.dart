import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/features/consumer/domain/models/offer_with_merchant.dart';
import 'package:barakali/features/merchant/domain/models/offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferWithMerchant.fromSupabase', () {
    Map<String, dynamic> row() => {
      'id': 'offer-1',
      'merchant_id': 'merchant-1',
      'title': 'Surprise pastry bag',
      'description': null,
      'category': 'bakery',
      'original_price': 85000,
      'discounted_price': 45000,
      'quantity_total': 8,
      'quantity_remaining': 3,
      'pickup_start': '2026-06-10T13:00:00Z',
      'pickup_end': '2026-06-10T15:00:00Z',
      'image_url': 'https://example.com/x.jpg',
      'status': 'active',
      'dietary_tags': ['vegetarian', 'vegan'],
      'created_at': '2026-06-10T09:00:00Z',
      'updated_at': '2026-06-10T09:00:00Z',
      'merchant': {
        'business_name': 'Paul Bakery',
        'rating': 4.5,
        'total_ratings': 12,
        'category': 'bakery',
        'is_halal': true,
        'latitude': 41.31,
        'longitude': 69.24,
        'address': 'Amir Temur Ave, 42',
        'logo_url': null,
      },
    };

    test('maps the embedded offer fields onto a typed Offer', () {
      final result = OfferWithMerchant.fromSupabase(row());

      expect(result.offer.id, 'offer-1');
      expect(result.offer.title, 'Surprise pastry bag');
      expect(result.offer.category, OfferCategory.bakery);
      expect(result.offer.discountedPrice, 45000);
      expect(result.offer.quantityRemaining, 3);
      expect(result.offer.status, OfferStatus.active);
    });

    test('maps the nested merchant summary (public fields only)', () {
      final result = OfferWithMerchant.fromSupabase(row());

      expect(result.merchant.name, 'Paul Bakery');
      expect(result.merchant.rating, 4.5);
      expect(result.merchant.totalRatings, 12);
      expect(result.merchant.category, 'bakery');
      expect(result.merchant.latitude, 41.31);
      expect(result.merchant.longitude, 69.24);
      expect(result.merchant.address, 'Amir Temur Ave, 42');
      expect(result.merchant.logoUrl, isNull);
    });

    test('maps offer dietary tags and the merchant halal flag', () {
      final result = OfferWithMerchant.fromSupabase(row());

      expect(result.offer.dietaryTags, ['vegetarian', 'vegan']);
      expect(result.offer.dietaryOptions, {
        DietaryOption.vegetarian,
        DietaryOption.vegan,
      });
      expect(result.merchant.isHalal, isTrue);
    });

    test('defaults dietary tags to empty and halal to false when absent', () {
      final r = row()..remove('dietary_tags');
      (r['merchant'] as Map<String, dynamic>).remove('is_halal');

      final result = OfferWithMerchant.fromSupabase(r);

      expect(result.offer.dietaryTags, isEmpty);
      expect(result.merchant.isHalal, isFalse);
    });

    test('handles an integer rating and null coordinates', () {
      final r = row();
      (r['merchant'] as Map<String, dynamic>)
        ..['rating'] = 5
        ..['latitude'] = null
        ..['longitude'] = null;

      final result = OfferWithMerchant.fromSupabase(r);

      expect(result.merchant.rating, 5.0);
      expect(result.merchant.latitude, isNull);
      expect(result.merchant.longitude, isNull);
    });
  });
}
