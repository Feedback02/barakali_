import 'package:flutter/services.dart';

class UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // Tolerate pasting a full number: drop a leading 998 country code and
    // truncate to the 9-digit local part instead of rejecting the whole paste.
    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String toE164(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  return '+998$digits';
}

String maskPhone(String e164) {
  if (e164.length < 4) return e164;
  final last2 = e164.substring(e164.length - 2);
  return '+998 ** *** ** $last2';
}

bool isValidUzbekPhone(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  return digits.length == 9;
}
