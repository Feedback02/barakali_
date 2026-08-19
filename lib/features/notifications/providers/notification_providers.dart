import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import '../data/device_registration_service.dart';
import '../data/fcm_service.dart';
import '../data/notification_repository_impl.dart';
import '../domain/models/notification_preferences.dart';
import '../domain/repositories/notification_repository.dart';

/// Version of the marketing-consent document the toggle records against. Bump
/// when the marketing terms change (matches the registration consent version).
const marketingConsentDocumentVersion = '1.0';

final fcmServiceProvider = Provider<FcmService>((ref) => const FcmService());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(supabaseClientProvider));
});

final deviceRegistrationProvider = Provider<DeviceRegistrationService>((ref) {
  return DeviceRegistrationService(
    ref.watch(fcmServiceProvider),
    ref.watch(notificationRepositoryProvider),
  );
});

/// The settings screen's source of truth. Loads the caller's preferences and
/// persists toggles optimistically.
final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);

class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() {
    return ref.read(notificationRepositoryProvider).fetchPreferences();
  }

  /// Persists [next], optimistically updating the UI and reverting on failure
  /// (returns false). A change to the marketing flag also writes an explicit
  /// consent record (GDPR Art.7).
  ///
  /// The two writes are not transactional, so ordering keeps the safe failure
  /// mode: enabling marketing records consent BEFORE flipping the flag (so the
  /// flag is never persisted `true` without a consent record), and withdrawing
  /// stops marketing FIRST, then logs the withdrawal best-effort (a failed log
  /// never leaves marketing on). The settings screen serializes calls (it
  /// disables the controls while a write is in flight), so a `false` return
  /// always means a genuine failure — never a dropped concurrent tap.
  Future<bool> setPreferences(NotificationPreferences next) async {
    final previous = state.value ?? const NotificationPreferences();
    final marketingChanged = previous.marketing != next.marketing;
    state = AsyncValue.data(next);
    final repo = ref.read(notificationRepositoryProvider);
    try {
      if (marketingChanged && next.marketing) {
        // Enable: consent first — if the flag write then fails we revert it but
        // keep the (truthful) consent record; marketing is never on without one.
        await repo.recordMarketingConsent(
          granted: true,
          documentVersion: marketingConsentDocumentVersion,
        );
      }
      await repo.updatePreferences(next);
    } catch (e) {
      log.w('Notification preferences update failed; reverting');
      state = AsyncValue.data(previous);
      return false;
    }
    // Pref persisted. Log a withdrawal best-effort — marketing is already off,
    // so a failed log must not revert the (correct) UI.
    if (marketingChanged && !next.marketing) {
      try {
        await repo.recordMarketingConsent(
          granted: false,
          documentVersion: marketingConsentDocumentVersion,
        );
      } catch (_) {
        log.w('Marketing withdrawal consent record failed (marketing is off)');
      }
    }
    return true;
  }
}
