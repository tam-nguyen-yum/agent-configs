---
name: review-mr
description: Review merge requests against byte-helium project standards, architecture rules, and team conventions. Use when the user says "review PR", "review MR", "check this PR", provides an MR URL or number, or asks for a code review of a branch (for example, "review changes from TBI-276 branch" means "review the MR that merges TBI-276 into main").
---

# Review MR (byte-helium)

byte-helium lives on **GitLab** — reviews operate on MRs via `glab`. "Review changes from \<branch\>" means the open MR from that branch into `main`, not a raw diff. GitHub URL → equivalent `gh` commands.

## 0. Auth gate

Run `glab auth status` before anything else. **Stop immediately** if it fails, or if any later `glab` command hits an auth error (`oauth2`, `invalid_grant`, `unauthorized`, `token`, `not logged in`, HTTP 401):

- No fallbacks — no bare `git diff`, no public API/curl, no partial data from commands that happened to succeed.
- Tell the user to fix `glab` auth (`glab auth login` or refresh their token) and re-run the review.

## 1. Resolve and fetch the MR

| Input | Resolution |
|-------|------------|
| MR URL | Extract the IID from the URL |
| `!123` / `123` | Use as IID directly |
| Branch name | `glab mr list --source-branch <branch>` |
| Nothing | Current branch (`git branch --show-current`), then resolve as above |

Fetch context in parallel (all via `glab`; auth error → stop per step 0):

```bash
glab mr view <iid> -F json          # title, description, branches, SHA
glab mr diff <iid>                  # changed files
glab api projects/:id/merge_requests/<iid>/notes   # prior feedback — don't duplicate it
```

Then the real diff (git is fine **after** glab auth and MR resolution succeed):

```bash
git fetch origin main <source_branch>
git diff origin/main...origin/<source_branch>
```

- **Read each changed file in full** — most "works but wrong" findings live in the surrounding code, not the diff hunk. Files >500 lines: Grep to the changed regions and read around them. Broad cross-file sweeps: delegate to the Explore agent.
- **CI**: `glab ci status` (or the MR view); red checks are `[CRITICAL]`. Don't re-run lint/type/test locally — CI already does, and `nx affected` is slow.

## 2. Load project context

- `AGENTS.md` — always. Non-negotiables, architecture guardrails, release rules.
- Platform conventions are owned by the **`react-web`** / **`react-native`** skills — consult the one the diff touches; on conflict with this file, they win.
- Process: `docs/making-a-change.md`, `docs/making-a-breaking-change.md`, `docs/testing.md`, `docs/cicd.md`, `docs/releases.md`.
- dv-sync: `tools/sync-dv-commerce/SKILL.md`.

## 3. Review — "it works" is not enough

CI proves the code runs. Find what CI can't: code that works but violates architecture, drags performance, or is wired incompletely. Skip dimensions that don't apply.

### Architecture — works, but in the wrong place

- **Platform boundaries**: packages are tagged `platform:agnostic|web|native`. No `dsc-native`/`core-native` imports in web code or `dsc-web`/`core-web` in native — even transitively through a helper.
- **Brand/market logic in core**: anything KFC- or TB-specific inside `byte-storefronts/core*` belongs in `brand-kfc`/`brand-tb` or the app.
- **Module system**: props type in `@byte-storefronts/types` first; overrides live in the brand package with a key matching the core module export name; consumers resolve via `getModule()`, never import the module set directly; modules don't touch the Redux store directly.
- **Logic altitude**: side effects and reusable business logic in sagas, not hooks/components. No tracking calls in React components/hooks (`no-tracking-in-react`) — route through sagas/services.
- **dv-owned code**: direct edits inside dv-synced trees (`byte-storefronts/*/src/**`) are `[CRITICAL]` — the next sync overwrites them. Fix upstream in dv-commerce or patch/exclude via `tools/sync-dv-commerce/config.ts`.
- **Dependencies**: versions come from the `catalog:` in `pnpm-workspace.yaml` — flag hard-coded versions in package manifests.

### Conventions — works, but not how this repo does it

- Scopes: `@byte-storefronts/*` = workspace packages, `@byte-helium/*` = apps. Any `@phdv/*` import is a dv-commerce leftover — flag it. Workspace packages (and subpath exports) over `../../../` paths.
- DSC components (`@byte-storefronts/dsc-web` / `dsc-native`) over raw MUI/RN primitives (`button-import` rule).
- `themeTokens.*` for spacing/colors/typography — no hardcoded values, no `px` suffix on web design tokens.
- `useStoreSelector`/`useStoreDispatch` from core — never `react-redux` hooks (`no-react-redux-hooks`).
- One dispatch with a consolidated payload, not consecutive `dispatch`/`put` calls (`no-consecutive-dispatch`).
- `type` over `interface`; no `any` (use `unknown` + guards); `data-testid` on interactive elements; user-facing strings through i18n (`useTranslation`).
- Native: `expo-image` not RN `Image`; `useAppNavigation()` not raw `useNavigation()`.

### Performance — works, but slow

