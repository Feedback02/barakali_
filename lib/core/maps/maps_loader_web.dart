import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Cap on how long [loadGoogleMaps] waits for a `<script>` to load before
/// proceeding anyway, so a blocked/failed load never hangs app startup.
const _scriptLoadTimeout = Duration(seconds: 10);

/// The marker-clustering JS library the web Maps plugin binds to (the global
/// `markerClusterer.MarkerClusterer`). `google_maps_flutter_web` constructs it
/// the moment a `ClusterManager` is registered, so it must be present before the
/// map mounts or clustering throws. Pinned to the plugin's supported version.
const _clustererSrc =
    'https://cdn.jsdelivr.net/npm/@googlemaps/markerclusterer@2.5.3/dist/index.umd.min.js';

/// Injects the Google Maps JS SDK `<script>` at runtime using [apiKey] from
/// `--dart-define`, so the key stays in the (gitignored) `.env` and is never
/// committed to source. Also loads the marker-clustering library the map relies
/// on. No-op if the key is empty or the scripts are already present. Resolves
/// when the scripts have loaded (or a short timeout elapses, so a load failure
/// never blocks app startup — the map simply won't render).
Future<void> loadGoogleMaps(String apiKey) async {
  if (apiKey.isEmpty) return;
  await Future.wait([
    _injectScript(
      src: 'https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async',
      marker: 'data-barakali-maps',
    ),
    _injectScript(src: _clustererSrc, marker: 'data-barakali-clusterer'),
  ]);
}

/// Appends a `<script>` with a [marker] attribute (so it's injected at most
/// once) and resolves when it loads, errors, or times out.
Future<void> _injectScript({
  required String src,
  required String marker,
}) async {
  if (web.document.querySelector('script[$marker]') != null) return;

  final completer = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script
    ..src = src
    ..async = true
    ..defer = true
    ..setAttribute(marker, 'true');

  void done(web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }

  script.addEventListener('load', done.toJS);
  script.addEventListener('error', done.toJS);
  web.document.head!.appendChild(script);

  return completer.future.timeout(_scriptLoadTimeout, onTimeout: () {});
}
