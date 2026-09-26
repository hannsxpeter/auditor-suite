# Where each stack puts its visibility signals

Read only the sections for the stacks inventory.sh detected, plus "Hosting and edge config" for the host. Each section says where titles, canonicals, robots rules, sitemaps, JSON-LD, share tags, redirects, and 404s live, and how to tell what renders on the server. If the stack is not listed (for example Hexo, whose `_config.yml` sets `url` and whose theme layouts hold the head), find the same things by reading the code. Dated framework and host facts are in facts.md (Frameworks; Hosting).

## Contents

1. Next.js App Router
2. Next.js Pages Router
3. Nuxt
4. Astro
5. SvelteKit
6. Remix and React Router 7
7. Gatsby
8. Angular
9. Plain single-page apps
10. WordPress
11. Hugo
12. Jekyll
13. Eleventy
14. Docusaurus
15. Django
16. Rails
17. Laravel
18. Hosted platforms
19. Hosting and edge config

## 1. Next.js App Router

Detect: an `app/` folder with `layout` and `page` files; `next` in package.json.
- Titles and descriptions: `export const metadata` or `generateMetadata()` in layout and page files; `title.template` (for example `'%s | Site'`) in a layout. A file marked `'use client'` cannot export metadata, so a client page shows its parent's title.
- Canonical: `alternates: { canonical }`, resolved against `metadataBase` in the root layout. With no `metadataBase`, relative values resolve against a default host (facts.md, Frameworks).
- Robots: `robots` in metadata (`{ index, follow, googleBot }`); `app/robots.ts` returning `MetadataRoute.Robots`, or a static `public/robots.txt` (one or the other).
- Sitemap: `app/sitemap.ts` (`MetadataRoute.Sitemap` with `lastModified`, `changeFrequency`, `priority`), `generateSitemaps` to split, or `next-sitemap` after the build.
- JSON-LD: a `<script type="application/ld+json">` rendered by a server component.
- Share tags: `openGraph` and `twitter` in metadata; files named `opengraph-image` and `twitter-image`; `ImageResponse` from `next/og`. Metadata merges shallowly: a page's `openGraph` replaces the parent's whole object.
- Redirects and status: `redirects()` and `headers()` in `next.config` (`permanent: true` sends 308, `false` sends 307); `redirect()` (307) and `permanentRedirect()` (308) from `next/navigation`; `NextResponse.redirect` in middleware (307 by default). `notFound()` renders `not-found` with 404; a page that only prints "not found" answers 200. With `output: 'export'`, config redirects and headers do not run.
- Rendering: server components render to HTML; client components also render on the server on first load. Content is missing from the HTML when it is fetched in `useEffect`, SWR, or React Query on the client, loaded with `dynamic(..., { ssr: false })`, or gated behind a mounted flag. `export const dynamic = 'force-dynamic'` renders on every request.
- Assets and images: bundles under `/_next/static/`; `next/image` lazy-loads unless the LCP image gets `priority`.
- Trailing slash: `trailingSlash` in `next.config` (default false; the other form redirects with 308).

## 2. Next.js Pages Router

Detect: a `pages/` folder with `_app` or `_document`; `next` in package.json.
- Head: `<Head>` from `next/head` in pages or `_app`, or `next-seo` (`<NextSeo>`, `<DefaultSeo>`). Values are output as written: a relative `og:image` or canonical stays relative.
- html lang: `<Html lang>` in `pages/_document`, or set by the built-in `i18n` config.
- Robots and sitemap: `public/robots.txt`; `next-sitemap` (`next-sitemap.config.js` with `siteUrl`, `exclude`, `robotsTxtOptions`); or a `pages/sitemap.xml.js` that writes XML in `getServerSideProps`.
- Redirects and status: `next.config` `redirects()`; `redirect: { destination, permanent }` returned from `getServerSideProps` or `getStaticProps` (308 when permanent, else 307); `return { notFound: true }` answers 404; `pages/404.js` is the 404 page.
- Rendering: `getStaticProps` and `getServerSideProps` put data in the HTML; data fetched in `useEffect` is client-only; `dynamic(() => import(...), { ssr: false })` skips the server.
- i18n: `i18n: { locales, defaultLocale, localeDetection }` in `next.config`; locale detection redirects the root path by Accept-Language (I18N-R4).

## 3. Nuxt

