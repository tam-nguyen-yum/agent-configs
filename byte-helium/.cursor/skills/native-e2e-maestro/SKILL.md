---
name: native-e2e-maestro
description: Write and run Maestro flows against byte-helium native apps, and know what Maestro cannot do. Use when authoring or running maestro flows, when adding a smoke test under apps/*-native-app-e2e/, or before proposing Maestro to drive a gesture — its swipe/hold limits decide whether the plan is viable at all.
---

# Maestro — byte-helium

Maestro is the repo's native E2E tool. Flows live under
`apps/tb-uk-native-app-e2e/maestro/`; CI runs are currently disabled pending
runner capacity, so treat local runs as the only signal.

## Read this before proposing Maestro for a gesture

Maestro drives taps and scrolls well and is useless for anything else. Check
these against the interaction **before** recommending it:

- **`swipe` always releases at the end.** There is no drag-and-hold. An
  interaction requiring "pull down and hold for N seconds" cannot be expressed.
  Buying the hold with a long `duration:` does not work either — see below.
- **Long durations are not honoured.** A `duration: 40000` swipe reports
  `COMPLETED` while producing no visual change at all.
- **Synthesised swipes do not reliably activate RNGH `Pan` recognizers.** A
  custom `Gesture.Pan()` with `activeOffsetY` / `failOffsetY` thresholds may
  never fire, even though a swipe in the *opposite* direction scrolls the
  underlying `ScrollView` fine. Native `UIScrollView` pan recognizers receive the
  events; custom RNGH ones may not.
- `COMPLETED` means "Maestro emitted the gesture", **not** "the app responded".
  Always verify with a screenshot diff.

If the interaction needs a real press-drag-hold-release, Maestro is the wrong
tool. Reach for CGEvent mouse control against the Simulator window
(`pyobjc-framework-Quartz`, needs Accessibility permission) — and say so up front
rather than discovering it after a build.

## Install

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash    # needs a JDK (repo has Zulu 17)
export PATH="$PATH:$HOME/.maestro/bin"
maestro --version
```

Not a workspace dependency — it is a machine-level install. Ask before adding it
to someone's machine.

## Running

```bash
# Repo smoke flows (APP_BUNDLE_ID is set by the package script)
pnpm --filter @byte-helium/tb-uk-native-app-e2e test:ios:smoke

# An ad-hoc flow
maestro test myflow.yaml
maestro hierarchy      # dump the current view tree — the debugging workhorse
```

## Flow basics

```yaml
appId: com.bytestorefronts.kfc.au.preview   # local build = 'preview' variant
---
- tapOn: "Menu"
- extendedWaitUntil:
    visible:
      id: "menu-landing-scroll-view"
    timeout: 30000
- swipe:
    start: 50%, 25%
    end: 50%, 95%
    duration: 800
```

`testID` maps to `resource-id` in the hierarchy. Prefer IDs over visible text.

Attaching a dev client to Metro is itself a flow:

```yaml
- tapOn: "http://localhost:8081"
- extendedWaitUntil:
    notVisible: "DEVELOPMENT SERVERS"
    timeout: 60000
```

## Verifying a flow actually did something

Screenshots are the ground truth, and identical hashes are the tell:

```bash
for i in 1 2 3 4 5; do xcrun simctl io booted screenshot "f-$i.png"; done
for f in f-*.png; do echo "$(md5 -q $f | cut -c1-8) $f"; done
```

All hashes equal ⇒ nothing moved, regardless of what Maestro reported.

## Interpreting "nothing happened"

Distinguish *the gesture never fired* from *the UI failed to render*, using
something you know is unconditionally painted. If a revealed surface has an
always-opaque layer and no trace of it appears, the gesture never fired — the
rendering is not implicated. Reason from the artifact instead of guessing.

## Writing repo flows

Smoke flows belong in `apps/<app>-e2e/maestro/flows/smoke/`. Keep them tied to
stable `testID`s, not copy — copy is translated and changes with CMS content.
