import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/consent_record.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    return null;
  }

  @override
  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    await _client
        .from('profiles')
        .update({'display_name': displayName})
        .eq('id', userId);
  }

  @override
  Future<void> updatePreferredLanguage({
    required String userId,
    required String language,
  }) async {
    await _client
        .from('profiles')
        .update({'preferred_language': language})
        .eq('id', userId);
  }

  @override
  Future<void> updateDietaryPrefs({
    required String userId,
    required List<String> dietaryPrefs,
  }) async {
    await _client
        .from('profiles')
        .update({'dietary_prefs': dietaryPrefs})
        .eq('id', userId);
  }

  @override
  Future<void> saveConsentRecords({
    required String userId,
    required List<ConsentRecord> records,
  }) async {
    final rows = records
        .map((r) => {...r.toJson(), 'user_id': userId})
        .toList();

    await _client.from('consent_records').insert(rows);
  }
}
