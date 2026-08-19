import 'package:flutter/material.dart';

/// Shared confirmation dialog. Returns `true` when the user confirms, `false`
/// (or `null` coerced to `false`) when they cancel or dismiss.
class BarakaliDialog {
  const BarakaliDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: destructive
                  ? TextButton.styleFrom(foregroundColor: scheme.error)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
