---
type: regex
target:
  source: file
  path: seoaudit.md
pattern: '(?:^|[^/\w.-])(?:\./)?app/sitemap\.ts(:| line | \(line |, line |#L)([5-9]|1[0-4])\b'
---

Finds the sitemap that stamps every URL with the build time at app/sitemap.ts:6 and :9 (CRAWL-R7).
