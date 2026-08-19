import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/firebase/firebase_options_env.dart';
import 'core/maps/maps_loader.dart';
import 'core/utils/app_logger.dart';
import 'features/notifications/data/fcm_service.dart';
import 'features/payment/domain/payment_config.dart';

/// Background/terminated-state FCM handler. Runs in its own isolate without the
/// app's providers, so it must stay self-contained. Notification-payload
/// messages (all we send today) are displayed by the OS on the channel from the
/// manifest's default_notification_channel_id, so there is nothing to do here —
/// this exists so FCM has a registered entry point and a hook for future
/// data-only messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      );
    }, appRunner: () async => _initAndRun());
  } else {
    log.w('Sentry DSN not provided');
    await _initAndRun();
  }
}

Future<void> _initAndRun() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only: the app is designed for portrait (like Too Good To Go).
  // Landscape squeezes the fixed headers/columns on Home and other screens and
  // overflows the short viewport. No-op on web (desktop windows stay wide).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Fail closed: a release build must disable the payment mock and use the
  // production Payme host (throws at startup otherwise).
  PaymentConfig.fromEnv().assertReleaseSafe();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
    log.i('Supabase initialized');
  } else {
    log.w('Supabase credentials not provided');
  }

  // Web: inject the Google Maps JS SDK from the --dart-define key (no-op on
  // mobile, where the key lives in the native manifests).
  const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  await loadGoogleMaps(mapsKey);

  // FCM: wire foreground display once Firebase is initialized. On web we must
  // initialize from the --dart-define config; on mobile the default app is already
  // auto-initialized natively (google-services.json / GoogleService-Info.plist)
  // before Dart runs, so re-calling initializeApp with the web options throws
  // "[DEFAULT] already exists" and skips FCM setup. Non-fatal so the app runs
  // without push if anything is misconfigured.
  try {
    if (kIsWeb) {
      if (firebaseConfigured) {
        await Firebase.initializeApp(options: firebaseOptionsFromEnv);
        await initFcmForegroundDisplay();
        log.i('Firebase initialized');
      }
    } else {
      // Mobile: the native default app is auto-initialized from
      // google-services.json, but the Dart side still needs initializeApp() to
      // populate `Firebase.apps` (so `firebaseReady` is true and the FCM
      // foreground display, background handler, and notification-tap listeners
      // actually wire up). Call it with NO options — passing `options:` for the
      // already-existing [DEFAULT] app throws "[DEFAULT] already exists".
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      await initFcmForegroundDisplay();
      log.i('Firebase initialized');
    }
  } catch (_) {
    log.w('Firebase init failed (non-fatal)');
  }

  runApp(const ProviderScope(child: BarakaliApp()));
}
