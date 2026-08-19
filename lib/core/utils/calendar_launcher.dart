import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

/// Builds the Google Calendar web "render" template URL for an event. Times are
/// emitted in UTC basic format (`YYYYMMDDTHHMMSSZ`) so the calendar localizes
/// them to the device zone. Pure + exported so it can be unit-tested.
Uri buildCalendarUri({
  required String title,
  required DateTime start,
  required DateTime end,
  String? details,
  String? location,
}) {
  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': title,
    'dates': '${_formatUtc(start)}/${_formatUtc(end)}',
    if (details != null && details.isNotEmpty) 'details': details,
    if (location != null && location.isNotEmpty) 'location': location,
  });
}

/// Adds an event to the user's calendar by opening Google Calendar's render
/// template in the browser / Calendar app. No extra dependency: it reuses
/// `url_launcher` and works on web + Android (and any browser). Best-effort: a
/// launch failure is logged, not surfaced (adding a reminder is a convenience,
/// not a critical path).
Future<void> addToCalendar({
  required String title,
  required DateTime start,
  required DateTime end,
  String? details,
  String? location,
}) async {
  final uri = buildCalendarUri(
    title: title,
    start: start,
    end: end,
    details: details,
    location: location,
  );
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) log.w('Could not open calendar');
  } catch (_) {
    // launchUrl can throw (no handler / PlatformException); adding a reminder is
    // a convenience, never surface it.
    log.w('Could not open calendar');
  }
}

String _formatUtc(DateTime dt) {
  final u = dt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}'
      'T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
}
