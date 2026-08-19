import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import 'package:barakali/features/consumer/providers/browse_providers.dart';
import 'package:barakali/features/merchant/providers/merchant_providers.dart';
import '../data/order_repository_impl.dart';
import '../domain/models/order.dart';
import '../domain/models/order_with_details.dart';
import '../domain/order_errors.dart';
import '../domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// The current consumer's orders, newest first (empty when signed out).
final myOrdersProvider =
    AsyncNotifierProvider<MyOrdersNotifier, List<OrderWithDetails>>(
      MyOrdersNotifier.new,
    );

class MyOrdersNotifier extends AsyncNotifier<List<OrderWithDetails>> {
  @override
  Future<List<OrderWithDetails>> build() async {
    final profile = await ref.watch(currentUserProfileProvider.future);
    if (profile == null) return const [];
    final orders = await ref.read(orderRepositoryProvider).fetchMyOrders();
    log.i('My orders loaded (count=${orders.length})');
    return orders;
  }
}

/// A single order by id, for the order detail screen. Re-fetched after pay/
/// cancel via [ref.invalidate].
final orderByIdProvider = FutureProvider.family<OrderWithDetails?, String>((
  ref,
  orderId,
) {
  return ref.read(orderRepositoryProvider).fetchOrderById(orderId);
});

/// The consumer's own pickup code for [orderId] (null if not theirs / not set).
/// Fetched via a consumer-only RPC because the column is unreadable directly.
final pickupCodeProvider = FutureProvider.family<String?, String>((
  ref,
  orderId,
) {
  return ref.read(orderRepositoryProvider).fetchPickupCode(orderId);
});

/// The id of the consumer's existing active (reserved/paid/picked-up) order for
/// [offerId], or null. Lets the offer screen send the user to their order
/// instead of letting them stack a duplicate reservation.
final activeOrderIdForOfferProvider = Provider.family<String?, String>((
  ref,
  offerId,
) {
  final orders = ref.watch(myOrdersProvider).value;
  if (orders == null) return null;
  for (final o in orders) {
    if (o.order.isActive && o.order.offerId == offerId) return o.order.id;
  }
  return null;
});

/// Orders for the current merchant (incoming reservations), newest first.
/// Empty when the user has no merchant record.
final merchantOrdersProvider =
    AsyncNotifierProvider<MerchantOrdersNotifier, List<OrderWithDetails>>(
      MerchantOrdersNotifier.new,
    );

class MerchantOrdersNotifier extends AsyncNotifier<List<OrderWithDetails>> {
  @override
  Future<List<OrderWithDetails>> build() async {
    final merchant = await ref.watch(myMerchantProvider.future);
    if (merchant == null) return const [];
    final orders = await ref
        .read(orderRepositoryProvider)
        .fetchMerchantOrders(merchant.id);
    log.i('Merchant orders loaded (count=${orders.length})');
    return orders;
  }
}

/// Drives merchant pickup verification. [verify] returns the [PickupResult] on
/// success (so the UI can confirm which bag was collected) or null on an
/// expected failure (the [OrderException] is held in state for the UI to map).
final verifyPickupProvider =
    AsyncNotifierProvider<VerifyPickupController, void>(
      VerifyPickupController.new,
    );

class VerifyPickupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PickupResult?> verify(String code) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(orderRepositoryProvider).verifyPickup(code);
      state = const AsyncValue.data(null);
      ref.invalidate(merchantOrdersProvider);
      log.i('Pickup verified (orderId=${result.orderId})');
      return result;
    } on OrderException catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Drives submitting a rating for a completed order. Returns true on success.
final submitRatingProvider =
    AsyncNotifierProvider<SubmitRatingController, void>(
      SubmitRatingController.new,
    );

class SubmitRatingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String orderId,
    required int score,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(orderRepositoryProvider)
          .submitRating(orderId: orderId, score: score, comment: comment);
      state = const AsyncValue.data(null);
      ref.invalidate(orderByIdProvider(orderId));
      ref.invalidate(myOrdersProvider);
      ref.invalidate(browseOffersProvider); // merchant aggregate changed
      log.i('Rating submitted (orderId=$orderId)');
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Drives the Reserve action. [reserve] returns the new [Reservation] on success
/// (so the caller can navigate to it) or null on an expected failure — the error
/// (an [OrderException]) is held in this provider's state for the UI to map.
final reserveControllerProvider =
    AsyncNotifierProvider<ReserveController, void>(ReserveController.new);

class ReserveController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Reservation?> reserve(String offerId) async {
    state = const AsyncValue.loading();
    try {
      final res = await ref.read(orderRepositoryProvider).reserve(offerId);
      state = const AsyncValue.data(null);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(browseOffersProvider); // quantity changed
      log.i('Offer reserved (orderId=${res.orderId})');
      return res;
    } on OrderException catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Drives per-order actions on the order screen (mock pay, cancel). Returns
/// true on success; on failure the [OrderException] is held in state.
final orderActionsProvider =
    AsyncNotifierProvider<OrderActionsController, void>(
      OrderActionsController.new,
    );

class OrderActionsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> pay(String orderId) =>
      _run(orderId, (repo) => repo.confirmPaymentMock(orderId));

  Future<bool> cancel(String orderId, {String? reason}) =>
      _run(orderId, (repo) => repo.cancel(orderId, reason: reason));

  Future<bool> _run(
    String orderId,
    Future<void> Function(OrderRepository repo) action,
  ) async {
    state = const AsyncValue.loading();
    try {
      await action(ref.read(orderRepositoryProvider));
      state = const AsyncValue.data(null);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(orderByIdProvider(orderId));
      ref.invalidate(browseOffersProvider);
      return true;
    } on OrderException catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
