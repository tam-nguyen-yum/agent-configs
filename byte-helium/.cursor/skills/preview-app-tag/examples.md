# Preview App Tag Examples

## Example A: From PR (Auto Patch)

User request:

`Create preview app build for tb-uk from PR 8026`

Flow:

1. Ask missing inputs:
   - platform intent (`ios` / `android` / `both`)
   - version mode (`auto-next-patch` / `manual-semver`)
2. Resolve source:
   - `gh pr view 8026 --json number,headRefName,headRefOid,url`
3. Determine next tag:
   - `git fetch --tags`
   - `git tag --list "app_v*-preview-tb-uk" --sort=-v:refname`
   - latest: `app_v400.340.1-preview-tb-uk`
   - candidate: `app_v400.340.2-preview-tb-uk`
4. Validate uniqueness:
   - `git tag --list "app_v400.340.2-preview-tb-uk"`
   - `git ls-remote --tags origin "app_v400.340.2-preview-tb-uk"`
5. Create local tag:
   - `git tag app_v400.340.2-preview-tb-uk <headRefOid>`
6. Pre-push review summary + ask:
   - `Push app_v400.340.2-preview-tb-uk to origin now?`
7. If approved:
   - `git push origin app_v400.340.2-preview-tb-uk`

Expected CI:

- `deploy-preview-app-ios`
- `deploy-preview-app-android`

## Example B: From Branch (Manual Semver)

User request:

`Create preview tag for tb-uk from branch feature/TBI-302 with manual version 400.341.0`

Flow:

1. Resolve branch SHA:
   - `git fetch origin feature/TBI-302`
   - `git rev-parse origin/feature/TBI-302`
2. Candidate tag:
   - `app_v400.341.0-preview-tb-uk`
3. Validate uniqueness:
   - `git tag --list "app_v400.341.0-preview-tb-uk"`
   - `git ls-remote --tags origin "app_v400.341.0-preview-tb-uk"`
4. Create local tag:
   - `git tag app_v400.341.0-preview-tb-uk <sha>`
5. Ask before push:
   - `Push app_v400.341.0-preview-tb-uk to origin now?`
6. If no:
   - keep local tag
   - optional cleanup: `git tag -d app_v400.341.0-preview-tb-uk`

## Platform Intent Note

If user selects only `ios` or only `android`, explicitly note:

- In this repo, preview tag pipeline typically triggers both iOS and Android preview jobs.
- Ask whether to continue with tag push anyway.
