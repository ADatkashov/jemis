/// Where the session tokens live between page reloads of one browser tab.
///
/// The old React admin used `sessionStorage`; this keeps the same behaviour: tokens survive a reload but are gone
/// when the tab is closed. On non-web platforms (unit tests) the store is a plain in-memory map.
abstract class SessionStore {
  String? read(String key);
  void write(String key, String? value);
}

class MemorySessionStore implements SessionStore {
  final _m = <String, String>{};
  @override
  String? read(String key) => _m[key];
  @override
  void write(String key, String? value) {
    if (value == null) {
      _m.remove(key);
    } else {
      _m[key] = value;
    }
  }
}
