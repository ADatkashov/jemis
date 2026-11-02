import 'package:web/web.dart' as web;

import 'session_store.dart';

SessionStore createSessionStore() => _BrowserSessionStore();

/// `window.sessionStorage`; every access is guarded because storage can be blocked (private mode, policies).
class _BrowserSessionStore implements SessionStore {
  @override
  String? read(String key) {
    try {
      return web.window.sessionStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String? value) {
    try {
      if (value == null) {
        web.window.sessionStorage.removeItem(key);
      } else {
        web.window.sessionStorage.setItem(key, value);
      }
    } catch (_) {
      // storage unavailable: the session just won't survive a reload
    }
  }
}
