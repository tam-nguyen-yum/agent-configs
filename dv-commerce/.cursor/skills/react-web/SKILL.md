---
name: react-web
description: Guides development of React web screens, components, modules, routing, and tests in this dv-commerce monorepo. Use whenever working in libs/web-*, apps/web-app-*, or when the user mentions web app, web screen, web module, or browser-facing features.
---

# React Web — dv-commerce

> This is plain **React** (not React Native Web). The web and mobile stacks are completely separate.

## Key paths

| What | Where |
|------|-------|
| Core modules (default UI) | `libs/web-core-modules/src/modules/` |
| Framework (screens, routing, hooks) | `libs/web-core-framework/src/` |
| Design system components | `@phdv/dsc-react-web` |
| Market overrides | `apps/web-app-[market]/src/modules/` |
| Module prop types | `libs/types/src/modules/` |
| App bootstrap | `apps/web-app-[market]/src/main.tsx` |

## Non-negotiables

- **Always use DSC components** (`@phdv/dsc-react-web`) — never raw HTML elements or bare MUI components
- **Unit tests mandatory** for all logic; view-only components only need tests if they contain logic
- Module types must live in `@phdv/types` before implementing the module
- Never import from native libraries — no `@byte-storefronts/dsc-native`, `@phdv/native-core-framework`, etc.
- Always add `data-testid` attributes for E2E targeting
- Never hardcode colors or spacing — use `themeTokens.*`
- **SSR-safe code** — guard browser globals: `typeof window !== 'undefined'` before accessing `window` or `document`

## Creating a web module

### 1. Define the type in `libs/types`

```typescript
// libs/types/src/modules/MyModuleProps.ts
export type MyModuleProps = {
  title: string
  onAction: () => void
}
```

### 2. Implement in `libs/web-core-modules`

```typescript
// libs/web-core-modules/src/modules/MyModule.tsx
import { Button, Typography, Box } from '@phdv/dsc-react-web'
import { useTheme } from '@phdv/dsc-react-web/theme'
import type { MyModuleProps } from '@phdv/types'

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

### 3. Register in `defaultModuleDefinition`

```typescript
// libs/web-core-modules/src/modules/index.ts
const defaultModuleDefinition: WebAppModuleDependency = {
  MyModule,
  // ... existing modules
}
```

### 4. Market override (only when needed)

```typescript
// apps/web-app-uk/src/modules/MyModule.tsx
import type { MyModuleProps } from '@phdv/types'

const MyModuleUK: React.FC<MyModuleProps> = ({ title, onAction }) => (
  // UK-specific implementation
)

export default MyModuleUK
```

### 5. Consume in an orchestration component

```typescript
import { getModule, useStoreSelector } from '@phdv/core'

const MyOrchestrator: React.FC = () => {
  const data = useStoreSelector(selectMyData)
  const { MyModule } = getModule()

  return <MyModule title={data.title} onAction={() => {}} />
}
```

## Screens

```typescript
// libs/web-core-framework/src/screens/MyScreen.tsx
import { Template } from '../template'
import { HeadMeta } from '../shared/components/HeadMeta'
import { ErrorBoundary } from 'react-error-boundary'
import { ErrorFallback } from '../shared/components/ErrorFallback'
import { useTranslation } from 'react-i18next'

export const MyScreen = () => {
  const { t } = useTranslation()
  return (
    <>
      <HeadMeta title={t('myScreen.title')} description={t('myScreen.description')} />
      <ErrorBoundary FallbackComponent={ErrorFallback}>
        <Template>
          {/* content */}
        </Template>
      </ErrorBoundary>
    </>
  )
}
```

Always pair a new screen with a **loading skeleton**:

```typescript
// libs/web-core-framework/src/page-skeletons/MyScreenSkeleton.tsx
import { Skeleton } from '@phdv/dsc-react-web'
import { DefaultSkeleton } from './DefaultSkeleton'

export const MyScreenSkeleton = () => (
  <DefaultSkeleton>
    <Skeleton variant="rectangular" height={200} />
    <Skeleton variant="text" />
  </DefaultSkeleton>
)
```

## Routing

```typescript
// Market-specific route
<MarketRoute path="/special-offer" component={SpecialOfferPage} markets={['UK', 'FR']} />

// Protected route (auth required)
<ProtectedRoute path="/account" component={Account} redirectTo="/login" />

// Navigation inside components
import { useNavigate } from 'react-router-dom'
const navigate = useNavigate()
navigate('/menu')
```

Use `useRouteInfo()` for route-aware logic (e.g. hiding elements during checkout):

```typescript
import { useRouteInfo } from '../shared/hooks/useRouteInfo'

const Layout = () => {
  const { isMenuRoute, isCheckoutRoute } = useRouteInfo()
  return isCheckoutRoute ? <MinimalHeader /> : <FullHeader />
}
```

## App bootstrap (adding a market override or route)

The key in `appModule` must match the **core module name** being overridden:

```typescript
// apps/web-app-uk/src/main.tsx
import { initApp } from '@phdv/web-core-framework'
import { config as marketConfig, findEnvironmentConfig } from './config'
import MyModule from './modules/MyModule'

initApp({
  environmentConfig: findEnvironmentConfig(),
  marketConfig,
  appModule: { MyModule },            // key MUST match core module name
  appService: { maps: myMapService },  // service overrides
  appRoutes: [{ path: '/promo', children: <PromoPage /> }],
})
```

## DSC components & theming

```typescript
import { Button, Typography, Box, TextField, Alert, Container, Grid } from '@phdv/dsc-react-web'
import { useTheme } from '@phdv/dsc-react-web/theme'
import { ShoppingCart } from '@phdv/dsc-react-web/Icons'

const MyComponent = () => {
  const { themeTokens } = useTheme()
  return (
    <Container maxWidth="lg">
      <Box sx={{ p: themeTokens.spacing200, backgroundColor: themeTokens.colorSurface }}>
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

Always use `themeTokens.*` for spacing, colors, and typography — never hardcode values or use plain CSS/CSS modules.

## Dialogs

Use the centralized dialog system — do not create ad-hoc modal state:

```typescript
import { useDialog } from '@phdv/core'

const { openDialog } = useDialog()
openDialog({ type: 'CONFIRM_DELETE_ITEM', props: { itemId: '123' } })
```

## Performance

```typescript
// Code-split heavy components
const HeavyComponent = lazy(() => import('./HeavyComponent'))
<Suspense fallback={<MyScreenSkeleton />}><HeavyComponent /></Suspense>

// Memoize expensive derived data
const sorted = useMemo(() => items.sort((a, b) => a.price - b.price), [items])
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

```bash
pnpm test:web:uk          # UK web app
pnpm nx test web-core-modules --testPathPattern="MyModule"
```

### E2E (Cypress)

```bash
pnpm e2e:web:uk
```

Always add `data-testid` on interactive elements so Cypress can target them reliably.

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

- Creating a module without a type in `@phdv/types` first
- Using raw MUI components directly instead of `@phdv/dsc-react-web` wrappers
- Hardcoding colors or spacing instead of `themeTokens.*`
- Using CSS modules or external stylesheets (use `sx` prop or `styled()`)
- Accessing `window` / `document` without SSR guard (`typeof window !== 'undefined'`)
- Building a screen without a paired loading skeleton
- Forgetting `data-testid` on interactive elements
- Creating market-specific logic inside a core module
- Opening dialogs with local state instead of `useDialog()`