- **Selectors**: select specific fields, never whole slices — a whole-slice selector re-renders on every slice write.
- **Render allocation**: inline objects/functions/`sx` passed to memoized children defeat the memo; hoist static ones, `useCallback`/`useMemo` the rest.
- **Loops**: stable unique `key`s (not array index when items reorder); no sorting/filtering/object-building inside JSX over large arrays — hoist to `useMemo`; no `.find()`/`.includes()` inside `.map()` over the same array (build a `Map`/`Set` once); no per-item async kicked off in a render loop.
- **Native lists**: `FlashList` with a sensible `estimatedItemSize` — not `FlatList`, not `.map()` in a `ScrollView`.
- **Sagas**: `takeLeading` vs `takeLatest` chosen deliberately; no redundant work per action. Heavy components lazy-loaded with `Suspense` + skeleton.

### Complete wiring — works on the demo path, broken elsewhere

When the MR **supersedes** an existing component/screen/hook/module, per-file reading misses the leftover registration. Sweep:

```bash
grep -rn "<OldName>\|<old-import-path>" byte-storefronts/<affected-package>/src apps/
```

- A stale registration for the same key elsewhere renders the old UI on that path — `[CRITICAL]`.
- Same key registered in multiple places must point to the same component unless divergence is clearly intentional (confirm who still imports the old one).
- Same sweep for renamed translation keys, test IDs, and feature flags.

### Tests & release hygiene

- Unit tests for new/changed logic; tests describe behavior, not implementation; edge cases exercised (judge from the diff — don't run coverage). E2E can be left to CI.
- **Changeset present** (`pnpm changeset`; empty one for infra/docs MRs) — `changeset-status` CI is blocking and the changeset drives the version bump.
- MR title in conventional-commit format; a `breaking:` MR includes a migration guide in its description.

### Security & accessibility (quick pass)

- No secrets/keys in the diff; client-exposed env vars use `NX_PUBLIC_`; inputs validated; auth checks where required.
- `aria-label` on icon-only buttons; form fields with `id` + label; native interactive elements have `accessibilityRole`/`accessibilityLabel`; `onClick` on non-buttons is keyboard-accessible.

## 4. Format and deliver

**Readability rules — non-negotiable:**

- **No paragraphs.** Apart from the 1–2 sentence opening summary, every line of the review is a bullet, a bold finding title, or a code snippet. Never write a multi-sentence prose block.
- One idea per bullet, max ~2 lines each. If a bullet needs more, split it or move detail into the snippet.
- Say what breaks for the user, analytics, or the next sync — not only what the code does differently.
- Order findings: critical → suggestion → nitpick → praise. Cap praise at one or two real wins.
- Skip empty sections — "Tests & changeset: fine." is one bullet, not a section.
- Re-reviews: bullet what changed since last look, then restate only still-open findings (fresh paths/lines).

| Marker | Meaning |
|--------|---------|
| `[CRITICAL]` | Must fix before merge — bugs, security, architecture violations, broken wiring |
| `[SUGGESTION]` | Should improve — performance, better patterns |
| `[NITPICK]` | Optional — naming, minor style |
| `[PRAISE]` | Worth celebrating — include one when deserved |

### Finding shape (required for CRITICAL / SUGGESTION)

One bold title line + exactly these bullets — never prose:

- **Where** — file/lines **changed by this MR** that introduce the problem, quoted as a 3–8 line snippet with neighbors in ` ```start:end:path ` format. Verify lines against `git diff origin/main...origin/<branch> -- <path>` before citing; line numbers alone are not enough.
- **Fix** — the concrete change as a small snippet (with 2–4 neighboring lines so the spot is findable by eye).
- **See also** — a path in this MR already showing the right pattern, with a short snippet; or "none in this MR".
- **Pre-existing (not in this MR):** `<path>` — only if the new code interacts with unchanged call sites; never list unchanged files under **Where**.

Before calling something a bug, check the MR's own tests/description for intent — if the behavior is deliberate (e.g. a test expects it), downgrade to `[SUGGESTION]` or drop it.

Nitpicks and praise: one line each, with a path.

### Template

````markdown
## MR Review: <title> (!<iid>)

<1–2 sentences: what it does and merge readiness. Mention CI only if red or running.>

### Findings

**[CRITICAL] <short title>** — <why it matters in one sentence>.

- **Where:**
```160:162:byte-storefronts/brand-kfc/src/modules/Header/index.tsx
  const handleStartOrderClick = () => {
    openLocationDialog(LocatorStep.OccasionEntry)
  }
```
- **Fix:** pass `'home'` as the second arg:
```ts
openLocationDialog(LocatorStep.OccasionEntry, 'home')
```
- **See also:**
```19:21:byte-storefronts/.../LocalisationBannerBlock/index.tsx
  const handleSetLocationClick = useCallback(() => {
    openLocationDialog(LocatorStep.OccasionEntry, 'home')
  }, [openLocationDialog])
```

**[SUGGESTION] <short title>** — <why it helps>. (same bullet shape)

**[NITPICK] <short title>** — <one line> (`path`).

**[PRAISE] <short title>** — <one line> (`path`).

### Verdict

- **Request changes | Approve | Comment only** — <one-line why>
````

**Display the review in the conversation — never post it.** No `glab mr note`, no approvals, no write-back. If the user explicitly asks to post, confirm intent first.

New patterns worth keeping: platform conventions → `react-web`/`react-native` skill; process/architecture rules → `AGENTS.md` or `docs/`; never markdown inside dv-synced trees.

## Skip these files

`node_modules`, `pnpm-lock.yaml` (flag only unexpected bulk changes), `*.snap` (flag only suspiciously large ones), generated GraphQL (`**/graphql.ts` under `byte-storefronts/contentful|yum-connect`, `*.schema.json`), `*.graphql` unless the MR is about schema changes.
