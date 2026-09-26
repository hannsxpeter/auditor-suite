# DS: Design System Consistency and Theming

Weight 9. Always active.
Owns: whether the UI is built from one source of truth: tokens and scales used instead of literals, shared primitives reused instead of copied, theme and dark-mode wiring, and tokens that reach inside shadow DOM.
Not here: cascade and specificity mechanics (STYLE); the contrast of a token pair (A11Y-R11); visual hierarchy and which action looks primary (uxauditor).
Standards: W3C Design Tokens Community Group format (for token files), the project's own design-system docs.
Read first: the token source (`tokens.json`, `theme.ts`, CSS custom properties, `tailwind.config`), the theme provider, and the primitive components.
Calibrate to the styling model: Tailwind utilities from the configured scale are tokens; a literal is a finding only where a token or a scale exists for it.

## Cards

### DS-R1 Hardcoded or off-scale value where a token exists
- Leads: `scan.sh DS-R1` lists hex, rgb, and hsl literals and arbitrary Tailwind values (`text-[#3a3a3a]`, `w-[327px]`).
- Confirm: a color, spacing, radius, shadow, or font size is a literal in a component while the token source defines a token for it (often the very same value); or the value is off the defined scale (`p-[13px]`, `margin: 7px`).
- Not a finding if: the literal is in the token source itself; no token exists for it and it is used once (note the missing token instead); it belongs to an illustration or chart palette documented as separate.
- Severity: Medium when load-bearing components bypass a declared token (theme changes and dark mode miss them); Low for isolated literals.
- Fix: replace the literal with the token (`bg-brand-600`, `var(--color-brand-600)`, `theme.colors.brand[600]`); add a token when a value repeats.
- Verify the fix: `scan.sh DS-R1` lists literals only in the token source.
- Refs: W3C Design Tokens format; the project's token source

### DS-R2 A primitive re-implemented or restyled per use
- Leads: `scan.sh DS-R2` lists component definitions named like primitives (Button, Card, Input, Select, Modal, Badge).
- Confirm: a hand-rolled button, input, or modal exists beside the design system's primitive; several near-identical variants exist (PrimaryButton, BlueButton, ButtonNew, CardV2); the library `Button` is imported and restyled inline at each call site.
- Not a finding if: the local component wraps the primitive and adds behavior (a submit button with a pending state).
- Severity: Medium when a load-bearing flow uses a copy that lacks the primitive's states (disabled, loading, focus); Low otherwise.
- Fix: replace the copies with the primitive and add a variant to it for the missing case.
- Verify the fix: the copies are deleted and every call site imports the primitive.
- Refs: the project's design-system docs

### DS-R3 Theme or dark mode wired only partly
- Leads: `scan.sh DS-R3` lists dark-mode selectors and utilities, `prefers-color-scheme`, `color-scheme`, and theme providers.
- Confirm: a dark theme ships but components use literal colors that do not swap; tokens are not overridden in the dark theme; `color-scheme` is not set, so form controls and scrollbars stay light in dark mode; a subtree renders outside the theme (a portal mounted outside the provider, a second React root, an iframe).
- Not a finding if: the app ships one theme only.
- Severity: High when a shipped theme leaves load-bearing text or controls unreadable (dark text on a dark background); Medium when parts stay in the wrong theme.
- Fix: define every semantic color as a token with a value per theme; set `color-scheme` per theme; mount portals inside the provider.
- Verify the fix: switch the theme on each load-bearing view: every surface and control swaps.
- Refs: CSS Color Adjustment (`color-scheme`); WCAG 1.4.3 for the unreadable case

### DS-R4 Tokens that do not reach inside shadow DOM
- Leads: `scan.sh DS-R4` lists `attachShadow`, `customElements.define`, `LitElement`, `:host`, `::part`, and `adoptedStyleSheets`.
- Confirm: a custom element with a shadow root is styled with document-level classes or utilities (they do not apply inside a shadow root), or its shadow stylesheet defines tokens on `:root` (which matches nothing inside a shadow tree), so the component renders its defaults instead of the theme.
- Not a finding if: tokens are CSS custom properties set on `:root` or on an ancestor of the host and read with `var()` inside the component: custom properties inherit through the shadow boundary.
- Severity: Medium when components ignore the brand or the theme switch; Low otherwise.
- Fix: read tokens with `var(--token, fallback)`, define component defaults on `:host`, and expose `::part()` for theming.
- Verify the fix: switching the theme changes the component's colors.
- Refs: CSS Scoping (`:host`, `::part`); MDN Using shadow DOM

### DS-R5 Two token sources that disagree
- Leads: `scan.sh DS-R5` lists token definitions (CSS custom properties, `colors:` and `palette:` objects, theme builders).
- Confirm: the same token is defined in two places with different values (a `tokens.css` and a `tailwind.config.js`, a design-tool export and a `theme.ts`), or components read from both, so the UI shows two versions of the brand.
- Not a finding if: a build step generates one source from the other (read the script).
- Severity: Medium when load-bearing components read the divergent copy; Low otherwise.
- Fix: keep one source and generate the others from it (Style Dictionary, or a Tailwind config that reads the CSS variables).
- Verify the fix: each token value is defined once; the other files import or generate it.
- Refs: W3C Design Tokens format

## Also check
- Breakpoints, spacing, or radius values that differ across surfaces for the same purpose.
- Variant sprawl: five near-identical card components (file under DS-R2).

## Paper controls (look protective, protect nothing)
- A `tokens.json`, `theme.ts`, or `:root` token set declared while components hardcode the same literal beside it.
- A dark-theme class toggled while half the colors are hardcoded, so dark mode is half broken.
- A design-system `Button` imported but restyled inline at every use.
