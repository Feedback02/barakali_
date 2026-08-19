import 'package:flutter/material.dart';

/// Groups an integer with thin spaces every 3 digits, e.g. 85000 -> "85 000".
/// Used for UZS amounts (integer, no minor unit).
String groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// "Jun 10, 18:00 – 20:00" (end date omitted when the window is same-day),
/// localized + in the device's local time zone. Stored times are UTC.
///
/// Uses the short month-day (no weekday) so the string stays readable inside a
/// card — the verbose weekday form ("Mon, Jun 29, …") overran and ellipsized,
/// especially for windows that cross midnight (two dates shown).
String formatPickupWindow(BuildContext context, DateTime start, DateTime end) {
  final mat = MaterialLocalizations.of(context);
  final s = start.toLocal();
  final e = end.toLocal();
  final startStr =
      '${mat.formatShortMonthDay(s)}, ${TimeOfDay.fromDateTime(s).format(context)}';
  final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
  final endStr = sameDay
      ? TimeOfDay.fromDateTime(e).format(context)
      : '${mat.formatShortMonthDay(e)}, ${TimeOfDay.fromDateTime(e).format(context)}';
  return '$startStr – $endStr';
}
