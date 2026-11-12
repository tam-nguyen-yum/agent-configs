# Review standards (byte-helium)

Load this after the MR is resolved. Skip a section that the diff does not touch.

On conflict with the **`react-web`** / **`react-native`** skills, those win for platform conventions. This file wins for placement (brand vs core) and leftover wiring.

**dv-commerce is retired.** Do not flag dv-sync or "dv-owned code": `byte-storefronts/*/src/**` is helium-owned. Leftover sync tooling or dv mentions in docs are cleanup debt, not a review blocker.

## Design — works, but bigger or more repeated than it needs to be

Run this pass first. It needs the ticket (SKILL.md, step 1).

**Smallest fix.** Write one line: the smallest change that would fix the ticket. Compare the diff with it.

- The diff does more than the ticket asks (extra refactor, cases nobody reported, a compatibility alias or shim) and the description does not say why → `[SUGGESTION]`. Name the hunks that could go, or be their own MR.
- A simpler shape fixes the same ticket → `[SUGGESTION]`. Show it in a few lines of code, and say what it gives up, if anything. Only suggest it after reading the callers and checking it still handles the cases the MR's specs cover.
- `[CRITICAL]` only when the extra part changes behaviour for another brand or screen.

**Already exists.** For each new exported function, hook, component, saga, selector or helper in the diff, search before grading. Search by name and by a word for what it does:

```bash
grep -rlE "<name>|<what it does>" byte-storefronts/*/src tools apps --include='*.ts' --include='*.tsx' | grep -v '\.spec\.'
```

Also check platform built-ins, the package's own dependencies and the `catalog:` in `pnpm-workspace.yaml`.

- An existing unit already does it, in the same package, in core or in the other brand → name the original by path and say which knob it is missing. Severity and the "not a copy" cases (web/native twins, module overrides, injected slices, brand re-exports) follow `.cursor/BUGBOT.md`.
- New code that re-derives near-verbatim what an existing builder/mapper/util already computes → ask for one shared helper, with only the case-specific fields left at the call sites. Otherwise the next spec change must land twice and the copies drift.
- The finding is for a repeated unit (function, component, saga, fragment). A few similar lines at two call sites are not a finding, and do not ask for a new abstraction to remove them.

**Over-built.** For each new abstraction, count its callers and put the number in the finding:

```bash
grep -rn "<NewName>" byte-storefronts/*/src apps tools | grep -v '\.spec\.'
```

- A new wrapper, factory, registry, context, generic helper or config layer with one caller → ask to inline it until a second caller exists.
- A new option, parameter, prop or flag that no caller in the diff passes; a new allowlist or registry that is empty.
- A new package, slice, service or module where an existing one could hold the code.
- More than one new concept in one MR → list them and ask which ones the ticket needs.

## Architecture — works, but in the wrong place

- **Dependency direction**: every package is classified (tier + platform) in `eslint-local-rules/rules/dependency-direction/registry.js`, and the `dependency-direction` lint rule enforces it. No `dsc-native`/`core-native` imports in web code or `dsc-web`/`core-web` in native — even transitively through a helper — and `brand-kfc` / `brand-tb` never import each other. A new package missing from the registry fails lint; check its classification is right, not just present.
- **Editing core**: `byte-storefronts/core*` ships to every brand. For each changed export or field, find who else reads it before grading:

  ```bash
  grep -rn "<fieldOrExport>" byte-storefronts/core-web/src byte-storefronts/core-native/src byte-storefronts/brand-tb/src byte-storefronts/brand-kfc/src
  ```

  - Another brand's behaviour changes and the description doesn't say why core must hold it → `[CRITICAL]`; name the brand file it belongs in and the other brand's screens that change.
  - A fix every brand needs, or a new extension point, explained in the description → accept; check the other brands keep their current behaviour.
  - Additive (optional field, new export) with no reader outside the MR's brand → at most `[NITPICK]` asking the description to say so.