Detect: `nuxt.config.ts`; `nuxt` in package.json.
- Head: `useSeoMeta({ title, description, ogImage, robots })`, `useHead({ link: [{ rel: 'canonical', href }] })`, and `app.head` in `nuxt.config`. The `@nuxtjs/seo` bundle adds sitemap, robots, schema.org, OG image, and link-checker modules driven by `site: { url }`.
- Robots and sitemap: `@nuxtjs/robots` and `@nuxtjs/sitemap`, or `public/robots.txt`. The robots module can block indexing outside production from its site config (verify its environment rules).
- Redirects and status: `routeRules: { '/old': { redirect: { to: '/new', statusCode: 301 } } }`; `navigateTo(path, { redirectCode: 301 })` (302 by default); `sendRedirect(event, url, 301)` in server routes (302 by default); `throw createError({ statusCode: 404, fatal: true })` for missing data, rendered by `error.vue`.
- Rendering: SSR by default. `ssr: false` in `nuxt.config` makes the whole app client-only; `routeRules` with `ssr: false` does it per route; `<ClientOnly>` skips the server; `useFetch` and `useAsyncData` run on the server, while `$fetch` inside `onMounted` runs only in the browser.
- Assets: bundles under `/_nuxt/`.

## 4. Astro

Detect: `astro.config.*`; `astro` in package.json.
- Head: written by hand in layouts (`<title>`, `<meta>`, `<link rel="canonical">`). `Astro.site` comes from `site` in `astro.config`; build absolute URLs with `new URL(Astro.url.pathname, Astro.site)`. Without `site`, absolute URLs and `@astrojs/sitemap` do not work.
- Sitemap and robots: `@astrojs/sitemap` (needs `site`; options `filter`, `serialize`, `changefreq`, `priority`, and `lastmod`, where one `lastmod` date applies to every URL); `public/robots.txt` or `src/pages/robots.txt.ts`.
- Redirects and status: `redirects` in `astro.config` (a static build without an adapter emits HTML pages with a meta refresh, not HTTP redirects); `Astro.redirect(path, status)` in server routes (302 by default); `src/pages/404.astro`; in server output set `Astro.response.status = 404` or return a 404 `Response`.
- Rendering: static HTML by default; `output: 'server'` or `export const prerender = false` renders on the server. Islands with `client:load`, `client:idle`, or `client:visible` render on the server and then hydrate; `client:only` skips the server, so that content is missing from the HTML.
- Assets: bundles under `/_astro/` (`build.assets`).
- Trailing slash: `trailingSlash` (`'always'`, `'never'`, `'ignore'`) together with `build.format` (`'directory'` or `'file'`).

## 5. SvelteKit

Detect: `svelte.config.js` and `src/routes/`; `@sveltejs/kit` in package.json.
- Head: `<svelte:head>` in `+page.svelte` and `+layout.svelte` (rendered on the server when SSR is on).
- Rendering options in `+page.js`, `+layout.js`, or their `.server` forms: `export const ssr = false` (client-only), `export const prerender = true`, `export const csr = false`. `adapter-static` with a `fallback` page makes an SPA.
- Redirects and status: `redirect(301, '/new')` from `@sveltejs/kit` in `load` or hooks (always pass the status); `error(404, 'Not found')` in `load` renders `+error.svelte` with 404; `handle` in `hooks.server.js` sets headers.
- Sitemap and robots: `src/routes/sitemap.xml/+server.js` returning XML; `static/robots.txt`.
- Assets: bundles under `/_app/immutable/`.
- Trailing slash: `export const trailingSlash = 'always' | 'never' | 'ignore'`.

## 6. Remix and React Router 7

Detect: `app/root.tsx` with `app/routes/`; `@remix-run/*`, or `react-router` with `react-router.config.ts`.
- Head: `export const meta` per route returns `[{ title }, { name: 'description', content }, { tagName: 'link', rel: 'canonical', href }]`. A child route's `meta` replaces its parents' meta instead of merging, so root tags vanish on routes that define their own. `links` exports add link tags. React Router 7 with React 19 also allows `<title>` and `<meta>` in components.
- JSON-LD: a script tag in the route component, or `{ 'script:ld+json': {...} }` in `meta`.
- Redirects and status: `redirect(url, 301)` from a loader (302 by default); `throw new Response('Not Found', { status: 404 })` or `data(null, { status: 404 })` for missing data; a splat route (`$.tsx`) is the catch-all.
- Robots and sitemap: resource routes (`app/routes/robots[.]txt.ts`, `sitemap[.]xml.ts`) or `public/robots.txt`.
- Rendering: loaders run on the server; a route with only a `clientLoader`, or SPA mode (`ssr: false` in `react-router.config.ts`), renders in the browser unless prerendered.

## 7. Gatsby

