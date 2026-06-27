# go_router_modular documentation

Documentation site for [`go_router_modular`](https://pub.dev/packages/go_router_modular),
built with [Nextra 4](https://nextra.site) (Next.js App Router) and published to
GitHub Pages as a static export.

## Languages

The docs are bilingual — **English** (`/en`) and **Portuguese** (`/pt`). The site
root (`/`) redirects to `/en`.

Content lives under `content/<locale>/`:

```
content/
  en/...   # English pages (.mdx) + _meta.ts navigation
  pt/...   # Portuguese pages — same file tree as en/
```

Every page must exist in **both** locales with the same relative path, and the
`_meta.ts` files in each locale must list the same keys in the same order
(only the labels differ).

## Develop

```bash
npm install
npm run dev      # http://localhost:3000 (open /en or /pt)
```

## Build (static export)

```bash
npm run build    # outputs the static site to ./out
```

For a GitHub Pages build (applies the repository `basePath`):

```bash
GITHUB_ACTIONS=true GITHUB_REPOSITORY=eduardohr-muniz/go_router_modular npm run build
```

## Architecture notes

- **App Router + `[lang]` segment.** `app/[lang]/layout.tsx` builds the per-locale
  sidebar via `getPageMap('/<lang>')`; `app/[lang]/[[...mdxPath]]/page.tsx` renders
  the MDX and generates static params for every locale + path.
- **i18n via folders, not Nextra's middleware.** Nextra's middleware-based i18n is
  incompatible with `output: 'export'`, so each locale is an ordinary content
  folder. This keeps the `/en` and `/pt` prefixes on every link in the static build.
- **Root redirect.** `public/index.html` does a relative redirect to `en/`, which
  stays correct under the GitHub Pages `basePath`.
- **Zod pinned to `4.3.6`** via `overrides` in `package.json` — Zod `4.4.x` has a
  regression that breaks Nextra's prop validation.

Deployment is automated by `.github/workflows/deploy.yml` on pushes to `master`.
