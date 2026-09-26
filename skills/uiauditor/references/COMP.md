# COMP: Component Implementation and UI State

Weight 13. Always active.
Owns: UI behavior as built in component code: loading, empty, error, and disabled states that exist and are wired; controlled inputs and form submission; list keys; visible rendering artifacts (hydration mismatch, flash, remount); overlays and portals; error boundaries; interactive markup that never hydrates.
Not here: lifecycle bugs with no visible symptom, such as uncleaned subscriptions, missing effect dependencies, or stale closures (codeauditor); whether a view needs an empty state and what it should say (uxauditor); focus inside overlays (A11Y-R5); the cost of client boundaries and hydration directives (PERF-R4); HTML sinks such as `dangerouslySetInnerHTML` or `v-html` (secauditor).
Standards: the framework's component docs (React, Vue, Svelte, Angular, Astro, React Native).
Read first: the data-fetching views of the load-bearing routes, the form components, the list components, and the overlay components.

## Cards

### COMP-R1 Load-bearing form that cannot be completed or loses its input (quick)
- Leads: `scan.sh COMP-R1` lists forms, submit handlers, and inputs with a bound `value`.
- Confirm: a controlled input (`value={x}`) with no `onChange` and no `readOnly`, so typing does nothing; both `value` and `defaultValue` set; a form whose submit handler does not call `event.preventDefault()` in a client-rendered app, so submit reloads the page and loses the input; a submit button outside its form with no `form` attribute; validation state that is set but never rendered.
- Not a finding if: the form is meant to submit natively to a server route (`action="/orders"` with a server handler, Remix `<Form>`, a Next.js server action, a SvelteKit form action, a Rails or Django form); the input is read-only on purpose and looks it.
- Severity: Critical when the form is on a load-bearing flow (sign-up, sign-in, checkout, payment, a primary create form); High on secondary forms.
- Fix: add `onChange` (or switch to an uncontrolled `defaultValue`); call `event.preventDefault()` and submit with fetch; render each validation message next to its field.
- Verify the fix: type into every field and submit: the values stay, the page does not reload, and errors appear.
- Refs: React docs "Controlling an input with a state variable"; HTML form submission

### COMP-R2 A UI state that is declared but never rendered, or only the happy path exists
- Leads: `scan.sh COMP-R2` lists loading and error values taken from hooks and empty catch blocks.
- Confirm: a view reads `isLoading`, `error`, or `status` but renders no branch for it; a `catch` that swallows the error or sets a flag nothing reads; a spinner not tied to a real pending state (it never stops, or never starts); an empty list rendered as a blank area; `disabled` or `selected` styling wired in some instances of a control and missing in others; a mutation button that stays enabled while its request is in flight (double submit).
- Not a finding if: a parent, a Suspense boundary, or an error boundary renders the state (read it); the view cannot be empty by construction.
- Severity: High when a load-bearing view or mutation shows nothing, a stale value, or false success on failure (a failed payment with no error, a blank dashboard); Medium otherwise.
- Fix: render loading, empty, error, and success branches from one state value; disable the submit while pending; set the error state in the catch.
- Verify the fix: force each state (slow network, empty response, 500 response): each renders distinctly.
- Refs: React docs "Conditional rendering"; WCAG 3.3.1 (errors must be shown)

