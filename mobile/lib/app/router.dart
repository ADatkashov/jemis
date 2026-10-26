import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_x.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/catalog/presentation/product_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/orders/presentation/orders_screens.dart';
import '../features/profile/presentation/profile_screens.dart';
import 'providers.dart';

class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Routes that need a session; signed-out users are sent to /login.
const _protectedPrefixes = ['/checkout', '/orders', '/profile'];

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen(authProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue || auth.hasError) return loc == '/splash' ? null : '/splash';
      final signedIn = auth.value != null;
      if (loc == '/splash') return '/';
      if (signedIn && (loc == '/login' || loc == '/register')) return '/';
      if (!signedIn && _protectedPrefixes.any(loc.startsWith)) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/product/:id', builder: (_, s) => ProductScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/checkout/done/:id', builder: (_, s) => OrderDoneScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(path: '/orders/:id', builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/profile/addresses', builder: (_, _) => const AddressesScreen()),
      GoRoute(path: '/profile/addresses/new', builder: (_, _) => const AddressFormScreen()),
      GoRoute(path: '/profile/addresses/:id', builder: (_, s) => AddressFormScreen(addressId: s.pathParameters['id'])),
      GoRoute(path: '/profile/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/profile/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalog',
              builder: (_, s) => CatalogScreen(
                categoryId: s.uri.queryParameters['category'],
                sort: s.uri.queryParameters['sort'],
                discounted: s.uri.queryParameters['discounted'] == '1',
                focusSearch: s.uri.queryParameters['focus'] == '1',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, _) => const CartScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

/// Bottom navigation shared by the four main destinations.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final cartCount = ref.watch(cartProvider.select((c) => c.value?.itemCount ?? 0));
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: l.navCatalog),
          NavigationDestination(
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
            label: l.navCart,
          ),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l.navProfile),
        ],
      ),
    );
  }
}
