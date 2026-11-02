import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

const orderStatuses = [
  'PENDING_PAYMENT',
  'CONFIRMED',
  'ACCEPTED',
  'PREPARING',
  'READY_FOR_DELIVERY',
  'ASSIGNED_TO_COURIER',
  'PICKED_UP',
  'ON_THE_WAY',
  'DELIVERED',
  'CANCELLED',
  'REFUNDED',
];

class OrderRow {
  const OrderRow({required this.id, required this.number, required this.status, required this.paymentStatus, required this.recipientName, required this.totalMinor, this.createdAt});
  final String id, number, status, paymentStatus, recipientName;
  final int totalMinor;
  final DateTime? createdAt;
  factory OrderRow.fromJson(Map<String, dynamic> j) => OrderRow(
        id: asStr(j['id']),
        number: asStr(j['number']),
        status: asStr(j['status']),
        paymentStatus: asStr(j['paymentStatus']),
        recipientName: asStr(j['recipientName']),
        totalMinor: asInt(j['totalMinor']),
        createdAt: DateTime.tryParse(asStr(j['createdAt'])),
      );
}

class OrderQuery {
  const OrderQuery({this.q = '', this.status = '', this.page = 0});
  final String q, status;
  final int page;
  OrderQuery copyWith({String? q, String? status, int? page}) => OrderQuery(q: q ?? this.q, status: status ?? this.status, page: page ?? this.page);
  @override
  bool operator ==(Object other) => other is OrderQuery && other.q == q && other.status == status && other.page == page;
  @override
  int get hashCode => Object.hash(q, status, page);
}

class OrderAddress {
  const OrderAddress({required this.city, required this.street, required this.house, this.apartment, this.entrance, this.floor, this.intercom});
  final String city, street, house;
  final String? apartment, entrance, floor, intercom;
  factory OrderAddress.fromJson(Map<String, dynamic> j) => OrderAddress(
      city: asStr(j['city']), street: asStr(j['street']), house: asStr(j['house']),
      apartment: j['apartment'] as String?, entrance: j['entrance'] as String?, floor: j['floor'] as String?, intercom: j['intercom'] as String?);
}

class OrderItem {
  const OrderItem({required this.productId, required this.sku, required this.name, required this.unitPriceMinor, required this.quantityMilli, required this.lineTotalMinor});
  final String productId, sku, name;
  final int unitPriceMinor, quantityMilli, lineTotalMinor;
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
      productId: asStr(j['productId']), sku: asStr(j['sku']), name: asStr(j['name']),
      unitPriceMinor: asInt(j['unitPriceMinor']), quantityMilli: asInt(j['quantityMilli']), lineTotalMinor: asInt(j['lineTotalMinor']));
}

class TimelineEntry {
  const TimelineEntry({required this.status, this.note, this.at});
  final String status;
  final String? note;
  final DateTime? at;
  factory TimelineEntry.fromJson(Map<String, dynamic> j) =>
      TimelineEntry(status: asStr(j['status']), note: j['note'] as String?, at: DateTime.tryParse(asStr(j['at'])));
}

class PaymentRow {
  const PaymentRow({required this.id, required this.provider, required this.status, required this.amountMinor, this.failureReason});
  final String id, provider, status;
  final int amountMinor;
  final String? failureReason;
  factory PaymentRow.fromJson(Map<String, dynamic> j) => PaymentRow(
      id: asStr(j['id']), provider: asStr(j['provider']), status: asStr(j['status']), amountMinor: asInt(j['amountMinor']), failureReason: j['failureReason'] as String?);
}

