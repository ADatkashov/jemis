/// Build-time configuration.
///
/// By default the admin console calls the API on its own origin (`/api/v1/...`): nginx (docker compose) and the
/// Render rewrite route proxy `/api/*` to the backend, so no CORS is needed. For `flutter run` against a backend on
/// another origin: `--dart-define=API_BASE_URL=http://localhost:8080` (that origin must be in `JEMIS_CORS_ORIGINS`).
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
}
