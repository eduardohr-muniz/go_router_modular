# GoRouter Modular Documentation

Este é o site de documentação oficial do **GoRouter Modular** construído com [Nextra](https://nextra.site).

## 🚀 Desenvolvimento

Para executar o site de documentação localmente:

```bash
# Instalar dependências
npm install

# Executar em modo de desenvolvimento
npm run dev
```

O site estará disponível em `http://localhost:3000`.

## 🏗️ Build

Para fazer build da documentação:

```bash
# Build de produção
npm run build

# Executar a versão built
npm start
```

## 📁 Estrutura

```
nextra_docs/
├── pages/              # Páginas da documentação
│   ├── docs/           # Documentação técnica
│   ├── guides/         # Guias e tutoriais
│   ├── examples/       # Exemplos práticos
│   └── _meta.json      # Configuração de navegação
├── public/             # Assets estáticos
├── theme.config.tsx    # Configuração do tema Nextra
├── next.config.js      # Configuração do Next.js
└── package.json        # Dependências do projeto
```

## 📚 Contribuindo

Para contribuir com a documentação:

1. Edite os arquivos MDX em `pages/`
2. Adicione novos assets em `public/`
3. Atualize a navegação em `_meta.json`
4. Teste localmente com `npm run dev`
5. Faça commit e push das mudanças

## 🔗 Links Úteis

- [GoRouter Modular no GitHub](https://github.com/Flutterando/go_router_modular)
- [Nextra Documentation](https://nextra.site)
- [Next.js Documentation](https://nextjs.org/docs)

---

Desenvolvido com ❤️ pela comunidade [Flutterando](https://flutterando.com.br)
