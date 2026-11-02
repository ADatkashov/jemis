import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../core/util/jwt.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/customers/data/customers_repository.dart';
import '../features/dashboard/data/dashboard_repository.dart';
import '../features/delivery/data/delivery_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/products/data/catalog_admin_repository.dart';
import '../features/promotions/data/promotions_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/staff/data/staff_repository.dart';

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

  Future<void> set(Locale l) async {
    state = l;
    await ref.read(sharedPrefsProvider).setString(_key, l.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      tokens: ref.watch(tokenStorageProvider),
      onSessionExpired: () => ref.read(authProvider.notifier).sessionExpired(),
    ));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)));
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(ref.watch(apiClientProvider)));
final ordersRepositoryProvider = Provider((ref) => OrdersRepository(ref.watch(apiClientProvider)));
final catalogAdminRepositoryProvider = Provider((ref) => CatalogAdminRepository(ref.watch(apiClientProvider)));
final deliveryRepositoryProvider = Provider((ref) => DeliveryRepository(ref.watch(apiClientProvider)));
final promotionsRepositoryProvider = Provider((ref) => PromotionsRepository(ref.watch(apiClientProvider)));
final customersRepositoryProvider = Provider((ref) => CustomersRepository(ref.watch(apiClientProvider)));
final staffRepositoryProvider = Provider((ref) => StaffRepository(ref.watch(apiClientProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(apiClientProvider)));
final auditRepositoryProvider = Provider((ref) => AuditRepository(ref.watch(apiClientProvider)));

// ---------------------------------------------------------------- auth / session

class AuthState {
  const AuthState({this.role});
  static const signedOut = AuthState();

  /// Taken from the access token for display and navigation only; the server enforces authorization.
  final String? role;
  bool get signedIn => role != null;
  bool get isAdmin => isAdminOnly(role);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final tokens = ref.read(tokenStorageProvider);
    if (!tokens.hasSession) return AuthState.signedOut;
    final role = roleFromToken(tokens.access);
    if (!canUseAdmin(role)) {
      tokens.clear();
      return AuthState.signedOut;
    }
    return AuthState(role: role);
  }

  /// Only ADMIN and MANAGER may use the console; any other role is signed out again immediately.
  Future<void> login(String identifier, String password) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.login(identifier, password);
    final role = roleFromToken(ref.read(tokenStorageProvider).access);
    if (!canUseAdmin(role)) {
      await repo.logout();
      throw AppException('FORBIDDEN_ROLE', 'insufficient role', status: 403);
    }
    state = AuthState(role: role);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AuthState.signedOut;
  }

  void sessionExpired() => state = AuthState.signedOut;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ---------------------------------------------------------------- data (autoDispose: re-fetched on every visit)

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) => ref.watch(dashboardRepositoryProvider).load());

final ordersListProvider = FutureProvider.autoDispose.family<Paged<OrderRow>, OrderQuery>((ref, q) => ref.watch(ordersRepositoryProvider).list(q));
final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetailModel, String>((ref, id) => ref.watch(ordersRepositoryProvider).get(id));

final categoriesProvider = FutureProvider.autoDispose<List<AdminCategory>>((ref) => ref.watch(catalogAdminRepositoryProvider).categories());
final productsProvider = FutureProvider.autoDispose.family<Paged<AdminProduct>, ProductQuery>((ref, q) => ref.watch(catalogAdminRepositoryProvider).products(q));

final zonesProvider = FutureProvider.autoDispose<List<Zone>>((ref) => ref.watch(deliveryRepositoryProvider).zones());
final slotsProvider = FutureProvider.autoDispose<List<Slot>>((ref) => ref.watch(deliveryRepositoryProvider).slots());
final couriersProvider = FutureProvider.autoDispose<List<Courier>>((ref) => ref.watch(deliveryRepositoryProvider).couriers());

final promotionsProvider = FutureProvider.autoDispose<List<Promo>>((ref) => ref.watch(promotionsRepositoryProvider).list());

final customersProvider = FutureProvider.autoDispose.family<Paged<CustomerRow>, CustomerQuery>((ref, q) => ref.watch(customersRepositoryProvider).list(q));
final customerDetailProvider = FutureProvider.autoDispose.family<CustomerDetail, String>((ref, id) => ref.watch(customersRepositoryProvider).detail(id));

final staffProvider = FutureProvider.autoDispose<List<StaffRow>>((ref) => ref.watch(staffRepositoryProvider).list());
final settingsProvider = FutureProvider.autoDispose<Map<String, String>>((ref) => ref.watch(settingsRepositoryProvider).load());
final auditProvider = FutureProvider.autoDispose<List<AuditRow>>((ref) => ref.watch(auditRepositoryProvider).latest());
