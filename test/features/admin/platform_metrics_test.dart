import 'package:barakali/features/admin/domain/models/platform_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlatformMetrics.fromJson maps the admin_platform_metrics jsonb', () {
    final m = PlatformMetrics.fromJson({
      'orders_today': 5,
      'orders_week': 9,
      'orders_month': 9,
      'revenue_total': 107000,
      'commission_total': 26750,
      'active_merchants': 7,
      'active_consumers': 2,
      'bags_saved': 3,
    });
    expect(m.ordersToday, 5);
    expect(m.ordersWeek, 9);
    expect(m.ordersMonth, 9);
    expect(m.revenueTotal, 107000);
    expect(m.commissionTotal, 26750);
    expect(m.activeMerchants, 7);
    expect(m.activeConsumers, 2);
    expect(m.bagsSaved, 3);
  });

  test('coerces numeric/string/missing values to int', () {
    final m = PlatformMetrics.fromJson({
      'orders_today': '4', // string
      'revenue_total': 100000.0, // num
      // everything else missing -> 0
    });
    expect(m.ordersToday, 4);
    expect(m.revenueTotal, 100000);
    expect(m.ordersWeek, 0);
    expect(m.bagsSaved, 0);
  });
}
