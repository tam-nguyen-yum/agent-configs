---
name: blueprint
description: Schema-driven screen composition in byte-helium — areas/structures/blocks, native floatingBlocks, the block registry, and CMS vs local fallback. Use when adding, moving, or hiding UI on a screen that renders <Blueprint>, when a block doesn't show up, when registering a new block type, or when the user mentions blueprint, floating block, block registry, or a *-page.ts schema.
---

# Blueprint (byte-helium)

There is no in-repo `tools/skills/blueprint/SKILL.md` — this file is the source
of truth. Edit the schema, not the screen.

## When to reach for it

Any time you are about to add JSX to a screen under `byte-storefronts/brand-*/src/**/screens/` or
`core-{web,native}`, first check whether that screen calls `useWebBlueprint` / `useNativeBlueprint`. If it
does, the change most likely belongs in a `*-page.ts` blueprint, not in the screen.

Strong signals:

- pinned / floating / sticky UI on native → `floatingBlocks`, not a screen-level import
- "show X only when logged in / on delivery / after a date" → `visibilityRules` on the block
- "this block doesn't render" → unregistered `type` silently renders `<Unknown>`; check the registry
- "make it configurable per market" → check whether a blueprint entry already covers it before adding a
  `FeatureConfig` flag

## Schema anatomy

Types live in `byte-storefronts/types/src/blueprint/index.ts`.

- **Page** → **areas** (`content`, optional `header` / `footer` / sidebars) → **structures** → **blocks**
- Each block has `type`, optional `attributes`, `styles`, and `visibilityRules`
- Native schemas also have `floatingBlocks?: BlockSchema[]` for pinned/sticky UI
- `visibilityRules` can gate on dates, breakpoints, login, occasion, platform, weekdays

## Render pipeline

- Hooks: `byte-storefronts/core/src/blueprint/hooks/useNativeBlueprint.ts`, `useWebBlueprint.ts`
- Native renderer: `byte-storefronts/core-native/src/blueprint/index.tsx` (`<Blueprint>`)
- Framework defaults: `core-native/src/blueprint/Block/getPageTypeBlock.ts`, `core-web/.../getPageTypeBlock.ts`
- An unknown `type` renders `<Unknown>` with no throw — "block missing" is almost always an unregistered type

## Brand layout (do not assume KFC paths for TB)

**KFC** — page schemas at `brand-kfc/src/blueprint/<page>-page.ts`, wired in `brand-kfc/src/blueprint/index.ts` as `webAppBlueprintDependency` / `nativeAppBlueprintDependency`. Brand blocks: `brand-kfc/src/blueprint/{native,web}/register*Blocks.ts`.

**TB** — schemas are split:

- native: `brand-tb/src/native/blueprint/definitions/*`
- web: `brand-tb/src/web/blueprint/definitions/*`
- shared: `brand-tb/src/shared/blueprint/`
- web register: `brand-tb/src/web/blueprint/registerWebBlocks.ts`
- There is **no** `registerNativeBlocks.ts`. Native apps call `registerBlocks` from the app (`apps/tb-*-native-app/src/App.tsx` or create-home helpers).

## CMS vs local fallback

`forceLocalBlueprints` / `forceFloatingBlockLocal` live on the types and on app/brand config (e.g. `apps/kfc-au-web-app/src/config.ts`). When set, the local `*-page.ts` schema wins over CMS. Use that when a block must ship with the app regardless of Contentful.

Apps load the brand map at startup (`loadBlueprint(nativeAppBlueprintDependency)` in native `loadDependencies.ts`; web via `initApp({ blueprintMap })`).

## Workflow

1. Confirm the screen uses `useWebBlueprint` / `useNativeBlueprint`.
2. Locate the page schema (KFC: `brand-kfc/src/blueprint/<page>-page.ts`; TB: `brand-tb/{native,web,shared}/blueprint/**`).
3. Find whether the block already exists — framework defaults in `getPageTypeBlock.ts`, brand blocks in the register files above.
4. Prefer a schema edit. Write a new component only if no registered block fits, then register its `type`.
5. Test through the schema (mock the blueprint hook, assert the declared blocks render).

Pair with `react-native` / `react-web` for component, styling, and navigation conventions.
