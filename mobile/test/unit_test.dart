import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jemis_app/core/models.dart';
import 'package:jemis_app/core/network/api_client.dart';
import 'package:jemis_app/core/util/money.dart';
import 'package:jemis_app/features/auth/presentation/auth_screens.dart';
import 'package:jemis_app/features/catalog/data/catalog_repository.dart';

class _MemTokens extends TokenStorage {
  _MemTokens(this.a, this.r);
  String? a;
  String? r;
  @override
  Future<String?> get access async => a;
  @override
  Future<String?> get refresh async => r;
  @override
  Future<void> save(String access, String refresh) async {
    a = access;
    r = refresh;
  }

  @override
  Future<void> clear() async {
    a = null;
    r = null;
  }
}

/// Scripted HTTP adapter: returns queued responses in order.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.script);
  final List<(int, Map<String, dynamic>)> script;
  final requests = <String>[];
  final auth = <String?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? body, Future<void>? cancel) async {
    requests.add('${o.method} ${o.path}');
    auth.add(o.headers['Authorization'] as String?);
    final (status, json) = script.removeAt(0);
    return ResponseBody.fromString(jsonEncode(json), status, headers: {Headers.contentTypeHeader: ['application/json']});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
  });

  group('money', () {
    test('formats integer minor units without float math', () {
      expect(formatMoney(118500, 'en').replaceAll(RegExp(r'[   ]'), ' '), '1,185 ₸');
      expect(formatMoney(99050, 'en'), '990,50 ₸');
      expect(formatMoney(5, 'en'), '0,05 ₸');
      expect(formatMoney(-1000, 'en'), '−10 ₸');
    });

    test('quantities', () {
      expect(formatQuantity(1500, 'en'), '1.5');
      expect(formatQuantity(2000, 'en'), '2');
      expect(formatQuantity(250, 'en'), '0.25');
    });

    test('parseMoneyInput', () {
      expect(parseMoneyInput('1 290,50'), 129050);
      expect(parseMoneyInput('790'), 79000);
      expect(parseMoneyInput('0.1'), 10);
      expect(parseMoneyInput('12.345'), isNull);
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('-5'), isNull);
    });
  });

  group('validators', () {
    test('required / email / phone / password', () {
      expect(Validators.required('  ', 'x'), 'x');
      expect(Validators.required('a', 'x'), isNull);
      expect(Validators.isEmail('a@b.kz'), isTrue);
      expect(Validators.isEmail('a@b'), isFalse);
      expect(Validators.isPhone('+7 (700) 123-45-67'), isTrue);
      expect(Validators.isPhone('12345'), isFalse);
      expect(Validators.isStrongEnough('1234567'), isFalse);
      expect(Validators.isStrongEnough('12345678'), isTrue);
    });
  });

  group('models', () {
    test('Quote parses server totals and reports blocking issues', () {
      final q = Quote.fromJson({
        'lines': [
          {'productId': 'p', 'name': 'Bananas', 'unit': 'KG', 'weighted': true, 'stepMilli': 500, 'unitPriceMinor': 79000, 'quantityMilli': 1500, 'lineTotalMinor': 118500, 'available': true, 'availableMilli': 5000}
        ],
        'subtotalMinor': 118500,
        'discountMinor': 0,
        'deliveryFeeMinor': 99000,
        'serviceFeeMinor': 0,
        'totalMinor': 217500,
        'minOrderMinor': 300000,
        'deliveryEstimated': false,
        'issues': ['MIN_ORDER_NOT_MET'],
      });
      expect(q.totalMinor, 217500);
      expect(q.quantityOf('p'), 1500);
      expect(q.quantityOf('x'), 0);
      expect(q.checkoutBlocked, isTrue);
    });

    test('Product first-add quantity respects the step', () {
      expect(const Product(id: '1', sku: 's', name: 'n', unit: 'KG', weighted: true, stepMilli: 500, priceMinor: 1, available: true, availableMilli: 1, lowStock: false).initialQuantityMilli, 1000);
      expect(const Product(id: '1', sku: 's', name: 'n', unit: 'KG', weighted: true, stepMilli: 1500, priceMinor: 1, available: true, availableMilli: 1, lowStock: false).initialQuantityMilli, 1500);
    });

    test('ProductFilter builds backend query and compares by value', () {
      const f = ProductFilter(query: ' milk ', categoryId: 'c', sort: 'price_asc', minPriceMinor: 100, inStock: true);
      final q = f.toQuery(2, 20);
      expect(q['q'], 'milk');
      expect(q['categoryId'], 'c');
      expect(q['minPrice'], 100);
      expect(q['inStock'], true);
      expect(q.containsKey('discounted'), isFalse);
      expect(f, const ProductFilter(query: ' milk ', categoryId: 'c', sort: 'price_asc', minPriceMinor: 100, inStock: true));
      expect(f.copyWith(categoryId: null).categoryId, isNull);
    });
  });

  group('localization files', () {
    test('ru, kk and en define exactly the same keys', () {
      Map<String, dynamic> load(String l) => jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
      Set<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();
      final ru = keys(load('ru'));
      expect(keys(load('kk')), ru);
      expect(keys(load('en')), ru);
      for (final l in ['ru', 'kk', 'en']) {
        for (final e in load(l).entries.where((e) => !e.key.startsWith('@'))) {
          expect((e.value as String).trim(), isNotEmpty, reason: '$l:${e.key}');
        }
      }
    });
  });

  group('api client', () {
    ApiClient make(_MemTokens t, _Adapter a, {void Function()? onExpired}) {
      final dio = Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = a;
      return ApiClient(tokens: t, language: () => 'kk', onSessionExpired: onExpired ?? () {}, dio: dio);
    }

    test('maps backend errors to stable codes', () async {
      final a = _Adapter([(409, {'code': 'SLOT_FULL', 'message': 'full'})]);
      final c = make(_MemTokens(null, null), a);
      try {
        await c.get('/x');
        fail('expected exception');
      } on AppException catch (e) {
        expect(e.code, 'SLOT_FULL');
        expect(e.status, 409);
      }
    });

    test('401 triggers one token refresh and the request is retried with the new token', () async {
      final a = _Adapter([
        (401, {'code': 'UNAUTHORIZED'}),
        (200, {'accessToken': 'new-access', 'refreshToken': 'new-refresh', 'expiresInSeconds': 900}),
        (200, {'ok': true}),
      ]);
      final t = _MemTokens('old-access', 'old-refresh');
      final c = make(t, a);
      final r = await c.get('/cart');
      expect((r as Map)['ok'], true);
      expect(a.requests, ['GET /cart', 'POST /auth/refresh', 'GET /cart']);
      expect(a.auth.last, 'Bearer new-access');
      expect(t.r, 'new-refresh');
    });

    test('a rejected refresh ends the session', () async {
      var expired = false;
      final a = _Adapter([
        (401, {'code': 'UNAUTHORIZED'}),
        (401, {'code': 'INVALID_REFRESH_TOKEN', 'message': 'x'}),
      ]);
      final t = _MemTokens('a', 'r');
      final c = make(t, a, onExpired: () => expired = true);
      await expectLater(c.get('/cart'), throwsA(isA<AppException>()));
      expect(expired, isTrue);
      expect(t.a, isNull);
    });
  });
}
