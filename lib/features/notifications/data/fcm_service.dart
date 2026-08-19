import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/core/firebase/firebase_options_env.dart';

const _vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

/// Thin wrapper over `FirebaseMessaging`. Isolates the plugin so the rest of the
/// app depends only on this small surface. Permission is requested ONLY via
/// [requestPermissionAndGetToken] (the explicit opt-in on the settings screen);
/// login uses [tokenIfPermitted], which never prompts.
class FcmService {
  const FcmService();

  /// The `device_tokens.platform` value for the current device.
  String get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  /// FCM is usable only when Firebase is actually initialized for this platform
  /// (web config on web; native default app on mobile); otherwise every call
  /// no-ops so the app runs without push.
  bool get _ready => firebaseReady;

  /// Returns the FCM token only if notification permission is ALREADY granted —
  /// never prompts. Used on sign-in so a returning, opted-in device re-registers
  /// without nagging, and a not-yet-opted-in device stays silent.
  Future<String?> tokenIfPermitted() async {
    if (!_ready) return null;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (!_granted(settings.authorizationStatus)) return null;
      return _getToken();
    } catch (_) {
      log.w('FCM tokenIfPermitted failed (non-fatal)');
      return null;
    }
  }

  /// Prompts for OS notification permission (the explicit opt-in) and returns the
  /// token, or null if denied / unavailable.
  Future<String?> requestPermissionAndGetToken() async {
    if (!_ready) return null;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (!_granted(settings.authorizationStatus)) return null;
      return _getToken();
    } catch (_) {
      log.w('FCM requestPermission/getToken failed (non-fatal)');
      return null;
    }
  }

  /// The current token without prompting (used on logout to know what to delete).
  Future<String?> currentToken() async {
    if (!_ready) return null;
    try {
      return _getToken();
    } catch (_) {
      return null;
    }
  }

  Stream<String> get onTokenRefresh =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  bool _granted(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;

  // getToken can hang indefinitely on web when service-worker push registration
  // can't complete (e.g. incognito/InPrivate, where Chromium disables the Push
  // API — the failure doesn't reject the future). Time it out so the UI never
  // sticks; a null result surfaces as "couldn't enable" rather than a frozen
  // control.
  Future<String?> _getToken() => FirebaseMessaging.instance
      .getToken(
        vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
        serviceWorkerScriptPath: kIsWeb ? _serviceWorkerPath() : null,
      )
      .timeout(const Duration(seconds: 20), onTimeout: () => null);

  /// The web service worker is registered with the (public) Firebase web config
  /// in its query string, so the committed `firebase-messaging-sw.js` carries no
  /// project config — it reads `self.location.search` instead.
  static String _serviceWorkerPath() {
    final query = Uri(
      queryParameters: {
        'apiKey': const String.fromEnvironment('FIREBASE_API_KEY'),
        'appId': const String.fromEnvironment('FIREBASE_APP_ID'),
        'messagingSenderId': const String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
        ),
        'projectId': const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      },
    ).query;
    return 'firebase-messaging-sw.js?$query';
  }
}

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Taps on a FOREGROUND local notification (the ones shown via [_localNotifications]
/// while the app is open). Payload is the FCM `data` map; the routing provider
/// listens here so an in-app notification tap deep-links like a tray tap does.
/// (Background/terminated tray taps come straight from FirebaseMessaging's
/// onMessageOpenedApp / getInitialMessage instead.)
///
/// Process-lifetime broadcast controller — intentionally never closed.
final _localTapController = StreamController<Map<String, dynamic>>.broadcast();
Stream<Map<String, dynamic>> get localNotificationTaps =>
    _localTapController.stream;

void _onLocalNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      _localTapController.add(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {
    // Malformed payload — ignore rather than crash the tap.
  }
}

/// Monotonic, 32-bit-bounded id for foreground local notifications (a raw
/// `hashCode` can collide or exceed the platform's 32-bit id range).
int _foregroundNotifId = 0;

/// The single Android notification channel. Android 8+ (every current device)
/// drops any notification without a channel, so this MUST exist for both
/// foreground local display AND backgrounded FCM display — the manifest's
/// `default_notification_channel_id` meta-data and the server's
/// `android.notification.channel_id` both point at this same id.
const _androidChannelId = 'barakali_default';
const _androidChannel = AndroidNotificationChannel(
  _androidChannelId,
  'Notifications',
  description: 'Order, pickup and offer notifications',
  importance: Importance.high,
);
const _foregroundDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _androidChannelId,
    'Notifications',
    channelDescription: 'Order, pickup and offer notifications',
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
);

/// Wires foreground display: when a push arrives while the app is open, FCM does
/// NOT show it automatically, so we render it via a local notification. Called
/// once at startup after `Firebase.initializeApp`. No-ops / best-effort — a
/// failure here must never break startup. (Background/closed delivery on web is
/// handled by the service worker.)
Future<void> initFcmForegroundDisplay() async {
  if (!firebaseReady) return;
  try {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    // Android 8+ requires the channel to exist before any notification shows.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      // Web keeps its existing (channel-less) behaviour; mobile attaches the
      // channel/details so Android 8+ actually displays the heads-up.
      _localNotifications.show(
        id: (_foregroundNotifId++) & 0x7fffffff,
        title: n.title,
        body: n.body,
        notificationDetails: kIsWeb ? null : _foregroundDetails,
        // Carry the routing data so a tap on this in-app notification deep-links.
        payload: message.data.isEmpty ? null : jsonEncode(message.data),
      );
    });
  } catch (_) {
    log.w('FCM foreground display init failed (non-fatal)');
  }
}
