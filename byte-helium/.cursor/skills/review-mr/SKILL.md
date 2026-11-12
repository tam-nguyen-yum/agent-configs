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

Then the ticket. Take the Jira key from the MR title, the branch or the `Closes` line:

```bash
acli jira workitem view <KEY> --fields "key,summary,description,issuetype" 2>/dev/null
```

No key, or `acli` fails: say so in the summary and use the MR description as the ask. Do not stop the review.

**Rename the chat immediately** after `glab mr view` returns (do not wait for the review), if the host has a rename tool (Cursor: `rename_chat`):

`Review MR !<iid> - <title>`

Use the GitLab IID and the MR title as-is. Truncate the whole string to 200 characters if needed. This is part of the skill, not an extra user request. On a local-only review (no MR view), skip rename.

Then the real diff (git is fine **after** auth succeeds):

```bash
git fetch origin main <source_branch>
git diff origin/main...origin/<source_branch>
```

**Read the MR's code, not the local checkout.** The local files belong to whatever branch is checked out, usually `main`, so their content and line numbers can differ from the MR. Read and search at the MR head:

```bash
git show origin/<source_branch>:<path>
git grep -n "<pattern>" origin/<source_branch> -- byte-storefronts apps tools
```

Every grep in STANDARDS.md runs this way (`git grep ... origin/<source_branch> -- <paths>`). Use the Read tool on local files only when `git rev-parse HEAD` equals `git rev-parse origin/<source_branch>`, or on a local-only review.

**Re-review** (this MR was reviewed earlier in the chat, or the user says "review again"): take the SHA reviewed last from that review, or from `glab api "projects/:id/merge_requests/<iid>/versions" 2>/dev/null` (`head_commit_sha`). A plain `git diff <old_sha> origin/<branch>` shows every file `main` changed if `main` was merged in, so limit it to the MR's files, old and new:

```bash
git log --oneline --first-parent <old_sha>..origin/<source_branch>
git diff <old_sha> origin/<source_branch> -- $( { git diff --name-only origin/main...<old_sha>; git diff --name-only origin/main...origin/<source_branch>; } | sort -u)
```

- **What to read:** the diff hunk plus the surrounding function/block. The Design pass in STANDARDS.md also searches outside the diff, because a copy of existing code never shows in the hunk. Full file only for rewrites, module registration (`modules/index.ts`, `index.native.ts`), or blueprint/`*-page.ts` schema changes. Files >500 lines: Grep the changed regions and read around them. Broad leftover-name sweeps: keep the grep in STANDARDS.md; delegate cross-package hunts to the Explore agent.
- **CI:** note status in the summary. A red job is `[CRITICAL]` only when it matches this diff (same package/files). Unrelated red pipelines are one summary bullet, not a finding. Don't re-run lint/type/test locally — CI already does. The one exception is the single spec file that proves a finding (section 3, "Prove it"). Task runner is **Turborepo** (`pnpm turbo run` / `pnpm --filter`), not Nx.

## 2. Load project context

- `AGENTS.md` — always.
- [STANDARDS.md](STANDARDS.md) — design (smallest fix, duplication, over-built code), architecture, conventions, performance, leftover wiring, recent history, tests/MR hygiene, secrets/a11y.
- `.cursor/BUGBOT.md` and `.gitlab/duo/mr-review-instructions.yaml` — always. They hold the team's rules for copies, brand rules in shared code, no-op tests, failure paths, market config, e2e and CI. Apply them as written; STANDARDS.md does not repeat them. For the Duo file, apply a rule only to files that match its `fileFilters`.
- Platform conventions: the **`react-web`** / **`react-native`** skill for the side the diff touches, when installed.
- Native release/fingerprint changes (native deps, config plugins, `eas.json`, `app.config.ts`, `.fingerprintignore`, `tools/app-config/src`, `X.Y.0` version line): load `.agents/skills/native-release/SKILL.md` and `docs/releases.md`.
- Process docs as needed: `docs/making-a-change.md`, `docs/making-a-breaking-change.md`, `docs/brand-extensions.md`, `docs/testing.md`, `docs/cicd.md`, `docs/releases.md`.

## 3. Review

CI proves the code runs. Find what CI can't: a design bigger than the ticket, copies of existing code, architecture, performance, incomplete wiring, reversed earlier fixes. Skip dimensions that don't apply. Score against STANDARDS.md.

Order:

1. **Design pass first** (STANDARDS.md, "Design"). Before reading the diff in detail, write one line for yourself: the smallest change that would fix the ticket. Then compare the diff with that line.
2. Then the other sections.
3. **Prove it.** Check every `[CRITICAL]` before reporting it.

### Prove it

Each `[CRITICAL]` carries a **Checked** line that says how it was checked. Pick the strongest check available:

- **Ran** — only when a checkout of the MR head with installed dependencies already exists: a worktree in `git worktree list` whose `HEAD` equals `origin/<source_branch>`, or the current checkout on a local-only review. Run the one spec file that covers the finding, by path. Never run a package's whole suite, and never use `-t` without a path.

  ```bash
  pnpm --filter <package> test <path/to/file.spec.ts> --coverage=false
  ```

