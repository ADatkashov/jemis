import '../../../core/network/api_client.dart';

class SettingsRepository {
  SettingsRepository(this._api);
  final ApiClient _api;

  /// Insertion order of the server response is kept (a Dart map literal/`Map.from` preserves it).
  Future<Map<String, String>> load() async {
    final r = await _api.get('/admin/settings') as Map<String, dynamic>;
    return {for (final e in r.entries) e.key: '${e.value}'};
  }

  Future<void> save(Map<String, String> changed) => _api.put('/admin/settings', body: changed);
}
