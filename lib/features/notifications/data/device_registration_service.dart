import 'dart:async';

import 'package:barakali/core/utils/app_logger.dart';
import '../domain/repositories/notification_repository.dart';
import 'fcm_service.dart';

/// Orchestrates the FCM device-token lifecycle: acquire + register on login,
/// re-register on token rotation, delete on logout / account deletion. Driven
/// by the auth state machine (see `AuthStateNotifier`). All operations no-op
/// when Firebase is not configured (the FcmService returns null tokens).
class DeviceRegistrationService {
  DeviceRegistrationService(this._fcm, this._repo);

  final FcmService _fcm;
  final NotificationRepository _repo;

  String? _currentToken;
  StreamSubscription<String>? _refreshSub;
  bool _enabling = false;

  /// Called on sign-in: registers the token ONLY if push permission is already
  /// granted — never prompts (push opt-in is explicit, via [enablePush]). A
  /// not-yet-opted-in device stays silent. Idempotent.
  Future<void> register() async {
    final token = await _fcm.tokenIfPermitted();
    await _registerToken(token);
  }

  /// The explicit push opt-in (the "Enable push" action on the settings screen):
  /// prompts for OS permission, then registers. Returns true if a token was
  /// obtained and stored. Idempotent; ignores overlapping taps while in flight.
  Future<bool> enablePush() async {
    if (_enabling) return false;
    _enabling = true;
    try {
      final token = await _fcm.requestPermissionAndGetToken();
      await _registerToken(token);
      return token != null;
    } finally {
      _enabling = false;
    }
  }

  Future<void> _registerToken(String? token) async {
    if (token == null) return;
    _currentToken = token;
    await _repo.registerDevice(token: token, platform: _fcm.platform);

    await _refreshSub?.cancel();
    _refreshSub = _fcm.onTokenRefresh.listen((rotated) async {
      _currentToken = rotated;
      try {
        await _repo.registerDevice(token: rotated, platform: _fcm.platform);
      } catch (_) {
        log.w('Device token refresh failed (non-fatal)');
      }
    });
  }

  /// Deletes this device's token and stops listening. Called before sign-out /
  /// account deletion so a logged-out device stops receiving pushes.
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = _currentToken ?? await _fcm.currentToken();
    _currentToken = null;
    if (token == null) return;
    await _repo.deleteDevice(token);
  }
}
