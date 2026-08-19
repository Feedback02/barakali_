import 'dart:convert';

import 'package:barakali/features/payment/domain/payme_checkout.dart';
import 'package:flutter_test/flutter_test.dart';

String _decodePayload(String url) {
  final encoded = url.split('/').last;
  return utf8.decode(base64.decode(encoded));
}

void main() {
  group('buildPaymeCheckoutUrl', () {
    test('encodes m / ac.order_id / a (tiyin) in the base64 payload', () {
      final url = buildPaymeCheckoutUrl(
        checkoutBase: 'https://checkout.test.paycom.uz',
        merchantId: 'MID123',
        orderId: 'order-1',
        amountTiyin: 2100000,
      );
      expect(url, startsWith('https://checkout.test.paycom.uz/'));
      expect(_decodePayload(url), 'm=MID123;ac.order_id=order-1;a=2100000');
    });

    test('appends optional lang and return url', () {
      final url = buildPaymeCheckoutUrl(
        checkoutBase: 'https://checkout.test.paycom.uz',
        merchantId: 'MID123',
        orderId: 'order-1',
        amountTiyin: 500,
        lang: 'ru',
        returnUrl: 'https://app.example/return',
      );
      expect(
        _decodePayload(url),
        'm=MID123;ac.order_id=order-1;a=500;l=ru;c=https://app.example/return',
      );
    });

    test('normalises a trailing slash on the base', () {
      final url = buildPaymeCheckoutUrl(
        checkoutBase: 'https://checkout.paycom.uz/',
        merchantId: 'M',
        orderId: 'o',
        amountTiyin: 100,
      );
      // exactly one slash between host and payload
      expect(url.startsWith('https://checkout.paycom.uz/'), isTrue);
      expect(url.contains('uz//'), isFalse);
    });
  });
}
