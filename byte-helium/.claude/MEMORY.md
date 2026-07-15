# Local Claude Code Memory (Not Committed)

This file is gitignored and stores project-specific learnings for Claude Code.

---

## Product Page Architecture: Legacy vs New System

**Discovered**: 2026-01-28 (in dv-commerce; updated 2026-07-15 for byte-helium)

### Key Finding

The source (synced from upstream dv-commerce) contains **two completely different product page systems** with separate price calculation logic. Both byte-helium brands (**KFC and Taco Bell**) use the **new** system. The legacy system was built for Pizza Hut in upstream dv-commerce — it is unused in byte-helium but the code is still present in the synced source.

### Legacy Product Page (unused in byte-helium; Pizza Hut in upstream dv-commerce)

- **Location**: `byte-storefronts/core-web/src/menu/components/LegacyProductPage/`
- **Type system**: Uses `PricedModifier` type
- **Price calculation**: `byte-storefronts/core/src/menu/utils/modifiers/pricing.ts`
- **Total price function**: `getTotalModifiersPrice()` (line 200)
- **Individual pricing**: `assignPricesToModifiers()`, `assignRangePricesToModifiers()`

### New Product Page (used by KFC and Taco Bell)

- **Location**: `byte-storefronts/shared-web/src/components/ProductPage/`
- **Type system**: Uses `NormalisedSelectedModifier` type
- **Price calculation**: `byte-storefronts/core/src/product/utils/configurationBuilders.ts`
- **Total price function**: `calculateTotalPrice()` (line 468)
- **Hook**: `useProductSelectedConfiguration` in `byte-storefronts/core/src/product/hooks/`

### Brand-Specific Customizers

- **KFC**: `byte-storefronts/brand-kfc/src/services/customisers/BrandProductCustomiser.ts`
- **Taco Bell**: `byte-storefronts/brand-tb/src/services/customisers/BrandProductCustomiser.ts`

### Debugging Tip

When debugging price issues for either brand, set breakpoints in `byte-storefronts/core/src/product/utils/configurationBuilders.ts` (both brands use the new system). The legacy path in `byte-storefronts/core/src/menu/utils/modifiers/pricing.ts` only matters if the change must stay compatible with upstream dv-commerce.

### Related Components

| Feature | Legacy (unused here) | New (KFC & TB) |
|---------|----------------------|----------------|
| Modifier selection | `ProductModifiers.tsx` | `ProductConfiguration.tsx` |
| Add Extra UI | `Toppings.tsx`, `MultiChoiceSlot.tsx` | `ModifierAddExtra.tsx` |
| Summary display | `SelectedSummary.tsx` | `SelectedConfiguration.tsx` |
