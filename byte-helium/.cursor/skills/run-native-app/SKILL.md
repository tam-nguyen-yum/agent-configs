---
name: run-native-app
description: Build, launch and visually verify a byte-helium native app on the iOS simulator or Android emulator. Use when asked to run/start/screenshot a native app, to confirm a native change actually works on device, or when a dev-client build shows a red-box, a stale bundle, or a crash that unit tests did not catch.
---

# Running a byte-helium native app locally

Jest cannot catch native-side failures. Anything touching a native module's props
(Lottie, reanimated, gesture-handler, maps, keyboard-controller) can be green in
tests, clean in lint, type-safe — and still abort on first render. When a change
touches native rendering, run it.

## Commands

```bash
nvm use && pnpm install

# Full native build + install + launch (10-25 min cold, ~2 min warm)
pnpm --filter @byte-helium/kfc-au-native-app ios
pnpm --filter @byte-helium/kfc-au-native-app android

# Metro only, against an already-installed dev client
cd apps/kfc-au-native-app && BUILD_TYPE=local pnpm exec expo start --dev-client
#   add --clear to drop the transformer cache

# Regenerate native projects after a config-plugin / dependency change
pnpm --filter @byte-helium/kfc-au-native-app prebuild
```

All three app scripts set `BUILD_TYPE=local`.

## Bundle IDs — check before you trust a run

`resolveNativeBundleIds` (`tools/app-config/src/native-app-config.ts`) maps
`BUILD_TYPE=local` to the **`preview`** variant, so a local build installs as:

| App | Local/dev-client bundle ID |
|---|---|
| `@byte-helium/kfc-au-native-app` | `com.bytestorefronts.kfc.au.preview` |
| `@byte-helium/tb-uk-native-app` | `com.bytestorefronts.tb.uk.preview` |

Prod identities (`com.ncr.hsr.KFCXpress`, `com.tacobelluk.app`) are frozen store
identities and never appear in a local run.

**Simulators accumulate stale installs under old bundle IDs.** The namespace has
changed over time, so an older build of the same app can sit alongside today's
under a different ID — two identical-looking icons on the springboard. Launching
the wrong one runs an old binary against today's Metro bundle, which surfaces as
a bogus native-module error (see below). Always enumerate and check build times:

```bash
xcrun simctl listapps booted | grep -B2 CFBundleIdentifier   # every install
# then compare binary mtimes before trusting one:
stat -f '%Sm %N' <bundle-path>/<AppName>.app/<AppName>
```

Delete stale ones: `xcrun simctl uninstall booted <old.bundle.id>`.

## The loop

```bash
xcrun simctl list devices available | grep iPhone      # find/boot a device
xcrun simctl launch booted com.bytestorefronts.kfc.au.preview
xcrun simctl terminate booted com.bytestorefronts.kfc.au.preview
xcrun simctl io booted screenshot shot.png             # visual check
```

`expo run:ios` exits once it has installed and opened the app; Metro keeps
running on 8081. Check with `lsof -ti:8081`.

On first launch the dev client shows its launcher — tap the
`http://localhost:8081` row to attach, then allow ~45-60s for the first bundle.

## Reading a native crash

A dev-client app that vanishes to the springboard has crashed, not been
backgrounded. The report is JSON-ish (a JSON header line + JSON body):

```bash
ls -t ~/Library/Logs/DiagnosticReports/*.ips | head -3
```

```python
import json
head, body = open(path).read().split('\n', 1)
head, body = json.loads(head), json.loads(body)
imgs = body['usedImages']
for t in body['threads']:
    if t.get('triggered'):
        for f in t['frames'][:20]:
            print(imgs[f['imageIndex']]['name'], f.get('symbol'))
```

`EXC_BREAKPOINT`/`SIGTRAP` with `_assertionFailure` in the trace is a **library
assertion**, not a memory bug — read the frame above it for which library and
which check. These are almost always a prop value the library rejects at runtime.

## Failure modes seen in this repo

| Symptom | Cause | Fix |
|---|---|---|
| `_bindings.X.getConstants is not a function` at bundle load | Stale app binary vs current JS bundle — usually the **wrong bundle ID** | Enumerate installs, launch the freshly built one |
| App aborts the moment a screen first displays | Native library assertion (e.g. lottie-ios `CompatibilityTracker`) | Read the `.ips` trace; fix the offending prop |
| Red-box persists after a JS fix | Transformer cache | Restart Metro with `--clear` |
| Change not appearing | Fast Refresh missed it | Terminate + relaunch the app |

## Isolating a regression

Before blaming the current change for a runtime error, prove it. The native
binary is unchanged by JS edits, so stashing and reloading tests the *same*
binary against baseline JS — a two-minute check that avoids a long wrong hunt:

```bash
git stash push -u -- <changed paths>
xcrun simctl terminate booted <id> && xcrun simctl launch booted <id>
# reproduce, then:
git stash pop
```

## Driving the UI

`xcrun simctl` cannot synthesise touches. For taps and navigation use Maestro —
see the `native-e2e-maestro` skill, **including its limits**: it cannot perform a
drag-and-hold, and its synthesised swipes do not reliably activate
react-native-gesture-handler `Pan` recognizers. Verify what you can (mount,
layout, no crash) and say plainly what remains unverified rather than implying a
gesture was exercised.

### Verifying without a gesture

The view hierarchy gives real laid-out geometry, which is enough to confirm
sizing/positioning maths even when you cannot trigger the interaction:

```bash
maestro hierarchy    # bounds are '[x1,y1][x2,y2]' in points
```
