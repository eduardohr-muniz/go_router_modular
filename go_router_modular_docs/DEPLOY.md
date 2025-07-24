# 🚀 Deploy para GitHub Pages

Este guia explica como fazer o deploy da documentação do GoRouter Modular para o GitHub Pages.

## 📋 Pré-requisitos

1. **Repositório no GitHub** com permissões de administrador
2. **GitHub Actions** habilitado no repositório
3. **GitHub Pages** configurado

## ⚙️ Configuração

### 1. Habilitar GitHub Pages

1. Vá para **Settings** > **Pages** no seu repositório
2. Em **Source**, selecione **GitHub Actions**
3. Clique em **Save**

### 2. Configurar GitHub Actions

O workflow já está configurado em `.github/workflows/deploy.yml` e será executado automaticamente quando você fizer push para a branch `main`.

### 3. Configuração do Docusaurus

O `docusaurus.config.ts` já está configurado com:

```typescript
url: 'https://eduardohr-muniz.github.io',
baseUrl: '/go_router_modular/',
```

## 🚀 Deploy Automático

### Para fazer deploy:

1. **Commit e push** para a branch `main`:
```bash
git add .
git commit -m "feat: update documentation"
git push origin main
```

2. **Verificar o deploy**:
   - Vá para **Actions** no GitHub
   - Monitore o workflow "Deploy to GitHub Pages"
   - Aguarde a conclusão do build

3. **Acessar a documentação**:
   - URL: `https://eduardohr-muniz.github.io/go_router_modular/`
   - O deploy pode levar alguns minutos

## 🔧 Desenvolvimento Local

### Iniciar servidor de desenvolvimento:
```bash
npm run docs:dev
```

### Build local:
```bash
npm run docs:build
```

### Servir build local:
```bash
npm run docs:serve
```

## 📝 Estrutura de URLs

- **Homepage**: `https://eduardohr-muniz.github.io/go_router_modular/`
- **Documentação**: `https://eduardohr-muniz.github.io/go_router_modular/docs/`
- **Blog**: `https://eduardohr-muniz.github.io/go_router_modular/blog/`

## 🐛 Troubleshooting

### Problemas comuns:

1. **Build falha**: Verifique os logs no GitHub Actions
2. **Links quebrados**: Use `onBrokenLinks: 'warn'` para desenvolvimento
3. **Cache**: Limpe o cache do navegador se necessário

### Logs úteis:
- GitHub Actions: `https://github.com/eduardohr-muniz/go_router_modular/actions`
- GitHub Pages: `https://github.com/eduardohr-muniz/go_router_modular/settings/pages`

## 📚 Recursos

- [Docusaurus Deploy Guide](https://docusaurus.io/docs/deployment)
- [GitHub Pages](https://pages.github.com/)
- [GitHub Actions](https://github.com/features/actions) 