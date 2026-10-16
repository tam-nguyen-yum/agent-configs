---
name: review-mr
description: Review merge requests against byte-helium project standards, architecture rules, and team conventions. Use when the user says "review PR", "review MR", "check this PR", provides an MR URL or number, or asks for a code review of a branch (for example, "review changes from TBI-276 branch" means "review the MR that merges TBI-276 into main").
---

# Review MR (byte-helium)

Findings only — display in chat. Never `glab mr note`, never approve, never write back. If the user asks to post, confirm first.

byte-helium lives on **GitLab**. "Review changes from \<branch\>" means the open MR from that branch into `main`. GitHub URL: same workflow after swapping `glab` for `gh` (`gh pr view`, `gh pr diff`, `gh pr checks`, `gh api repos/:owner/:repo/pulls/<n>/comments`).

Judging rules: [STANDARDS.md](STANDARDS.md). Finding shape: [examples.md](examples.md).

## 0. Auth gate

Run `glab auth status` first.

**MR in the request** (`!123`, GitLab URL, or "review the MR"): auth failure (`oauth2`, `invalid_grant`, `unauthorized`, `token`, `not logged in`, HTTP 401) → **stop**. No fallbacks. Tell the user to `glab auth login` (or refresh the token) and re-run.

**Local branch only** (already checked out; no MR id/URL): if `glab` fails, run `git fetch origin main`, review `git diff origin/main...HEAD`, and say the review is **local-only** — no CI, no prior notes. Do not invent MR metadata.

## 1. Resolve and fetch

| Input          | Resolution                                                          |
| -------------- | ------------------------------------------------------------------- |
| MR URL         | Extract the IID from the URL                                        |
| `!123` / `123` | Use as IID directly                                                 |
| Branch name    | `glab mr list --source-branch <branch>`                             |
| Nothing        | Current branch (`git branch --show-current`), then resolve as above |

When `glab` is available, fetch in parallel:

```bash
glab mr view <iid> -F json 2>/dev/null                                      # title, description, branches, SHA, head_pipeline
glab api "projects/:id/merge_requests/<iid>/notes?per_page=100" 2>/dev/null # prior feedback; skip `system` notes, don't duplicate it
glab ci status -b <source_branch> 2>/dev/null
```

`glab` prints an update notice on stderr that breaks JSON parsing, so keep `2>/dev/null`. Quote API paths containing `?` — zsh treats them as globs. Without `per_page` the notes API returns only 20.

**Rename the chat immediately** after `glab mr view` returns (do not wait for the review), if the host has a rename tool (Cursor: `rename_chat`):

`Review MR !<iid> - <title>`

Use the GitLab IID and the MR title as-is. Truncate the whole string to 200 characters if needed. This is part of the skill, not an extra user request. On a local-only review (no MR view), skip rename.

Then the real diff (git is fine **after** auth succeeds):

```bash
git fetch origin main <source_branch>
git diff origin/main...origin/<source_branch>
```

**Re-review** (this MR was reviewed earlier in the chat, or the user says "review again"): take the SHA reviewed last from that review, or from `glab api "projects/:id/merge_requests/<iid>/versions" 2>/dev/null` (`head_commit_sha`). A plain `git diff <old_sha> origin/<branch>` shows every file `main` changed if `main` was merged in, so limit it to the MR's files, old and new:

```bash
git log --oneline --first-parent <old_sha>..origin/<source_branch>
git diff <old_sha> origin/<source_branch> -- $( { git diff --name-only origin/main...<old_sha>; git diff --name-only origin/main...origin/<source_branch>; } | sort -u)
```

- **What to read:** the diff hunk plus the surrounding function/block. Full file only for rewrites, module registration (`modules/index.ts`, `index.native.ts`), or blueprint/`*-page.ts` schema changes. Files >500 lines: Grep the changed regions and read around them. Broad leftover-name sweeps: keep the grep in STANDARDS.md; delegate cross-package hunts to the Explore agent.
- **CI:** note status in the summary. A red job is `[CRITICAL]` only when it matches this diff (same package/files). Unrelated red pipelines are one summary bullet, not a finding. Don't re-run lint/type/test locally — CI already does. Task runner is **Turborepo** (`pnpm turbo run` / `pnpm --filter`), not Nx.

