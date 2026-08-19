import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:barakali/core/models/dietary.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String phone,
    @JsonKey(name: 'display_name') required String displayName,
    required String role,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'preferred_language') required String preferredLanguage,
    @JsonKey(name: 'bags_saved') required int bagsSaved,
    @JsonKey(name: 'dietary_prefs')
    @Default(<String>[])
    List<String> dietaryPrefs,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

extension UserProfileDietary on UserProfile {
  /// The consumer's standing dietary preferences parsed to the shared enum
  /// (unknown values dropped).
  Set<DietaryOption> get dietaryOptions => DietaryOption.parse(dietaryPrefs);
}
