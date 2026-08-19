import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/providers/locale_provider.dart';

/// AppBar action that lets the user switch the app language. Used on screens
/// that have no Profile tab (merchant/admin dashboards) so the language can be
/// changed from anywhere, mirroring the selector in the consumer Profile tab.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  static const _locales = [
    ('ru', 'Русский'),
    ('uz', 'Oʻzbekcha'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate_rounded),
      tooltip: l10n.language,
      onSelected: (code) =>
          ref.read(localeProvider.notifier).setLocale(Locale(code)),
      itemBuilder: (context) => [
        for (final (code, label) in _locales)
          CheckedPopupMenuItem(
            value: code,
            checked: currentLocale.languageCode == code,
            child: Text(label),
          ),
      ],
    );
  }
}
