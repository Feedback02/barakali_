import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:barakali/core/utils/app_logger.dart';

/// Tiny durable flag: has this device seen the first-run value-prop intro?
/// Backed by `flutter_secure_storage` (already a dependency) so it survives
/// reinstall-less restarts on web + mobile. Not a secret — secure storage is
/// just the cross-platform KV we already ship. All ops are best-effort: a read
/// failure reports "seen" so a storage glitch can never trap a user in the
/// intro, and a write failure only means the intro may show once more.
class OnboardingStore {
  const OnboardingStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'onboarding_seen_v1';

  Future<bool> isSeen() async {
    try {
      return (await _storage.read(key: _key)) == 'true';
    } catch (_) {
      log.w('Onboarding flag read failed; treating as seen');
      return true;
    }
  }

  Future<void> markSeen() async {
    try {
      await _storage.write(key: _key, value: 'true');
    } catch (_) {
      log.w('Onboarding flag write failed (non-fatal)');
    }
  }
}
