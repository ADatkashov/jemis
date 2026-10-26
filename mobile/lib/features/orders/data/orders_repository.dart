import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class PaymentAttempt {
  const PaymentAttempt({required this.id, required this.developmentOnly, this.note, this.redirectUrl});
  final String id;
  final bool developmentOnly;
  final String? note;
  final String? redirectUrl;
}

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<Paged<OrderSummary>> list(int page) async =>
      Paged.fromJson(await _api.get('/orders', query: {'page': page, 'size': 50}) as Map<String, dynamic>, OrderSummary.fromJson);

  Future<Order> get(String id) async => Order.fromJson(await _api.get('/orders/$id') as Map<String, dynamic>);

  Future<Tracking> tracking(String id) async => Tracking.fromJson(await _api.get('/orders/$id/tracking') as Map<String, dynamic>);

  Future<Order> cancel(String id) async => Order.fromJson(await _api.post('/orders/$id/cancel') as Map<String, dynamic>);

  /// Returns how many items could not be re-added (unavailable now).
  Future<int> reorder(String id) async {
    final r = await _api.post('/orders/$id/reorder') as Map<String, dynamic>;
    return (r['skippedProductIds'] as List).length;
  }

  Future<PaymentAttempt> initiatePayment(String orderId) async {
    final r = await _api.post('/payments/orders/$orderId/initiate') as Map<String, dynamic>;
    return PaymentAttempt(
        id: r['id'] as String,
        developmentOnly: r['developmentOnly'] as bool,
        note: r['note'] as String?,
        redirectUrl: r['redirectUrl'] as String?);
  }

  /// DEVELOPMENT ONLY: finishes a mock payment through the backend's signed webhook path.
  Future<void> simulateMockPayment(String paymentId, {required bool success}) async =>
      _api.post('/dev/payments/$paymentId/simulate?outcome=${success ? 'success' : 'failure'}');
}
