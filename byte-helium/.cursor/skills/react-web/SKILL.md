---
name: react-web
description: Guides development of React web screens, components, modules, routing, and tests in this byte-helium monorepo. Use whenever working in byte-storefronts/core-web*, byte-storefronts/dsc-web, byte-storefronts/shared-web, apps/*-web-app*, or when the user mentions web app, web screen, web module, or browser-facing features.
---

# React Web — byte-helium

> This is plain **React** bundled with **Vite** (Nx) — not React Native Web, and **not SSR/Next.js**. The web and mobile stacks are completely separate. The app is client-rendered: `initApp()` resolves and then `root.render()` mounts it.

## Package scope (read first)

Every internal import uses the **`@byte-storefronts/*`** scope — there is no `@phdv/*`. These are real pnpm workspace packages under `byte-storefronts/` (with granular `package.json` exports for subpaths), not tsconfig path aliases. The ones you'll use most:

| Package | Lives in | Holds |
|-------|---------|-------|
| `@byte-storefronts/types` | `byte-storefronts/types/src` | All prop & domain types |
| `@byte-storefronts/core` (+ subpaths `/menu`, `/cart`, `/globalState`, …) | `byte-storefronts/core/src` | Cross-platform state, selectors, domain hooks |
| `@byte-storefronts/core-web` | `byte-storefronts/core-web/src` | Screens, routing, `initApp`, framework |
| `@byte-storefronts/core-web-modules` | `byte-storefronts/core-web-modules/src` | Default modules + `getModule()` |
| `@byte-storefronts/dsc-web` (+ `/Icons`) | `byte-storefronts/dsc-web/src` | DSC components, `useTheme`, icons |
| `@byte-storefronts/brand-kfc` / `brand-tb` | `byte-storefronts/brand-[kfc\|tb]/src` | Brand assets, theme, routes, module overrides (`webModules`) |

## Key paths

| What | Where |
|------|-------|
| Core modules (default UI) | `byte-storefronts/core-web-modules/src/modules/` |
| Framework (screens, routing, hooks) | `byte-storefronts/core-web/src/` |
| Design system components | `@byte-storefronts/dsc-web` |
| Brand overrides | `byte-storefronts/brand-[kfc\|tb]/src/modules/` (exported as `webModules`) |
| Module prop types | `byte-storefronts/types/src/modules/` |
| App bootstrap | `apps/[brand-market]-web-app/src/main.tsx` |

Apps present under `apps/`: `kfc-au-web-app` and `tb-uk-web-app` (each with a matching `*-e2e` project), plus `storybook-web`. App package names use the `@byte-helium/*` scope (e.g. `@byte-helium/kfc-au-web-app`).

## Where new code goes

`core*` packages ship to every brand — a change there reaches KFC and TB at once. So a feature asked for by one brand starts in that brand's package, not in core.

| Asked for by | Put it in |
|---|---|
| One brand (KFC only, TB only) | `byte-storefronts/brand-[kfc\|tb]/src/` |
| One app / market | `apps/<brand>-<market>-web-app/src/` |
| Every brand, same behaviour | `core-web*` / `core` — say so before you start |

Editing `core-web*`, `core`, or `dsc-web` for a brand feature is a last resort. It is only right when the brand package genuinely cannot hold the change — a bug every brand hits, or the core module needs a new prop or extension point for the brand to hook into. When that happens:

- Tell the user first, in one sentence, and say why the brand package can't hold it.
- Keep the core change additive: a new optional prop or hook point, with every other brand rendering exactly what it renders today.
- Repeat the reason in the MR description — reviewers flag a brand MR that touches core as `[CRITICAL]` (see the `review-mr` skill).

## Non-negotiables

- **A brand feature goes in the brand package** — only touch `core*` when every brand needs the change (see "Where new code goes").
- **Always use DSC components** (`@byte-storefronts/dsc-web`) — never raw HTML elements or bare MUI components. DSC is the MUI wrapper layer.
- **Unit tests mandatory** for all logic; view-only components only need tests if they contain logic
- Module types must live in `@byte-storefronts/types` before implementing the module
- Never import from native libraries — no `@byte-storefronts/dsc-native`, `@byte-storefronts/core-native`, etc.
- Always add `data-testid` attributes for E2E targeting
- Never hardcode colors or spacing — use `themeTokens.*`
- **Guard browser globals in shared/utility code** — `typeof window !== 'undefined'` before touching `window`/`document` (the app is client-only, but utilities can run in Node during build/tests)

## Creating a web module

### 1. Define the type in `byte-storefronts/types`

```typescript
// byte-storefronts/types/src/modules/MyModuleProps.ts
export type MyModuleProps = {
  title: string
  onAction: () => void
}
```

### 2. Implement the default in `byte-storefronts/core-web-modules`

Only when every brand should get this UI. If one brand asked for it, skip to step 4 and build the component in the brand package instead — leave the core default alone.

```typescript
// byte-storefronts/core-web-modules/src/modules/MyModule.tsx
import { Button, Typography, Box, useTheme } from '@byte-storefronts/dsc-web'
import type { MyModuleProps } from '@byte-storefronts/types'

const MyModule: React.FC<MyModuleProps> = ({ title, onAction }) => {
  const { themeTokens } = useTheme()
  return (
    <Box sx={{ p: themeTokens.spacing200 }}>
      <Typography variant="h2">{title}</Typography>
      <Button variant="contained" onClick={onAction} data-testid="my-module-btn">
        Go
      </Button>
    </Box>
  )
}

export default MyModule
```

`useTheme` is exported from the `@byte-storefronts/dsc-web` root (not a `/theme` subpath). Icons come from `@byte-storefronts/dsc-web/Icons`.

### 3. Register it in the module definition

The module contract is the `WebAppModuleDependency` type in `byte-storefronts/types/src/appDependencies.ts`. Add your default implementation to the core module set in `byte-storefronts/core-web-modules/src` so `getModule()` can resolve it. Don't import that set directly — go through `getModule()`.

### 4. Brand implementation or override

The brand's version lives in the brand package and is exported through its `webModules` set (`byte-storefronts/brand-[kfc|tb]/src/modules/index.ts`), which the app passes to `initApp` as `moduleMap`:

```typescript
// byte-storefronts/brand-kfc/src/modules/MyModule/index.tsx
import type { MyModuleProps } from '@byte-storefronts/types'

const MyModuleKFC: React.FC<MyModuleProps> = ({ title, onAction }) => (
  // KFC-specific implementation
)

export default MyModuleKFC
```

### 5. Consume in an orchestration component

```typescript
import { getModule } from '@byte-storefronts/core-web-modules'
import { useStoreSelector } from '@byte-storefronts/core/globalState'

const MyOrchestrator: React.FC = () => {
  const data = useStoreSelector(selectMyData)
  const { MyModule } = getModule()

  return <MyModule title={data.title} onAction={() => {}} />
}
```

## Screens

```typescript
// byte-storefronts/core-web/src/screens/MyScreen.tsx
import HeadMeta from '../shared/components/HeadMeta'
import { ErrorBoundary } from 'react-error-boundary'
import ErrorFallback from '../shared/components/ErrorFallback'
import { useTranslation } from 'react-i18next'

export const MyScreen = () => {
  const { t } = useTranslation()
  return (
    <>
      <HeadMeta title={t('myScreen.title')} description={t('myScreen.description')} />
      <ErrorBoundary FallbackComponent={ErrorFallback}>
        {/* content */}
      </ErrorBoundary>
    </>
  )
}
```

There is **no generic `<Template>` component** — page chrome is applied by the layout wrappers (`LayoutWrapper` / `SimpleLayoutWrapper`), which the route layer wraps around screens for you (see Routing).

Always pair a new screen with a **loading skeleton** in `byte-storefronts/core-web/src/page-skeletons/`:

```typescript
// byte-storefronts/core-web/src/page-skeletons/MyScreenSkeleton.tsx
import { Skeleton } from '@byte-storefronts/dsc-web'
import { DefaultSkeleton } from './DefaultSkeleton'

