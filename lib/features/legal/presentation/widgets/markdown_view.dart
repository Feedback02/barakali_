import 'package:flutter/material.dart';

/// Minimal Markdown renderer for the bundled legal documents — no third-party
/// dependency (the `flutter_markdown` package was discontinued, and the
/// documents only need headings, bullets, callouts, paragraphs, and bold).
///
/// Supported syntax:
/// - `# ` / `## ` / `### ` — headings
/// - `- ` / `* ` — bullet list item
/// - `> ` — callout box (used for the DRAFT notice)
/// - `**bold**` — inline bold (within paragraphs, bullets, and callouts)
/// - blank line — paragraph break; consecutive non-blank lines join into one
///   paragraph
///
/// Other inline markup (links) is rendered literally.
class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.source});

  final String source;

  /// Splits [text] on `**` pairs into bold/regular spans. An unmatched marker
  /// degrades gracefully (the trailing segment renders bold).
  static List<InlineSpan> _inline(String text, TextStyle? base) {
    final parts = text.split('**');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? base?.copyWith(fontWeight: FontWeight.w700) : base,
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = <Widget>[];
    final paragraph = StringBuffer();

    void flushParagraph() {
      final text = paragraph.toString().trim();
      paragraph.clear();
      if (text.isEmpty) return;
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text.rich(
            TextSpan(children: _inline(text, theme.textTheme.bodyMedium)),
          ),
        ),
      );
    }

    for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushParagraph();
      } else if (line.startsWith('### ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(4).replaceAll('**', ''),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              line.substring(3).replaceAll('**', ''),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.substring(2).replaceAll('**', ''),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        flushParagraph();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _inline(
                        line.substring(2),
                        theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        flushParagraph();
        blocks.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              TextSpan(
                children: _inline(line.substring(2), theme.textTheme.bodySmall),
              ),
            ),
          ),
        );
      } else {
        if (paragraph.isNotEmpty) paragraph.write(' ');
        paragraph.write(line);
      }
    }
    flushParagraph();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
