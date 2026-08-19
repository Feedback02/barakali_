import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_detail_row.dart';
import 'package:barakali/core/widgets/barakali_input.dart';
import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:barakali/features/orders/presentation/order_labels.dart';
import '../domain/models/admin_order.dart';
import '../providers/admin_providers.dart';
import 'admin_action.dart';

/// Status filter chips: "All" + each order status.
const _statusFilters = OrderStatus.values;

/// Admin order management: search any order by id / consumer phone / merchant
/// name, optionally filter by status, view detail + status history, and refund
/// a paid order (via the existing admin_refund_order RPC — the real gate is
/// server-side is_admin(), not this screen).
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  OrderStatus? _status;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Typing debounces (one RPC per pause, not per keystroke); chip taps search
  // immediately. The controller also drops stale results, so either way the
  // list reflects the latest query.
  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _runSearch);
  }

  void _runSearch() {
    ref
        .read(adminOrderSearchProvider.notifier)
        .search(query: _searchController.text, status: _status?.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminOrdersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: BarakaliInput(
              controller: _searchController,
              hint: l10n.adminOrdersSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (_) => _onQueryChanged(),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(l10n.adminOrderStatusAll),
                    selected: _status == null,
                    onSelected: (_) {
                      setState(() => _status = null);
                      _runSearch();
                    },
                  ),
                ),
                for (final s in _statusFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(orderStatusLabel(l10n, s)),
                      selected: _status == s,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _runSearch();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncRefreshList<AdminOrder>(
              async: ref.watch(adminOrderSearchProvider),
              onRefresh: () =>
                  ref.read(adminOrderSearchProvider.notifier).refresh(),
              emptyIcon: Icons.receipt_long_outlined,
              emptyTitle: l10n.adminOrdersEmptyTitle,
              errorTitle: l10n.adminOrdersErrorTitle,
              builder: (_, orders) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [for (final o in orders) _OrderCard(order: o)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BarakaliCard(
        onTap: () => _showOrderSheet(context, order),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.offerTitle ?? l10n.offerUnavailable,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.merchantName ?? '-'} · '
              '${order.consumerName ?? order.consumerPhone ?? '-'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.priceUzs(groupThousands(order.amountPaid)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showOrderSheet(BuildContext context, AdminOrder order) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _OrderSheet(order: order),
  );
}

class _OrderSheet extends ConsumerWidget {
  const _OrderSheet({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
                    order.offerTitle ?? l10n.offerUnavailable,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            BarakaliDetailRow(
              label: l10n.adminOrderMerchant,
              value: order.merchantName ?? '-',
            ),
            BarakaliDetailRow(
              label: l10n.adminOrderConsumer,
              value: [
                order.consumerName,
                order.consumerPhone,
              ].where((e) => e != null && e.isNotEmpty).join(' · '),
            ),
            BarakaliDetailRow(
              label: l10n.adminOrderAmount,
              value: l10n.priceUzs(groupThousands(order.amountPaid)),
            ),
            BarakaliDetailRow(
              label: l10n.adminOrderCommission,
              value: l10n.priceUzs(groupThousands(order.commissionAmount)),
            ),
            if (order.cancellationReason != null)
              BarakaliDetailRow(
                label: l10n.adminOrderCancelReason,
                value: order.cancellationReason!,
              ),
            const SizedBox(height: 16),
            Text(
              l10n.adminOrderStatusHistory,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _Timeline(order: order),
            if (order.isRefundable) ...[
              const SizedBox(height: 16),
              _RefundButton(order: order),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status history derived purely from the order's timestamp columns (no history
/// table): each timestamp that is set becomes a timeline entry.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mat = MaterialLocalizations.of(context);
    String fmt(DateTime t) {
      final local = t.toLocal();
      return '${mat.formatMediumDate(local)}, '
          '${TimeOfDay.fromDateTime(local).format(context)}';
    }

    final entries = <(String, DateTime)>[
      (l10n.orderStatusReserved, order.reservedAt),
      if (order.paidAt != null) (l10n.orderStatusPaid, order.paidAt!),
      if (order.pickedUpAt != null)
        (l10n.orderStatusPickedUp, order.pickedUpAt!),
      // cancelled_at backs cancelled/refunded/expired — only show it as a
      // terminal entry when the status actually is one (so the label can't
      // disagree with the row).
      if (order.cancelledAt != null && _isCancelTerminal(order.status))
        (_terminalLabel(l10n, order.status), order.cancelledAt!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, ts) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  fmt(ts),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static bool _isCancelTerminal(OrderStatus s) =>
      s == OrderStatus.cancelled ||
      s == OrderStatus.refunded ||
      s == OrderStatus.expired;

  /// `cancelled_at` backs cancelled / refunded / expired — label it by the
  /// order's actual terminal status.
  static String _terminalLabel(AppLocalizations l10n, OrderStatus s) =>
      switch (s) {
        OrderStatus.refunded => l10n.orderStatusRefunded,
        OrderStatus.expired => l10n.orderStatusExpired,
        _ => l10n.orderStatusCancelled,
      };
}

class _RefundButton extends ConsumerWidget {
  const _RefundButton({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final busy = ref.watch(adminRefundProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: busy ? null : () => _refund(context, ref),
        style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
        child: Text(l10n.adminOrderRefund),
      ),
    );
  }

  Future<void> _refund(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RefundDialog(),
    );
    if (reason == null || !context.mounted) return; // cancelled
    await runAdminAction(
      context,
      action: () => ref
          .read(adminRefundProvider.notifier)
          .refund(orderId: order.id, reason: reason.isEmpty ? null : reason),
      readError: () => ref.read(adminRefundProvider).error,
      successMessage: (l10n) => l10n.adminOrderRefunded,
    );
  }
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog();

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
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
      title: Text(l10n.adminRefundConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminRefundConfirmBody),
          const SizedBox(height: 12),
          BarakaliInput(
            controller: _controller,
            label: l10n.adminRefundReasonLabel,
            autofocus: true,
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
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.adminOrderRefund),
        ),
      ],
    );
  }
}
