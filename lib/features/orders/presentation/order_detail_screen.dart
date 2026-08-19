import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/utils/calendar_launcher.dart';
import 'package:barakali/core/utils/format.dart';
import 'package:barakali/core/utils/maps_launcher.dart';
import 'package:barakali/core/widgets/barakali_button.dart';
import 'package:barakali/core/widgets/barakali_countdown.dart';
import 'package:barakali/core/widgets/barakali_dialog.dart';
import 'package:barakali/core/widgets/barakali_empty_state.dart';
import 'package:barakali/core/widgets/barakali_image.dart';
import '../domain/models/order.dart';
import '../domain/models/order_with_details.dart';
import '../domain/order_errors.dart';
import '../providers/order_providers.dart';
import 'order_labels.dart';
import 'order_status_stepper.dart';

/// Detail for one order: status, the offer it's for, the pickup code (once
/// paid), and the pay / cancel actions.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderTitle)),
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
            : _OrderContent(details: details),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (details) =>
            details == null ? null : _OrderActionsBar(order: details.order),
        orElse: () => null,
      ),
    );
  }
}

class _OrderContent extends ConsumerWidget {
  const _OrderContent({required this.details});

  final OrderWithDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final order = details.order;
    final offer = details.offer;
    final merchant = details.merchant;

    return ListView(
      children: [
        if (offer?.imageUrl != null)
          BarakaliImage(
            url: offer!.imageUrl,
            width: double.infinity,
            height: 180,
            borderRadius: 0,
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OrderStatusBadge(status: order.status),
                  const Spacer(),
                  Text(
                    l10n.priceUzs(groupThousands(order.amountPaid)),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // The stepper only applies to the happy path; for cancelled /
              // refunded / expired orders the badge alone tells the story (and
              // the stepper collapses), so skip the surrounding spacing too.
              if (order.isActive || order.status == OrderStatus.completed) ...[
                const SizedBox(height: 20),
                OrderStatusStepper(status: order.status),
              ],
              const SizedBox(height: 16),
              Text(
                offer?.title ?? l10n.offerUnavailable,
                style: theme.textTheme.titleLarge,
              ),
              if (merchant != null) ...[
                const SizedBox(height: 4),
                Text(
                  merchant.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              // Live pickup countdown for an order that's still in progress
              // (reserved/paid); terminal orders show none.
              if (offer != null && order.isActive) ...[
                const SizedBox(height: 16),
                BarakaliCountdown(
                  start: offer.pickupStart,
                  end: offer.pickupEnd,
                ),
              ],
              const SizedBox(height: 20),
              if (offer != null)
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: l10n.offerPickupWindowLabel,
                  value: formatPickupWindow(
                    context,
                    offer.pickupStart,
                    offer.pickupEnd,
                  ),
                ),
              // Let the user drop the pickup window into their calendar while
              // the order is still upcoming (reserved/paid) - not once it's been
              // picked up, when the window is already in the past.
              if (offer != null &&
                  (order.status == OrderStatus.reserved ||
                      order.status == OrderStatus.paid))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => addToCalendar(
                      title: l10n.orderCalendarEventTitle(
                        merchant?.name ?? offer.title,
                      ),
                      start: offer.pickupStart,
                      end: offer.pickupEnd,
                      details: offer.title,
                      location: merchant?.address,
                    ),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(l10n.orderAddToCalendar),
                  ),
                ),
              if (merchant != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: l10n.merchantAddressLabel,
                  value: merchant.address,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => openDirections(
                      latitude: merchant.latitude,
                      longitude: merchant.longitude,
                      address: merchant.address,
                    ),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: Text(l10n.offerGetDirections),
                  ),
                ),
              ],
              if (order.status == OrderStatus.paid) ...[
                const SizedBox(height: 16),
                const _PickupGuide(),
                const SizedBox(height: 16),
                _PickupCodeSection(orderId: order.id),
              ],
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(height: 24),
                _RatingSection(details: details),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Rate a completed order (one per order). Shows the input until rated, then
/// the read-only rating.
class _RatingSection extends ConsumerStatefulWidget {
  const _RatingSection({required this.details});

  final OrderWithDetails details;

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  final _commentController = TextEditingController();
  int _score = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final existing = widget.details.rating;

    if (existing != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rateYourRating,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          _Stars(score: existing.score),
          if (existing.comment != null && existing.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(existing.comment!, style: theme.textTheme.bodyMedium),
          ],
        ],
      );
    }

