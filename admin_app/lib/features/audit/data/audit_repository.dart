import '../../../core/models.dart';
import '../../../core/network/api_client.dart';

class AuditRow {
  const AuditRow({this.createdAt, this.actorEmail, required this.action, required this.entity, this.entityId, this.details});
  final DateTime? createdAt;
  final String? actorEmail, entityId, details;
  final String action, entity;
  factory AuditRow.fromJson(Map<String, dynamic> j) => AuditRow(
      createdAt: DateTime.tryParse(asStr(j['createdAt'])),
      actorEmail: j['actorEmail'] as String?,
      action: asStr(j['action']),
      entity: asStr(j['entity']),
      entityId: j['entityId'] as String?,
      details: j['details'] as String?);
}

class AuditRepository {
  AuditRepository(this._api);
  final ApiClient _api;

  Future<List<AuditRow>> latest() async => asList(await _api.get('/admin/audit-log', query: {'size': 100})).map(AuditRow.fromJson).toList();
}
