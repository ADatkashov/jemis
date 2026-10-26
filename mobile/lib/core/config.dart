/// Build-time configuration: `flutter run --dart-define=API_BASE_URL=https://api.example.com`.
class AppConfig {
  /// 10.0.2.2 is the host machine as seen from the Android emulator.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  /// Optional support phone number shown on the order screen. Empty = support entry shows a notice.
  static const supportPhone = String.fromEnvironment('SUPPORT_PHONE');

  static const defaultCity = String.fromEnvironment('DEFAULT_CITY', defaultValue: 'Алматы');
}
