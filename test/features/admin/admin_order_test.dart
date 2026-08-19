import 'package:barakali/features/admin/domain/models/admin_order.dart';
import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(Map<String, dynamic> overrides) => {
  'id': '56115cd4-0000-4000-8000-000000000001',
  'status': 'paid',
  'amount_paid': 25000,
  'commission_amount': 6250,
  'reserved_at': '2026-06-12T08:00:00Z',
  'paid_at': '2026-06-12T08:05:00Z',
  'picked_up_at': null,
  'cancelled_at': null,
  'cancellation_reason': null,
  'payment_provider': 'payme',
  'consumer_id': 'c0000000-0000-4000-8000-000000000002',
  'consumer_phone': '+998900000002',
  'consumer_name': 'Test Consumer',
  'merchant_id': '576fc30a-b5cc-4467-9c25-b5a8c6743639',
  'merchant_name': 'Paul Bakery',
  'offer_id': 'd0000000-0000-4000-8000-000000000001',
  'offer_title': 'Surprise pastry bag',
  ...overrides,
};

void main() {
  test('AdminOrder.fromJson maps the enriched search row', () {
    final o = AdminOrder.fromJson(_row({}));
    expect(o.status, OrderStatus.paid);
    expect(o.amountPaid, 25000);
    expect(o.commissionAmount, 6250);
    expect(o.consumerPhone, '+998900000002');
    expect(o.merchantName, 'Paul Bakery');
    expect(o.offerTitle, 'Surprise pastry bag');
    expect(o.paidAt, isNotNull);
    expect(o.pickedUpAt, isNull);
  });

  test('isRefundable is true only for a paid order', () {
    expect(AdminOrder.fromJson(_row({'status': 'paid'})).isRefundable, isTrue);
    for (final s in [
      'reserved',
      'picked_up',
      'completed',
      'refunded',
      'cancelled',
      'expired',
    ]) {
      expect(
        AdminOrder.fromJson(_row({'status': s})).isRefundable,
        isFalse,
        reason: '$s must not be refundable',
      );
    }
  });

  test('picked_up status wire value parses to OrderStatus.pickedUp', () {
    final o = AdminOrder.fromJson(
      _row({'status': 'picked_up', 'picked_up_at': '2026-06-12T09:00:00Z'}),
    );
    expect(o.status, OrderStatus.pickedUp);
    expect(o.pickedUpAt, isNotNull);
  });

  test('tolerates nulled consumer (erased) — order still parses', () {
    final o = AdminOrder.fromJson(
      _row({
        'consumer_id': null,
        'consumer_phone': null,
        'consumer_name': null,
      }),
    );
    expect(o.consumerId, isNull);
    expect(o.consumerPhone, isNull);
    expect(o.merchantName, 'Paul Bakery');
  });
}