- **Brand/market logic in core**: anything KFC- or TB-specific inside `byte-storefronts/core*` belongs in `brand-kfc`/`brand-tb` or the app.
- **Brand extensions (slices, events, sagas)**: core's Redux surface (`AnyEvent`, root reducer) is closed — brands add at runtime via `store.slice.inject()` / `store.eventListener.inject()` (wrapped in `injectBrandListeners`), never override core slices or events (`docs/brand-extensions.md`). Brand events must use a namespace prefix (`<domain>/...`), type saga effects with `createTypedListenerEffects<BrandEvent>()`, and read injected state through `createInjectedSliceSelector`. Brands re-export core's structural `StoreDispatchHook` / `StoreSelectorHook` — never depend on `react-redux` directly (causes TS2742 in declarations).
- **Module system**: props type in `@byte-storefronts/types` first; overrides live in the brand package with a key matching the core module export name; consumers resolve via `getModule()`, never import the module set directly; modules don't touch the Redux store directly.
- **Logic altitude**: side effects and reusable business logic in sagas, not hooks/components. No tracking calls in React components/hooks (`no-tracking-in-react`) — route through sagas/services.
- **Dependencies & install-time patches**: versions come from the `catalog:` in `pnpm-workspace.yaml` — flag hard-coded versions in package manifests. Any install-time string patch (`patches/`, Podfile/Gradle hooks editing a pod or library file) must pin that dependency to the exact verified version, never a floating range.
- **Package manifests (`sideEffects`)**: every `byte-storefronts/*` package must declare `sideEffects` (`false`, or the explicit CSS/polyfill paths that run on import) so Rollup drops unused barrel members.

## Conventions — works, but not how this repo does it

- **Comments & JSDoc**: rare and short — 1–2 lines explaining the non-obvious _why_ (including JSDoc on declarations). Flag comments that restate the code, change history, ticket narrative, or multi-paragraph rationale (belongs in the MR description).
- **`.cjs` imports in specs**: specs importing a `.cjs` module need a sibling `.d.cts` declaration; never add TS7016 to a typecheck lane, and never silence lint with `require()` + `eslint-disable`.
- Scopes: `@byte-storefronts/*` = workspace packages, `@byte-helium/*` = apps. Any `@phdv/*` import is an invalid scope that won't resolve — flag it. Workspace packages (and subpath exports) over `../../../` paths.
- DSC components (`@byte-storefronts/dsc-web` / `dsc-native`) over raw MUI/RN primitives (`button-import` rule).
- `themeTokens.*` for spacing/colors/typography — no hardcoded values.
- One dispatch with a consolidated payload, not consecutive `dispatch`/`put` calls (`no-consecutive-dispatch`).
- `type` over `interface`; no `any` (use `unknown` + guards); `data-testid` on interactive elements; user-facing strings through i18n (`useTranslation`).
- Native: `expo-image` not RN `Image`; `useAppNavigation()` not raw `useNavigation()`.

## Performance — works, but slow

- **Selectors**: select specific fields, never whole slices — a whole-slice selector re-renders on every slice write.
- **Render allocation**: inline objects/functions/`sx` passed to memoized children defeat the memo; hoist static ones, `useCallback`/`useMemo` the rest.
- **Loops**: stable unique `key`s (not array index when items reorder); no sorting/filtering/object-building inside JSX over large arrays — hoist to `useMemo`; no `.find()`/`.includes()` inside `.map()` over the same array (build a `Map`/`Set` once); no per-item async kicked off in a render loop.
- **Native lists**: `FlashList` — not `FlatList`, not `.map()` in a `ScrollView`. Do not require `estimatedItemSize` (FlashList v2; see `core-native-modules/src/modules/MenuList/index.tsx`).
- **Sagas & lazy loading**: `takeLeading` vs `takeLatest` chosen deliberately; no redundant work per action. Heavy components lazy-loaded with `Suspense` + skeleton via `importWithRetries` (`wrap-dynamic-import`).
- **Web bundle budgets & boot shell**:
  - KFC boot-shell entries (`apps/kfc-*-web-app/src/main.tsx`) must only paint the route skeleton and `import()` `bootstrap.tsx` — import skeleton primitives from subpaths (`dsc-web/Box`, `dsc-web/Skeleton`), never package roots/barrels.
  - `VENDOR_CHUNKS` (`tools/app-config/src/vite.js`) must not add manual chunks for vendors the shell only partly needs (MUI) or loads after boot (Datadog).
  - Raising a ratchet in `WEB_BUNDLE_BUDGETS` (`tools/ci/lib/bundle-budget.ts`) without moving new code off the initial graph and explaining why in the MR description is `[CRITICAL]`.

