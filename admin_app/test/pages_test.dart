import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jemis_admin/core/network/api_client.dart';
import 'package:jemis_admin/features/audit/presentation/audit_page.dart';
import 'package:jemis_admin/features/categories/presentation/categories_page.dart';
import 'package:jemis_admin/features/customers/presentation/customers_page.dart';
import 'package:jemis_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:jemis_admin/features/delivery/presentation/delivery_page.dart';
import 'package:jemis_admin/features/orders/presentation/order_detail_page.dart';
import 'package:jemis_admin/features/orders/presentation/orders_page.dart';
import 'package:jemis_admin/features/products/presentation/products_page.dart';
import 'package:jemis_admin/features/promotions/presentation/promotions_page.dart';
import 'package:jemis_admin/features/settings/presentation/settings_page.dart';
import 'package:jemis_admin/features/staff/presentation/staff_page.dart';

import 'helpers.dart';

const _cat = {'id': 'c1', 'slug': 'fruit', 'nameRu': 'Фрукты', 'nameKk': 'Жемістер', 'nameEn': 'Fruit', 'sortOrder': 1, 'active': true};
const _product = {
  'id': 'p1', 'categoryId': 'c1', 'sku': 'APL-1', 'nameRu': 'Яблоки', 'nameKk': 'Алма', 'nameEn': 'Apples', 'unit': 'KG', 'weighted': true,
  'stepMilli': 500, 'priceMinor': 129050, 'oldPriceMinor': 150000, 'stockMilli': 12500, 'reservedMilli': 500, 'lowStockMilli': 5000, 'active': true,
};

Map<String, dynamic> orderDetail({String status = 'PENDING_PAYMENT', String payment = 'PENDING', List<String> next = const ['CONFIRMED', 'CANCELLED'], String? notes}) => {
      'order': {
        'id': 'o1', 'number': 'JM-100001', 'status': status, 'paymentStatus': payment, 'paymentMethod': 'CARD', 'recipientName': 'Айгуль',
        'address': {'city': 'Алматы', 'street': 'Абая', 'house': '10', 'apartment': '5', 'intercom': '12'},
        'slot': {'date': '2026-11-03', 'start': '10:00:00', 'end': '12:00:00'},
        'instructions': 'Позвонить',
        'subtotalMinor': 200000, 'discountMinor': 20000, 'deliveryFeeMinor': 99000, 'serviceFeeMinor': 0, 'totalMinor': 279000, 'promoCode': 'SAVE10',
        'items': [{'productId': 'p1', 'sku': 'APL-1', 'name': 'Яблоки', 'unitPriceMinor': 129050, 'quantityMilli': 1500, 'lineTotalMinor': 193575}],
        'timeline': [{'status': 'PENDING_PAYMENT', 'note': 'created', 'at': '2026-11-02T10:00:00Z'}],
      },
      'operatorNotes': notes,
      'recipientPhone': '+77001112233',
      'payments': [{'id': 'pay1', 'provider': 'MOCK', 'status': 'PENDING', 'amountMinor': 279000}],
      'issues': [{'description': 'Нет дома', 'createdAt': '2026-11-02T11:00:00Z'}],
      'allowedNext': next,
    };

