## MODIFIED Requirements

### Requirement: Paridade de conteúdo e navegação entre EN e PT

O sistema SHALL manter a mesma árvore de páginas e a mesma estrutura de navegação nos dois idiomas, com textos traduzidos. Para cada documento em `content/en/` MUST existir o documento correspondente em `content/pt/` (mesmo caminho relativo), e os arquivos `_meta` de cada idioma MUST listar as mesmas chaves de navegação na mesma ordem. A árvore MUST cobrir: `index` (Home); `getting-started/` (`quick-start`, `migration-guide`); `routes/` (`routes-system`, `shell-route`, `navigation`, `best-practices`, `transitions/index`, `transitions/examples`, `loader-system`, `redirects`); `dependency-injection`; `event-module/` (`index`, `widget-mixin`); `microfrontends`; `testing/` (`index`, `event-testing`, `fake-injector`); `changelog`.

Arquivos de referência: `nextra_docs/content/en/`, `nextra_docs/content/pt/`, `_meta` por idioma.

#### Scenario: Toda página existe nos dois idiomas

- **WHEN** as árvores `content/en/` e `content/pt/` são comparadas por caminho relativo
- **THEN** o conjunto de arquivos de conteúdo é idêntico entre os dois idiomas (nenhuma página existe em apenas um idioma)

#### Scenario: Navegação espelhada na mesma ordem

- **WHEN** os arquivos `_meta` de EN e PT são comparados
- **THEN** as chaves de navegação e sua ordem são as mesmas (apenas os rótulos diferem por idioma)

#### Scenario: Tópico obrigatório ausente é detectado

- **WHEN** qualquer tópico da árvore obrigatória não possui arquivo em um dos idiomas
- **THEN** a entrega é considerada incompleta (falha de paridade)

#### Scenario: A página de boas práticas de routing existe nos dois idiomas e na navegação

- **WHEN** a seção `routes/` é inspecionada em EN e PT
- **THEN** existe `routes/best-practices.mdx` em `content/en/` e em `content/pt/`
- **AND** a chave `best-practices` consta nos `_meta` de `en/routes` e `pt/routes`, na mesma posição

## ADDED Requirements

### Requirement: Página de boas práticas de routing documenta a convenção recomendada

O sistema SHALL fornecer, na seção de routing, uma página de boas práticas (`routes/best-practices.mdx`) que documente a convenção recomendada do `go_router_modular`, alinhada à Agent Skill `go-router-modular` e às specs de roteamento. A página MUST cobrir: (a) o padrão `feature_route.dart` por feature com `<Feature>RouteRelative` (constantes de path/nome, chaves `param$`, paths `*$<param>`, `*Module`, `*Named`) e `<Feature>Route` (navegação via `.of(context)` e leitores estáticos de parâmetro); (b) navegação exclusivamente nomeada (`goNamed`/`pushNamed`) com contraexemplo de path cru; (c) `name` obrigatório no `ChildRoute` e composição via `*Module`/`ModuleRoute`; e (d) preferência por módulos síncronos, evitando `binds`/`imports` assíncronos. O conteúdo MUST usar apenas símbolos da superfície pública (`lib/go_router_modular.dart`) e NÃO duplicar o material de referência de `navigation`/`routes-system`, referenciando-os para detalhe.

Arquivos de referência: `nextra_docs/content/{en,pt}/routes/best-practices.mdx`.

#### Scenario: Documenta o padrão feature_route.dart com as duas classes

- **WHEN** a página de boas práticas é lida (EN e PT)
- **THEN** ela apresenta `<Feature>RouteRelative` (constantes) e `<Feature>Route` (navegação + leitores), com um exemplo de código coerente

#### Scenario: Regra de navegação nomeada com contraexemplo

- **WHEN** a página é lida
- **THEN** ela mostra a navegação por `MyRoute.of(context)` e marca como incorreto o uso de `context.go('/...')` com path cru

#### Scenario: Cobre name no ChildRoute e módulos síncronos

- **WHEN** a página é lida
- **THEN** ela mostra `ChildRoute` com `name:` por constante e recomenda `binds`/`imports` síncronos, desaconselhando módulos assíncronos
