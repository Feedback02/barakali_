import 'package:barakali/core/models/dietary.dart';
import 'package:barakali/features/auth/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> row() => {
    'id': 'u-1',
    'phone': '+998900000001',
    'display_name': 'Aziz',
    'role': 'consumer',
    'avatar_url': null,
    'preferred_language': 'ru',
    'bags_saved': 4,
    'dietary_prefs': ['halal', 'vegan'],
    'created_at': '2026-06-10T09:00:00Z',
    'updated_at': '2026-06-10T09:00:00Z',
  };

  group('UserProfile dietary preferences', () {
    test('parses dietary_prefs and exposes them as the shared enum', () {
      final p = UserProfile.fromJson(row());
      expect(p.dietaryPrefs, ['halal', 'vegan']);
      expect(p.dietaryOptions, {DietaryOption.halal, DietaryOption.vegan});
    });

    test('defaults to empty when dietary_prefs is absent', () {
      final r = row()..remove('dietary_prefs');
      final p = UserProfile.fromJson(r);
      expect(p.dietaryPrefs, isEmpty);
      expect(p.dietaryOptions, isEmpty);
    });
  });
}
