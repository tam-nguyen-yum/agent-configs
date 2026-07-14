---
name: preview-app-tag
description: Prepare and push preview tags for mobile app preview builds with a mandatory confirmation gate. Use when the user asks to create a preview app build, preview tag, QA preview build, or trigger preview app pipeline for a market (for example tb-uk) from a branch or PR.
disable-model-invocation: true
---

# Preview App Tag

Create preview tags in a safe, auditable way and only push after explicit approval.

## Use This Skill When

- User asks to create a new preview app build for QA via tag trigger.
- User asks for "create preview tag", "trigger preview apps", or similar.
- User provides a market (`tb-uk`, `uk`, etc.) and source (`PR` or `branch`).

## Critical Behavior

- Never push without explicit yes/no confirmation from the user.
- Never overwrite or force-update tags.
- Always show tag, target SHA, source, and commands before push.
- If user asks for `ios` or `android` only, explain that preview tag workflow triggers both platforms in this repo, then confirm whether to continue.

## Inputs To Collect (AskQuestion)

Collect missing inputs using AskQuestion:

1. `market` (example: `tb-uk`)
2. `platformIntent`: `ios`, `android`, or `both`
3. `sourceType`: `pr` or `branch`
4. `sourceValue`: PR number (for `pr`) or branch name (for `branch`)
5. `versionMode`: `auto-next-patch` or `manual-semver`
6. If `manual-semver`: `semver` (`X.Y.Z`)

## Workflow

### 1) Resolve source to exact commit SHA

If `sourceType = pr`:

```bash
gh pr view <PR_NUMBER> --json number,headRefName,headRefOid,url
git fetch origin <headRefName>
```

Use `headRefOid` as target SHA.

If `sourceType = branch`:

```bash
git fetch origin <BRANCH_NAME>
git rev-parse origin/<BRANCH_NAME>
```

Use output SHA as target SHA.

### 2) Build candidate tag

Format must be:

```text
app_v<semver>-preview-<market>
```

If `versionMode = auto-next-patch`:

```bash
git fetch --tags
git tag --list "app_v*-preview-<market>" --sort=-v:refname
```

- Pick latest matching tag.
- Extract `<semver>`.
- Bump patch (`X.Y.Z -> X.Y.(Z+1)`).
- If no matching tag exists, ask user whether to start with `1.0.0` or provide manual semver.

If `versionMode = manual-semver`:

- Validate strict semver regex: `^\d+\.\d+\.\d+$`.

### 3) Validate uniqueness (local and remote)

```bash
git tag --list "<candidate_tag>"
git ls-remote --tags origin "<candidate_tag>"
```

- If exists locally or remotely, stop and ask user to choose another version.

### 4) Create local tag only

```bash
git tag <candidate_tag> <target_sha>
```

Then verify:

```bash
git rev-list -n 1 <candidate_tag>
```

### 5) Pre-push review summary (mandatory)

Show a concise review block:

- Market
- Platform intent
- Source type/value
- Resolved SHA
- Candidate tag
- Validation status (unique local/remote)
- Commands that will run on approval:
  - `git push origin <candidate_tag>`

### 6) Explicit confirmation gate (mandatory)

Ask a direct yes/no question:

- "Push `<candidate_tag>` to origin now?"

If **Yes**:

```bash
git push origin <candidate_tag>
```

Then report:

- Tag pushed
- Target SHA
- Expected CI jobs: `deploy-preview-app-ios`, `deploy-preview-app-android`

If **No**:

- Stop safely.
- Keep local tag.
- Provide cleanup command if user wants to remove it:
  - `git tag -d <candidate_tag>`

## Error Handling

- `gh` missing or unauthorized: ask user to provide branch directly, then use branch flow.
- PR not found: ask for corrected PR number or branch name.
- Branch not found on origin: ask for corrected branch name.
- Invalid semver: request valid `X.Y.Z`.
- Duplicate tag: ask for next version and retry validation.

## Output Style

- Keep progress updates short.
- Always include exact tag and SHA.
- Never claim push happened unless `git push` succeeded.

## Examples

See [examples.md](examples.md) for full sample runs:

- PR-based flow (`tb-uk`, both platforms, auto-next-patch)
- Branch-based flow (manual semver)
