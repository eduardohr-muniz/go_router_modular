## ADDED Requirements

### Requirement: Guards são avaliados após o registro de binds e antes da seleção de branch

O sistema SHALL avaliar a função composta dos guards de uma rota dentro do mesmo `redirect` que registra os binds do módulo, executando-a **depois** do registro dos binds e **antes** de qualquer redirect interno de seleção de branch do stateful shell. Isso garante que `Modular.get` dentro de um guard resolva as dependências do módulo, e que um guard que barra impeça a montagem da tela e a seleção da primeira branch.

Arquivos de referência: `lib/src/routing/redirect/module_route_lifecycle.dart`, `lib/src/routing/builders/module_route_builder.dart`, `lib/src/di/injection_manager.dart`.

#### Scenario: Binds são registrados antes de o guard rodar

- **WHEN** a navegação ativa uma rota de módulo cujo guard chama `Modular.get<AuthService>()`
- **THEN** os binds do módulo já foram registrados quando o guard é avaliado
- **AND** a dependência é resolvível dentro do guard

#### Scenario: Guard que barra impede a montagem da tela

- **WHEN** o registro de binds conclui e o guard composto retorna uma rota de redirecionamento
- **THEN** o widget da rota não é construído
- **AND** a navegação segue para a rota retornada pelo guard

#### Scenario: Guard do stateful shell roda antes da seleção da primeira branch

- **WHEN** a rota de um stateful shell é ativada com um guard que retorna uma rota
- **THEN** o redirecionamento do guard é aplicado antes do redirect interno que levaria à primeira branch

#### Scenario: Guard que libera permite o fluxo normal de registro e seleção

- **WHEN** o guard composto retorna `null`
- **THEN** a navegação prossegue normalmente, incluindo a eventual seleção da primeira branch do stateful shell
