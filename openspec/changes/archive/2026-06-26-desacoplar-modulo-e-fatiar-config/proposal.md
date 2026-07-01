## Why

Depois do passo C (imports internos desacoplados), o grafo real expôs os dois acoplamentos estruturais que restam:

1. **Ciclo `module ⇄ routing`**: `Module.configureRoutes()` faz duas coisas — registra o `AppModule` (via `InjectionManager`) **e** constrói rotas (via `ModularRouteBuilder`). Isso força `lib/src/core/module/module.dart` a importar `routing/` e `core/manager/`, enquanto `routing/` importa `module.dart` (o `ModuleRoute` guarda um `Module`). É o único ciclo do pacote e a violação de Single Responsibility documentada.

2. **God-config de 472 linhas**: `core/config/go_router_modular_configure.dart` acumula quatro responsabilidades — o façade `Modular`/`Modular`, a composição (`configure`/`copyRouterConfig`), o snapshot imutável `_ModularRouterParams` (+ extension `copyWith`) e o serviço de navegação `RouteWithCompleterService`, além do estado global de transição padrão e do `modularNavigatorKey`. Como `route_builder` lê `Modular.getDefaultTransition` e `RouteWithCompleterService` desse arquivo, mover a orquestração para dentro do façade criaria um novo ciclo `config ⇄ route_builder`.

Este é o passo B (escopo amplo): tornar `Module` um contrato puro movendo a orquestração para um composition root, e fatiar o god-config por responsabilidade, eliminando ambos os ciclos. Habilita o passo A (reorganização por subsistema) e a extração do micropackage de DI, sem alterar comportamento nem a superfície pública.

## What Changes

- Remover `configureRoutes()` de `Module`, deixando-o um contrato puro (apenas `imports`, `binds`, `routes`, `initState`, `dispose`, e a proteção de transição). A orquestração (registrar `AppModule` + construir rotas) passa ao composition root.
- `Modular.configure()` passa a orquestrar diretamente: `InjectionManager.registerAppModule(appModule)` + `ModularRouteBuilder(appModule).buildRoutes(topLevel: true)`.
- `route_builder` passa a construir submódulos com `ModularRouteBuilder(submodulo).buildRoutes(...)` em vez de `submodulo.configureRoutes(...)`.
- Relocar o marcador `ModularRoute` (`i_modular_route.dart`, hoje em `routing/` e folha sem dependências) para um local neutro de contrato, de modo que `module.dart` não dependa da pasta `routing/`.
- Extrair `RouteWithCompleterService` do god-config para um arquivo próprio.
- Extrair o estado de runtime (`defaultTransition`/`getDefaultTransition` e `modularNavigatorKey`) para um holder neutro que `routing/` e `events/` leem sem importar o façade — cortando `config ⇄ route_builder`.
- Extrair `_ModularRouterParams` + a extension `copyWith` para um arquivo próprio.
- Atualizar `lib/go_router_modular.dart` para preservar a superfície pública (mesmos símbolos exportados, ainda que os caminhos dos `export` mudem).
- Adicionar uma guarda automatizada de ausência de ciclos entre as áreas centrais (`module`, `routing`, `config`/bootstrap).
- **Sem mudança de comportamento**: o fluxo observável de `configure`, navegação, registro/descarte e transições permanece idêntico; a superfície pública exportada é preservada.

Justificativa SOLID/Clean Code: remove a dupla responsabilidade de `configureRoutes` (Single Responsibility), inverte corretamente as dependências (composition root conhece todos; subsistemas não se conhecem — Dependency Inversion) e fatia o god-object em arquivos coesos.

## Capabilities

### New Capabilities

- `package-layering`: A disciplina de camadas do pacote — ausência de ciclos entre áreas centrais, `Module` como contrato puro independente de roteamento/manager, composition root como único ponto que conhece todos os subsistemas, e o god-config fatiado por responsabilidade (façade, composição, params, runtime, serviço de completer). Inclui a guarda automatizada contra ciclos.

### Modified Capabilities

<!-- As specs de comportamento (routing-configuration, module-contract, routing-lifecycle, routing-navigation) permanecem válidas: o comportamento observável não muda. A mudança é estrutural. A nota de remoção de Module.configureRoutes é registrada em package-layering, pois configureRoutes era de-facto interno (nenhum consumidor externo o chama). -->

## Impact

- **Código de produção**: `core/module/module.dart` (remove `configureRoutes`), `core/config/go_router_modular_configure.dart` (fatiado em múltiplos arquivos), `routing/route_builder.dart` (deixa de chamar `configureRoutes` e de importar o façade), `routing/i_modular_route.dart` (relocado), e ajustes de import nos consumidores de `RouteWithCompleterService`, do runtime e dos params (`extensions/route_extension.dart`, `events/modular_event.dart`, `widgets/*`).
- **Barril público** `lib/go_router_modular.dart`: caminhos de `export` atualizados; superfície de símbolos preservada.
- **Testes**: nova guarda de ausência de ciclos; a guarda de import de barril (passo C) e a suíte existente continuam válidas.
- **Comportamento**: nenhum. Verificado por `flutter analyze` + suíte + equivalência da superfície pública (símbolos exportados).
- **Habilitação futura**: destrava o passo A (reorganização por subsistema) e aproxima `extract-modular-di-package`.
- **Riscos**: médios — é a mudança mais ampla até aqui; mitigados por fases verificáveis e pela suíte de testes.

## Não-objetivos

- Não reorganizar todas as pastas do pacote por subsistema (isso é o passo A); aqui apenas movemos os arquivos necessários para quebrar os ciclos e fatiar o god-config.
- Não alterar a superfície pública nem o comportamento observável de qualquer API (`Modular.configure`, `Modular.get`, `routerConfig`, navegação, transições permanecem idênticos).
- Não extrair o micropackage de DI (`extract-modular-di-package`); apenas habilitar.
- Não refatorar a lógica interna de resolução de binds, construção de rotas ou eventos — apenas mover responsabilidades entre arquivos e cortar dependências.
- Não introduzir nova dependência externa.
