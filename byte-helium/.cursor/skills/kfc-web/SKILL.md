---
name: kfc-web
description: KFC brand-specific web & native UI patterns — location flow, OccasionFirstDialog, cart dialog, and re-localization. Use when working in libs/brand-kfc/, apps/web-app-kfc-au/, apps/expo-app-kfc-au/, or when the user mentions KFC location, occasion dialog, cart dialog, re-localize, or store selection.
---

# KFC — Brand-Specific Patterns

> KFC overrides several core modules with brand-specific implementations in `libs/brand-kfc/`.

## Key paths

| What | Where |
|------|-------|
| KFC brand library | `libs/brand-kfc/src/` |
| Web module overrides | `libs/brand-kfc/src/modules/index.ts` |
| Native module overrides | `libs/brand-kfc/src/modules/index.native.ts` |
| OccasionFirstDialog (web) | `libs/brand-kfc/src/modules/OccasionFirstDialog/index.tsx` |
| KFC Cart page screen (web) | `libs/brand-kfc/src/screens/Cart/index.tsx` |
| Location chip (header button) | `libs/brand-kfc/src/modules/AppBarLocation/LocationButton.tsx` |
| Native MenuListStackNavigator | `libs/brand-kfc/src/native/navigation/MenuListStackNavigator.tsx` |
| Core location dialog wiring | `libs/web-core-framework/src/location/components/location-dialog/` |

> Note: KFC no longer overrides the cart via a `CartDialog` module/`CartDialogModule` (those paths
> are gone from source; only stale coverage artifacts remain). KFC now has a dedicated `/cart` **page
> screen** at `libs/brand-kfc/src/screens/Cart/index.tsx` that renders core `InteractiveCart`.

## Dialog pattern (shared by location & cart)

KFC uses **URL-query-param-driven MUI Dialogs** for overlay screens. The pattern is:

1. A trigger sets `?modal=<type>` on the current URL
2. An orchestrator module reads the query param and opens the dialog
3. Mobile: true fullscreen with slide-up transition (covers entire viewport); Desktop: centered modal
4. Closing strips the `modal` param and stays on the current page
5. No `top: headerHeight` offset — the dialog covers the full viewport including header

### Re-localization flow (`?modal=location&type=relocation`)

- **Trigger**: `LocationButton` (`data-testid="location-chip"`) dispatches locator entry-point action
- **Dialog**: `OccasionFirstDialog` (`data-testid="occasion-first-dialog"`)
- **Content**: OccasionFirstSelection → OccasionFirstDialogContent or DeliveryLocationFlow

## Cart (web)

KFC renders the cart on a dedicated `/cart` **page screen** (`libs/brand-kfc/src/screens/Cart/index.tsx`),
not a query-param dialog. The screen:
- Uses a side-by-side desktop layout (items left `xl={7}`, sticky order summary right `xl={4}`).
- Renders core `InteractiveCart` (from `@byte-storefronts/core-web/cart/components`) for the line-item list,
  coupons, cross-sell, and loyalty; plus `PaymentSummaryButton` + `AvailableCardPaymentMethods`.
- `InteractiveCart` is shared across **three** surfaces — the `/cart` page, the `SideCart`
  (`asCards={false}`), and the generic `CartList` screen — so changes to it affect all three.
  It exposes an optional `renderLineItem` slot for brand-specific line-item UI without forking the component.

## Native cart presentation

On native, KFC's `MenuListStackNavigator` presents the cart as a **fullScreenModal** with `slide_from_bottom` animation instead of a regular stack push. This gives the cart a modal feel (slides up, swipe down to dismiss) while reusing the same `CartList` screen component.

## Testing selectors

| Element | Selector |
|---------|----------|
| Location chip button | `[data-testid="location-chip"]` |
| Occasion dialog wrapper | `[data-testid="occasion-first-dialog"]` |
| Cart page | `[data-testid="cart-page"]` |

## Common pitfalls

- The attribute is `data-testid`, not `data-id`
- Location: don't look for a route change to `/location` — KFC uses a query-param-driven dialog.
  Cart, however, **is** a real `/cart` page route (no longer a dialog).
- The location dialog content components are in `libs/brand-kfc/src/location/` (not in `modules/`)
- `DeliveryLocationFlow` is imported from `@byte-storefronts/core-web`, not from brand-kfc
- Cart components (`InteractiveCart`, `PaymentSummaryButton`, etc.) are exported from `@byte-storefronts/core-web/cart`
- `InteractiveCart` is shared by the `/cart` page, the side cart, and the generic `CartList` screen —
  brand-specific line-item UI should use its `renderLineItem` slot rather than editing the shared DSC `BasketItem`
- Native cart uses the same `CartList` screen — only the navigation presentation changes
