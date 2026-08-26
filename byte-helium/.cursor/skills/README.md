# Agent Skills

> **Shared with Claude Code** via `.claude/skills` → `../.cursor/skills` symlink. Edit skills here; both Cursor and Claude Code pick up changes.

## What are skills?

Skills are instruction files that give the AI agent repo-specific knowledge for particular tasks — things like "how modules are created in this codebase", "how to run Nx tasks", or "what DSC components to use". Without them the agent gives generic advice; with them it gives answers specific to this monorepo.

## How to use them

**You don't need to do anything most of the time.** The agent picks up the right skill automatically based on what you're working on.

If you want to be explicit, just mention the topic in your message:

```
"Create a new web module for the loyalty banner"   → react-web skill kicks in
"Add a native screen for order tracking"           → react-native skill kicks in
"Review MR !123" / "Review changes from TBI-276"    → review-mr skill kicks in
"Debug the modifier price for this product"        → product-debug skill kicks in
"How do I submit with EAS?" / Expo SDK upgrade     → expo-official skill kicks in
"Create a changeset for my changes"                → changeset skill kicks in
"Add tracking for the add-to-cart event"           → analytics-event skill kicks in
```

Skills teach the AI agent how to perform specialised tasks in this repo. The agent picks them up automatically based on context — you can also reference them explicitly in chat.

> **Nx skills** (`nx-workspace`, `nx-run-tasks`, `nx-generate`, `nx-plugins`, `link-workspace-packages`, `lsp-setup`, `monitor-ci`) come from the [`nx-claude-plugins`](https://github.com/nrwl/nx-ai-agents-config) plugin enabled in `.claude/settings.json`, alongside the official Figma plugin. Don't duplicate them here. The Copilot copies live in `.github/skills/`.

## Available skills

| Skill | Triggers automatically when... | What it does |
|---|---|---|
| `react-web` | Working in `byte-storefronts/*-web*`, `apps/*-web-app*`, or user mentions web app / browser | Guides React web screens, modules, DSC components, routing, and tests |
| `react-native` | Working in `byte-storefronts/*-native*`, `apps/*-native-app*`, or user mentions React Native / Expo / mobile | Guides React Native (iOS/Android) screens, modules, DSC components, navigation, and tests |
| `kfc-web` | Working on KFC-specific flows in `byte-storefronts/brand-kfc/` or `apps/kfc-au-*` (occasion dialog, location flow, cart dialog) — web and native | Documents KFC brand UI patterns, query-param-driven modals, and the re-localization flow |
| `product-debug` | User debugs modifier prices, weights, `isDefault` flags, or cart hydration issues | Maps the product/modifier domain (legacy vs new product page, brand customisers, selectors) and provides a regression matrix |
| `review-mr` | User asks to review an MR/PR, pastes an MR URL or number, or says "review changes from \<branch\>" | Fetches the GitLab MR with `glab` and reviews what CI can't: architecture, brand-vs-core placement, performance, incomplete wiring, tests, changeset, accessibility |
| `expo-official` | User mentions Expo Router, EAS (build/submit/workflows), dev client, store submission, SDK upgrade, NativeWind, or generic Expo platform topics | Points to [expo/skills](https://github.com/expo/skills) and maps topics to upstream `SKILL.md` URLs; pair with `react-native` for byte-helium-specific patterns |
| `changeset` | User asks to create/add a changeset, or asks whether one is needed for a branch/MR | Thin pointer to the canonical repo skill (`tools/skills/changeset/SKILL.md`) plus a diff-to-changeset workflow for the current branch |
| `blueprint` | Adding/moving/hiding UI on a screen that renders `<Blueprint>`, a block not showing up, registering a new block type, or user mentions blueprint / floating block / block registry / `*-page.ts` | Thin pointer to `tools/skills/blueprint/SKILL.md` — schema anatomy, `floatingBlocks`, the block registry, CMS vs local fallback, and the "edit the schema, not the screen" rule |
| `run-native-app` | User asks to run/start/screenshot a native app, or a change needs confirming on a real simulator rather than in jest | Build + launch loop, local `preview` bundle IDs, the stale-install trap, Metro cache resets, reading `.ips` crash traces, isolating a regression with `git stash` |
| `native-e2e-maestro` | Writing or running Maestro flows, adding a smoke test, or considering Maestro to drive a gesture | Install, flow syntax, `maestro hierarchy`, screenshot-hash verification — and the hard limits (no drag-and-hold, long durations ignored, RNGH `Pan` often not activated) |
| `confluence-docs` | User pastes a Confluence link or asks what a wiki page / spec says | Reads Confluence pages with `acli` — resolving the page ID, `--body-format` choices, walking a page tree, and turning the XHTML into plain text |
| `analytics-event` | User asks to add/implement a tracking or analytics event, or works an ATLAS tracking ticket | Wires a brand analytics event (GTM, mParticle, Firebase) the way past event MRs were reviewed, so the same mistakes don't repeat |

## react-web vs react-native at a glance

| | `react-web` | `react-native` |
|---|---|---|
| **Apps** | `apps/kfc-au-web-app`, `apps/tb-uk-web-app` | `apps/kfc-au-native-app`, `apps/tb-uk-native-app` |
| **Core modules** | `byte-storefronts/core-web-modules` | `byte-storefronts/core-native-modules` |
| **Framework** | `byte-storefronts/core-web` | `byte-storefronts/core-native` |
| **Design system** | `@byte-storefronts/dsc-web` (MUI-based) | `@byte-storefronts/dsc-native` (RN Paper-based) |
| **Navigation** | `useNavigate()` — React Router | `useAppNavigation()` — React Navigation |
| **Styling** | `sx` prop + `themeTokens` | `StyleSheet.create` + `themeTokens` |
| **Unit testing** | `@testing-library/react` | `@testing-library/react-native` |
| **E2E testing** | Cypress | Maestro |
| **Platform** | Browser | iOS + Android (via Expo SDK) |

> These two stacks share **only** platform-agnostic packages like `@byte-storefronts/core` (Redux store, sagas, selectors) and `@byte-storefronts/types`. Never import web libs in native code or vice versa.
