import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase web config, supplied at build time via --dart-define (kept in the
// gitignored .env, like the Maps key). These are public Firebase identifiers,
// not secrets — security is enforced by RLS / App Check, not by hiding them —
// but we still keep them out of git for consistency.
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _messagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

/// True when the Firebase web config was provided at build time. When false,
/// `Firebase.initializeApp` is skipped and all FCM calls no-op (the app runs
/// normally without push).
bool get firebaseConfigured =>
    _apiKey.isNotEmpty &&
    _appId.isNotEmpty &&
    _messagingSenderId.isNotEmpty &&
    _projectId.isNotEmpty;

/// True when Firebase is actually initialized and usable for FCM on this
/// platform. On web that means the build carried the web config (and
/// `Firebase.initializeApp` ran). On mobile the default app auto-initializes
/// natively from `google-services.json` / `GoogleService-Info.plist`
/// independently of the web config flag, so we check the live app list — this is
/// what gates the "Enable push" UI and every FCM call, so a misconfigured build
/// can't offer push and then fail silently.
bool get firebaseReady =>
    kIsWeb ? firebaseConfigured : Firebase.apps.isNotEmpty;

FirebaseOptions get firebaseOptionsFromEnv => FirebaseOptions(
  apiKey: _apiKey,
  appId: _appId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  authDomain: _authDomain.isEmpty ? null : _authDomain,
  storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
);
