---
name: expo-official
description: Applies Expo team official agent guidance from expo/skills (Expo Router UI, EAS Build/Submit/Workflows, dev client, NativeWind/Tailwind, API routes, data fetching, SDK upgrades, App Store/Play, DOM components, SwiftUI/Jetpack Compose). Use when the user works on Expo or EAS, or mentions expo-router, eas.json, EAS Hosting, TestFlight, dev client, upgrading Expo SDK, or generic Expo docs—not only inside byte-helium native apps.
---

# Expo official skills (expo/skills)

## Scope with byte-helium

- For **this monorepo’s** patterns (modules, DSC, Redux, market overrides), follow the project **`react-native`** skill first.
- Use **this skill** when the task is **Expo/EAS platform** behavior: Router, EAS CLI, credentials, workflows, store submission, SDK upgrades, NativeWind setup, etc.

## Primary workflow (no Remote Rule required)

Cursor’s **Remote Rule (GitHub)** flow is optional. If **Done** stays disabled or the feature is missing, use this skill only: for the matching topic below, **read the upstream file** via the raw URL (e.g. the Read tool on the URL, or `curl`). That loads the same content as Expo’s plugin without installing a remote rule.

## Optional: Cursor Remote Rule (GitHub)

Expo’s README suggests: Settings → **Rules & Commands** → **Project Rules** → **Add Rule** → **Remote Rule (GitHub)** → `https://github.com/expo/skills.git`.

If **Done** is greyed out, common causes include: Cursor version without full GitHub rule support, GitHub not connected in Cursor, org policy blocking remote rules, or the UI requiring a specific URL shape (try the repo URL without `.git`). This project does **not** depend on that working—the raw-URL workflow above is enough.

## When to read which upstream skill

Base path (replace `<skill>`):

`https://raw.githubusercontent.com/expo/skills/main/plugins/expo/skills/<skill>/SKILL.md`

| Topic | `<skill>` |
|-------|-----------|
| Expo Router UI, navigation, styling, animations, native UI patterns | `building-native-ui` |
| API routes + EAS Hosting | `expo-api-routes` |
| EAS Workflow YAML / CI-CD | `expo-cicd-workflows` |
| App Store, Play Store, EAS Build/Submit, web hosting | `expo-deployment` |
| Dev builds, TestFlight dev client, `expo-dev-client` | `expo-dev-client` |
| Local Expo modules / native modules | `expo-module` |
| Tailwind v4 + NativeWind v5 | `expo-tailwind-setup` |
| Jetpack Compose in Expo | `expo-ui-jetpack-compose` |
| SwiftUI in Expo | `expo-ui-swift-ui` |
| Fetching, caching, offline, Router loaders | `native-data-fetching` |
| SDK upgrade, deprecations, dependency fixes | `upgrading-expo` |
| DOM components / web code in native | `use-dom` |

## Referenced files under an upstream skill

If `SKILL.md` points to `./references/...` or `./scripts/...`, resolve under the same skill folder on `main`:

`https://raw.githubusercontent.com/expo/skills/main/plugins/expo/skills/<skill>/references/...`

## Other install paths (not Cursor-native)

- **Claude Code:** `/plugin marketplace add expo/skills` then `/plugin install expo` (see [expo/skills README](https://github.com/expo/skills/blob/main/README.md)).
- **Generic:** `bunx skills add expo/skills` (extracts skills for manual upgrades).

## License

Upstream content is MIT (see [expo/skills](https://github.com/expo/skills)).

## More detail

See [reference.md](reference.md) for quick copy-paste URLs and verification prompts.
