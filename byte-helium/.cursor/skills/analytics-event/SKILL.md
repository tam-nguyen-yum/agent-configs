---
name: analytics-event
description: Implement a brand analytics/tracking event (GTM, mParticle, Firebase) in byte-helium. Use for ATLAS tracking tickets or any request like "add analytic event", "track X event", "implement tracking for Y". Encodes the review feedback from past event MRs so new events don't repeat the same mistakes.
---

# Analytics event implementation (byte-helium)

Distilled from reviewer feedback on past event MRs (!654 and siblings). Every rule
here exists because a human reviewer flagged its violation. Follow it file-by-file;
finish with the pre-push gate at the bottom.

## Reference implementation

**!651 (change-store, branch `ATLAS-286-Analytic-Event-Change-Store`) was approved
with zero review comments** — mirror its file shape before inventing anything:
listener/saga in core, payload builder, brand sinks (GTM web + mParticle native),
types in `@byte-storefronts/types`, tests per file.

## Triggers — where the event fires from

- **Never** track from React. No tracker calls (lint-banned) *and* no new
  `useEffect`-dispatches-event patterns in components. The trigger is a saga.
- Web: listen to an existing signal in a saga — `APP_URL_CHANGE`
  (`'@@router/LOCATION_CHANGE'`) for screen-entry events, or an existing domain
  event. Native: extend `trackScreenChangeHandler` or the relevant listener.
- **Brand-override sweep (caused a silent no-op bug in !654):** before wiring a
  trigger into a `core-web`/`core` screen or module, check whether the brand
  overrides it: `grep -rn "<ScreenName>" byte-storefronts/brand-kfc/src/routes/ byte-storefronts/brand-kfc/src/screens/`.
  KFC AU overrides Checkout, and others — a trigger in the core screen never fires there.
- "Once per X" state: derive from one key (e.g. `trackedCartId`), never a
  separate boolean alongside it. No mutable module-level globals — close over the
  state in a factory (`createXxxHandler()`) so tests get fresh state.

## Input types (`byte-storefronts/types/src/trackingClient.ts`)

- **No field that is derivable from another field already in the input.**
  The cart is the biggest source: `deliveryAddress`, `storeNumber`, occasion,
  totals, items all live on `CartContents` — don't duplicate them as siblings.
- Collapse boolean pairs the consumers reduce anyway (`loggedIn` + `guest` →
  `member`). Prefer one nullable object over flag + name (`store?: { storeNumber,
  name }` instead of `localised` + `storeName`).
- Fields the saga always supplies are **required**, not optional. Optional only
  when genuinely absent in some flows.
- **No PII fields in shared types.** PII extraction happens inside the one
  brand mapper allowed to send it; the shared type stays clean.
- No provider-specific comments (mParticle/GA/Firebase) in generic types.
  JSDoc: one line max, only if the name is ambiguous (e.g. distinguishing
  view-checkout from begin-checkout).

## Naming

- Match the existing sibling pattern before naming anything:
  `cartEventType` uses `CART_VIEW_CART` → a checkout-view event is
  `CART_VIEW_CHECKOUT` / `'cart/view-checkout'`, **not** `CART_CHECKOUT_VIEW`.
- The name must be consistent through the whole chain: event type → tracker
  method → `TrackXxxInput` → handler saga → input builder → tests.

## Sinks & payloads

- **KFC AU sinks: GTM (web) + mParticle (native) only. No Firebase for brand
  events, no loyalty fields** — even when the spec shows Firebase samples or
  loyalty columns. Ignore them.
- KFC AU `userType` token: `deriveUserType` in `brand-kfc/src/utils/tracking.ts`
  — format is `"localised guest"` style (space-separated full words).
- Reuse the shared mappers/builders (`mapLineItemForCheckout`,
  `mapOccasionToDisposition`, `applyCurrencyFactor`, `formatDeliveryAddress`,
  `getLocalIsoDateTimeString`/`getDeviceTimezone`) — never re-derive inline what
  a sibling mapper already computes.
- PII (address, email, phone): mParticle only — it's the CDP that already holds
  identity. GA4/GTM/Firebase-bound payloads must exclude it. The gate lives in
  each client's mapper, documented there.
- Timestamps: two fields, `actualEventLocalTime` (ISO 8601 with offset) and
  `deviceTimezone` (IANA name). Not derivable from each other or a `Date` — keep
  both, formatted once in the input builder.

## Overlap check before adding an event

- List what already fires on the same user action (generic screen_view /
  trackScreenChange, existing click events). If the new event's payload is what
  distinguishes it, say so in the MR description. If it duplicates an existing
  event, raise it against the spec **before** implementing — don't ship
  double/triple tracking silently.

## Pre-push gate (mandatory)

1. Tests for every new file; run the affected package tests.
2. Changeset added (`pnpm changeset`).
3. **Run the `review-mr` skill on the branch's MR (or local diff against `main`)
   and fix everything at CRITICAL/SUGGESTION level.**
4. Only push to origin after the review pass is clean and the user confirms.
