## ADDED Requirements

### Requirement: Registro de binds do módulo ao entrar na rota

O sistema SHALL registrar os binds de um módulo quando sua rota é ativada, executando o registro dentro do `redirect` do `GoRoute` correspondente ao `ModuleRoute` (ou shell de módulo). O registro MUST ocorrer antes de o widget da rota ser construído, garantindo que as dependências do módulo estejam resolvíveis quando a tela montar.

Arquivos de referência: `lib/src/routing/route_builder.dart`, `lib/src/core/manager/injection_manager.dart`, `lib/src/core/module/module.dart`.

#### Scenario: Entrar numa rota de módulo registra seus binds

- **WHEN** a navegação ativa uma rota de `ModuleRoute`
- **THEN** o `redirect` registra os binds do módulo (diretos e importados) antes de a tela ser construída
- **AND** uma dependência declarada pelo módulo é resolvível dentro do widget da rota

#### Scenario: Reentrar num módulo já ativo não registra novamente

- **WHEN** a navegação ativa uma sub-rota de um módulo cujos binds já estão registrados
- **THEN** o registro não é repetido para esse módulo

### Requirement: Loader durante o registro de binds

O sistema SHALL exibir o `ModularLoader` enquanto o registro de binds de uma rota está em andamento, e ocultá-lo ao concluir. O loader MUST NOT ser exibido quando o registro ocorre no contexto de uma navegação que já gerencia sua própria sinalização de conclusão (navegação assíncrona com completer pendente).

Arquivos de referência: `lib/src/routing/route_builder.dart`, `lib/src/widgets/modular_loader.dart`.

#### Scenario: Registro síncrono de rota mostra e esconde o loader

- **WHEN** o registro de binds de uma rota inicia sem completer pendente
- **THEN** o `ModularLoader` é exibido durante o registro
- **AND** é ocultado ao final do registro, mesmo em caso de erro

#### Scenario: Navegação assíncrona com completer não exibe o loader automático

- **WHEN** o registro ocorre durante uma navegação assíncrona com completer pendente
- **THEN** o `ModularLoader` automático não é exibido

### Requirement: Descarte do módulo ao sair da rota

O sistema SHALL descartar um módulo quando o widget da sua rota é desmontado, usando o `ParentWidgetObserver` para disparar o descarte no `dispose` do widget. O descarte MUST acionar o `dispose` do módulo e a remoção dos seus binds (respeitando o compartilhamento entre módulos e a proteção do AppModule descrita na spec de DI).

Arquivos de referência: `lib/src/widgets/parent_widget_observer.dart`, `lib/src/routing/route_builder.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Sair da rota desmonta o observer e descarta o módulo

- **WHEN** o widget de uma rota de módulo é removido da árvore
- **THEN** o `ParentWidgetObserver.dispose` dispara o descarte do módulo
- **AND** os binds exclusivos do módulo são descartados

### Requirement: Proteção contra descarte prematuro em transição rápida

O sistema SHALL proteger um módulo contra descarte prematuro durante transições rápidas. Quando `didChangeDependencies` sinaliza que o módulo está em transição (`onDidChangeGoingReference`), o descarte disparado por um `dispose` concorrente MUST ser ignorado para aquele módulo até a marca de transição expirar (no microtask seguinte).

Arquivos de referência: `lib/src/core/module/module.dart`, `lib/src/routing/route_builder.dart`, `lib/src/widgets/parent_widget_observer.dart`.

#### Scenario: Módulo em transição não é descartado pelo dispose concorrente

- **WHEN** um módulo é marcado como em transição e um `dispose` concorrente tenta descartá-lo
- **THEN** o descarte é ignorado enquanto a marca de transição estiver ativa
- **AND** o módulo permanece registrado após a transição

### Requirement: Descarte em cascata das branches de shell stateful

O sistema SHALL descartar, em cascata, todos os módulos das branches de um `StatefulShellModularRoute` quando o shell stateful é removido da árvore. Cada módulo de branch que não estiver em transição MUST ser descartado, e o próprio módulo do shell MUST ser descartado em seguida.

Arquivos de referência: `lib/src/routing/route_builder.dart`, `lib/src/widgets/parent_widget_observer.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Remover o shell stateful descarta as branches ativas

- **WHEN** um `StatefulShellModularRoute` com múltiplas branches ativas é removido
- **THEN** cada módulo de branch não em transição é descartado
- **AND** o módulo do shell é descartado por último

### Requirement: OnceBuilder evita reinstanciar dependências no rebuild

O sistema SHALL construir o widget de uma rota através de um `OnceBuilder`, que executa a closure de construção uma única vez e cacheia o resultado. Isso MUST evitar que rebuilds internos do `go_router` reexecutem a closure e criem novas instâncias de binds factory resolvidos dentro dela.

Arquivos de referência: `lib/src/widgets/once_builder.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: Closure de build é executada uma única vez

- **WHEN** o widget de uma rota envolto por `OnceBuilder` é reconstruído pelo `go_router`
- **THEN** a closure de construção não é reexecutada
- **AND** um bind factory resolvido dentro dela não gera nova instância a cada rebuild
