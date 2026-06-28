## ADDED Requirements

### Requirement: Detecção de dependência circular entre tipos distintos

O sistema SHALL detectar dependência circular durante a resolução. Enquanto um tipo `T` está sendo construído, se a construção de outro tipo solicitar `T` de volta (ciclo real), o sistema MUST lançar `ModularException` com mensagem que descreve a cadeia de dependência detectada, em vez de entrar em recursão infinita.

Arquivos de referência: `lib/src/core/bind/bind_locator.dart`, `lib/src/core/bind/bind_search_protection.dart`, `lib/src/exceptions/exception.dart`.

#### Scenario: Ciclo A→B→A é interrompido com exceção

- **WHEN** `A` depende de `B` e `B` depende de `A`, e `get<A>()` é chamado
- **THEN** o sistema lança `ModularException`
- **AND** a mensagem descreve a cadeia de dependência circular

### Requirement: Self-reference legítima é permitida

O sistema SHALL permitir que uma `factoryFunction` resolva o próprio tipo que está produzindo quando essa resolução pode ser satisfeita por um bind alternativo (self-reference legítima, ex.: `addFactory<Interface>((injector) => injector.get())`). Nesse caso, o sistema MUST liberar o bypass apenas para a invocação mais recente que está produzindo aquele tipo, e MUST NOT confundir esse caso com um ciclo real.

Arquivos de referência: `lib/src/core/bind/bind_locator.dart`, `lib/src/core/bind/bind_search_protection.dart`.

#### Scenario: Factory que resolve o próprio tipo via bind alternativo

- **WHEN** um bind de `Interface` resolve `injector.get<Interface>()` e existe um bind concreto compatível disponível
- **THEN** o sistema permite o bypass para a invocação mais recente
- **AND** a resolução conclui sem disparar erro de dependência circular

### Requirement: Limite de tentativas de busca como salvaguarda

O sistema SHALL contar as tentativas de busca por tipo (`searchAttempts`). Ao exceder o limite máximo de tentativas para o mesmo tipo, o sistema MUST limpar o estado de busca e lançar `ModularException`, evitando laços que escapem da detecção baseada em pilha.

Arquivos de referência: `lib/src/core/bind/bind_locator.dart`, `lib/src/core/bind/bind_search_protection.dart`.

#### Scenario: Excesso de tentativas aborta a busca

- **WHEN** a resolução do mesmo tipo é tentada além do limite máximo permitido
- **THEN** o sistema limpa o estado de busca
- **AND** lança `ModularException`

### Requirement: Bloqueio de factory durante sua própria execução

O sistema SHALL marcar um `Bind` como bloqueado enquanto sua `factoryFunction` está em execução, usando um contador por identidade do bind que suporta aninhamento (`pushInvocation` incrementa, `popInvocation` decrementa). Durante a execução, a busca por tipo MUST pular o bind bloqueado, permitindo que uma resolução do mesmo tipo encontre um bind alternativo em vez de reentrar na mesma factory.

Arquivos de referência: `lib/src/core/bind/bind_search_protection.dart`, `lib/src/core/bind/bind_locator.dart`.

#### Scenario: Bind bloqueado é ignorado pela busca por tipo

- **WHEN** a `factoryFunction` de um bind está em execução e solicita o mesmo tipo
- **THEN** a busca por tipo ignora o bind atualmente bloqueado
- **AND** o contador de bloqueio retorna a zero somente após o término da factory

#### Scenario: Aninhamento de invocações preserva o bloqueio

- **WHEN** o mesmo bind é empilhado em duas invocações aninhadas e uma delas é desempilhada
- **THEN** o bind permanece bloqueado até a segunda invocação ser desempilhada

### Requirement: Propagação de cache entre binds duplicados de módulos importados

O sistema SHALL preservar a identidade de singletons quando um módulo é importado por outro. Como a coleta de imports reexecuta `module.binds`, criando novos objetos `Bind` com cache vazio para o mesmo tipo, o commit do batch MUST propagar a instância já cacheada do bind canônico para os binds duplicados, evitando dupla instanciação do singleton.

Arquivos de referência: `lib/src/core/bind/bind_registry.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Singleton de módulo importado não é instanciado duas vezes

- **WHEN** um `AppModule` registra `addSingleton<Logger>(...)` e um módulo de rota importa o `AppModule`
- **THEN** o `Logger` é instanciado uma única vez
- **AND** o bind duplicado criado pela importação recebe a mesma instância cacheada (identidade preservada)
