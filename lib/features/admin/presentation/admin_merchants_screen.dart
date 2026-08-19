import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_detail_row.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import '../domain/models/admin_merchant.dart';
import '../providers/admin_providers.dart';
import 'admin_action.dart';
import 'admin_fee_dialog.dart';
import 'admin_labels.dart';

/// Default map center (Tashkent) prefilled into the approve dialog — a pending
/// merchant has no coordinates yet, and approval requires them for the map.
const _defaultLat = 41.3111;
const _defaultLng = 69.2797;

const _queues = [
  MerchantModerationState.pending,
  MerchantModerationState.approved,
  MerchantModerationState.suspended,
  MerchantModerationState.rejected,
];

/// Admin merchant management: four moderation queues with approve / reject /
/// suspend / reinstate actions. The actions are the *UX surface* — the real
/// gate is the admin-gated SECURITY DEFINER RPCs (is_admin() asserted server
/// side), so a non-admin reaching here still cannot moderate anything.
class AdminMerchantsScreen extends ConsumerStatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  ConsumerState<AdminMerchantsScreen> createState() =>
      _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends ConsumerState<AdminMerchantsScreen> {
  @override
  void initState() {
    super.initState();
    // A pushed route: refresh every queue on open (applications arrive between
    // visits). The current lists stay visible during reload.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(adminMerchantsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: _queues.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminMerchantsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final s in _queues) Tab(text: merchantStateLabel(l10n, s)),
            ],
          ),
        ),
        body: TabBarView(
          children: [for (final s in _queues) _MerchantQueue(state: s)],
        ),
      ),
    );
  }
}

class _MerchantQueue extends ConsumerWidget {
  const _MerchantQueue({required this.state});

  final MerchantModerationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AsyncRefreshList<AdminMerchant>(
      async: ref.watch(adminMerchantsProvider(state)),
      onRefresh: () => ref.refresh(adminMerchantsProvider(state).future),
      emptyIcon: Icons.storefront_outlined,
      emptyTitle: l10n.adminMerchantsEmptyTitle,
      errorTitle: l10n.adminMerchantsErrorTitle,
      builder: (_, items) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [for (final m in items) _MerchantCard(merchant: m)],
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant});

  final AdminMerchant merchant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BarakaliCard(
        onTap: () => _showMerchantSheet(context, merchant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    merchant.businessName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                MerchantStateBadge(state: merchant.state),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              merchant.address,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${merchantCategoryLabel(l10n, merchant.category)} · '
              '${l10n.adminMerchantPhone}: ${merchant.phone}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet: merchant details + the actions valid for its current state.
Future<void> _showMerchantSheet(BuildContext context, AdminMerchant merchant) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MerchantSheet(merchant: merchant),
  );
}

class _MerchantSheet extends ConsumerWidget {
  const _MerchantSheet({required this.merchant});

