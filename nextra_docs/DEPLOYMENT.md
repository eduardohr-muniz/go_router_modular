# 🚀 Deployment Guide

Guia para fazer deploy da documentação do GoRouter Modular.

## 📦 Opções de Deploy

### 1. Vercel (Recomendado)

```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel

# Deploy de produção
vercel --prod
```

### 2. Netlify

```bash
# Build local
npm run build

# Deploy no Netlify
# Faça upload da pasta .next para o Netlify
```

### 3. GitHub Pages

```bash
# Configurar para static export
# Adicionar ao next.config.js:
module.exports = withNextra({
  output: 'export',
  trailingSlash: true,
  images: {
    unoptimized: true
  }
})

# Build estático
npm run build

# Deploy na pasta out/
```

### 4. Firebase Hosting

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar projeto
firebase init hosting

# Build
npm run build

# Deploy
firebase deploy
```

## 🌐 URLs Sugeridas

- **Produção**: `https://go-router-modular-docs.vercel.app`
- **Staging**: `https://go-router-modular-docs-staging.vercel.app`
- **GitHub Pages**: `https://eduardohr-muniz.github.io/go_router_modular`

## ⚙️ Configurações de Ambiente

```bash
# .env.local
NEXT_PUBLIC_SITE_URL=https://go-router-modular-docs.vercel.app
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX  # Google Analytics
```

## 🔄 CI/CD

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy Documentation
on:
  push:
    branches: [main]
    paths: ['nextra_docs/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd nextra_docs && npm ci
      - name: Build
        run: cd nextra_docs && npm run build
      - name: Deploy to Vercel
        run: cd nextra_docs && vercel --prod --token ${{ secrets.VERCEL_TOKEN }}
```

## 📊 Analytics

Para adicionar Google Analytics:

```tsx
// theme.config.tsx
head: () => (
  <>
    <script async src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`} />
    <script
      dangerouslySetInnerHTML={{
        __html: `
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '${GA_ID}');
        `,
      }}
    />
  </>
)
```

---

**Recomendação**: Use Vercel para facilidade e performance otimizada.
