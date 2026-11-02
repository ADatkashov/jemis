import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_admin/app/nav.dart';
import 'package:jemis_admin/app/providers.dart';
import 'package:jemis_admin/app/router.dart';
import 'package:jemis_admin/core/form_result.dart';
import 'package:jemis_admin/core/network/api_client.dart';
import 'package:jemis_admin/core/network/session_store.dart';
import 'package:jemis_admin/core/network/token_storage.dart';
import 'package:jemis_admin/core/util/jwt.dart';
import 'package:jemis_admin/features/delivery/data/delivery_repository.dart';
import 'package:jemis_admin/features/orders/data/orders_repository.dart';
import 'package:jemis_admin/features/products/data/catalog_admin_repository.dart';
import 'package:jemis_admin/features/promotions/data/promotions_repository.dart';
import 'package:jemis_admin/features/settings/presentation/settings_page.dart';
import 'package:jemis_admin/features/staff/data/staff_repository.dart';

import 'helpers.dart';

void main() {
  group('jwt', () {
    test('reads the role claim, tolerates garbage', () {
      expect(roleFromToken(jwt('ADMIN')), 'ADMIN');
      expect(roleFromToken('abc'), isNull);
      expect(roleFromToken('a.!!!.c'), isNull);
      expect(roleFromToken(null), isNull);
      expect(canUseAdmin('MANAGER'), isTrue);
      expect(canUseAdmin('COURIER'), isFalse);
      expect(canUseAdmin(null), isFalse);
      expect(isAdminOnly('MANAGER'), isFalse);
    });
  });

  group('navigation', () {
    test('ADMIN-only entries are hidden from managers', () {
      expect(navItemsFor('ADMIN').map((i) => i.id), containsAll(['staff', 'settings', 'audit']));
      expect(navItemsFor('MANAGER').map((i) => i.id), ['dashboard', 'orders', 'products', 'categories', 'delivery', 'promotions', 'customers']);
    });

    test('nested paths belong to their section', () {
      expect(navItemFor('/')!.id, 'dashboard');
      expect(navItemFor('/orders/abc')!.id, 'orders');
      expect(navItemFor('/orders')!.id, 'orders');
      expect(navItemFor('/ordersx'), isNull);
      expect(navItemFor('/nope'), isNull);
    });

    test('redirects', () {
      const none = AuthState.signedOut;
      const manager = AuthState(role: 'MANAGER');
      const admin = AuthState(role: 'ADMIN');
      expect(redirectFor('/orders', none), '/login');
      expect(redirectFor('/login', none), isNull);
      expect(redirectFor('/login', manager), '/');
      expect(redirectFor('/orders/1', manager), isNull);
      expect(redirectFor('/staff', manager), '/');
      expect(redirectFor('/audit', manager), '/');
      expect(redirectFor('/staff', admin), isNull);
      expect(redirectFor('/unknown', admin), '/');
    });
  });

  group('validation', () {
    ProductInput product({String price = '1 290,50', String old = '', String step = '1000'}) => ProductInput(
        categoryId: 'c1', sku: ' S1 ', nameRu: 'Яблоко', nameKk: 'Алма', nameEn: 'Apple', priceText: price, oldPriceText: old, stepText: step, brand: ' ');

    test('product body in minor units, blank optionals become null', () {
      final b = product().toBody().value!;
      expect(b['priceMinor'], 129050);
      expect(b['oldPriceMinor'], isNull);
      expect(b['sku'], 'S1');
      expect(b['brand'], isNull);
      expect(b['stepMilli'], 1000);
    });

    test('product price rules', () {
      expect(product(price: 'abc').toBody().error, FormError.invalidPrice);
      expect(product(old: 'x').toBody().error, FormError.invalidPrice);
      expect(product(old: '1290,50').toBody().error, FormError.prevPriceHigher);
      expect(product(old: '1500').toBody().value!['oldPriceMinor'], 150000);
      expect(product(step: '0').toBody().error, FormError.invalidNumber);
      const empty = ProductInput(categoryId: 'c', sku: '', nameRu: '', nameKk: '', nameEn: '', priceText: '1');
      expect(empty.toBody().error, FormError.required);
    });

    test('stock adjustment needs a number and a reason', () {
      expect(validateStockAdjustment('-2.5', ' recount ').value, (delta: -2500, reason: 'recount'));
      expect(validateStockAdjustment('5', ' ').error, FormError.enterQtyReason);
      expect(validateStockAdjustment('abc', 'r').error, FormError.enterQtyReason);
    });

    test('category slug', () {
      FormResult<AdminCategory> c(String slug) => validateCategory(slug: slug, nameRu: 'а', nameKk: 'ә', nameEn: 'a');
      expect(c('fruit-and-veg').ok, isTrue);
      expect(c('Fruit').error, FormError.invalidSlug);
      expect(c('a b').error, FormError.invalidSlug);
      expect(c('').error, FormError.required);
      expect(validateCategory(slug: 'x', nameRu: 'а', nameKk: 'ә', nameEn: 'a', sortOrder: 'q').error, FormError.invalidNumber);
    });

    FormResult<Promo> promo({PromoType type = PromoType.percent, String value = '10', String max = '', String min = '0', String code = 'SAVE10', String uses = ''}) =>
        validatePromo(code: code, type: type, value: value, maxDiscount: max, minOrder: min, usageLimit: uses, stackable: false, active: true);

    test('promo percent vs fixed', () {
      expect(promo().value!.value, 10);
      expect(promo(value: '0').error, FormError.invalidNumber);
      expect(promo(value: '101').error, FormError.invalidNumber);
      final fixed = promo(type: PromoType.fixed, value: '500', max: '300', min: '1000').value!;
      expect(fixed.value, 50000);
      expect(fixed.maxDiscountMinor, 30000);
      expect(fixed.minOrderMinor, 100000);
      expect(promo(type: PromoType.fixed, value: 'x').error, FormError.invalidAmount);
      expect(promo(max: 'x').error, FormError.invalidAmount);
      expect(promo(uses: '0').error, FormError.invalidNumber);
      expect(promo(uses: '5').value!.usageLimit, 5);
      expect(promo(code: 'bad code').error, FormError.invalidPromoCode);
      expect(promo(code: ' ').error, FormError.required);
    });

    test('promo body keeps the category and serializes UTC', () {
      final r = validatePromo(
          id: 'p', categoryId: 'cat', code: 'A', type: PromoType.fixed, value: '1', maxDiscount: '', minOrder: '0', startsAt: DateTime.utc(2026, 1, 2, 3), stackable: true, active: false);
      final b = r.value!.toBody();
      expect(b['categoryId'], 'cat');
      expect(b['type'], 'FIXED');
      expect(b['startsAt'], '2026-01-02T03:00:00.000Z');
      expect(b['endsAt'], isNull);
    });

    test('zone amounts', () {
      FormResult<Zone> z({String fee = '990', String min = '0', String free = '', String name = 'Центр'}) =>
          validateZone(name: name, city: 'Алматы', fee: fee, min: min, free: free, active: true);
      expect(z().value!.feeMinor, 99000);
      expect(z().value!.freeDeliveryThresholdMinor, isNull);
      expect(z(free: '10 000').value!.freeDeliveryThresholdMinor, 1000000);
      expect(z(fee: 'x').error, FormError.invalidAmount);
      expect(z(free: 'x').error, FormError.invalidAmount);
      expect(z(name: ' ').error, FormError.required);
    });

    test('slot times, capacity and days', () {
      FormResult<Slot> s({String start = '10:00', String end = '12:00', String cap = '10', String days = '1, 2,3', String extra = '0'}) =>
          validateSlot(start: start, end: end, capacity: cap, days: days, extra: extra, active: true);
      expect(s().value!.daysOfWeek, '1,2,3');
      expect(s().value!.toBody()['startTime'], '10:00');
      expect(s(start: '25:00').error, FormError.invalidTime);
      expect(s(end: '9:5').error, FormError.invalidTime);
      expect(s(cap: '-1').error, FormError.invalidNumber);
      expect(s(days: '0,8').error, FormError.invalidDays);
      expect(s(days: '1,,2').error, FormError.invalidDays);
      expect(s(extra: 'z').error, FormError.invalidAmount);
    });

    test('staff', () {
      FormResult<Map<String, dynamic>> st({String email = 'a@b.kz', String pw = '1234567890', String phone = ''}) =>
          validateStaff(email: email, fullName: 'Айгуль', password: pw, role: 'COURIER', phone: phone);
      expect(st().value!['phone'], isNull);
      expect(st(phone: ' +7 700 000 00 00 ').value!['phone'], '+7 700 000 00 00');
      expect(st(email: 'nope').error, FormError.invalidEmail);
      expect(st(pw: '123456789').error, FormError.passwordTooShort);
      expect(st(email: '').error, FormError.required);
    });

    test('settings send only changed values', () {
      expect(changedSettings({'a': '1', 'b': '2'}, {'a': '1', 'b': '3'}), {'b': '3'});
      expect(changedSettings({'a': '1'}, {}), isEmpty);
    });
  });

  group('models', () {
    test('order detail parsing, refund and courier rules', () {
      final d = OrderDetailModel.fromJson({
        'order': {
          'id': 'o1', 'number': 'JM-1', 'status': 'READY_FOR_DELIVERY', 'paymentStatus': 'SUCCEEDED', 'paymentMethod': 'CARD', 'recipientName': 'A',
          'address': {'city': 'Алматы', 'street': 'Абая', 'house': '1'},
          'slot': {'date': '2026-11-02', 'start': '10:00:00', 'end': '12:00:00'},
          'items': [], 'timeline': [],
        },
        'payments': [], 'issues': [], 'allowedNext': ['ASSIGNED_TO_COURIER'],
      });
      expect(d.slotLabel, '2026-11-02 10:00–12:00');
      expect(d.canAssignCourier, isTrue);
      expect(d.canRefund, isFalse);
      final done = OrderDetailModel.fromJson({
        'order': {'id': 'o', 'number': 'n', 'status': 'DELIVERED', 'paymentStatus': 'SUCCEEDED', 'address': <String, dynamic>{}},
      });
      expect(done.canRefund, isTrue);
    });
  });

  group('api client', () {
    test('toException maps codes and network failures', () {
      final req = RequestOptions(path: '/x');
      final e = ApiClient.toException(DioException(requestOptions: req, response: Response(requestOptions: req, statusCode: 409, data: {'code': 'SLOT_FULL', 'message': 'full'})));
      expect((e.code, e.status, e.message), ('SLOT_FULL', 409, 'full'));
      expect(ApiClient.toException(DioException(requestOptions: req)).isNetwork, isTrue);
      expect(ApiClient.toException(DioException(requestOptions: req, response: Response(requestOptions: req, statusCode: 502, data: 'bad gateway'))).code, 'ERROR');
    });

    test('a 401 refreshes once, retries with the new token', () async {
      final tokens = TokenStorage(MemorySessionStore())..save('old', 'r1');
      final adapter = _Adapter([
        (401, {'code': 'UNAUTHORIZED'}),
        (200, {'accessToken': 'new', 'refreshToken': 'r2'}),
        (200, {'ok': true}),
      ]);
      var expired = 0;
      final api = ApiClient(tokens: tokens, onSessionExpired: () => expired++, dio: Dio(BaseOptions(baseUrl: 'http://t/api/v1'))..httpClientAdapter = adapter);
      final r = await api.get('/admin/dashboard') as Map;
      expect(r['ok'], true);
      expect(adapter.requests, ['GET /admin/dashboard', 'POST /auth/refresh', 'GET /admin/dashboard']);
      expect(adapter.auth, ['Bearer old', null, 'Bearer new']);
      expect(tokens.refresh, 'r2');
      expect(expired, 0);
    });

    test('a rejected refresh ends the session', () async {
      final tokens = TokenStorage(MemorySessionStore())..save('old', 'r1');
      final adapter = _Adapter([(401, {'code': 'UNAUTHORIZED'}), (401, {'code': 'INVALID_TOKEN'})]);
      var expired = 0;
      final api = ApiClient(tokens: tokens, onSessionExpired: () => expired++, dio: Dio(BaseOptions(baseUrl: 'http://t/api/v1'))..httpClientAdapter = adapter);
      await expectLater(api.get('/admin/orders'), throwsA(isA<AppException>().having((e) => e.isUnauthorized, 'unauthorized', true)));
      expect(tokens.hasSession, isFalse);
      expect(expired, 1);
    });

    test('token storage round-trips through the store', () {
      final store = MemorySessionStore();
      final t = TokenStorage(store)..save('a', 'b');
      expect((t.access, t.refresh, t.hasSession), ('a', 'b', true));
      t.clear();
      expect(t.hasSession, isFalse);
    });
  });
}

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
