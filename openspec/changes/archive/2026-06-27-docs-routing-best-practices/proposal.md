## Why

A convenção de uso recomendada do `go_router_modular` (organização de rotas por feature, navegação nomeada, `name` no `ChildRoute`, módulos síncronos) já existe como Agent Skill em `.claude/skills/go-router-modular/`, mas **não está na documentação pública** do Nextra. Quem lê os docs não encontra o padrão recomendado; só descobre se usar Claude Code no repositório. Documentar as boas práticas na seção de routing dá ao leitor humano a mesma orientação que o agente recebe, em um lugar canônico e versionado.

## What Changes

- **Nova página "Best Practices"** na seção de routing do Nextra, em inglês (`content/en/routes/best-practices.mdx`) e português (`content/pt/routes/best-practices.mdx`), mantendo a paridade EN/PT do site.
- A página documenta:
  - **Padrão `feature_route.dart` por feature**, ao lado de `feature_module.dart`, com duas classes: `MyRouteRelative` (constantes de path/nome, chaves `param$`, paths `*$<param>`, `*Module`, `*Named`) e `MyRoute` (navegação via `MyRoute.of(context)` + leitores estáticos como `getMyIdParam(state)`).
  - **Navegação exclusivamente nomeada** (`goNamed`/`pushNamed` via `MyRoute`), com contraexemplo explícito de path cru (`context.go('/...')`).
  - **`name` obrigatório no `ChildRoute`** e composição via `*Module`/`ModuleRoute`.
  - **Evitar módulos assíncronos** (preferir `binds`/`imports` síncronos; `Future` só quando inevitável e justificado).
  - Tabela de nomenclatura e checklist final.
- **Registro nos `_meta.ts`** de `en/routes` e `pt/routes` para a página aparecer na navegação lateral (label "Best Practices" / "Boas Práticas").
- A página referencia as páginas existentes (`navigation`, `routes-system`) em vez de duplicar o material de referência.

## Capabilities

### New Capabilities
<!-- Nenhuma capability nova: a documentação já é uma capability existente. -->

### Modified Capabilities
- `documentation-site`: a árvore obrigatória de conteúdo e a navegação espelhada EN/PT passam a incluir `routes/best-practices`, e o site ganha uma página normativa de boas práticas alinhada à API pública e às specs de roteamento.

## Impact

- Novos arquivos: `nextra_docs/content/en/routes/best-practices.mdx`, `nextra_docs/content/pt/routes/best-practices.mdx`.
- Arquivos editados: `nextra_docs/content/en/routes/_meta.ts`, `nextra_docs/content/pt/routes/_meta.ts` (adicionar a chave `best-practices`).
- Build/deploy: nenhuma mudança de configuração; a página entra no export estático normalmente.
- Código do pacote (`lib/`): sem mudança.
- Consistência: o conteúdo espelha a Agent Skill `go-router-modular`; ambos devem permanecer alinhados.

## Non-goals (Não-objetivos)

- Não duplicar o conteúdo de `navigation.mdx`/`routes-system.mdx`; a página de boas práticas referencia essas páginas para detalhe de API.
- Não alterar a API nem o comportamento do pacote.
- Não impor o padrão em runtime; é orientação de documentação.
- Não criar a página em outros idiomas além de EN e PT.
