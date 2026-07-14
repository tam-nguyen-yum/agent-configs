---
name: react-native
description: Guides development of React Native / Expo screens, components, modules, navigation, and tests in this byte-helium monorepo. Use whenever working in libs/native-*, apps/expo-app-*, or when the user mentions React Native, Expo, mobile screens, or native modules.
---

# React Native — byte-helium

## Package scope (read first)

Every internal import uses the **`@byte-storefronts/*`** scope — there is no `@phdv/*`. The aliases are defined in `tsconfig.base.json`. The ones you'll use most:

| Alias | Maps to | Holds |
|-------|---------|-------|
| `@byte-storefronts/types` | `libs/types/src` | All prop & domain types |
| `@byte-storefronts/core` (+ subpaths `/menu`, `/cart`, `/globalState`, …) | `libs/core/src` | Cross-platform state, selectors, domain hooks |
| `@byte-storefronts/core-native` (+ `/shared`, `/modules`, `/routing`, `/blueprint`, `/globalState`, `/tracking`) | `libs/native-core-framework/src` | Screens, navigation, hooks, framework bootstrap |
| `@byte-storefronts/core-native-modules` | `libs/native-core-modules/src` | Default modules + `getModule()` |
| `@byte-storefronts/dsc-native` | `libs/dsc-react-native/src` | Design-system components, `useTheme`, theme types |

## Key paths

| What | Where |
|------|-------|
| Core modules (default UI) | `libs/native-core-modules/src/modules/` |
| Framework (screens, nav, hooks) | `libs/native-core-framework/src/` |
| Design system components | `@byte-storefronts/dsc-native` |
| Market overrides | `apps/expo-app-[market]/src/modules/` |
| Module prop types | `libs/types/src/modules/` |

Markets present under `apps/`: `expo-app-uk`, `expo-app-ca`, `expo-app-fr`, `expo-app-jp`, `expo-app-mx`, `expo-app-pr`, `expo-app-kw`, `expo-app-kfc-au`, `expo-app-tb-uk`, plus `expo-app-template`.

## Non-negotiables

- **Use DSC for UI components** (`@byte-storefronts/dsc-native`) — `Text`, `Button`, `Surface`, `Card`, `TextInput`, etc. must come from DSC, not raw RN. Layout/interaction primitives (`View`, `TouchableOpacity`, `ScrollView`, `StyleSheet`) are fine from `react-native` directly.
- **Unit tests mandatory** for all logic; view-only components only need tests if they contain logic
- Must work on both **iOS and Android**
- Module types must live in `@byte-storefronts/types` before implementing the module
- Never import from web libraries — no `@byte-storefronts/dsc-web`, `@byte-storefronts/core-web`, etc.

## Creating a native module

### 1. Define the type in `libs/types`

```typescript
// libs/types/src/modules/MyModuleProps.ts
export type MyModuleProps = {
  title: string
  onPress: () => void
}
```

### 2. Implement in `libs/native-core-modules`

```typescript
// libs/native-core-modules/src/modules/MyModule.tsx
import React from 'react'
import { TouchableOpacity } from 'react-native'
import { Surface, Text } from '@byte-storefronts/dsc-native'
import type { MyModuleProps } from '@byte-storefronts/types'

const MyModule: React.FC<MyModuleProps> = ({ title, onPress }) => (
  <TouchableOpacity
    onPress={onPress}
    testID="my-module"
    accessible
    accessibilityLabel={title}
    accessibilityRole="button"
  >
    <Surface>
      <Text variant="bodyLarge">{title}</Text>
    </Surface>
  </TouchableOpacity>
)

export default MyModule
```

### 3. Register it in the module definition

The default module set lives in `libs/native-core-modules/src/index.ts` (an internal `const`, not an exported `defaultModuleDefinition`). Add your module there so `getModule()` can resolve it. Don't import that const directly — go through `getModule()`.

### 4. Market override (only when needed)

Place the override in the market app and register it with `loadModules()` (see step 6). The override keeps the same `MyModuleProps` type:

```typescript
// apps/expo-app-uk/src/modules/MyModule.tsx
import type { MyModuleProps } from '@byte-storefronts/types'

const MyModuleUK: React.FC<MyModuleProps> = ({ title, onPress }) => (
  // UK-specific implementation
)

export default MyModuleUK
```

