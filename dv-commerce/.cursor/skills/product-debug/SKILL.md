---
name: product-debug
description: Debug product customization, modifier state, and cart edit hydration issues in dv-commerce. Use when users report modifier mismatches between cart and Product Page, bundle sub-product hydration issues, zero-weight modifier behavior, isDefault flag confusion, or added/removed summary inconsistencies.
---

# Product Debug — dv-commerce

Use this skill for product-level debugging in dv-commerce — single products, bundle sub-products, and the full modifier lifecycle from cart payload through UI display.

## Invoke This Skill When

- User says "edit from cart shows wrong modifiers"
- A removed default modifier appears selected on Product Page
- "Added" and "Removed" summary sections are incorrect
- Zero-weight payload (`weight.value = 0`) is involved
- Behavior differs between cart item display and Product Page display
- Bundle sub-product customisation is not hydrating correctly from cart
- `isDefault` flag appears wrong on a selected modifier
- Single-select vs multi-select slot behavior is unexpected
- Option/variant switching causes modifier state to reset incorrectly

## Domain Model: Modifiers, Weights, and isDefault

### Key definitions

| Concept | Meaning |
|---------|---------|
| **Default modifier** | A modifier pre-selected at its default weight in the product's recipe (variant `defaultModifiers`) |
| **Zero-weight modifier** (`WEIGHT_LEVEL.NONE = 0`) | An explicit removal signal. Tells the backend the user removed a default modifier. **Never part of the default recipe.** |
| **`isDefault` flag** | Means "this modifier is currently at its default weight" — NOT "this modifier belongs to the default recipe". A modifier can belong to the default recipe but have `isDefault: false` if its weight differs from the default. |
| **Extra weight** | A modifier at weight > `WEIGHT_LEVEL.REGULAR`. If default, it appears in the "extras" summary. |

### isDefault determination rules (in `getNormalisedProductModifiers.ts`)

During cart hydration, `isDefault` is resolved by comparing BOTH `modifierCode` AND `modifierWeightCode` against the variant's default modifiers:
- **Same modifier code + same weight code** → `isDefault: true`
- **Same modifier code + different weight code** (extra or zero) → `isDefault: false`
- **Different modifier code** → `isDefault: false`

This is intentional. Do NOT simplify to modifier-code-only matching.

### Where isDefault is consumed

| Consumer | What it checks | Why |
|----------|---------------|-----|
| `buildMultiSelectSlot` (~line 236) | `current?.isDefault` | Only default modifiers get zero-weight entries on removal. Non-defaults are simply dropped. |
| `isExtraModifier` | `!isDefault \|\| (isDefault && hasExtraWeight)` | Filters "added" summary. Zero-weight is never an extra. |
| `isDefaultModifier` | `modifier.isDefault ?? false` | Filters "removed" summary — only defaults that were removed. |
| `formatModifierName` | `isDefault` + weight | Controls `(x2)` label — only non-default extras get quantity display. |
| `formatRemovedSlotNames` | `WEIGHT_LEVEL.NONE` check | Independent of `isDefault` — checks weight directly. |

### Zero-weight end-to-end flow

```
User removes default "Cheddar" from product
  → buildMultiSelectSlot: current?.isDefault is true → creates zero-weight entry
  → { weight: NONE, weightCode: 'cheddar_none', isDefault: true (spread from current) }
  → mapSelectedSlotsToModifiers forwards to cart save (selected: 0)
  → Backend interprets zero-weight as "modifier explicitly removed"

User re-edits from cart:
  → getNormalisedProductModifiers hydrates with isDefault: false
    (because 'cheddar_none' ≠ default 'cheddar_regular')
  → Checkbox is unchecked (weight = 0)
  → Appears in "removed" summary (formatRemovedSlotNames checks WEIGHT_LEVEL.NONE)
  → If user adds it back → weight becomes REGULAR → isDefault: true again
  → If user then removes again → buildMultiSelectSlot sees isDefault: true → creates zero-weight ✓
```

### itemUnavailable on cart-hydrated modifiers

`itemUnavailable: false` is **intentionally hardcoded** for cart-hydrated modifiers. We need to display unavailable items during cart editing so the user can see what they previously selected, not silently hide them.

## Core Files

### Single product flow
- `libs/core/src/product/hooks/useNormalisedProduct.ts` — entry hook, accepts `lineItemId` or direct `cartSelectedSlots` overrides
- `libs/core/src/product/utils/getNormalisedProductModifiers.ts` — normalises variant data + cart state into `selectedConfiguration`
- `libs/core/src/product/utils/configurationBuilders.ts` — builds/updates slots on user interaction, summary formatting
- `libs/core/src/menu/utils/modifiers/modifierState.ts` — derives checkbox/UI state from selected configuration
- `libs/core/src/cart/mappers/mapCart.ts` — maps GraphQL cart response to Redux state

### Bundle sub-product flow (additional files)
- `libs/core/src/bundle/hooks/useBundleCustomiseProduct.ts` — orchestrates bundle product customisation, forwards `lineItemId`
- `libs/core/src/bundle/hooks/useBundleProductConfiguration.ts` — resolves matching `configuredChoice` from parent bundle cart line item
- `libs/core/src/menu/utils/compoundChoiceCode.ts` — rewrites choice codes for repeated choices (`selectedQuantity > 1`)
- `libs/core/src/bundle/utils/mapLegacyData.ts` — `mapSelectedSlotsToModifiers` converts normalised slots to cart save format

