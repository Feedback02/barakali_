import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:barakali/core/utils/app_logger.dart';

/// The user's coordinates. A plain record so it doesn't couple to any maps SDK.
typedef UserCoords = ({double lat, double lng});

/// Approximate geographic center of Tashkent — the map/browse fallback when the
/// device location is unavailable (MVP launches in Tashkent only).
const tashkentCenter = (lat: 41.3111, lng: 69.2797);

/// The device's current position, or null when unavailable (location services
/// off, permission denied, or any error). Never throws — the browse list falls
/// back to its default (soonest-pickup) order and the map centers on Tashkent
/// when this is null.
final userLocationProvider = FutureProvider<UserCoords?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return null;

    // Do NOT bail on `denied` here. On web, checkPermission/requestPermission
    // can report the pre-decision 'prompt' state as `denied`, so bailing would
    // discard the result before the user even answers (and the FutureProvider
    // caches it). getCurrentPosition triggers the browser prompt and resolves
    // on the user's actual choice — throwing if they truly block, which the
    // catch below turns into a null fallback. This is why granting on the first
    // prompt now updates the app without needing the "Use my location" retry.
    // Speed: WebSettings.maximumAge lets the browser return a recently-cached
    // position instantly instead of forcing a fresh fix on every call — the
    // default (maximumAge:0) is why each load re-acquired and stalled for
    // seconds-to-minutes on a laptop. LocationAccuracy.low keeps
    // enableHighAccuracy:false (fast network/IP location; block-level accuracy
    // is plenty for proximity sorting). geolocator_web's own timeLimit is
    // broken (it feeds microseconds into the JS millisecond timeout), so we cap
    // the wait with a Dart-side .timeout() — on timeout the catch returns null
    // and the "Use my location" chip lets the user retry.
    // WebSettings is web-only; passing it on Android/iOS makes the platform call
    // fail (the whole tuning below — maximumAge caching, broken web timeLimit — is
    // browser-specific). On mobile a fresh low-accuracy fix can be slow indoors, so
    // try the cached last-known position first, then fall back to a current fix.
    if (!kIsWeb) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        log.i('User location resolved');
        return (lat: lastKnown.latitude, lng: lastKnown.longitude);
      }
    }
    final locationSettings = kIsWeb
        ? WebSettings(
            accuracy: LocationAccuracy.low,
            maximumAge: const Duration(minutes: 10),
          )
        : const LocationSettings(accuracy: LocationAccuracy.low);
    final position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    ).timeout(const Duration(seconds: 15));
    log.i('User location resolved');
    return (lat: position.latitude, lng: position.longitude);
  } catch (_) {
    log.w('Location unavailable; using fallback');
    return null;
  }
});
