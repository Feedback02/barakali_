// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  // Absolute URLs for canonical + og tags. Canonical host is the registered
  // custom domain barakaliapp.com (apex); www + the barakali.pages.dev Pages
  // URL should 301 here (Cloudflare redirect rule) so there's one canonical
  // origin for SEO.
  site: 'https://barakaliapp.com',

  // Inline the (small ~22KB) CSS into each page's <head> instead of a separate
  // linked file, so styles apply on the first paint with no fetch gap (kills the
  // unstyled-content flash on a cold/hard reload).
  build: {
    inlineStylesheets: 'always',
  },

  // Russian is the default and serves from the root (no /ru/ prefix); Uzbek and
  // English serve under /uz/ and /en/. Mirrors the app's ru-default i18n.
  i18n: {
    locales: ['ru', 'uz', 'en'],
    defaultLocale: 'ru',
    routing: {
      prefixDefaultLocale: false,
    },
  },

  vite: {
    plugins: [tailwindcss()],
  },

  integrations: [sitemap()],
});