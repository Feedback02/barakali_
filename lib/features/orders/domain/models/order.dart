import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// A consumer's reservation/transaction for an offer. Prices are integer UZS;
/// mirrors the `public.orders` table. Order state is server-owned — it only
/// changes through the reservation/payment/pickup RPCs, never a direct write.
@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'consumer_id') String? consumerId,
    @JsonKey(name: 'offer_id') String? offerId,
    @JsonKey(name: 'merchant_id') String? merchantId,
    required OrderStatus status,
    // Null on fetched rows: SELECT on orders.pickup_code is revoked from the
    // client roles so a merchant can't read it off the wire (it would defeat
    // single-presentation pickup). The consumer fetches their own code via the
    // get_order_pickup_code RPC; reserve_offer also returns it at creation.
    @JsonKey(name: 'pickup_code') String? pickupCode,
    @JsonKey(name: 'payment_provider') String? paymentProvider,
    @JsonKey(name: 'amount_paid') required int amountPaid,
    // The platform fee is fetched only on merchant/admin order reads (it feeds
    // the merchant net-payout display); consumer reads omit the column so the
    // fee never ships to the consumer client. Defaults to 0 when absent.
    @JsonKey(name: 'commission_amount') @Default(0) int commissionAmount,
    @JsonKey(name: 'reserved_at') required DateTime reservedAt,
    @JsonKey(name: 'paid_at') DateTime? paidAt,
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

extension OrderLifecycle on Order {
  /// In-progress orders (awaiting payment or pickup) vs. terminal ones
  /// (completed/cancelled/refunded/expired). Drives the active/past split in
  /// the Orders list.
  bool get isActive =>
      status == OrderStatus.reserved ||
      status == OrderStatus.paid ||
      status == OrderStatus.pickedUp;

  /// What the merchant actually receives: the bag price minus the platform
  /// fee. `commissionAmount` is the fixed per-bag fee (server-computed in
  /// reserve_offer, clamped to never exceed amount_paid), so this is always
  /// >= 0. Merchant-facing only; consumers never see the fee.
  int get netPayout => amountPaid - commissionAmount;
}

/// Order lifecycle states (matches the DB CHECK constraint + transition guard).
enum OrderStatus {
  @JsonValue('reserved')
  reserved,
  @JsonValue('paid')
  paid,
  @JsonValue('picked_up')
  pickedUp,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
  @JsonValue('expired')
  expired;

  /// The wire value stored in the DB (snake_case for `picked_up`).
  String get value => switch (this) {
    OrderStatus.pickedUp => 'picked_up',
    _ => name,
  };
}
