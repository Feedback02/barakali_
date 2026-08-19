import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import '../domain/admin_errors.dart';
import 'admin_labels.dart';

/// Runs an admin action that returns true on success, then shows the standard
/// result feedback: on success optionally pop the sheet + a success snackbar; on
/// failure a localized snackbar mapped from the action's held error.
///
/// Centralizes the capture-messenger/navigator-before-await + context.mounted +
/// AdminException→localized-message pattern that the merchant / order admin
/// screens all repeated. [readError] returns the controller's held error after a
/// failure (typically `() => ref.read(provider).error`); a non-[AdminException]
/// falls back to [AdminErrorCode.unknown].
Future<bool> runAdminAction(
  BuildContext context, {
  required Future<bool> Function() action,
  required Object? Function() readError,
  required String Function(AppLocalizations) successMessage,
  bool popOnSuccess = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final ok = await action();
  if (!context.mounted) return ok;
  if (ok) {
    if (popOnSuccess) navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(successMessage(l10n))));
  } else {
    final err = readError();
    final code = err is AdminException ? err.code : AdminErrorCode.unknown;
    messenger.showSnackBar(
      SnackBar(content: Text(adminErrorMessage(l10n, code))),
    );
  }
  return ok;
}
