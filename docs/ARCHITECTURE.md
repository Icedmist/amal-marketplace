# Architecture

## Overview

```
Flutter app (Android)
  └─ CatalogService ──► Supabase REST (products, categories, reviews)
  └─ CartState / WishlistState ──► SharedPreferences (device-local)
  └─ CheckoutScreen ──► delivery fee + order summary ──► wa.me
```

The mobile app is a native Flutter client for the same marketplace as:

- https://amal-market-place.lovable.app

## Backend

| Item | Value |
|------|--------|
| Supabase URL | `https://jwksdthoybvvtcgtwojr.supabase.co` |
| Auth key | Publishable key (same as web; RLS-protected) |
| Tables read | `products`, `categories`, `reviews` |
| Tables not written | `orders`, `reviews` (see known gaps) |

Product list fields mirror the web catalog select list (price, sale_price,
flags, stock, colors, sizes, specifications, images, etc.). Only `published`
products are queried.

The catalog currently contains **735 published products**; the shop pages
through all of them (24 per request) instead of stopping at the first screen.

## App modules

| Path | Role |
|------|------|
| `lib/config/` | Brand copy, delivery rates, Nigerian states, Supabase config |
| `lib/models/` | `Product`, `CategoryItem`, `ProductReview`, `ProductPage` |
| `lib/services/` | Catalog, search, pagination, related products, reviews |
| `lib/state/` | Variant-aware cart and wishlist |
| `lib/screens/` | UI flows including checkout |
| `lib/theme/` | Navy/gold Material 3 theme |
| `lib/widgets/` | Cards, rails, money formatting, empty states |

## Catalog queries

`CatalogService.fetchProducts` supports:

- full-text-ish search over name/brand/description (sanitized for PostgREST)
- category, price range, minimum rating and in-stock filters
- sorts: recommended, newest, price asc/desc, rating, best selling
- `page` + `limit` pagination with an exact total count

The shop keeps accumulated items, fetches the next page near the bottom, and
ignores responses from superseded searches (request id guard).

## Product detail

- Color and size chips are required when the product defines them.
- Quantity is capped at `stock`; out-of-stock products cannot be added.
- Specifications render key/value pairs (including lists/maps).
- Flash sales show a countdown when `is_flash_sale` and `flash_ends_at` are set.
- Reviews are read from the `reviews` table (author, rating, comment, verified
  badge). Writing reviews is not enabled in v1.
- "You may also like" loads up to 12 related products from the same category.

## Cart

Cart lines are keyed by `productId|color|size`, so variants stay separate. The
cart is persisted in `SharedPreferences` (`amal_cart_v1`) and restored on
launch. Quantities are clamped to the stock snapshot stored with the line.

Wishlist snapshots are also stored in `SharedPreferences`
(`amal_wishlist_v1`). Product data in a wishlist is not refreshed in v1; opening
an item fetches the current product detail from Supabase.

## Checkout (v1)

`CheckoutScreen` collects:

- full name and phone
- state (all 36 states + FCT), city and delivery address
- delivery method: standard, express or pick-up at the Jimeta shop
- optional order notes

The delivery fee comes from `AmalBrand.deliveryFee`:

| Destination | Standard | Express |
|-------------|----------|---------|
| Yola North / Jimeta / Girei / Sangere FUTY | Free | ₦1,000 |
| Rest of Adamawa | ₦2,000 | ₦3,500 |
| Nationwide | ₦5,000 | ₦8,500 |
| Pick up at shop | Free | Free |

The app then opens `wa.me` with items, variants, subtotal, delivery, total and
customer details. The cart is cleared only when WhatsApp launches successfully.
No payment is collected in the app.

## Known gaps

- **Authentication / accounts** — guest-only; Supabase auth is not wired.
- **Server-side orders** — no `orders` inserts, order history or tracking.
- **Reviews** — read-only; customers cannot submit a review from the app.
- **Products list** — single `image_url` and optional `video_url`; there is no
  multi-image gallery.
- **Wishlist freshness** — stored snapshots are not periodically refreshed.
- **Notifications / deep links** — no push notifications or app links.
- **iOS / web builds** — Android only at the moment.

These are intentional v1 follow-ups and are tracked in
[docs/CHANGELOG.md](CHANGELOG.md#2026-11-24--v110-compile-fix-checkout-and-catalog-completion).
