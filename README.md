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

## Screenshots

Captured against the real backend (`dev` profile, demo data). Mobile shots come from the Flutter web build (390×844 @2x), not a device.

### Admin (`admin/`)

<img src="docs/screenshots/admin/00-login.png" alt="login" width="320"> <img src="docs/screenshots/admin/01-dashboard.png" alt="dashboard" width="320"> <img src="docs/screenshots/admin/02-orders.png" alt="orders" width="320"> <img src="docs/screenshots/admin/03-products.png" alt="products" width="320"> <img src="docs/screenshots/admin/04-categories.png" alt="categories" width="320"> <img src="docs/screenshots/admin/05-delivery.png" alt="delivery" width="320"> <img src="docs/screenshots/admin/06-promotions.png" alt="promotions" width="320"> <img src="docs/screenshots/admin/07-customers.png" alt="customers" width="320"> <img src="docs/screenshots/admin/08-staff.png" alt="staff" width="320"> <img src="docs/screenshots/admin/09-settings.png" alt="settings" width="320"> <img src="docs/screenshots/admin/10-audit.png" alt="audit" width="320"> <img src="docs/screenshots/admin/11-order-detail.png" alt="order detail" width="320"> 

### Customer app (`mobile/`)

<img src="docs/screenshots/mobile/01-home-guest.png" alt="home guest" width="160"> <img src="docs/screenshots/mobile/02-catalog-guest.png" alt="catalog guest" width="160"> <img src="docs/screenshots/mobile/03-product.png" alt="product" width="160"> <img src="docs/screenshots/mobile/04-cart-guest.png" alt="cart guest" width="160"> <img src="docs/screenshots/mobile/05-login.png" alt="login" width="160"> <img src="docs/screenshots/mobile/06-register.png" alt="register" width="160"> <img src="docs/screenshots/mobile/09-home.png" alt="home" width="160"> <img src="docs/screenshots/mobile/11-catalog-added.png" alt="catalog added" width="160"> <img src="docs/screenshots/mobile/12-product-auth.png" alt="product auth" width="160"> <img src="docs/screenshots/mobile/13-cart.png" alt="cart" width="160"> <img src="docs/screenshots/mobile/15-checkout-slot.png" alt="checkout slot" width="160"> <img src="docs/screenshots/mobile/17-orders.png" alt="orders" width="160"> <img src="docs/screenshots/mobile/18-order-detail.png" alt="order detail" width="160"> <img src="docs/screenshots/mobile/19-profile.png" alt="profile" width="160"> <img src="docs/screenshots/mobile/20-addresses.png" alt="addresses" width="160"> <img src="docs/screenshots/mobile/21-address-new.png" alt="address new" width="160"> <img src="docs/screenshots/mobile/22-favorites.png" alt="favorites" width="160"> <img src="docs/screenshots/mobile/23-notifications.png" alt="notifications" width="160"> <img src="docs/screenshots/mobile/24-edit-profile.png" alt="edit profile" width="160"> 

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