### UI layer
- `libs/web-shared/src/components/ProductPage/MultiSelectCheckboxList.tsx`
- Summary display reads from `configurationBuilders.ts` formatters

## Canonical Data Flows

### Single product cart edit
```
CartGraphQLPayload → mapCart.ts → CartStateLineItem
  → selectCartLineItemById(lineItemId)
  → useNormalisedProduct (flattens lineItem.selectedModifiers via flattenSelectedSlots)
  → getNormalisedProductModifiers (groups by slotCode, resolves weights)
  → selectedConfiguration → product reducer
  → modifierState.ts → checkbox UI
  → configurationBuilders.ts → summary UI
```

### Bundle sub-product cart edit
```
BundleConfigurator passes bundleLineItemId (from normalisedParams.lineItemId)
  → useBundleCustomiseProduct forwards as lineItemId
  → useBundleProductConfiguration:
    - selectCartLineItemById(bundleLineItemId) → parent bundle line item
    - Finds matching configuredChoice by compound choiceCode + productCode
    - Extracts cartSelectedSlots + cartVariantCode from configuredProduct
  → useNormalisedProduct (cartSelectedSlots override takes precedence over lineItem)
  → getNormalisedProductModifiers (same logic as single product from here)
  → selectedConfiguration → product reducer → UI
```

## Debug Workflow

1. **Reproduce deterministically**
   - Add product (or bundle), modify one default modifier, add to cart.
   - Edit same line item from cart.
   - Capture expected vs actual for: checkbox state, added summary, removed summary.

2. **Confirm data contract from cart payload**
   - Inspect selected modifiers in cart response:
     - `modifierCode`, `weight.modifierWeightCode`, `weight.value`, `weight.price.amount`
   - For bundles: also inspect `configuredChoices[i].configuredProduct.selectedModifiers`
   - Do not assume weight code alone is reliable for zero-weight handling.

3. **Trace hydration path**
   - Single product: `lineItemId` → `selectCartLineItemById` → `flattenSelectedSlots` → `getNormalisedProductModifiers`
   - Bundle: `bundleLineItemId` → `selectCartLineItemById` → `applyCompoundChoiceCodes` → match by `choiceCode + productCode` → extract `cartSelectedSlots` → `getNormalisedProductModifiers`

4. **Validate invariants**
   - Removed default modifier:
     - `selectedModifierWeight` resolves to `0`
     - `isDefault` is `false` (weight code differs from default)
     - Checkbox is unchecked
     - Appears in removed summary, not added summary
   - Default modifier at regular weight:
     - `isDefault` is `true`
     - Checkbox is checked
     - Does NOT appear in added or removed summary
   - Default modifier at extra weight:
     - `isDefault` is `false` (weight code differs)
     - Not treated as removed
     - Appears in added/extra summary
   - Non-default modifier added by user:
     - `isDefault` is `false`
     - Appears in added summary
     - On removal: simply dropped (no zero-weight entry)

5. **Patch minimally**
   - Change only the smallest logic boundary that violates invariants.
   - Preserve behavior for regular and extra-weight modifiers.

6. **Add regression tests** — cover all matrix cases below.

## Regression Matrix (Mandatory)

Test file: `libs/core/src/product/utils/__tests__/getNormalisedProductModifiers.spec.ts`

Required scenarios:
1. Default kept at base weight → `isDefault: true`
2. Default removed via zero-weight → `isDefault: false`, `selectedModifierWeight: 0`
3. Default increased to extra weight → `isDefault: false`, appears as extra
4. Non-default modifier added → `isDefault: false`
5. Cart payload has `weight.value = 0` but weight code is missing/unmatched in variant weights
6. Bundle sub-product hydration with mixed zero-weight + extra modifiers
7. Multiple modifiers in same slot (grouped correctly)

Also cover in: `libs/core/src/product/utils/__tests__/configurationBuilders.spec.ts`
- `buildMultiSelectSlot`: default removal creates zero-weight, non-default removal drops modifier
- `formatSelectedSlotNames`: zero-weight excluded from extras, extra-weight included
- `formatRemovedSlotNames`: zero-weight defaults appear as removed

## Fast Checks For Root Cause

- **Checkbox wrong** → inspect `modifierState.ts` quantity logic; confirm hydrated `selectedModifierWeight`
- **Summary wrong** → inspect `isDefault` + weight in `getNormalisedProductModifiers.ts`; inspect filtering in `configurationBuilders.ts`
- **Cart and Product Page disagree** → compare cart payload with normalised selected configuration
- **Bundle not hydrating** → check `useBundleProductConfiguration.ts` matching logic; verify compound choice codes align
- **isDefault unexpectedly true/false** → check weight code comparison in `getNormalisedProductModifiers.ts` (must match BOTH code AND weight)

## Anti-Patterns To Avoid

- Simplifying `isDefault` to modifier-code-only matching (loses weight semantics)
- Treating `modifierWeightCode` as authoritative when `weight.value` is `0`
- Fixing only summary logic while checkbox logic still derives from wrong weight
- Broad refactors before proving which layer is wrong
- Shipping without regression coverage for removed default + extra default paths
- Assuming zero-weight modifiers belong to the default recipe (they never do — confirmed with Menu team)
