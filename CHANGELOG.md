# Changelog

All notable versioned releases of the AMAL Flutter Android app.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0/).

## [1.1.0] — 2026-11-24

### Added

- Delivery-aware checkout screen: customer details, state/city/address,
  delivery method, live fee and total, then a complete WhatsApp order summary
- Shop pagination with infinite scroll (all 735+ products are reachable) plus
  price, rating and in-stock filters and debounced search
- Product variants (color/size), quantity stepper, specifications, flash-sale
  countdown, product video link, verified reviews and related products
- Cart lines are variant-aware and quantity is capped at available stock
- Review model and catalog queries (`reviews`, related products)
- Home free-delivery-zone sheet with published rates
- Widget, cart, and model tests covering the new flows

### Changed

- Upgraded `supabase_flutter` API usage (`publishableKey`, typed PostgREST
  builders) so the project compiles with the locked dependency set
- Product cards show an out-of-stock badge; account screen lists delivery
  options and email support
- Branded launcher icon (AMAL mark) with an Android adaptive icon, plus a
  square `amal-icon.png` used in the app header, welcome and account screens
- Android launcher label and app title are now **AMAL Market Link**
- Welcome screen's second action opens the live web shop instead of duplicating
  guest entry
- Catalog search sanitizes PostgREST control characters
- Delivery fee no longer treats an empty city as a free zone
- Release CI pins Flutter `3.50.1` and uses Android Gradle Plugin `9.1.1`
  with Gradle `9.5.0`
- Version bumped to `1.1.0+2`; removed the unused `shimmer` dependency

### Fixed

- Compile errors in `CatalogService` caused by assigning PostgREST transform
  builders to filter-builder variables
- Home "Free delivery zones" chip was a no-op
- Category tiles rendered raw icon names such as `Tv`/`Smartphone` instead of icons

### Documentation

- Updated README, architecture, release guide and engineering log
- Release workflow now gates on `flutter analyze` and `flutter test`,
  and uploads a SHA-256 checksum next to the APK

[1.1.0]: https://github.com/Icedmist/amal-marketplace/releases/tag/v1.1.0

## [1.0.0] — 2026-11-24

### Added

- Flutter Android app for AMAL — Ahmad Market Link
- Live Supabase catalog (home, shop, product detail)
- Local cart & wishlist with WhatsApp checkout
- GitHub Actions workflow: each GitHub Release / `v*` tag builds and attaches `amal-<tag>.apk`
- Documentation: architecture, release process, and per-change engineering log

[1.0.0]: https://github.com/Icedmist/amal-marketplace/releases/tag/v1.0.0
