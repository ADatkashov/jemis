import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_app/app/providers.dart';
import 'package:jemis_app/app/router.dart';
import 'package:jemis_app/core/models.dart';
import 'package:jemis_app/features/auth/presentation/auth_screens.dart';
import 'package:jemis_app/features/checkout/presentation/checkout_screen.dart';
import 'package:jemis_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<ProviderContainer> pumpRouter(WidgetTester tester, Profile? profile) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    authProvider.overrideWith(() => FakeAuth(profile)),
    cartProvider.overrideWith(() => FakeCart(profile == null ? null : quote([]))),
    homeProvider.overrideWith((ref) async => const HomeFeed(banners: [], categories: [], popular: [], fresh: [], discounted: [])),
    addressesProvider.overrideWith(() => _FakeAddresses()),
    availabilityProvider.overrideWith((ref) async => const Availability('Asia/Almaty', false, [])),
    paymentMethodsProvider.overrideWith((ref) async => [const PayMethod('CASH', 'cod', false)]),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: Consumer(builder: (context, ref, _) => MaterialApp.router(
          locale: const Locale('ru'),
          routerConfig: ref.watch(routerProvider),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [AppL10n.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        )),
  ));
  await tester.pumpAndSettle();
  return container;
}

class _FakeAddresses extends AddressesNotifier {
  @override
  Future<List<Address>> build() async => const [];
}

void main() {
  testWidgets('signed-out users opening checkout are sent to login (session guard)', (tester) async {
    final c = await pumpRouter(tester, null);
    c.read(routerProvider).go('/checkout');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CheckoutScreen), findsNothing);
  });

  testWidgets('signed-in users reach checkout and see the address step', (tester) async {
    final c = await pumpRouter(tester, demoProfile);
    c.read(routerProvider).go('/checkout');
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.text('Добавьте адрес доставки'), findsOneWidget);
    // placing an order is impossible without address and slot
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
  });

  testWidgets('signed-in users are redirected away from the login screen', (tester) async {
    final c = await pumpRouter(tester, demoProfile);
    c.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('bottom navigation exposes the four main destinations and switches tabs', (tester) async {
    await pumpRouter(tester, demoProfile);
    for (final label in ['Главная', 'Каталог', 'Корзина', 'Профиль']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(find.text('Мои заказы'), findsOneWidget);
  });

  testWidgets('login form validates input before calling the server', (tester) async {
    await tester.pumpWidget(testApp(const LoginScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(null))]));
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pump();
    expect(find.text('Обязательное поле'), findsNWidgets(2));
  });

  testWidgets('register form requires a strong password and a valid email', (tester) async {
    await tester.pumpWidget(testApp(const RegisterScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(null))]));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Name');
    await tester.enterText(fields.at(1), 'not-an-email');
    await tester.enterText(fields.at(3), 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Регистрация'));
    await tester.pump();
    expect(find.text('Некорректный email'), findsOneWidget);
    expect(find.text('Минимум 8 символов'), findsOneWidget);
  });
}
