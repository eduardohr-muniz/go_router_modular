# Injeção de Dependências

## Purpose

Define o comportamento do container de DI do go_router_modular: definição de binds, tipos de bind (singleton eager, singleton lazy e factory), armazenamento dual (por tipo e por chave), resolução com caminho rápido e cache negativo, e descarte polimórfico de instâncias.

## Requirements

### Requirement: Definição de bind como contrato tipo→factory

O sistema SHALL representar cada dependência como um `Bind<T>` que associa um tipo `T` a uma `factoryFunction` do tipo `T Function(Injector injector)`. O `Bind` MUST carregar os atributos que determinam seu ciclo de vida: `isSingleton`, `isLazy`, `key` opcional e a `stackTrace` de criação para diagnóstico. O `Bind` MUST expor seu `type` sem instanciar a dependência.

Arquivos de referência: `lib/src/core/bind/bind.dart`.

#### Scenario: Bind preserva o tipo declarado sem instanciar

- **WHEN** um `Bind<MeuServico>` é criado com uma `factoryFunction`
- **THEN** `bind.type` retorna `MeuServico`
- **AND** a `factoryFunction` não é invocada apenas por consultar o `type`

#### Scenario: Bind guarda a stack trace de criação

- **WHEN** um `Bind` é construído
- **THEN** sua `stackTrace` referencia o local de criação para mensagens de diagnóstico

### Requirement: Tipo de bind singleton eager

O sistema SHALL suportar singletons eager criados por `Bind.singleton` / `Injector.addSingleton`, com `isSingleton = true` e `isLazy = false`. A instância MUST ser criada uma única vez durante o commit do batch e MUST ser reutilizada em todas as resoluções subsequentes, preservando a identidade do objeto.

Arquivos de referência: `lib/src/core/bind/bind.dart`, `lib/src/core/bind/bind_registry.dart`, `lib/src/di/injector.dart`.

#### Scenario: Singleton eager é instanciado no commit e reutilizado

- **WHEN** um módulo registra `addSingleton<MeuServico>((injector) => MeuServico())` e o batch é commitado
- **THEN** a `factoryFunction` é invocada exatamente uma vez durante o commit
- **AND** toda chamada `Injector().get<MeuServico>()` retorna a mesma instância (identidade preservada)

### Requirement: Tipo de bind singleton lazy

O sistema SHALL suportar singletons lazy criados por `Bind.lazySingleton` / `Injector.addLazySingleton`, com `isSingleton = true` e `isLazy = true`. A `factoryFunction` MUST NOT ser invocada no commit; ela MUST ser invocada apenas na primeira resolução e o resultado MUST ser cacheado e reutilizado nas resoluções seguintes.

Arquivos de referência: `lib/src/core/bind/bind.dart`, `lib/src/core/bind/bind_locator.dart`, `lib/src/di/injector.dart`.

#### Scenario: Singleton lazy só instancia na primeira resolução

- **WHEN** um módulo registra `addLazySingleton<MeuRepositorio>((injector) => MeuRepositorio())` e o batch é commitado
- **THEN** a `factoryFunction` ainda não foi invocada
- **WHEN** ocorre a primeira chamada `Injector().get<MeuRepositorio>()`
- **THEN** a `factoryFunction` é invocada e a instância é cacheada
- **AND** a segunda chamada `get` retorna a mesma instância sem invocar a `factoryFunction` novamente

### Requirement: Tipo de bind factory (transiente)

O sistema SHALL suportar binds factory criados por `Bind.add` / `Injector.addFactory` / `Injector.add`, com `isSingleton = false`. Cada resolução MUST invocar a `factoryFunction` e retornar uma nova instância, sem cache.

Arquivos de referência: `lib/src/core/bind/bind.dart`, `lib/src/core/bind/bind_locator.dart`, `lib/src/di/injector.dart`.

#### Scenario: Factory cria nova instância a cada resolução

- **WHEN** um módulo registra `addFactory<MeuController>((injector) => MeuController())`
- **THEN** duas chamadas `Injector().get<MeuController>()` retornam instâncias distintas (identidades diferentes)

### Requirement: Registro de binds por meio do Injector em modo batch

O sistema SHALL permitir que um módulo registre binds através do `Injector` em modo de registro. `Injector.startRegistering` MUST ativar o modo, os métodos `addSingleton`, `addLazySingleton`, `addFactory` e `add` MUST acumular binds, e `finishRegistering` MUST retornar a lista coletada e desativar o modo. Chamar um método de registro fora do modo batch MUST lançar `StateError`.

Arquivos de referência: `lib/src/di/injector.dart`.

#### Scenario: Coleta de binds em modo batch

- **WHEN** `startRegistering` é chamado, seguido de `addSingleton<A>(...)` e `addFactory<B>(...)`, e então `finishRegistering`
- **THEN** `finishRegistering` retorna a lista contendo os dois binds
- **AND** o modo de registro é desativado

#### Scenario: Registro fora do modo batch é rejeitado

- **WHEN** `addSingleton<A>(...)` é chamado sem `startRegistering` anterior
- **THEN** o sistema lança `StateError`

### Requirement: Armazenamento dual por tipo e por chave

O sistema SHALL armazenar binds em duas estruturas: um mapa por tipo (`bindsMap`) para binds sem chave e um mapa por chave (`bindsMapByKey`) para binds nomeados. Um mesmo bind MUST NOT ocupar as duas estruturas simultaneamente: binds sem chave vivem em `bindsMap`, binds com `key` vivem em `bindsMapByKey`.

Arquivos de referência: `lib/src/core/bind/bind_storage.dart`, `lib/src/core/bind/bind_registry.dart`.

#### Scenario: Bind sem chave é indexado por tipo

