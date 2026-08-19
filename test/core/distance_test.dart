import 'package:barakali/core/utils/distance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('haversineKm', () {
    test('is zero for identical points', () {
      expect(haversineKm(41.31, 69.28, 41.31, 69.28), closeTo(0, 0.0001));
    });

    test('matches a known Tashkent intra-city distance', () {
      // Tashkent center (~41.3111, 69.2797) to ~41.35, 69.34 is roughly 6.5 km.
      final d = haversineKm(41.3111, 69.2797, 41.35, 69.34);
      expect(d, closeTo(6.5, 0.6));
    });

    test('is symmetric', () {
      final ab = haversineKm(41.0, 69.0, 41.5, 69.5);
      final ba = haversineKm(41.5, 69.5, 41.0, 69.0);
      expect(ab, closeTo(ba, 0.0001));
    });

    test('grows with separation', () {
      final near = haversineKm(41.31, 69.28, 41.32, 69.29);
      final far = haversineKm(41.31, 69.28, 41.50, 69.50);
      expect(far, greaterThan(near));
    });
  });
}
