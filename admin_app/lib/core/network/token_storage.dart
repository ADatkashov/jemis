import 'session_store.dart';
import 'session_store_stub.dart' if (dart.library.js_interop) 'session_store_web.dart';

class TokenStorage {
  TokenStorage([SessionStore? store]) : _s = store ?? createSessionStore();
  final SessionStore _s;

  static const _access = 'jemis.admin.access';
  static const _refresh = 'jemis.admin.refresh';

  String? get access => _s.read(_access);
  String? get refresh => _s.read(_refresh);
  bool get hasSession => refresh != null;

  void save(String access, String refresh) {
    _s.write(_access, access);
    _s.write(_refresh, refresh);
  }

  void clear() {
    _s.write(_access, null);
    _s.write(_refresh, null);
  }
}