## Complete wiring — works on the demo path, broken elsewhere

When the MR **supersedes** an existing component/screen/hook/module, the diff hunk misses leftover registration. Sweep:

```bash
grep -rn "<OldName>\|<old-import-path>" byte-storefronts/<affected-package>/src apps/
```

- A stale registration for the same key elsewhere renders the old UI on that path — `[CRITICAL]`.
- Same key registered in multiple places must point to the same component unless divergence is clearly intentional (confirm who still imports the old one).
- Same sweep for renamed translation keys, test IDs, and feature flags.

## Recent history — works, but undoes an earlier fix

When a hunk sits under a JSDoc/invariant comment, or touches code changed in the last ~30 days, check what the last change was for:

```bash
git log -L<start>,<end>:<path> origin/main --format='%h %ad %s' --date=short -s
```

- Read that commit's specs. A new spec that gives a different answer than an old one for the same input shape, or new code that contradicts the comment above it, is `[CRITICAL]` unless the description says the earlier rule is being reversed and why.
- Name the earlier ticket and author in the finding so the MR author knows who to check with.

## Tests & MR hygiene

- Unit tests for new/changed logic; tests describe behavior, not implementation; edge cases exercised (judge from the diff — don't run coverage). E2E can be left to CI.
- **No changeset required**: the changesets flow is superseded (see `docs/releases.md`), so never flag a missing or deleted `.changeset/*.md`.
- MR title in conventional-commit format; a `breaking:` MR includes a migration guide in its description.
- Title ticket, branch ticket and `Closes` line agree, or the description says how the tickets relate (`docs/making-a-change.md`).
- The description names every behaviour change QA must retest: dependency upgrades/downgrades, removed native modules, and anything that alters the native fingerprint (forcing a new store binary instead of an OTA — see `docs/releases.md`). A bare `Closes ATLAS-123` on an MR that changes user-facing or release behaviour is a `[SUGGESTION]`; list the screens/brands/release impact it should name.
- Native `X.Y.0` version line in `apps/<app>/package.json`: bump only when the change needs a new store-visible line (`docs/releases.md`). Changing shared native app config (`tools/app-config/src/native-app-config.ts`) for one brand's need requires the MR description to say why.
- Adding a CI job, package, service or abstraction: the description must state what it replaces/retires, or that it replaces nothing (`docs/making-a-change.md`). A new package or root entry must be placed in `.paths-*` in `.gitlab-ci/rules.yml` or `IGNORED_TOP_LEVEL` in `tools/ci/release/mr-scope-paths.ts`.
- CI YAML (`.gitlab-ci/`): jobs must pick an `extends` preset in `.gitlab-ci/rules.yml` (never write inline `rules:`), must not use recursive wildcards (`**`) in `artifacts:paths`, and any job adding `allow_failure` or a non-blocking manual button must name the person/channel who checks it and how often (`docs/cicd.md`).
- The `mr-size-report` bot flags MRs over its limits; over-limit with no reason in the description → `[SUGGESTION]` to split (name the seam, e.g. core change vs brand UI).
- Native code touched (`apps/*-native-app*`, `*-native`, `brand-*/src/native`, `blueprint/native`): say in the summary whether `native-e2e-<brand>` ran for every brand reached. A green MR with skipped Native is not proof Native passed — summary bullet, not a finding.

## Security & accessibility (quick pass)

- No secrets/keys in the diff. Web: `tools/app-config/src/vite.js` loads every env var unprefixed and defines it as `process.env.<KEY>`, so any `process.env.X` referenced from web code ships in the bundle — no prefix protects it; flag a secret read that way as `[CRITICAL]`. Native: only `EXPO_PUBLIC_*` reaches the JS bundle. `NX_PUBLIC_ENV` / `NX_PUBLIC_MARKET` remain as leftover config keys — do not introduce new `NX_PUBLIC_*` vars. Inputs validated; auth checks where required.
- `aria-label` on icon-only buttons; form fields with `id` + label; native interactive elements have `accessibilityRole`/`accessibilityLabel`; `onClick` on non-buttons is keyboard-accessible.