export const MyScreenSkeleton = () => (
  <DefaultSkeleton>
    <Skeleton variant="rectangular" height={200} />
    <Skeleton variant="text" />
  </DefaultSkeleton>
)
```

## Routing

Routing is built from a **route map** assembled in each app's `main.tsx` (via `getBrandRouteMap`) from `screens` and `redirects`, then passed to `initApp` as `routeMap`. The framework renders routes through `CustomRoute`, which controls layout/header/footer per route:

```typescript
// CustomRoute props (byte-storefronts/core-web/src/CustomRoute.tsx)
<CustomRoute
  path="/menu"
  component={MenuPage}
  hideHeader={false}
  hideFooter={false}
  removeContentContainer={false}
  skipLayoutWrapper={false}
/>
```

For auth-gated pages use `LoggedOutRedirectRoute` (`byte-storefronts/core-web/src/shared/components/`). There is **no `MarketRoute` or `ProtectedRoute`** — market-specific routes are handled per app through the route map.

Navigation inside components uses React Router:

```typescript
import { useNavigate } from 'react-router-dom'
const navigate = useNavigate()
navigate('/menu')
```

Use `useRouteInfo()` for route-aware logic. It returns `{ isOrderPage, isHomePage, isMenuPage }`:

```typescript
import { useRouteInfo } from '../shared/hooks/useRouteInfo'

