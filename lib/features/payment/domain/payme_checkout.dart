import 'dart:convert';

/// Builds the Payme checkout redirect URL for an order.
///
/// Payme's hosted checkout takes a base64-encoded payload of
/// `m=<merchantId>;ac.order_id=<orderId>;a=<amountTiyin>` appended to the
/// checkout host. The `ac.order_id` key must match the kassa "account" field
/// (and the Edge Function's `ACCOUNT_FIELD`). The amount is in **tiyin**
/// (1 soum = 100 tiyin).
///
/// Security: the amount here is only a request hint — the Edge Function
/// recomputes it from the order in `CheckPerformTransaction`/`CreateTransaction`
/// and Payme rejects a mismatch (-31001), so a tampered client amount can never
/// over- or under-charge. The merchant id is public (it identifies the kassa,
/// not a secret).
String buildPaymeCheckoutUrl({
  required String checkoutBase,
  required String merchantId,
  required String orderId,
  required int amountTiyin,
  String? lang,
  String? returnUrl,
}) {
  final parts = <String>[
    'm=$merchantId',
    'ac.order_id=$orderId',
    'a=$amountTiyin',
  ];
  if (lang != null && lang.isNotEmpty) parts.add('l=$lang');
  if (returnUrl != null && returnUrl.isNotEmpty) parts.add('c=$returnUrl');

  final encoded = base64.encode(utf8.encode(parts.join(';')));
  final base = checkoutBase.endsWith('/')
      ? checkoutBase.substring(0, checkoutBase.length - 1)
      : checkoutBase;
  return '$base/$encoded';
}
