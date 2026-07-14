---
name: review-pr
description: Review pull requests against byte-helium project standards, architecture rules, and team conventions. Use when the user says "review PR", "review pull request", "check this PR", provides a PR URL or number, or asks for a code review of a branch (for example, "review changes from TBI-276 branch" should be interpreted as "review the PR that merges TBI-276 into main").
---

# Review PR

## Input Resolution

Determine the PR to review from user input. Always assume that when the user says "review changes from \<branch\>" they want the PR that merges that branch into the default base branch (normally `main`) to be reviewed, not just a raw diff:

| Input | How to resolve |
|-------|---------------|
| PR/MR URL (e.g. `https://github.com/owner/repo/pull/123`) | Extract owner, repo, and PR/MR number from URL |
| PR/MR number (e.g. `#123` or `123`) | Use with repo detected from `git remote -v` |
| Branch name (e.g. "review changes from TBI-276 branch") | Treat as "review PR/MR for this branch into the default base (main)"; resolve to the open PR/MR whose head/source branch matches this name (see below) |
| No input | Use current branch (`git branch --show-current`), then resolve its open PR/MR into the default base (see below) |

### Detect the host and pick the CLI

Inspect the remote to choose between `gh` (GitHub) and `glab` (GitLab):

```bash
git remote get-url origin
# *github.com*  → use gh   (operates on a pull request, "PR")
# *gitlab*      → use glab (operates on a merge request, "MR")
```

GitHub "pull request (PR)" and GitLab "merge request (MR)" are the same concept — wherever
this skill says PR, the GitLab path operates on the equivalent MR. Both `gh` and `glab`
infer the owner/repo (and GitLab project) from the local remote, so most commands omit them;
only raw `gh api` / `glab api` paths spell them out.

### Resolve branch or current branch to a PR/MR number

When you have a branch name or the current branch but no number:

```bash
# GitHub
gh pr list --head <branch> --state open --json number,headRefName,title,url
# or resolve a branch's PR directly:
gh pr view <branch> --json number,headRefName,title,url

# GitLab
glab mr list --source-branch <branch>   # returns the MR IID
```

If multiple results match, prefer the one whose head/source ref matches the branch name, or
ask the user.

If that is insufficient, fall back to a search: `gh search prs --repo <owner>/<repo> <query>`
(GitHub PR search syntax) or `glab mr list` with filters / `glab api`.

## Step 1: Fetch PR Context

Gather the PR/MR context with the CLI for the detected host. Run these in parallel:

| What | GitHub (`gh`) | GitLab (`glab`) |
|------|---------------|-----------------|
| **Metadata** — title, body, base/head branch, head sha (for `git` in Step 2) | `gh pr view <n> --json title,body,baseRefName,headRefName,headRefOid` | `glab mr view <iid> -F json` |
| **Changed files** | `gh pr view <n> --json files` (or `gh pr diff <n> --name-only`) | `glab mr diff <iid>` (or `glab api projects/:id/merge_requests/<iid>/changes`) |
| **Inline review threads** — prior line-level feedback | `gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate` | `glab api projects/:id/merge_requests/<iid>/notes` |
| **Conversation comments** | `gh pr view <n> --json comments` | `glab mr view <iid>` |
| **Optional — submitted reviews** (approve / request changes / summaries) | `gh pr view <n> --json reviews` | `glab mr view <iid>` (approvals / notes) |

`<n>` is the PR number (GitHub) and `<iid>` the MR IID (GitLab). The `--paginate` flag on
`gh api` walks all pages of inline comments automatically.

From the combined responses, extract: title, description, base branch, head branch, changed file paths, and prior feedback so you do not duplicate comments.

## Step 2: Gather the Diff and File Context

1. **Get the full diff** against the base branch:
   ```bash
   git fetch origin <base_branch>
   git diff origin/<base_branch>...origin/<pr_branch> -- <changed_files>
   ```

2. **Read each changed file in full** — review the diff in the context of the surrounding code, not in isolation.

3. **For large files (>500 lines)**: use Grep to jump to the changed regions and read around them with `offset`/`limit`, rather than reading the entire file. Delegate broad cross-file sweeps to the Explore agent and keep only the conclusion.

## Step 3: Load Domain Context

For each affected library or app, read its domain-specific guidance:

| Path prefix | Read |
|-------------|------|
| `libs/core/` | `libs/core/CLAUDE.md`, `libs/core/CLAUDE_MEMORY.md` |
| `libs/web-core-modules/` | `libs/web-core-modules/CLAUDE.md` |
| `libs/web-core-framework/` | `libs/web-core-framework/CLAUDE.md` |
| `libs/native-core-modules/` | `libs/native-core-modules/CLAUDE.md` |
| `libs/native-core-framework/` | `libs/native-core-framework/CLAUDE.md` |
| `libs/dsc-react-web/` | `libs/dsc-react-web/CLAUDE.md`, `libs/dsc-react-web/CLAUDE_MEMORY.md` |
| `libs/dsc-react-native/` | `libs/dsc-react-native/CLAUDE.md`, `libs/dsc-react-native/CLAUDE_MEMORY.md` |
| `libs/types/` | `libs/types/CLAUDE.md` |
| `apps/web-app-*` | `libs/web-core-modules/CLAUDE.md` (for override rules) |
| `apps/expo-app-*` | `libs/native-core-modules/CLAUDE.md` (for override rules) |

Cross-cutting review patterns live in the per-library `CLAUDE_MEMORY.md` files (e.g. `libs/core/CLAUDE_MEMORY.md`, `libs/dsc-react-web/CLAUDE_MEMORY.md`) — there is no repo-root `CLAUDE_MEMORY.md`. Read the memory file for each affected library.

When the diff touches **web** code, also consult the `react-web` skill; when it touches **native** code, consult the `react-native` skill — these are the source of truth for platform conventions, package scopes, and APIs, and are kept in sync with the codebase. Prefer them over re-deriving rules here (see Step 5).

Only read files that exist; skip gracefully if a CLAUDE.md is missing for a path.

## Step 4: Run Automated Checks (skip by default)

**CI already runs lint, type-check, and tests on every PR** — don't re-run them as part of a review. `nx affected` recomputes the project graph against the base and is slow; running it locally rarely adds value over reading CI status.

Instead, **read the PR's CI status** (`gh pr checks <n>` on GitHub, or `glab ci status` / `glab mr view <iid>` on GitLab) and report any red checks as `[CRITICAL]`.

Only run a check locally when **all** of these hold: the user explicitly asked for a thorough/local verification, CI status is unavailable, and you can scope it to the changed project(s):

```bash
# Scope to the specific project(s) the PR touches — not the whole affected graph
pnpm nx run <project>:lint
pnpm nx run <project>:type
```

## Step 5: Review Against Project Standards

Work through each changed file and evaluate against these categories. Skip categories that don't apply to the file type.

> **Platform conventions are owned by the `react-web` and `react-native` skills.** For web changes, the `react-web` skill is the authoritative checklist (package scopes, DSC usage, `initApp`/`moduleMap`, routing, dialogs); for native changes, the `react-native` skill is. The categories below are review-specific judgment (wiring, architecture, security, tests) plus a condensed restatement of the platform rules — when they disagree with those skills, the skills win. Don't re-derive platform rules from memory.

### Package scopes (get these right)

| Scope | Meaning |
|-------|---------|
| `@byte-storefronts/*` | This repo's **workspace libraries** (`core`, `core-web`, `core-web-modules`, `core-native`, `core-native-modules`, `dsc-web`, `dsc-native`, `types`, …) — 130+ tsconfig path aliases into `libs/`. Edited here. |
| `@byte-helium/*` | **External** packages from the Helium GitLab registry (e.g. `@byte-helium/coding-standards`). Not editable in this repo. |
| `@phdv/*` | Legacy scope, **only** `@phdv/e2e`, `@phdv/e2e/node`, `@phdv/design-tokens`. Everything else that looks like `@phdv/*` (e.g. `@phdv/types`, `@phdv/core`, `@phdv/dsc-react-web`) is **wrong** — flag it. |

### Complete Wiring (cross-file check — do not skip)

Most categories below are per-file; this one requires comparing the diff against the rest of the repo. When the PR **adds a new component, screen, hook, or module that supersedes an existing one** (e.g. a brand-specific `PreferenceCenter` replacing the core `Preferences` screen):

1. **Find every registration site of the old implementation** — grep the repo (scoped to the affected brand/platform) for the superseded export name and its import path:
   ```bash
   grep -rn "<OldName>\|<old-import-path>" libs/<affected-lib>/src apps/<affected-apps>
   ```