Detect: `gatsby-config.*`; `gatsby` in package.json.
- Head: the Head API (`export const Head = () => (<><title>...</title></>)`), or `react-helmet` with `gatsby-plugin-react-helmet` (rendered at build, so it reaches the HTML).
- Sitemap and robots: `gatsby-plugin-sitemap` (needs `siteMetadata.siteUrl`); `gatsby-plugin-robots-txt`, whose `env` option picks a policy by `GATSBY_ACTIVE_ENV` or `NODE_ENV` (check which one production builds set).
- Redirects: `createRedirect({ fromPath, toPath, isPermanent })` in `gatsby-node` makes HTTP redirects only with a host adapter or plugin; otherwise it is a client-side redirect.
- Rendering: static HTML at build; DSG and SSR (`getServerData`) are optional; client-only routes (`matchPath`) render in the browser.
- 404: `src/pages/404.js`; the host must serve it with a 404 status.

## 8. Angular

Detect: `angular.json`; `@angular/core` in package.json.
- Head: the `Title` and `Meta` services (`title.setTitle()`, `meta.updateTag()`); canonical links added through the `DOCUMENT` token. These run only in the browser unless the app renders on the server or prerenders.
- Rendering: without `@angular/ssr` (Angular 17 and later; formerly Angular Universal) or prerendering, `index.html` holds an empty `<app-root>`. With it, read `angular.json` (`ssr`, `prerender`, `outputMode`) and the server routes config (`app.routes.server.ts` with `RenderMode.Server`, `RenderMode.Prerender`, or `RenderMode.Client`).
- Redirects and status: `redirectTo` in routes is a client-side redirect; the wildcard route `{ path: '**' }` answers 200 unless the server sets 404 (a `status: 404` server route in newer versions; verify for the version in use).
- Robots and sitemap: files listed in the `assets` array of `angular.json` (for example `src/robots.txt`).

## 9. Plain single-page apps (React, Vue, Vite, Create React App)

Detect: an `index.html` with `<div id="root">` or `<div id="app">`, `createRoot` or `createApp(...).mount`, and no SSR framework.
- Head: `react-helmet`, `react-helmet-async`, `@unhead/vue` (formerly `@vueuse/head`), and `vue-meta` run in the browser only, unless a prerender or SSR step exists.
- Routing: `BrowserRouter`, `createBrowserRouter`, and `createWebHistory` give real URLs; `HashRouter` and `createWebHashHistory` give `#/` URLs that crawlers treat as one page.
- 404: hosts rewrite every path to `index.html` with 200 (see section 19), so unknown routes are soft 404s (RENDER-R5).
- Robots and sitemap: static files in `public/`, often hand-written and stale.
- The durable fix for content pages is prerendering or SSR (for example Vike or vite-ssg, or a move to a framework).

## 10. WordPress

Detect: `wp-content/`, `wp-config.php`, or theme files (`functions.php`, `header.php`, a `style.css` with `Theme Name`).
- SEO layer: usually a plugin (Yoast `wordpress-seo`, Rank Math `seo-by-rank-math`, All in One SEO `all-in-one-seo-pack`) that outputs title, description, canonical, robots, share tags, JSON-LD, and sitemaps. Its settings live in the database: mark them coverage-limited.
- Core: `add_theme_support( 'title-tag' )` for titles; `rel_canonical` on single posts and pages; the `wp_robots` filter (5.7 and later) for robots meta; core sitemaps at `/wp-sitemap.xml` (5.5 and later; most SEO plugins replace them); a virtual robots.txt unless a physical `robots.txt` sits in the web root.
- Search visibility: Settings, Reading, "Discourage search engines" sets `blog_public` to 0, which prints a noindex robots meta on every page. Look for `blog_public` in config, deploy scripts, and database dumps (CRAWL-R1).
- Themes: a hardcoded `<title>` or canonical in `header.php` duplicates the plugin's tags (CANON-R3).
- Redirects: `.htaccess`, plugin redirect tables (database), and `wp_redirect()` or `wp_safe_redirect()` (302 by default).
- Headless WordPress: audit the frontend's stack instead.

## 11. Hugo

