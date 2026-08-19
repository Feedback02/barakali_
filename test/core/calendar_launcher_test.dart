import 'package:barakali/core/utils/calendar_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildCalendarUri', () {
    test('targets the Google Calendar render template', () {
      final uri = buildCalendarUri(
        title: 'Order pickup: Paul Bakery',
        start: DateTime.utc(2026, 6, 30, 9, 5, 0),
        end: DateTime.utc(2026, 6, 30, 11, 0, 0),
      );
      expect(uri.host, 'calendar.google.com');
      expect(uri.path, '/calendar/render');
      expect(uri.queryParameters['action'], 'TEMPLATE');
      expect(uri.queryParameters['text'], 'Order pickup: Paul Bakery');
    });

    test('encodes start/end as a UTC basic-format range', () {
      final uri = buildCalendarUri(
        title: 'x',
        start: DateTime.utc(2026, 6, 30, 9, 5, 0),
        end: DateTime.utc(2026, 6, 30, 11, 0, 0),
      );
      expect(uri.queryParameters['dates'], '20260630T090500Z/20260630T110000Z');
    });

    test('converts a local time to UTC before formatting', () {
      final local = DateTime(2026, 6, 30, 12, 0, 0);
      final uri = buildCalendarUri(title: 'x', start: local, end: local);
      final expected =
          '${local.toUtc().year.toString().padLeft(4, '0')}'
          '${local.toUtc().month.toString().padLeft(2, '0')}'
          '${local.toUtc().day.toString().padLeft(2, '0')}';
      expect(uri.queryParameters['dates'], startsWith(expected));
      expect(uri.queryParameters['dates'], endsWith('Z'));
    });

    test('omits optional details/location when empty', () {
      final uri = buildCalendarUri(
        title: 'x',
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 1),
        details: '',
        location: null,
      );
      expect(uri.queryParameters.containsKey('details'), isFalse);
      expect(uri.queryParameters.containsKey('location'), isFalse);
    });

    test('includes details/location when provided', () {
      final uri = buildCalendarUri(
        title: 'x',
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 1),
        details: 'Surprise non box',
        location: 'Tashkent',
      );
      expect(uri.queryParameters['details'], 'Surprise non box');
      expect(uri.queryParameters['location'], 'Tashkent');
    });
  });
}
