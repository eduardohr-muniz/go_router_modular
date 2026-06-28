# Escopo de Binds por Módulo

## Purpose

Validação de escopo de binds por módulo no registro (commit-time): o AppModule (e seus imports) é o único escopo global; qualquer outro módulo só pode depender de binds que ele mesmo injetou ou importou. Violação lança no push. A resolução estática (Modular.get/Bind.get/context.read) permanece global — brecha consciente.

## Requirements

### Requirement: Conjunto visível de um módulo

O sistema SHALL definir o conjunto de binds visível a um módulo M como a união dos binds que M injetou, dos binds que M importou e dos binds do `AppModule` (incluindo os imports do `AppModule`). O `AppModule` MUST ser o único escopo global, acessível por todos os módulos.

Arquivos de referência: `lib/src/di/bind_context_tracker.dart`, `lib/src/di/injection_manager.dart`.

#### Scenario: Conjunto visível inclui próprios, importados e AppModule

- **WHEN** um módulo M injeta o bind `X`, importa o módulo A (que injeta `Y`), e o `AppModule` injeta `G`
- **THEN** o conjunto visível de M contém `X`, `Y` e `G`

### Requirement: Validação de escopo no registro do módulo (commit-time)

O sistema SHALL validar, ao registrar um módulo M, que cada bind **declarado por M** resolve suas dependências diretas dentro do conjunto visível de M. A validação MUST ocorrer de forma síncrona ao final do registro (no momento do `push`/entrada da rota), e MUST lançar `ModularException` quando um bind de M depende de um bind fora do escopo de M — mesmo que esse bind exista e esteja vivo no container por pertencer a outro módulo não importado.

A mensagem MUST identificar o módulo solicitante, o tipo dependido e a correção sugerida (importar o módulo dono ou injetar o bind em M).

Arquivos de referência: `lib/src/di/injection_manager.dart`, `lib/src/di/injector.dart`, `lib/src/shared/exception.dart`.

#### Scenario: Bind do módulo depende de tipo fora do escopo

- **WHEN** `ModuleA` injeta `ServiceA` e `ServiceB`; `ModuleB` (que não importa `ModuleA` nem injeta `ServiceB`) declara um bind cuja factory faz `i.get<ServiceB>()`; e a navegação entra em `ModuleB` (push, com `ModuleA` ainda vivo)
- **THEN** o registro de `ModuleB` lança `ModularException`
- **AND** a mensagem orienta importar `ModuleA` ou injetar `ServiceB` em `ModuleB`

#### Scenario: Dependências dentro do escopo registram normalmente

- **WHEN** um bind de M depende apenas de binds próprios de M, de binds importados por M, ou de binds do `AppModule`
- **THEN** o registro de M conclui sem erro

#### Scenario: Falha de escopo é fail-fast no registro

- **WHEN** a violação de escopo ocorre
- **THEN** o erro é lançado no registro do módulo (entrada da rota), não tardiamente

### Requirement: Resolução estática permanece global (brecha consciente)

O sistema SHALL manter a resolução estática `Modular.get<T>()` / `Bind.get<T>()` e `context.read<T>()` como **global** (sem enforcement de escopo em runtime). Essa é uma brecha consciente: o uso direto desses pontos para resolver um bind de outro módulo é responsabilidade do desenvolvedor, e NÃO é o caminho idiomático (factories e dependências entre binds são validadas no registro).

Arquivos de referência: `lib/src/bootstrap/go_router_modular_configure.dart`, `lib/src/di/bind.dart`, `lib/src/ui/context_extension.dart`.

#### Scenario: Resolução estática não aplica escopo

- **WHEN** `Modular.get<T>()` é chamado para um bind de qualquer módulo vivo no container
- **THEN** o sistema resolve normalmente (sem checagem de escopo), conforme a brecha documentada
