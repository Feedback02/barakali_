import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:barakali/features/orders/domain/models/order_with_details.dart';
import 'package:barakali/features/orders/providers/order_providers.dart';
import '../domain/payme_checkout.dart';
import '../domain/payment_config.dart';
import '../providers/payment_providers.dart';

/// Payment screen for a reserved order (`/order/:id/pay`).
///
/// Real flow: opens the Payme hosted checkout (when a kassa id is configured),
/// then polls the order until the server-side webhook flips it to `paid`. Dev
/// flow: a "simulate payment" button calls the 4A mock RPC. The two are gated by
/// [PaymentConfig] so dev stays testable until the sandbox key lands.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  Timer? _poll;
  bool _waiting = false; // checkout opened, polling for confirmation
  bool _launching = false;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _poll?.cancel();
    setState(() => _waiting = true);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.invalidate(orderByIdProvider(widget.orderId));
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
    if (mounted && _waiting) setState(() => _waiting = false);
  }

  Future<void> _payWithPayme(Order order, PaymentConfig config) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final url = buildPaymeCheckoutUrl(
      checkoutBase: config.checkoutBase,
      merchantId: config.paymeMerchantId,
      orderId: order.id,
      amountTiyin: order.amountPaid * 100,
      lang: lang,
    );

    setState(() => _launching = true);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('launch returned false');
      _startPolling();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.payLaunchError)));
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _simulate() async {
    final ok = await ref
        .read(orderActionsProvider.notifier)
        .pay(widget.orderId);
    // On success the controller invalidates orderByIdProvider; the watched
    // status flips to paid and the UI rebuilds into the success state.
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.offerActionError)));
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/order/${widget.orderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(orderByIdProvider(widget.orderId));

    // Stop polling as soon as the order leaves the reserved state.
    ref.listen(orderByIdProvider(widget.orderId), (_, next) {
      final status = next.value?.order.status;
      if (status != null && status != OrderStatus.reserved) _stopPolling();
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => BarakaliEmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.ordersErrorTitle,
        ),
        data: (details) => details == null
            ? BarakaliEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.offerUnavailable,
              )
            : _body(details),
      ),
    );
  }

  Widget _body(OrderWithDetails details) {
    final order = details.order;
    if (order.status == OrderStatus.paid) return _PaidView(onView: _back);
    if (order.status != OrderStatus.reserved) {
      return _NotPayableView(status: order.status, onBack: _back);
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final config = ref.watch(paymentConfigProvider);
    final actionBusy = ref.watch(orderActionsProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AmountCard(title: details.offer?.title, amount: order.amountPaid),
        const SizedBox(height: 24),
        if (_waiting) ...[
          _WaitingCard(
            onCheckNow: () => ref.invalidate(orderByIdProvider(order.id)),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _stopPolling, child: Text(l10n.payBack)),
        ] else ...[
          if (config.isPaymeConfigured) ...[
            BarakaliButton(
              label: l10n.payWithPayme,
              isLoading: _launching,
              onPressed: () => _payWithPayme(order, config),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.payProviderNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ] else if (!config.mockEnabled)
            Text(
              l10n.payUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          if (config.mockEnabled) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: actionBusy ? null : _simulate,
              child: Text(l10n.payDevSimulate),
            ),
          ],
        ],
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.title, required this.amount});

  final String? title;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(title!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.payAmountLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.priceUzs(groupThousands(amount)),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.onCheckNow});

  final VoidCallback onCheckNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(l10n.payWaitingTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          l10n.payWaitingHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        BarakaliButton(label: l10n.payCheckNow, onPressed: onCheckNow),
      ],
    );
  }
}

class _PaidView extends StatelessWidget {
  const _PaidView({required this.onView});

  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(l10n.paySuccess, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          BarakaliButton(label: l10n.payViewOrder, onPressed: onView),
        ],
      ),
    );
  }
}

class _NotPayableView extends StatelessWidget {
  const _NotPayableView({required this.status, required this.onBack});

  final OrderStatus status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BarakaliEmptyState(
            icon: Icons.info_outline_rounded,
            title: l10n.payNotPayable,
          ),
          const SizedBox(height: 16),
          BarakaliButton(label: l10n.payViewOrder, onPressed: onBack),
        ],
      ),
    );
  }
}
