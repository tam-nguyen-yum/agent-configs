# Agent Skills

## What are skills?

Skills are instruction files that give the AI agent repo-specific knowledge for particular tasks — things like "how modules are created in this codebase", "how to run Nx tasks", or "what DSC components to use". Without them the agent gives generic advice; with them it gives answers specific to this monorepo.

## How to use them

**You don't need to do anything most of the time.** The agent picks up the right skill automatically based on what you're working on.

If you want to be explicit, just mention the topic in your message:

```
"Create a new web module for the loyalty banner"   → react-web skill kicks in
"Add a native screen for order tracking"           → react-native skill kicks in
"Why is my nx build failing?"                      → nx-workspace skill kicks in
"Monitor ci"                                       → monitor-ci skill kicks in
"How do I submit with EAS?" / Expo SDK upgrade     → expo-official skill kicks in
```

Skills teach the AI agent how to perform specialised tasks in this repo. The agent picks them up automatically based on context — you can also reference them explicitly in chat.

## Available skills

| Skill | Triggers automatically when... | What it does |
|---|---|---|
| `react-web` | Working in `libs/web-*`, `apps/web-app-*`, or user mentions web app / browser | Guides React web screens, modules, DSC components, routing, and tests |
| `react-native` | Working in `libs/native-*`, `apps/expo-app-*`, or user mentions React Native / Expo / mobile | Guides React Native (iOS/Android) screens, modules, DSC components, navigation, and tests |
| `nx-workspace` | User asks about workspace structure, projects, targets, or an nx command fails | Explores and explains the Nx monorepo: projects, dependencies, targets, configuration |
| `nx-run-tasks` | User wants to build, test, lint, serve, or run any Nx task | Determines the right `nx run` / `nx run-many` / `nx affected` command to use |
| `nx-generate` | User mentions scaffold, generate, create app/lib, or project structure | Runs the correct Nx generator with the right options |
| `nx-plugins` | User wants to add a new framework or technology to the workspace | Finds and installs the right Nx plugin |
| `monitor-ci` | User says "monitor ci", "watch ci", "check ci status", or needs self-healing CI help | Polls Nx Cloud CI pipeline and surfaces failures / self-healing fixes |
| `link-workspace-packages` | A new package was created, or imports fail with "cannot find module" / TS2307 | Wires up workspace package dependencies using yarn workspaces |
| `expo-official` | User mentions Expo Router, EAS (build/submit/workflows), dev client, store submission, SDK upgrade, NativeWind, or generic Expo platform topics | Points to [expo/skills](https://github.com/expo/skills) and maps topics to upstream `SKILL.md` URLs; pair with `react-native` for dv-commerce-specific patterns |

## react-web vs react-native at a glance

| | `react-web` | `react-native` |
|---|---|---|
| **Apps** | `apps/web-app-[market]` | `apps/expo-app-[market]` |
| **Core modules** | `libs/web-core-modules` | `libs/native-core-modules` |
| **Framework** | `libs/web-core-framework` | `libs/native-core-framework` |
| **Design system** | `@phdv/dsc-react-web` (MUI-based) | `@byte-storefronts/dsc-native` (RN Paper-based) |
| **Navigation** | `useNavigate()` — React Router | `useAppNavigation()` — React Navigation |
| **Styling** | `sx` prop + `themeTokens` | `StyleSheet.create` + `themeTokens` |
| **Unit testing** | `@testing-library/react` | `@testing-library/react-native` |
| **E2E testing** | Cypress | Detox |
| **Platform** | Browser | iOS + Android (via Expo SDK) |

> These two stacks share **only** `@phdv/core` (Redux store, sagas, selectors) and `@phdv/types`. Never import web libs in native code or vice versa.
