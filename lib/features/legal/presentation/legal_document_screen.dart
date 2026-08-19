import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import '../domain/legal_document.dart';
import '../providers/legal_providers.dart';
import 'widgets/markdown_view.dart';

/// Read-only viewer for a bundled legal document, rendered in the active
/// locale. Public route — reachable without a session so the registration
/// consent links work before the profile exists.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = switch (document) {
      LegalDocument.termsOfService => l10n.legalTermsTitle,
      LegalDocument.privacyPolicy => l10n.legalPrivacyTitle,
    };
    final textAsync = ref.watch(
      legalDocumentTextProvider((doc: document, lang: lang)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: textAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.legalLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (source) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            MarkdownView(source: source),
            const SizedBox(height: 24),
            Text(
              l10n.legalVersionLine(kLegalDocumentVersion, kLegalDocumentDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
