import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/legal_document.dart';

/// Renders [label] as body text, turning the first occurrence of [linkPhrase]
/// into a tappable link that opens [document]'s viewer. If [linkPhrase] isn't
/// found in [label] (e.g. a translation drifted), the whole label renders as
/// plain text — the consent stays usable, it just loses the inline link.
///
/// [linkPhrase] is a localized key chosen to be a guaranteed substring of the
/// consent label (it differs from the document's nominative title because of
/// declension — e.g. Russian "Политику конфиденциальности" vs "Политика
/// конфиденциальности").
class LegalLinkText extends StatefulWidget {
  const LegalLinkText({
    super.key,
    required this.label,
    required this.linkPhrase,
    required this.document,
  });

  final String label;
  final String linkPhrase;
  final LegalDocument document;

  @override
  State<LegalLinkText> createState() => _LegalLinkTextState();
}

class _LegalLinkTextState extends State<LegalLinkText> {
  TapGestureRecognizer? _recognizer;

  @override
  void dispose() {
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;
    final idx = widget.linkPhrase.isEmpty
        ? -1
        : widget.label.indexOf(widget.linkPhrase);

    if (idx < 0) {
      return Text(widget.label, style: baseStyle);
    }

    final before = widget.label.substring(0, idx);
    final after = widget.label.substring(idx + widget.linkPhrase.length);

    _recognizer?.dispose();
    _recognizer = TapGestureRecognizer()
      ..onTap = () => context.push(widget.document.route);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: widget.linkPhrase,
            style: baseStyle?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _recognizer,
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}
