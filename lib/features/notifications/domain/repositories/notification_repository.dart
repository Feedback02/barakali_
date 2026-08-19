import '../models/notification_preferences.dart';

abstract class NotificationRepository {
  /// The caller's notification preferences. Returns defaults if no row exists
  /// (RLS `notif_prefs_select_own`).
  Future<NotificationPreferences> fetchPreferences();

  /// Upserts the caller's preferences (conflict on `user_id`). `user_id` is set
  /// to the caller — RLS forbids writing anyone else's row.
  Future<void> updatePreferences(NotificationPreferences prefs);

  /// Records an explicit marketing-consent event (GDPR Art.7) in the append-only
  /// `consent_records` table. Called whenever the marketing toggle changes —
  /// `granted` is the new value (a withdrawal is logged as `granted=false`).
  Future<void> recordMarketingConsent({
    required bool granted,
    required String documentVersion,
  });

  /// Upserts an FCM registration token for the caller (conflict on the unique
  /// `token`). `platform` is one of ios|android|web.
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  /// Removes a device token (on logout / account deletion).
  Future<void> deleteDevice(String token);
}