## 2. Load project context

- `AGENTS.md` — always.
- [STANDARDS.md](STANDARDS.md) — architecture, conventions, performance, leftover wiring, recent history, tests/MR hygiene, secrets/a11y.
- Platform conventions: the **`react-web`** / **`react-native`** skill for the side the diff touches, when installed.
- Process docs as needed: `docs/making-a-change.md`, `docs/making-a-breaking-change.md`, `docs/testing.md`, `docs/cicd.md`, `docs/releases.md`.

## 3. Review

CI proves the code runs. Find what CI can't: architecture, performance, incomplete wiring, reversed earlier fixes. Skip dimensions that don't apply. Score against STANDARDS.md.

Cap: **at most 3 `[CRITICAL]` and 5 `[SUGGESTION]`**. Extra issues become one-line `[NITPICK]`s or are dropped. Then **stop**. Do not patch, commit, or open a follow-up unless the user asks.

## 4. Format and deliver

- 1–2 sentence opening: what the MR does and merge readiness. Mention CI only if red or running.
- No empty sections. Order: critical → suggestion → nitpick → praise (cap praise at one or two).
- Say what breaks for the user or analytics — not only what the code does differently.
- Re-reviews: open with what changed since last look (by commit), say which earlier findings are resolved, then only still-open and new findings (fresh paths/lines). See [examples.md](examples.md).
- Clean review: **No merge blockers.** plus at most one praise line. Skip the findings template.

| Marker         | Meaning                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| `[CRITICAL]`   | Must fix before merge — bugs, security, architecture violations, broken wiring |
| `[SUGGESTION]` | Should improve — performance, better patterns                                  |
| `[NITPICK]`    | Optional — naming, minor style                                                 |
| `[PRAISE]`     | Worth celebrating — include one when deserved                                  |

### Finding shape (CRITICAL / SUGGESTION)

Required:

- **Title** — `[SEVERITY] <short title>` — why it matters (one sentence).
- **Where** — file/lines **changed by this MR**, 3–8 line snippet in ` ```start:end:path ` format. Verify against `git diff origin/main...origin/<branch> -- <path>` (or `...HEAD` when local-only). Line numbers alone are not enough. Findings about the MR title or description quote the field instead of a code snippet.

Optional:

- **Fix** — small snippet if the change is obvious.
- **See also** — only if `grep` found a sibling **in this MR** that already does it right. Never invent one; omit the bullet rather than write "none in this MR".
- **Pre-existing (not in this MR):** `<path>` — only if the new code interacts with unchanged call sites; never list unchanged files under **Where**.

Nitpicks and praise: one line each, with a path.

### Template

````markdown
## MR Review: <title> (!<iid>)

<1–2 sentences: what it does and merge readiness.>

### Findings

**[CRITICAL] <short title>** — <why it matters>.

- **Where:**

```160:162:byte-storefronts/brand-kfc/src/modules/Header/index.tsx
  const handleStartOrderClick = () => {
    openLocationDialog(LocatorStep.OccasionEntry)
  }
```

**[SUGGESTION] <short title>** — <why it helps>. (Where required; Fix / See also optional)

**[NITPICK] <short title>** — <one line> (`path`).

### Verdict

- **Request changes | Ready to merge | Comment only** — <one-line why>
````

Verdict is advice in chat, not a GitLab action.

New patterns worth keeping: platform conventions → `react-web`/`react-native` skill; process/architecture rules → `AGENTS.md`, STANDARDS.md, or `docs/`.

## Skip these files

`node_modules`, `pnpm-lock.yaml` (flag only unexpected bulk changes), `*.snap` (flag only suspiciously large ones), generated GraphQL (`**/graphql.ts` under `byte-storefronts/contentful|yum-connect`, `*.schema.json`), `*.graphql` unless the MR is about schema changes.
