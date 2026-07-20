---
name: changeset
description: Author a Changesets release-intent file for the current branch in byte-helium. Use when the user says "create a changeset", "add a changeset", "changeset for current branch / my changes / this MR", or asks whether a changeset is needed.
---

# Changeset (byte-helium)

The canonical skill lives **in the repo**: read `tools/skills/changeset/SKILL.md` first — it owns the rules (when a changeset is needed, the fixed `@byte-storefronts/*` SDK group, the independently versioned native apps, the `--empty` escape hatch, the blocking `changeset-status` CI gate). Do not duplicate its content here; if it conflicts with this file, it wins.

## Workflow for "create me a changeset for the current branch"

1. Read `tools/skills/changeset/SKILL.md`.
2. Inspect the branch's changes: `git diff --stat origin/main...HEAD` (fetch `origin/main` first if stale), plus `pnpm changeset status --since=origin/main` to see which publishable packages changed without a changeset.
3. Map changed files to packages and decide per the canonical skill: published `@byte-storefronts/*` and/or native app → real changeset; infra/docs/private-only → empty changeset.
4. Pick the bump level from the nature of the change (feat → minor, fix → patch; breaking → major with migration guide in the MR description).
5. Write the `.changeset/*.md` file(s) directly (the interactive `pnpm changeset` prompt doesn't work well for agents). Follow existing conventions visible in git history: kebab-case filename referencing the ticket/change (e.g. `atlas-162-<what-changed>.md`), one file per logical concern, and a summary detailed enough to serve as the `CHANGELOG.md` entry — what changed and why, with the ticket ID.
6. Show the user the changeset content; don't commit unless asked.
