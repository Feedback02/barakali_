import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/order_with_details.dart';
import '../domain/order_errors.dart';
import '../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._client);

  final SupabaseClient _client;

  // The order columns the client needs, plus its offer (all columns, for the
  // full Offer model) and a public merchant summary. The embedded reads are
  // allowed for the order's own consumer even after the offer goes
  // sold_out/expired or the merchant deactivates, via the `*_select_order_party`
  // RLS policies.
  //
  // `pickup_code` is deliberately NOT selected: SELECT on that column is revoked
  // from the client roles, so a merchant can't read a customer's code off the
  // wire (single-presentation pickup). The consumer reads their own code via
  // [fetchPickupCode]; reserve_offer returns it at creation.
  //
  // `commission_amount` (the platform fee) is fetched ONLY on the merchant read
  // (it feeds the merchant net-payout display); the consumer read omits it so
  // the fee never ships to the consumer client. The Order model defaults it to
  // 0 when absent.
  static const _consumerSelect =
      'id, consumer_id, offer_id, merchant_id, status, payment_provider, '
      'amount_paid, reserved_at, paid_at, picked_up_at, '
      'cancelled_at, created_at, '
      'offer:offers(*), '
      'merchant:merchants(business_name, rating, total_ratings, category, '
      'address, latitude, longitude, logo_url), '
      'rating:ratings(score, comment)';

  static const _merchantSelect =
      'id, consumer_id, offer_id, merchant_id, status, payment_provider, '
      'amount_paid, commission_amount, reserved_at, paid_at, picked_up_at, '
      'cancelled_at, created_at, '
      'offer:offers(*), '
      'merchant:merchants(business_name, rating, total_ratings, category, '
      'address, latitude, longitude, logo_url), '
      'rating:ratings(score, comment)';

  @override
  Future<Reservation> reserve(String offerId) async {
    try {
      final res = await _client.rpc(
        'reserve_offer',
        params: {'p_offer_id': offerId},
      );
      final row = (res as List<dynamic>).first as Map<String, dynamic>;
      return (
        orderId: row['id'] as String,
        pickupCode: (row['pickup_code'] as String).trim(),
      );
    } on PostgrestException catch (e) {
      throw OrderException(parseOrderError(e.message));
    }
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    try {
      await _client.rpc(
        'cancel_order',
        params: {'p_order_id': orderId, 'p_reason': ?reason},
      );
    } on PostgrestException catch (e) {
      throw OrderException(parseOrderError(e.message));
    }
  }

  @override
  Future<void> confirmPaymentMock(String orderId) async {
    try {
      await _client.rpc('confirm_payment', params: {'p_order_id': orderId});
    } on PostgrestException catch (e) {
      throw OrderException(parseOrderError(e.message));
    }
  }

  @override
  Future<List<OrderWithDetails>> fetchMyOrders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await _client
        .from('orders')
        .select(_consumerSelect)
        .eq('consumer_id', uid)
        .order('created_at', ascending: false);
    return rows.map(OrderWithDetails.fromSupabase).toList();
  }

  @override
  Future<OrderWithDetails?> fetchOrderById(String orderId) async {
    final row = await _client
        .from('orders')
        .select(_consumerSelect)
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : OrderWithDetails.fromSupabase(row);
  }

  @override
  Future<List<OrderWithDetails>> fetchMerchantOrders(String merchantId) async {
    final rows = await _client
        .from('orders')
        .select(_merchantSelect)
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);
    return rows.map(OrderWithDetails.fromSupabase).toList();
  }

  @override
  Future<String?> fetchPickupCode(String orderId) async {
    // Server-side: returns the code only to the order's own consumer (NULL
    // otherwise). The column itself is unreadable via a direct table select.
    final res = await _client.rpc(
      'get_order_pickup_code',
      params: {'p_order_id': orderId},
    );
    final code = (res as String?)?.trim();
    return (code == null || code.isEmpty) ? null : code;
  }

  @override
  Future<PickupResult> verifyPickup(String code) async {
    try {
      final res = await _client.rpc('verify_pickup', params: {'p_code': code});
      final row = (res as List<dynamic>).first as Map<String, dynamic>;
      return (
        orderId: row['order_id'] as String,
        offerTitle: row['offer_title'] as String,
      );
    } on PostgrestException catch (e) {
      throw OrderException(parseOrderError(e.message));
    }
  }

  @override
  Future<void> submitRating({
    required String orderId,
    required int score,
    String? comment,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const OrderException(OrderErrorCode.notAuthenticated);
    }
    // merchant_id is server-derived (set_rating_merchant trigger); don't send it.
    await _client.from('ratings').insert({
      'order_id': orderId,
      'consumer_id': uid,
      'score': score,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }
}