- **WHEN** um `Bind<MeuServico>` sem `key` é registrado
- **THEN** ele é localizável por `get<MeuServico>()`
- **AND** não aparece no mapa por chave

#### Scenario: Bind com chave é indexado por chave

- **WHEN** um `Bind<MeuServico>` com `key: "primario"` é registrado
- **THEN** ele é localizável por `get<MeuServico>(key: "primario")`
- **AND** não ocupa o slot do tipo no mapa por tipo

### Requirement: Resolução de bind via get com caminho rápido

O sistema SHALL resolver dependências por `Injector.get<T>({String? key})`, delegando a `Bind.get` e ao `BindLocator`. Quando não houver factory em execução, a busca for por tipo sem chave e existir um singleton já cacheado, o sistema MUST retornar a instância cacheada pelo caminho rápido, sem percorrer as estratégias completas de busca.

Arquivos de referência: `lib/src/di/injector.dart`, `lib/src/core/bind/bind.dart`, `lib/src/core/bind/bind_locator.dart`.

#### Scenario: Resolução de singleton cacheado usa caminho rápido

- **WHEN** um singleton já foi instanciado e `get<MeuServico>()` é chamado sem chave e sem factory em execução
- **THEN** o sistema retorna a instância cacheada diretamente

### Requirement: Cache negativo para tipos não registrados

O sistema SHALL manter um cache negativo (`negativeLookupCache`) com os tipos confirmadamente não encontrados após esgotar todas as estratégias de busca. Resoluções subsequentes do mesmo tipo MUST falhar imediatamente sem repetir a busca. O cache negativo MUST ser invalidado sempre que binds forem adicionados ou removidos, evitando falsos negativos.

Arquivos de referência: `lib/src/core/bind/bind_storage.dart`, `lib/src/core/bind/bind_locator.dart`, `lib/src/core/bind/bind_registry.dart`, `lib/src/core/bind/bind_disposer.dart`.

#### Scenario: Tipo ausente é memorizado como negativo

- **WHEN** `get<TipoInexistente>()` falha após esgotar as estratégias
- **THEN** o tipo é adicionado ao cache negativo
- **AND** a próxima chamada `get<TipoInexistente>()` falha imediatamente sem repetir a busca

#### Scenario: Registro de novo bind invalida o cache negativo

- **WHEN** um tipo está no cache negativo e um novo bind é registrado
- **THEN** o cache negativo é limpo
- **AND** uma resolução posterior reexecuta as estratégias de busca

### Requirement: Resolução de bind nomeado por chave

O sistema SHALL resolver binds nomeados quando `get<T>(key: ...)` for chamado, buscando primeiro no mapa por chave. Quando o `key` não corresponder a nenhum bind registrado, o sistema MUST falhar com exceção de bind não encontrado.

Arquivos de referência: `lib/src/core/bind/bind_locator.dart`.

#### Scenario: Resolução por chave existente

- **WHEN** existe um bind registrado com `key: "secundario"` e `get<MeuServico>(key: "secundario")` é chamado
- **THEN** o sistema retorna a instância correspondente à chave

### Requirement: Resolução tolerante com tryGet e verificação com isRegistered

O sistema SHALL oferecer `tryGet<T>({String? key})` que retorna a instância ou `null` em vez de lançar, e `isRegistered<T>({String? key})` que indica se o tipo está registrado sem invocar a `factoryFunction`.

Arquivos de referência: `lib/src/core/bind/bind.dart`, `lib/src/core/bind/bind_locator.dart`.

#### Scenario: tryGet retorna null para tipo ausente

- **WHEN** `tryGet<TipoInexistente>()` é chamado
- **THEN** o sistema retorna `null` sem lançar exceção

#### Scenario: isRegistered não instancia o bind

- **WHEN** existe um singleton lazy ainda não resolvido e `isRegistered<MeuRepositorio>()` é chamado
- **THEN** o sistema retorna `true`
- **AND** a `factoryFunction` do bind não é invocada

### Requirement: Exceção clara ao resolver bind não encontrado

O sistema SHALL lançar `ModularException` quando uma resolução obrigatória (`get`) não encontrar o bind solicitado, com mensagem que identifica o tipo requisitado.

Arquivos de referência: `lib/src/core/bind/bind_locator.dart`, `lib/src/exceptions/exception.dart`.

#### Scenario: get de tipo inexistente lança exceção informativa

- **WHEN** `get<TipoInexistente>()` é chamado e nenhuma estratégia encontra o bind
- **THEN** o sistema lança `ModularException`
- **AND** a mensagem identifica o tipo `TipoInexistente`

### Requirement: Descarte polimórfico de instâncias

O sistema SHALL descartar a instância cacheada de um bind ao removê-lo, tentando, na ordem, os métodos de limpeza idiomáticos: `dispose()` (ex.: `ChangeNotifier`), depois `close()` (ex.: `Bloc`, `StreamController`) e depois `cancel()` (ex.: `Timer`, `StreamSubscription`). A ausência de um desses métodos na instância MUST ser ignorada silenciosamente, sem propagar `NoSuchMethodError`. Após a tentativa de limpeza, o cache do bind MUST ser zerado.

Arquivos de referência: `lib/src/di/clean_bind.dart`, `lib/src/core/bind/bind_disposer.dart`.

#### Scenario: Instância com dispose é limpa ao descartar

- **WHEN** um bind cujo objeto é um `ChangeNotifier` é descartado
- **THEN** o sistema chama `dispose()` na instância
- **AND** o cache do bind é zerado

#### Scenario: Instância sem método de limpeza é descartada sem erro

- **WHEN** um bind cujo objeto não possui `dispose`, `close` nem `cancel` é descartado
- **THEN** o sistema não lança `NoSuchMethodError`
- **AND** o cache do bind é zerado
