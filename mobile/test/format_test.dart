import 'package:flutter_test/flutter_test.dart';
import 'package:tayran_ui/tayran_ui.dart';
import 'package:tayran/core/widgets/picker_sheet.dart';

void main() {
  group('EgyptPhone.digits', () {
    test('accepts what people type and paste', () {
      expect(EgyptPhone.digits('01012345678'), '1012345678');
      expect(EgyptPhone.digits('+20 10 1234 5678'), '1012345678');
      expect(EgyptPhone.digits('00201512345678'), '1512345678');
      expect(EgyptPhone.digits('٠١٠١٢٣٤٥٦٧٨'), '1012345678');
      expect(EgyptPhone.digits('١٠ ١٢٣٤'), '101234');
    });

    test('cuts to 10 digits', () {
      expect(EgyptPhone.digits('101234567899'), '1012345678');
    });
  });

  group('EgyptPhone.isValid', () {
    test('only 010, 011, 012, 015 mobiles', () {
      for (final ok in [
        '1012345678',
        '1112345678',
        '1212345678',
        '1512345678',
      ]) {
        expect(EgyptPhone.isValid(ok), isTrue, reason: ok);
      }
      for (final bad in ['1312345678', '101234567', '2012345678', '']) {
        expect(EgyptPhone.isValid(bad), isFalse, reason: bad);
      }
    });
  });

  test('groups 2-4-4 as typed', () {
    expect(EgyptPhone.group('1'), '1');
    expect(EgyptPhone.group('101'), '10 1');
    expect(EgyptPhone.group('1012345'), '10 1234 5');
    expect(EgyptPhone.group('1012345678'), '10 1234 5678');
  });

  test('Arabic-Indic digits in Arabic, Western in English', () {
    expect(Digits.localize('+20 10', arabic: true), '+٢٠ ١٠');
    expect(Digits.localize('+20 10', arabic: false), '+20 10');
    expect(Digits.clock(30, arabic: true), '٠:٣٠');
  });

  test('Arabic search folding', () {
    expect(foldArabic('منية النصر').contains(foldArabic('منيه')), isTrue);
    expect(foldArabic('أبو'), foldArabic('ابو'));
    expect(foldArabic('كفر الياسمين'), contains(foldArabic('ياسمين')));
  });
}
