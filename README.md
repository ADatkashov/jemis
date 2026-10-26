# JEMIS — grocery delivery (Almaty)

Modular monolith: `backend/` (Spring Boot 3, Java 17, PostgreSQL, Flyway), `admin/` (React + TypeScript + Vite),
`mobile/` (Flutter, Riverpod, GoRouter, Dio; ru/kk/en).

## Quick start (local)
```bash
# 1. PostgreSQL (database `jemis`, user `jemis`)
# 2. Backend with DEMO data (dev profile only!)
cd backend && JEMIS_DB_PASSWORD=<pwd> SPRING_PROFILES_ACTIVE=dev ./gradlew bootRun
#    demo accounts (dev only): admin@jemis.local / Admin12345!, customer@jemis.local / Customer123!, courier@jemis.local / Courier123!
# 3. Admin:  cd admin && npm ci && npm run dev      (http://localhost:5173)
# 4. Mobile: cd mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
Production-like stack: copy `.env.example` to `.env`, then `docker compose up --build`.

## Tests
`cd backend && ./gradlew test` (needs PostgreSQL `jemis_test`, see `application-test.yml`) ·
`cd admin && npm test && npm run build` · `cd mobile && flutter analyze && flutter test`

## Configuration
See `.env.example`. The backend refuses to start without `JEMIS_JWT_SECRET` (>= 32 bytes).
The mock payment provider and demo data are enabled only by the `dev` profile.

## Not implemented / needs external credentials
- Real payment provider (e.g. FreedomPay): only the provider interface, signed idempotent webhooks and a DEV-ONLY mock exist.
- SMS/email (password reset delivery), push (FCM), geocoding/maps and live courier GPS are interfaces only; the app says so instead of faking them.
- Delivery zones match by city name; no polygon/geocoding. Product images are URLs (no upload); placeholders are shown when absent.
- Docker files and the CI workflow were written but not executed in this environment (no Docker daemon). iOS/Android release builds were not performed (no mobile SDKs here); Flutter was verified with `analyze` and widget tests only.
- Freezed/codegen is not used; models are hand-written.
- Rate limiting is in-memory per instance.
