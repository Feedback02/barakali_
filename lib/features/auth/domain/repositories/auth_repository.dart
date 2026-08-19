import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get onAuthStateChange;
  Session? get currentSession;
  User? get currentUser;

  Future<void> sendOtp({required String phone});
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  });
  Future<void> signOut();

  /// Permanently erases the caller's account (GDPR Art.17) via the
  /// `delete-account` Edge Function, then signs out locally.
  Future<void> deleteAccount();

  /// Exports the caller's personal data (GDPR Art.20) via the `export-data`
  /// Edge Function, returned as a pretty-printed JSON string.
  Future<String> exportData();
}
