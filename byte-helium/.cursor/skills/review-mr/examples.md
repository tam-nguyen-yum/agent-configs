# Example findings

## Good finding — leftover / incomplete wiring

The MR renamed a brand module but left the old key registered. CI is green; the old UI still renders on one path.

````markdown
**[CRITICAL] OccasionFirstDialog still registered under the old module key** — KFC AU keeps the previous dialog on `/menu` because `webModules` still exports `OccasionFirstDialog` from the old file.

- **Where:**

```12:16:byte-storefronts/brand-kfc/src/modules/index.ts
export const webModules = {
  OccasionFirstDialog: OldOccasionFirstDialog,
  LocationButton,
}
```

- **Fix:** point the same key at the new component (or delete the old export if the new one is registered under a different name that `getModule()` actually reads).
````

Required pieces: severity, path, why it matters for a user/path, snippet from **this** MR's diff. Fix is optional and only here because it is one obvious line.

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