### 5. Consume via orchestration

Resolve the active implementation (core or market override) with `getModule()`:

```typescript
import { getModule } from '@byte-storefronts/core-native-modules'
import { useStoreSelector } from '@byte-storefronts/core/globalState'

const MyOrchestrator: React.FC = () => {
  const data = useStoreSelector(selectMyData)
  const { MyModule } = getModule()

  return <MyModule title={data.title} onPress={() => {}} />
}
```

### 6. Wire overrides at app startup

Market apps register overrides in their `App.tsx` with `loadModules()` — it shallow-merges over the defaults:

```typescript
// apps/expo-app-uk/src/App.tsx
import { loadModules } from '@byte-storefronts/core-native/modules'
import * as nativeModules from './modules'
import CallToRegister from './modules/CallToRegister'

loadModules({ ...nativeModules, CallToRegister })
```

## Screens

```typescript
// libs/native-core-framework/src/screens/MyScreen.tsx
import Screen from '../shared/components/Screen'
import { useAppNavigation } from '../shared/hooks/useAppNavigation'
import { useTranslation } from 'react-i18next'

export const MyScreen = () => {
  const { t } = useTranslation()
  const navigation = useAppNavigation()

  return (
    <Screen testID="my-screen">
      {/* content */}
    </Screen>
  )
}
```

Always use `useAppNavigation()` (typed) — not the raw `useNavigation()` hook. Inside the framework, import it from `../shared/hooks/useAppNavigation`; from a market app it is re-exported via `@byte-storefronts/core-native/shared`.

## Navigation

```typescript
import { createStackNavigator } from '@react-navigation/stack'

const Stack = createStackNavigator<MyStackParamList>()

export const MyStackNavigator = () => {
  const screenOptions = useStandardScreenOptions()
  return (
    <Stack.Navigator screenOptions={screenOptions}>
      <Stack.Screen name="MyScreen" component={MyScreen} />
    </Stack.Navigator>
  )
}
```

## DSC components & theming

`useTheme` and the theme types come from the package **root**, not a `/theme` subpath:

```typescript
import { Button, Text, Surface, TextInput, Card, useTheme } from '@byte-storefronts/dsc-native'
import type { DSCNativeTheme } from '@byte-storefronts/dsc-native'

const MyComponent = () => {
  const { themeTokens } = useTheme()
  return (
    <Surface style={{ padding: themeTokens.spacing200 }}>
      <Text variant="headlineMedium">Title</Text>
      <Button mode="contained" onPress={() => {}}>Continue</Button>
    </Surface>
  )
}
```

`useTheme()` returns a `DSCNativeTheme` (react-native-paper based) — `themeTokens` is one field alongside `themeName`, `themeVariant`, `themeAssets`, `componentsConfig`, `isRtlLayout`, and the Paper theme props. Always use `themeTokens.*` for spacing (`spacing200`), colors (`colorBackgroundFoundation`, `colorBackgroundPaper`, …), and typography — never hardcode values.

## Styling: platform differences & safe areas

```typescript
import { Platform, StyleSheet } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'

const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 4 },
    android: { elevation: 4 },
  }),
})

const MyScreen = () => {
  const insets = useSafeAreaInsets()
  return <View style={{ paddingTop: insets.top }}>{/* ... */}</View>
}
```

## Images

Always use `expo-image`, not the RN `Image` component:

```typescript
import { Image } from 'expo-image'

<Image source={{ uri }} style={styles.img} contentFit="cover" transition={200} placeholder={blurhash} />
```

## Lists

Use `FlashList` for long lists (not `FlatList`):

```typescript
import { FlashList } from '@shopify/flash-list'

<FlashList
  data={items}
  renderItem={({ item }) => <ItemCard item={item} />}
  estimatedItemSize={100}
  keyExtractor={item => item.id}
/>
```

## Loading & error states

```typescript
import LoadingOverlay from '../shared/components/LoadingOverlay'
import { ErrorBoundary } from 'react-error-boundary'
import ErrorFallback from '../shared/components/ErrorFallback'

const MyScreen = () => {
  const { data, isLoading } = useMyData()
  if (isLoading) return <LoadingOverlay />
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Content data={data} />
    </ErrorBoundary>
  )
}
```

