import 'package:flutter/foundation.dart';

/// Build-time payment configuration (via --dart-define), kept out of source.
///
/// - [paymeMerchantId]: the platform's Payme *kassa* id (public — it travels in
///   the checkout URL). When empty, the real Payme button is hidden and only the
///   dev mock is available.
/// - [checkoutBase]: the Payme checkout host. Defaults to the SANDBOX
///   (`checkout.test.paycom.uz`); production builds pass `checkout.paycom.uz`.
/// - [mockEnabled]: whether the dev-only "simulate payment" affordance shows.
///   Defaults to true for dev; production builds pass `false`.
class PaymentConfig {
  const PaymentConfig({
    this.paymeMerchantId = '',
    this.checkoutBase = 'https://checkout.test.paycom.uz',
    this.mockEnabled = true,
  });

  final String paymeMerchantId;
  final String checkoutBase;
  final bool mockEnabled;

  /// True once a Payme kassa id is configured — gates the real "Pay with Payme".
  bool get isPaymeConfigured => paymeMerchantId.isNotEmpty;

  /// Fail-closed guard for production. Hiding the dev "simulate" button is NOT a
  /// security control (the mock RPC is revoked server-side before prod) — this
  /// just stops a misconfigured *release* build from shipping with the dev
  /// affordance enabled or pointing at the Payme sandbox. Asserts (which are
  /// stripped in release) would be useless here, so this throws at startup.
  void assertReleaseSafe() {
    if (!kReleaseMode) return;
    if (mockEnabled) {
      throw StateError('Release build must set PAYMENT_MOCK_ENABLED=false');
    }
    if (checkoutBase.contains('test.paycom.uz')) {
      throw StateError(
        'Release build must set a production PAYME_CHECKOUT_BASE',
      );
    }
  }

  factory PaymentConfig.fromEnv() => const PaymentConfig(
    paymeMerchantId: String.fromEnvironment('PAYME_MERCHANT_ID'),
    checkoutBase: String.fromEnvironment(
      'PAYME_CHECKOUT_BASE',
      defaultValue: 'https://checkout.test.paycom.uz',
    ),
    mockEnabled: bool.fromEnvironment(
      'PAYMENT_MOCK_ENABLED',
      defaultValue: true,
    ),
  );
}
