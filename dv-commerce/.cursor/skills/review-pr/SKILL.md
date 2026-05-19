---
name: review-pr
description: Review pull requests against dv-commerce project standards, architecture rules, and team conventions. Use when the user says "review PR", "review pull request", "check this PR", provides a PR URL or number, or asks for a code review of a branch (for example, "review changes from TBI-276 branch" should be interpreted as "review the PR that merges TBI-276 into main").
---

# Review PR

## Input Resolution

Determine the PR to review from user input. Always assume that when the user says "review changes from \<branch\>" they want the PR that merges that branch into the default base branch (normally `main`) to be reviewed, not just a raw diff:

| Input | How to resolve |
|-------|---------------|
| PR URL (e.g. `https://github.com/owner/repo/pull/123`) | Extract owner, repo, and PR number from URL |
| PR number (e.g. `#123` or `123`) | Use with repo detected from `git remote -v` |
| Branch name (e.g. "review changes from TBI-276 branch") | Treat as "review PR for this branch into the default base (main)"; use **`list_pull_requests`** (GitHub MCP) to find the open PR whose head branch matches this name |
| No input | Use current branch (`git branch --show-current`), then **`list_pull_requests`** to find its open PR into the default base |

Parse the remote to extract `owner` and `repo`:

```bash
git remote get-url origin
# https://github.com/ORG/REPO.git → owner=ORG, repo=REPO
# git@github.com:ORG/REPO.git    → owner=ORG, repo=REPO
```

### Resolve branch or current branch to a PR number

Use **GitHub MCP** (`server: "user-github"`). Read the tool schema in your MCP filesystem (e.g. `mcps/user-github/tools/list_pull_requests.json`) before calling.

When you have a branch name or the current branch but no PR number, call **`list_pull_requests`**:

```
call_mcp_tool(server: "user-github", toolName: "list_pull_requests", arguments: {
  owner: "<owner>",
  repo: "<repo>",
  state: "open",
  head: "<owner>:<branch>"
})
```

`head` must be `user-or-org:branch-name` (GitHub API). For a branch on the same repo, use the repository `owner` before the colon.

If multiple PRs match, prefer the one whose head ref matches the branch name, or ask the user.

If `list_pull_requests` is insufficient, fall back to **`search_pull_requests`** with a scoped query (`owner`, `repo`, and GitHub PR search syntax).

## Step 1: Fetch PR Context

Use **GitHub MCP** (`server: "user-github"`). Read `mcps/user-github/tools/pull_request_read.json` before calling.

Run **`pull_request_read`** **in parallel** for the same `owner`, `repo`, and `pullNumber` (a **number**, not a string):

1. **PR metadata** — `method: "get"` — title, body/description, `base.ref`, `head.ref`, `head.sha` (for `git` in Step 2).
2. **Changed files** — `method: "get_files"` — file paths; paginate with `page` / `perPage` (max 100) until all files are returned.
3. **Inline review threads** — `method: "get_review_comments"` — prior line-level review feedback; paginate if needed.
4. **PR conversation** — `method: "get_comments"` — issue-style comments on the PR.
5. **Optional** — `method: "get_reviews"` — submitted reviews (approve / request changes / comment summaries).

**Pagination:** For `get_files`, `get_comments`, and `get_review_comments`, advance `page` until a page returns no new items.

**Optional:** `method: "get_diff"` can provide an API diff; prefer **Step 2** `git diff` as the primary source.

Example (repeat per `method`):

```
call_mcp_tool(server: "user-github", toolName: "pull_request_read", arguments: {
  method: "get",
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <number>
})
```

From the combined responses, extract: title, description, base branch, head branch, changed file paths, and prior feedback so you do not duplicate comments.

## Step 2: Gather the Diff and File Context

1. **Get the full diff** against the base branch:
   ```bash
   git fetch origin <base_branch>
   git diff origin/<base_branch>...origin/<pr_branch> -- <changed_files>
   ```

2. **Read each changed file in full** — review the diff in the context of the surrounding code, not in isolation.

