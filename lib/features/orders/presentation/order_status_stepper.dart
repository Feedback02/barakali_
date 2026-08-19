import 'package:flutter/material.dart';

import 'package:barakali/core/l10n/app_localizations.dart';

import '../domain/models/order.dart';
import 'order_labels.dart';

/// Horizontal progress through the consumer happy-path order lifecycle:
/// reserved -> paid -> picked up. The internal `picked_up` -> `completed`
/// finalization is invisible to the consumer (both read "picked up" in every
/// locale), so it collapses into the final step rather than showing a duplicate
/// node. Off-path terminal states (cancelled / refunded / expired) are not a
/// point on this path, so the stepper renders nothing for them and the status
/// badge alone conveys the outcome.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.reserved,
    OrderStatus.paid,
    OrderStatus.pickedUp,
  ];

  @override
  Widget build(BuildContext context) {
    // Both picked_up and completed land on the final step (fully done).
    final isFinal =
        status == OrderStatus.pickedUp || status == OrderStatus.completed;
    final activeIndex = switch (status) {
      OrderStatus.reserved => 0,
      OrderStatus.paid => 1,
      OrderStatus.pickedUp || OrderStatus.completed => _steps.length - 1,
      _ => -1,
    };
    if (activeIndex < 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Expanded(
            child: _Step(
              label: orderStatusLabel(l10n, _steps[i]),
              // A node is "done" once the flow has passed it; on the final step
              // (picked up / completed) every node is done.
              done: i < activeIndex || isFinal,
              current: i == activeIndex && !isFinal,
              hasLeftLine: i > 0,
              hasRightLine: i < _steps.length - 1,
              leftLineDone: i <= activeIndex,
              rightLineDone: i < activeIndex,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.current,
    required this.hasLeftLine,
    required this.hasRightLine,
    required this.leftLineDone,
    required this.rightLineDone,
  });

  final String label;
  final bool done;
  final bool current;
  final bool hasLeftLine;
  final bool hasRightLine;
  final bool leftLineDone;
  final bool rightLineDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reached = done || current;
    final mutedLine = scheme.onSurface.withValues(alpha: 0.18);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _line(
                hasLeftLine
                    ? (leftLineDone ? scheme.primary : mutedLine)
                    : null,
              ),
            ),
            _node(scheme),
            Expanded(
              child: _line(
                hasRightLine
                    ? (rightLineDone ? scheme.primary : mutedLine)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: reached
                ? scheme.onSurface
                : scheme.onSurface.withValues(alpha: 0.5),
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _line(Color? color) =>
      Container(height: 2, color: color ?? Colors.transparent);

  Widget _node(ColorScheme scheme) {
    final filled = done || current;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? scheme.primary : Colors.transparent,
        border: filled
            ? null
            : Border.all(
                color: scheme.onSurface.withValues(alpha: 0.3),
                width: 2,
              ),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
          : current
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onPrimary,
              ),
            )
          : null,
    );
  }
}
