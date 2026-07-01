# Ciclo de Vida de Módulos (DI)

## Purpose

Define o ciclo de vida de módulos sobre o container de DI: registro em batch via Injector, rastreamento bidirecional módulo↔bind, descarte automático quando nenhum módulo usa mais o bind, proteção do AppModule e serialização de operações pela fila.

## Requirements

### Requirement: Contrato do módulo

O sistema SHALL definir `Module` como o contrato que agrupa binds, rotas, imports e hooks de ciclo de vida. Um módulo MUST poder declarar `imports()` (módulos dos quais depende), `binds(Injector injector)` (registro de dependências), `routes` (rotas que contribui), `initState(InjectorReader injector)` (hook pós-registro) e `dispose()` (hook pré-descarte).

Arquivos de referência: `lib/src/core/module/module.dart`.

#### Scenario: Módulo declara binds e imports

- **WHEN** um `Module` implementa `binds` registrando dependências e `imports` retornando outros módulos
- **THEN** o registro do módulo torna esses binds e os binds importados resolvíveis

### Requirement: Registro de módulo em batch com coleta de imports

O sistema SHALL registrar um módulo coletando primeiro seus próprios binds (via `startRegistering` / `binds` / `finishRegistering`) e, em seguida, os binds de seus imports recursivamente. O conjunto resultante MUST ser registrado e commitado em batch antes de o hook `initState` ser invocado.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/bind/bind_registry.dart`.

#### Scenario: Imports recursivos são incluídos no registro

- **WHEN** um módulo importa outro que por sua vez importa um terceiro
- **THEN** os binds dos três módulos ficam resolvíveis após o registro
- **AND** `initState` do módulo é chamado somente após o commit do batch

### Requirement: Rastreamento bidirecional módulo↔bind

O sistema SHALL rastrear, em ambas as direções, quais binds cada módulo contribui (`moduleBindTypes`) e quais módulos usam cada bind (contexto do bind), identificando cada bind por `BindIdentifier` (tipo + chave opcional). Esse rastreamento MUST ser a base para decidir o descarte de binds.

Arquivos de referência: `lib/src/core/manager/bind_context_tracker.dart`, `lib/src/di/bind_identifier.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: BindIdentifier distingue binds por tipo e chave

- **WHEN** dois binds do mesmo tipo são registrados, um sem chave e outro com `key: "secundario"`
- **THEN** eles são rastreados como `BindIdentifier` distintos

### Requirement: Descarte de bind quando nenhum módulo o utiliza

O sistema SHALL descartar um bind apenas quando o último módulo que o utiliza for removido. Ao sair de um módulo, para cada bind contribuído, o sistema MUST remover o módulo do contexto do bind e, se nenhum outro módulo usar aquele bind, MUST descartá-lo (acionando o descarte polimórfico da instância).

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/manager/bind_context_tracker.dart`, `lib/src/core/bind/bind_disposer.dart`.

#### Scenario: Bind compartilhado sobrevive enquanto outro módulo o usa

- **WHEN** dois módulos ativos contribuem o mesmo bind e um deles é removido
- **THEN** o bind permanece registrado e resolvível
- **WHEN** o segundo módulo também é removido
- **THEN** o bind é descartado

### Requirement: AppModule nunca é descartado

O sistema SHALL tratar o `AppModule` como módulo raiz permanente. Binds contribuídos pelo `AppModule` MUST NOT ser descartados quando outros módulos saem, e o próprio `AppModule` MUST NOT ser desregistrado.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/manager/bind_context_tracker.dart`.

#### Scenario: Bind do AppModule persiste após saída de módulo de rota

- **WHEN** um bind é contribuído pelo `AppModule` e também por um módulo de rota, e o módulo de rota é removido
- **THEN** o bind permanece registrado por pertencer ao `AppModule`

### Requirement: Serialização de operações de registro e descarte

O sistema SHALL serializar as operações de registro e descarte de módulos através de uma fila (`OperationQueue`), executando-as em ordem para evitar condições de corrida. Uma operação que lance `ModularException` MUST propagar a falha; outras falhas MUST NOT interromper o processamento das operações seguintes.

Arquivos de referência: `lib/src/core/manager/operation_queue.dart`, `lib/src/core/manager/injection_manager.dart`.

