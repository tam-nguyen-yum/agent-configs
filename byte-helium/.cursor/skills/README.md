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
"Review this PR" / "Check my changes"              → review-pr skill kicks in
"Debug the modifier price for this product"        → product-debug skill kicks in
"How do I submit with EAS?" / Expo SDK upgrade     → expo-official skill kicks in
"Create a changeset for my changes"                → changeset skill kicks in
```

Skills teach the AI agent how to perform specialised tasks in this repo. The agent picks them up automatically based on context — you can also reference them explicitly in chat.

> **Nx skills** (`nx-workspace`, `nx-run-tasks`, `nx-generate`, `nx-plugins`, `link-workspace-packages`, `monitor-ci`) come from the [`nx-claude-plugins`](https://github.com/nrwl/nx-ai-agents-config) plugin enabled in `.claude/settings.json`. Don't duplicate them here.

## Available skills

| Skill | Triggers automatically when... | What it does |
|---|---|---|
| `react-web` | Working in `byte-storefronts/*-web*`, `apps/*-web-app*`, or user mentions web app / browser | Guides React web screens, modules, DSC components, routing, and tests |
| `react-native` | Working in `byte-storefronts/*-native*`, `apps/*-native-app*`, or user mentions React Native / Expo / mobile | Guides React Native (iOS/Android) screens, modules, DSC components, navigation, and tests |
| `kfc-web` | Working on KFC-specific flows in `byte-storefronts/brand-kfc/` or `apps/kfc-au-*` (occasion dialog, location flow, cart dialog) | Documents KFC brand-specific UI patterns, query-param-driven modals, and re-localization flow |
| `product-debug` | User debugs modifier prices, weights, `isDefault` flags, or cart hydration issues | Maps the product/modifier domain (legacy vs new product page, brand customisers, selectors) and provides a regression matrix |
| `review-pr` | User asks to review a PR or check their changes | Reviews against byte-helium standards: web/native boundary, Redux patterns, DSC usage, SSR safety, tests, accessibility |
| `expo-official` | User mentions Expo Router, EAS (build/submit/workflows), dev client, store submission, SDK upgrade, NativeWind, or generic Expo platform topics | Points to [expo/skills](https://github.com/expo/skills) and maps topics to upstream `SKILL.md` URLs; pair with `react-native` for byte-helium-specific patterns |
| `changeset` | User asks to create/add a changeset, or asks whether one is needed for a branch/MR | Thin pointer to the canonical repo skill (`tools/skills/changeset/SKILL.md`) plus a diff-to-changeset workflow for the current branch |

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
