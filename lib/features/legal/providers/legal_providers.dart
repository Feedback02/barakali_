import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/legal_document.dart';

/// Loads a bundled legal document's markdown text for a given locale. Keyed by
/// (document, language) so the three languages cache independently; rootBundle
/// already caches the underlying asset string.
final legalDocumentTextProvider =
    FutureProvider.family<String, ({LegalDocument doc, String lang})>((
      ref,
      args,
    ) {
      return rootBundle.loadString(args.doc.assetPath(args.lang));
    });
