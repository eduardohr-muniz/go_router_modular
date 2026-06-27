## Context

Investigação do estado atual (modo explore) revelou que 12 dos 45 arquivos sob `lib/src/` importam o barril público `package:go_router_modular/go_router_modular.dart`. Como o barril re-exporta todas as áreas (DI, routing, events, widgets, config, extensions), qualquer arquivo que o importa passa a depender transitivamente do pacote inteiro — inclusive arquivos de base que deveriam ser folhas do grafo.

Mapa real do que cada arquivo de barril efetivamente usa (origem → destinos reais):

```
core/manager/bind_context_tracker.dart   → core/module(Module), di(BindIdentifier)
core/manager/injection_manager.dart      → core/bind(Bind), core/module(Module), di(BindIdentifier,Injector), internal(SetupModular)
di/injector.dart                         → core/bind(Bind)
events/event_module.dart                 → core/module(Module)
events/modular_event.dart                → core/module(Module), internal(SetupModular)
extensions/context_extension.dart        → core/bind(Bind)
extensions/route_extension.dart          → core/config(RouteWithCompleterService)
internal/asserts/...configure_assert.dart→ core/config(GoRouterModular,Modular), widgets(ModularApp)
routing/route_builder.dart               → core/config(Modular,RouteWithCompleterService), core/manager(InjectionManager), core/module(Module), exceptions(GoRouterModularException), internal(ModuleAssert), widgets(ModularLoader,OnceBuilder,ParentWidgetObserver)
routing/shell_modular_route.dart         → (nenhum símbolo do pacote)
widgets/material_app_router.dart         → core/config(Modular)
widgets/parent_widget_observer.dart      → core/config(Modular), core/module(Module)
```

Achados que orientam o desenho:

- O subsistema de DI está quase autossuficiente: `di/injector.dart` só precisa de `core/bind`. Isso é insumo direto para `extract-modular-di-package`.
- `routing/shell_modular_route.dart` não usa nada do pacote — o import é peso morto.
- `RouteWithCompleterService` e o façade `Modular` vivem dentro do god-object `core/config/go_router_modular_configure.dart` e são alcançados por routing, extensions e widgets — acoplamento que o passo B (fora deste escopo) deverá tratar.
- `route_builder.dart` é o maior concentrador de dependências cruzadas — confirma-o como alvo do passo B.

Esta mudança é o passo C da sequência C → B → A: comportamento-preservado, mecânico, e cujo valor é tornar o grafo visível e impor disciplina de import. Restrições: pt-BR; sem mudança de comportamento; sem abreviações.

## Goals / Non-Goals

**Goals:**

- Trocar os 12 imports de barril por imports específicos, preservando comportamento e superfície pública.
- Padronizar o estilo de import interno (`package:go_router_modular/src/...`).
- Adicionar uma guarda automatizada que impeça a reintrodução do import de barril.
- Deixar registrado o grafo real revelado, como insumo para o passo B.

**Non-Goals:**

- Não mover arquivos nem reorganizar pastas (passo A).
- Não quebrar o ciclo `module ⇄ routing` nem extrair serviços do god-config (passo B).
- Não extrair o micropackage de DI (`extract-modular-di-package`).
- Não tocar no conteúdo nem na superfície do barril público.

## Decisions

### Decisão 1: Imports específicos via `package:go_router_modular/src/...`, não relativos

Adotar o caminho absoluto `package:go_router_modular/src/<área>/<arquivo>.dart` como estilo único dos imports internos novos.

- **Por quê:** é o estilo já majoritário (54 ocorrências) e evita a fragilidade de `../../` ao mover arquivos no passo A. Consistência reduz carga cognitiva (Clean Code).
- **Alternativa considerada:** imports relativos `../` — rejeitada por quebrarem ao reorganizar pastas e por já serem minoria (6 ocorrências).

### Decisão 2: Resolver símbolos pelo arquivo de origem real, não por barris de área

Cada arquivo importa diretamente o arquivo que **define** o símbolo (ex.: `core/bind/bind.dart` para `Bind`), não um barril intermediário de área.

- **Por quê:** mantém a dependência mínima e explícita (Interface Segregation); um barril de área reintroduziria parte do problema. Barris de área podem ser considerados no passo A, se desejável.
- **Alternativa considerada:** criar barris por subsistema agora — adiada para o passo A para manter este change estritamente mecânico.

