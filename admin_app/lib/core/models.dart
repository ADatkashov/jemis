/// JSON helpers: the backend sends integers for money/quantities and omits null fields.
int asInt(Object? v) => (v as num?)?.toInt() ?? 0;
int? asIntOrNull(Object? v) => (v as num?)?.toInt();
String asStr(Object? v) => v as String? ?? '';
List<Map<String, dynamic>> asList(Object? v) => ((v as List?) ?? const []).cast<Map<String, dynamic>>();

class Paged<T> {
  const Paged({required this.items, required this.page, required this.totalPages, required this.totalElements});

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;

  factory Paged.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) f) => Paged(
        items: asList(j['items']).map(f).toList(),
        page: asInt(j['page']),
        totalPages: asInt(j['totalPages']),
        totalElements: asInt(j['totalElements']),
      );
}