#### Scenario: Registro e descarte concorrentes são serializados

- **WHEN** um registro e um descarte de módulos são enfileirados em sequência
- **THEN** eles são executados um após o outro, na ordem de enfileiramento

### Requirement: Reset do container para testes

O sistema SHALL oferecer um reset completo do estado de DI para isolar testes, limpando binds, cache negativo, estado de proteção e rastreamento de módulos. Após o reset, nenhum bind registrado anteriormente MUST permanecer resolvível.

Arquivos de referência: `lib/src/core/manager/injection_manager.dart`, `lib/src/core/bind/bind_disposer.dart`, `lib/src/core/bind/bind_search_protection.dart`.

#### Scenario: Reset limpa o container entre testes

- **WHEN** binds foram registrados e o reset de testes é executado
- **THEN** `tryGet` de qualquer bind anteriormente registrado retorna `null`

### Requirement: Injetor falso e template de binds para testes

O sistema SHALL oferecer ferramentas de teste isoladas do container global: `FakeInjector`, imutável e construído de forma fluente (`add` retorna nova instância), que implementa `InjectorReader` e lança erro específico ao resolver um bind ausente; e `BindTemplate`, uma coleção imutável de receitas de registro reutilizáveis entre testes.

Arquivos de referência: `lib/src/testing/fake_injector.dart`, `lib/src/testing/bind_template.dart`.

#### Scenario: FakeInjector resolve instância adicionada e falha em bind ausente

- **WHEN** um `FakeInjector` recebe `add<MeuServico>(instancia)` e `get<MeuServico>()` é chamado
- **THEN** retorna a instância fornecida
- **WHEN** `get<OutroServico>()` é chamado sem que ele tenha sido adicionado
- **THEN** o sistema lança o erro de bind ausente do injetor falso

### Requirement: Contagem de referências por instância de módulo na pilha

O sistema SHALL contar quantas entradas de rota ativas referenciam cada instância de módulo. O registro dos binds de um módulo MUST ocorrer apenas na primeira referência (transição de 0 para 1); referências subsequentes da mesma instância MUST apenas incrementar a contagem, sem re-registrar. O descarte do módulo (dispose e remoção de binds) MUST ocorrer apenas quando a última referência sai (transição de 1 para 0).

Arquivos de referência: `lib/src/di/injection_manager.dart`, `lib/src/di/bind_context_tracker.dart`.

#### Scenario: Mesma instância empilhada não é descartada no pop intermediário

- **WHEN** a pilha é `A → B → A` (a mesma instância de `A` referenciada duas vezes) e a entrada de cima de `A` sai (pop)
- **THEN** os binds de `A` permanecem registrados e resolvíveis
- **AND** a entrada de baixo de `A` continua funcionando

#### Scenario: Descarte só na última referência

- **WHEN** todas as entradas que referenciam a instância de `A` saem da pilha
- **THEN** `A.dispose()` é chamado e os binds de `A` são descartados
- **AND** o descarte ocorre uma única vez

#### Scenario: Registro efetivo uma única vez para entradas repetidas

- **WHEN** a mesma instância de módulo é referenciada por múltiplas entradas em sequência
- **THEN** a coleta de binds, o commit e o `initState` ocorrem uma única vez (na primeira referência)
- **AND** as referências seguintes apenas incrementam a contagem

### Requirement: Registro e descarte balanceados

O sistema SHALL manter o registro e o descarte de uma instância de módulo balanceados: N referências de entrada correspondem a N decrementos na saída, com o trabalho efetivo de registro e de descarte ocorrendo uma única vez em cada extremo. O contador MUST ser reiniciado pelo reset de testes, e o `AppModule` MUST permanecer nunca descartado independentemente da contagem.

Arquivos de referência: `lib/src/di/injection_manager.dart`.

#### Scenario: Contador não dessincroniza com a proteção de transição

- **WHEN** ocorre uma transição rápida que aciona a proteção `didChangeGoingReference` durante o ciclo de uma instância repetida
- **THEN** a contagem de referências permanece consistente
- **AND** o módulo não é descartado enquanto houver referência ativa

#### Scenario: Reset de testes limpa a contagem

- **WHEN** o reset de testes é executado
- **THEN** as contagens de referência de todos os módulos são zeradas