Detect: `hugo.toml`, `hugo.yaml`, or `config.toml` with `baseURL`; `layouts/` and `content/`.
- Base URL: `baseURL` drives `.Permalink` and `absURL`; `baseURL = "/"` or a wrong host makes canonicals, share URLs, and sitemap `<loc>` values relative or wrong (CANON-R2).
- Head: `layouts/_default/baseof.html` and `layouts/partials/head.html`; embedded templates for Open Graph, X cards, and schema (`_internal/opengraph.html` in older versions, `partial "opengraph.html"` in newer ones; verify).
- Canonical: `<link rel="canonical" href="{{ .Permalink }}">`, absolute when `baseURL` is right.
- Robots and sitemap: `enableRobotsTXT = true` with `layouts/robots.txt`; the built-in sitemap uses `.Lastmod` (front matter `lastmod`, or git dates with `enableGitInfo`); `[sitemap]` config sets changefreq and priority.
- Redirects: front matter `aliases` generate pages with a meta refresh, not HTTP redirects; real redirects need host config.
- Multilingual: `.Translations` and `.AllTranslations` feed hreflang.
- 404: `layouts/404.html` builds `404.html`; the host must serve it with a 404 status.

## 12. Jekyll

Detect: `_config.yml` with `url` and `baseurl`, `_layouts/`, and `jekyll` in the Gemfile.
- Head: `jekyll-seo-tag` (`{% seo %}`) outputs title, description, canonical, share tags, and JSON-LD from `_config.yml` and front matter; it needs `url`.
- Sitemap and feed: `jekyll-sitemap` (lastmod from `last_modified_at` or the post date; verify) and `jekyll-feed` (`feed.xml`, with `{% feed_meta %}` for autodiscovery).
- Redirects: `jekyll-redirect-from` (`redirect_from:` in front matter) writes meta-refresh pages, not HTTP redirects; GitHub Pages has no server redirects.
- robots.txt: a `robots.txt` at the root (it can use Liquid when it has front matter).
- 404: `404.html` (GitHub Pages serves it with a 404 status).

## 13. Eleventy

Detect: `eleventy.config.*` or `.eleventy.js`; `@11ty/eleventy` in package.json.
- Head: layouts in `_includes/` (Nunjucks, Liquid, and others); the site URL usually in `_data/site.json` or `_data/metadata.js`; canonicals such as `{{ site.url }}{{ page.url }}`.
- Sitemap and robots: templates with `permalink: /sitemap.xml` or `/robots.txt`; check that lastmod uses each item's date, not the build time.
- Feeds: `@11ty/eleventy-plugin-rss`.
- Redirects: host config (`_redirects`, `netlify.toml`) or meta-refresh templates.
- 404: a template with `permalink: 404.html`.

## 14. Docusaurus

Detect: `docusaurus.config.*`; `@docusaurus/core` in package.json.
- Base URL: `url` and `baseUrl` build canonicals and absolute URLs; `trailingSlash` (unset, true, or false) must match the host, or pages redirect.
- Robots: `noIndex: true` in the config puts noindex on every page (a classic production leak; CRAWL-R1); `static/robots.txt`.
- Head: front matter `title`, `description`, `image`, and `slug`; `themeConfig.metadata` for site-wide tags; `themeConfig.image` for the default share image; `<Head>` from `@docusaurus/Head` inside pages.
- Sitemap: `@docusaurus/plugin-sitemap` (in preset-classic; options such as `lastmod`, `changefreq`, `priority`, `ignorePatterns`).
- Redirects: `@docusaurus/plugin-client-redirects` makes client-side redirect pages, not HTTP redirects.
- Rendering: static HTML per page.

## 15. Django

Detect: `manage.py` and `settings.py`; `django` in requirements or pyproject.
- Head: `{% block title %}` and `{% block meta %}` in `base.html`; `django-meta` or hand-written share tags.
- Canonical: `request.build_absolute_uri()` includes the query string (CANON-R4); `request.build_absolute_uri(request.path)` does not.
- Sitemap and feeds: `django.contrib.sitemaps` (`Sitemap` classes with `lastmod()`, `location()`, `protocol = 'https'`, `i18n`, `alternates`, `x_default`); feeds with `django.contrib.syndication`.
- Robots: a template view, `django-robots`, or a static file.
- Redirects and status: `redirect()` and `HttpResponseRedirect` send 302 unless `permanent=True` or `HttpResponsePermanentRedirect` (301); `django.contrib.redirects` stores 301s in the database; `APPEND_SLASH` and `PREPEND_WWW` (CommonMiddleware); `SECURE_SSL_REDIRECT` and `SECURE_HSTS_SECONDS` (SecurityMiddleware); `raise Http404` or `get_object_or_404` for missing data.
- i18n: `i18n_patterns` and `LocaleMiddleware`, which redirects unprefixed URLs by Accept-Language (I18N-R4).
- Rendering: server-side templates; a separate JavaScript frontend needs its own section.

## 16. Rails

