import '../models/consent_record.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId);
  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  });
  Future<void> updatePreferredLanguage({
    required String userId,
    required String language,
  });
  Future<void> updateDietaryPrefs({
    required String userId,
    required List<String> dietaryPrefs,
  });
  Future<void> saveConsentRecords({
    required String userId,
    required List<ConsentRecord> records,
  });
}
