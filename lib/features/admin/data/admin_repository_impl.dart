import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_errors.dart';
import '../domain/models/admin_merchant.dart';
import '../domain/models/admin_order.dart';
import '../domain/models/platform_metrics.dart';
import '../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AdminMerchant>> fetchMerchants(
    MerchantModerationState state,
  ) async {
    // Each moderation state maps to a deterministic predicate over the
    // server-owned flags — mirrors AdminMerchant.state on the client and the
    // idx_merchants_pending partial index server-side.
    var query = _client.from('merchants').select();
    query = switch (state) {
      MerchantModerationState.pending =>
        query.eq('is_approved', false).isFilter('rejected_at', null),
      MerchantModerationState.rejected =>
        query.eq('is_approved', false).not('rejected_at', 'is', null),
      MerchantModerationState.approved =>
        query.eq('is_approved', true).eq('is_active', true),
      MerchantModerationState.suspended =>
        query.eq('is_approved', true).eq('is_active', false),
    };
    try {
      final rows = await query.order('created_at', ascending: false);
      return rows.map(AdminMerchant.fromJson).toList();
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<PlatformMetrics> fetchMetrics() async {
    try {
      final res = await _client.rpc('admin_platform_metrics');
      return PlatformMetrics.fromJson(res as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<List<AdminOrder>> searchOrders({
    String? query,
    String? status,
    int limit = 50,
  }) async {
    try {
      final res = await _client.rpc(
        'admin_search_orders',
        params: {'p_query': ?query, 'p_status': ?status, 'p_limit': limit},
      );
      return (res as List<dynamic>)
          .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> refundOrder({required String orderId, String? reason}) async {
    try {
      await _client.rpc(
        'admin_refund_order',
        params: {'p_order_id': orderId, 'p_reason': ?reason},
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> approveMerchant({
    required String merchantId,
    required double latitude,
    required double longitude,
    String? note,
  }) async {
    try {
      await _client.rpc(
        'approve_merchant',
        params: {
          'p_merchant_id': merchantId,
          'p_lat': latitude,
          'p_lng': longitude,
          'p_note': ?note,
        },
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> rejectMerchant({
    required String merchantId,
    required String note,
  }) async {
    try {
      await _client.rpc(
        'reject_merchant',
        params: {'p_merchant_id': merchantId, 'p_note': note},
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> setMerchantActive({
    required String merchantId,
    required bool active,
    String? note,
  }) async {
    try {
      await _client.rpc(
        'set_merchant_active',
        params: {
          'p_merchant_id': merchantId,
          'p_active': active,
          'p_note': ?note,
        },
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<int> fetchPlatformBagFee() async {
    try {
      final row = await _client
          .from('platform_config')
          .select('bag_fee')
          .eq('id', 1)
          .single();
      return (row['bag_fee'] as num).toInt();
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> setPlatformBagFee(int fee) async {
    try {
      await _client.rpc('set_platform_bag_fee', params: {'p_fee': fee});
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> setMerchantFee({
    required String merchantId,
    required int? fee,
  }) async {
    try {
      // p_fee is explicitly nullable: null resets the merchant to the platform
      // default, so send the null through rather than dropping the key.
      await _client.rpc(
        'set_merchant_fee',
        params: {'p_merchant_id': merchantId, 'p_fee': fee},
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }

  @override
  Future<void> setMerchantHalal({
    required String merchantId,
    required bool isHalal,
  }) async {
    try {
      await _client.rpc(
        'set_merchant_halal',
        params: {'p_merchant_id': merchantId, 'p_is_halal': isHalal},
      );
    } on PostgrestException catch (e) {
      throw AdminException(parseAdminError(e.message));
    }
  }
}
