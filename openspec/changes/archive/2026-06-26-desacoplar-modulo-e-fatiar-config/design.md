## Context

Após o passo C, o grafo real revelou dois acoplamentos estruturais:

1. **Ciclo `module ⇄ routing`** — raiz única em `Module.configureRoutes()` (`core/module/module.dart:32-35`):

   ```dart
   List<RouteBase> configureRoutes({String modulePath = '', bool topLevel = false}) {
     InjectionManager.instance.registerAppModule(this);            // registro (DI)
     return ModularRouteBuilder(this).buildRoutes(modulePath: modulePath, topLevel: topLevel); // construção (routing)
   }
   ```

   Isso obriga `module.dart` a importar `routing/route_builder.dart` + `core/manager/injection_manager.dart`; e `routing/*` importa `module.dart` (`ModuleRoute` guarda `Module`). `configureRoutes` é chamado em 4 lugares, todos internos: `configure()` (top-level) e `route_builder` (3 sites, submódulos). Nenhum consumidor externo o chama — é de-facto interno.

2. **God-config** `core/config/go_router_modular_configure.dart` (472 linhas) com 4 responsabilidades: façade `Modular`/`Modular`; composição `configure`/`copyRouterConfig`; `_ModularRouterParams` + extension `copyWith`; e `RouteWithCompleterService`. Mais o estado global `_defaultTransition`/`getDefaultTransition` e `modularNavigatorKey`.

Achados do levantamento (validados por grep/leitura):

- `i_modular_route.dart` (marcador `ModularRoute`) é **folha pura** (zero imports) — relocar é trivial.
- `bind_registry` e `internal/setup` **não** usam o façade (os matches eram a substring `debugLogModular`). Não há inversão de camada a partir de `core/bind`.
- O único acoplamento de `routing` ao façade em código é `route_builder` → `Modular.getDefaultTransition` (4 sites) e `RouteWithCompleterService`. `stateful_shell_modular_route` cita `Modular` só em comentários.

Restrições: pt-BR; sem mudança de comportamento; superfície pública preservada; sem abreviações.

## Goals / Non-Goals

**Goals:**

- Eliminar o ciclo `module ⇄ routing` tornando `Module` um contrato puro e movendo a orquestração para o composition root.
- Eliminar o risco de ciclo `config ⇄ route_builder` extraindo do god-config os pedaços que `routing` consome (completer service + estado de runtime).
- Fatiar o god-config em arquivos coesos por responsabilidade.
- Preservar a superfície pública e o comportamento; adicionar guarda contra ciclos.

**Non-Goals:**

- Não reorganizar todas as pastas por subsistema (passo A).
- Não mudar comportamento observável nem assinaturas públicas.
- Não extrair o micropackage de DI.

## Decisions

### Decisão 1: Estrutura-alvo dos arquivos

```
lib/src/
  bootstrap/
    go_router_modular.dart          ← façade + composition root (Modular/Modular):
                                       configure(), copyRouterConfig(), get/tryGet, routerConfig.
                                       É o ÚNICO que importa module + manager + routing/route_builder + params + runtime.
    modular_router_params.dart      ← _ModularRouterParams + extension ModularRouterConfigCopyWith
    modular_router_runtime.dart     ← holder neutro: defaultTransition (get/set) + modularNavigatorKey
  routing/
    route_with_completer_service.dart ← RouteWithCompleterService (movido do god-config)
    modular_route.dart (marcador)   ← i_modular_route.dart relocado p/ local neutro (ver Decisão 3)
  core/module/module.dart           ← contrato puro, sem configureRoutes
```

- **Por quê:** separa façade/composição (topo) de params (dados) e runtime (estado lido por routing/events). O composition root é o único que conhece todos os subsistemas (Dependency Inversion). Mantém `Modular`/`Modular` como classe única para preservar a API pública (`Modular.configure`, `Modular.get`, etc.).
- **Alternativa considerada:** manter tudo em `core/config/` e só separar classes em arquivos no mesmo diretório — viável, mas `bootstrap/` comunica melhor o papel de composition root. A decisão de diretório final pode ser ajustada na implementação sem afetar o comportamento.

### Decisão 2: Quebra do ciclo via remoção de `configureRoutes`

`Module.configureRoutes` é removido. A orquestração vai para o composition root:

```dart
// em configure(): substitui appModule.configureRoutes(topLevel: true)
InjectionManager.instance.registerAppModule(appModule);
final routes = ModularRouteBuilder(appModule).buildRoutes(topLevel: true);
```

Em `route_builder`, os 3 sites `submodulo.configureRoutes(modulePath: x, topLevel: false)` viram `ModularRouteBuilder(submodulo).buildRoutes(modulePath: x, topLevel: false)`. O `registerAppModule` desses sites era no-op (idempotente, AppModule já setado), então não há perda de comportamento.