3. **For large files (>500 lines)**: use SemanticSearch scoped to the file rather than reading the entire file.

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

Also read `CLAUDE_MEMORY.md` at the repo root — it contains cross-cutting review patterns.

Only read files that exist; skip gracefully if a CLAUDE.md is missing for a path.

## Step 4: Run Automated Checks (optional)

If the user asks for a thorough review, or if you want to catch issues early:

```bash
# Lint affected projects
yarn nx affected -t lint --base=origin/<base_branch>

# Type-check affected projects
yarn nx affected -t type --base=origin/<base_branch>
```

Report any failures as Critical findings.

## Step 5: Review Against Project Standards

Work through each changed file and evaluate against these categories. Skip categories that don't apply to the file type.

### Architecture Boundaries

- No web ↔ native cross-imports (`@phdv/dsc-react-native` in web code or vice versa)
- No market-specific logic in core libraries (`libs/core/`, `libs/web-core-modules/`, etc.)
- Modules must not interact with the Redux store directly
- Reusable logic belongs in sagas, not hooks
- `@byte-storefronts/*` packages are external — changes belong in byte-helium, not here

### Module System

- Market override must have a corresponding core module
- Module types must be defined in `@phdv/types` before implementation
- Override key in `appModule` must match the core module export name
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

### TypeScript

- `type` over `interface`
- No `any` — use `unknown` with type guards or proper generic constraints
- Descriptive naming consistent with existing patterns
- Absolute imports using `@phdv/*` paths, not deep relative paths

### React Patterns

- Functional components only (no class components)
- No conditional hooks or conditional early returns before hooks
- DSC components (`@phdv/dsc-react-web` or `@byte-storefronts/dsc-native`) over raw HTML/MUI/RN primitives
- `data-testid` on interactive elements for E2E targeting
- Dialogs via `useDialog()`, not local modal state

### Testing

- Unit tests present for all new/changed business logic
- Test quality: tests describe behavior, not implementation
- Snapshot tests only for intentional UI output verification
- 80%+ coverage target for new code
- E2E coverage for user-facing flows

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

### SSR Safety (web only)

- `typeof window !== 'undefined'` guard before accessing `window`, `document`, `localStorage`

### Import Correctness

- `@phdv/*` for workspace libraries
- `@byte-storefronts/*` for external packages (not relative paths into node_modules)
- No platform boundary violations

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

## Step 7: Submit or Display

| Mode | Action |
|------|--------|
| **Display** (default) | Show the review in the conversation |
| **Submit** | Post to GitHub via MCP when user explicitly asks |

To submit via GitHub MCP:

```
call_mcp_tool(server: "user-github", toolName: "pull_request_review_write", arguments: {
  method: "create",
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <number>,
  body: "<formatted review text>",
  event: "COMMENT"
})
```

Use `event`: `COMMENT` for a general / comment-only review, `REQUEST_CHANGES` when critical issues must block merge, and `APPROVE` **only** if the user explicitly asked you to approve. Align `event` with your overall verdict.

If the API errors on commit targeting, set `commitID` to the head SHA from `pull_request_read` with `method: "get"` and retry.

Never approve automatically — always confirm with the user before using `APPROVE`.

## Step 8: Surface Learnings

If the review reveals a new pattern, anti-pattern, or architectural insight:

1. Ask the user if it should be added to the relevant `CLAUDE_MEMORY.md`
2. Use the memory format from `CLAUDE_MEMORY.md`:
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

These are the most frequently caught issues in this codebase (from CLAUDE_MEMORY.md):

1. **Global state selectors** — selecting entire slices instead of specific fields
2. **Conditional hooks** — `if (x) return; useEffect(...)` violates Rules of Hooks
3. **Inline object props** — `<Comp style={{ margin: 8 }} />` in render causes re-renders of all descendants
4. **Missing edge cases** — "What if both states are true?" (PR #4901 pattern)
5. **Debug code left in** — `console.log`, hardcoded values, temporary changes
6. **Wrong abstraction level** — component logic that should be a saga or service
