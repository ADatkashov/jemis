import 'package:intl/intl.dart';

/// Money is integer minor units (tiyn). No floating point is used for amounts.
String formatMoney(int minor, String locale) {
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final wholeStr = NumberFormat.decimalPattern(locale).format(whole);
  final fracStr = frac == 0 ? '' : ',${frac.toString().padLeft(2, '0')}';
  return '${negative ? '−' : ''}$wholeStr$fracStr ₸';
}

/// Quantities are integer milli-units (1000 = 1 piece / 1 kg / 1 l).
String formatQuantity(int milli, String locale) {
  final whole = milli ~/ 1000;
  final frac = milli % 1000;
  if (frac == 0) return NumberFormat.decimalPattern(locale).format(whole);
  final decimals = frac.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '');
  final sep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  return '$whole$sep$decimals';
}

/// Parses a user-entered amount in tenge ("1 290,50") into minor units, or null when invalid.
int? parseMoneyInput(String input) {
  final s = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  return int.parse(parts[0]) * 100 + int.parse((parts.length > 1 ? parts[1] : '').padRight(2, '0'));
}
