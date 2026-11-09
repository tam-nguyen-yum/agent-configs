# Example findings

## Good finding — leftover / incomplete wiring

The MR renamed a brand module but left the old key registered. CI is green; the old UI still renders on one path.

````markdown
**[CRITICAL] OccasionFirstDialog still registered under the old module key**

KFC AU `/menu` after the module rename.

| | Before | After this MR |
| --- | --- | --- |
| Dialog on `/menu` | new OccasionFirstDialog | old dialog still renders |

- **Where:**

```12:16:byte-storefronts/brand-kfc/src/modules/index.ts
export const webModules = {
  OccasionFirstDialog: OldOccasionFirstDialog,
  LocationButton,
}
```

- **Fix:** point the same key at the new component (or delete the old export if the new one is registered under a different name that `getModule()` actually reads).
````

## Good finding — user-visible behaviour

A Product CMS entry exists (title + image) but there is no per-variant CMS. The popup always overwrites name and image from the variant.

````markdown
**[CRITICAL] Addon popup loses the product image and name when the product has a Product entry**

Addon popup, product like "Chips" with a Product entry (title + image) but no per-variant CMS.

| | Before | After this MR |
| --- | --- | --- |
| Name | Chips Large | just "Large" (or raw Byte Portal name in prod) |
| Image | product image | empty |
| Analytics | "Chips Large" | same broken name |

Hits KFC and TB, web and native. The new spec asserts this broken result.

- **Where:**

```76:86:byte-storefronts/core/src/menu/hooks/useAddonsPopup.ts
          name:
            getVariantDisplayName(item.variant) ??
            formatMultiOptionLabel(/* … */),
          viewItemImage: firstImageWithUrl(images),
```
````

Required pieces: severity, scenario, comparison table, path, snippet from **this** MR's diff. Fix is optional and only when it is one obvious line. Do not put the table's content back into a paragraph after the title.

## False positive — justified core edit

Do **not** flag a core change as `[CRITICAL]` brand-vs-core when the MR description already says why the brand package cannot hold it, and the change is additive.

Example: MR description — "All brands hit a zero-weight cart-hydration bug in `getNormalisedProductModifiers`; fix lives in core because brand customisers all call this." Diff adds a regression spec and does not change TB-only UI.

- Wrong: `[CRITICAL] core edit belongs in brand-kfc`.
- Right: drop it, or at most `[NITPICK]` if the description is thin but the spec + additive shape are clearly cross-brand.

Before calling something a bug, check the MR's own tests/description for intent — if a test expects the behaviour, downgrade to `[SUGGESTION]` or drop it.

## Re-review

The author pushed fixes after the first review. Lead with what changed, close out earlier findings, then list only what is still open.

```markdown
## MR Review: fix(kfc): ATLAS-1631 receipt customisations (!1310) — re-review

**No merge blockers.** `066ed4f05` drops the emptied-slot rule, so the core change is now an additive `quantity` field that only KFC reads.

**Changed since last review:** emptied-slot block and its spec removed; `main` merged in; UI files unchanged.

**[SUGGESTION] `getModifierLines` still re-derives the cart's formatting** — (Where as before, fresh lines)
```

Do not repeat resolved findings beyond one line, and re-verify every **Where** against the new head — line numbers move after a `main` merge.