void main() {
  setUpAll(initLocales);

  group('dashboard', () {
    final dash = {
      'ordersToday': 7, 'paidRevenueTodayMinor': 1234500, 'currency': 'KZT', 'awaitingProcessing': 2, 'inDelivery': 3, 'lowStockCount': 1,
      'lowStock': [{'id': 'p1', 'sku': 'APL-1', 'name': 'Яблоки', 'availableMilli': 1500, 'thresholdMilli': 5000}],
      'recentOrders': [{'id': 'o1', 'number': 'JM-100001', 'status': 'PREPARING', 'paymentStatus': 'SUCCEEDED', 'totalMinor': 279000}],
    };

    testWidgets('shows metrics, recent orders and low stock; localized', (tester) async {
      final api = FakeApi((m, p, b, q) => dash);
      await pumpPage(tester, const DashboardPage(), api);
      expect(find.text('Заказов сегодня'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(textLike('12 345'), findsOneWidget);
      expect(find.text('JM-100001'), findsOneWidget);
      expect(find.text('Собирается'), findsOneWidget);
      expect(find.text('Оплачен'), findsOneWidget);
      expect(find.text('APL-1'), findsOneWidget);
      expect(find.text('1,5'), findsOneWidget);
    });

    testWidgets('renders in English', (tester) async {
      await pumpPage(tester, const DashboardPage(), FakeApi((m, p, b, q) => dash), lang: 'en');
      expect(find.text('Orders today'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(textLike('12,345 ₸'), findsOneWidget);
    });

    testWidgets('renders in Kazakh', (tester) async {
      await pumpPage(tester, const DashboardPage(), FakeApi((m, p, b, q) => dash), lang: 'kk');
      expect(find.text('Бүгінгі тапсырыстар'), findsOneWidget);
      expect(find.text('Жиналуда'), findsOneWidget);
    });

    testWidgets('error with retry reloads', (tester) async {
      var fail = true;
      final api = FakeApi((m, p, b, q) => fail ? AppException('NETWORK', 'down') : dash);
      await pumpPage(tester, const DashboardPage(), api);
      expect(find.text('Нет связи с сервером.'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('API errors show code and message', (tester) async {
      final api = FakeApi((m, p, b, q) => AppException('FORBIDDEN', 'Access denied', status: 403));
      await pumpPage(tester, const DashboardPage(), api);
      expect(find.text('FORBIDDEN: Access denied'), findsOneWidget);
    });

    testWidgets('recent order opens its detail', (tester) async {
      await pumpPage(tester, const DashboardPage(), FakeApi((m, p, b, q) => dash));
      await tester.tap(find.byKey(const ValueKey('order-o1')));
      await tester.pumpAndSettle();
      expect(find.text('order-detail-o1'), findsOneWidget);
    });
  });

  group('orders', () {
    Map<String, dynamic> row(String id, String number) => {
          'id': id, 'number': number, 'status': 'CONFIRMED', 'paymentStatus': 'SUCCEEDED', 'recipientName': 'Айгуль', 'totalMinor': 150000, 'createdAt': '2026-11-02T10:00:00Z',
        };

    testWidgets('lists, searches (debounced), filters by status and pages', (tester) async {
      final api = FakeApi((m, p, b, q) => (q?['page'] ?? 0) == 1 ? page([row('o2', 'JM-100002')], pageNo: 1, totalPages: 2) : page([row('o1', 'JM-100001')], totalPages: 2));
      await pumpPage(tester, const OrdersPage(), api);
      expect(find.text('JM-100001'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(api.queries['GET /admin/orders'], {'page': 0, 'size': 25});

      await tester.enterText(find.byKey(const ValueKey('search')), '7700');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.queries['GET /admin/orders']!['q'], '7700');

      await tester.tap(find.byKey(const ValueKey('status-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отменён').last);
      await tester.pumpAndSettle();
      expect(api.queries['GET /admin/orders']!['status'], 'CANCELLED');
      expect(api.queries['GET /admin/orders']!['q'], '7700');

      await tester.tap(find.byTooltip('Следующая страница'));
      await tester.pumpAndSettle();
      expect(api.queries['GET /admin/orders']!['page'], 1);
      expect(find.text('JM-100002'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpPage(tester, const OrdersPage(), FakeApi((m, p, b, q) => page([])));
      expect(find.text('Ничего не найдено'), findsOneWidget);
    });
  });

  group('order detail', () {
    FakeApi make(Map<String, dynamic> detail, {void Function(String, String)? onWrite}) => FakeApi((m, p, b, q) {
          if (p == '/admin/delivery/couriers') {
            return [
              {'id': 'k1', 'displayName': 'Ерлан', 'active': true, 'trackingConsent': true},
              {'id': 'k2', 'displayName': 'Отключён', 'active': false, 'trackingConsent': false},
            ];
          }
          if (m == 'GET') return detail;
          onWrite?.call(m, p);
          return null;
        });

    testWidgets('shows everything the old admin showed', (tester) async {
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), make(orderDetail(notes: 'VIP')));
      expect(find.text('JM-100001'), findsOneWidget);
      expect(find.text('Алматы, Абая 10, кв. 5, домофон 12'), findsOneWidget);
      expect(find.text('2026-11-03 10:00–12:00'), findsOneWidget);
      expect(find.text('Позвонить'), findsOneWidget);
      expect(find.text('Айгуль +77001112233'), findsOneWidget);
      expect(find.text('Яблоки'), findsOneWidget);
      expect(find.text('Скидка SAVE10'), findsOneWidget);
      expect(textLike('−200'), findsOneWidget);
      expect(textLike('2 790'), findsWidgets);
      expect(find.text('Оплата (CARD)'), findsOneWidget);
      expect(find.textContaining('Нет дома'), findsOneWidget);
      expect(find.textContaining('created'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'VIP'), findsOneWidget);
    });

    testWidgets('status transition posts the new status', (tester) async {
      final api = make(orderDetail());
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      await tester.tap(find.byKey(const ValueKey('to-CONFIRMED')));
      await tester.pumpAndSettle();
      expect(api.bodies['POST /admin/orders/o1/status'], {'status': 'CONFIRMED'});
    });

    testWidgets('cancelling asks for confirmation first', (tester) async {
      final api = make(orderDetail());
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      await tester.tap(find.byKey(const ValueKey('to-CANCELLED')));
      await tester.pumpAndSettle();
      expect(find.text('Отменить этот заказ?'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(api.calls, isNot(contains('POST /admin/orders/o1/status')));
      await tester.tap(find.byKey(const ValueKey('to-CANCELLED')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(api.bodies['POST /admin/orders/o1/status'], {'status': 'CANCELLED'});
    });

    testWidgets('refund only for paid finished orders, with confirmation', (tester) async {
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), make(orderDetail()));
      expect(find.byKey(const ValueKey('refund')), findsNothing);

      final api = make(orderDetail(status: 'DELIVERED', payment: 'SUCCEEDED', next: const []));
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      await tester.tap(find.byKey(const ValueKey('refund')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('POST /admin/orders/o1/refund'));
    });

    testWidgets('courier can be offered only when ready for delivery, inactive couriers are hidden', (tester) async {
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), make(orderDetail()));
      expect(find.byKey(const ValueKey('assign')), findsNothing);

      final api = make(orderDetail(status: 'READY_FOR_DELIVERY', payment: 'SUCCEEDED', next: const []));
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('assign'))).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('courier')));
      await tester.pumpAndSettle();
      expect(find.text('Отключён'), findsNothing);
      await tester.tap(find.text('Ерлан').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('assign')));
      await tester.pumpAndSettle();
      expect(api.bodies['POST /admin/orders/o1/assign'], {'courierId': 'k1'});
    });

    testWidgets('operator notes save only when changed', (tester) async {
      final api = make(orderDetail(notes: 'VIP'));
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('save-notes'))).onPressed, isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('notes')));
      await tester.enterText(find.byKey(const ValueKey('notes')), 'VIP, позвонить');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('save-notes')));
      await tester.tap(find.byKey(const ValueKey('save-notes')));
      await tester.pumpAndSettle();
      expect(api.bodies['POST /admin/orders/o1/notes'], {'notes': 'VIP, позвонить'});
    });

    testWidgets('a failing action shows the server error and keeps the page', (tester) async {
      final api = FakeApi((m, p, b, q) {
        if (p == '/admin/delivery/couriers') return [];
        if (m == 'GET') return orderDetail();
        return AppException('INVALID_TRANSITION', 'Not allowed', status: 409);
      });
      await pumpPage(tester, const OrderDetailPage(id: 'o1'), api);
      await tester.tap(find.byKey(const ValueKey('to-CONFIRMED')));
      await tester.pumpAndSettle();
      expect(find.text('INVALID_TRANSITION: Not allowed'), findsOneWidget);
      expect(find.text('JM-100001'), findsOneWidget);
    });
  });

  group('products', () {
    FakeApi make() => FakeApi((m, p, b, q) {
          if (p == '/admin/categories') return [_cat];
          if (p == '/admin/products' && m == 'GET') return page([_product]);
          return null;
        });

    testWidgets('lists with old price and stock / reserved', (tester) async {
      await pumpPage(tester, const ProductsPage(), make());
      expect(find.text('APL-1'), findsOneWidget);
      expect(find.text('12,5 / 0,5'), findsOneWidget);
      expect(textLike('1 290,50'), findsWidgets);
    });

    testWidgets('search sends q', (tester) async {
      final api = make();
      await pumpPage(tester, const ProductsPage(), api);
      await tester.enterText(find.byKey(const ValueKey('search')), 'ябл');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.queries['GET /admin/products']!['q'], 'ябл');
    });

    testWidgets('creating a product validates, then posts minor units', (tester) async {
      final api = make();
      await pumpPage(tester, const ProductsPage(), api);
      await tester.tap(find.byKey(const ValueKey('new')));
      await tester.pumpAndSettle();
      expect(find.text('Новый товар'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Обязательное поле'), findsWidgets);
      expect(api.calls, isNot(contains('POST /admin/products')));

      await enter(tester, labeled('Артикул'), 'BAN-1');
      await enter(tester, labeled('Название (ru)'), 'Бананы');
      await enter(tester, labeled('Название (kk)'), 'Банан');
      await enter(tester, labeled('Название (en)'), 'Bananas');
      await enter(tester, labeled('Цена, ₸ (за 1 единицу)'), '500');
      await enter(tester, labeled('Прежняя цена, ₸'), '400');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Прежняя цена должна быть выше цены'), findsOneWidget);
      expect(api.calls, isNot(contains('POST /admin/products')));

      await enter(tester, labeled('Прежняя цена, ₸'), '650,50');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['POST /admin/products'] as Map;
      expect(body['sku'], 'BAN-1');
      expect(body['categoryId'], 'c1');
      expect(body['priceMinor'], 50000);
      expect(body['oldPriceMinor'], 65050);
      expect(body['unit'], 'PIECE');
      expect(find.text('Новый товар'), findsNothing);
    });

    testWidgets('editing PUTs to the product and a server error stays in the dialog', (tester) async {
      var fail = true;
      final api = FakeApi((m, p, b, q) {
        if (p == '/admin/categories') return [_cat];
        if (m == 'GET') return page([_product]);
        if (fail) return AppException('SKU_EXISTS', 'SKU already used', status: 409);
        return null;
      });
      await pumpPage(tester, const ProductsPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-p1')));
      await tester.pumpAndSettle();
      expect(find.text('Редактирование товара'), findsOneWidget);
      expect(find.text('Остаток 12,5, резерв 0,5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('SKU_EXISTS: SKU already used'), findsOneWidget);
      fail = false;
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect((api.bodies['PUT /admin/products/p1'] as Map)['priceMinor'], 129050);
      expect(find.text('Редактирование товара'), findsNothing);
    });

    testWidgets('stock adjustment needs quantity and reason, sends signed milli-units', (tester) async {
      final api = make();
      await pumpPage(tester, const ProductsPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-p1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('adjust')));
      await tester.tap(find.byKey(const ValueKey('adjust')));
      await tester.pumpAndSettle();
      expect(find.text('Укажите количество и причину'), findsOneWidget);
      await enter(tester, labeled('Изменить на (напр. 10 или -2.5)'), '-2.5');
      await enter(tester, labeled('Причина'), 'пересчёт');
      await tester.tap(find.byKey(const ValueKey('adjust')));
      await tester.pumpAndSettle();
      expect(api.bodies['POST /admin/products/p1/stock'], {'deltaMilli': -2500, 'reason': 'пересчёт'});
    });
  });

  group('categories', () {
    testWidgets('create validates the slug and posts', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? [_cat] : null);
      await pumpPage(tester, const CategoriesPage(), api);
      expect(find.text('Фрукты / Жемістер / Fruit'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('new')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Slug (a-z, 0-9, -)'), 'Bad Slug');
      await enter(tester, labeled('Название (ru)'), 'Овощи');
      await enter(tester, labeled('Название (kk)'), 'Көкөніс');
      await enter(tester, labeled('Название (en)'), 'Veg');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Только a-z, 0-9 и «-»'), findsOneWidget);
      await enter(tester, labeled('Slug (a-z, 0-9, -)'), 'veg');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['POST /admin/categories'] as Map;
      expect(body['slug'], 'veg');
      expect(body['parentId'], isNull);
      expect(body['active'], true);
    });

    testWidgets('edit uses PUT', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? [_cat] : null);
      await pumpPage(tester, const CategoriesPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-c1')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Порядок'), '5');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect((api.bodies['PUT /admin/categories/c1'] as Map)['sortOrder'], 5);
    });
  });

  group('delivery', () {
    FakeApi make() => FakeApi((m, p, b, q) {
          if (m != 'GET') return null;
          return switch (p) {
            '/admin/delivery/zones' => [
                {'id': 'z1', 'name': 'Центр', 'city': 'Алматы', 'feeMinor': 99000, 'minOrderMinor': 500000, 'freeDeliveryThresholdMinor': 1500000, 'active': true},
              ],
            '/admin/delivery/slots' => [
                {'id': 's1', 'startTime': '10:00:00', 'endTime': '12:00:00', 'capacity': 8, 'daysOfWeek': '1,2,3', 'extraFeeMinor': 0, 'active': true},
              ],
            _ => [
                {'id': 'k1', 'displayName': 'Ерлан', 'phone': '+7700', 'active': true, 'trackingConsent': false},
              ],
          };
        });

    testWidgets('shows zones, windows and couriers', (tester) async {
      await pumpPage(tester, const DeliveryPage(), make());
      expect(find.text('Центр'), findsOneWidget);
      expect(textLike('990'), findsWidgets);
      expect(find.text('10:00–12:00'), findsOneWidget);
      expect(find.text('Ерлан'), findsOneWidget);
      expect(find.text('геолокация выключена'), findsOneWidget);
      expect(find.textContaining('Зоны доставки сейчас сопоставляются только по городу'), findsOneWidget);
    });

    testWidgets('zone: invalid amount blocked, valid posts minor units', (tester) async {
      final api = make();
      await pumpPage(tester, const DeliveryPage(), api);
      await tester.tap(find.byKey(const ValueKey('new-zone')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Название'), 'Юг');
      await enter(tester, labeled('Город (должен совпадать с городом адреса клиента)'), 'Алматы');
      await enter(tester, labeled('Стоимость доставки, ₸'), 'abc');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Некорректная сумма'), findsOneWidget);
      await enter(tester, labeled('Стоимость доставки, ₸'), '1 200');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['POST /admin/delivery/zones'] as Map;
      expect(body['feeMinor'], 120000);
      expect(body['freeDeliveryThresholdMinor'], isNull);
    });

    testWidgets('zone edit keeps existing values', (tester) async {
      final api = make();
      await pumpPage(tester, const DeliveryPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-zone-z1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['PUT /admin/delivery/zones/z1'] as Map;
      expect(body['freeDeliveryThresholdMinor'], 1500000);
      expect(body['minOrderMinor'], 500000);
    });

    testWidgets('window: validates days and sends HH:mm', (tester) async {
      final api = make();
      await pumpPage(tester, const DeliveryPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-slot-s1')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Дни, напр. 1,2,3'), '9');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Формат: числа 1–7 через запятую'), findsOneWidget);
      await enter(tester, labeled('Дни, напр. 1,2,3'), '1,2');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['PUT /admin/delivery/slots/s1'] as Map;
      expect(body['startTime'], '10:00');
      expect(body['daysOfWeek'], '1,2');
      expect(body['capacity'], 8);
    });
  });

  group('promotions', () {
    final promo = {'id': 'pr1', 'code': 'SAVE10', 'type': 'PERCENT', 'value': 10, 'minOrderMinor': 500000, 'usedCount': 3, 'usageLimit': 100, 'active': true, 'stackable': false, 'categoryId': 'c9'};

    testWidgets('lists discount, usage and active', (tester) async {
      await pumpPage(tester, const PromotionsPage(), FakeApi((m, p, b, q) => [promo]));
      expect(find.text('SAVE10'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('3 / 100'), findsOneWidget);
    });

    testWidgets('create fixed promo posts minor units', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? [promo] : null);
      await pumpPage(tester, const PromotionsPage(), api);
      await tester.tap(find.byKey(const ValueKey('new')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Код'), 'WELCOME');
      await tester.tap(find.byKey(const ValueKey('promo-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Фиксированная, ₸').last);
      await tester.pumpAndSettle();
      await enter(tester, labeled('Сумма, ₸'), '500');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['POST /admin/promotions'] as Map;
      expect(body['type'], 'FIXED');
      expect(body['value'], 50000);
      expect(body['minOrderMinor'], 0);
    });

    testWidgets('edit validates percent range and preserves the category', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? [promo] : null);
      await pumpPage(tester, const PromotionsPage(), api);
      await tester.tap(find.byKey(const ValueKey('edit-pr1')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Процент (1–100)'), '150');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Некорректное число'), findsOneWidget);
      await enter(tester, labeled('Процент (1–100)'), '15');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['PUT /admin/promotions/pr1'] as Map;
      expect(body['value'], 15);
      expect(body['categoryId'], 'c9');
      expect(body['usageLimit'], 100);
    });
  });

  group('customers', () {
    FakeApi make() => FakeApi((m, p, b, q) {
          if (p == '/admin/customers') {
            return page([{'id': 'u1', 'fullName': 'Айгуль', 'email': 'a@b.kz', 'phone': '+7700', 'status': 'ACTIVE', 'createdAt': '2026-11-01T00:00:00Z'}]);
          }
          return {
            'customer': {'id': 'u1', 'fullName': 'Айгуль', 'status': 'ACTIVE'},
            'orders': [{'id': 'o1', 'number': 'JM-100001', 'status': 'DELIVERED', 'totalMinor': 279000, 'createdAt': '2026-11-02T10:00:00Z'}],
          };
        });

    testWidgets('search and show a customer\'s orders, which link to the order', (tester) async {
      final api = make();
      await pumpPage(tester, const CustomersPage(), api);
      expect(find.text('a@b.kz'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('search')), 'айг');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.queries['GET /admin/customers']!['q'], 'айг');
      await tester.tap(find.byKey(const ValueKey('orders-u1')));
      await tester.pumpAndSettle();
      expect(find.text('Доставлен'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('customer-order-o1')));
      await tester.pumpAndSettle();
      expect(find.text('order-detail-o1'), findsOneWidget);
    });
  });

  group('staff', () {
    final rows = [
      {'id': 'u1', 'fullName': 'Админ', 'email': 'admin@jemis.local', 'role': 'ADMIN', 'status': 'ACTIVE'},
      {'id': 'u2', 'fullName': 'Курьер', 'email': 'c@jemis.local', 'role': 'COURIER', 'status': 'DISABLED'},
    ];

    testWidgets('toggle sends the opposite state', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? rows : null);
      await pumpPage(tester, const StaffPage(), api);
      expect(find.text('Отключить'), findsOneWidget);
      expect(find.text('Включить'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('toggle-u1')));
      await tester.pumpAndSettle();
      expect(api.bodies['PUT /admin/staff/u1/active'], {'active': false});
      await tester.tap(find.byKey(const ValueKey('toggle-u2')));
      await tester.pumpAndSettle();
      expect(api.bodies['PUT /admin/staff/u2/active'], {'active': true});
    });

    testWidgets('create enforces the 10 character password', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? rows : null);
      await pumpPage(tester, const StaffPage(), api);
      await tester.tap(find.byKey(const ValueKey('new')));
      await tester.pumpAndSettle();
      await enter(tester, labeled('Эл. почта'), 'new@jemis.local');
      await enter(tester, labeled('Полное имя'), 'Новый');
      await enter(tester, labeled('Пароль (мин. 10)'), 'short');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      expect(find.text('Минимум 10 символов'), findsOneWidget);
      await enter(tester, labeled('Пароль (мин. 10)'), 'long-enough-1');
      await tester.tap(find.byKey(const ValueKey('submit')));
      await tester.pumpAndSettle();
      final body = api.bodies['POST /admin/staff'] as Map;
      expect(body['role'], 'MANAGER');
      expect(body['phone'], isNull);
      expect(body['email'], 'new@jemis.local');
    });

    testWidgets('a toggle failure is shown', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? rows : AppException('LAST_ADMIN', 'Cannot disable the last admin', status: 409));
      await pumpPage(tester, const StaffPage(), api);
      await tester.tap(find.byKey(const ValueKey('toggle-u1')));
      await tester.pumpAndSettle();
      expect(find.text('LAST_ADMIN: Cannot disable the last admin'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('shows help, sends only changed keys', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? {'delivery.days_ahead': '3', 'payment.cash_enabled': 'true', 'custom.key': 'x'} : null);
      await pumpPage(tester, const SettingsPage(), api);
      expect(find.text('delivery.days_ahead'), findsWidgets);
      expect(find.text('true разрешает оплату при получении'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('save'))).onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('setting-delivery.days_ahead')), '5');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save')));
      await tester.pumpAndSettle();
      expect(api.bodies['PUT /admin/settings'], {'delivery.days_ahead': '5'});
      expect(find.text('Сохранено'), findsOneWidget);
    });

    testWidgets('editing back to the original value disables save', (tester) async {
      final api = FakeApi((m, p, b, q) => {'a.b': '1'});
      await pumpPage(tester, const SettingsPage(), api);
      await tester.enterText(find.byKey(const ValueKey('setting-a.b')), '2');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('save'))).onPressed, isNotNull);
      await tester.enterText(find.byKey(const ValueKey('setting-a.b')), '1');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('save'))).onPressed, isNull);
    });

    testWidgets('a rejected value shows the error', (tester) async {
      final api = FakeApi((m, p, b, q) => m == 'GET' ? {'a.b': '1'} : AppException('INVALID_SETTING', 'bad value', status: 400));
      await pumpPage(tester, const SettingsPage(), api);
      await tester.enterText(find.byKey(const ValueKey('setting-a.b')), 'zzz');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save')));
      await tester.pumpAndSettle();
      expect(find.text('INVALID_SETTING: bad value'), findsOneWidget);
    });
  });

  group('audit', () {
    testWidgets('renders rows', (tester) async {
      final api = FakeApi((m, p, b, q) => [
            {'createdAt': '2026-11-02T10:00:00Z', 'actorEmail': 'admin@jemis.local', 'action': 'ZONE_CREATE', 'entity': 'zone', 'entityId': 'z1', 'details': 'Алматы'},
          ]);
      await pumpPage(tester, const AuditPage(), api);
      expect(find.text('admin@jemis.local'), findsOneWidget);
      expect(find.text('ZONE_CREATE'), findsOneWidget);
      expect(find.text('zone z1'), findsOneWidget);
      expect(api.queries['GET /admin/audit-log'], {'size': 100});
    });
  });
}