    final busy = ref.watch(submitRatingProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.rateTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Center(
          child: RatingBar.builder(
            initialRating: _score.toDouble(),
            minRating: 1,
            itemCount: 5,
            itemSize: 40,
            glow: false,
            unratedColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            itemBuilder: (context, _) =>
                Icon(Icons.star_rounded, color: theme.colorScheme.secondary),
            onRatingUpdate: (value) => setState(() => _score = value.round()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 2,
          maxLength: 280,
          decoration: InputDecoration(
            hintText: l10n.rateCommentHint,
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        BarakaliButton(
          label: l10n.rateSubmit,
          isLoading: busy,
          onPressed: _score == 0 ? null : () => _submit(context),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(submitRatingProvider.notifier)
        .submit(
          orderId: widget.details.order.id,
          score: _score,
          comment: _commentController.text,
        );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? l10n.rateSuccess : l10n.offerActionError)),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= score ? Icons.star_rounded : Icons.star_border_rounded,
            color: color,
            size: 28,
          ),
      ],
    );
  }
}

/// A short, numbered "how to collect" guide shown above the pickup code once an
/// order is paid.
class _PickupGuide extends StatelessWidget {
  const _PickupGuide();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.orderPickupGuideTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _GuideStep(number: 1, text: l10n.orderPickupGuideStep1),
        const SizedBox(height: 8),
        _GuideStep(number: 2, text: l10n.orderPickupGuideStep2),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// Loads the consumer's own pickup code (via the consumer-only RPC, since the
/// column isn't directly readable) and renders the QR card once available.
class _PickupCodeSection extends ConsumerWidget {
  const _PickupCodeSection({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(pickupCodeProvider(orderId))
        .maybeWhen(
          data: (code) => code == null
              ? const SizedBox.shrink()
              : _PickupCodeCard(code: code),
          orElse: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
  }
}

class _PickupCodeCard extends StatelessWidget {
  const _PickupCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            l10n.orderPickupCodeLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: code,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            code,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderPickupCodeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// The action bar: mock-pay + cancel while reserved, cancel while paid (the
/// server enforces the free-cancel window), nothing once terminal.
class _OrderActionsBar extends ConsumerWidget {
  const _OrderActionsBar({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(orderActionsProvider).isLoading;

    final children = <Widget>[];
    if (order.status == OrderStatus.reserved) {
      children.add(
        BarakaliButton(
          label: l10n.orderPayNow,
          onPressed: () => context.push('/order/${order.id}/pay'),
        ),
      );
      children.add(
        TextButton(
          onPressed: busy ? null : () => _cancel(context, ref, l10n),
          child: Text(l10n.orderCancelAction),
        ),
      );
    } else if (order.status == OrderStatus.paid) {
      children.add(
        OutlinedButton(
          onPressed: busy ? null : () => _cancel(context, ref, l10n),
          child: Text(l10n.orderCancelAction),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await BarakaliDialog.confirm(
      context,
      title: l10n.orderCancelConfirmTitle,
      body: order.status == OrderStatus.paid
          ? l10n.orderCancelConfirmBodyPaid
          : l10n.orderCancelConfirmBodyReserved,
      confirmLabel: l10n.orderCancelAction,
      cancelLabel: l10n.orderKeepAction,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(orderActionsProvider.notifier).cancel(order.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.orderCancelledMessage : _error(ref, l10n)),
      ),
    );
    if (ok) context.pop();
  }

  String _error(WidgetRef ref, AppLocalizations l10n) {
    final err = ref.read(orderActionsProvider).error;
    final code = err is OrderException ? err.code : OrderErrorCode.unknown;
    return orderErrorMessage(l10n, code);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
