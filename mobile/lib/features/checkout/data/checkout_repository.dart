import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class CheckoutRepository {
  CheckoutRepository(this._api);
  final ApiClient _api;

  Future<Availability> availability() async =>
      Availability.fromJson(await _api.get('/delivery/availability') as Map<String, dynamic>);

  Future<List<PayMethod>> methods() async =>
      (await _api.get('/payments/methods') as List).map((e) => PayMethod.fromJson(e as Map<String, dynamic>)).toList();

  Future<Quote> quote({required String addressId, String? slotTemplateId, String? promoCode}) async =>
      Quote.fromJson(await _api.post('/checkout/quote', body: {
        'addressId': addressId,
        'slotTemplateId': ?slotTemplateId,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      }) as Map<String, dynamic>);

  /// [idempotencyKey] makes retries and double taps safe: the server returns the same order.
  Future<Order> place({
    required String idempotencyKey,
    required String addressId,
    required String slotTemplateId,
    required String slotDate,
    required String paymentMethod,
    String? promoCode,
    required int expectedTotalMinor,
  }) async =>
      Order.fromJson(await _api.post('/checkout',
          headers: {'Idempotency-Key': idempotencyKey},
          body: {
            'addressId': addressId,
            'slotTemplateId': slotTemplateId,
            'slotDate': slotDate,
            'paymentMethod': paymentMethod,
            if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
            'expectedTotalMinor': expectedTotalMinor,
          }) as Map<String, dynamic>);
}