- **Por quê:** corta a dependência de `module.dart` para `routing` e `manager` na raiz. `route_builder` já está em `routing`, então construir `ModularRouteBuilder` diretamente é natural.
- **Nota de API:** `configureRoutes` é público no `Module` exportado, mas nenhum consumidor externo o usa (só chamado internamente). Sua remoção é uma mudança de API interna de-facto; registrada como tal. Caso se queira zero-risco de quebra, um shim `@Deprecated` poderia delegar ao composition root — mas isso reintroduziria o import de routing em `module.dart`, recriando o ciclo; portanto a remoção limpa é preferida.

### Decisão 3: Relocar o marcador `ModularRoute`

`i_modular_route.dart` (folha pura) é relocado de `routing/` para um local neutro de contrato, para que `module.dart` (que precisa de `ModularRoute` em `List<ModularRoute> routes`) não dependa da pasta `routing/`.

- **Por quê:** sem isso, `module → routing/i_modular_route.dart` e `routing/route_builder → module` mantêm um ciclo no nível de pasta, ainda que não no nível de dependência real (o marcador é folha). Relocar deixa a fronteira de pasta limpa.
- **Alternativa considerada:** manter o marcador em `routing/` e aceitar que o "ciclo" é só nominal (o grafo de dependências reais já é acíclico, pois o marcador não importa nada). Aceitável se quisermos minimizar movimentação; a guarda de ciclos pode ser definida sobre dependências reais, não pastas. Decisão final pode ficar para a implementação conforme a guarda escolhida.

### Decisão 4: Cortar `config ⇄ route_builder` via holder de runtime + completer service

`route_builder` deixa de importar o façade: passa a ler a transição padrão do `modular_router_runtime.dart` e o `RouteWithCompleterService` do arquivo próprio. `configure()` escreve `defaultTransition`/`modularNavigatorKey` no holder. `events/modular_event.dart` lê `modularNavigatorKey` do holder.

- **Por quê:** é exatamente o acoplamento que impediria mover a orquestração para o façade. Com o estado em um holder neutro, o composition root pode importar `route_builder` sem ciclo.

### Decisão 5: Fases verificáveis

A implementação é faseada para que `apply` possa pausar e verificar entre fases: (1) extrair runtime + completer service + params do god-config; (2) cortar `route_builder` → façade; (3) quebrar o ciclo do `Module`; (4) relocar marcador; (5) atualizar barril + guarda. Cada fase roda `flutter analyze`.

## Risks / Trade-offs

- **[Maior superfície de mudança até aqui]** → Fases pequenas e verificáveis; `flutter analyze` + suíte após cada fase; equivalência da superfície pública por comparação de símbolos exportados.
- **[Remoção de `configureRoutes` quebrar consumidor externo]** → Improvável (nenhum uso fora do pacote); registrado como nota de API. Shim depreciado é possível, mas recriaria o ciclo — por isso evitado.
- **[Mudar caminhos de `export` no barril]** → A verificação compara o conjunto de SÍMBOLOS exportados (não as linhas), garantindo paridade pública mesmo com caminhos novos.
- **[Novo ciclo acidental ao mover arquivos]** → A guarda de ciclos + `flutter analyze` capturam; mover em fases reduz a janela de erro.
- **[`RouteWithCompleterService` ser público]** → Se exportado, manter o símbolo no barril após o move; se interno, apenas ajustar imports dos consumidores.

## Migration Plan

1. **Fase 1 — Extrair do god-config:** criar `modular_router_runtime.dart` (defaultTransition + modularNavigatorKey), `route_with_completer_service.dart` e `modular_router_params.dart`; ajustar imports internos. `flutter analyze`.
2. **Fase 2 — Cortar routing→façade:** `route_builder` e consumidores leem runtime/completer service dos novos arquivos. `flutter analyze`.
3. **Fase 3 — Contrato puro:** remover `configureRoutes` de `Module`; mover orquestração para `configure()`; `route_builder` usa `ModularRouteBuilder(...)` direto. `flutter analyze`.
4. **Fase 4 — Relocar marcador:** mover `ModularRoute` para local neutro; atualizar imports. `flutter analyze`.
5. **Fase 5 — Barril + guarda:** atualizar `lib/go_router_modular.dart` (paridade de símbolos); adicionar guarda de ciclos; `flutter analyze` + `flutter test` completos.
6. Rollback por fase (cada fase é um conjunto isolado de moves/edits).

## Open Questions

- Diretório final do composition root: novo `bootstrap/` ou manter em `core/config/` apenas fatiando arquivos? (Recomendação: `bootstrap/`, mas decidível na implementação.)
- A guarda de ciclos deve operar sobre dependências de arquivo reais (mais preciso) ou sobre pastas (mais simples)? Se sobre dependências reais, relocar o marcador (Decisão 3) torna-se opcional.
- `RouteWithCompleterService` deve permanecer exportado no barril (é usado por `route_extension`, que é público) ou tornar-se estritamente interno? (Verificar uso externo antes de decidir.)
