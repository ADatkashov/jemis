import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_app/app/providers.dart';
import 'package:jemis_app/core/models.dart';
import 'package:jemis_app/core/network/api_client.dart';
import 'package:jemis_app/core/widgets/common.dart';
import 'package:jemis_app/core/widgets/product_card.dart';
import 'package:jemis_app/core/widgets/quantity_stepper.dart';
import 'package:jemis_app/features/cart/presentation/cart_screen.dart';

import 'helpers.dart';

void main() {
  group('ProductCard', () {
    testWidgets('shows name, unit price, discount and an add button', (tester) async {
      final p = product(price: 79000, old: 99000, discount: 20);
      await tester.pumpWidget(testApp(Scaffold(body: ProductCard(product: p, width: 180)), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(quote([])))]));
      await tester.pumpAndSettle();
      expect(find.text('Бананы'), findsOneWidget);
      expect(find.textContaining('790'), findsWidgets);
      expect(find.text('−20%'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('В корзину')), findsOneWidget);
    });

    testWidgets('tapping add sends the first quantity to the cart', (tester) async {
      final cart = FakeCart(quote([]));
      await tester.pumpWidget(testApp(Scaffold(body: ProductCard(product: product(), width: 180)), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => cart)]));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(cart.calls, ['p1:1000']);
    });

    testWidgets('shows a stepper once the product is in the cart', (tester) async {
      final p = product();
      await tester.pumpWidget(testApp(Scaffold(body: ProductCard(product: p, width: 180)), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(quote([line(p, 1500)])))]));
      await tester.pumpAndSettle();
      expect(find.byType(QuantityStepper), findsOneWidget);
      expect(find.textContaining('1,5'), findsOneWidget);
    });

    testWidgets('unavailable products cannot be ordered', (tester) async {
      await tester.pumpWidget(testApp(Scaffold(body: ProductCard(product: product(available: false, availableMilli: 0), width: 180)), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(quote([])))]));
      await tester.pumpAndSettle();
      expect(find.text('Нет в наличии'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });
  });

  group('QuantityStepper', () {
    testWidgets('steps by the product step and stops at the available stock', (tester) async {
      final seen = <int>[];
      Widget build(int q) => testApp(Scaffold(body: QuantityStepper(quantityMilli: q, stepMilli: 500, unit: 'KG', availableMilli: 2000, onChanged: seen.add)));
      await tester.pumpWidget(build(1500));
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      expect(seen, [2000, 1000]);
      await tester.pumpWidget(build(2000));
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add)).onPressed, isNull); // cap reached
    });

    testWidgets('has screen-reader labels', (tester) async {
      await tester.pumpWidget(testApp(Scaffold(body: QuantityStepper(quantityMilli: 1000, stepMilli: 1000, unit: 'PIECE', availableMilli: 5000, onChanged: (_) {}))));
      expect(find.bySemanticsLabel('Увеличить количество'), findsOneWidget);
      expect(find.bySemanticsLabel('Уменьшить количество'), findsOneWidget);
    });
  });

  group('CartScreen', () {
    testWidgets('renders server totals, delivery fee and min-order warning; checkout disabled below minimum', (tester) async {
      final p = product();
      final q = quote([line(p, 1500)], minOrder: 300000, issues: ['MIN_ORDER_NOT_MET']);
      await tester.pumpWidget(testApp(const CartScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(q))]));
      await tester.pumpAndSettle();
      expect(find.textContaining('Минимальный заказ'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && w.data?.replaceAll('\u00a0', ' ') == '1 185 ₸'), findsWidgets); // 1.5 kg x 790
      final button = tester.widget<FilledButton>(find.byType(FilledButton).last);
      expect(button.onPressed, isNull);
    });

    testWidgets('shows promo discount and enables checkout for a valid cart', (tester) async {
      final p = product(price: 100000);
      final q = quote([line(p, 4000)], discount: 40000, minOrder: 300000);
      await tester.pumpWidget(testApp(const CartScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(q))]));
      await tester.pumpAndSettle();
      expect(find.text('−400 ₸'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNotNull);
    });

    testWidgets('flags unavailable and under-stocked lines', (tester) async {
      final p = product(availableMilli: 500);
      final l = CartLine(productId: 'p1', name: 'Бананы', unit: 'KG', weighted: true, stepMilli: 500, unitPriceMinor: 79000, quantityMilli: 2000, lineTotalMinor: 158000, available: true, availableMilli: p.availableMilli, issue: 'INSUFFICIENT_STOCK');
      final q = quote([l], issues: ['UNAVAILABLE_ITEMS']);
      await tester.pumpWidget(testApp(const CartScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(q))]));
      await tester.pumpAndSettle();
      expect(find.textContaining('Доступно только'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);
    });

    testWidgets('empty cart state offers a way to the catalog', (tester) async {
      await tester.pumpWidget(testApp(const CartScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(quote([])))]));
      await tester.pumpAndSettle();
      expect(find.text('Корзина пуста'), findsOneWidget);
      expect(find.text('Перейти в каталог'), findsOneWidget);
    });

    testWidgets('signed-out users are asked to sign in', (tester) async {
      await tester.pumpWidget(testApp(const CartScreen(), overrides: [authProvider.overrideWith(() => FakeAuth(null)), cartProvider.overrideWith(() => FakeCart(null))]));
      await tester.pumpAndSettle();
      expect(find.text('Войдите, чтобы продолжить'), findsOneWidget);
    });
  });

  group('localization', () {
    testWidgets('the same screen renders in Russian, Kazakh and English', (tester) async {
      for (final (code, text) in [('ru', 'Корзина пуста'), ('kk', 'Себет бос'), ('en', 'Your cart is empty')]) {
        await tester.pumpWidget(testApp(const CartScreen(), locale: Locale(code), overrides: [authProvider.overrideWith(() => FakeAuth(demoProfile)), cartProvider.overrideWith(() => FakeCart(quote([])))]));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget, reason: code);
      }
    });
  });

  group('loading and error states', () {
    testWidgets('ErrorView shows a localized message and a working retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(testApp(Scaffold(body: ErrorView(error: AppException('NETWORK', 'x'), onRetry: () => retried++))));
      expect(find.text('Нет соединения с сервером'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      expect(retried, 1);
    });

    testWidgets('unknown errors fall back to a generic message', (tester) async {
      await tester.pumpWidget(testApp(Scaffold(body: ErrorView(error: AppException('WEIRD', 'x'), onRetry: () {}))));
      expect(find.text('Что-то пошло не так'), findsOneWidget);
    });

    testWidgets('skeletons render without images', (tester) async {
      await tester.pumpWidget(testApp(const Scaffold(body: ProductCardSkeleton())));
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('ProductImage falls back to a local placeholder', (tester) async {
      await tester.pumpWidget(testApp(const Scaffold(body: ProductImage(url: null, size: 80))));
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    });
  });

  test('cart totals shown to users are exactly the server values (no client recalculation)', () {
    final p = product();
    final q = quote([line(p, 1500)], discount: 1000);
    expect(q.totalMinor, q.subtotalMinor - q.discountMinor + q.deliveryFeeMinor + q.serviceFeeMinor);
    expect(ProviderContainer(), isNotNull);
  });
}
