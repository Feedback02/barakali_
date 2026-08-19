import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:barakali/core/utils/app_logger.dart';
import '../domain/models/notification_preferences.dart';
import '../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._client);

  final SupabaseClient _client;

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No authenticated user');
    return uid;
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    final uid = _requireUid();
    final row = await _client
        .from('notification_preferences')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return const NotificationPreferences();
    return NotificationPreferences.fromJson(row);
  }

  @override
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    final uid = _requireUid();
    await _client.from('notification_preferences').upsert({
      'user_id': uid,
      ...prefs.toJson(),
    }, onConflict: 'user_id');
    log.i('Notification preferences updated');
  }

  @override
  Future<void> recordMarketingConsent({
    required bool granted,
    required String documentVersion,
  }) async {
    final uid = _requireUid();
    await _client.from('consent_records').insert({
      'user_id': uid,
      'consent_type': 'marketing_notifications',
      'document_version': documentVersion,
      'granted': granted,
    });
    log.i('Marketing consent recorded (granted=$granted)');
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    final uid = _requireUid();
    // Conflict on the globally-unique token: re-registering the same device
    // (or a device that moved to this account) refreshes ownership + timestamp.
    await _client.from('device_tokens').upsert({
      'user_id': uid,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
    log.i('Device token registered (platform=$platform)');
  }

  @override
  Future<void> deleteDevice(String token) async {
    await _client.from('device_tokens').delete().eq('token', token);
    log.i('Device token deleted');
  }
}
