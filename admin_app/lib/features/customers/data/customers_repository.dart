import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class CustomerRow {
  const CustomerRow({required this.id, required this.fullName, this.email, this.phone, required this.status});
  final String id, fullName, status;
  final String? email, phone;
  factory CustomerRow.fromJson(Map<String, dynamic> j) =>
      CustomerRow(id: asStr(j['id']), fullName: asStr(j['fullName']), email: j['email'] as String?, phone: j['phone'] as String?, status: asStr(j['status']));
}

class CustomerOrder {
  const CustomerOrder({required this.id, required this.number, required this.status, required this.totalMinor, this.createdAt});
  final String id, number, status;
  final int totalMinor;
  final DateTime? createdAt;
  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
      id: asStr(j['id']), number: asStr(j['number']), status: asStr(j['status']), totalMinor: asInt(j['totalMinor']), createdAt: DateTime.tryParse(asStr(j['createdAt'])));
}

class CustomerDetail {
  const CustomerDetail({required this.customer, required this.orders});
  final CustomerRow customer;
  final List<CustomerOrder> orders;
  factory CustomerDetail.fromJson(Map<String, dynamic> j) => CustomerDetail(
      customer: CustomerRow.fromJson(j['customer'] as Map<String, dynamic>), orders: asList(j['orders']).map(CustomerOrder.fromJson).toList());
}

class CustomerQuery {
  const CustomerQuery({this.q = '', this.page = 0});
  final String q;
  final int page;
  @override
  bool operator ==(Object other) => other is CustomerQuery && other.q == q && other.page == page;
  @override
  int get hashCode => Object.hash(q, page);
}

class CustomersRepository {
  CustomersRepository(this._api);
  final ApiClient _api;

  Future<Paged<CustomerRow>> list(CustomerQuery q) async =>
      Paged.fromJson(await _api.get('/admin/customers', query: {'page': q.page, 'q': q.q}) as Map<String, dynamic>, CustomerRow.fromJson);

  Future<CustomerDetail> detail(String id) async => CustomerDetail.fromJson(await _api.get('/admin/customers/$id') as Map<String, dynamic>);
}