### Decisão 3: Guarda como teste de arquitetura no pacote de testes

Implementar a guarda como um teste Dart que lê os arquivos de `lib/src/` e verifica a ausência do import de barril, em vez de depender de regra de lint custom.

- **Por quê:** roda na mesma suíte (`flutter test`), não exige plugin de lint, e dá mensagem clara apontando o arquivo infrator. Torna a disciplina executável e versionada.
- **Alternativa considerada:** regra de `custom_lint`/`analysis_options` — mais cerimônia e dependência adicional para um invariante simples.

### Decisão 4: Verificação de equivalência por análise estática + suíte existente

A garantia de "comportamento preservado" se apoia em `flutter analyze` (zero erros/warnings) e na suíte de testes atual passando, além da inspeção de que a superfície do barril não mudou.

- **Por quê:** troca de import não altera semântica; o risco real (ciclo de import acidental, símbolo não resolvido) é exatamente o que o analyzer e os testes capturam.

## Risks / Trade-offs

- **[Ciclo de import acidental entre arquivos]** → Dart tolera imports cíclicos entre arquivos (não entre `part`); ainda assim, `flutter analyze` e os testes validam que tudo resolve. Mitigação: rodar analyze após cada lote de arquivos.
- **[Símbolo ambíguo após remover o barril]** (dois símbolos com mesmo nome de áreas diferentes) → improvável dado o mapa; se ocorrer, usar import com `show`/prefixo no arquivo específico.
- **[Falsa sensação de desacoplamento]** → o change torna o grafo visível mas NÃO corta os acoplamentos legítimos (route_builder, Modular). O design deixa explícito que isso é o passo B, para não criar expectativa equivocada.
- **[Guarda frágil a formatação]** → a varredura deve casar o import independente de espaços/aspas; cobrir com cenário de teste positivo e negativo.

## Migration Plan

1. Ajustar os imports em lotes por área (DI → events → extensions → widgets → manager → routing), rodando `flutter analyze` entre os lotes.
2. Remover o import morto de `routing/shell_modular_route.dart`.
3. Adicionar o teste de guarda e confirmar que passa no estado final e falha ao reintroduzir um barril (teste do próprio teste).
4. Rodar `flutter analyze` e `flutter test` completos.
5. Rollback trivial: reverter os imports (mudança isolada, sem efeito em lógica).

## Achados durante a implementação (passo C)

Itens descobertos ao aplicar e validados por `flutter analyze`/suíte — insumo direto para o passo B:

- **`internal/asserts/go_router_modular_configure_assert.dart` era falso-positivo**: o `import` do barril estava dentro da string de exemplo do assert (texto mostrado ao desenvolvedor), não era diretiva real. A guarda foi desenhada para inspecionar apenas o bloco de diretivas no topo do arquivo, ignorando texto em strings.
- **`routing/shell_modular_route.dart` não era "import morto"**: usa `ModularRoute` (mesma área) e `GoRouterState` (go_router). Trocado por `routing/i_modular_route.dart` + `go_router`, não removido.
- **`widgets/parent_widget_observer.dart` não usava `Modular`**: só `Module`. O mapa cruzado superestimou por casar texto; o analyzer confirmou o import supérfluo.
- **Dependências cruzadas reais confirmadas para o passo B**: `route_builder.dart` permanece como maior concentrador (core/config `Modular`+`RouteWithCompleterService`, core/manager `InjectionManager`, core/module, exceptions, widgets×3, e 6 arquivos siblings de routing). O façade `Modular` e o serviço `RouteWithCompleterService` continuam embutidos no god-config `core/config/go_router_modular_configure.dart` e alcançados por routing/extensions/widgets — alvos do passo B.
- **Confirmação para o micropackage de DI**: `di/injector.dart` resolveu com dependência única em `core/bind/bind.dart`; `core/manager/injection_manager.dart` depende de `core/bind` + `core/module` + `di` + `internal/setup` — fronteira de DI próxima de zero-dependência de Flutter/routing.

## Open Questions

- A guarda deve também proibir imports relativos `../` em `lib/src/` (padronização total para `package:.../src/...`), ou isso fica como ajuste oportunístico fora do invariante principal?
- Vale já introduzir barris por subsistema (ex.: `di.dart` interno) neste change, ou manter estritamente mecânico e deixar barris para o passo A? (Recomendação atual: deixar para o A.)
