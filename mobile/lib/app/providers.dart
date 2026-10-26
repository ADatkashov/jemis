import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/checkout/data/checkout_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/profile/data/profile_repository.dart';

// ---------------------------------------------------------------- infrastructure

/// Overridden in main() after SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('sharedPrefsProvider'));

const supportedLocales = [Locale('ru'), Locale('kk'), Locale('en')];

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return supportedLocales.firstWhere((l) => l.languageCode == saved, orElse: () => const Locale('ru'));
  }

  /// Switching the language keeps the account and the cart; it only changes presentation.
  Future<void> set(Locale l) async {
    state = l;
    await ref.read(sharedPrefsProvider).setString(_key, l.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      tokens: ref.watch(tokenStorageProvider),
      language: () => ref.read(localeProvider).languageCode,
      onSessionExpired: () => ref.read(authProvider.notifier).sessionExpired(),
    ));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)));
final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));
final catalogRepositoryProvider = Provider((ref) => CatalogRepository(ref.watch(apiClientProvider)));
final cartRepositoryProvider = Provider((ref) => CartRepository(ref.watch(apiClientProvider)));
final checkoutRepositoryProvider = Provider((ref) => CheckoutRepository(ref.watch(apiClientProvider)));
final ordersRepositoryProvider = Provider((ref) => OrdersRepository(ref.watch(apiClientProvider)));

// ---------------------------------------------------------------- auth / session

/// null = signed out. AsyncError = the session could not be verified (e.g. server unreachable).
class AuthNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    if (!await ref.read(authRepositoryProvider).hasSession()) return null;
    try {
      return await ref.read(profileRepositoryProvider).me();
    } on AppException catch (e) {
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<void> login(String identifier, String password) async {
    await ref.read(authRepositoryProvider).login(identifier, password);
    state = AsyncData(await ref.read(profileRepositoryProvider).me());
  }

  Future<void> register({String? email, String? phone, required String password, required String fullName}) async {
    await ref.read(authRepositoryProvider).register(
        email: email, phone: phone, password: password, fullName: fullName, locale: ref.read(localeProvider).languageCode);
    state = AsyncData(await ref.read(profileRepositoryProvider).me());
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void sessionExpired() => state = const AsyncData(null);

  Future<void> updateProfile({required String fullName, String? phone, bool? notifyOrders, bool? notifyPromos}) async {
    final p = await ref.read(profileRepositoryProvider).update(
        fullName: fullName,
        phone: phone,
        locale: ref.read(localeProvider).languageCode,
        notifyOrders: notifyOrders,
        notifyPromos: notifyPromos);
    state = AsyncData(p);
  }

  /// Persists the chosen UI language on the account (used for server-side notifications).
  Future<void> syncLocale() async {
    final p = state.value;
    if (p == null) return;
    state = AsyncData(await ref.read(profileRepositoryProvider).update(fullName: p.fullName, locale: ref.read(localeProvider).languageCode));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Profile?>(AuthNotifier.new);

bool isSignedIn(WidgetRef ref) => ref.watch(authProvider).value != null;

// ---------------------------------------------------------------- catalog

final homeProvider = FutureProvider.autoDispose<HomeFeed>((ref) {
  ref.watch(localeProvider);
  return ref.watch(catalogRepositoryProvider).home();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(catalogRepositoryProvider).categories();
});

final productDetailProvider = FutureProvider.autoDispose.family<ProductDetail, String>((ref, id) {
  ref.watch(localeProvider);
  return ref.watch(catalogRepositoryProvider).product(id);
});

final frequentProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  if (ref.watch(authProvider).value == null) return const [];
  ref.watch(localeProvider);
  return ref.watch(profileRepositoryProvider).frequentProducts();
});

class ProductListState {
  const ProductListState({this.filter = const ProductFilter(), this.items = const [], this.page = -1, this.hasMore = true, this.loading = false, this.error, this.total = 0});
  final ProductFilter filter;
  final List<Product> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final Object? error;
  final int total;

  ProductListState copyWith({ProductFilter? filter, List<Product>? items, int? page, bool? hasMore, bool? loading, Object? error = _keep, int? total}) =>
      ProductListState(
        filter: filter ?? this.filter,
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        loading: loading ?? this.loading,
        error: identical(error, _keep) ? this.error : error,
        total: total ?? this.total,
      );
  static const _keep = Object();
}

/// Incremental, backend-driven product list. A new filter cancels the in-flight request.
class ProductListNotifier extends Notifier<ProductListState> {
  CancelToken? _cancel;

  @override
  ProductListState build() {
    ref.onDispose(() => _cancel?.cancel());
    return const ProductListState();
  }

  Future<void> setFilter(ProductFilter f) async {
    if (f == state.filter && state.page >= 0) return;
    _cancel?.cancel();
    state = ProductListState(filter: f);
    await loadMore();
  }

  Future<void> reload() async {
    _cancel?.cancel();
    state = ProductListState(filter: state.filter);
    await loadMore();
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final filter = state.filter;
    final next = state.page + 1;
    _cancel = CancelToken();
    state = state.copyWith(loading: true, error: null);
    try {
      final r = await ref.read(catalogRepositoryProvider).products(filter, next, cancel: _cancel);
      if (filter != state.filter) return; // superseded
      state = state.copyWith(items: [...state.items, ...r.items], page: next, hasMore: r.hasMore, loading: false, total: r.totalElements);
    } on AppException catch (e) {
      if (e.code == 'CANCELLED') return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> retry() async {
    state = state.copyWith(error: null);
    await loadMore();
  }
}

final productListProvider = NotifierProvider.autoDispose<ProductListNotifier, ProductListState>(ProductListNotifier.new);

// ---------------------------------------------------------------- cart

class PromoNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? code) => state = code == null || code.trim().isEmpty ? null : code.trim();
}

final promoCodeProvider = NotifierProvider<PromoNotifier, String?>(PromoNotifier.new);

class CartNotifier extends AsyncNotifier<Quote?> {
  @override
  Future<Quote?> build() async {
    final user = ref.watch(authProvider).value;
    ref.watch(localeProvider);
    if (user == null) return null;
    return ref.read(cartRepositoryProvider).get(promoCode: ref.read(promoCodeProvider));
  }

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  Future<void> _refresh() async => state = AsyncData(await _repo.get(promoCode: ref.read(promoCodeProvider)));

  /// milli <= 0 removes the line. Throws AppException (e.g. INSUFFICIENT_STOCK) for the UI to show.
  Future<void> setQuantity(String productId, int milli) async {
    if (milli <= 0) {
      await _repo.remove(productId);
    } else {
      await _repo.setQuantity(productId, milli);
    }
    await _refresh();
  }

  Future<void> clear() async {
    await _repo.clear();
    ref.read(promoCodeProvider.notifier).set(null);
    await _refresh();
  }

  Future<void> applyPromo(String code) async {
    ref.read(promoCodeProvider.notifier).set(code);
    await _refresh();
  }

  Future<void> reload() async => _refresh();
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Quote?>(CartNotifier.new);

// ---------------------------------------------------------------- addresses / favorites

class AddressesNotifier extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() async {
    if (ref.watch(authProvider).value == null) return const [];
    return ref.read(profileRepositoryProvider).addresses();
  }

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> _reload() async => state = AsyncData(await _repo.addresses());

  Future<Address> add(AddressInput a) async {
    final created = await _repo.createAddress(a);
    await _reload();
    return created;
  }

  Future<void> edit(String id, AddressInput a) async {
    await _repo.updateAddress(id, a);
    await _reload();
  }

  Future<void> remove(String id) async {
    await _repo.deleteAddress(id);
    await _reload();
  }

  Future<void> makeDefault(String id) async {
    await _repo.makeDefault(id);
    await _reload();
  }
}

final addressesProvider = AsyncNotifierProvider<AddressesNotifier, List<Address>>(AddressesNotifier.new);

/// The address used for delivery; defaults to the account's default (or first) address.
class SelectedAddressNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

final selectedAddressIdProvider = NotifierProvider<SelectedAddressNotifier, String?>(SelectedAddressNotifier.new);

final selectedAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider).value ?? const [];
  if (list.isEmpty) return null;
  final id = ref.watch(selectedAddressIdProvider);
  return list.firstWhere((a) => a.id == id, orElse: () => list.firstWhere((a) => a.isDefault, orElse: () => list.first));
});

class FavoritesNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    if (ref.watch(authProvider).value == null) return const [];
    ref.watch(localeProvider);
    return ref.read(profileRepositoryProvider).favorites();
  }

  Future<void> toggle(Product p) async {
    final repo = ref.read(profileRepositoryProvider);
    final has = (state.value ?? const []).any((x) => x.id == p.id);
    if (has) {
      await repo.removeFavorite(p.id);
    } else {
      await repo.addFavorite(p.id);
    }
    state = AsyncData(await repo.favorites());
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<Product>>(FavoritesNotifier.new);

// ---------------------------------------------------------------- checkout / orders / notifications

final availabilityProvider = FutureProvider.autoDispose<Availability>((ref) => ref.watch(checkoutRepositoryProvider).availability());
final paymentMethodsProvider = FutureProvider.autoDispose<List<PayMethod>>((ref) => ref.watch(checkoutRepositoryProvider).methods());

final ordersProvider = FutureProvider.autoDispose<Paged<OrderSummary>>((ref) {
  ref.watch(authProvider);
  return ref.watch(ordersRepositoryProvider).list(0);
});

final orderProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) {
  ref.watch(localeProvider);
  return ref.watch(ordersRepositoryProvider).get(id);
});

final trackingProvider = FutureProvider.autoDispose.family<Tracking, String>((ref, id) => ref.watch(ordersRepositoryProvider).tracking(id));

final notificationsProvider = FutureProvider.autoDispose<Paged<AppNotification>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(profileRepositoryProvider).notifications(0);
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  if (ref.watch(authProvider).value == null) return 0;
  return ref.watch(profileRepositoryProvider).unreadCount();
});
