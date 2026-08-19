import 'package:barakali/features/legal/domain/legal_document.dart';
import 'package:barakali/features/legal/presentation/widgets/legal_link_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('renders the full label with the link phrase present', (
    tester,
  ) async {
    await _pump(
      tester,
      const LegalLinkText(
        label: 'I agree to the Terms of Service',
        linkPhrase: 'Terms of Service',
        document: LegalDocument.termsOfService,
      ),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(), 'I agree to the Terms of Service');
  });

  testWidgets('falls back to plain text when the phrase is absent', (
    tester,
  ) async {
    await _pump(
      tester,
      const LegalLinkText(
        label: 'I agree to the Terms of Service',
        linkPhrase: 'Политику', // not a substring of the label
        document: LegalDocument.termsOfService,
      ),
    );
    expect(find.text('I agree to the Terms of Service'), findsOneWidget);
  });
}
