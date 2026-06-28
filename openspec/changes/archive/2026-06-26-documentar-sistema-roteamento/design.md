## Context

O roteamento do `go_router_modular` é uma camada modular sobre o `go_router`, implementada em `lib/src/routing/`, `lib/src/core/config/go_router_modular_configure.dart`, `lib/src/widgets/` e `lib/src/extensions/`. Seu diferencial é entrelaçar navegação e ciclo de vida da injeção de dependências: ao entrar numa rota de módulo os binds são registrados (no `redirect`), ao sair são descartados (no `dispose` de um observer de widget). Esse desenho já existe e funciona; o que falta é documentação que explique cada peça e o porquê dela. Esta mudança é **documental** — captura o comportamento atual como specs executáveis sem alterar `lib/`. Complementa a spec `documentar-sistema-di`, que descreve o container de DI em si.

Peças e responsabilidade única (Single Responsibility), com caminho de referência:

- `ModularRoute` (`i_modular_route.dart`): marcador abstrato que habilita seleção polimórfica de rotas.
- `ChildRoute` (`child_route.dart`): dados de rota folha → `GoRoute`.
- `ModuleRoute` (`module_route.dart`): segmento que monta um `Module` → `GoRoute` aninhado com `redirect`.
- `ShellModularRoute` (`shell_modular_route.dart`): layout compartilhado → `ShellRoute`.
- `StatefulShellModularRoute` + `ModularBranch`/`ModuleBranch` (`stateful_shell_modular_route.dart`): shell com estado por branch → `StatefulShellRoute`.
- `ModularRouteBuilder` (`route_builder.dart`): único tradutor de tipos modulares para `RouteBase`, normalização de paths e ponto de injeção do ciclo de vida.
- `StatefulShellBranchTransitions` (`stateful_shell_branch_transitions.dart`): resolução e sincronização da animação entre branches.
- `Modular` (`go_router_modular_configure.dart`): configuração singleton, snapshot imutável de parâmetros, `copyWith`/`copyRouterConfig`.
- `ParentWidgetObserver` (`parent_widget_observer.dart`): dispara o descarte do módulo no `dispose` do widget.
- `OnceBuilder` (`once_builder.dart`): cacheia a closure de build para não reinstanciar factories no rebuild.
- `ModularLoader` (`modular_loader.dart`) + `ModularApp.router` (`material_app_router.dart`): overlay de carregamento durante o registro e injeção do router.
- Extensions (`route_extension.dart`, `context_extension.dart`): navegação assíncrona com completers, utilitários de pop, leitura de estado e açúcar de DI.

Restrições: pt-BR; specs refletem comportamento real verificável pela suíte existente; sem abreviações nos nomes citados.

## Goals / Non-Goals

**Goals:**

- Specs testáveis cobrindo: tipos de rota e seu mapeamento ao `go_router`, construção e normalização de paths, ligação roteamento↔ciclo de vida do DI, configuração global e navegação ergonômica.
- Tornar explícito o **porquê** dos mecanismos não óbvios: `redirect` como gancho de registro, `OnceBuilder` contra reinstanciação, proteção de transição (`onDidChangeGoingReference`), descarte em cascata de branches, loader condicional ao completer.
- Mapear onde SOLID é forte (polimorfismo de rotas, inversão por callbacks no observer) e fraco (acoplamento a `go_transitions`, mutação global de `GoTransition.defaultDuration`), sem prescrever refatoração.
- Rastreabilidade: cada requisito aponta o(s) arquivo(s) de referência em `lib/`.

**Non-Goals:**

- Não alterar comportamento nem assinaturas em `lib/`.
- Não redocumentar o container de DI (tipos de bind, resolução, proteções) — escopo de `documentar-sistema-di`.
- Não documentar eventos/widgets fora do necessário para o roteamento.
- Não corrigir os pontos fracos de SOLID identificados.

## Decisions

### Decisão 1: Quatro capabilities por eixo de responsabilidade

Dividiu-se em `routing-routes` (o que são as rotas e como viram `go_router`), `routing-lifecycle` (quando binds são registrados/descartados), `routing-configuration` (como o router é montado e parametrizado) e `routing-navigation` (como se navega).

- **Por quê:** cada eixo muda por motivos independentes (Single Responsibility aplicado à documentação). Os tipos de rota podem evoluir sem mexer no ciclo de vida; a configuração é ortogonal à navegação.
- **Alternativa considerada:** uma única capability `routing` monolítica — rejeitada por agrupar requisitos com ciclos de mudança distintos e dificultar deltas futuros.

