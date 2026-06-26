## Context

`Module` (`lib/src/core/module/module.dart`) é a única abstração que o usuário do `go_router_modular` escreve para compor uma aplicação: ele agrupa binds, rotas, imports e hooks de ciclo de vida. A classe é pequena, mas cada membro é consumido por outras peças em momentos precisos:

- `imports()` é lido por `InjectionManager._collectImportedBinds` (`injection_manager.dart`), que registra os binds dos importados e desce recursivamente, com um conjunto de visitados que evita ciclos.
- `binds(Injector injector)` é chamado dentro de uma janela `startRegistering`/`finishRegistering` do `Injector` (`injector.dart`), que coleta os binds sem invocar as factories ainda.
- `routes` é consumido pelo `ModularRouteBuilder` (`route_builder.dart`).
- `initState(InjectorReader injector)` é chamado após o commit dos binds; recebe a interface de leitura, não a de escrita — Interface Segregation explícita.
- `dispose()` é chamado antes da remoção dos binds em `InjectionManager._unregisterModuleInternal`.
- `didChangeGoingReference` + `onDidChangeGoingReference` formam a proteção contra descarte prematuro: o observer de rota marca o módulo em transição e um microtask remove a marca; `_disposeModule` consulta a marca para pular o descarte.
- `configureRoutes({modulePath, topLevel})` registra o módulo como `AppModule` (idempotente) e constrói as rotas.

Distinção central: o `AppModule` é registrado uma única vez (`registerAppModule`) e nunca descartado; módulos de feature são registrados sob demanda e descartados ao sair. `EventModule` (`event_module.dart`) estende `Module` ativando listeners em `initState`.

Esta mudança é **documental** — captura esse contrato e o ciclo de vida como specs executáveis, sem alterar `lib/`. Complementa `documentar-sistema-di` (mecânica do container) e `documentar-sistema-roteamento` (conversão de rotas e gatilhos de navegação). Restrições: pt-BR; specs verificáveis pela suíte existente; sem abreviações nos nomes citados.

## Goals / Non-Goals

**Goals:**

- Specs testáveis cobrindo o contrato do `Module` (cada membro), a ordem determinística do ciclo de vida (registro e descarte) e as variedades de módulo (`AppModule`, feature, `EventModule`).
- Tornar explícito o **porquê** das decisões não óbvias: por que `initState` recebe `InjectorReader` e não `Injector`; por que `imports` precisa de proteção contra ciclos; por que `dispose` vem antes da remoção de binds; por que existe a janela de microtask na proteção de transição; por que o `AppModule` é especial.
- Documentar as formas idiomáticas de declaração para servir de guia ao usuário.
- Mapear onde SOLID é forte e fraco, sem prescrever refatoração.
- Rastreabilidade: cada requisito aponta o(s) arquivo(s) de referência.

**Non-Goals:**

- Não alterar comportamento nem assinaturas em `lib/`.
- Não redocumentar a mecânica interna do container (escopo de `documentar-sistema-di`) nem a conversão de rotas em si (escopo de `documentar-sistema-roteamento`).
- Não documentar o barramento de eventos em profundidade — apenas a extensão do ciclo de vida em `EventModule`.
- Não corrigir os pontos fracos de SOLID identificados.

## Decisions

### Decisão 1: Três capabilities por eixo — contrato, ordem do ciclo de vida e variedades

Dividiu-se em `module-contract` (o que cada membro é e promete), `module-lifecycle-order` (a sequência determinística de registro/descarte e a proteção de transição) e `module-kinds` (`AppModule` vs feature vs `EventModule`, composição por imports).

- **Por quê:** o contrato muda por motivos diferentes da ordem de execução, que por sua vez é diferente das variedades de módulo (Single Responsibility aplicado à documentação). Permite deltas independentes.
- **Alternativa considerada:** uma única capability `module` — rejeitada por misturar o "o quê" com o "quando" e o "quais tipos".

### Decisão 2: Especificar a ordem do ciclo de vida como contrato observável

