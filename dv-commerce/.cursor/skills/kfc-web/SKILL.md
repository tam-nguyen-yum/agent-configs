---
name: kfc-web
description: KFC brand-specific web UI patterns — location flow, OccasionFirstDialog, and re-localization. Use when working in libs/brand-kfc/, apps/web-app-au/, or when the user mentions KFC location, occasion dialog, re-localize, or store selection on web.
---

# KFC Web — Brand-Specific Patterns

> KFC overrides several core web modules with brand-specific implementations in `libs/brand-kfc/`.

## Key paths

| What | Where |
|------|-------|
| KFC brand library | `libs/brand-kfc/src/` |
| OccasionFirstDialog module | `libs/brand-kfc/src/modules/OccasionFirstDialog/index.tsx` |
| Dialog content (order details) | `libs/brand-kfc/src/location/OccasionFirstDialog/` |
| Location chip (header button) | `libs/brand-kfc/src/modules/AppBarLocation/LocationButton.tsx` |
| URL-driven locator modal hooks | `libs/brand-kfc/src/location/hooks/` |
| Core location dialog wiring | `libs/web-core-framework/src/location/components/location-dialog/` |
| Core URL detection logic | `libs/core/src/dom/sagas/detectors/` |

## Re-localization flow (location chip → OccasionFirstDialog)

Clicking the **location chip** in the header opens the re-localize screen. This is how it works:

1. **Trigger** — `LocationButton` (`data-testid="location-chip"`) in the app bar calls `handleChangeLocation`, which dispatches a locator entry-point action.
2. **URL change** — The router updates the URL to `/?modal=location&type=relocation`. The `modal` and `type` query params drive the dialog open/close state.
3. **Dialog** — `OccasionFirstDialog` renders a **MUI Dialog** (`data-testid="occasion-first-dialog"`):
   - **Mobile**: fullscreen (`fullScreen={!mdUp}`) with a slide-up transition
   - **Desktop**: centered modal with `minWidth: 'sm'`, positioned below the header
4. **Content** resolves based on state:
   - No occasion selected → `OccasionFirstSelection` (pick Delivery/Collection)
   - Occasion is ORDER → `OccasionFirstDialogContent` (shows order type, location, time with Change buttons + Confirm CTA)
   - Occasion is DELIVERY → `DeliveryLocationFlow` (address search)
5. **Close** — Closing the dialog dispatches `LOCATOR_DIALOG_ABANDONED` if no location was confirmed, and strips the `modal` query param from the URL.

### Important details

- The dialog sits **below the header** (`top: headerHeight`), not a true full-viewport takeover.
- The backdrop also offsets by `headerHeight` so the header remains visible and interactive.
- On desktop, the dialog is a centered modal (not fullscreen).
- The `disableScrollLock` prop means the page behind is still scrollable.
- URL is the source of truth — deep-linking to `/?modal=location&type=relocation` opens the dialog directly.

## Location chip anatomy

`LocationButton` renders differently by breakpoint:

- **Mobile**: Shows only the occasion label (e.g. "Delivery")
- **Desktop**: Shows `"Delivery · Frenchs Forest, Northern Beaches Council, 2086"` via i18n key `header.locationChip.label`

## Testing selectors

| Element | Selector |
|---------|----------|
| Location chip button | `[data-testid="location-chip"]` |
| Occasion dialog wrapper | `[data-testid="occasion-first-dialog"]` |

## Common pitfalls

- The attribute is `data-testid`, not `data-id` — use `data-testid="location-chip"` in selectors
- Don't look for a route change to a `/location` page — it's a query-param-driven dialog, not a separate page
- The dialog content is in `libs/brand-kfc/src/location/` (not in the `modules/` folder where the dialog shell lives)
- `DeliveryLocationFlow` is imported from `@byte-storefronts/core-web`, not from brand-kfc
