# Tayran (طيران)

Quick-commerce groceries for villages in Egypt. Arabic first (RTL), English second.

- **Phase 1:** sign-in / sign-up up to home: phone → OTP → (new user: name → address) → home.
- **Phase 2:** the catalog.
  - An admin portal manages admins, categories, subcategories, products and their images.
  - Images go through a pipeline into object storage behind a CDN.
  - A publisher writes the store catalog as one immutable JSON file.
  - The app shows the category screen and product sheet from that file, with no backend call, and keeps a local cart.

```
backend/              Spring Boot 4.1 (Java 21) + PostgreSQL + Flyway
mobile/               Flutter customer app (Riverpod, go_router, dio)
admin/                Flutter Web admin portal
packages/tayran_ui/   Shared design system: tokens, theme, font, icons, base widgets, TayranImage
```

## Prerequisites

- JDK 21 (`JAVA_HOME` must point at it; Maven uses it)
- Maven 3.9+ (or `backend/mvnw`)
- Docker Desktop (local Postgres and the integration tests)
- Flutter SDK 3.47+ (Dart 3.13+) with Android Studio, an Android emulator and Chrome

## 1. Start Postgres

```bash
cd backend
docker compose up -d
```

This starts PostgreSQL 17 on `localhost:5433`. The database, user and password are all `tayran`. Port 5433 avoids clashing with a PostgreSQL already on 5432.

## 2. Run the backend (dev profile)

Set the first admin's phone and password in your shell. They are read only from the environment and never stored in code, config files or migrations:

```bash
export ADMIN_SEED_PHONE=01xxxxxxxxx
```

```bash
export ADMIN_SEED_PASSWORD='<your password: 10+ characters, a letter and a digit>'
```

```bash
cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

- **Where things are:** the API is at `http://localhost:8080/api/v1`, Swagger UI at `/api/v1/swagger-ui.html`.
- **Seed admin:** created on startup only if no admin exists. Without the two variables the backend logs a warning and skips it.
- **Dev seed (TEST DATA):** with an empty catalog, the `dev` profile seeds 8 categories, 24 subcategories and 169 products from `seed/catalog.json`. The images in `seed-images/` go through the real pipeline.
- **Images in dev:** stored under `backend/.local-cdn/` and served at `/api/v1/cdn/**`. `CDN_BASE_URL` defaults to that URL.
- **Publishing:** the catalog is published at startup in dev, then every ~90 s whenever something changed.
- **Other profiles:** `JWT_SECRET` (32+ bytes), `OTP_HASH_SECRET`, `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` and `CDN_BASE_URL` are required.
- **Port taken?** If 8080 is in use, start with `SERVER_PORT=8081` (any free port) and use that port everywhere below.

### Object storage in production (Cloudflare R2)