- **Reverted** — for "this test passes without the change". Same checkout, and only when `git status --porcelain` there is empty. Put the source file back to `main`, run the spec, then restore the file. A spec that still passes proves the finding.

  ```bash
  git checkout origin/main -- <source file>
  pnpm --filter <package> test <path/to/file.spec.ts> --coverage=false
  git checkout HEAD -- <source file>
  ```

  Skip this for a source file the MR adds. Check `git status --porcelain` is empty again afterwards.

- **Read** — no such checkout. Follow the path at the MR head with `git show` / `git grep`: name the caller, the input that breaks, and the line that gives the wrong result.

Do not create a worktree, switch branches or run `pnpm install` to prove a finding.

A `[CRITICAL]` with no check that confirms it becomes a `[SUGGESTION]` written as a question, with **Checked:** not verified. A check that shows the code is right drops the finding.

Cap: **at most 3 `[CRITICAL]` and 5 `[SUGGESTION]`**. When the Design pass has findings, keep up to 2 of the 5 suggestion slots for them. Extra issues become one-line `[NITPICK]`s or are dropped. Then **stop**. Do not patch, commit, or open a follow-up unless the user asks.

## 4. Format and deliver

- 1–2 sentence opening: what the MR does and merge readiness. Mention CI only if red or running.
- No empty sections. Order: critical → suggestion → nitpick → praise (cap praise at one or two).
- CRITICAL / SUGGESTION: scenario + comparison table (not a prose paragraph). See Finding shape.
- Re-reviews: open with what changed since last look (by commit), say which earlier findings are resolved, then only still-open and new findings (fresh paths/lines). See [examples.md](examples.md).
- Clean review: **No merge blockers.** plus at most one praise line. Skip the findings template.

| Marker         | Meaning                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| `[CRITICAL]`   | Must fix before merge — bugs, security, architecture violations, broken wiring |
| `[SUGGESTION]` | Should improve — simpler design, copies of existing code, performance, patterns |
| `[NITPICK]`    | Optional — naming, minor style                                                 |
| `[PRAISE]`     | Worth celebrating — include one when deserved                                  |

### Finding shape (CRITICAL / SUGGESTION)

Do not put the explanation in one long sentence after the title. Lead with the case, then a table a human can scan.

Required:

- **Title** — `[SEVERITY] <short title>` — one short clause, not the whole argument.
- **Scenario** — one line: screen + the case that breaks. Concrete names if they help (`Chips`, `/menu`).
- **Table** — comparison, not a restatement of the title:
  - User/analytics behaviour: `| | Before | After this MR |` — one row per thing that changes (Name, Image, Analytics, Visibility, …).
  - Not a before/after (missing QA list, architecture, tests): `| | Now | Need |`.
  - Design finding: `| | This MR | Simpler |` — rows such as New files, New concepts, Callers, Existing code it repeats. Put the simpler shape in **Fix** as a few lines of code.
- **Where** — file/lines **changed by this MR**, 3–8 line snippet in ` ```start:end:path ` format. Verify against `git diff origin/main...origin/<branch> -- <path>` (or `...HEAD` when local-only). Line numbers alone are not enough. Findings about the MR title or description quote the field instead of a code snippet.

- **Checked** — required on `[CRITICAL]`, one line: `ran <spec path>: <result>`, `reverted <source file>: spec still passes`, `read <caller path>: <what it showed>`, or `not verified`.

After the table, at most 1–2 short lines (scope, a test that locks it). Do not rewrite the table as prose.

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

**[CRITICAL] <short title>**

<Screen + case.>

| | Before | After this MR |
| --- | --- | --- |
| <What> | <old> | <new> |

<Optional: 1–2 short lines — brands/platforms, test that locks it.>

- **Where:**

```160:162:byte-storefronts/brand-kfc/src/modules/Header/index.tsx
  const handleStartOrderClick = () => {
    openLocationDialog(LocatorStep.OccasionEntry)
  }
```

- **Checked:** <ran | reverted | read | not verified> — <one line>

**[SUGGESTION] <short title>**

<Screen + case, or who is blocked.>

| | Now | Need |
| --- | --- | --- |
| <What> | <current> | <wanted> |

- **Where:** (required; Fix / See also optional)

**[NITPICK] <short title>** — <one line> (`path`).

### Verdict

- **Request changes | Ready to merge | Comment only** — <one-line why>
````

Verdict is advice in chat, not a GitLab action.

New patterns worth keeping: platform conventions → `react-web`/`react-native` skill; process/architecture rules → `AGENTS.md`, STANDARDS.md, or `docs/`.

## Skip these files

`node_modules`, `pnpm-lock.yaml` (flag only unexpected bulk changes), `*.snap` (flag only suspiciously large ones), generated GraphQL (`**/graphql.ts` under `byte-storefronts/contentful|yum-connect`, `*.schema.json`), `*.graphql` unless the MR is about schema changes.
