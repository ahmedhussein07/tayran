# Tayran mobile app

Flutter app for Tayran (طيران), Arabic first (RTL). Phase 1: phone → OTP → name → address → home.

Setup, running on an emulator and the API it talks to are in the [root README](../README.md).

- `lib/core/theme/tokens.dart`: design tokens from the design export (colors, spacing, radius, shadows, type)
- `lib/core/`: network, session, router, strings and shared widgets
- `lib/features/`: `auth` (phone, OTP), `onboarding` (name, address), `home`
- `brand/`: sources for the launcher icon, splash and home banners, and the category photo credits (not bundled)