### COMP-R3 Index or unstable keys on a list that changes
- Leads: `scan.sh COMP-R3` lists index keys (`key={index}`, `:key="i"`, Svelte `(i)` keys, a `keyExtractor` that returns the index) and random or time-based keys.
- Confirm: the list can be reordered, filtered, sorted, or have items added or removed, and it is keyed by the index, by a random or time-based value, or not at all (React then warns and falls back to the index).
- Not a finding if: the list is static (never reordered, filtered, or edited while mounted) and its rows hold no state.
- Severity: High when rows hold local state, inputs, focus, or animation (after a removal, the next row shows the removed row's quantity or checked state); Medium when rows are stateless (extra re-renders and flicker). Random keys are High on any list: every render remounts every row and drops input and focus.
- Fix: key by a stable id from the data (`key={item.id}`); create ids when items are created, never during render.
- Verify the fix: edit the second row's state, remove the first row: the edited state stays with its item.
- Refs: React docs "Rendering lists" (keys); Vue docs "Maintaining state with key"

### COMP-R4 Visible rendering artifacts: hydration mismatch, flash, or remount
- Leads: `scan.sh COMP-R4` lists render-time reads of `window`, storage, `Date.now()`, and `Math.random()`, and `suppressHydrationWarning`. Also read for components defined inside other components and `styled()` calls inside render functions.
- Confirm: in a server-rendered app, markup depends on values that differ between server and client (time, random numbers, `window` or `localStorage` read during render), so the page paints one thing and then another; a view renders default content before data resolves and then jumps (a signed-out header flashes for signed-in users); a component type or styled component is created inside a render function, so it remounts on every render and drops input and focus. Cite the symptom the user sees.
- Not a finding if: the value is read in an effect after mount or behind a client-only boundary; the app renders on the client only (no hydration). Effect or subscription bugs with no visible symptom belong to codeauditor.
- Severity: High when the artifact drops user input or focus on a load-bearing form, or a mismatch paints wrong prices, auth state, or content; Medium for a visible flash; Low otherwise.
- Fix: read per-client values in an effect or a client-only component; render a skeleton that matches the final layout; define components and styled components at module level.
- Verify the fix: the dev console shows no hydration warning on the route; typing in the form keeps focus across re-renders.
- Refs: React docs "hydrateRoot" (hydration mismatches); React docs "Preserving and resetting state"

### COMP-R5 Overlay clipped or stacked under other content
- Leads: `scan.sh COMP-R5` lists portals and top-layer APIs; read overlay components and their ancestors for `overflow`, `transform`, and `z-index`.
- Confirm: a modal, menu, dropdown, or tooltip renders inside an ancestor with `overflow: hidden` or `auto` (it is clipped), or with `transform`, `filter`, `perspective`, `contain: paint`, or `will-change: transform` (a `position: fixed` child is then placed against that ancestor, not the viewport), or inside a stacking context that a sibling covers.
- Not a finding if: the overlay renders through a portal (`createPortal`, Vue `<Teleport>`, a library portal) or the top layer (`showModal()`, `popover`).
- Severity: High when a load-bearing overlay or its actions are clipped or hidden so they cannot be used; Medium otherwise.
- Fix: render overlays in a portal at the end of `body`, or in the top layer.
- Verify the fix: open the overlay inside the scrolling or transformed container: it covers the viewport and all its actions show.
- Refs: MDN "position" (fixed positioning and the containing block); MDN Stacking context

### COMP-R6 No error boundary around data-driven views
- Leads: `scan.sh COMP-R6` lists error boundaries and framework error handlers.
- Confirm: a tree of data-driven components has no error boundary (React `componentDidCatch` or `getDerivedStateFromError`, a Next.js `error.tsx` per route segment, a Remix `ErrorBoundary`, Vue `onErrorCaptured`, Svelte `<svelte:boundary>`), so one render error blanks the whole view; or the only boundary is at the root, so a widget failure replaces the whole app.
- Not a finding if: the framework adds a route-level boundary by default (read the version and config); the view has no data-driven or third-party components.
- Severity: High when one widget's render error can blank a load-bearing route; Medium when only a root boundary exists.
- Fix: a boundary per route and around risky widgets, with a fallback that offers retry.
- Verify the fix: make one widget throw during render: only that widget shows the fallback.
- Refs: React docs "Catching rendering errors with an error boundary"

### COMP-R7 Interactive markup that never becomes interactive (quick)
- Leads: `scan.sh COMP-R7` lists framework components used in Astro files, Stimulus `data-controller` names, and `"use client"` boundaries.
- Confirm: an Astro page renders a React, Vue, or Svelte component that has handlers or state but no `client:*` directive (it ships as static HTML and its controls do nothing); a `data-controller` name that no registered Stimulus controller matches; server-rendered markup whose script is never loaded on that page.
- Not a finding if: the component has no handlers or state (static on purpose); a parent island hydrates it.
- Severity: Critical when the dead control is the only way to finish a load-bearing flow (add to cart, checkout, sign-in); High on other load-bearing controls; Medium elsewhere.
- Fix: add the directive (`client:load` in the first view, `client:visible` or `client:idle` below it; PERF-R4 judges the choice) or register the controller.
- Verify the fix: the built page loads the island's script and the control responds.
- Refs: Astro docs "Client directives"; Stimulus docs "Controllers"

## Also check
- A view that keeps showing stale data after a mutation because nothing refetches or updates the cache.
- A list or table whose sort, filter, or pagination controls change the URL or state but not the rendered rows.

## Paper controls (look protective, protect nothing)
- A spinner shown but never tied to a real pending state, so it spins forever or never appears.
- An empty-state component that exists but renders a bare blank area.
- An error toast wired to a `catch` that never sets the state the toast reads.
- `key={index}` on a list with add and remove buttons.
