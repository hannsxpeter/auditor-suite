import { defineConfig } from 'astro/config'
import sitemap from '@astrojs/sitemap'

export default defineConfig({
  site: 'https://www.tidewaterbikes.example',
  integrations: [sitemap()],
  build: {
    inlineStylesheets: 'never',
  },
})
