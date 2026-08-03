---
name: blueprint
description: Schema-driven screen composition in byte-helium — areas/structures/blocks, native floatingBlocks, the block registry, and CMS vs local fallback. Use when adding, moving, or hiding UI on a screen that renders <Blueprint>, when a block doesn't show up, when registering a new block type, or when the user mentions blueprint, floating block, block registry, or a *-page.ts schema.
---

# Blueprint (byte-helium)

The canonical skill lives **in the repo**: read `tools/skills/blueprint/SKILL.md` first — it owns the rules
(schema anatomy, the render pipeline, `floatingBlocks`, `forceLocalBlueprints` /
`forceFloatingBlockLocal`, the recipes, and the anti-patterns). Do not duplicate its content here; if it
conflicts with this file, it wins.

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

## Workflow

1. Read `tools/skills/blueprint/SKILL.md`.
2. Locate the page blueprint: `byte-storefronts/brand-*/src/blueprint/<page>-page.ts`, wired in
   `blueprint/index.ts`.
3. Find whether the block already exists — framework defaults in
   `core-native/src/blueprint/Block/getPageTypeBlock.ts`, brand blocks in
   `brand-*/src/blueprint/{native,web}/register*Blocks.ts`.
4. Prefer a schema edit. Write a new component only if no registered block fits.
5. Test through the schema (mock `useNativeBlueprint`, assert the declared blocks render) — see the canonical
   skill's testing section.

Pair with `react-native` / `react-web` for component, styling, and navigation conventions.
