import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Future<void> login(String identifier, String password) async {
    final r = await _api.post('/auth/login', body: {'identifier': identifier, 'password': password}) as Map<String, dynamic>;
    _tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
  }

  Future<void> logout() async {
    final rt = _tokens.refresh;
    if (rt != null) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': rt});
      } on AppException {
        // best effort: the local session is dropped either way
      }
    }
    _tokens.clear();
  }
}
