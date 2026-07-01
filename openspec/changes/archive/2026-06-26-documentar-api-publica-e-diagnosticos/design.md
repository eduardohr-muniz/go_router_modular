## Context

O esforço de documentação do `go_router_modular` já produziu specs para DI, roteamento, módulos, eventos e dependências. Uma auditoria de cobertura — cruzando o basename de cada arquivo de `lib/` (47 arquivos) com o texto de todas as specs propostas — identificou exatamente cinco arquivos sem qualquer referência:

- `lib/go_router_modular.dart` — barril de API pública.
- `lib/testing.dart` — barril de utilitários de teste.
- `lib/src/internal/asserts/go_router_modular_configure_assert.dart` — mensagem-guia de `assert`.
- `lib/src/internal/internal_logs.dart` — `iLog`/`kInternalLogs`.
- `lib/src/core/dependency_analyzer/dependency_analyzer.dart` — `DependencyAnalyzer`.

A inspeção dos pontos de uso revelou dois achados relevantes para a documentação honesta:

- `iLog`/`kInternalLogs` **não é chamado em nenhum lugar** de `lib/` (código dormente).
- O `DependencyAnalyzer` tem suas APIs de rastreamento chamadas **apenas pelo próprio teste**; em produção só `clearAll()` é usado (limpeza em `ModularTestScope`). A proteção real contra ciclos vive em `BindSearchProtection`.

Esta mudança fecha a cobertura documental do `lib/` registrando esses cinco arquivos como especificação executável, sem alterar código.

## Goals / Non-Goals

**Goals:**

- Documentar a superfície de API pública (barris principal e de testes), incluindo a política deliberada de `hide`/`show` nos re-exports.
- Documentar os helpers internos de diagnóstico/guarda, distinguindo o que é ativo (assert de configuração) do que é dormente (`iLog`, rastreamento do `DependencyAnalyzer`).
- Tornar o código dormente visível e acionável (candidato a remoção/ativação) com base em evidência.

**Non-Goals:**

- Não alterar a política de exports nem nenhum arquivo de `lib/`.
- Não remover nem ativar `iLog` ou o rastreamento do `DependencyAnalyzer`.
- Não redocumentar DI, roteamento, módulos ou eventos.
- Não documentar arquivos já cobertos por outras specs.

## Decisions

### Decisão 1: Duas capabilities por natureza — contrato público vs. helpers internos

Optou-se por `public-api-surface` (o que o pacote expõe ao consumidor) e `internal-diagnostics` (helpers internos de guarda/observabilidade).

- **Por quê:** são audiências e motivos de mudança distintos. A superfície pública muda quando a API do pacote muda; os diagnósticos internos mudam por razões de implementação/manutenção. Single Responsibility aplicado à documentação.
- **Alternativa considerada:** uma capability única "miscelânea". Rejeitada por misturar contrato externo com detalhe interno.

### Decisão 2: Documentar a política de hide/show como requisito normativo

O re-export com `hide GoRouter, ShellRoute` e `hide GoTransition` é intencional: os tipos modulares (`Modular`, `ShellModularRoute`, `GoTransition` modular) substituem os originais. A spec o registra como requisito com cenários verificáveis.

- **Por quê:** essa ocultação é fácil de quebrar acidentalmente (um export descuidado reintroduz colisão de nomes). Documentá-la cria um ponto de regressão detectável.
- **Alternativa considerada:** tratar como detalhe trivial. Rejeitada porque a ocultação é parte do contrato público e da ergonomia do pacote.

### Decisão 3: Código dormente como requisito de primeira classe

Tanto `iLog` quanto o rastreamento do `DependencyAnalyzer` ganham requisitos que afirmam explicitamente a ausência de uso em produção, com cenários verificáveis por busca.

- **Por quê:** documentar o que NÃO é usado evita a falsa impressão de que toda a infraestrutura é necessária; gera achado acionável sem executar a remoção (fora de escopo). Espelha o tratamento dado às dependências órfãs em `documentar-dependencias-packages`.
- **Alternativa considerada:** documentar apenas a API "como se" estivesse em uso. Rejeitada por ser enganosa.

### Como o desenho respeita SOLID

- **Single Responsibility:** cada capability cobre um motivo de mudança; cada requisito, um arquivo/conceito.
- **Open/Closed:** a superfície pública é estendida adicionando exports ao barril sem alterar os existentes; o catálogo de diagnósticos cresce adicionando requisitos.
- **Dependency Inversion (observado no alvo):** a documentação evidencia que o pacote expõe abstrações próprias (tipos modulares) e oculta as concretas equivalentes das libs externas, reduzindo o acoplamento do consumidor ao `go_router`/`go_transitions`.

## Risks / Trade-offs

- **Divergência spec ↔ barris/código** → exports e helpers podem evoluir; mitigação: cada requisito cita o arquivo de referência e os cenários são verificáveis por inspeção/busca na revisão.
- **Risco de o leitor remover o código dormente aqui** → mitigação: spec e Não-objetivos afirmam que remoção/ativação é fora de escopo desta mudança documental.
- **Cobertura aparentemente "completa"** → após esta mudança o `lib/` fica 100% referenciado por basename; mitigação: registrar que "referenciado" significa citado por uma spec, não necessariamente exaustivamente especificado em cada detalhe.

## Migration Plan

Não aplicável a runtime — mudança puramente documental. Passos de entrega:

1. Criar os dois arquivos de spec em `openspec/changes/documentar-api-publica-e-diagnosticos/specs/`.
2. Validar o conteúdo contra os barris e os pontos de uso (sem editar `lib/`).
3. Ao aplicar (`/opsx:apply`), sincronizar para `openspec/specs/public-api-surface` e `openspec/specs/internal-diagnostics` via `/opsx:sync`.

Rollback: remover os arquivos de spec adicionados; nenhum código é afetado.

## Open Questions

- Remover `iLog`/`kInternalLogs` e o rastreamento dormente do `DependencyAnalyzer`, ou passar a usá-los de fato? Fora de escopo aqui; deve ser uma mudança separada com decisão explícita e testes.