## Bottom sheets

`BottomDrawer` (in `libs/native-core-framework/src/shared/components/`) is a framework wrapper around the DSC `BottomSheet` — prefer it over wiring the raw DSC component yourself:

```typescript
import BottomDrawer from '../shared/components/BottomDrawer'

<BottomDrawer visible={isOpen} onDismiss={() => setOpen(false)} testID="my-sheet">
  <SheetContent />
</BottomDrawer>
```

## Performance

```typescript
// Memoize expensive components
export default React.memo(MyModule, (prev, next) => prev.id === next.id)

// Memoize derived data and callbacks
const processed = useMemo(() => items.map(transform), [items])
const handlePress = useCallback((id: string) => onPress(id), [onPress])
```

## Testing

### Components

```typescript
import { render, fireEvent, waitFor } from '@testing-library/react-native'

describe('MyModule', () => {
  it('renders content', () => {
    const { getByText } = render(<MyModule title="Hello" onPress={jest.fn()} />)
    expect(getByText('Hello')).toBeTruthy()
  })

  it('calls onPress', () => {
    const onPress = jest.fn()
    const { getByTestId } = render(<MyModule title="Hello" onPress={onPress} />)
    fireEvent.press(getByTestId('my-module'))
    expect(onPress).toHaveBeenCalled()
  })

  it('shows content after load', async () => {
    const { getByTestId } = render(<MyScreen />)
    await waitFor(() => expect(getByTestId('content')).toBeTruthy())
  })
})
```

### Hooks

```typescript
import { renderHook, act } from '@testing-library/react-native'

describe('useMyFeature', () => {
  it('returns initial state', () => {
    const { result } = renderHook(() => useMyFeature())
    expect(result.current.isLoading).toBe(false)
  })

  it('updates state on action', async () => {
    const { result } = renderHook(() => useMyFeature())
    await act(async () => { await result.current.doSomething() })
    expect(result.current.data).toBeDefined()
  })
})
```

### Run tests

Scope tests to the library you changed — don't run the whole suite:

```bash
pnpm test:native-core       # native-core-framework
pnpm test:native-modules    # native-core-modules
pnpm test:native-dsc        # dsc-react-native
pnpm test:native-shared     # native-shared
pnpm test:expo              # expo-app-uk (default app suite)
pnpm test:expo:kw           # expo-app-kw

# Target a single file via nx:
pnpm nx test native-core-modules --testPathPattern="MyModule"
```

## Accessibility checklist

Every interactive element needs:

```typescript
<TouchableOpacity
  accessible
  accessibilityRole="button"
  accessibilityLabel="Select delivery location"
  accessibilityHint="Double tap to change your delivery address"
  testID="location-btn"
>
```

## Deep linking

`useBranch` (`libs/native-core-framework/src/linking/hooks/useBranch.ts`) is the Branch.io integration handler — it manages link state, permissions, and routing:

```typescript
import { useBranch } from '../linking/hooks/useBranch'

const MyComponent = () => {
  useBranch((params) => {
    if (params.productId) {
      navigation.navigate('ProductPage', { productId: params.productId })
    }
  })
}
```

## Common pitfalls

- Using the `@phdv/*` scope — it doesn't exist; everything is `@byte-storefronts/*`
- Importing `useTheme` from a `/theme` subpath — it's exported from `@byte-storefronts/dsc-native` root
- Creating a module without a type in `@byte-storefronts/types` first
- Using DSC-available components (`Text`, `Button`, `Card`, `Surface`) from `react-native` instead of `@byte-storefronts/dsc-native`
- Importing the internal module definition directly instead of resolving via `getModule()` / registering with `loadModules()`
- Forgetting safe area insets on screens with custom headers
- Using `useNavigation()` instead of typed `useAppNavigation()`
- Hardcoding pixel dimensions instead of using flex or theme tokens
- Ignoring Android back button / keyboard avoidance
- Using `FlatList` for long lists (use `FlashList` instead)
- Using the RN `Image` component (use `expo-image` instead)
