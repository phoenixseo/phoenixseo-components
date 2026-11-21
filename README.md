# PhoenixSEO Components

The component library for [PhoenixSEO Page Builder](../sdc-page-builder/) — free
components you can browse, look at and download. Not published yet.

Every component on the site comes from the plugin repository: the site reads
`plugin/schemas/<type>/` and turns it into pages, previews and ZIP downloads. Nothing is
maintained twice.

- **Design decisions:** [`docs/specs/2026-11-21_components-site-design.md`](docs/specs/2026-11-21_components-site-design.md)
- **The source of every component:** `../sdc-page-builder/plugin/schemas/`
- **The runtime, i.e. the plugin itself:** `phoenixseo/sdc-page-builder`

## Status

Planning. No build yet. Next step is the export script that renders the shipped components
to static HTML plus a `catalog.json`.