  final AdminMerchant merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mat = MaterialLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    merchant.businessName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                MerchantStateBadge(state: merchant.state),
              ],
            ),
            const SizedBox(height: 12),
            BarakaliDetailRow(
              label: l10n.adminMerchantCategory,
              value: merchantCategoryLabel(l10n, merchant.category),
            ),
            BarakaliDetailRow(
              label: l10n.adminMerchantPhone,
              value: merchant.phone,
            ),
            BarakaliDetailRow(
              label: l10n.adminMerchantAddress,
              value: merchant.address,
            ),
            if (merchant.description != null &&
                merchant.description!.isNotEmpty)
              BarakaliDetailRow(
                label: l10n.merchantDescriptionLabel,
                value: merchant.description!,
              ),
            BarakaliDetailRow(
              label: l10n.adminMerchantRating,
              value: merchant.totalRatings == 0
                  ? '-'
                  : '${merchant.rating.toStringAsFixed(1)} (${merchant.totalRatings})',
            ),
            BarakaliDetailRow(
              label: l10n.adminMerchantBagsSaved,
              value: '${merchant.totalBagsSaved}',
            ),
            BarakaliDetailRow(
              label: l10n.adminFeeSectionTitle,
              value: merchant.platformFee != null
                  ? l10n.priceUzs(groupThousands(merchant.platformFee!))
                  : l10n.adminFeeDefaultValue,
            ),
            BarakaliDetailRow(
              label: l10n.adminMerchantHalal,
              value: merchant.isHalal
                  ? l10n.adminHalalStateOn
                  : l10n.adminHalalStateOff,
            ),
            BarakaliDetailRow(
              label: l10n.adminMerchantJoined,
              value: mat.formatMediumDate(merchant.createdAt.toLocal()),
            ),
            if (merchant.moderationNote != null &&
                merchant.moderationNote!.isNotEmpty)
              BarakaliDetailRow(
                label: l10n.adminMerchantNote,
                value: merchant.moderationNote!,
              ),
            const SizedBox(height: 16),
            ..._actions(context, ref, l10n),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final busy = ref.watch(merchantModerationProvider).isLoading;
    final feeBusy = ref.watch(adminFeeProvider).isLoading;
    final stateActions = switch (merchant.state) {
      MerchantModerationState.pending => [
        _ActionButton(
          label: l10n.adminActionApprove,
          busy: busy,
          onPressed: () => _approve(context, ref),
        ),
        _ActionButton(
          label: l10n.adminActionReject,
          busy: busy,
          destructive: true,
          onPressed: () => _reject(context, ref),
        ),
      ],
      MerchantModerationState.rejected => [
        _ActionButton(
          label: l10n.adminActionApprove,
          busy: busy,
          onPressed: () => _approve(context, ref),
        ),
      ],
      MerchantModerationState.approved => [
        _ActionButton(
          label: l10n.adminActionSuspend,
          busy: busy,
          destructive: true,
          onPressed: () => _suspend(context, ref),
        ),
      ],
      MerchantModerationState.suspended => [
        _ActionButton(
          label: l10n.adminActionReinstate,
          busy: busy,
          onPressed: () => _reinstate(context, ref),
        ),
      ],
    };
    return [
      ...stateActions,
      // The per-merchant fee override is settable in any moderation state (the
      // cold-start ramp lever). Empty in the dialog resets to the platform
      // default. Server-gated by the admin-only set_merchant_fee RPC.
      _ActionButton(
        label: l10n.adminFeeEdit,
        busy: feeBusy,
        onPressed: () => _setFee(context, ref),
      ),
      // Halal is normally self-declared at registration; this lets an admin
      // set/correct it for existing merchants. Server-gated by set_merchant_halal.
      _ActionButton(
        label: merchant.isHalal
            ? l10n.adminActionUnsetHalal
            : l10n.adminActionSetHalal,
        busy: busy,
        onPressed: () => _setHalal(context, ref),
      ),
    ];
  }

  Future<void> _setHalal(BuildContext context, WidgetRef ref) async {
    await runAdminAction(
      context,
      action: () => ref
          .read(merchantModerationProvider.notifier)
          .setHalal(merchantId: merchant.id, isHalal: !merchant.isHalal),
      readError: () => ref.read(merchantModerationProvider).error,
      successMessage: (l10n) => l10n.adminHalalUpdated,
    );
  }

  Future<void> _setFee(BuildContext context, WidgetRef ref) async {
    final result = await showFeeDialog(
      context,
      initial: merchant.platformFee,
      allowDefault: true,
    );
    if (result == null || !context.mounted) return;
    await runAdminAction(
      context,
      action: () => ref
          .read(adminFeeProvider.notifier)
          .setMerchantFee(merchantId: merchant.id, fee: result.fee),
      readError: () => ref.read(adminFeeProvider).error,
      successMessage: (l10n) => l10n.adminFeeUpdated,
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<_ApproveInput>(
      context: context,
      builder: (_) => _ApproveDialog(merchant: merchant),
    );
    if (input == null || !context.mounted) return;
    await _dispatch(
      context,
      ref,
      action: (n) => n.approve(
        merchantId: merchant.id,
        latitude: input.lat,
        longitude: input.lng,
        note: input.note,
      ),
      successMessage: (l10n) => l10n.adminMerchantApproved,
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final note = await _promptNote(
      context,
      title: l10n.adminActionReject,
      label: l10n.adminRejectNoteLabel,
      required: true,
    );
    if (note == null || !context.mounted) return;
    await _dispatch(
      context,
      ref,
      action: (n) => n.reject(merchantId: merchant.id, note: note),
      successMessage: (l10n) => l10n.adminMerchantRejected,
    );
  }

  Future<void> _suspend(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final note = await _promptNote(
      context,
      title: l10n.adminActionSuspend,
      label: l10n.adminNoteLabel,
      required: false,
    );
    if (note == null || !context.mounted) return;
    await _dispatch(
      context,
      ref,
      action: (n) =>
          n.setActive(merchantId: merchant.id, active: false, note: note),
      successMessage: (l10n) => l10n.adminMerchantSuspended,
    );
  }

  Future<void> _reinstate(BuildContext context, WidgetRef ref) async {
    await _dispatch(
      context,
      ref,
      action: (n) => n.setActive(merchantId: merchant.id, active: true),
      successMessage: (l10n) => l10n.adminMerchantReinstated,
    );
  }

  /// Runs a moderation action, then (if still mounted) pops the sheet and shows
  /// a success/failure snackbar — via the shared [runAdminAction] helper.
  Future<void> _dispatch(
    BuildContext context,
    WidgetRef ref, {
    required Future<bool> Function(MerchantModerationController) action,
    required String Function(AppLocalizations) successMessage,
  }) {
    return runAdminAction(
      context,
      action: () => action(ref.read(merchantModerationProvider.notifier)),
      readError: () => ref.read(merchantModerationProvider).error,
      successMessage: successMessage,
    );
  }
}

/// Prompts for a moderation note. Returns the entered text on confirm (empty
/// allowed only when [required] is false), or null when cancelled.
Future<String?> _promptNote(
  BuildContext context, {
  required String title,
  required String label,
  required bool required,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteDialog(title: title, label: label, required: required),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.label,
    required this.required,
  });

  final String title;
  final String label;
  final bool required;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: BarakaliInput(
        controller: _controller,
        label: widget.label,
        autofocus: true,
        maxLength: 280,
        errorText: _showError ? l10n.adminErrorNoteRequired : null,
        onChanged: (_) {
          if (_showError) setState(() => _showError = false);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (widget.required && text.isEmpty) {
              setState(() => _showError = true);
              return;
            }
            Navigator.pop(context, text);
          },
          child: Text(l10n.dialogConfirm),
        ),
      ],
    );
  }
}