2. **Check that all sites the PR should cover are updated.** If the new component is wired in one navigator/route/module but an old registration remains elsewhere for the same purpose, flag it as `[CRITICAL]` — the old UI will still render on that path.
3. **Check registration-key consistency**: when the same key (e.g. `nativeRoute.PREFERENCES`, a module override key, a route path) is registered in multiple navigators or module maps, all registrations must point to the same component unless the divergence is clearly intentional.
4. Apply the same sweep to renamed translation keys, test IDs, and feature flags: a replacement is only complete when no consumer still references the superseded one (unless the old implementation is intentionally kept for other markets/brands — confirm by checking who still imports it).

This check applies with extra force when **reviewing your own PR before requesting review** — it catches the "added the new thing, forgot to unhook the old thing somewhere" gap that per-file reading misses.

### Architecture Boundaries

- No web ↔ native cross-imports (`@byte-storefronts/dsc-native` / `core-native` in web code, or `dsc-web` / `core-web` in native code)
- No market-specific logic in core libraries (`libs/core/`, `libs/web-core-modules/`, etc.)
- Modules must not interact with the Redux store directly
- Reusable logic belongs in sagas, not hooks
- `@byte-helium/*` packages are external (Helium registry) — changes belong in that repo, not here. `@byte-storefronts/*` are this repo's libs and are fair game.

### Module System

- Market override must have a corresponding core module
- Module types must be defined in `@byte-storefronts/types` before implementation
- Override key in `moduleMap` (passed to `initApp` on web, `loadModules` on native) must match the core module export name
- Core modules define defaults; markets configure, core provides

### Redux & Saga Patterns

- Selectors are specific (select only what you need, never whole slices)
- Reducers are pure (no side effects)
- Side effects belong in sagas
- `takeLeading` vs `takeLatest` is intentional and correct for the use case

### Performance

- No inline object or function creation in render (causes unnecessary re-renders)
- `React.memo` used where appropriate for expensive components
- Inline `sx` objects extracted to module scope when static
- Reference stability maintained for props passed to memoized children
- Lazy loading for heavy components with `Suspense` + skeleton fallback

#### Loops & lists (check explicitly)

- **Stable, unique `key`s** on mapped elements — never the array index when items can reorder/insert/delete
- **No expensive work per iteration in render** — sorting, filtering, mapping over large arrays, or building new objects inside the JSX should be hoisted into `useMemo` (web) or precomputed, not recomputed every render
- **List rows are memoized** when the list is long or re-renders often, and their props are reference-stable (callbacks via `useCallback`, not fresh closures per row)
- **Native long lists use `FlashList`** (`@shopify/flash-list`) with a sensible `estimatedItemSize`, not `FlatList` or a `.map()` inside a `ScrollView`
- **No `O(n²)` patterns** — e.g. `.find()` / `.includes()` inside a `.map()` over the same large array; prefer a `Map`/`Set` lookup built once
- Async work is **not** kicked off per-item inside a render loop (effects/requests belong outside the map, batched where possible)

### TypeScript

- `type` over `interface`
- No `any` — use `unknown` with type guards or proper generic constraints
- Descriptive naming consistent with existing patterns
- Absolute imports using `@byte-storefronts/*` workspace aliases, not deep relative paths (`../../../`)

### React Patterns

- Functional components only (no class components)
- No conditional hooks or conditional early returns before hooks
- DSC components (`@byte-storefronts/dsc-web` or `@byte-storefronts/dsc-native`) over raw HTML/MUI/RN primitives
- `data-testid` on interactive elements for E2E targeting
- Web dialogs are rendered centrally by the `Dialogs` component and driven by feature hooks/state (e.g. `useSwapCouponsDialog`) — not ad-hoc local modal state, and not a generic `useDialog()` (no such hook exists)

### Testing

- Unit tests present for all new/changed business logic
- Test quality: tests describe behavior, not implementation
- Snapshot tests only for intentional UI output verification
- Important branches and edge cases are exercised (judge coverage qualitatively from the diff — don't run a coverage report; it's slow and CI tracks the threshold)
- E2E coverage for user-facing flows (E2E execution can be left to CI)

### Security

- No secrets, API keys, or credentials in the diff
- Environment variables exposed to client use `NX_PUBLIC_` prefix
- User inputs are validated
- Auth checks present where required

### Accessibility

- `aria-label` on icon-only buttons
- Form fields have `id` + `label` association
- Landmark regions (`<nav>`, `<main>`) are labeled
- Interactive elements are keyboard-accessible (`onClick` on non-button → check for `onKeyDown`)

### Browser-global safety (web)

The web app is **client-rendered (Webpack/Nx), not SSR**, so this is a low-priority check — only flag it when code runs outside the browser. Shared utilities, config, and node-side build code that touch `window`, `document`, or `localStorage` should guard with `typeof window !== 'undefined'`. Inside a normal React component body it's a non-issue.

