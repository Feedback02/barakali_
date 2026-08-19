import '../models/admin_merchant.dart';
import '../models/admin_order.dart';
import '../models/platform_metrics.dart';

abstract class AdminRepository {
  /// Live platform counters (orders by period, revenue/commission, active
  /// merchants/consumers, bags saved) via the admin-gated
  /// `admin_platform_metrics()` aggregate RPC.
  Future<PlatformMetrics> fetchMetrics();

  /// Search orders by partial id / consumer phone / consumer name / merchant
  /// name (server-side via `admin_search_orders`), optionally filtered by
  /// [status]. A null/empty [query] returns the most recent orders.
  Future<List<AdminOrder>> searchOrders({
    String? query,
    String? status,
    int limit,
  });

  /// Refund a paid order (admin only) via `admin_refund_order` — paid→refunded
  /// + restock + audit_log. Throws [AdminException] on an expected guard
  /// (e.g. not refundable).
  Future<void> refundOrder({required String orderId, String? reason});

  /// All merchants in the given moderation [state], newest first. Reads through
  /// the broad admin SELECT RLS on `merchants` (non-admins get nothing).
  Future<List<AdminMerchant>> fetchMerchants(MerchantModerationState state);

  /// Approve a pending/rejected merchant. Coordinates are required (the consumer
  /// map needs them). Server-side: sets is_approved/approved_at/coords, clears
  /// rejected_at, writes audit_log. Throws [AdminException] on an expected guard.
  Future<void> approveMerchant({
    required String merchantId,
    required double latitude,
    required double longitude,
    String? note,
  });

  /// Reject a pending merchant (stays unapproved, distinguished from never-
  /// reviewed by rejected_at). A note is required. Writes audit_log.
  Future<void> rejectMerchant({
    required String merchantId,
    required String note,
  });

  /// Suspend ([active] = false) or reinstate ([active] = true) an already-
  /// approved merchant. Writes audit_log.
  Future<void> setMerchantActive({
    required String merchantId,
    required bool active,
    String? note,
  });

  /// The current platform default fee per bag (integer UZS), from the admin-only
  /// `platform_config` singleton.
  Future<int> fetchPlatformBagFee();

  /// Set the platform default fee per bag via the admin-gated
  /// `set_platform_bag_fee` RPC (audited).
  Future<void> setPlatformBagFee(int fee);

  /// Set (or clear) a merchant's per-merchant fee override via the admin-gated
  /// `set_merchant_fee` RPC. A null [fee] resets the merchant to the platform
  /// default. Audited.
  Future<void> setMerchantFee({required String merchantId, required int? fee});

  /// Set a merchant's self-declared halal flag via the admin-gated
  /// `set_merchant_halal` RPC (for corrections / existing merchants). Audited.
  Future<void> setMerchantHalal({
    required String merchantId,
    required bool isHalal,
  });
}
