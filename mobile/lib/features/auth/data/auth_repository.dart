import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Future<void> login(String identifier, String password) async {
    final r = await _api.post('/auth/login', body: {'identifier': identifier, 'password': password}) as Map<String, dynamic>;
    await _tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
  }

  Future<void> register({String? email, String? phone, required String password, required String fullName, required String locale}) async {
    final r = await _api.post('/auth/register', body: {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'fullName': fullName,
      'locale': locale,
    }) as Map<String, dynamic>;
    await _tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
  }

  Future<void> requestPasswordReset(String identifier) async => _api.post('/auth/password/reset-request', body: {'identifier': identifier});

  Future<void> logout() async {
    final rt = await _tokens.refresh;
    if (rt != null) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': rt});
      } on AppException {
        // best effort: the local session is dropped either way
      }
    }
    await _tokens.clear();
  }

  Future<bool> hasSession() async => (await _tokens.refresh) != null;
}
