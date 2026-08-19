import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/app/router.dart';
import 'package:barakali/core/firebase/firebase_options_env.dart';
import 'package:barakali/features/auth/domain/models/auth_state.dart';
import 'package:barakali/features/auth/providers/auth_providers.dart';
import '../data/fcm_service.dart';

/// Routes a notification TAP to the relevant screen. A tap delivers the FCM
/// `data` map ({type, offer_id?/order_id?}); without this the app just opens at
/// Home. Three tap sources are wired: background tray tap (onMessageOpenedApp),
/// cold-start tray tap (getInitialMessage), and a foreground in-app tap
/// ([localNotificationTaps]).
///
/// Navigation waits until the user is authenticated — a cold-start tap fires
/// before the persisted session is restored, and pushing earlier would be eaten
/// by the auth redirect. Activate by `ref.watch`-ing it once at the app root.
final notificationTapProvider = Provider<void>((ref) {
  if (!firebaseReady) return;

  // The getInitialMessage() future isn't cancellable; guard its late callback
  // so it can't touch a disposed Ref if the activation point ever changes (today
  // this is watched for the whole app lifetime, so it effectively never fires).
  var disposed = false;
  String? pending;

  void flush() {
    final path = pending;
    if (path == null) return;
    if (ref.read(authStateProvider).value != AppAuthState.authenticated) return;
    pending = null;
    ref.read(routerProvider).push(path);
  }

  void onTap(Map<String, dynamic> data) {
    if (disposed) return;
    final path = routeForNotificationData(data);
    if (path == null) return;
    pending = path;
    flush();
  }

  // Cold start: app was terminated, opened by tapping the notification.
  FirebaseMessaging.instance.getInitialMessage().then((m) {
    if (m != null) onTap(m.data);
  });
  // Backgrounded: tapped while the app was alive in the background.
  final opened = FirebaseMessaging.onMessageOpenedApp.listen(
    (m) => onTap(m.data),
  );
  // Foreground: tapped the in-app local notification.
  final local = localNotificationTaps.listen(onTap);
  // A pending cold-start route navigates as soon as auth resolves.
  ref.listen(authStateProvider, (_, _) => flush());

  ref.onDispose(() {
    disposed = true;
    opened.cancel();
    local.cancel();
  });
});

/// Maps FCM notification data to an in-app route, or null if not routable.
/// Prefers an order (most specific) then an offer.
String? routeForNotificationData(Map<String, dynamic> data) {
  final orderId = data['order_id'];
  if (orderId is String && orderId.isNotEmpty) return '/order/$orderId';
  final offerId = data['offer_id'];
  if (offerId is String && offerId.isNotEmpty) return '/offer/$offerId';
  return null;
}