const Layout = () => {
  const { isMenuPage } = useRouteInfo()
  return isMenuPage ? <MenuHeader /> : <FullHeader />
}
```

## App bootstrap (`initApp`)

`initApp` is imported from `@byte-storefronts/core-web`. The keys in `moduleMap` must match the **core module names** being overridden; `serviceMap` overrides services; `routeMap` supplies routes:

```typescript
// apps/kfc-au-web-app/src/main.tsx
import { initApp } from '@byte-storefronts/core-web'
import { config as brandConfig, getBrandRouteMap, webModules } from '@byte-storefronts/brand-kfc'
import { config as marketConfig, findEnvironmentConfig } from './config'

initApp({
  brandConfig,
  environmentConfig: findEnvironmentConfig(),
  marketConfig,
  serviceMap: { maps: createMapService },          // service overrides
  moduleMap: webModules,                            // brand overrides; keys MUST match core module names
  routeMap: getBrandRouteMap(marketConfig.market.name, { screens, redirects }),
  blueprintMap,
  brandAssets: getAssets(environmentConfig),
  getBrandThemes: () => getThemeStyles(environmentConfig),
}).then(stateStore => {
  // optional: inject listeners on the resolved store
})
```

> Note: the parameters are `moduleMap`, `serviceMap`, `routeMap` — **not** `appModule`, `appService`, `appRoutes`.

## DSC components & theming

```typescript
import { Button, Typography, Box, TextField, Alert, Container, Grid, useTheme } from '@byte-storefronts/dsc-web'
import { ShoppingCart } from '@byte-storefronts/dsc-web/Icons'

const MyComponent = () => {
  const { themeTokens } = useTheme()
  return (
    <Container maxWidth="lg">
      <Box sx={{ p: themeTokens.spacing200 }}>
        <Typography variant="h1">Title</Typography>
        <Button variant="contained" startIcon={<ShoppingCart />} aria-label="Add to cart">
          Order Now
        </Button>
        <Alert severity="error">Something went wrong</Alert>
      </Box>
    </Container>
  )
}
```

DSC wraps MUI and exposes far more than the basics above — `Dialog`, `Drawer`, `Card`, `Tabs`, `Menu`, `Accordion`, `Chip`, `Avatar`, `Radio`, `Checkbox`, `Switch`, `Carousel`, `Skeleton`, and brand-specific composites (`OccasionSelector`, `Footer`, …). Check `byte-storefronts/dsc-web/src` for the full list before reaching for raw MUI. Always use `themeTokens.*` for spacing/colors/typography — never hardcode values or use plain CSS/CSS modules.

## Dialogs

Dialogs are rendered centrally by the `Dialogs` component (`byte-storefronts/core-web/src/Dialogs.tsx`), mounted once near the app root. Each dialog is driven by its own feature state/hook (e.g. `useSwapCouponsDialog`, `useCouponWallet` in `@byte-storefronts/core/cart`) rather than a single generic `useDialog({ type })` API. To add a dialog: build it as a component, render it inside `Dialogs`, and control its visibility through its feature hook/selector. Don't manage ad-hoc local modal state for shared dialogs.

## Performance

```typescript
// Code-split heavy components
const HeavyComponent = lazy(() => import('./HeavyComponent'))
<Suspense fallback={<MyScreenSkeleton />}><HeavyComponent /></Suspense>