### Decisão 2: Descrever o acoplamento DI a partir do roteamento, sem duplicar a spec de DI

Os requisitos de `routing-lifecycle` descrevem **quando e onde** o registro/descarte é disparado pela navegação (redirect, `ParentWidgetObserver`), referenciando — mas não redescrevendo — o comportamento interno do container já coberto por `documentar-sistema-di`.

- **Por quê:** evita duplicação e divergência entre as duas specs (DRY). A fronteira é clara: "o roteamento dispara; o container executa".
- **Alternativa considerada:** repetir as regras de descarte de bind aqui — rejeitada por criar duas fontes de verdade.

### Decisão 3: Especificar comportamento observável, não a estrutura interna do builder

Os cenários descrevem efeitos visíveis (path efetivo, tela construída uma vez, módulo descartado ao sair, loader exibido/ocultado) e citam métodos internos apenas como referência.

- **Por quê:** mantém a spec estável diante de refatorações internas do `ModularRouteBuilder` desde que o comportamento se preserve. Alinha com Interface Segregation: o contrato é a API pública de rotas/navegação, não os métodos privados de construção.
- **Alternativa considerada:** fixar nomes de métodos privados e a ordem exata de agregação como contrato — rejeitada por acoplar a spec à implementação atual.

### Decisão 4: Registrar mecanismos não óbvios como requisitos de primeira classe

`OnceBuilder` (anti-reinstanciação), proteção de transição rápida, descarte em cascata de branches, loader condicional ao completer e precedência de container do shell stateful são requisitos próprios, com cenários.

- **Por quê:** são exatamente as partes que causam regressões silenciosas quando alguém "simplifica" sem entender — por exemplo, remover o `OnceBuilder` reintroduz múltiplas instâncias de binds factory a cada rebuild interno do `go_router`.

### Decisão 5: Manter constantes e detalhes de animação abstratos

Durações efetivas, janela de microtask da proteção de transição e a mecânica do `AnimationController` do switcher de branches são descritas pela intenção observável, não por números ou nomes internos.

- **Por quê:** não acoplar a spec a constantes que podem mudar sem alterar o comportamento percebido.

## Risks / Trade-offs

- **[Divergência spec↔código ao longo do tempo]** → A suíte de testes existente é a verificação executável; cada requisito cita o arquivo de referência, e mudanças de comportamento devem atualizar a spec via novo change OpenSpec.
- **[Fronteira borrada com a spec de DI]** → `routing-lifecycle` descreve apenas o gatilho a partir da navegação e referencia a spec de DI para o comportamento do container; cenários evitam reafirmar regras de descarte de bind.
- **[Acoplamento a `go_transitions` e estado global mutável]** → Registrados como pontos fracos de SOLID/OCP no design; cenários de transição focam no efeito (animada vs. `indexedStack`) e não na mutação global de `GoTransition.defaultDuration`.
- **[Comportamento incidental tratado como contrato]** → Cenários focam em efeitos que a suíte já valida; comportamento não testado foi descrito de forma conservadora.

## Migration Plan

Não há deploy de runtime — a mudança adiciona apenas artefatos OpenSpec. Passos:

1. Revisar e validar (`openspec validate documentar-sistema-roteamento`).
2. Executar as tarefas de verificação (`flutter analyze`, `flutter test --coverage`) confirmando que a suíte atual cobre os cenários descritos.
3. Sincronizar as deltas para `openspec/specs/` quando aprovado (`/opsx:sync` ou `/opsx:archive`).
4. Rollback: remover o diretório do change; nenhum efeito sobre `lib/`.

## Open Questions

- A precedência exata de resolução de transição do shell stateful (container > transição de rota > transição padrão > `indexedStack`) deve virar requisito numérico explícito ou permanecer descrita por cenários? (Recomendação atual: cenários.)
- `RouteModularModel` (`route_model.dart`) aparenta ser código legado não integrado ao fluxo principal — deve ser documentado como obsoleto numa próxima iteração ou ignorado por não ter comportamento observável?
- O conjunto completo de variantes assíncronas de navegação deve ter um cenário por variante ou um cenário representativo cobre o contrato comum? (Recomendação atual: representativo, dado que compartilham o mesmo mecanismo de completer.)
