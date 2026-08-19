import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_errors.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> sendOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    // The Edge Function identifies the account from the caller's JWT (attached
    // automatically) — no body needed. It throws FunctionException on non-2xx.
    // A 409 means the account has in-flight orders and erasure was refused.
    try {
      await _client.functions.invoke('delete-account');
    } on FunctionException catch (e) {
      if (e.status == 409) {
        throw const AccountDeletionBlockedException();
      }
      rethrow;
    }
    // The auth.users row is now gone; clear the (now-invalid) local session.
    await _client.auth.signOut();
  }

  @override
  Future<String> exportData() async {
    // The Edge Function returns application/json, decoded into res.data here;
    // re-encode it indented for a human-readable export.
    final res = await _client.functions.invoke('export-data');
    return const JsonEncoder.withIndent('  ').convert(res.data);
  }
}