> Import-scope and platform-boundary correctness are already covered by the **Package scopes** table and **Architecture Boundaries** above — apply those, don't re-check separately here.

## Step 6: Format the Review

Structure findings using severity levels:

### Severity Definitions

| Level | Marker | Meaning |
|-------|--------|---------|
| Critical | `[CRITICAL]` | Must fix before merge — bugs, security issues, architecture violations, broken tests |
| Suggestion | `[SUGGESTION]` | Should improve — performance, better patterns, readability |
| Nitpick | `[NITPICK]` | Optional — naming, minor style preferences |
| Praise | `[PRAISE]` | Worth celebrating — good patterns, thorough tests, clean architecture |

### Output Template

```markdown
## PR Review: <PR title> (#<number>)

### Summary
<few sentence overview of what this PR does (put in bullet points) and overall assessment>

### Findings

#### [CRITICAL] <title>
**File:** `<path>` (line <N>)
**Issue:** <what's wrong>
**Fix:** <concrete suggestion with code if helpful>

#### [SUGGESTION] <title>
**File:** `<path>` (line <N>)
**Issue:** <what could be better>
**Suggestion:** <alternative approach, ideally with a codebase example>

#### [NITPICK] <title>
**File:** `<path>` (line <N>)
**Note:** <minor observation>

#### [PRAISE] <title>
**File:** `<path>` (line <N>)
**Note:** <what's done well and why it matters>

### Tests Assessment
<Are tests adequate? What's missing? Coverage concerns?>

### Overall Verdict
- [ ] Approve — ready to merge
- [ ] Request changes — critical issues must be addressed
- [ ] Comment only — suggestions but no blockers
```

Always include at least one `[PRAISE]` item when something is done well — the team culture values celebrating good work.

## Step 7: Display the Review

**Always display the review in the conversation — never post it to the PR/MR.** Do not submit reviews, comments, approvals, or change requests: never run `gh pr comment` / `gh pr review` (or `glab mr note` / `glab mr approve`), or any other write-back. Those are out of scope for this skill; the user takes the displayed review and acts on it themselves.

If the user explicitly asks you to post the review, stop and confirm that intent before doing anything — it is not part of the normal flow.

## Step 8: Surface Learnings

If the review reveals a new pattern, anti-pattern, or architectural insight:

1. Ask the user if it should be added to the affected library's `CLAUDE_MEMORY.md` (e.g. `libs/core/CLAUDE_MEMORY.md`, `libs/dsc-react-web/CLAUDE_MEMORY.md`) — or, if it's a platform convention, to the `react-web` / `react-native` skill instead
2. Use the memory format already in that file:
   ```markdown
   ### <Title>
   - **PR**: #<number> - <brief description>
   - **What happened**: <the setup>
   - **The revelation**: <what the review revealed>
   - **The learning**: <crystallized wisdom>
   ```

## Files to Skip

Do not review these — they are generated or vendored:

- `**/node_modules/**`
- `**/*.snap` (snapshot files — flag only if snapshots are suspiciously large)
- `**/graphql.ts` under `libs/contentful/` or `libs/yum-connect/` (generated by codegen)
- `**/*.schema.json` (generated GraphQL schemas)
- `**/*.graphql` (schema definition files — review only if the PR is specifically about schema changes)
- Lock files (`yarn.lock`, `package-lock.json`)

## Common Pitfalls to Watch For

These are the most frequently caught issues in this codebase (drawn from the per-library `CLAUDE_MEMORY.md` files):

1. **Global state selectors** — selecting entire slices instead of specific fields
2. **Conditional hooks** — `if (x) return; useEffect(...)` violates Rules of Hooks
3. **Inline object props** — `<Comp style={{ margin: 8 }} />` in render causes re-renders of all descendants
4. **Missing edge cases** — "What if both states are true?" (PR #4901 pattern)
5. **Debug code left in** — `console.log`, hardcoded values, temporary changes
6. **Wrong abstraction level** — component logic that should be a saga or service
7. **Incomplete replacement wiring** — a new component supersedes an old one, but a navigator/route/module map elsewhere still registers the old one for the same key (ATLAS-170 pattern: KFC `PreferenceCenter` wired in `MoreStackNavigator` while `ProfileStackNavigator` still used core `Preferences` for `nativeRoute.PREFERENCES`). See "Complete Wiring" in Step 5.
