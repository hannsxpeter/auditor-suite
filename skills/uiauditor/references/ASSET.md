# ASSET: Assets, Media, Icons and Fonts

Weight 6. Always active.
Owns: the static media as authored or referenced: image format, weight, and responsive sources; the SVG and icon strategy; font files and `@font-face` loading; favicon, app icons, and the web app manifest; broken asset references; embed attributes.
Not here: alt text and captions (A11Y-R10, A11Y-R7); iframe titles (A11Y-R2); missing image dimensions (RESP-R4); a lazy or low-priority LCP image (PERF-R1); bundle weight unrelated to assets (codeauditor).
Standards: HTML responsive images (`srcset`, `sizes`, `<picture>`), CSS Fonts Level 4 (`font-display`), Web App Manifest.
Read first: the image, icon, and font folders (`public/`, `static/`, `src/assets/`), the `@font-face` rules, and the document head. `ls -lS` on the asset folders lists the heaviest files first; it is read-only and allowed.

## Cards

### ASSET-R1 Oversized, legacy-format, or single-size raster images
- Leads: `scan.sh ASSET-R1` lists references to raster files and `srcset` use; `ls -lS` on the image folders lists the heaviest files.
- Confirm: a raster image is much heavier or larger than its rendered size (a 3000px, 2 MB JPEG in a 600px slot); a photo is a PNG or an animation a GIF; one size ships to every screen with no `srcset` and `sizes` or `<picture>`; a remote image URL requests no size or format.
- Not a finding if: an image CDN or framework component resizes and converts on request (`next/image`, an imgix or Cloudinary URL with size parameters).
- Severity: High when an oversized image is in the first view of a load-bearing page (PERF-R1 owns the LCP consequence); Medium elsewhere; Low for small overages.
- Fix: export at 1x and 2x the rendered size in AVIF or WebP with a JPEG fallback, and serve it with `srcset` and `sizes` or `<picture>`.
- Verify the fix: the heaviest first-view image is under about 200 KB at its displayed size.
- Refs: HTML responsive images; web.dev "Serve images in modern formats"

### ASSET-R2 Whole icon sets imported, duplicated inline SVGs, or unoptimized SVG
- Leads: `scan.sh ASSET-R2` lists namespace imports of icon libraries, `library.add(...)` calls, and SVG files with embedded rasters or editor metadata.
- Confirm: an icon library is imported whole (`import * as Icons from 'lucide-react'` with `Icons[name]` lookups, Font Awesome `library.add(fas)`), which defeats tree-shaking; the same inline SVG is pasted into many components; an `.svg` file embeds a base64 PNG or JPEG or carries editor metadata.
- Not a finding if: icons are imported by name from an ESM package (tree-shaken); a sprite or a shared icon component is used.
- Severity: Medium when a full icon set ships in the main bundle; Low for duplication and SVG cruft.
- Fix: import icons by name; move repeated SVGs into one icon component or sprite; optimize SVG files with SVGO; replace raster-in-SVG with a real raster or a true vector.
- Verify the fix: the bundle analyzer shows only the used icons; `scan.sh ASSET-R2` lists no namespace icon imports.
- Refs: MDN SVG; the icon library's tree-shaking docs

### ASSET-R3 Fonts loaded without font-display, preload, or subsetting
- Leads: `scan.sh ASSET-R3` lists `@font-face` rules, font files, Google Fonts links, font preloads, and font packages.
- Confirm: an `@font-face` for body or heading text has no `font-display` (text can stay invisible for up to 3 seconds while it loads); a Google Fonts URL lacks `display=swap`; the critical font is not preloaded, a preload is never used, or a preload lacks `crossorigin` (then the font downloads twice); every weight and style of a family ships where two are used; a single-script site ships no subset.
- Not a finding if: the framework optimizes fonts (`next/font`, `@fontsource` with only the used weights); system fonts are used.
- Severity: Medium when body text is invisible until the font loads on load-bearing pages; Low otherwise.
- Fix: `font-display: swap` (or `optional`), preload the one critical WOFF2 file with `crossorigin`, ship only the used weights, and consider one variable font instead of many static files.
- Verify the fix: each `@font-face` has `font-display`; each font preload has `as="font"`, `type="font/woff2"`, and `crossorigin`.
- Refs: CSS Fonts Level 4 (`font-display`); web.dev "Best practices for fonts"

### ASSET-R4 Broken asset references, favicon, or app icons
- Leads: `scan.sh ASSET-R4` lists icon, apple-touch-icon, and manifest links and manifest icon entries; check each referenced file exists with `ls`.
- Confirm: a `src`, `href`, or `url()` points to a file that does not exist in the repo or the build input; a path differs only in letter case (it works on macOS and fails on Linux servers); the favicon link points to a missing file, or there is none; the manifest is malformed or its icons are missing where installing the app is intended.
- Not a finding if: the file is generated at build time or served from a CDN (cite the config).
- Severity: High when a load-bearing image or the logo is broken; Medium for a missing favicon or manifest icons on a public site; Low otherwise.
- Fix: correct the path and its case; add the favicon set (`favicon.ico`, an SVG icon, a 180px `apple-touch-icon`) and complete manifest icons (192px and 512px).
- Verify the fix: every referenced asset path resolves to a file with matching case.
- Refs: HTML link types (icon); Web App Manifest

## Also check
- Third-party `<iframe>` embeds without `loading="lazy"` below the fold, or without a `sandbox` or `allow` list that limits what the embed may do.
- Fonts from a third-party host add a connection on the critical path: preconnect, or self-host.

## Paper controls (look protective, protect nothing)
- A `logo.svg` that is a 2 MB PNG wrapped in SVG.
- A favicon link to a file that does not exist.
- A font preloaded but never used, or used but not preloaded.
- An icon component that imports the whole set at every call site.