class OrderIssue {
  const OrderIssue({required this.description, this.createdAt});
  final String description;
  final DateTime? createdAt;
  factory OrderIssue.fromJson(Map<String, dynamic> j) => OrderIssue(description: asStr(j['description']), createdAt: DateTime.tryParse(asStr(j['createdAt'])));
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.id,
    required this.number,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.recipientName,
    required this.address,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.deliveryFeeMinor,
    required this.serviceFeeMinor,
    required this.totalMinor,
    required this.items,
    required this.timeline,
    required this.payments,
    required this.issues,
    required this.allowedNext,
    this.slotLabel,
    this.instructions,
    this.promoCode,
    this.operatorNotes,
    this.recipientPhone,
    this.courierName,
    this.courierPhone,
  });

  final String id, number, status, paymentStatus, paymentMethod, recipientName;
  final OrderAddress address;
  final String? slotLabel, instructions, promoCode, operatorNotes, recipientPhone, courierName, courierPhone;
  final int subtotalMinor, discountMinor, deliveryFeeMinor, serviceFeeMinor, totalMinor;
  final List<OrderItem> items;
  final List<TimelineEntry> timeline;
  final List<PaymentRow> payments;
  final List<OrderIssue> issues;
  final List<String> allowedNext;

  /// Refund is offered only for a paid order that has ended (cancelled or delivered).
  bool get canRefund => paymentStatus == 'SUCCEEDED' && (status == 'CANCELLED' || status == 'DELIVERED');
  bool get canAssignCourier => status == 'READY_FOR_DELIVERY';

  factory OrderDetailModel.fromJson(Map<String, dynamic> j) {
    final o = j['order'] as Map<String, dynamic>;
    final slot = o['slot'] as Map<String, dynamic>?;
    final courier = j['courier'] as Map<String, dynamic>?;
    return OrderDetailModel(
      id: asStr(o['id']),
      number: asStr(o['number']),
      status: asStr(o['status']),
      paymentStatus: asStr(o['paymentStatus']),
      paymentMethod: asStr(o['paymentMethod']),
      recipientName: asStr(o['recipientName']),
      address: OrderAddress.fromJson((o['address'] as Map<String, dynamic>?) ?? const {}),
      slotLabel: slot == null ? null : '${asStr(slot['date'])} ${hhmm(asStr(slot['start']))}–${hhmm(asStr(slot['end']))}',
      instructions: o['instructions'] as String?,
      subtotalMinor: asInt(o['subtotalMinor']),
      discountMinor: asInt(o['discountMinor']),
      deliveryFeeMinor: asInt(o['deliveryFeeMinor']),
      serviceFeeMinor: asInt(o['serviceFeeMinor']),
      totalMinor: asInt(o['totalMinor']),
      promoCode: o['promoCode'] as String?,
      items: asList(o['items']).map(OrderItem.fromJson).toList(),
      timeline: asList(o['timeline']).map(TimelineEntry.fromJson).toList(),
      operatorNotes: j['operatorNotes'] as String?,
      recipientPhone: j['recipientPhone'] as String?,
      courierName: courier?['name'] as String?,
      courierPhone: courier?['phone'] as String?,
      payments: asList(j['payments']).map(PaymentRow.fromJson).toList(),
      issues: asList(j['issues']).map(OrderIssue.fromJson).toList(),
      allowedNext: ((j['allowedNext'] as List?) ?? const []).cast<String>(),
    );
  }
}

/// "10:00:00" -> "10:00".
String hhmm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<Paged<OrderRow>> list(OrderQuery q) async {
    final r = await _api.get('/admin/orders', query: {
      'page': q.page,
      'size': 25,
      if (q.q.isNotEmpty) 'q': q.q,
      if (q.status.isNotEmpty) 'status': q.status,
    });
    return Paged.fromJson(r as Map<String, dynamic>, OrderRow.fromJson);
  }

  Future<OrderDetailModel> get(String id) async => OrderDetailModel.fromJson(await _api.get('/admin/orders/$id') as Map<String, dynamic>);

  Future<void> changeStatus(String id, String status) => _api.post('/admin/orders/$id/status', body: {'status': status});
  Future<void> refund(String id) => _api.post('/admin/orders/$id/refund');
  Future<void> assign(String id, String courierId) => _api.post('/admin/orders/$id/assign', body: {'courierId': courierId});
  Future<void> saveNotes(String id, String notes) => _api.post('/admin/orders/$id/notes', body: {'notes': notes});
}
