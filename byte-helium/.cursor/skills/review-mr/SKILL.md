---
name: review-mr
description: Review merge requests against byte-helium project standards, architecture rules, and team conventions. Use when the user says "review PR", "review MR", "check this PR", provides an MR URL or number, or asks for a code review of a branch (for example, "review changes from TBI-276 branch" means "review the MR that merges TBI-276 into main").
---

# Review MR (byte-helium)

byte-helium lives on **GitLab** — reviews operate on merge requests via `glab`. When the user says "review changes from \<branch\>", review the open MR from that branch into `main`, not a raw diff. (If given a GitHub URL, use the equivalent `gh` commands.)

## 1. Resolve and fetch the MR

| Input | Resolution |
|-------|------------|
| MR URL | Extract the IID from the URL |
| `!123` / `123` | Use as IID directly |
| Branch name | `glab mr list --source-branch <branch>` |
| Nothing | Current branch (`git branch --show-current`), then resolve as above |

Fetch context in parallel:

```bash
glab mr view <iid> -F json          # title, description, branches, SHA
glab mr diff <iid>                  # changed files
glab api projects/:id/merge_requests/<iid>/notes   # prior feedback — don't duplicate it
```

Then get the real diff and read around it:

```bash
git fetch origin main <source_branch>
git diff origin/main...origin/<source_branch>
```

**Read each changed file in full** — most "works but wrong" findings are only visible in the surrounding code, not the diff hunk. For files >500 lines, Grep to the changed regions and read around them; delegate broad cross-file sweeps to the Explore agent.

**CI**: read `glab ci status` (or the MR view) and report red checks as `[CRITICAL]`. Don't re-run lint/type/test locally — CI already does, and `nx affected` is slow.

## 2. Load project context

- `AGENTS.md` — always. It holds the non-negotiables, architecture guardrails, and release rules.
- Platform conventions are owned by the **`react-web`** / **`react-native`** skills — consult them for whatever platform the diff touches; when this file and those skills disagree, they win.
- Process questions: `docs/making-a-change.md`, `docs/making-a-breaking-change.md`, `docs/testing.md`, `docs/cicd.md`, `docs/releases.md`.
- dv-sync questions: `tools/sync-dv-commerce/SKILL.md`.

## 3. Review — "it works" is not enough

CI proves the code runs. Your job is the findings CI can't make: code that works but violates the architecture, drags performance, or is wired incompletely. Work through each dimension; skip what doesn't apply.

### Architecture — works, but in the wrong place

- **Platform boundaries**: packages are tagged `platform:agnostic|web|native`. No `dsc-native`/`core-native` imports in web code or `dsc-web`/`core-web` in native code — even transitively through a helper.
- **Brand/market logic in core**: anything KFC- or TB-specific inside `byte-storefronts/core*` belongs in `brand-kfc`/`brand-tb` or the app.
- **Module system**: props type in `@byte-storefronts/types` first; overrides live in the brand package and their key must match the core module export name; consumers resolve via `getModule()`, never import the module set directly; modules don't touch the Redux store directly.
- **Logic altitude**: side effects and reusable business logic belong in sagas, not hooks or components. Tracking calls don't belong in React components/hooks (lint rule `no-tracking-in-react` — route them through sagas/services).
- **dv-owned code**: markdown and source inside dv-synced trees (`byte-storefronts/*/src/**`) edited directly in helium is a `[CRITICAL]` — the next sync overwrites it. Fix upstream in dv-commerce or add a patch/exclude via `tools/sync-dv-commerce/config.ts`.
- **Dependencies**: versions come from the `catalog:` in `pnpm-workspace.yaml` — flag hard-coded versions in package manifests.

### Conventions — works, but not how this repo does it

- Scopes: `@byte-storefronts/*` = workspace packages, `@byte-helium/*` = apps. Any `@phdv/*` import is a dv-commerce leftover — flag it. Use workspace packages (and subpath exports), not `../../../` relative paths.
- DSC components (`@byte-storefronts/dsc-web` / `dsc-native`) over raw MUI/RN primitives (`button-import` rule exists for a reason).
- `themeTokens.*` for spacing/colors/typography — no hardcoded values, no `px` suffix on web design tokens.
- `useStoreSelector`/`useStoreDispatch` from core — never `react-redux`'s `useSelector`/`useDispatch` (`no-react-redux-hooks`).
- One dispatch with a consolidated payload, not consecutive `dispatch`/`put` calls (`no-consecutive-dispatch`).
- `type` over `interface`; no `any` (use `unknown` + guards); `data-testid` on interactive elements; user-facing strings through i18n (`useTranslation`), not hardcoded.
- Native: `expo-image` not RN `Image`; `useAppNavigation()` not raw `useNavigation()`.

