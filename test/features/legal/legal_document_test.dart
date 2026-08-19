import 'package:barakali/features/legal/domain/legal_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegalDocument.assetPath', () {
    test('maps each document + supported locale to its asset', () {
      expect(
        LegalDocument.termsOfService.assetPath('ru'),
        'assets/legal/terms_of_service_ru.md',
      );
      expect(
        LegalDocument.termsOfService.assetPath('uz'),
        'assets/legal/terms_of_service_uz.md',
      );
      expect(
        LegalDocument.privacyPolicy.assetPath('en'),
        'assets/legal/privacy_policy_en.md',
      );
    });

    test('falls back to Russian for an unsupported locale', () {
      expect(
        LegalDocument.privacyPolicy.assetPath('fr'),
        'assets/legal/privacy_policy_ru.md',
      );
      expect(
        LegalDocument.termsOfService.assetPath(''),
        'assets/legal/terms_of_service_ru.md',
      );
    });
  });

  test('routes are distinct and under /legal', () {
    expect(LegalDocument.termsOfService.route, '/legal/terms');
    expect(LegalDocument.privacyPolicy.route, '/legal/privacy');
  });

  test('document version and date constants are set', () {
    expect(kLegalDocumentVersion, isNotEmpty);
    expect(kLegalDocumentDate, isNotEmpty);
  });
}
