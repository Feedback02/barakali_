import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_detail_row.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import 'package:barakali/core/widgets/barakali_status_badge.dart';
import '../domain/models/support_ticket.dart';
import '../providers/support_providers.dart';

/// Admin support inbox: all reported issues (open first), with a resolve action.
/// Reading all tickets relies on the admin SELECT RLS; resolve goes through the
/// admin-gated `resolve_ticket` RPC.
class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(adminTicketsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSupportTitle)),
      body: AsyncRefreshList<SupportTicket>(
        async: ref.watch(adminTicketsProvider),
        onRefresh: () => ref.refresh(adminTicketsProvider.future),
        emptyIcon: Icons.support_agent_rounded,
        emptyTitle: l10n.adminSupportEmptyTitle,
        errorTitle: l10n.adminSupportErrorTitle,
        builder: (_, tickets) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [for (final t in tickets) _TicketCard(ticket: t)],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BarakaliCard(
        onTap: () => _showTicketSheet(context, ticket),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ticket.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showTicketSheet(BuildContext context, SupportTicket ticket) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TicketSheet(ticket: ticket),
  );
}

class _TicketSheet extends ConsumerWidget {
  const _TicketSheet({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mat = MaterialLocalizations.of(context);
    final reporter = [
      ticket.reporterName,
      ticket.reporterPhone,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                _StatusBadge(status: ticket.status),
              ],
            ),
            const SizedBox(height: 12),
            if (reporter.isNotEmpty)
              BarakaliDetailRow(
                label: l10n.adminSupportReporter,
                value: reporter,
              ),
            BarakaliDetailRow(
              label: l10n.adminSupportCreated,
              value: mat.formatMediumDate(ticket.createdAt.toLocal()),
            ),
            const SizedBox(height: 8),
            Text(ticket.message, style: theme.textTheme.bodyMedium),
            if (ticket.adminNote != null && ticket.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              BarakaliDetailRow(
                label: l10n.adminSupportNote,
                value: ticket.adminNote!,
              ),
            ],
            if (ticket.isOpen) ...[
              const SizedBox(height: 16),
              _ResolveButton(ticket: ticket),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResolveButton extends ConsumerWidget {
  const _ResolveButton({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(resolveTicketProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: busy ? null : () => _resolve(context, ref),
        child: Text(l10n.adminSupportResolve),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _ResolveDialog(),
    );
    if (note == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await ref
        .read(resolveTicketProvider.notifier)
        .resolve(ticketId: ticket.id, note: note.isEmpty ? null : note);
    if (!context.mounted) return;
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminSupportResolved)),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminActionError)));
    }
  }
}

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog();

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminSupportResolve),
      content: BarakaliInput(
        controller: _controller,
        label: l10n.adminSupportNoteLabel,
        autofocus: true,
        maxLength: 280,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.dialogCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.adminSupportResolve),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final open = status == SupportTicketStatus.open;
    return BarakaliStatusBadge(
      label: open
          ? l10n.adminSupportStatusOpen
          : l10n.adminSupportStatusResolved,
      color: open ? scheme.secondary : scheme.primary,
    );
  }
}
