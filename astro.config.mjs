// @ts-check
import { defineConfig } from 'astro/config';

// Fully static: the catalog is generated data, not a database. Nothing here
// needs a server, and nothing should — the site is a shelf, not an application.
//
// No host has been decided, so the site URL comes from the environment. Set
// SITE_URL before a build that is meant to be published; the fallback keeps
// canonicals honest for a local build instead of pointing at a domain that
// does not serve this site.
export default defineConfig({
  site: process.env.SITE_URL ?? 'http://localhost:4321',
  output: 'static',
  trailingSlash: 'always',
  build: {
    format: 'directory',
    // Small pages, but inlined CSS hides where a style came from.
    inlineStylesheets: 'auto',
  },
});
