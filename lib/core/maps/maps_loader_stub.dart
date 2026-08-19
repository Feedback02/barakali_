/// Non-web no-op: the Maps API key is supplied via the native manifests
/// (Android `AndroidManifest.xml`, iOS `AppDelegate`), not at runtime.
Future<void> loadGoogleMaps(String apiKey) async {}