Detect: `rails` in the Gemfile, `config/routes.rb`, and `app/views/layouts/`.
- Head: `app/views/layouts/application.html.erb` with `content_for :title`; the `meta-tags` gem (`set_meta_tags`, `display_meta_tags` with `canonical`, `noindex`, `og`).
- Sitemap and robots: `sitemap_generator` (`config/sitemap.rb`, `default_host`, `lastmod: record.updated_at`); `public/robots.txt`.
- Redirects and status: `redirect_to` sends 302 unless `status: :moved_permanently`; a route `redirect('/new')` sends 301; `config.force_ssl = true` redirects to https and sets HSTS; a missing record raises `ActiveRecord::RecordNotFound`, which renders 404 in production (`public/404.html`).
- i18n: `I18n.available_locales`, locale scopes in routes (`scope '(:locale)'`), and detection gems such as `http_accept_language`.
- Rendering: server-rendered; Hotwire and Turbo keep content in the HTML.

## 17. Laravel

Detect: `artisan`, `laravel/framework` in composer.json, and `resources/views/`.
- Head: Blade layouts (`resources/views/layouts/app.blade.php`) with `@yield('title')` and `@stack('meta')`; packages such as `artesaos/seotools` (`SEOMeta::setTitle`, `SEOMeta::setCanonical`, `OpenGraph`, `JsonLd`) or `ralphjsmit/laravel-seo`.
- Canonical: `url()->current()` drops the query string; `url()->full()` and `request()->fullUrl()` keep it (CANON-R4).
- Sitemap and robots: `spatie/laravel-sitemap` (`Url::create(...)->setLastModificationDate(...)`, or `SitemapGenerator`, which crawls the site); `public/robots.txt`.
- Redirects and status: `redirect()` and `Route::redirect` send 302 by default; `Route::permanentRedirect` and `redirect()->to($url, 301)` send 301; `abort(404)` and `findOrFail()` for missing data.
- Rendering: Blade and Livewire render on the server; Inertia.js pages render in the browser unless Inertia SSR is set up (look for an `ssr` entry file and `inertia.ssr` config).

## 18. Hosted platforms (Shopify, Ghost, Wix, Squarespace, Webflow)

- Shopify: Liquid themes (`layout/theme.liquid`, `sections/`, `snippets/`, `templates/*.json`). `{{ canonical_url }}` and `{{ content_for_header }}` come from the platform; robots rules are customized in `templates/robots.txt.liquid`; the sitemap is generated and cannot be edited; product JSON-LD comes from the theme, often via `{{ product | structured_data }}`. Redirects, noindex settings, and apps live in the admin.
- Ghost: Handlebars themes; `{{ghost_head}}` in `default.hbs` outputs canonical, share tags, and JSON-LD, so removing it removes them all; sitemap and robots.txt are generated; redirects live in `redirects.yaml` or `redirects.json` uploaded in the admin; routes in `routes.yaml`.
- Wix, Squarespace, Webflow: templates and SEO settings live in the platform; a repo holds at most custom code (Wix Velo, code embeds).
- For all of them: audit what the repo holds, mark the rest coverage-limited in Scope and limitations, and file no "missing" findings for settings you cannot see.

## 19. Hosting and edge config

- Vercel (`vercel.json`): `redirects` (`permanent: true` sends 308, false 307, or set `statusCode`), `rewrites`, `headers`, `trailingSlash`, `cleanUrls`. Domain redirects (www to apex) live in the dashboard. Preview deployments get a noindex header (facts.md, Hosting).
- Netlify (`netlify.toml`, `_redirects`, `_headers`): redirects default to 301; `status = 200` is a rewrite (the `/* /index.html 200` SPA fallback); `force = true` applies a rule even when a file exists. Deploy previews get a noindex header (facts.md, Hosting).
- Cloudflare Pages (`_redirects`, `_headers`) and Cloudflare dashboard rules: bot and AI-crawler blocking and managed robots.txt settings live outside the repo.
- nginx: `return 301 https://$host$request_uri;`, `rewrite ... permanent;`, and `add_header X-Robots-Tag ...`; `try_files $uri /index.html;` and `error_page 404 =200 /index.html;` create soft 404s.
- Apache (`.htaccess`): `RewriteRule ... [R=301,L]` and `Redirect 301`; `ErrorDocument 404 /404.html` (a full URL there makes Apache redirect instead of answering 404).
- Firebase Hosting (`firebase.json`): `rewrites` to `/index.html` (SPA soft 404s), `redirects` with `type: 301`, `cleanUrls`, `trailingSlash`.
- AWS CloudFront and Amplify: custom error responses that map 403 or 404 to `/index.html` with 200 create soft 404s (look in IaC files).
- GitHub Pages: no server redirects or custom headers; `404.html` is served with a 404 status.
