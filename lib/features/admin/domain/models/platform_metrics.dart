/// Platform-wide operator counters, returned as one jsonb object by the
/// admin-gated `admin_platform_metrics()` RPC. Read-only; aggregates only (no
/// PII). Money fields are integer UZS.
class PlatformMetrics {
  const PlatformMetrics({
    required this.ordersToday,
    required this.ordersWeek,
    required this.ordersMonth,
    required this.revenueTotal,
    required this.commissionTotal,
    required this.activeMerchants,
    required this.activeConsumers,
    required this.bagsSaved,
  });

  final int ordersToday;
  final int ordersWeek;
  final int ordersMonth;

  /// Money actually collected (orders paid/picked_up/completed), integer UZS.
  final int revenueTotal;

  /// Platform commission earned over the same set, integer UZS.
  final int commissionTotal;

  /// Merchants that are approved AND active (live on the consumer surface).
  final int activeMerchants;

  /// Distinct consumers who transacted in the last 30 days.
  final int activeConsumers;

  /// Successfully picked-up bags (completed orders) — the "saved from waste" count.
  final int bagsSaved;

  factory PlatformMetrics.fromJson(Map<String, dynamic> json) =>
      PlatformMetrics(
        ordersToday: _int(json['orders_today']),
        ordersWeek: _int(json['orders_week']),
        ordersMonth: _int(json['orders_month']),
        revenueTotal: _int(json['revenue_total']),
        commissionTotal: _int(json['commission_total']),
        activeMerchants: _int(json['active_merchants']),
        activeConsumers: _int(json['active_consumers']),
        bagsSaved: _int(json['bags_saved']),
      );

  static int _int(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };
}
