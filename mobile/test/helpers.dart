import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_app/app/providers.dart';
import 'package:jemis_app/core/models.dart';
import 'package:jemis_app/l10n/app_localizations.dart';

Product product({String id = 'p1', String name = 'Бананы', int price = 79000, int? old, bool weighted = true, String unit = 'KG', int step = 500, bool available = true, int availableMilli = 10000, int? discount}) => Product(
      id: id,
      sku: 'SKU-$id',
      name: name,
      unit: unit,
      weighted: weighted,
      stepMilli: step,
      priceMinor: price,
      oldPriceMinor: old,
      discountPercent: discount,
      available: available,
      availableMilli: availableMilli,
      lowStock: false,
    );

CartLine line(Product p, int qty) => CartLine(
      productId: p.id,
      name: p.name,
      unit: p.unit,
      weighted: p.weighted,
      stepMilli: p.stepMilli,
      unitPriceMinor: p.priceMinor,
      quantityMilli: qty,
      lineTotalMinor: (p.priceMinor * qty + 500) ~/ 1000,
      available: p.available,
      availableMilli: p.availableMilli,
    );

Quote quote(List<CartLine> lines, {int delivery = 99000, int discount = 0, int minOrder = 0, List<String> issues = const [], int? freeFrom}) {
  final sub = lines.fold<int>(0, (a, l) => a + l.lineTotalMinor);
  return Quote(
    lines: lines,
    subtotalMinor: sub,
    discountMinor: discount,
    deliveryFeeMinor: delivery,
    serviceFeeMinor: 0,
    totalMinor: sub - discount + delivery,
    minOrderMinor: minOrder,
    freeDeliveryThresholdMinor: freeFrom,
    deliveryEstimated: false,
    issues: issues,
  );
}

class FakeAuth extends AuthNotifier {
  FakeAuth(this.profile);
  final Profile? profile;
  @override
  Future<Profile?> build() async => profile;
}

class FakeCart extends CartNotifier {
  FakeCart(this.initial);
  Quote? initial;
  final calls = <String>[];
  @override
  Future<Quote?> build() async => initial;
  @override
  Future<void> setQuantity(String productId, int milli) async {
    calls.add('$productId:$milli');
  }
}

const demoProfile = Profile(id: 'u1', fullName: 'Demo', email: 'd@e.kz', locale: 'ru', notifyOrders: true, notifyPromos: false);

Widget testApp(Widget home, {Locale locale = const Locale('ru'), List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [AppL10n.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: home,
      ),
    );
