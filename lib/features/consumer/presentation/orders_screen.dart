import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/widgets/async_refresh_list.dart';
import 'package:barakali/core/widgets/barakali_card.dart';
import 'package:barakali/core/widgets/barakali_countdown.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import 'package:barakali/features/orders/domain/models/order.dart';
import 'package:barakali/features/orders/domain/models/order_with_details.dart';
import 'package:barakali/features/orders/presentation/order_labels.dart';
import 'package:barakali/features/orders/providers/order_providers.dart';

/// The consumer Orders tab: active reservations on top, past orders below.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navOrders)),
      body: AsyncRefreshList<OrderWithDetails>(
        async: async,
        onRefresh: () => ref.refresh(myOrdersProvider.future),
        emptyIcon: Icons.receipt_long_outlined,
        emptyTitle: l10n.ordersEmptyTitle,
        emptyMessage: l10n.ordersEmptyBody,
        errorTitle: l10n.ordersErrorTitle,
        builder: (_, orders) => _OrdersList(orders: orders),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(title: l10n.ordersActiveTitle),
          for (final item in active) _OrderCard(item: item, highlight: true),
        ],
        if (past.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 16),
          _SectionHeader(title: l10n.ordersPastTitle),
          for (final item in past) _OrderCard(item: item),
        ],
      ],
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.item, this.highlight = false});

  final OrderWithDetails item;

  /// Active orders are framed with a primary border so they stand out from the
  /// past-orders section below.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final order = item.order;
    final offer = item.offer;
    final merchant = item.merchant;

    final card = BarakaliCard(
      onTap: () => context.push('/order/${order.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BarakaliImage(url: offer?.imageUrl, width: 64, height: 64),
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
                if (merchant != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    merchant.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    OrderStatusBadge(status: order.status),
                    const SizedBox(width: 8),
                    Text(
                      l10n.priceUzs(groupThousands(order.amountPaid)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (offer != null) ...[
                  const SizedBox(height: 4),
                  // Active orders show a live countdown to the pickup window;
                  // past orders just restate the static window.
                  if (highlight)
                    BarakaliCountdown(
                      start: offer.pickupStart,
                      end: offer.pickupEnd,
                      compact: true,
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
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
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: highlight
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: card,
            )
          : card,
    );
  }
}
