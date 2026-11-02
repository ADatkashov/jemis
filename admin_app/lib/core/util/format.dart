import 'package:intl/intl.dart';

/// Money is integer minor units (tiyn); quantities are integer milli-units. No floating point math on money.
String formatMoney(int minor, String locale, {String currency = 'KZT'}) {
  final sign = minor < 0 ? '-' : '';
  final abs = minor.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final wholeStr = NumberFormat.decimalPattern(locale).format(whole);
  final symbol = currency == 'KZT' ? '₸' : currency;
  return '$sign$wholeStr${frac == 0 ? '' : ',${frac.toString().padLeft(2, '0')}'} $symbol';
}

/// Parses a user-entered amount like "1 290,50" into minor units; null if invalid.
int? parseMoney(String input) {
  final s = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  return int.parse(parts[0]) * 100 + int.parse((parts.length > 1 ? parts[1] : '').padRight(2, '0'));
}

/// Minor units back into the text a user would type ("1290" or "1290,50").
String moneyToInput(int minor) {
  final whole = minor ~/ 100;
  final frac = minor % 100;
  return frac == 0 ? '$whole' : '$whole,${frac.toString().padLeft(2, '0')}';
}

String formatQuantity(int milli, String locale) {
  final whole = milli ~/ 1000;
  final frac = milli % 1000;
  if (frac == 0) return '$whole';
  final decimals = frac.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '');
  final sep = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  return '$whole$sep$decimals';
}

/// Parses "1,5" / "0.25" into milli-units; null if invalid (more than 3 decimals, negative, not a number).
int? parseQuantity(String input) {
  final s = input.replaceAll(',', '.').trim();
  if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  return int.parse(parts[0]) * 1000 + int.parse((parts.length > 1 ? parts[1] : '').padRight(3, '0'));
}

/// Signed stock adjustment such as "10" or "-2.5" into milli-units; null if invalid or zero.
int? parseSignedQuantity(String input) {
  final t = input.trim();
  final negative = t.startsWith('-');
  final d = parseQuantity(negative ? t.substring(1) : t);
  if (d == null || d == 0) return null;
  return negative ? -d : d;
}

String formatDateTime(DateTime dt, String locale) => DateFormat.yMd(locale).add_Hm().format(dt.toLocal());

DateTime? tryParseDateTime(String? iso) => iso == null ? null : DateTime.tryParse(iso);
