import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:barakali/features/orders/domain/models/order_with_details.dart';
import 'package:barakali/features/orders/domain/order_errors.dart';
import 'package:barakali/features/orders/domain/repositories/order_repository.dart';
import 'package:barakali/features/orders/presentation/order_labels.dart';
import 'package:barakali/features/orders/providers/order_providers.dart';

/// Merchant's incoming reservations + pickup verification. The merchant verifies
/// a pickup by the code/QR the customer presents — they can't complete a pickup
/// without it.
class MerchantOrdersScreen extends ConsumerStatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  ConsumerState<MerchantOrdersScreen> createState() =>
      _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends ConsumerState<MerchantOrdersScreen> {
  @override
  void initState() {
    super.initState();
    // A pushed route (not a kept-alive tab): refresh incoming reservations each
    // time the screen opens, since consumers create them between visits. The
    // current list stays visible during the reload (skipLoadingOnReload).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(merchantOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navOrders)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVerify,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(l10n.verifyPickupCta),
      ),
      body: AsyncRefreshList<OrderWithDetails>(
        async: ref.watch(merchantOrdersProvider),
        onRefresh: () => ref.refresh(merchantOrdersProvider.future),
        emptyIcon: Icons.receipt_long_outlined,
        emptyTitle: l10n.merchantOrdersEmptyTitle,
        emptyMessage: l10n.merchantOrdersEmptyBody,
        errorTitle: l10n.ordersErrorTitle,
        builder: (_, orders) => _OrdersList(orders: orders),
      ),
    );
  }

  Future<void> _openVerify() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<PickupResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VerifyPickupSheet(),
    );
    if (result != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.verifySuccess(result.offerTitle))),
      );
    }
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders});

  final List<OrderWithDetails> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = orders.where((o) => o.order.isActive).toList();
    final past = orders.where((o) => !o.order.isActive).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _StatsHeader(orders: orders),
        const SizedBox(height: 8),
        if (active.isNotEmpty) ...[
          _SectionHeader(title: l10n.ordersActiveTitle),
          for (final item in active) _MerchantOrderCard(item: item),
        ],
        if (past.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 16),
          _SectionHeader(title: l10n.ordersPastTitle),
          for (final item in past) _MerchantOrderCard(item: item),
        ],
      ],
    );
  }
}

/// Compact merchant stats: bags collected, revenue, average rating. Derived
/// from the loaded orders + the embedded merchant summary (no extra query).
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.orders});

  final List<OrderWithDetails> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = orders
        .where((o) => o.order.status == OrderStatus.completed)
        .toList();
    final bags = completed.length;
    // Merchant "revenue" is their net payout (bag price minus the platform
    // fee), not the gross the consumer paid.
    final revenue = completed.fold<int>(0, (s, o) => s + o.order.netPayout);
    final merchant = orders.isEmpty ? null : orders.first.merchant;
    final total = merchant?.totalRatings ?? 0;
    final ratingText = total == 0
        ? '-'
        : (merchant?.rating ?? 0).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _StatTile(label: l10n.statsBagsSold, value: '$bags'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.statsRevenue,
            value: l10n.priceUzs(groupThousands(revenue)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.statsRating,
            value: total == 0 ? ratingText : '$ratingText ($total)',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BarakaliCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _MerchantOrderCard extends StatelessWidget {
  const _MerchantOrderCard({required this.item});

  final OrderWithDetails item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final order = item.order;
    final offer = item.offer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BarakaliCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarakaliImage(url: offer?.imageUrl, width: 56, height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer?.title ?? l10n.offerUnavailable,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OrderStatusBadge(status: order.status),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.merchantNetPayout(
                            l10n.priceUzs(groupThousands(order.netPayout)),
                          ),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (offer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatPickupWindow(
                        context,
                        offer.pickupStart,
                        offer.pickupEnd,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to verify a pickup: type the customer's code or scan their QR.
/// Manual entry always works (camera/scan is optional, degrades gracefully).
class _VerifyPickupSheet extends ConsumerStatefulWidget {
  const _VerifyPickupSheet();

  @override
  ConsumerState<_VerifyPickupSheet> createState() => _VerifyPickupSheetState();
}

class _VerifyPickupSheetState extends ConsumerState<_VerifyPickupSheet> {
  final _controller = TextEditingController();
  bool _scanning = false;
  bool _handledScan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = ref.watch(verifyPickupProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.verifyPickupTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_scanning) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.verifyScanUnavailable,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            autofocus: !_scanning,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: l10n.verifyCodeHint,
              counterText: '',
            ),
            onSubmitted: (_) => _verify(context),
          ),
          const SizedBox(height: 12),
          BarakaliButton(
            label: l10n.verifyAction,
            isLoading: busy,
            onPressed: () => _verify(context),
          ),
          TextButton.icon(
            onPressed: busy
                ? null
                : () => setState(() {
                    _scanning = !_scanning;
                    _handledScan = false;
                  }),
            icon: Icon(
              _scanning
                  ? Icons.keyboard_rounded
                  : Icons.qr_code_scanner_rounded,
            ),
            label: Text(
              _scanning ? l10n.verifyEnterManually : l10n.verifyScanQr,
            ),
          ),
        ],
      ),
    );
  }

  // A pickup code is exactly 6 chars from the no-confusable alphabet
  // (no I/O/0/1), matching generate_pickup_code() server-side. Ignore any scan
  // that isn't a pickup code (e.g. an unrelated QR) so it neither triggers a
  // wasted verify round-trip nor latches _handledScan and blocks the next scan.
  static final _pickupCodePattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    final code = raw.trim().toUpperCase();
    if (!_pickupCodePattern.hasMatch(code)) return;
    _handledScan = true;
    _controller.text = code;
    _verify(context);
  }

  Future<void> _verify(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final code = _controller.text.trim();
    if (code.isEmpty || ref.read(verifyPickupProvider).isLoading) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(verifyPickupProvider.notifier).verify(code);
    if (!mounted) return;
    if (result != null) {
      navigator.pop(result);
    } else {
      _handledScan = false;
      final err = ref.read(verifyPickupProvider).error;
      final messageCode = err is OrderException
          ? err.code
          : OrderErrorCode.unknown;
      messenger.showSnackBar(
        SnackBar(content: Text(orderErrorMessage(l10n, messageCode))),
      );
    }
  }
}
