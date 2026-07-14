# Local Claude Code Memory (Not Committed)

This file is gitignored and stores project-specific learnings for Claude Code.

---

## Product Page Architecture: Legacy vs New System

**Discovered**: 2026-01-28

### Key Finding

Pizza Hut and Taco Bell use **two completely different product page systems** with separate price calculation logic.

### Legacy Product Page (Used by Pizza Hut)

- **Location**: `libs/web-core-framework/src/menu/components/LegacyProductPage/`
- **Type system**: Uses `PricedModifier` type
- **Price calculation**: `libs/core/src/menu/utils/modifiers/pricing.ts`
- **Total price function**: `getTotalModifiersPrice()` (line 170)
- **Individual pricing**: `assignPricesToModifiers()`, `assignRangePricesToModifiers()`

### New Product Page (Used by Taco Bell and KFC)

- **Location**: `libs/web-shared/src/components/ProductPage/`
- **Type system**: Uses `NormalisedSelectedModifier` type
- **Price calculation**: `libs/core/src/product/utils/configurationBuilders.ts`
- **Total price function**: `calculateTotalPrice()` (line 362)
- **Hook**: `useProductSelectedConfiguration` in `libs/core/src/product/hooks/`

### Brand-Specific Customizers

- **Pizza Hut**: `libs/brand-ph/src/services/customisers/BrandProductCustomiser.ts`
  - Has custom `getAdditionalFields()` for swap/free modifier logic
- **Taco Bell**: `libs/brand-tb/src/services/customisers/BrandProductCustomiser.ts`

### Debugging Tip

When debugging price issues:
- **Pizza Hut**: Set breakpoints in `libs/core/src/menu/utils/modifiers/pricing.ts`
- **Taco Bell**: Set breakpoints in `libs/core/src/product/utils/configurationBuilders.ts`

### Related Components

| Feature | Legacy (PH) | New (TB) |
|---------|-------------|----------|
| Modifier selection | `ProductModifiers.tsx` | `ProductConfiguration.tsx` |
| Add Extra UI | `Toppings.tsx`, `MultiChoiceSlot.tsx` | `ModifierAddExtra.tsx` |
| Summary display | `SelectedSummary.tsx` | `SelectedConfiguration.tsx` |
