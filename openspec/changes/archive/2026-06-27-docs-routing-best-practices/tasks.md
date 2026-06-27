## 1. Conteúdo da página (EN + PT)

- [x] 1.1 Criar `nextra_docs/content/en/routes/best-practices.mdx` com frontmatter `title: Best Practices` e `import { Callout } from 'nextra/components'`.
- [x] 1.2 Documentar na página EN: padrão `feature_route.dart` com `MyRouteRelative` (constantes `param$`, path relativo, `*Module`, `*Named`, `*$<param>`) e `MyRoute` (`of(context)`, `go`/`push`/`pushMyDetail`, leitor estático `getMyIdParam`), espelhando o exemplo canônico da skill.
- [x] 1.3 Documentar na página EN: navegação só nomeada com contraexemplo (`❌ context.go('/my')` vs `✅ MyRoute.of(context).go()`), `name` no `ChildRoute` + composição `*Module`/`ModuleRoute`, e a regra de módulos síncronos (mostrar `binds` em cascade `..addSingleton..add`); referenciar `navigation` e `routes-system`.
- [x] 1.4 Criar `nextra_docs/content/pt/routes/best-practices.mdx` como tradução fiel da página EN (mesmo código, textos em pt-BR).

## 2. Navegação (_meta)

- [x] 2.1 Adicionar a chave `'best-practices': 'Best Practices'` em `nextra_docs/content/en/routes/_meta.ts`, logo após `navigation`.
- [x] 2.2 Adicionar a chave `'best-practices': 'Boas Práticas'` em `nextra_docs/content/pt/routes/_meta.ts`, na mesma posição.

## 3. Verificação

- [x] 3.1 Conferir paridade: `best-practices.mdx` existe em `content/en/routes` e `content/pt/routes`, e a chave `best-practices` está em ambos os `_meta.ts` na mesma posição.
- [x] 3.2 Conferir que os símbolos usados nos exemplos existem na API pública (`Module`, `ChildRoute`, `ModuleRoute`, `Modular.get`, `Injector`, `context.goNamed`/`pushNamed`).
- [x] 3.3 (Opcional) Rodar o build do Nextra (`cd nextra_docs && npm run build`) e confirmar que a página entra no export sem erro.
