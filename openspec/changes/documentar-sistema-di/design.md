## Context

O sistema de injeção de dependências do `go_router_modular` está implementado em `lib/src/core/bind/`, `lib/src/core/manager/` e `lib/src/di/`. É um container modular cujo ciclo de vida dos binds é rastreado por módulo/rota. O desenho já está dividido em camadas com responsabilidade única, mas esse conhecimento só existe no código. Esta mudança é **documental**: captura o comportamento atual como especificação executável (requisitos + cenários) e descreve a arquitetura para manutenção e onboarding, sem modificar `lib/`.

Estado atual resumido (cada peça aponta para `Single Responsibility`):

- `Bind<T>` (`lib/src/core/bind/bind.dart`): define o contrato tipo→factory, atributos de ciclo de vida (`isSingleton`, `isLazy`, `key`) e o cache da instância. Também expõe a fachada estática (`get`, `tryGet`, `registerBatch`, `commitBatch`, `dispose`) que delega para os componentes abaixo.
- `BindStorage` (`bind_storage.dart`): armazenamento puro — mapa por tipo, mapa por chave, pendências e cache negativo.
- `BindRegistry` (`bind_registry.dart`): única porta de escrita no storage; fluxo batch (`registerBatch` → `commitBatch`) e indexação canônica (slot por tipo vs. slot por chave).
- `BindLocator` (`bind_locator.dart`): resolução multi-estratégia, caminho rápido, cache negativo e coordenação da proteção.
- `BindSearchProtection` (`bind_search_protection.dart`): estado de busca — tentativas, pilha de busca, pilha de invocações e contador de bloqueio por identidade.
- `BindDisposer` (`bind_disposer.dart`) + `CleanBind` (`lib/src/di/clean_bind.dart`): descarte e limpeza polimórfica (`dispose`/`close`/`cancel`).
- `InjectionManager` (`injection_manager.dart`) + `BindContextTracker` (`bind_context_tracker.dart`) + `OperationQueue` (`operation_queue.dart`): ciclo de vida de módulos, rastreamento bidirecional módulo↔bind e serialização das operações.
- `Injector` / `InjectorReader` (`lib/src/di/injector.dart`): fachada de registro (escrita) e leitura (`get`); `FakeInjector` e `BindTemplate` (`lib/src/testing/`) são as variantes de teste.

Restrições: pt-BR em todos os artefatos; a spec deve refletir o comportamento real verificável pela suíte de testes existente; nenhuma abreviação nos nomes citados.

## Goals / Non-Goals

**Goals:**

- Produzir specs testáveis que descrevam fielmente: tipos de bind, armazenamento dual, resolução, proteções e ciclo de vida de módulos.
- Tornar explícito o **porquê** de cada mecanismo não óbvio (cache negativo, bloqueio de factory, propagação de cache em imports, fila de operações).
- Mapear onde SOLID é forte e onde é fraco, para guiar refatorações futuras sem prescrevê-las aqui.
- Garantir rastreabilidade: cada requisito aponta o(s) arquivo(s) de referência em `lib/`.

**Non-Goals:**

- Não alterar comportamento nem assinatura de qualquer API em `lib/`.
- Não corrigir os pontos fracos de SOLID identificados.
- Não documentar roteamento, eventos ou widgets além do necessário para o contexto dos binds.

## Decisions

### Decisão 1: Dividir a documentação em três capabilities em vez de uma só

Optou-se por `dependency-injection` (o quê o container faz), `dependency-injection-protection` (como ele se protege) e `module-lifecycle` (como módulos governam o ciclo de vida dos binds).

- **Por quê:** cada uma tem um motivo de mudança distinto (Single Responsibility aplicado à própria documentação). A resolução pode evoluir sem tocar nas proteções; o ciclo de vida de módulos é ortogonal aos tipos de bind.
- **Alternativa considerada:** uma única capability `dependency-injection` monolítica — rejeitada por agrupar requisitos com ciclos de mudança independentes, dificultando deltas futuros.

### Decisão 2: Especificar comportamento observável, não estruturas internas

Os cenários descrevem efeitos visíveis (identidade preservada, factory invocada N vezes, exceção lançada) e citam os arquivos internos apenas como referência, não como contrato.

- **Por quê:** mantém a spec estável diante de refatorações internas (ex.: trocar singletons estáticos por injeção real no `Bind`) desde que o comportamento se mantenha. Alinha com Interface Segregation: o contrato público é `Injector`/`InjectorReader`, não as classes internas.
- **Alternativa considerada:** especificar nomes de métodos privados e estruturas de dados — rejeitada por acoplar a spec à implementação atual.

### Decisão 3: Registrar os mecanismos não óbvios como requisitos de primeira classe

Cache negativo, bloqueio de factory por identidade (com aninhamento), self-reference legítima vs. ciclo real, propagação de cache entre binds duplicados de imports e serialização por fila são requisitos próprios.

- **Por quê:** são exatamente as partes que causam regressões silenciosas quando alguém "simplifica" sem entender. A propagação de cache em imports, por exemplo, evita dupla instanciação de singletons quando um módulo importa outro — comportamento já coberto por teste de regressão no repositório.
- **Alternativa considerada:** tratá-los como notas de implementação no design — rejeitada porque notas não são verificáveis nem versionadas como contrato.

### Decisão 4: Mapear SOLID descritivamente, sem prescrever refatoração

O design lista os pontos fortes (camadas com responsabilidade única, `InjectorReader` segregado, inversão por delegação) e os pontos fracos (singletons estáticos no `Bind`, cascata fixa em `CleanBind`, estado global mutável que exige `resetForTesting`).

- **Por quê:** dá contexto para decisões futuras sem inflar o escopo desta mudança documental.

## Risks / Trade-offs

- **[Divergência spec↔código ao longo do tempo]** → A suíte de testes existente é a verificação executável; cada requisito cita o arquivo de referência, e mudanças de comportamento devem atualizar a spec correspondente via novo change OpenSpec.
- **[Spec descrever comportamento incidental como contrato]** → Cenários focam em efeitos que a suíte de testes já valida; comportamento não testado foi descrito de forma conservadora, sem inventar garantias.
- **[Estado global mutável dificulta isolamento]** → Registrado como ponto fraco de SOLID; o requisito de reset para testes documenta a mitigação existente (`resetForTesting`).
- **[Imprecisão em detalhes de proteção]** (limites de tentativa, bypass de self-reference) → Cenários descrevem a intenção observável; números mágicos foram mantidos abstratos ("limite máximo") para não acoplar a spec a constantes internas.

## Migration Plan

Não se aplica deploy de runtime — a mudança adiciona apenas artefatos OpenSpec. Passos:

1. Revisar e validar os artefatos (`openspec validate documentar-sistema-di`).
2. Implementar as tarefas de verificação (`flutter analyze`, `flutter test --coverage`) confirmando que a suíte atual cobre os cenários descritos.
3. Sincronizar as deltas para `openspec/specs/` quando aprovado (`/opsx:sync` ou `/opsx:archive`).
4. Rollback: remover o diretório do change; nenhum efeito sobre `lib/`.

## Open Questions

- Constantes de proteção (limite exato de tentativas de busca, janela de validação deferida) devem virar requisitos numéricos ou permanecer abstratas? (Recomendação atual: manter abstratas.)
- Há comportamento de `pendingObjectBinds` / descoberta de `Bind<Object>` relevante o suficiente para virar requisito próprio numa próxima iteração, ou permanece como detalhe interno do `BindLocator`?
