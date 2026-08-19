import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/theme_mode_store.dart';

final themeModeStoreProvider = Provider<ThemeModeStore>((ref) {
  // Defaults are fine across web/Android/iOS; the store treats every op as
  // best-effort, so no special options are needed.
  return const ThemeModeStore(FlutterSecureStorage());
});

/// The app-wide light/dark/system theme preference. Defaults to `system` and
/// loads the persisted choice asynchronously (a brief first-frame flash to the
/// stored value is acceptable, like the locale), so it never blocks startup.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  // If the user picks a theme before the persisted value finishes loading, the
  // async load must not clobber their fresh choice.
  bool _userSet = false;

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final stored = await ref.read(themeModeStoreProvider).read();
    if (!_userSet && stored != state) state = stored;
  }

  Future<void> setMode(ThemeMode mode) async {
    _userSet = true;
    if (mode == state) return;
    state = mode;
    await ref.read(themeModeStoreProvider).write(mode);
  }
}
