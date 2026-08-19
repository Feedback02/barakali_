/// Loads the Google Maps SDK at runtime. On web this injects the Maps
/// JavaScript `<script>` using the key from `--dart-define` (so the key stays
/// in the gitignored `.env` and is never committed); on other platforms it is a
/// no-op (the key lives in the native manifests).
library;

export 'maps_loader_stub.dart'
    if (dart.library.js_interop) 'maps_loader_web.dart';
