/// The in-app legal documents (bundled as localized assets under
/// `assets/legal/`). The text is authored per language so word order /
/// declension stay natural; this enum only maps a document + locale to its
/// asset path and viewer route.
enum LegalDocument {
  termsOfService,
  privacyPolicy;

  /// Localized asset path, falling back to Russian (the app default) for any
  /// locale we don't ship a translation for.
  String assetPath(String languageCode) {
    final lang = switch (languageCode) {
      'en' => 'en',
      'uz' => 'uz',
      _ => 'ru',
    };
    final base = switch (this) {
      LegalDocument.termsOfService => 'terms_of_service',
      LegalDocument.privacyPolicy => 'privacy_policy',
    };
    return 'assets/legal/${base}_$lang.md';
  }

  /// In-app viewer route (registered as a public route — reachable pre-auth so
  /// the registration consent links work before the profile exists).
  String get route => switch (this) {
    LegalDocument.termsOfService => '/legal/terms',
    LegalDocument.privacyPolicy => '/legal/privacy',
  };
}

/// Version recorded against each `consent_records` row at registration and
/// shown in the viewer. Bump when the document text changes materially (and
/// consider re-prompting existing users to re-accept — tracked follow-up).
const String kLegalDocumentVersion = '1.0';

/// Display-only date the bundled documents were last revised.
const String kLegalDocumentDate = '2026-06-13';
