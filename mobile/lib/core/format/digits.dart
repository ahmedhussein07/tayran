/// Numerals and phone formatting. Arabic UI shows Arabic-Indic digits (٠١٢٣); English shows Western.
abstract final class Digits {
  static const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Replaces Western digits with Arabic-Indic ones when [arabic] is true.
  static String localize(String value, {required bool arabic}) {
    if (!arabic) return value;
    final sb = StringBuffer();
    for (final unit in value.codeUnits) {
      sb.write(unit >= 0x30 && unit <= 0x39 ? _arabicIndic[unit - 0x30] : String.fromCharCode(unit));
    }
    return sb.toString();
  }

  /// Turns Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits into Western ones.
  static String toWestern(String value) {
    final sb = StringBuffer();
    for (final unit in value.codeUnits) {
      if (unit >= 0x0660 && unit <= 0x0669) {
        sb.writeCharCode(0x30 + unit - 0x0660);
      } else if (unit >= 0x06F0 && unit <= 0x06F9) {
        sb.writeCharCode(0x30 + unit - 0x06F0);
      } else {
        sb.writeCharCode(unit);
      }
    }
    return sb.toString();
  }

  /// "0:30"-style countdown.
  static String clock(int totalSeconds, {required bool arabic}) {
    final m = totalSeconds ~/ 60;
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return localize('$m:$s', arabic: arabic);
  }
}

/// Egyptian mobile numbers, as the app holds them: the 10 digits after +20 ("1012345678").
abstract final class EgyptPhone {
  static final _valid = RegExp(r'^1[0125]\d{8}$');

  /// Extracts the national digits from whatever was typed or pasted:
  /// Arabic or Western digits, a leading 0 ("010…"), "+20…" or "0020…". Cut to 10 digits.
  static String digits(String raw) {
    var d = Digits.toWestern(raw).replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0020')) {
      d = d.substring(4);
    } else if (d.startsWith('20') && d.length > 10) {
      d = d.substring(2);
    }
    if (d.startsWith('0')) d = d.substring(1);
    return d.length > 10 ? d.substring(0, 10) : d;
  }

  /// 10 digits starting 10, 11, 12 or 15.
  static bool isValid(String digits) => _valid.hasMatch(digits);

  /// Groups 2-4-4 as typed: "10 1234 5678".
  static String group(String digits) {
    final parts = <String>[];
    for (final (start, end) in const [(0, 2), (2, 6), (6, 10)]) {
      if (digits.length > start) parts.add(digits.substring(start, digits.length < end ? digits.length : end));
    }
    return parts.join(' ');
  }

  /// E.164 for the API: "+201012345678".
  static String e164(String digits) => '+20$digits';

  /// The local form people recognise: "01012345678".
  static String local(String digits) => '0$digits';
}
