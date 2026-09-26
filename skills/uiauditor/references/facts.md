# Dated facts

Last reviewed: 2026-09-26.

Facts that change over time, each with the date it became true and a source to re-check. You cannot open these sources during an audit (no network), so treat them as current as of the review date; when a finding rests on one, say so in Scope and limitations. Maintainers: re-check every source, update the facts, then update the Last reviewed date.

## Accessibility standards and law

- WCAG 2.2 became a W3C Recommendation on 2023-10-05. Success criteria new since 2.1: 2.4.11 Focus Not Obscured (Minimum) AA; 2.4.12 Focus Not Obscured (Enhanced) AAA; 2.4.13 Focus Appearance AAA; 2.5.7 Dragging Movements AA; 2.5.8 Target Size (Minimum) AA; 3.2.6 Consistent Help A; 3.3.7 Redundant Entry A; 3.3.8 Accessible Authentication (Minimum) AA; 3.3.9 Accessible Authentication (Enhanced) AAA. Verify at: https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/
- WCAG 2.2 removed 4.1.1 Parsing as obsolete (since 2023-10-05). Cite 1.3.1 or 4.1.2 for the consequence of broken markup, never 4.1.1. Verify at: https://www.w3.org/TR/WCAG22/
- 3.2.6 Consistent Help and 3.3.7 Redundant Entry are journey-level criteria that uxauditor judges; cite them here only for a code-level defect.
- European Accessibility Act: applies to covered products and services on the EU market from 2025-06-28. Its harmonised standard, EN 301 549 (v3.2.1), maps to WCAG 2.1 AA. Verify at: https://eur-lex.europa.eu/eli/dir/2019/882/oj
- US Section 508 (federal agencies' ICT): the refreshed standards, required from 2018-01-18, incorporate WCAG 2.0 AA. Verify at: https://www.access-board.gov/ict/
- US ADA Title II rule (Department of Justice, published 2024-04-24): web content and mobile apps of state and local governments must meet WCAG 2.1 AA from 2026-04-24 for entities serving 50,000 people or more, and from 2027-04-26 for smaller ones. Check for later amendments. Verify at: https://www.ada.gov/ (the Title II web and mobile rule)

## Core Web Vitals

- INP (Interaction to Next Paint) replaced FID (First Input Delay) as a Core Web Vital on 2024-03-12. Never cite FID. Good values at the 75th percentile of page loads: LCP 2.5 s or less (poor above 4 s), INP 200 ms or less (poor above 500 ms), CLS 0.1 or less (poor above 0.25). Verify at: https://web.dev/articles/vitals

## Browser platform (Baseline)

Baseline means the feature works in current Chrome, Edge, Firefox, and Safari; "widely available" follows 30 months later. Before recommending a feature, compare it with the browsers the project supports (a `browserslist` entry or the README).

- `<dialog>` with `showModal()`: Baseline since 2022-03, widely available since 2024-09. `showModal()` puts the dialog in the top layer with a `::backdrop`, makes the rest of the page inert, and closes on Escape; `show()` does none of that. Verify at: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog
- `:focus-visible`: Baseline since 2022-03; no polyfill is needed. Verify at: https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible
- The `inert` attribute: Baseline since 2023-04. Verify at: https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/inert
- The Popover API (`popover`, `popovertarget`): Baseline since 2024-04, widely available from about 2026-10. Keep a fallback where older browsers must work. Verify at: https://developer.mozilla.org/en-US/docs/Web/API/Popover_API
- Small, large, and dynamic viewport units (`svh`, `lvh`, `dvh`): Baseline since 2022-11. Verify at: https://developer.mozilla.org/en-US/docs/Web/CSS/length
- Size container queries (`@container`, `container-type`): Baseline since 2023-02. Verify at: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries
- `fetchpriority` on images, links, and scripts: Baseline since 2024-10. Verify at: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img

## Frameworks

- Tailwind CSS v4.0 (released 2025-01): `outline-none` now sets `outline-style: none`; the v3 behavior (a transparent 2px outline that stays visible in forced-colors mode) is renamed `outline-hidden`. So `focus:outline-none` with a box-shadow ring shows no focus in forced-colors mode on v4. Read the version in package.json. Verify at: https://tailwindcss.com/docs/upgrade-guide
- Next.js 14 (released 2023-10) moved viewport settings out of `metadata` into a separate `viewport` export (or `generateViewport`); both places can set `maximumScale` and `userScalable`, so check both for A11Y-R4. Verify at: https://nextjs.org/docs/app/api-reference/functions/generate-viewport
