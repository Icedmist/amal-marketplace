# AMAL — Ahmad Market Link (Flutter)

Android Flutter client for **[AMAL Marketplace](https://amal-market-place.lovable.app)** (Ahmad Market Link) — phones, fashion, electronics, groceries and home essentials with delivery across Nigeria and free delivery in Yola North, Jimeta, Girei and Sangere FUTY.

## Features

- **Live catalog** from the same Supabase backend as the web app (735+ published products)
- **Shop** with debounced search, category filters, price/rating/stock filters, sorting and infinite-scroll pagination
- **Product detail** with color/size selection, quantity stepper, specifications, verified reviews, product video and related products
- **Delivery-aware checkout** — customer details, state/city, delivery method and live delivery fee, then a prefilled WhatsApp order summary
- **Cart & wishlist** persisted locally with `shared_preferences`; cart separates variants and caps quantities at available stock
- **Guest shopping** — no account required for v1
- **WhatsApp support** (CEO + Marketing Manager), brand offices and free-delivery zones

## Run locally

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run
```

Release APK:

```bash
flutter build apk --release
```

## Checkout (v1)

Checkout collects the customer's name, phone, state, city, address and delivery
method, calculates the delivery fee from the published zone rates, and opens
WhatsApp with a complete order summary. AMAL confirms stock, payment and
delivery in the chat. No payment is taken inside the app.

Cart and wishlist are device-local; the `orders` table is not written yet (see
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#known-gaps)).

## Documentation

| Doc | Purpose |
|-----|---------|
| [CHANGELOG.md](CHANGELOG.md) | Versioned release notes |
| [docs/CHANGELOG.md](docs/CHANGELOG.md) | Per-change engineering log |
| [docs/RELEASE.md](docs/RELEASE.md) | How GitHub Releases trigger APK builds |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | App structure, backend and known gaps |

## Release → APK workflow

Publishing a GitHub Release (or pushing a `v*` tag) runs [`.github/workflows/release-apk.yml`](.github/workflows/release-apk.yml):

1. Installs dependencies
2. Runs `flutter analyze --fatal-infos` and `flutter test`
3. Builds a release APK
4. Names it `amal-<tag>.apk` (example: `amal-v1.1.0.apk`), writes a SHA-256 checksum
5. Uploads both files to that GitHub Release

Optional secrets for Play-ready signing: `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

See [docs/RELEASE.md](docs/RELEASE.md) for the full flow and first-push steps.

## Source web app

- Preview / shop: https://amal-market-place.lovable.app
- Package ID: `com.ahmadmarketlink.amal_marketplace`
- Version: `1.1.0+2`

> Repository: https://github.com/Icedmist/amal-marketplace
