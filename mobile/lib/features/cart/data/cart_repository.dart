import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Quote> get({String? promoCode}) async =>
      Quote.fromJson(await _api.get('/cart', query: {if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode}) as Map<String, dynamic>);

  Future<Quote> setQuantity(String productId, int milli) async =>
      Quote.fromJson(await _api.put('/cart/items/$productId', body: {'quantityMilli': milli}) as Map<String, dynamic>);

  Future<Quote> remove(String productId) async =>
      Quote.fromJson(await _api.delete('/cart/items/$productId') as Map<String, dynamic>);

  Future<void> clear() async => _api.delete('/cart');
}
