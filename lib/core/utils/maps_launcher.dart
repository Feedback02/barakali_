import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

/// Opens the device map app at a location: precise coordinates when known,
/// otherwise a text search on the address. Best-effort, a failure is logged and
/// never surfaced (directions are a convenience, not a critical path).
Future<void> openDirections({
  double? latitude,
  double? longitude,
  required String address,
}) async {
  final hasCoords = latitude != null && longitude != null;
  final query = hasCoords ? '$latitude,$longitude' : address;
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) log.w('Could not open maps for directions');
  } catch (_) {
    // launchUrl can throw (no handler / PlatformException); directions are a
    // convenience, never surface it.
    log.w('Could not open maps for directions');
  }
}
