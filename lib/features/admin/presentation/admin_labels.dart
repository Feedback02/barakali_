import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/barakali_status_badge.dart';

import '../domain/admin_errors.dart';
import '../domain/models/admin_merchant.dart';

String merchantStateLabel(AppLocalizations l10n, MerchantModerationState s) =>
    switch (s) {
      MerchantModerationState.pending => l10n.adminStatePending,
      MerchantModerationState.approved => l10n.adminStateApproved,
      MerchantModerationState.suspended => l10n.adminStateSuspended,
      MerchantModerationState.rejected => l10n.adminStateRejected,
    };

Color merchantStateColor(ColorScheme scheme, MerchantModerationState s) =>
    switch (s) {
      MerchantModerationState.pending => scheme.secondary,
      MerchantModerationState.approved => scheme.primary,
      MerchantModerationState.suspended => scheme.tertiary,
      MerchantModerationState.rejected => scheme.error,
    };

/// Maps the stored merchant category token to its localized label. Falls back
/// to the raw token for any value not in the known set.
String merchantCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'restaurant' => l10n.merchantCategoryRestaurant,
      'cafe' => l10n.merchantCategoryCafe,
      'bakery' => l10n.merchantCategoryBakery,
      'supermarket' => l10n.merchantCategorySupermarket,
      'other' => l10n.merchantCategoryOther,
      _ => category,
    };

String adminErrorMessage(AppLocalizations l10n, AdminErrorCode code) =>
    switch (code) {
      AdminErrorCode.coordsRequired => l10n.adminErrorCoordsRequired,
      AdminErrorCode.noteRequired => l10n.adminErrorNoteRequired,
      AdminErrorCode.notRefundable => l10n.adminErrorNotRefundable,
      AdminErrorCode.notApproved ||
      AdminErrorCode.merchantNotFound ||
      AdminErrorCode.notAdmin ||
      AdminErrorCode.unknown => l10n.adminActionError,
    };

class MerchantStateBadge extends StatelessWidget {
  const MerchantStateBadge({super.key, required this.state});

  final MerchantModerationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BarakaliStatusBadge(
      label: merchantStateLabel(l10n, state),
      color: merchantStateColor(Theme.of(context).colorScheme, state),
    );
  }
}