### Performance — works, but slow

- **Selectors**: select specific fields, never whole slices — a whole-slice selector re-renders on every slice write.
- **Render allocation**: inline objects/functions/`sx` created per render and passed to memoized children defeat the memo; hoist static ones, `useCallback`/`useMemo` the rest.
- **Loops**: stable unique `key`s (not array index when items reorder); no sorting/filtering/object-building inside JSX over large arrays — hoist to `useMemo`; no `.find()`/`.includes()` inside `.map()` over the same array (`O(n²)` — build a `Map`/`Set` once); no per-item async kicked off in a render loop.
- **Native lists**: `FlashList` with a sensible `estimatedItemSize` — not `FlatList`, not `.map()` in a `ScrollView`.
- **Sagas**: `takeLeading` vs `takeLatest` chosen deliberately; no redundant work per action.
- Heavy components lazy-loaded with `Suspense` + skeleton fallback.

### Complete wiring — works on the demo path, broken elsewhere

When the MR adds a component/screen/hook/module that **supersedes** an existing one, per-file reading misses the leftover registration. Sweep:

```bash
grep -rn "<OldName>\|<old-import-path>" byte-storefronts/<affected-package>/src apps/
```

- Every registration site (navigators, route maps, module maps) the MR should cover is updated; a stale registration for the same key elsewhere renders the old UI on that path — `[CRITICAL]`.
- Same key registered in multiple places must point to the same component unless divergence is clearly intentional (e.g. one brand keeps the old one — confirm who still imports it).
- Apply the same sweep to renamed translation keys, test IDs, and feature flags.

### Tests & release hygiene

- Unit tests for new/changed logic; tests describe behavior, not implementation; edge cases exercised (judge from the diff — don't run coverage).
- E2E for user-facing flows can be left to CI (web Cypress, native Maestro).
- **Changeset present** (`pnpm changeset`; empty one for infra/docs MRs) — the `changeset-status` CI job is blocking and the changeset, not the MR title, drives the version bump.
- MR title in conventional-commit format; a `breaking:` MR includes a migration guide in its description.

### Security & accessibility (quick pass)

- No secrets/keys in the diff; client-exposed env vars use the `NX_PUBLIC_` prefix; inputs validated; auth checks where required.
- `aria-label` on icon-only buttons; form fields with `id` + label; native interactive elements have `accessibilityRole`/`accessibilityLabel`; `onClick` on non-buttons is keyboard-accessible.

## 4. Format and deliver

| Marker | Meaning |
|--------|---------|
| `[CRITICAL]` | Must fix before merge — bugs, security, architecture violations, broken wiring |
| `[SUGGESTION]` | Should improve — performance, better patterns |
| `[NITPICK]` | Optional — naming, minor style |
| `[PRAISE]` | Worth celebrating — always include one when deserved |

```markdown
## MR Review: <title> (!<iid>)

### Summary
<what the MR does + overall assessment, few bullets>

### Findings
#### [CRITICAL] <title>
**File:** `<path>` (line <N>)
**Issue:** <what's wrong — even though it works>
**Fix:** <concrete direction, with a codebase example when possible>

### Tests & release hygiene
<adequate? changeset present? what's missing?>

### Verdict
Approve | Request changes | Comment only
```

**Display the review in the conversation — never post it.** No `glab mr note`, no approvals, no write-back of any kind. If the user explicitly asks to post, confirm intent first.

If the review surfaces a new pattern worth keeping: platform conventions go in the `react-web`/`react-native` skill, process/architecture rules in `AGENTS.md` or `docs/`, and never in markdown inside dv-synced trees.

## Skip these files

`node_modules`, `pnpm-lock.yaml` (flag only unexpected bulk changes), `*.snap` (flag only suspiciously large ones), generated GraphQL (`**/graphql.ts` under `byte-storefronts/contentful|yum-connect`, `*.schema.json`), `*.graphql` unless the MR is about schema changes.
