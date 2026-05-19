---
name: react-native
description: Guides development of React Native / Expo screens, components, modules, navigation, and tests in this dv-commerce monorepo. Use whenever working in libs/native-*, apps/expo-app-*, or when the user mentions React Native, Expo, mobile screens, or native modules.
---

# React Native — dv-commerce

## Key paths

| What | Where |
|------|-------|
| Core modules (default UI) | `libs/native-core-modules/src/modules/` |
| Framework (screens, nav, hooks) | `libs/native-core-framework/src/` |
| Design system components | `@byte-storefronts/dsc-native` |
| Market overrides | `apps/expo-app-[market]/src/modules/` |
| Module prop types | `libs/types/src/modules/` |

## Non-negotiables

- **Use DSC for UI components** (`@byte-storefronts/dsc-native`) — `Text`, `Button`, `Surface`, `Card`, `TextInput`, etc. must come from DSC, not raw RN. Layout/interaction primitives (`View`, `TouchableOpacity`, `ScrollView`, `StyleSheet`) are fine from `react-native` directly.
- **Unit tests mandatory** for all logic; view-only components only need tests if they contain logic
- Must work on both **iOS and Android**
- Module types must live in `@phdv/types` before implementing the module
- Never import from web libraries — no `@phdv/dsc-react-web`, `@phdv/web-core-framework`, etc.

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
import type { MyModuleProps } from '@phdv/types'

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

### 3. Register in `defaultModuleDefinition`

```typescript
// libs/native-core-modules/src/modules/index.tsx
export const defaultModuleDefinition = {
  MyModule,
  // ... existing modules
}
```

### 4. Market override (only when needed)

```typescript
// apps/expo-app-uk/src/modules/MyModule.tsx
import type { MyModuleProps } from '@phdv/types'

const MyModuleUK: React.FC<MyModuleProps> = ({ title, onPress }) => (
  // UK-specific implementation
)

export default MyModuleUK
```

### 5. Consume via orchestration

Use `getModule()` to resolve the correct implementation (core or market override):

```typescript
import { getModule, useStoreSelector } from '@phdv/core'

const MyOrchestrator: React.FC = () => {
  const data = useStoreSelector(selectMyData)
  const { MyModule } = getModule()

  return <MyModule title={data.title} onPress={() => {}} />
}
```

## Screens

```typescript
// libs/native-core-framework/src/screens/MyScreen.tsx
import { Screen } from '../shared/components/Screen'
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

Always use `useAppNavigation()` (typed) — not the raw `useNavigation()` hook.

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

```typescript
import { Button, Text, Surface, TextInput, Card } from '@byte-storefronts/dsc-native'
import { useTheme } from '@byte-storefronts/dsc-native/theme'

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

Always use `themeTokens.*` for spacing, colors, and typography — never hardcode values.

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
import { LoadingOverlay } from '../shared/components/LoadingOverlay'
import { ErrorBoundary } from 'react-error-boundary'
import { ErrorFallback } from '../shared/components/ErrorFallback'

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

```typescript
import { BottomDrawer } from '../shared/components/BottomDrawer'

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

```bash
pnpm test:expo          # all native tests
pnpm test:expo:uk       # UK app specifically
# or via nx:
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

Use the route transform and Branch.io hooks from the framework:

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

- Creating a module without a type in `@phdv/types` first
- Using DSC-available components (`Text`, `Button`, `Card`) from `react-native` instead of `@byte-storefronts/dsc-native`
- Forgetting safe area insets on screens with custom headers
- Using `useNavigation()` instead of typed `useAppNavigation()`
- Hardcoding pixel dimensions instead of using flex or theme tokens
- Ignoring Android back button / keyboard avoidance
- Not testing on both platforms
- Using `FlatList` for long lists (use `FlashList` instead)
- Using the RN `Image` component (use `expo-image` instead)
