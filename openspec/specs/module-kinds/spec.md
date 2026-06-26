# Variedades de Module

## Purpose

Define as variedades de módulo e seus papéis: AppModule (raiz, registrado uma vez, nunca descartado) vs módulos de feature (sob demanda), composição por imports com proteção contra ciclos, e EventModule como extensão orientada a eventos.

## Requirements

### Requirement: AppModule é registrado uma vez e nunca descartado

O sistema SHALL tratar o módulo raiz como `AppModule`: registrado de forma idempotente via `registerAppModule` (uma segunda chamada não re-registra) e nunca descartado. Os binds do `AppModule` MUST persistir por toda a vida do aplicativo, mesmo quando módulos de feature que os compartilham são descartados.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/manager/bind_context_tracker.dart`, `lib/src/core/module/module.dart`.

#### Scenario: Registrar o AppModule duas vezes não re-registra

- **WHEN** `registerAppModule` é chamado para um módulo já definido como `AppModule`
- **THEN** o registro não é repetido

#### Scenario: Tentativa de descartar o AppModule é ignorada

- **WHEN** um descarte é solicitado para o `AppModule`
- **THEN** o módulo e seus binds permanecem registrados

### Requirement: Módulos de feature são registrados sob demanda e descartados ao sair

O sistema SHALL registrar módulos de feature sob demanda, quando sua rota é ativada, e descartá-los quando saem da árvore de rotas. Os hooks `initState` e `dispose` MUST ser invocados a cada ciclo de carga e descarga do módulo.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/routing/route_builder.dart`, `lib/src/core/module/module.dart`.

#### Scenario: Módulo de feature passa por initState ao entrar e dispose ao sair

- **WHEN** a navegação entra na rota de um módulo de feature e depois sai dela
- **THEN** `initState` é invocado na entrada
- **AND** `dispose` é invocado na saída

### Requirement: Bind compartilhado entre módulos só é descartado pelo último consumidor

O sistema SHALL preservar um bind enquanto qualquer módulo ainda o utilizar. Quando um módulo de feature é descartado, um bind também usado por outro módulo (por exemplo, importado pelo `AppModule`) MUST permanecer resolvível; ele só MUST ser descartado quando nenhum módulo o usar mais.

Arquivos de referência: `lib/src/core/manager/bind_context_tracker.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Bind importado pelo AppModule sobrevive ao descarte do módulo de feature

- **WHEN** um módulo de feature compartilha um bind também referenciado pelo `AppModule` e o módulo de feature é descartado
- **THEN** o bind permanece resolvível por continuar em uso pelo `AppModule`

### Requirement: EventModule estende o ciclo de vida com listeners de evento

O sistema SHALL oferecer `EventModule` como extensão de `Module` que inicia os listeners de evento durante `initState`. Os listeners declarados via `eventImports`/`listen` MUST ser ativados quando o módulo é inicializado, integrando-se ao mesmo ciclo de vida de registro/descarte do `Module`.

Arquivos de referência: `lib/src/events/event_module.dart`, `lib/src/core/module/module.dart`.

#### Scenario: EventModule ativa seus listeners ao inicializar

- **WHEN** um `EventModule` que declara listeners é registrado
- **THEN** seus listeners são ativados durante `initState`

### Requirement: Formas idiomáticas de declaração de módulo

O sistema SHALL suportar as formas idiomáticas de declaração de módulo: `AppModule` (apenas binds globais e `ModuleRoute` para features), módulo de feature (com `imports`, `binds`, `routes` incluindo `ChildRoute('/')`, e hooks), módulo com `ShellModularRoute`, módulo com `StatefulShellModularRoute` e `EventModule`. Cada forma MUST seguir as asserções de configuração do contrato do módulo.

Arquivos de referência: `lib/src/core/module/module.dart`, `example/`.

#### Scenario: AppModule declara binds globais e rotas de módulos

- **WHEN** um `AppModule` declara apenas binds globais e `ModuleRoute` para módulos de feature
- **THEN** os binds globais persistem e cada `ModuleRoute` monta seu módulo sob demanda

#### Scenario: Módulo de feature declara rota índice e hooks

- **WHEN** um módulo de feature declara `ChildRoute('/')` como entrada e implementa `initState`/`dispose`
- **THEN** a rota índice serve de entrada e os hooks são executados no ciclo de vida do módulo