// Memoize expensive derived data
const sorted = useMemo(() => [...items].sort((a, b) => a.price - b.price), [items])
export const MyList = memo(({ items }) => <List items={items} />)
```

## Testing

### Components & modules

```typescript
import { render, screen, fireEvent } from '@testing-library/react'

describe('MyModule', () => {
  it('renders title', () => {
    render(<MyModule title="Hello" onAction={jest.fn()} />)
    expect(screen.getByText('Hello')).toBeInTheDocument()
  })

  it('calls onAction on button click', () => {
    const onAction = jest.fn()
    render(<MyModule title="Hello" onAction={onAction} />)
    fireEvent.click(screen.getByTestId('my-module-btn'))
    expect(onAction).toHaveBeenCalled()
  })
})
```

### Hooks

```typescript
import { renderHook, act } from '@testing-library/react'

describe('useMyHook', () => {
  it('returns initial state', () => {
    const { result } = renderHook(() => useMyHook())
    expect(result.current.isLoading).toBe(false)
  })

  it('updates after action', () => {
    const { result } = renderHook(() => useMyHook())
    act(() => { result.current.doSomething() })
    expect(result.current.value).toBe(1)
  })
})
```

### Run tests

Scope jest to the spec files you changed — never to a whole package:

```bash
cd byte-storefronts/core-web && pnpm exec jest --coverage=false --maxWorkers=2 \
  src/path/to/MyModule.spec.tsx

# Fuzzy match on the file path instead of naming it:
cd byte-storefronts/core-web-modules && pnpm exec jest --coverage=false --maxWorkers=2 \
  --testPathPattern="MyModule"
```

Never run `pnpm --filter <pkg> test` or `turbo run test`. A bare package run
loads every spec file in the package (core-web is 553, core is 1433) across 11
default workers, and `turbo run test` parallelises that across packages — enough
to take the machine down.

`--testPathPattern` is safe because it filters at file-discovery time. `-t` /
`--testNamePattern` is **not**: it filters tests *within* suites, so jest still
loads and executes every spec file to enumerate test names. Always pass
`--maxWorkers` explicitly — the repo configures none.

### E2E (Cypress)

```bash
pnpm --filter @byte-helium/kfc-au-web-app-e2e e2e:ci
```

Always add `data-testid` on interactive elements so Cypress can target them reliably. (E2E can be left to CI.)

## Accessibility checklist

```typescript
// Icon-only buttons need aria-label
<Button aria-label="Add pizza to cart"><ShoppingCart /></Button>

// Form fields need id + label association
<TextField id="email-input" label="Email Address" aria-describedby="email-hint" required />

// Landmark regions need labels
<nav aria-label="Main navigation">{/* ... */}</nav>
```

## Common pitfalls

- Using the `@phdv/*` scope — it doesn't exist; everything is `@byte-storefronts/*` (`dsc-web`, `core-web`, `core-web-modules`, …)
- Passing `appModule` / `appService` / `appRoutes` to `initApp` — the real keys are `moduleMap` / `serviceMap` / `routeMap`
- Reaching for a `useDialog` hook or `MarketRoute` / `ProtectedRoute` / `Template` component — none exist (see Dialogs / Routing / Screens)
- Creating a module without a type in `@byte-storefronts/types` first
- Using raw MUI components directly instead of `@byte-storefronts/dsc-web` wrappers
- Hardcoding colors or spacing instead of `themeTokens.*`
- Using CSS modules or external stylesheets (use `sx` prop or `styled()`)
- Accessing `window` / `document` in shared utilities without a `typeof window !== 'undefined'` guard
- Building a screen without a paired loading skeleton
- Forgetting `data-testid` on interactive elements
- Creating brand- or market-specific logic inside a core module (it belongs in `brand-kfc`/`brand-tb` or the app)
- Building a one-brand feature inside `core-web*` instead of `brand-kfc`/`brand-tb`
