# Tayran (طيران)

Quick-commerce groceries for villages in Egypt. Arabic first (RTL), English second.

Phase 1 covers sign-in / sign-up up to the home screen:
phone → OTP → (new user: name → address) → home.

```
backend/   Spring Boot 4.1 (Java 21) + PostgreSQL + Flyway
mobile/    Flutter app (Riverpod, go_router, dio)
```

## Prerequisites

- JDK 21 (`JAVA_HOME` must point at it; Maven uses it)
- Maven 3.9+ (or `backend/mvnw`)
- Docker Desktop (local Postgres and the integration test)
- Flutter SDK (Dart 3.12+, Flutter 3.44+) with Android Studio and an Android emulator

## 1. Start Postgres

```bash
cd backend
docker compose up -d
```

This starts PostgreSQL 17 on `localhost:5433` (database, user and password are all `tayran`).
Port 5433 is used on purpose, so it doesn't clash with a PostgreSQL already installed on 5432.

## 2. Run the backend (dev profile)

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

- The API is at `http://localhost:8080/api/v1`, and Swagger UI at `http://localhost:8080/api/v1/swagger-ui.html`.
- Flyway creates the schema, seeds the 8 main categories, and in `dev` only loads the
  sample villages and streets (`db/testdata`, marked TEST DATA).
- The `dev` profile has local-only defaults for `JWT_SECRET` and `OTP_HASH_SECRET`. Any
  other profile needs both set as environment variables (`JWT_SECRET` must be at least 32 bytes),
  plus `DB_URL`, `DB_USERNAME` and `DB_PASSWORD`.

### Where to find the dev OTP

There is no SMS provider yet. In the `dev` profile the code is printed in the backend log:

```
[DEV OTP] phone=+201012345678 code=4821
```

Outside `dev` the log only says `OTP sent to *********5678`.

## 3. Run the app on an Android emulator

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` is how the Android emulator reaches your computer's `localhost`, and it's also the
default when `API_BASE_URL` isn't set. On a real phone, use your computer's LAN IP instead
(`http://192.168.x.x:8080/api/v1`). Debug builds allow plain HTTP; release builds don't.

If port 8080 is taken on your machine, start the backend with `SERVER_PORT=8081` (any free
port) and pass the same port in `API_BASE_URL`.

The app follows the system light/dark setting.

## Tests

```bash
cd backend
mvn test
```

- Unit tests: phone normalization, the OTP service (expiry, attempts, resend window, hourly
  limit) and the next-step logic.
- `AuthFlowIntegrationTest` runs the whole API flow against a real PostgreSQL with
  Testcontainers. It needs Docker running and is skipped when Docker isn't available.

```bash
cd mobile
flutter test
```

## API (prefix `/api/v1`)

Every response uses the same wrapper:

```json
{ "success": true, "messageEn": "SUCCESS", "messageAr": "تم بنجاح", "content": { } }
{ "success": false, "code": "OTP_INVALID", "messageEn": "...", "messageAr": "...", "content": { "remainingAttempts": 3 } }
```

| Method | Path | Auth | Body | `content` |
|---|---|---|---|---|
| POST | `/auth/otp/request` | – | `{phone}` | `{challengeId, expiresInSeconds, resendAfterSeconds}` |
| POST | `/auth/otp/verify` | – | `{challengeId, code}` | `{accessToken, refreshToken, nextStep}` |
| POST | `/auth/refresh` | – | `{refreshToken}` | `{accessToken, refreshToken, nextStep}` (the refresh token is rotated) |
| PUT | `/me/name` | Bearer | `{firstName, lastName}` | `{nextStep}` |
| GET | `/locations` | – | – | `{villages:[{id, nameAr, nameEn, streets:[…]}]}`, with `ETag` and `Cache-Control`; 304 on `If-None-Match` |
| POST | `/me/address` | Bearer | `{villageId, streetId, landmark}` | `{nextStep: "HOME"}` |
| GET | `/app/bootstrap` | Bearer | – | `{nextStep, firstName, address, etaText, etaMinutes, categories}` |

Error codes: `INVALID_PHONE`, `OTP_INVALID`, `OTP_EXPIRED`, `OTP_TOO_MANY_ATTEMPTS`,
`OTP_RESEND_TOO_SOON` (429), `OTP_RATE_LIMITED` (429), `VALIDATION_ERROR`, `INVALID_STREET`,
`UNAUTHORIZED` (401), `TOKEN_EXPIRED` (401), plus `NOT_FOUND`, `METHOD_NOT_ALLOWED` and
`INTERNAL_ERROR`. Messages live in `backend/src/main/resources/files/error-map.json`.

## Design source

Tokens, fonts and art come from the design export (`Tayran-design-export`): the colors,
spacing, radius, shadows and type scale are in `mobile/lib/core/theme/tokens.dart`. The
IBM Plex Sans Arabic fonts were converted from the export's `.woff2` files to `.ttf`, which
Flutter needs (license in `mobile/assets/fonts/OFL.txt`).
