import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class AddressInput {
  const AddressInput({required this.city, required this.street, required this.house, this.label, this.apartment, this.entrance, this.floor, this.intercom, this.recipientName, this.recipientPhone, this.instructions, this.isDefault = false});
  final String city;
  final String street;
  final String house;
  final String? label;
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? intercom;
  final String? recipientName;
  final String? recipientPhone;
  final String? instructions;
  final bool isDefault;

  Map<String, dynamic> toJson() {
    String? n(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    return {
      'city': city.trim(),
      'street': street.trim(),
      'house': house.trim(),
      'label': n(label),
      'apartment': n(apartment),
      'entrance': n(entrance),
      'floor': n(floor),
      'intercom': n(intercom),
      'recipientName': n(recipientName),
      'recipientPhone': n(recipientPhone),
      'instructions': n(instructions),
      'isDefault': isDefault,
    };
  }
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<Profile> me() async => Profile.fromJson(await _api.get('/customer/me') as Map<String, dynamic>);

  Future<Profile> update({required String fullName, String? phone, String? locale, bool? notifyOrders, bool? notifyPromos}) async =>
      Profile.fromJson(await _api.put('/customer/me', body: {
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'locale': ?locale,
        'notifyOrders': ?notifyOrders,
        'notifyPromos': ?notifyPromos,
      }) as Map<String, dynamic>);

  Future<void> requestAccountDeletion() async => _api.delete('/customer/me');

  Future<List<Address>> addresses() async =>
      (await _api.get('/customer/addresses') as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();

  Future<Address> createAddress(AddressInput a) async => Address.fromJson(await _api.post('/customer/addresses', body: a.toJson()) as Map<String, dynamic>);

  Future<Address> updateAddress(String id, AddressInput a) async =>
      Address.fromJson(await _api.put('/customer/addresses/$id', body: a.toJson()) as Map<String, dynamic>);

  Future<void> deleteAddress(String id) async => _api.delete('/customer/addresses/$id');

  Future<void> makeDefault(String id) async => _api.post('/customer/addresses/$id/default');

  Future<List<Product>> favorites() async =>
      (await _api.get('/customer/favorites') as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();

  Future<void> addFavorite(String productId) async => _api.put('/customer/favorites/$productId');

  Future<void> removeFavorite(String productId) async => _api.delete('/customer/favorites/$productId');

  Future<List<Product>> frequentProducts() async =>
      (await _api.get('/customer/frequent-products') as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();

  Future<Paged<AppNotification>> notifications(int page) async =>
      Paged.fromJson(await _api.get('/notifications', query: {'page': page, 'size': 30}) as Map<String, dynamic>, AppNotification.fromJson);

  Future<int> unreadCount() async => ((await _api.get('/notifications/unread-count') as Map<String, dynamic>)['count'] as num).toInt();

  Future<void> markAllRead() async => _api.post('/notifications/read-all');
}
