## Why

O pacote agora tem documentação sólida no Nextra e specs normativas em `openspec/specs/`, mas as **boas práticas de uso** (como nomear rotas, como navegar, como organizar um feature) não estão capturadas em um formato que um agente (Claude Code) aplique automaticamente ao escrever código com `go_router_modular`. Sem isso, código gerado tende a usar navegação por string de path crua e módulos com `binds`/`imports` assíncronos — exatamente os anti-padrões que queremos evitar.

Uma **Agent Skill** versionada no repositório (`.claude/skills/`) codifica a convenção do projeto uma única vez e a torna disponível a todos os contribuidores: o agente passa a gerar rotas e navegação no padrão correto por padrão, sem o autor precisar relembrar a convenção a cada feature.

## What Changes

- **Nova Agent Skill `go-router-modular`** em `.claude/skills/go-router-modular/SKILL.md`, versionada no repo, que orienta o agente a aplicar as boas práticas do pacote ao criar/editar rotas, módulos e navegação.
- A skill estabelece o padrão de **um `feature_route.dart` ao lado de cada `feature_module.dart`**, contendo:
  - `MyRouteRelative`: classe só de constantes de path/nome, com a constante de path relativo montado como `ChildRoute` (geralmente `'/'`), `*Module` (path de montagem do módulo no pai, ex.: `'/my'`), `*Named` (string do nome da rota), chaves de parâmetro com prefixo `param$` (ex.: `param$id`) e paths com parâmetro com sufixo `*$<param>` (ex.: `myDetail$id`).
  - `MyRoute`: classe de navegação construída com `BuildContext` (`MyRoute.of(context)`), com métodos de navegação (`go()`, `push()`, `pushMyDetail({required String id})`) e os leitores estáticos de parâmetro (`getMyIdParam(state)`).
- **Regra forte — navegação sempre nomeada**: navegar somente via `context.goNamed`/`pushNamed` encapsulado em `MyRoute`; nunca `context.go('/path')` com string crua. `pathParameters`/`extra` entram pelos métodos de `MyRoute`.
- **Regra forte — `name` no `ChildRoute`**: toda `ChildRoute` declara `name: MyRouteRelative.myNamed`; o `*Module` define onde o módulo é montado no pai. A skill cobre também que `ModuleRoute` aceita `name`.
- **Regra forte — evitar módulos assíncronos**: preferir `binds(Injector i)` e `imports()` síncronos; usar a forma assíncrona (retornando `Future`) apenas quando inevitável, com justificativa.
- **Convenção de nomenclatura**: classe de constantes com sufixo `*RouteRelative`; classe de navegação/leitura com sufixo `*Route` (via `.of(context)`); chaves de parâmetro com prefixo `param$`; paths com parâmetro com sufixo `*$<param>`; nomes de rota em kebab-case.
- **Casos de teste (evals)** para a skill, montados com o `skill-creator`, validando o gatilho (quando a skill deve disparar) e a qualidade da orientação gerada.

## Capabilities

### New Capabilities
- `agent-skill-go-router-modular`: define os requisitos da Agent Skill versionada no repo que orienta o agente a aplicar as boas práticas do `go_router_modular` — padrão `feature_route.dart` (`*RouteRelative`/`*Route`), navegação exclusivamente nomeada, `name` no `ChildRoute` e prevenção de módulos assíncronos —, incluindo o gatilho da skill e a suíte de evals que a valida.

### Modified Capabilities
<!-- Nenhuma capability existente do pacote muda comportamento; a skill é um artefato de tooling do repositório. -->

## Impact

- Novos arquivos:
  - `.claude/skills/go-router-modular/SKILL.md` (skill principal) e eventuais arquivos de referência/`examples` de apoio.
  - Artefatos de eval do `skill-creator` (prompts de teste e configuração), em local apropriado do skill-creator.
- Documentação: a skill aponta para a doc Nextra (`nextra_docs/content/{en,pt}/routes/*`) e para as specs (`openspec/specs/routing-*`) como fonte da verdade, sem duplicar conteúdo normativo.
- Código do pacote (`lib/`): **sem mudança** — a skill é tooling de agente; não altera a API nem o comportamento de `go_router_modular`.
- Fluxo do contribuidor: ao usar Claude Code neste repo, a skill dispara em tarefas de rota/módulo/navegação e aplica o padrão automaticamente.

## Non-goals (Não-objetivos)

- Não alterar a API pública nem o comportamento do pacote `go_router_modular`.
- Não tornar a navegação por string de path crua impossível em runtime (o pacote continua suportando-a); a skill apenas orienta o agente a não usá-la.
- Não proibir em definitivo módulos assíncronos no código existente; a regra é "evitar ao máximo", não remover suporte.
- Não reescrever a documentação Nextra; a skill referencia a doc existente em vez de duplicá-la.
- Não publicar a skill em nenhum marketplace externo; é uma skill local do repositório.
