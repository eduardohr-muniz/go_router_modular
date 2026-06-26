## ADDED Requirements

### Requirement: Navegação assíncrona que aguarda a construção da tela

O sistema SHALL oferecer, via extensions de `BuildContext`, variantes assíncronas de navegação (`goAsync`, `goNamedAsync`, `pushAsync`, `pushNamedAsync`, `pushReplacementAsync`, `pushReplacementNamedAsync`, `replaceAsync`, `replaceNamedAsync`) que registram um completer antes de navegar e completam o `Future` quando a navegação conclui, incluindo o registro de binds da rota de destino. Um callback `onComplete` opcional MUST ser invocado ao concluir.

Arquivos de referência: `lib/src/extensions/route_extension.dart`, `lib/src/routing/route_builder.dart`.

#### Scenario: goNamedAsync conclui após a navegação e registro

- **WHEN** `context.goNamedAsync('perfil')` é aguardado
- **THEN** o `Future` completa após a navegação e o registro de binds da rota de destino
- **AND** o `onComplete`, se fornecido, é invocado

### Requirement: Utilitários de pop por localização e por nome

O sistema SHALL oferecer `popUntil(location)` e `popUntilNamed(routeName)` como utilitários síncronos sobre o `go_router` que removem rotas da pilha até alcançar a localização ou o nome de rota indicado.

Arquivos de referência: `lib/src/extensions/route_extension.dart`.

#### Scenario: popUntil remove rotas até a localização alvo

- **WHEN** a pilha contém várias rotas e `context.popUntil('/home')` é chamado
- **THEN** as rotas são removidas até que a localização atual corresponda a `/home`

### Requirement: Leitura de estado e parâmetros da rota atual

O sistema SHALL oferecer, via extensions de `BuildContext`, acesso ao estado da rota atual: o `GoRouterState` corrente, o path corrente e a leitura de um parâmetro de path por nome.

Arquivos de referência: `lib/src/extensions/route_extension.dart`.

#### Scenario: Leitura de parâmetro de path por nome

- **WHEN** a rota atual é `/usuario/:id` resolvida com `id = "42"` e `context.getPathParam('id')` é chamado
- **THEN** o sistema retorna `"42"`

### Requirement: Açúcar de injeção de dependências por contexto

O sistema SHALL oferecer `context.read<T>()` como atalho de resolução de dependências, delegando à resolução do container de DI (equivalente a `Bind.get<T>()`). Quando o tipo não está registrado, a resolução MUST falhar da mesma forma que a resolução direta do container.

Arquivos de referência: `lib/src/extensions/context_extension.dart`, `lib/src/core/bind/bind.dart`.

#### Scenario: context.read resolve a dependência registrada

- **WHEN** um bind de `MeuServico` está registrado e `context.read<MeuServico>()` é chamado
- **THEN** o sistema retorna a instância resolvida pelo container

#### Scenario: context.read de tipo não registrado falha

- **WHEN** `context.read<TipoInexistente>()` é chamado sem o tipo registrado
- **THEN** a resolução falha com a mesma exceção da resolução direta do container
