import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:barakali/core/providers/supabase_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'package:barakali/features/notifications/providers/notification_providers.dart';
import '../data/auth_repository_impl.dart';
import '../data/profile_repository_impl.dart';
import '../domain/models/auth_state.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
});

final authStateProvider =
    AsyncNotifierProvider<AuthStateNotifier, AppAuthState>(
      AuthStateNotifier.new,
    );

class AuthStateNotifier extends AsyncNotifier<AppAuthState> {
  StreamSubscription<supabase.AuthState>? _subscription;

  @override
  Future<AppAuthState> build() async {
    _subscription?.cancel();
    _subscription = ref
        .read(authRepositoryProvider)
        .onAuthStateChange
        .listen(_handleAuthChange);

    ref.onDispose(() => _subscription?.cancel());

    final session = ref.read(authRepositoryProvider).currentSession;
    if (session == null) return AppAuthState.unauthenticated;

    return _resolveAuthState(session.user.id);
  }

  /// Signs the user out. State is updated via the signedOut auth event.
  Future<void> signOut() async {
    await _unregisterDevice();
    await ref.read(authRepositoryProvider).signOut();
  }

  /// Permanently erases the account (GDPR Art.17). Throws on failure so the UI
  /// can surface an error; on success the signedOut event resets routing state.
  Future<void> deleteAccount() async {
    // Erase first: if it's refused (e.g. open orders), we must NOT have already
    // dropped this device's push token from the still-active account. The
    // erase_user cascade removes device_tokens on success anyway.
    await ref.read(authRepositoryProvider).deleteAccount();
    await _unregisterDevice();
  }

  /// Registers this device for push after a successful sign-in. No-ops while
  /// FCM is disabled (5A) or permission is denied; never blocks auth.
  Future<void> _registerDevice() async {
    try {
      await ref.read(deviceRegistrationProvider).register();
    } catch (_) {
      log.w('Device registration failed (non-fatal)');
    }
  }

  /// Deletes this device's token so a logged-out device stops receiving pushes.
  Future<void> _unregisterDevice() async {
    try {
      await ref.read(deviceRegistrationProvider).unregister();
    } catch (_) {
      log.w('Device unregistration failed (non-fatal)');
    }
  }

  /// Exports the caller's personal data (GDPR Art.20) as a JSON string.
  Future<String> exportData() async {
    return ref.read(authRepositoryProvider).exportData();
  }

  Future<AppAuthState> _resolveAuthState(String userId) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .fetchProfile(userId);

    if (profile == null) return AppAuthState.unauthenticated;
    if (profile.displayName.isEmpty) return AppAuthState.needsRegistration;
    return AppAuthState.authenticated;
  }

  void _handleAuthChange(supabase.AuthState authState) async {
    switch (authState.event) {
      // initialSession fires on app start once Supabase finishes restoring a
      // persisted session — on web this can land AFTER build() has already run
      // with a null currentSession, so it must be handled to recover the session.
      case supabase.AuthChangeEvent.initialSession:
      case supabase.AuthChangeEvent.signedIn:
        final userId = authState.session?.user.id;
        if (userId == null) {
          state = const AsyncValue.data(AppAuthState.unauthenticated);
          return;
        }
        state = const AsyncValue.loading();
        state = await AsyncValue.guard(() => _resolveAuthState(userId));
        if (state.value == AppAuthState.authenticated) {
          unawaited(_registerDevice());
        }
      case supabase.AuthChangeEvent.signedOut:
        state = const AsyncValue.data(AppAuthState.unauthenticated);
      case supabase.AuthChangeEvent.userUpdated:
        // Re-resolve without dropping to loading (avoids a splash flash).
        final userId = authState.session?.user.id;
        if (userId != null) {
          state = await AsyncValue.guard(() => _resolveAuthState(userId));
        }
      // tokenRefreshed (fires periodically) and other events leave the session
      // user + profile unchanged, so they must not reset routing state.
      default:
        break;
    }
  }
}

final currentUserProfileProvider =
    AsyncNotifierProvider<CurrentUserProfileNotifier, UserProfile?>(
      CurrentUserProfileNotifier.new,
    );

class CurrentUserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final authState = await ref.watch(authStateProvider.future);
    if (authState != AppAuthState.authenticated) return null;

    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return null;

    final profile = await ref
        .read(profileRepositoryProvider)
        .fetchProfile(userId);
    log.i('User profile loaded');
    return profile;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
