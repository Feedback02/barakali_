import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/locale_provider.dart';
import 'package:barakali/core/utils/app_logger.dart';
import 'auth_providers.dart';

const _supported = {'uz', 'ru', 'en'};

/// Keeps the app locale and `profiles.preferred_language` in sync so push
/// notifications — rendered server-side from `preferred_language` — arrive in
/// the language the user picked, on web and mobile alike. Without this the
/// column stays at its `'ru'` default forever (nothing else writes it).
///
/// Activate by `ref.watch`-ing it once at the app root. Both directions guard on
/// equality so they can't ping-pong.
final localeSyncProvider = Provider<void>((ref) {
  // profile -> locale: a signed-in user's saved language drives the UI (and so
  // a re-pick isn't needed every launch).
  ref.listen(currentUserProfileProvider, (_, next) {
    // Ignore in-flight emissions: a refresh() (e.g. the one the locale->profile
    // path triggers) emits AsyncLoading carrying the *stale previous* value
    // first. Acting on it would yank the locale back to the old language for a
    // frame before the new value lands — the visible new->old->new flicker.
    if (next.isLoading) return;
    final lang = next.value?.preferredLanguage;
    if (lang == null || !_supported.contains(lang)) return;
    if (ref.read(localeProvider).languageCode == lang) return;
    ref.read(localeProvider.notifier).setLocale(Locale(lang));
  }, fireImmediately: true);

  // locale -> profile: persist a user-driven language change so the server
  // localizes notifications to it.
  ref.listen(localeProvider, (prev, next) async {
    if (prev?.languageCode == next.languageCode) return;
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    if (ref.read(currentUserProfileProvider).value?.preferredLanguage ==
        next.languageCode) {
      return;
    }
    try {
      await ref
          .read(profileRepositoryProvider)
          .updatePreferredLanguage(userId: userId, language: next.languageCode);
      ref.read(currentUserProfileProvider.notifier).refresh();
    } catch (_) {
      log.w('Persist preferred_language failed (non-fatal)');
    }
  });
});