`module-lifecycle-order` fixa a sequência (binds → imports → commit → mapeamento → initState → validação) e a precedência (dispose antes de remover binds) como requisitos, porque a ordem é parte do contrato que o usuário depende — por exemplo, ler um bind importado dentro de `initState`.

- **Por quê:** a ordem é exatamente o que quebra silenciosamente em refatorações do `InjectionManager`. Documentá-la como requisito a torna verificável.
- **Alternativa considerada:** tratar a ordem como detalhe interno — rejeitada porque o usuário escreve código que depende dela (resolver imports em `initState`).

### Decisão 3: Destacar a separação Injector vs InjectorReader como requisito de ISP

O fato de `binds` receber `Injector` (escrita) e `initState` receber `InjectorReader` (leitura) é um requisito de primeira classe, com cenário que verifica que `initState` não expõe métodos de registro.

- **Por quê:** é a aplicação mais clara de Interface Segregation no pacote e orienta o usuário a não registrar binds em `initState`.

### Decisão 4: Referenciar, não duplicar, as specs de DI e de roteamento

`module-kinds` descreve o compartilhamento de binds e a proteção do `AppModule` do ponto de vista do `Module`, referenciando a spec de DI para a mecânica de descarte; a proteção de transição referencia a spec de roteamento para o gatilho do observer.

- **Por quê:** evita três fontes de verdade para a mesma regra (DRY); a fronteira é "o `Module` define o contrato; o container executa; o roteamento dispara".

### Decisão 5: Documentar as formas idiomáticas como requisito de suporte, não como tutorial

As formas idiomáticas (`AppModule`, feature, shell, stateful shell, `EventModule`) viram um requisito com cenários, citando `example/` como referência, em vez de um passo a passo.

- **Por quê:** mantém o artefato como especificação verificável (os exemplos existem e compilam) e não como documentação narrativa que envelhece.

## Risks / Trade-offs

- **[Sobreposição com as specs de DI e roteamento]** → Fronteira explícita: contrato e ordem do `Module` aqui; mecânica do container em `documentar-sistema-di`; conversão de rotas e gatilhos em `documentar-sistema-roteamento`. Cenários evitam reafirmar regras já cobertas.
- **[Ordem do ciclo de vida tratada como contrato rígido]** → Apenas a sequência observável e dependida pelo usuário foi fixada; detalhes internos (estruturas do tracker, janela de 500ms da validação) ficaram abstratos.
- **[Pontos fracos de SOLID]** (dupla responsabilidade de `configureRoutes`, `didChangeGoingReference` público) → Registrados como contexto; cenários descrevem o efeito observável, não o acoplamento interno.
- **[Divergência spec↔código]** → A suíte de testes e os exemplos em `example/` são a verificação executável; cada requisito cita o arquivo de referência.

## Migration Plan

Não há deploy de runtime — a mudança adiciona apenas artefatos OpenSpec. Passos:

1. Revisar e validar (`openspec validate documentar-module-detalhado`).
2. Executar as tarefas de verificação (`flutter analyze`, `flutter test --coverage`) confirmando que a suíte e os exemplos cobrem os cenários.
3. Sincronizar as deltas para `openspec/specs/` quando aprovado (`/opsx:sync` ou `/opsx:archive`).
4. Rollback: remover o diretório do change; nenhum efeito sobre `lib/`.

## Open Questions

- A janela de microtask da proteção de transição e o atraso da validação agendada (500ms) devem virar requisitos numéricos ou permanecer descritos pela intenção observável? (Recomendação atual: intenção observável.)
- `EventModule` merece sua própria spec dedicada (incluindo barramento e disparo) numa próxima iteração, ou basta o requisito de extensão do ciclo de vida aqui? (Recomendação atual: spec dedicada futura para o sistema de eventos.)
- A dupla responsabilidade de `configureRoutes` (registrar + construir) deve gerar uma proposta de refatoração separada, ou permanece apenas documentada como ponto fraco?
