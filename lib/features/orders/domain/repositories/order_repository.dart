import '../models/order_with_details.dart';

/// The result of a successful reservation: the new order id and its single-use
/// pickup code.
typedef Reservation = ({String orderId, String pickupCode});

/// The result of a successful pickup verification.
typedef PickupResult = ({String orderId, String offerTitle});

/// Order operations. All state-changing methods go through server-side RPCs
/// (the client never writes order rows directly); expected failures surface as
/// [OrderException] with a typed code.
abstract class OrderRepository {
  /// Atomically reserves one bag of [offerId] (server locks quantity, computes
  /// the amount, and creates the order). Throws [OrderException] on sold-out /
  /// unavailable / too-many-reservations.
  Future<Reservation> reserve(String offerId);

  /// Cancels the consumer's own order (reserved, or paid within the free-cancel
  /// window) and restores the offer quantity.
  Future<void> cancel(String orderId, {String? reason});

  /// Dev/sandbox mock: marks a reserved order paid. The real transition is
  /// driven server-side by the payment provider webhook.
  Future<void> confirmPaymentMock(String orderId);

  /// The current consumer's orders, newest first.
  Future<List<OrderWithDetails>> fetchMyOrders();

  /// A single order with its offer + merchant, or null if not visible.
  Future<OrderWithDetails?> fetchOrderById(String orderId);

  /// The order's single-use pickup code, returned only to the order's own
  /// consumer (null otherwise). The column is unreadable via a direct table
  /// select, so a merchant can never read a customer's code off the wire.
  Future<String?> fetchPickupCode(String orderId);

  /// Orders for the given merchant (incoming reservations), newest first.
  Future<List<OrderWithDetails>> fetchMerchantOrders(String merchantId);

  /// Verifies a pickup by the code the consumer presents (manual entry or QR).
  /// Server-side: owning-merchant only, single-use, within the pickup window +
  /// 30 min; transitions the order to completed. Throws [OrderException].
  Future<PickupResult> verifyPickup(String code);

  /// Rates a completed order (one per order). The merchant is server-derived
  /// from the order; the consumer only sends order/score/comment.
  Future<void> submitRating({
    required String orderId,
    required int score,
    String? comment,
  });
}
