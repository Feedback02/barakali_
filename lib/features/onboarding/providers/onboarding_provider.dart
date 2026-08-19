import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/onboarding_store.dart';

final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  // Defaults are fine across web/Android/iOS; the store treats every op as
  // best-effort (a read failure reports "seen"), so no special options needed.
  return const OnboardingStore(FlutterSecureStorage());
});

/// Whether the first-run value-prop intro has been seen on this device. Drives
/// the router gate ahead of `/auth/phone` for unauthenticated first-run users.
/// Resolves once at startup (the router holds on splash while it loads).
final onboardingSeenProvider =
    AsyncNotifierProvider<OnboardingSeenNotifier, bool>(
      OnboardingSeenNotifier.new,
    );

class OnboardingSeenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(onboardingStoreProvider).isSeen();

  /// Persist that the intro was completed/skipped and flip the gate open.
  Future<void> markSeen() async {
    await ref.read(onboardingStoreProvider).markSeen();
    state = const AsyncData(true);
  }
}
