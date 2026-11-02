import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jemis_admin/app/providers.dart';
import 'package:jemis_admin/core/network/api_client.dart';
import 'package:jemis_admin/core/network/session_store.dart';
import 'package:jemis_admin/core/network/token_storage.dart';
import 'package:jemis_admin/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Handler = dynamic Function(String method, String path, Object? body, Map<String, dynamic>? query);

/// ApiClient whose transport is a plain function: no sockets, every call is recorded for assertions.
class FakeApi extends ApiClient {
  FakeApi(this.handler, {TokenStorage? tokens}) : super(tokens: tokens ?? TokenStorage(MemorySessionStore()), onSessionExpired: () {}, baseUrl: 'http://test');

  final Handler handler;
  final calls = <String>[];
  final bodies = <String, Object?>{};
  final queries = <String, Map<String, dynamic>?>{};

  @override
  Future<dynamic> request(String method, String path, {Object? body, Map<String, dynamic>? query}) async {
    final key = '$method $path';
    calls.add(key);
    bodies[key] = body;
    queries[key] = query;
    final r = handler(method, path, body, query);
    if (r is AppException) throw r;
    return r;
  }

  int count(String call) => calls.where((c) => c == call).length;
}

/// Unsigned JWT with a role claim: the app only decodes the payload for display.
String jwt(String role) {
  String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b64({'alg': 'none'})}.${b64({'role': role})}.sig';
}

Map<String, dynamic> page(List<Map<String, dynamic>> items, {int pageNo = 0, int totalPages = 1}) =>
    {'items': items, 'page': pageNo, 'size': 25, 'totalElements': items.length, 'totalPages': totalPages};

Future<void> initLocales() async {
  await initializeDateFormatting('ru');
  await initializeDateFormatting('kk');
  await initializeDateFormatting('en');
}

Future<List<Override>> baseOverrides(FakeApi api, {String? lang}) async {
  SharedPreferences.setMockInitialValues({'locale': ?lang});
  final prefs = await SharedPreferences.getInstance();
  return [apiClientProvider.overrideWithValue(api), sharedPrefsProvider.overrideWithValue(prefs), tokenStorageProvider.overrideWithValue(api.tokens)];
}

/// Pumps [page] at desktop width inside a router (so `context.go` works); `/orders/:id` renders a marker.
Future<void> pumpPage(WidgetTester tester, Widget page, FakeApi api, {String? lang, Size size = const Size(1400, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final overrides = await baseOverrides(api, lang: lang);
  final router = GoRouter(initialLocation: '/page', routes: [
    GoRoute(path: '/page', builder: (_, _) => Scaffold(body: page)),
    GoRoute(path: '/orders/:id', builder: (_, s) => Scaffold(body: Text('order-detail-${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        locale: ref.watch(localeProvider),
        supportedLocales: supportedLocales,
        localizationsDelegates: const [AppL10n.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        routerConfig: router,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Types into the text field that sits under [fieldKey] or has the given label.
Future<void> enter(WidgetTester tester, Finder f, String text) async {
  await tester.ensureVisible(f);
  await tester.enterText(f, text);
  await tester.pump();
}

Finder labeled(String label) => find.widgetWithText(TextFormField, label);

/// Finds Text widgets whose content (with no-break spaces normalised) contains [s]; money/grouping uses NBSP.
Finder textLike(String s) => find.byWidgetPredicate((w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').replaceAll(RegExp('[  ]'), ' ').contains(s));
