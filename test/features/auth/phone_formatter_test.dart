import 'package:flutter_test/flutter_test.dart';

import 'package:barakali/features/auth/presentation/utils/phone_formatter.dart';

String _format(String input) {
  return UzbekPhoneFormatter()
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: input))
      .text;
}

void main() {
  group('UzbekPhoneFormatter', () {
    test('groups 9 digits as XX YYY YY YY', () {
      expect(_format('901234567'), '90 123 45 67');
    });

    test('strips a pasted +998 country code', () {
      expect(_format('+998901234567'), '90 123 45 67');
      expect(_format('998 90 123 45 67'), '90 123 45 67');
    });

    test('truncates to the 9-digit local part', () {
      expect(_format('9012345678901'), '90 123 45 67');
    });

    test('keeps a 9-digit local number that happens to start with 998', () {
      expect(_format('998765432'), '99 876 54 32');
    });

    test('drops non-digit characters', () {
      expect(_format('90-123-45-67'), '90 123 45 67');
    });
  });

  group('phone helpers', () {
    test('toE164 prefixes +998 and strips formatting', () {
      expect(toE164('90 123 45 67'), '+998901234567');
    });

    test('maskPhone hides all but the last two digits', () {
      expect(maskPhone('+998901234567'), '+998 ** *** ** 67');
    });

    test('isValidUzbekPhone requires exactly 9 digits', () {
      expect(isValidUzbekPhone('90 123 45 67'), isTrue);
      expect(isValidUzbekPhone('90 123 45 6'), isFalse);
    });
  });
}
