import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class LowStockItem {
  const LowStockItem({required this.id, required this.sku, required this.name, required this.availableMilli});
  final String id, sku, name;
  final int availableMilli;
  factory LowStockItem.fromJson(Map<String, dynamic> j) =>
      LowStockItem(id: asStr(j['id']), sku: asStr(j['sku']), name: asStr(j['name']), availableMilli: asInt(j['availableMilli']));
}

class RecentOrder {
  const RecentOrder({required this.id, required this.number, required this.status, required this.paymentStatus, required this.totalMinor});
  final String id, number, status, paymentStatus;
  final int totalMinor;
  factory RecentOrder.fromJson(Map<String, dynamic> j) => RecentOrder(
      id: asStr(j['id']), number: asStr(j['number']), status: asStr(j['status']), paymentStatus: asStr(j['paymentStatus']), totalMinor: asInt(j['totalMinor']));
}

class Dashboard {
  const Dashboard({
    required this.ordersToday,
    required this.paidRevenueTodayMinor,
    required this.currency,
    required this.awaitingProcessing,
    required this.inDelivery,
    required this.lowStockCount,
    required this.lowStock,
    required this.recentOrders,
  });
  final int ordersToday, paidRevenueTodayMinor, awaitingProcessing, inDelivery, lowStockCount;
  final String currency;
  final List<LowStockItem> lowStock;
  final List<RecentOrder> recentOrders;

  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
        ordersToday: asInt(j['ordersToday']),
        paidRevenueTodayMinor: asInt(j['paidRevenueTodayMinor']),
        currency: (j['currency'] as String?) ?? 'KZT',
        awaitingProcessing: asInt(j['awaitingProcessing']),
        inDelivery: asInt(j['inDelivery']),
        lowStockCount: asInt(j['lowStockCount']),
        lowStock: asList(j['lowStock']).map(LowStockItem.fromJson).toList(),
        recentOrders: asList(j['recentOrders']).map(RecentOrder.fromJson).toList(),
      );
}

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;
  Future<Dashboard> load() async => Dashboard.fromJson(await _api.get('/admin/dashboard') as Map<String, dynamic>);
}
