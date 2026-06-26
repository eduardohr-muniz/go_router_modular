## Context

O `go_router_modular` oferece três pilares: injeção de dependências modular, roteamento por módulos e **comunicação por eventos**. Este último é o `EventModule` — um `Module` que ganha capacidade de escutar eventos tipados via o mixin `EventListenerMixin`, com registro/descarte de ouvintes acoplado ao ciclo de vida do módulo (`initState` → `dispose`).

O sistema de eventos é construído sobre o pacote `event_bus` e tem comportamento sutil que não é evidente pela leitura superficial:

- **Dois mixins de escuta distintos** com semânticas diferentes de `exclusive`: o `EventListenerMixin` (em `Module`) implementa fila de ouvintes exclusivos com um único ativo; o `ModularEventMixin` (em `State`) apenas converte o stream para broadcast (vários ouvintes simultâneos), sem fila.
- **Estado global centralizado** em `EventState` (singleton), chaveado de duas formas: assinaturas/flags por `eventBusId` (`internalEventBus.hashCode + hashCode` do módulo) e estruturas exclusivas por `internalEventBus.hashCode`.
- **Auto-descarte configurável** em dois níveis: global (`SetupModular.autoDisposeEvents`) e por ouvinte (`autoDispose`).
- **Parâmetro `broadcast` depreciado** mantido por compatibilidade, mapeado para `exclusive`.
- **`BuildContext` opcional** no callback, resolvido a partir do navegador modular e potencialmente nulo (ex.: refresh de página na web).

A ausência de especificação executável torna esse comportamento frágil a regressões. Esta mudança documenta o estado atual sem alterá-lo, complementando `documentar-sistema-di` e `documentar-sistema-roteamento`.

## Goals / Non-Goals

**Goals:**

- Especificar, de forma testável, todo o comportamento observável do sistema de eventos: `EventModule`, `EventListenerMixin`, `ModularEventListener`, `ModularEvent`, `ModularEventMixin`, `EventState` e os utilitários de teste (`clearEventModuleState`, `EventRecorder`, `ModularEventBus`).
- Tornar explícitos os pontos sutis: fila de exclusivos, dois níveis de auto-descarte, isolamento por barramento, contexto nulo e o `broadcast` depreciado.
- Mapear onde os princípios SOLID se manifestam e onde são fracos, como contexto para decisões futuras.

**Non-Goals:**

- Não alterar, refatorar ou corrigir nenhum comportamento do sistema de eventos.
- Não unificar as semânticas divergentes de `exclusive` entre os dois mixins.
- Não remover o parâmetro `broadcast` depreciado nem o estado global mutável.
- Não redocumentar DI ou roteamento — apenas referenciá-los onde o ciclo de vida do `Module` dispara o registro/descarte de ouvintes.

## Decisions

### Decisão 1: Dividir em quatro capabilities por responsabilidade

Optou-se por separar a documentação em `events-event-module` (módulo e ciclo de vida), `events-listening` (API `on` e modos de escuta), `events-bus` (barramento, disparo e estado) e `events-testing` (utilitários de teste e diagnóstico).

- **Por quê:** cada capability tem um único motivo para mudar (Single Responsibility aplicado à própria documentação). Um leitor que só quer entender disparo vai a `events-bus`; quem quer entender exclusivos vai a `events-listening`.
- **Alternativa considerada:** uma única spec `events` monolítica. Rejeitada por misturar concerns e dificultar evolução incremental, espelhando o que já foi feito para roteamento (quatro capabilities `routing-*`).

### Decisão 2: Documentar as duas semânticas de `exclusive` separadamente

`EventListenerMixin.on(exclusive: true)` cria fila FIFO com um único ativo e reativação no descarte; `ModularEventMixin.on(exclusive: true)` apenas usa `asBroadcastStream()` permitindo múltiplos ouvintes. São comportamentos diferentes sob o mesmo nome.

