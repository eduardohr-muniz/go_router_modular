# Deployment

The documentation is a **static export** (`output: 'export'`) deployed to
**GitHub Pages** by `.github/workflows/deploy.yml` on every push to `master`.

## Automatic (GitHub Pages)

The workflow:

1. Checks out the repo and sets up Node 20.
2. Runs `npm ci` in `nextra_docs/`.
3. Builds with the repository `basePath`:
   `GITHUB_ACTIONS=true GITHUB_REPOSITORY=<owner>/<repo> npm run build`.
4. Creates `out/.nojekyll` and publishes `nextra_docs/out` to GitHub Pages.

Nothing else is required — push to `master` and the site updates. Published at
`https://eduardohr-muniz.github.io/go_router_modular`.

## Manual / local

```bash
cd nextra_docs
npm ci
npm run build            # static site in ./out

# Preview the export locally
npx serve out            # (or any static file server)
```

To reproduce the exact GitHub Pages output (with the `/repo` basePath):

```bash
GITHUB_ACTIONS=true GITHUB_REPOSITORY=eduardohr-muniz/go_router_modular npm run build
touch out/.nojekyll
```

## Notes

- The site is bilingual: `/en` and `/pt`, with `/` redirecting to `/en` via
  `public/index.html`.
- Requirements: Node ≥ 20 (Nextra 4 / Next 15).
- Zod is pinned to `4.3.6` through `overrides` in `package.json`; do not bump it
  to `4.4.x` (a regression there breaks Nextra's prop validation).
- Any host that serves a static folder works (Netlify, Cloudflare Pages, Firebase
  Hosting, etc.) — point it at `nextra_docs/out`. For hosts without a `basePath`,
  build without the `GITHUB_ACTIONS` / `GITHUB_REPOSITORY` env vars.
