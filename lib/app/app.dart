import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/locale_provider.dart';
import '../features/auth/providers/locale_sync_provider.dart';
import '../features/notifications/providers/notification_tap_provider.dart';
import '../features/profile/providers/theme_mode_provider.dart';
import 'router.dart';
import 'theme.dart';

class BarakaliApp extends ConsumerWidget {
  const BarakaliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeSyncProvider);
    ref.watch(notificationTapProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Barakali',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
