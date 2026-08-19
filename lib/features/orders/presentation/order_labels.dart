import 'package:flutter/material.dart';
import 'package:barakali/core/l10n/app_localizations.dart';
import 'package:barakali/core/widgets/barakali_status_badge.dart';

import '../domain/models/order.dart';
import '../domain/order_errors.dart';

String orderStatusLabel(AppLocalizations l10n, OrderStatus status) =>
    switch (status) {
      OrderStatus.reserved => l10n.orderStatusReserved,
      OrderStatus.paid => l10n.orderStatusPaid,
      OrderStatus.pickedUp => l10n.orderStatusPickedUp,
      OrderStatus.completed => l10n.orderStatusCompleted,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
      OrderStatus.refunded => l10n.orderStatusRefunded,
      OrderStatus.expired => l10n.orderStatusExpired,
    };

Color orderStatusColor(ColorScheme scheme, OrderStatus status) =>
    switch (status) {
      OrderStatus.reserved => scheme.secondary,
      OrderStatus.paid ||
      OrderStatus.pickedUp ||
      OrderStatus.completed => scheme.primary,
      OrderStatus.cancelled || OrderStatus.refunded => scheme.error,
      OrderStatus.expired => scheme.outline,
    };

String orderErrorMessage(AppLocalizations l10n, OrderErrorCode code) =>
    switch (code) {
      OrderErrorCode.soldOut => l10n.orderErrorSoldOut,
      OrderErrorCode.offerUnavailable => l10n.offerUnavailable,
      OrderErrorCode.maxReservations => l10n.orderErrorMaxReservations,
      OrderErrorCode.cancelWindowClosed => l10n.orderErrorCancelWindow,
      OrderErrorCode.notCancellable => l10n.orderErrorNotCancellable,
      OrderErrorCode.paymentInProgress => l10n.orderErrorPaymentInProgress,
      OrderErrorCode.codeNotFound => l10n.verifyErrorCodeNotFound,
      OrderErrorCode.pickupExpired => l10n.verifyErrorExpired,
      OrderErrorCode.notMerchant ||
      OrderErrorCode.notOwner ||
      OrderErrorCode.notAuthenticated ||
      OrderErrorCode.unknown => l10n.offerActionError,
    };

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BarakaliStatusBadge(
      label: orderStatusLabel(l10n, status),
      color: orderStatusColor(Theme.of(context).colorScheme, status),
    );
  }
}
