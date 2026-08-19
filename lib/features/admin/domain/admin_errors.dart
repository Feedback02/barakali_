/// Expected failures from the admin moderation RPCs (approve/reject/
/// set_merchant_active). The server RAISEs these as bare uppercase tokens;
/// [parseAdminError] maps the message to a code so the console can show a
/// localized string (never the raw DB message). [notAdmin] should never reach
/// a seeded admin — it's the defense-in-depth signal that the caller's token
/// is not actually an admin (the real gate, not the hidden UI).
enum AdminErrorCode {
  notAdmin,
  coordsRequired,
  noteRequired,
  notApproved,
  merchantNotFound,
  notRefundable,
  unknown,
}

class AdminException implements Exception {
  const AdminException(this.code);

  final AdminErrorCode code;

  @override
  String toString() => 'AdminException(${code.name})';
}

AdminErrorCode parseAdminError(String message) {
  final m = message.toUpperCase();
  if (m.contains('NOT_ADMIN')) return AdminErrorCode.notAdmin;
  if (m.contains('COORDS_REQUIRED')) return AdminErrorCode.coordsRequired;
  if (m.contains('NOTE_REQUIRED')) return AdminErrorCode.noteRequired;
  if (m.contains('NOT_APPROVED')) return AdminErrorCode.notApproved;
  if (m.contains('MERCHANT_NOT_FOUND')) return AdminErrorCode.merchantNotFound;
  if (m.contains('NOT_REFUNDABLE') || m.contains('ORDER_NOT_FOUND')) {
    return AdminErrorCode.notRefundable;
  }
  return AdminErrorCode.unknown;
}
