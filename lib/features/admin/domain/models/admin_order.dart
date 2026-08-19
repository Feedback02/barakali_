import 'package:barakali/features/orders/domain/models/order.dart';

/// An order as the admin console sees it — the order row enriched (server-side,
/// via `admin_search_orders`) with the consumer's phone/name, the merchant name,
/// and the offer title. Consumer/merchant/offer fields are nullable: the FKs are
/// `ON DELETE SET NULL`, so an erased consumer's order still lists (with null
/// name/phone). Read-only projection; the only write is a refund via
/// `admin_refund_order`. `pickup_code` is intentionally NOT exposed to admins.
class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.status,
    required this.amountPaid,
    required this.commissionAmount,
    required this.reservedAt,
    this.paidAt,
    this.pickedUpAt,
    this.cancelledAt,
    this.cancellationReason,
    this.paymentProvider,
    this.consumerId,
    this.consumerPhone,
    this.consumerName,
    this.merchantId,
    this.merchantName,
    this.offerId,
    this.offerTitle,
  });

  final String id;
  final OrderStatus status;
  final int amountPaid;
  final int commissionAmount;
  final DateTime reservedAt;
  final DateTime? paidAt;
  final DateTime? pickedUpAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? paymentProvider;
  final String? consumerId;
  final String? consumerPhone;
  final String? consumerName;
  final String? merchantId;
  final String? merchantName;
  final String? offerId;
  final String? offerTitle;

  /// Only a `paid` order can be refunded (matches `admin_refund_order`'s guard).
  bool get isRefundable => status == OrderStatus.paid;

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
    id: json['id'] as String,
    status: _statusFromWire(json['status'] as String),
    amountPaid: (json['amount_paid'] as int?) ?? 0,
    commissionAmount: (json['commission_amount'] as int?) ?? 0,
    reservedAt: DateTime.parse(json['reserved_at'] as String),
    paidAt: _ts(json['paid_at']),
    pickedUpAt: _ts(json['picked_up_at']),
    cancelledAt: _ts(json['cancelled_at']),
    cancellationReason: json['cancellation_reason'] as String?,
    paymentProvider: json['payment_provider'] as String?,
    consumerId: json['consumer_id'] as String?,
    consumerPhone: json['consumer_phone'] as String?,
    consumerName: json['consumer_name'] as String?,
    merchantId: json['merchant_id'] as String?,
    merchantName: json['merchant_name'] as String?,
    offerId: json['offer_id'] as String?,
    offerTitle: json['offer_title'] as String?,
  );

  static DateTime? _ts(Object? v) =>
      v == null ? null : DateTime.parse(v as String);

  static OrderStatus _statusFromWire(String s) => OrderStatus.values.firstWhere(
    (e) => e.value == s,
    orElse: () => OrderStatus.reserved,
  );
}
