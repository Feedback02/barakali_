import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:barakali/core/utils/app_logger.dart';

/// Durable per-device theme preference (system / light / dark). Backed by
/// `flutter_secure_storage` (already a dependency) so it survives restarts on
/// web + mobile. Not a secret, just the cross-platform KV we already ship. All
/// ops are best-effort: a read failure falls back to `system` so a storage
/// glitch can never trap a user in the wrong theme, and a write failure only
/// means the choice may not persist past this run.
class ThemeModeStore {
  const ThemeModeStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'theme_mode_v1';

  Future<ThemeMode> read() async {
    try {
      return switch (await _storage.read(key: _key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      log.w('Theme mode read failed; defaulting to system');
      return ThemeMode.system;
    }
  }

  Future<void> write(ThemeMode mode) async {
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      log.w('Theme mode write failed (non-fatal)');
    }
  }
}
