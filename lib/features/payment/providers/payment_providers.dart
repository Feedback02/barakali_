import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_config.dart';

/// The build-time payment configuration. A provider so screens read it through
/// Riverpod (and tests can override it).
final paymentConfigProvider = Provider<PaymentConfig>(
  (ref) => PaymentConfig.fromEnv(),
);