typedef _ApproveInput = ({double lat, double lng, String? note});

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.merchant});

  final AdminMerchant merchant;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late final TextEditingController _lat = TextEditingController(
    text: (widget.merchant.latitude ?? _defaultLat).toString(),
  );
  late final TextEditingController _lng = TextEditingController(
    text: (widget.merchant.longitude ?? _defaultLng).toString(),
  );
  final _note = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminActionApprove),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.adminApproveCoordsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          BarakaliInput(
            controller: _lat,
            label: l10n.adminApproveLatLabel,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            errorText: _showError ? l10n.adminErrorCoordsRequired : null,
          ),
          const SizedBox(height: 8),
          BarakaliInput(
            controller: _lng,
            label: l10n.adminApproveLngLabel,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
          ),
          const SizedBox(height: 8),
          BarakaliInput(
            controller: _note,
            label: l10n.adminNoteLabel,
            maxLength: 280,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        TextButton(
          onPressed: () {
            final lat = double.tryParse(_lat.text.trim());
            final lng = double.tryParse(_lng.text.trim());
            if (lat == null ||
                lng == null ||
                lat < -90 ||
                lat > 90 ||
                lng < -180 ||
                lng > 180) {
              setState(() => _showError = true);
              return;
            }
            final note = _note.text.trim();
            Navigator.pop(context, (
              lat: lat,
              lng: lng,
              note: note.isEmpty ? null : note,
            ));
          },
          child: Text(l10n.adminActionApprove),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.busy,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: destructive
            ? OutlinedButton(
                onPressed: busy ? null : onPressed,
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                child: Text(label),
              )
            : ElevatedButton(
                onPressed: busy ? null : onPressed,
                child: Text(label),
              ),
      ),
    );
  }
}