Run with the `r2` profile and set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` and (optionally) `R2_ENDPOINT`. Set `CDN_BASE_URL` to the bucket's public/CDN URL. Image variants and catalog files are written with `Cache-Control: public, max-age=31536000, immutable`.

### Admin portal settings

- `ADMIN_ALLOWED_ORIGINS`: comma-separated origins allowed to call `/admin/**` with credentials. Dev default: `http://localhost:5000`.
- `ADMIN_COOKIE_SECURE`: Secure flag on the refresh cookie. Default `true`. Set `false` only for plain-HTTP local runs.
- `FORWARD_HEADERS_STRATEGY=framework` behind a trusted proxy, so the login rate limit sees real client IPs.

### Where to find the dev OTP

There is no SMS provider yet. In `dev` the code is printed in the backend log: `[DEV OTP] phone=+201012345678 code=4821`.

## 3. Run the admin portal

```bash
cd admin && flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

Sign in with the seed admin. The portal keeps the access token in memory only. The refresh token is an httpOnly, SameSite=Strict cookie scoped to `/api/v1/admin/auth`, so a reload restores the session. Five wrong passwords lock an account for 15 minutes; another admin's password reset unlocks it.

## 4. Run the app on an Android emulator

Images and the catalog are served from the same `localhost` URL the browser uses. Forward the emulator's `localhost` to your computer, then run:

```bash
adb reverse tcp:8080 tcp:8080
```

```bash
cd mobile && flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

On a real phone, use your computer's LAN IP for `API_BASE_URL`. Also set `CDN_BASE_URL=http://192.168.x.x:8080/api/v1/cdn` on the backend. Debug builds allow plain HTTP; release builds don't.

How the app gets its data:

- **Home:** the bootstrap returns the active categories in admin order, the current catalog `{store, version, url}` and the image URL templates.
- **Catalog:** downloaded only when the version changes, kept on the device, and used offline.
- **Category and product screens:** read only that file, so they make no backend calls.

## Tests

```bash
cd backend && mvn test
```

- **Unit tests:**
  - phone normalization, the OTP service, the next-step logic
  - the seed admin
  - the image pipeline: variants, transparency, padding, dedupe, rejected files
  - the category / subcategory delete rules
  - the publisher: a failed write never bumps the version, old versions are deleted
- **Integration tests (Testcontainers, one shared PostgreSQL; skipped without Docker):**
  - the Phase 1 flow
  - admin auth: generic error, lockout, cookie rotation, logout, 403 for customer tokens
  - the catalog: admin uploads images and creates a category, subcategory and products, then publish; bootstrap and the catalog file reflect it, soft-deleted and inactive items are excluded, and categories show active only, in admin order

```bash
cd packages/tayran_ui && flutter test
```

```bash
cd mobile && flutter test
```

- `tayran_ui`: image variant selection.
- `mobile`: the catalog cache (no re-download for the same version, new version once, offline, corrupt cache, failed download), the catalog model and the cart summary.

## API (prefix `/api/v1`)

Every response uses the same wrapper:

```json
{ "success": true, "messageEn": "SUCCESS", "messageAr": "تم بنجاح", "content": { } }
{ "success": false, "code": "OTP_INVALID", "messageEn": "...", "messageAr": "...", "content": { "remainingAttempts": 3 } }
```

Customer:

| Method | Path | Auth | `content` |
|---|---|---|---|
| POST | `/auth/otp/request` | – | `{challengeId, expiresInSeconds, resendAfterSeconds}` |
| POST | `/auth/otp/verify` | – | `{accessToken, refreshToken, nextStep}` |
| POST | `/auth/refresh` | – | `{accessToken, refreshToken, nextStep}` (rotated) |
| PUT | `/me/name` | Bearer | `{nextStep}` |
| GET | `/locations` | – | villages and streets, with `ETag` / 304 |
| POST | `/me/address` | Bearer | `{nextStep: "HOME"}` |
| GET | `/app/bootstrap` | Bearer | `{nextStep, firstName, address, etaText, etaMinutes, categories:[{id,nameAr,nameEn,img,bg,tile}], catalog:{store,version,url}, images:{product,productWidths,category,categoryWidths}}` |
| GET | `/cdn/**` | – | dev only: local object storage |

Admin (all need an ADMIN token, except login / refresh / logout):

| Method | Path | Notes |
|---|---|---|
| POST | `/admin/auth/login` | `{phone, password}` → `{accessToken, expiresInSeconds, admin}` + refresh cookie |
| POST | `/admin/auth/refresh` · `/admin/auth/logout` | use the cookie |
| GET / PUT | `/admin/me` · `/admin/me/password` | |
| GET / POST / PUT / DELETE | `/admin/users[/{id}]`, PUT `/admin/users/{id}/password` | |
| POST | `/admin/images?kind=CATEGORY\|PRODUCT` | multipart `file` → `{hash, bg, previewUrl}` |
| GET / POST / PUT / DELETE | `/admin/categories[/{id}]`, PUT `/{id}/active`, PUT `/order` | delete only when empty |
| … | `/admin/categories/{id}/subcategories[/{subId}]` (+ `/active`, `/order`) | delete only with no products, deleted ones included |
| GET / POST / PUT / DELETE | `/admin/products[/{id}]` | list filters: `q, categoryId, subcategoryId, active, available, page, size`; delete is soft |

Error codes and their HTTP status live in `backend/src/main/resources/files/error-map.json`.

## Design source

Tokens, fonts and art come from the design export (`Tayran-design-export`). The colours, spacing, radius, shadows and type scale are in `packages/tayran_ui/lib/src/theme/tokens.dart`. The IBM Plex Sans Arabic fonts were converted from the export's `.woff2` files to `.ttf` (license in `packages/tayran_ui/assets/fonts/OFL.txt`).
