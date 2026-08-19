import 'package:barakali/features/legal/presentation/widgets/markdown_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the plain text of every Text/Text.rich rendered under [finder].
String _allText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    if (w.data != null) {
      buffer.write(w.data);
    } else if (w.textSpan != null) {
      buffer.write(w.textSpan!.toPlainText());
    }
  }
  return buffer.toString();
}

void main() {
  testWidgets('renders inline **bold** without leaking literal asterisks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownView(
            source:
                '## Heading\n\n'
                '- **Account data:** your phone number\n\n'
                'We do **not** collect biometric data.\n\n'
                '> DRAFT — **pending** review',
          ),
        ),
      ),
    );

    final text = _allText(tester);
    expect(text, contains('Account data:'));
    expect(text, contains('We do not collect biometric data.'));
    expect(text, isNot(contains('**')));
  });

  testWidgets('joins wrapped lines into one paragraph', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownView(source: 'first line\nsecond line')),
      ),
    );
    expect(_allText(tester), contains('first line second line'));
  });
}