- **Por quê:** documentá-los como requisitos distintos (em `events-listening`) evita que o leitor assuma equivalência. Cada um tem cenários próprios.
- **Alternativa considerada:** tratar como um só conceito. Rejeitada por ser factualmente incorreta e fonte provável de bugs no consumidor.

### Decisão 3: Especificar o esquema de chaveamento do `EventState` explicitamente

A spec `events-bus` registra que assinaturas/flags usam `eventBusId = internalEventBus.hashCode + hashCode` do módulo, enquanto as estruturas exclusivas usam apenas `internalEventBus.hashCode`.

- **Por quê:** essa assimetria é a origem do isolamento por módulo (subscriptions) versus por barramento (fila exclusiva). Sem documentá-la, o comportamento de fila compartilhada entre módulos do mesmo barramento parece mágico.
- **Alternativa considerada:** omitir detalhe de implementação. Rejeitada porque o comportamento observável (fila compartilhada entre módulos) só é explicável por esse chaveamento.

### Como o desenho respeita SOLID

- **Single Responsibility:** `EventState` concentra exclusivamente o armazenamento de estado; `ModularEventListener` isola a organização de ouvintes; `EventRecorder`/`ModularEventBus` isolam o suporte a testes. A divisão em quatro capabilities reflete essas fronteiras.
- **Dependency Inversion:** o `EventModule` depende da abstração `ModularEventListener` (lista injetada por `eventImports()`), não de implementações concretas de ouvintes. O barramento é injetável (`EventBus?` no construtor), permitindo substituir o global por um isolado em testes.
- **Open/Closed (pontos de extensão):** novos ouvintes são adicionados criando subclasses de `ModularEventListener` e registrando-as em `eventImports()`, sem alterar o `EventModule`. Novos tipos de evento são apenas novas classes, sem tocar a infraestrutura.
- **Liskov:** `EventModule` é substituível por qualquer `Module` onde um módulo é esperado, pois apenas estende o contrato de ciclo de vida.

### Pontos fracos de SOLID (registrados como contexto, não corrigidos)

- **Estado global mutável compartilhado** (`EventState` singleton) acopla todos os módulos a um estado de processo — dificulta paralelismo de testes sem `clearEventModuleState()`.
- **Parâmetro `broadcast` depreciado** mantido em três assinaturas (`ModularEvent.on`, `EventListenerMixin.on`, `ModularEventListener.on`) viola Interface Segregation de forma branda, mantido por compatibilidade.
- **Divergência semântica de `exclusive`** entre os dois mixins é uma quebra branda de princípio da menor surpresa.

## Risks / Trade-offs

- **Divergência spec ↔ código** → A spec referencia arquivos e comportamentos atuais; mitigação: cada requisito cita os arquivos de referência e os cenários são desenhados como testes verificáveis contra o código existente.
- **Detalhe de implementação na spec (chaveamento de hash)** → Pode parecer acoplamento excessivo a implementação; mitigação: incluído apenas onde o comportamento observável (isolamento/fila) depende dele, não como descrição linha a linha.
- **Cobertura de cenários de borda** → Risco de documentar só o caminho feliz; mitigação: cada capability inclui cenários de erro/vazio/borda (contexto nulo, fila vazia, tipo não escutado, debug desabilitado, ouvinte regular ignorado por exclusivo existente).

## Migration Plan

Não aplicável a comportamento de runtime — mudança puramente documental. Passos de entrega:

1. Criar os quatro arquivos de spec em `openspec/changes/documentar-event-module/specs/`.
2. Validar consistência com o código de referência (sem editar `lib/`).
3. Ao aplicar (`/opsx:apply`), sincronizar as specs para `openspec/specs/events-*` via `/opsx:sync`.

Rollback: remover os arquivos de spec adicionados; nenhum código de produção é afetado.

## Open Questions

- Nenhuma bloqueante. Questão futura (fora de escopo): unificar a semântica de `exclusive` entre `EventListenerMixin` e `ModularEventMixin` exigiria mudança de comportamento e seria proposta como change separada.
