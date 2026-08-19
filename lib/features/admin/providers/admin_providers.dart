import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/features/consumer/providers/browse_providers.dart';
import '../data/admin_repository_impl.dart';
import '../domain/admin_errors.dart';
import '../domain/models/admin_merchant.dart';
import '../domain/models/admin_order.dart';
import '../domain/models/platform_metrics.dart';
import '../domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The merchants in one moderation state (one provider instance per queue tab).
/// Refetched after any moderation action via [ref.invalidate].
final adminMerchantsProvider =
    FutureProvider.family<List<AdminMerchant>, MerchantModerationState>((
      ref,
      state,
    ) {
      return ref.read(adminRepositoryProvider).fetchMerchants(state);
    });

/// Live platform metrics for the admin dashboard. Refreshable (focus/pull).
final platformMetricsProvider = FutureProvider<PlatformMetrics>((ref) {
  return ref.read(adminRepositoryProvider).fetchMetrics();
});

/// The current admin order search (query + optional status filter), holding the
/// result list. `build()` (and a null query) returns the most recent orders.
/// Call [search] to re-run with new terms.
final adminOrderSearchProvider =
    AsyncNotifierProvider<AdminOrderSearchController, List<AdminOrder>>(
      AdminOrderSearchController.new,
    );

class AdminOrderSearchController extends AsyncNotifier<List<AdminOrder>> {
  String? _query;
  String? _status;
  // Monotonic request id: a slower in-flight search (e.g. for "a") must not
  // overwrite the result of a newer one (for "ab"). Only the latest wins.
  int _seq = 0;

  @override
  Future<List<AdminOrder>> build() {
    return ref
        .read(adminRepositoryProvider)
        .searchOrders(query: _query, status: _status);
  }

  Future<void> search({String? query, String? status}) async {
    _query = (query != null && query.trim().isEmpty) ? null : query?.trim();
    _status = status;
    final reqId = ++_seq;
    state = const AsyncValue.loading();
    try {
      final orders = await ref
          .read(adminRepositoryProvider)
          .searchOrders(query: _query, status: _status);
      if (reqId != _seq) return; // superseded by a newer search
      state = AsyncValue.data(orders);
    } catch (e, st) {
      if (reqId != _seq) return;
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-run the current search (for pull-to-refresh / post-refund refresh).
  Future<void> refresh() => search(query: _query, status: _status);
}

/// Drives an admin refund (`admin_refund_order`). Returns true on success; on an
/// expected failure the [AdminException] is held in state. Refreshes the search.
final adminRefundProvider = AsyncNotifierProvider<AdminRefundController, void>(
  AdminRefundController.new,
);

class AdminRefundController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> refund({required String orderId, String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(adminRepositoryProvider)
          .refundOrder(orderId: orderId, reason: reason);
      state = const AsyncValue.data(null);
      await ref.read(adminOrderSearchProvider.notifier).refresh();
      log.i('Admin refund (orderId=$orderId)');
      return true;
    } on AdminException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Drives the admin moderation actions (approve / reject / suspend / reinstate).
/// Each returns true on success; on an expected failure the [AdminException] is
/// held in state for the UI to map to a localized message. On success it
/// invalidates every merchant queue (a merchant moves between tabs) and the
/// consumer browse (approval/suspension changes the public listing).
final merchantModerationProvider =
    AsyncNotifierProvider<MerchantModerationController, void>(
      MerchantModerationController.new,
    );

class MerchantModerationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> approve({
    required String merchantId,
    required double latitude,
    required double longitude,
    String? note,
  }) {
    return _run(
      (repo) => repo.approveMerchant(
        merchantId: merchantId,
        latitude: latitude,
        longitude: longitude,
        note: note,
      ),
      'merchant_approved',
      merchantId,
    );
  }

  Future<bool> reject({required String merchantId, required String note}) {
    return _run(
      (repo) => repo.rejectMerchant(merchantId: merchantId, note: note),
      'merchant_rejected',
      merchantId,
    );
  }

  Future<bool> setActive({
    required String merchantId,
    required bool active,
    String? note,
  }) {
    return _run(
      (repo) => repo.setMerchantActive(
        merchantId: merchantId,
        active: active,
        note: note,
      ),
      active ? 'merchant_reinstated' : 'merchant_suspended',
      merchantId,
    );
  }

  Future<bool> setHalal({required String merchantId, required bool isHalal}) {
    return _run(
      (repo) => repo.setMerchantHalal(merchantId: merchantId, isHalal: isHalal),
      isHalal ? 'merchant_halal_set' : 'merchant_halal_unset',
      merchantId,
    );
  }

  Future<bool> _run(
    Future<void> Function(AdminRepository repo) action,
    String event,
    String merchantId,
  ) async {
    state = const AsyncValue.loading();
    try {
      await action(ref.read(adminRepositoryProvider));
      state = const AsyncValue.data(null);
      ref.invalidate(adminMerchantsProvider);
      ref.invalidate(browseOffersProvider);
      log.i('Admin $event (merchantId=$merchantId)');
      return true;
    } on AdminException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// The current platform default fee per bag (integer UZS). Refreshed after an
/// admin edits it via [AdminFeeController.setPlatformFee].
final platformBagFeeProvider = FutureProvider<int>((ref) {
  return ref.read(adminRepositoryProvider).fetchPlatformBagFee();
});

/// Drives the admin fixed-fee edits (the platform default + a per-merchant
/// override). Returns true on success; on an expected failure the
/// [AdminException] is held in state. Invalidates the affected reads.
final adminFeeProvider = AsyncNotifierProvider<AdminFeeController, void>(
  AdminFeeController.new,
);

class AdminFeeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setPlatformFee(int fee) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminRepositoryProvider).setPlatformBagFee(fee);
      state = const AsyncValue.data(null);
      ref.invalidate(platformBagFeeProvider);
      log.i('Admin set platform bag fee ($fee)');
      return true;
    } on AdminException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setMerchantFee({
    required String merchantId,
    required int? fee,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(adminRepositoryProvider)
          .setMerchantFee(merchantId: merchantId, fee: fee);
      state = const AsyncValue.data(null);
      ref.invalidate(adminMerchantsProvider);
      log.i('Admin set merchant fee (merchantId=$merchantId, fee=$fee)');
      return true;
    } on AdminException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
