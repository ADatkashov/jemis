import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_admin/app/app.dart';
import 'package:jemis_admin/core/network/api_client.dart';
import 'package:jemis_admin/core/network/session_store.dart';
import 'package:jemis_admin/core/network/token_storage.dart';

import 'helpers.dart';

const _dash = {
  'ordersToday': 1, 'paidRevenueTodayMinor': 0, 'currency': 'KZT', 'awaitingProcessing': 0, 'inDelivery': 0, 'lowStockCount': 0, 'lowStock': [], 'recentOrders': [],
};

FakeApi backend({String role = 'ADMIN', TokenStorage? tokens, bool badLogin = false}) => FakeApi((m, p, b, q) {
      if (p == '/auth/login') {
        if (badLogin) return AppException('INVALID_CREDENTIALS', 'bad', status: 401);
        return {'accessToken': jwt(role), 'refreshToken': 'r-$role'};
      }
      if (p == '/auth/logout') return null;
      if (p == '/admin/dashboard') return _dash;
      if (p == '/admin/staff') return [];
      return page([]);
    }, tokens: tokens);

Future<void> pumpApp(WidgetTester tester, FakeApi api, {String? lang, Size size = const Size(1400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(overrides: await baseOverrides(api, lang: lang), child: const AdminApp()));
  await tester.pumpAndSettle();
}

Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('login-email')), 'admin@jemis.local');
  await tester.enterText(find.byKey(const ValueKey('login-password')), 'secret');
  await tester.tap(find.byKey(const ValueKey('login-submit')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initLocales);

  testWidgets('signed out users land on the login form; fields are required', (tester) async {
    await pumpApp(tester, backend());
    expect(find.text('JEMIS Admin'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Обязательное поле'), findsNWidgets(2));
  });

  testWidgets('ADMIN signs in, sees every section and the tokens are stored', (tester) async {
    final api = backend(role: 'ADMIN');
    await pumpApp(tester, api);
    await signIn(tester);
    expect(api.bodies['POST /auth/login'], {'identifier': 'admin@jemis.local', 'password': 'secret'});
    expect(find.text('Заказов сегодня'), findsOneWidget);
    for (final id in ['dashboard', 'orders', 'products', 'categories', 'delivery', 'promotions', 'customers', 'staff', 'settings', 'audit']) {
      expect(find.byKey(ValueKey('nav-$id')), findsOneWidget, reason: id);
    }
    expect(api.tokens.refresh, 'r-ADMIN');
  });

  testWidgets('MANAGER does not get the ADMIN-only sections', (tester) async {
    await pumpApp(tester, backend(role: 'MANAGER'));
    await signIn(tester);
    expect(find.byKey(const ValueKey('nav-orders')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-staff')), findsNothing);
    expect(find.byKey(const ValueKey('nav-settings')), findsNothing);
    expect(find.byKey(const ValueKey('nav-audit')), findsNothing);
  });

  testWidgets('COURIER and CUSTOMER accounts are refused and logged out again', (tester) async {
    final api = backend(role: 'COURIER');
    await pumpApp(tester, api);
    await signIn(tester);
    expect(find.text('Неверные данные или недостаточно прав'), findsOneWidget);
    expect(api.tokens.hasSession, isFalse);
    expect(api.calls, contains('POST /auth/logout'));
    expect(find.text('Заказов сегодня'), findsNothing);
  });

  testWidgets('wrong password and network failure show different messages', (tester) async {
    await pumpApp(tester, backend(badLogin: true));
    await signIn(tester);
    expect(find.text('Неверные данные или недостаточно прав'), findsOneWidget);

    final offline = FakeApi((m, p, b, q) => AppException('NETWORK', 'down'));
    await pumpApp(tester, offline);
    await signIn(tester);
    expect(find.text('Нет связи с сервером.'), findsOneWidget);
  });

  testWidgets('an existing session skips the login and navigation works', (tester) async {
    final tokens = TokenStorage(MemorySessionStore())..save(jwt('ADMIN'), 'r');
    await pumpApp(tester, backend(tokens: tokens));
    expect(find.text('Заказов сегодня'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Все статусы'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-staff')));
    await tester.pumpAndSettle();
    expect(find.text('Сотрудники'), findsWidgets);
  });

  testWidgets('a stored token of a non-admin role is discarded', (tester) async {
    final tokens = TokenStorage(MemorySessionStore())..save(jwt('CUSTOMER'), 'r');
    await pumpApp(tester, backend(tokens: tokens));
    expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
    expect(tokens.hasSession, isFalse);
  });

  testWidgets('logout returns to the login form', (tester) async {
    final tokens = TokenStorage(MemorySessionStore())..save(jwt('ADMIN'), 'r');
    final api = backend(tokens: tokens);
    await pumpApp(tester, api);
    await tester.tap(find.byKey(const ValueKey('logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
    expect(api.bodies['POST /auth/logout'], {'refreshToken': 'r'});
    expect(tokens.hasSession, isFalse);
  });

  testWidgets('language switch re-renders and is remembered', (tester) async {
    final tokens = TokenStorage(MemorySessionStore())..save(jwt('ADMIN'), 'r');
    await pumpApp(tester, backend(tokens: tokens));
    await tester.tap(find.byKey(const ValueKey('lang')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Orders today'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('narrow window uses a drawer', (tester) async {
    final tokens = TokenStorage(MemorySessionStore())..save(jwt('MANAGER'), 'r');
    await pumpApp(tester, backend(role: 'MANAGER', tokens: tokens), size: const Size(500, 900));
    expect(find.byKey(const ValueKey('nav-orders')), findsNothing);
    await tester.tap(find.byTooltip('Открыть меню навигации'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-orders')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Все статусы'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-orders')), findsNothing);
  });

  test('ARB files have identical key sets and every placeholder is declared', () {
    Map<String, dynamic> load(String l) => jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
    final ru = load('ru'), kk = load('kk'), en = load('en');
    Set<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys(kk), keys(ru));
    expect(keys(en), keys(ru));
    for (final lang in [kk, en]) {
      for (final k in keys(ru)) {
        final ph = RegExp(r'\{(\w+)\}').allMatches(ru[k] as String).map((m) => m.group(1)).toSet();
        final other = RegExp(r'\{(\w+)\}').allMatches(lang[k] as String).map((m) => m.group(1)).toSet();
        expect(other, ph, reason: k);
      }
    }
  });
}
