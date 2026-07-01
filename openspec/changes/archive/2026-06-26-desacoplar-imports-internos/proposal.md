## Why

Doze dos 45 arquivos internos de `lib/src/` importam o **barril público inteiro** (`package:go_router_modular/go_router_modular.dart`) em vez das dependências que realmente usam. Isso cria um emaranhado (hairball) oculto: arquivos de baixíssimo nível como `di/injector.dart` e `core/manager/bind_context_tracker.dart` passam a depender, transitivamente, de **todo** o pacote (routing, widgets, events, config). O grafo de dependências parece raso só porque o acoplamento está escondido atrás de um único import. Convivem ainda três estilos de import inconsistentes (54 absolutos `package:.../src/`, 12 barril completo, 6 relativos `../`).

Substituir os imports de barril por imports específicos é uma mudança mecânica e comportamento-preservado, mas de alto valor: ela **revela o grafo real de dependências** (pré-requisito para os próximos passos de desacoplamento), aproxima o subsistema de DI de ser autossuficiente — habilitando a futura extração do micropackage `extract-modular-di-package` — e estabelece uma disciplina de import que evita a regressão do emaranhado. É o passo "C" da sequência de refatoração discutida (C → B → A): tornar o acoplamento visível antes de cortá-lo.

## What Changes

- Substituir, nos 12 arquivos internos, o import do barril público pelos imports específicos dos arquivos efetivamente usados (mapa de origem→destino já levantado).
- Remover o import supérfluo em `routing/shell_modular_route.dart`, que não usa nenhum símbolo do pacote.
- Padronizar o estilo de import interno para caminhos `package:go_router_modular/src/...` específicos (eliminando o uso do barril dentro de `lib/src/`).
- Adicionar uma guarda automatizada (teste) que falha se qualquer arquivo sob `lib/src/` voltar a importar o barril público, fixando a disciplina.
- Registrar, como subproduto, o grafo real de dependências revelado (insumo para o passo B — desacoplar `route_builder` e o façade `Modular`/`RouteWithCompleterService`).
- **Sem mudança de comportamento**: nenhuma API pública é alterada, adicionada ou removida; nenhuma lógica muda. Apenas a forma como os arquivos internos declaram suas dependências.

Justificativa SOLID/Clean Code: o import de barril dentro do pacote viola a **Inversão/Direção de Dependências** (um módulo de base passa a depender do topo) e o **Interface Segregation** (cada arquivo passa a "ver" toda a superfície pública em vez do mínimo necessário). Imports específicos restauram dependências explícitas e mínimas (Clean Code: dependências reveladas, nada de acoplamento implícito).

## Capabilities

### New Capabilities
- `internal-import-discipline`: A disciplina de dependências internas do pacote — arquivos sob `lib/src/` dependem explicitamente dos arquivos específicos que usam, nunca do barril público, e o subsistema de DI permanece com dependências mínimas. Inclui a guarda automatizada que previne regressão.

### Modified Capabilities
<!-- Nenhuma capability de comportamento existente muda. As specs de DI, roteamento, module e eventos continuam válidas — esta mudança preserva comportamento e só ajusta a forma dos imports internos. -->

## Impact

- **Código de produção**: 12 arquivos em `lib/src/` têm seus imports ajustados (nenhuma outra linha muda). Lista exata na seção de tarefas.
- **Testes**: novo teste de arquitetura/guarda em `test/` que varre `lib/src/` e falha diante de import de barril.
- **Comportamento**: nenhum. A superfície pública exportada por `lib/go_router_modular.dart` é idêntica.
- **Habilitação futura**: aproxima a fronteira `di/` de zero-dependência (insumo direto para `extract-modular-di-package`) e fornece o grafo real para o passo B.
- **Riscos**: baixos — risco principal é introduzir um ciclo de import entre arquivos ao trocar o barril por imports diretos; Dart tolera imports cíclicos entre arquivos, mas isso é validado por `flutter analyze` e pela suíte de testes.

## Não-objetivos

- Não mover arquivos nem reorganizar pastas (isso é o passo A — reorganização por subsistema).
- Não quebrar o ciclo `module ⇄ routing` nem desacoplar `route_builder`/`Modular`/`RouteWithCompleterService` (isso é o passo B). Aqui apenas o tornamos visível.
- Não extrair o micropackage de DI (isso é `extract-modular-di-package`); apenas habilitar essa extração.
- Não alterar a superfície pública nem o conteúdo do barril `lib/go_router_modular.dart` (consumidores externos continuam usando o barril normalmente).
- Não refatorar lógica, renomear símbolos nem mudar comportamento de qualquer peça.
