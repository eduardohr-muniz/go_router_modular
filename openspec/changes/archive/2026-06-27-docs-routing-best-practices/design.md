## Context

O site Nextra (`nextra_docs/`, App Router, i18n EN/PT) já tem a seção `routes/` com `routes-system`, `shell-route`, `navigation`, `transitions/*`, `loader-system`, `redirects`. A convenção recomendada de organização/navegação de rotas existe como Agent Skill em `.claude/skills/go-router-modular/SKILL.md`, mas falta na documentação pública.

A capability `documentation-site` exige paridade EN/PT (mesma árvore, mesmos `_meta` na mesma ordem) e exatidão técnica (apenas símbolos da API pública). Qualquer página nova precisa respeitar essas duas regras.

## Goals / Non-Goals

**Goals:**
- Publicar as boas práticas de routing como página canônica na doc, em EN e PT.
- Manter o conteúdo alinhado à skill `go-router-modular` (mesma convenção, mesmos nomes).
- Preservar paridade EN/PT e registro no `_meta`.

**Non-Goals:**
- Duplicar `navigation.mdx`/`routes-system.mdx` — referenciar, não copiar.
- Mudar API/runtime do pacote ou a config de build.
- Suportar idiomas além de EN/PT.

## Decisions

### Decisão 1: Página dedicada vs. seção em página existente
Criar uma página dedicada `routes/best-practices.mdx` em vez de inflar `navigation.mdx`. As boas práticas cruzam navegação **e** organização de módulos/rotas; uma página própria é o lugar natural e fácil de linkar. Alternativa (anexar a `routes-system`) rejeitada por misturar referência de API com guia opinativo.

### Decisão 2: Posição na navegação (`_meta`)
Inserir `best-practices` logo após `navigation` em ambos os `_meta.ts`, pois é a continuação natural ("agora que você sabe navegar, organize assim"). A ordem MUST ser idêntica entre EN e PT.

### Decisão 3: Conteúdo espelha a skill, com fonte única de exemplo
Reusar o exemplo canônico `MyRouteRelative`/`MyRoute` da skill (mesmos nomes, mesma estrutura) para que doc e skill não divirjam. A página referencia `navigation` e `routes-system` para detalhe de API em vez de reexplicá-los.

### Decisão 4: Frontmatter e componentes Nextra
Seguir o padrão das páginas vizinhas: frontmatter `title`, `import { Callout } from 'nextra/components'` para as notas (regra/contraexemplo). Blocos de código Dart com realce.

## Risks / Trade-offs

- **[Drift entre skill e doc]** → Ambas usam o mesmo exemplo canônico e os mesmos nomes; manter o alinhamento ao editar qualquer uma. A página cita a convenção como "a recomendada", não um contrato de runtime.
- **[Quebra de paridade EN/PT]** → A spec exige paridade; a verificação confere arquivo nos dois idiomas e chave nos dois `_meta`.
- **[Exemplos com símbolos inexistentes]** → Usar apenas `Module`, `ChildRoute`, `ModuleRoute`, `Modular.get`, `context.goNamed/pushNamed`, `Injector` — todos exportados por `lib/go_router_modular.dart`.

## Migration Plan

1. Criar `content/en/routes/best-practices.mdx` e `content/pt/routes/best-practices.mdx`.
2. Registrar a chave `best-practices` em `en/routes/_meta.ts` e `pt/routes/_meta.ts` (mesma posição).
3. Conferir paridade (arquivo nos dois idiomas, chave nos dois `_meta`) e que os símbolos existem na API pública.
4. (Opcional) Build local do Nextra para validar que a página entra no export.
5. **Rollback**: remover os dois `.mdx` e as duas entradas de `_meta` — sem efeito no pacote.

## Open Questions

- Nenhuma bloqueante. O label exato em PT ("Boas Práticas") pode ser ajustado no apply.
