/// Expected, user-facing failures from the order RPCs. The server RAISEs these
/// as bare uppercase tokens in the exception message; [parseOrderError] maps the
/// message to a code so the presentation layer can show a localized string
/// (never the raw DB message). Unrecognized failures fall back to [unknown].
enum OrderErrorCode {
  soldOut,
  offerUnavailable,
  maxReservations,
  cancelWindowClosed,
  notCancellable,
  paymentInProgress,
  notOwner,
  notAuthenticated,
  // Pickup verification (4B)
  notMerchant,
  codeNotFound,
  pickupExpired,
  unknown,
}

class OrderException implements Exception {
  const OrderException(this.code);

  final OrderErrorCode code;

  @override
  String toString() => 'OrderException(${code.name})';
}

OrderErrorCode parseOrderError(String message) {
  final m = message.toUpperCase();
  if (m.contains('SOLD_OUT')) return OrderErrorCode.soldOut;
  if (m.contains('OFFER_UNAVAILABLE') || m.contains('OFFER_NOT_FOUND')) {
    return OrderErrorCode.offerUnavailable;
  }
  if (m.contains('MAX_RESERVATIONS')) return OrderErrorCode.maxReservations;
  if (m.contains('CANCEL_WINDOW_CLOSED')) {
    return OrderErrorCode.cancelWindowClosed;
  }
  if (m.contains('NOT_CANCELLABLE') || m.contains('NOT_RESERVED')) {
    return OrderErrorCode.notCancellable;
  }
  if (m.contains('HAS_LIVE_PAYMENT')) return OrderErrorCode.paymentInProgress;
  if (m.contains('NOT_OWNER')) return OrderErrorCode.notOwner;
  if (m.contains('NOT_AUTHENTICATED')) return OrderErrorCode.notAuthenticated;
  if (m.contains('NOT_MERCHANT')) return OrderErrorCode.notMerchant;
  if (m.contains('CODE_NOT_FOUND')) return OrderErrorCode.codeNotFound;
  if (m.contains('PICKUP_EXPIRED')) return OrderErrorCode.pickupExpired;
  return OrderErrorCode.unknown;
}
