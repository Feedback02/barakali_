import 'package:flutter_test/flutter_test.dart';

import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:barakali/features/orders/domain/models/order_with_details.dart';
import 'package:barakali/features/orders/domain/order_errors.dart';

void main() {
  group('parseOrderError', () {
    test('maps known server tokens to codes', () {
      expect(parseOrderError('SOLD_OUT'), OrderErrorCode.soldOut);
      expect(
        parseOrderError('ERROR: MAX_RESERVATIONS (PL/pgSQL ...)'),
        OrderErrorCode.maxReservations,
      );
      expect(
        parseOrderError('OFFER_UNAVAILABLE'),
        OrderErrorCode.offerUnavailable,
      );
      expect(
        parseOrderError('OFFER_NOT_FOUND'),
        OrderErrorCode.offerUnavailable,
      );
      expect(
        parseOrderError('CANCEL_WINDOW_CLOSED'),
        OrderErrorCode.cancelWindowClosed,
      );
      expect(parseOrderError('NOT_CANCELLABLE'), OrderErrorCode.notCancellable);
      expect(parseOrderError('NOT_RESERVED'), OrderErrorCode.notCancellable);
      expect(parseOrderError('NOT_OWNER'), OrderErrorCode.notOwner);
      expect(
        parseOrderError('NOT_AUTHENTICATED'),
        OrderErrorCode.notAuthenticated,
      );
      expect(parseOrderError('NOT_MERCHANT'), OrderErrorCode.notMerchant);
      expect(parseOrderError('CODE_NOT_FOUND'), OrderErrorCode.codeNotFound);
      expect(parseOrderError('PICKUP_EXPIRED'), OrderErrorCode.pickupExpired);
    });

    test('unknown message falls back to unknown', () {
      expect(parseOrderError('connection reset'), OrderErrorCode.unknown);
    });
  });

  group('Order', () {
    final base = <String, dynamic>{
      'id': 'o1',
      'consumer_id': 'c1',
      'offer_id': 'of1',
      'merchant_id': 'm1',
      'status': 'reserved',
      'pickup_code': 'ABC123',
      'amount_paid': 38000,
      // Fixed platform fee per bag (not a percentage). Effective rate stored
      // for reporting: 7000/38000 ~= 0.1842.
      'commission_amount': 7000,
      'commission_rate': 0.1842,
      'reserved_at': '2026-06-11T10:00:00Z',
      'created_at': '2026-06-11T10:00:00Z',
    };

    Order withStatus(String s) => Order.fromJson({...base, 'status': s});

    test('fromJson maps status, amount and pickup code', () {
      final order = Order.fromJson(base);
      expect(order.status, OrderStatus.reserved);
      expect(order.amountPaid, 38000);
      expect(order.commissionAmount, 7000);
      expect(order.pickupCode, 'ABC123');
    });

    test('netPayout is the bag price minus the fixed platform fee', () {
      expect(Order.fromJson(base).netPayout, 31000);
    });

    test('isActive is true while in progress, false once terminal', () {
      expect(withStatus('reserved').isActive, isTrue);
      expect(withStatus('paid').isActive, isTrue);
      expect(withStatus('picked_up').isActive, isTrue);
      expect(withStatus('completed').isActive, isFalse);
      expect(withStatus('cancelled').isActive, isFalse);
      expect(withStatus('refunded').isActive, isFalse);
      expect(withStatus('expired').isActive, isFalse);
    });

    test('status wire value uses snake_case for picked_up', () {
      expect(OrderStatus.pickedUp.value, 'picked_up');
      expect(OrderStatus.reserved.value, 'reserved');
    });
  });

  group('OrderWithDetails.fromSupabase rating embed', () {
    // Regression: ratings.order_id is UNIQUE, so PostgREST embeds `ratings` as a
    // to-ONE object (or null), NOT a list. Casting it as a List threw and broke
    // the entire orders fetch the moment any order had a rating.
    Map<String, dynamic> orderJson(Object? rating) => {
      'id': 'o1',
      'status': 'completed',
      'pickup_code': 'ABC123',
      'amount_paid': 23000,
      'commission_amount': 5750,
      'commission_rate': 0.25,
      'reserved_at': '2026-06-12T07:51:56Z',
      'created_at': '2026-06-12T07:51:56Z',
      'offer': null,
      'merchant': null,
      'rating': rating,
    };

    test('parses a rating embedded as a to-one object', () {
      final d = OrderWithDetails.fromSupabase(
        orderJson({'score': 5, 'comment': 'great'}),
      );
      expect(d.rating?.score, 5);
      expect(d.rating?.comment, 'great');
    });

    test('tolerates a rating embedded as a list', () {
      final d = OrderWithDetails.fromSupabase(
        orderJson([
          {'score': 4, 'comment': null},
        ]),
      );
      expect(d.rating?.score, 4);
      expect(d.rating?.comment, isNull);
    });

    test('null rating yields no rating', () {
      expect(OrderWithDetails.fromSupabase(orderJson(null)).rating, isNull);
    });
  });
}
