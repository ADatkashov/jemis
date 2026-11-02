import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/audit/presentation/audit_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/categories/presentation/categories_page.dart';
import '../features/customers/presentation/customers_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/delivery/presentation/delivery_page.dart';
import '../features/orders/presentation/order_detail_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/products/presentation/products_page.dart';
import '../features/promotions/presentation/promotions_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/staff/presentation/staff_page.dart';
import 'nav.dart';
import 'providers.dart';
import 'shell.dart';

class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Where a request for [location] should land given the session, or null to stay.
/// Pure so it can be unit-tested: signed-out users see /login; non-admins never reach ADMIN-only pages;
/// unknown paths go home (as the old React admin did).
String? redirectFor(String location, AuthState auth) {
  if (!auth.signedIn) return location == '/login' ? null : '/login';
  if (location == '/login') return '/';
  final item = navItemFor(location);
  if (item == null || (item.adminOnly && !auth.isAdmin)) return '/';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen(authProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(state.uri.path, ref.read(authProvider)),
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersPage()),
          GoRoute(path: '/orders/:id', builder: (_, s) => OrderDetailPage(id: s.pathParameters['id']!)),
          GoRoute(path: '/products', builder: (_, _) => const ProductsPage()),
          GoRoute(path: '/categories', builder: (_, _) => const CategoriesPage()),
          GoRoute(path: '/delivery', builder: (_, _) => const DeliveryPage()),
          GoRoute(path: '/promotions', builder: (_, _) => const PromotionsPage()),
          GoRoute(path: '/customers', builder: (_, _) => const CustomersPage()),
          GoRoute(path: '/staff', builder: (_, _) => const StaffPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(path: '/audit', builder: (_, _) => const AuditPage()),
        ],
      ),
    ],
  );
});
