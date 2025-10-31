# 📋 Guia Passo a Passo: Configuração GitHub Pages com Nextra

Este guia explica como configurar completamente a automação do Nextra no GitHub para fazer deploy automático da documentação.

## 🎯 Pré-requisitos

- Repositório GitHub criado
- Código já commitado no repositório
- Permissões de administrador no repositório (para configurar GitHub Pages)

---

## 📝 PASSO 1: Configurar GitHub Pages no Repositório

1. **Acesse seu repositório no GitHub**
   - Vá para: `https://github.com/SEU_USUARIO/go_router_modular`

2. **Vá em Settings (Configurações)**
   - Clique na aba **Settings** do repositório
   - No menu lateral, clique em **Pages** (pode estar em "Code and automation" → "Pages")

3. **Configure o Source**
   - Em **Source**, selecione: **GitHub Actions**
   - Não selecione "Deploy from a branch"
   - Salve as alterações

4. **Verifique as Permissões**
   - Ainda em Settings, vá em **Actions** → **General**
   - Em **Workflow permissions**, selecione: **Read and write permissions**
   - Marque: **Allow GitHub Actions to create and approve pull requests**
   - Salve as alterações

---

## 📝 PASSO 2: Verificar o Workflow (já configurado)

O arquivo `.github/workflows/deploy.yml` já está configurado! Verifique:

✅ **Branch de trigger**: O workflow está configurado para a branch `master`
   - Se você usa `main`, precisa ajustar no arquivo

✅ **Permissões corretas**: `contents: read`, `pages: write`, `id-token: write`

✅ **Build do Nextra**: Configurado para buildar a pasta `nextra_docs`

✅ **Deploy**: Configurado para fazer deploy da pasta `out`

---

## 📝 PASSO 3: Ajustar Branch (se necessário)

Se seu repositório usa a branch `main` ao invés de `master`:

1. Edite o arquivo `.github/workflows/deploy.yml`
2. Altere a linha:
   ```yaml
   branches: [master]
   ```
   Para:
   ```yaml
   branches: [main]
   ```

---

## 📝 PASSO 4: Fazer Push e Testar

1. **Commit e Push**
   ```bash
   git add .github/workflows/deploy.yml
   git commit -m "feat: configure GitHub Pages deployment"
   git push origin master  # ou main, conforme sua branch
   ```

2. **Verificar o Workflow**
   - Vá para a aba **Actions** do seu repositório
   - Você verá o workflow "Deploy Nextra Documentation to GitHub Pages" rodando
   - Aguarde alguns minutos para o build e deploy completarem

3. **Verificar o Deploy**
   - No workflow, você verá um ambiente chamado `github-pages`
   - Quando concluído, clique no ambiente para ver a URL do site
   - A URL será algo como: `https://SEU_USUARIO.github.io/go_router_modular/`

---

## 📝 PASSO 5: Configurar Custom Domain (Opcional)

Se quiser usar um domínio customizado:

1. Vá em **Settings** → **Pages**
2. Em **Custom domain**, adicione seu domínio
3. Configure o DNS conforme instruções do GitHub
4. Marque **Enforce HTTPS** (após o DNS propagar)

---

## 🔍 Verificação Final

### ✅ Checklist

- [ ] GitHub Pages configurado com source "GitHub Actions"
- [ ] Permissões do workflow configuradas como "Read and write"
- [ ] Workflow commitado e pushed para o repositório
- [ ] Workflow executado com sucesso na aba Actions
- [ ] Site acessível na URL do GitHub Pages

### 📊 Onde Verificar

1. **Status do Deploy**: `https://github.com/SEU_USUARIO/go_router_modular/actions`
2. **URL do Site**: `https://SEU_USUARIO.github.io/go_router_modular/`
3. **Ambiente GitHub Pages**: Settings → Environments → github-pages

---

## 🐛 Troubleshooting

### Workflow não executa
- ✅ Verifique se a branch está correta (`master` ou `main`)
- ✅ Verifique se o arquivo `.github/workflows/deploy.yml` está commitado
- ✅ Verifique se há mudanças na pasta `nextra_docs/` (o workflow pode ter trigger em paths)

### Build falha
- ✅ Verifique os logs do workflow em Actions
- ✅ Certifique-se que `package.json` e `package-lock.json` estão na pasta `nextra_docs/`
- ✅ Verifique se todas as dependências estão listadas

### Deploy falha
- ✅ Verifique as permissões: Settings → Actions → General → Workflow permissions
- ✅ Certifique-se que GitHub Pages está configurado para usar GitHub Actions (não branch)

### Site não carrega corretamente
- ✅ Verifique se o `basePath` está configurado corretamente no `next.config.js`
- ✅ Certifique-se que o arquivo `.nojekyll` está sendo criado na pasta `out/`
- ✅ Verifique a URL - deve incluir o nome do repositório: `/go_router_modular/`

---

## 🔄 Atualizações Futuras

O workflow está configurado para executar automaticamente quando:
- Há push na branch `master` (ou `main`, conforme configurado)
- Você executa manualmente via `workflow_dispatch`

Para atualizar a documentação:
1. Faça alterações nos arquivos em `nextra_docs/pages/`
2. Commit e push
3. O GitHub Actions fará o deploy automaticamente!

---

## 📚 Referências

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Nextra Documentation](https://nextra.site)

