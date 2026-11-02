import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_admin/core/util/format.dart';

String nb(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

void main() {
  group('money', () {
    test('formats minor units without floating point', () {
      expect(nb(formatMoney(118500, 'ru')), '1 185 ₸');
      expect(nb(formatMoney(99050, 'ru')), '990,50 ₸');
      expect(nb(formatMoney(5, 'ru', currency: 'KZT')), '0,05 ₸');
    });

    test('formats negatives and other currencies', () {
      expect(nb(formatMoney(-250, 'ru')), '-2,50 ₸');
      expect(nb(formatMoney(100, 'en', currency: 'USD')), '1 USD');
      expect(nb(formatMoney(123456789, 'en')), '1,234,567,89 ₸');
    });

    test('parses user input into minor units', () {
      expect(parseMoney('1 290,50'), 129050);
      expect(parseMoney('790'), 79000);
      expect(parseMoney('0.1'), 10);
      expect(parseMoney('12.345'), isNull);
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('-5'), isNull);
      expect(parseMoney(''), isNull);
    });

    test('moneyToInput is the inverse of parseMoney', () {
      expect(moneyToInput(129050), '1290,50');
      expect(moneyToInput(79000), '790');
      expect(moneyToInput(5), '0,05');
      for (final v in [0, 5, 10, 99, 100, 129050]) {
        expect(parseMoney(moneyToInput(v)), v);
      }
    });
  });

  group('quantity', () {
    test('round-trips milli-units', () {
      expect(formatQuantity(1500, 'en'), '1.5');
      expect(formatQuantity(2000, 'en'), '2');
      expect(formatQuantity(250, 'en'), '0.25');
      expect(formatQuantity(1500, 'ru'), '1,5');
      expect(parseQuantity('1,5'), 1500);
      expect(parseQuantity('0.25'), 250);
      expect(parseQuantity('1.2345'), isNull);
      expect(parseQuantity('-1'), isNull);
    });

    test('signed adjustments', () {
      expect(parseSignedQuantity('10'), 10000);
      expect(parseSignedQuantity('-2.5'), -2500);
      expect(parseSignedQuantity(' -0,25 '), -250);
      expect(parseSignedQuantity('0'), isNull);
      expect(parseSignedQuantity('x'), isNull);
      expect(parseSignedQuantity('--1'), isNull);
    });
  });
}
