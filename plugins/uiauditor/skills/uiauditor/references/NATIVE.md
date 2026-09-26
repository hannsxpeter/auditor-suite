# NATIVE: Native and Cross-Platform UI Implementation

Weight 9. Active when React Native, Expo, react-native-web, or another native-mobile UI toolkit is used.
Owns: what only native and cross-platform UI has: text and primitive rules that crash or misrender, web assumptions in native styles (and native-only code in the web build), list virtualization, safe areas and the keyboard, platform differences, back navigation, and touch target sizes.
Not here: accessibility props (`accessibilityLabel`, `accessibilityRole`, `accessibilityState`, announcements): the A11Y cards cover them, so a native lockout reaches the accessibility floor. Semantic HTML (SEM) and web CSS (STYLE) do not apply to native screens.
Standards: React Native docs, Apple Human Interface Guidelines (44x44 pt targets), Android accessibility guidance (48x48 dp targets).
Read first: the navigation setup, the root layout and safe-area provider, the list screens, and the forms. For Flutter, SwiftUI, or Jetpack Compose, apply the same checks with that toolkit's primitives (`ListView.builder`, `List`, `LazyColumn`; `SafeArea`, `safeAreaInset`, `WindowInsets`).

## Cards

### NATIVE-R1 Raw text or a falsy number rendered outside Text (quick)
- Leads: `scan.sh NATIVE-R1` lists `{count && ...}` and `{items.length && ...}` conditions.
- Confirm: a string or number can render directly inside a `View` rather than a `Text`: `{items.length && <List />}` renders `0` when the list is empty, or a bare `{title}` or literal text sits in a `View`. React Native throws "Text strings must be rendered within a <Text> component" and the screen crashes; react-native-web renders it, so web tests miss it.
- Not a finding if: the condition is boolean (`items.length > 0 &&`, `!!count &&`); the value is inside `<Text>`.
- Severity: Critical when the crash can hit a load-bearing screen (an empty cart, a zero-count badge); High elsewhere.
- Fix: use boolean conditions (`items.length > 0 ? <List /> : null`) and wrap all text in `<Text>`.
- Verify the fix: render the screen with empty data on a simulator: no red-screen error.
- Refs: React Native docs "Text"

### NATIVE-R2 Web assumptions in native code, or native-only code in the web build
- Leads: `scan.sh NATIVE-R2` lists px strings, CSS-only style values, and HTML tags in native code.
- Confirm: styles use web units or values React Native does not support (`'16px'`, `display: 'grid'`, `position: 'fixed'`, hover styles); HTML elements (`div`, `span`) appear in native files; with react-native-web, a native-only module is imported on the web path with no `.web.js` file or `Platform.OS` guard, or a web-only API runs on native.
- Not a finding if: the file is web-only by name (`Component.web.tsx`) or behind a `Platform.OS === 'web'` check.
- Severity: High when a load-bearing screen misrenders or crashes on one target; Medium otherwise.
- Fix: unitless numbers and flexbox in `StyleSheet.create`; platform files (`.ios.tsx`, `.android.tsx`, `.web.tsx`) or `Platform.select` for real differences.
- Verify the fix: the screen renders on iOS, Android, and web (when targeted) with no warnings.
- Refs: React Native docs "Style" and "Platform-specific code"

### NATIVE-R3 Long list rendered without virtualization
- Leads: `scan.sh NATIVE-R3` lists `ScrollView` uses and `keyExtractor` functions.
- Confirm: a list that can hold many rows is rendered with `.map()` inside a `ScrollView`; a `FlatList` returns the index from `keyExtractor`; a `FlatList` or `SectionList` sits inside a `ScrollView` with the same orientation (virtualization stops working).
- Not a finding if: the list is short by construction (say how you know).
- Severity: High when a load-bearing screen can list hundreds of rows (memory use, jank, crashes on low-end Android); Medium otherwise.
- Fix: `FlatList`, `SectionList`, or `FlashList` with a stable `keyExtractor={item => item.id}`; move headers into `ListHeaderComponent` instead of an outer `ScrollView`.
- Verify the fix: the list is virtualized and keyed by id; scrolling a 1,000-row fixture stays smooth.
- Refs: React Native docs "FlatList" and "Optimizing FlatList Configuration"

### NATIVE-R4 Content under notches, system bars, or the keyboard
- Leads: `scan.sh NATIVE-R4` lists safe-area APIs, hardcoded status-bar offsets, keyboard avoidance, and platform branches.
- Confirm: fixed offsets (`paddingTop: 44`) stand in for safe-area insets; React Native's built-in `SafeAreaView` is relied on for Android (it applies only on iOS); a form's inputs or submit button sit under the on-screen keyboard with no `KeyboardAvoidingView` or keyboard-aware scroll view (its `behavior` must differ by platform: `padding` on iOS, `height` or none on Android).
- Not a finding if: `react-native-safe-area-context` or the navigation library applies the insets to the screen.
- Severity: High when controls of a load-bearing screen sit under the notch, the home indicator, or the keyboard; Medium otherwise.
- Fix: `useSafeAreaInsets()` from `react-native-safe-area-context`; `KeyboardAvoidingView` with platform-specific behavior around forms.
- Verify the fix: on a notched iOS simulator and an Android emulator with the keyboard open, every control stays visible.
- Refs: React Native docs "SafeAreaView" and "KeyboardAvoidingView"

### NATIVE-R5 Back navigation blocked, or touch targets too small (quick)
- Leads: `scan.sh NATIVE-R5` lists `BackHandler`, `beforeRemove`, `gestureEnabled: false`, responder and pan handlers, and `hitSlop`.
- Confirm: a `BackHandler` listener returns `true` without navigating, `gestureEnabled: false` turns off the iOS swipe back, or a pan gesture captures the screen edge, so the user cannot leave the screen; or touch targets are under 44x44 pt (iOS) or 48x48 dp (Android) with no `hitSlop`.
- Not a finding if: the block is a confirm-before-leaving prompt that offers a way out; the screen keeps a visible close or back control.
- Severity: Critical when a screen on a load-bearing flow leaves no way out (system back blocked and no visible close or back control); High when system back or swipe back is blocked but a visible control remains; Medium for undersized targets on load-bearing controls; Low otherwise.
- Fix: return `false` from `BackHandler` unless a confirm dialog handles the event; keep swipe back; add `hitSlop` or padding to reach 44 pt or 48 dp.
- Verify the fix: press system back on Android and swipe from the edge on iOS on each screen: both leave it; target boxes measure at least 44 pt or 48 dp.
- Refs: Apple Human Interface Guidelines (hit targets); Android accessibility guidance (touch target size); React Native docs "BackHandler"

## Also check
- Hover and cursor styles in native code, which never fire on touch (file under NATIVE-R2).
- Images without explicit `width` and `height` in native styles, which render at zero size for remote sources.

## Paper controls (look protective, protect nothing)
- A `TouchableOpacity` wrapping a `View` with no `accessibilityRole` or label (file under A11Y-R2).
- A `.map()` rendering hundreds of rows inside a `ScrollView`.
- A hardcoded status-bar offset instead of safe-area insets.
- A hover style that is dead on touch.
