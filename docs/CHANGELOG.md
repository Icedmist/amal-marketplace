# Engineering change log

Track **every meaningful change** here (not only version bumps).  
Keep newest entries at the top. Link PRs/commits when available.

---

## 2026-11-24 — v1.1.0: compile fix, checkout and catalog completion

**Why:** A functionality review found the app did not compile against the locked
Supabase packages, the shop exposed only 48 of 735 products, delivery rates were
unused, and product variants/reviews/specs were parsed but never shown.

### Changes

1. **Compile / dependency fixes**
   - `lib/services/catalog_service.dart`: PostgREST filters stay on the filter
     builder; ordering/range/count moved to transform builders.
   - `lib/main.dart`: `Supabase.initialize(publishableKey: …)` (removed the
     deprecated `anonKey` argument).
   - Regenerated `pubspec.lock` with `flutter pub get`; removed unused `shimmer`.

2. **Catalog & shop**
   - Infinite-scroll pagination (`page`/`limit`), total count, request-guard for
     stale responses.
   - Price / minimum-rating / in-stock filter sheet; debounced search; search
     term sanitized for PostgREST grammar.
   - Related products and reviews queries added; review model in
     `lib/models/review.dart`.
   - Delivery fee no longer treats an empty city as a free zone.

3. **Product detail**
   - Color/size selection, quantity stepper capped at stock, specifications,
     flash countdown, video link, verified reviews and related products.
   - Fetch failure now offers a retry instead of a dead "not found" screen.

4. **Cart & checkout**
   - Variant-aware cart lines (`productId|color|size`), stock-capped quantities.
   - New `lib/screens/checkout_screen.dart`: contact + address form, delivery
     method and live fee, order summary, WhatsApp handoff, cart cleared only
     after a successful launch.
   - Cart shows variant labels, stock hints and routes to checkout.

5. **Home, account & branding**
   - Free-delivery chip opens a rates sheet; category icons mapped to Material
     icons; deals include flash/daily-deal flags.
   - Account lists delivery options and email support; about copy matches the
     WhatsApp checkout; welcome's second action opens the web shop.
   - Launcher label/app title set to **AMAL Market Link**; launcher icon replaced
     with the AMAL mark (legacy mipmaps + adaptive icon), plus a square in-app
     `assets/brand/amal-icon.png`.

6. **Tests**
   - `test/cart_state_test.dart` (variants, stock cap, persistence)
   - `test/product_model_test.dart` (payload parsing/fallbacks)
   - `test/screens_test.dart` (shell tabs, product detail, checkout validation)
   - `test/support/fakes.dart` (offline catalog fake)

7. **Release workflow / docs**
   - `flutter analyze --fatal-infos` + `flutter test` gates, concurrency,
     artifact upload, SHA-256 checksum, safer tag resolution.
   - README, CHANGELOG, ARCHITECTURE and RELEASE updated.

### Verification

- `flutter analyze --fatal-infos` → no issues
- `flutter test` → 15 tests pass
- `flutter build apk --debug` → succeeds

### Follow-ups

- [ ] Create GitHub remote and push (repository has no remote yet)
- [ ] Add Play Store upload keystore secrets for production signing
- [ ] Auth (email/OTP) + server-side order rows + order history
- [ ] In-app payments beyond WhatsApp checkout
- [ ] iOS build target / deep links

---

## 2026-11-24 — Project bootstrap

**Why:** Port AMAL marketplace (https://amal-market-place.lovable.app) to a Flutter Android app with release-tagged APK automation and documented change tracking.

### Changes

1. **Repo init**
   - Created Flutter project `amal_marketplace` (`com.ahmadmarketlink.amal_marketplace`)
   - Added brand asset `assets/brand/amal-logo.png`
   - Initialized git repository with baseline docs

2. **App core**
   - Connected to live Supabase project `jwksdthoybvvtcgtwojr` (same backend as the Lovable web app)
   - Implemented screens: Welcome, Home, Shop, Product detail, Cart, Wishlist, Account, About
   - Local cart / wishlist via `shared_preferences`
   - WhatsApp order + support links from brand config
   - Theme: navy `#0F2A5C` + gold accent, DM Sans

3. **Release automation**
   - Added `.github/workflows/release-apk.yml`
   - Triggers on: GitHub Release `published`, push of `v*` tags, and manual `workflow_dispatch`
   - Outputs `amal-<tag>.apk` attached to the matching GitHub Release

4. **Documentation**
   - `README.md`, `CHANGELOG.md`, `docs/CHANGELOG.md`, `docs/RELEASE.md`, `docs/ARCHITECTURE.md`

### Files touched (high level)

- `lib/**` — Flutter app
- `android/**` — INTERNET permission, app label `AMAL`, optional release signing
- `.github/workflows/release-apk.yml`
- `docs/**`, `CHANGELOG.md`, `README.md`
