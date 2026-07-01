## Why

Depois dos passos C (imports internos) e B (quebra de ciclos + fatiamento do god-config), as responsabilidades estão desacopladas, mas a organização de pastas ainda não reflete os subsistemas: o motor de DI está espalhado por quatro diretórios (`core/bind/`, `core/manager/`, `core/dependency_analyzer/`, `di/`), e `core/` virou uma gaveta que junta DI, módulo, config e telemetria sem relação. Isso dificulta navegar pelo código e esconde a fronteira do subsistema de DI — justamente o que precisa estar nítido para a futura extração do micropackage `extract-modular-di-package`.

Este é o passo A: reorganizar `lib/src/` por subsistema, consolidando todo o motor de DI em `di/` e eliminando a pasta `core/`. É uma mudança puramente estrutural (mover arquivos + atualizar imports), comportamento-preservado, viabilizada porque os ciclos já foram eliminados no passo B.

## What Changes

- Consolidar **todo o motor de DI** em `lib/src/di/`: `core/bind/*`, `core/manager/*`, `core/dependency_analyzer/dependency_analyzer.dart` e os arquivos já existentes em `di/`.
- Mover o contrato `Module` para `lib/src/module/module.dart`.
- Mover para `lib/src/routing/` os arquivos de runtime de roteamento extraídos no passo B (`modular_router_runtime.dart`, `modular_router_params.dart`, `route_with_completer_service.dart`), que hoje residem em `core/config/`.
- Criar `lib/src/bootstrap/` para o composition root (`go_router_modular_configure.dart`).
- Unificar `lib/src/widgets/` + `lib/src/extensions/` em `lib/src/ui/`.
- Criar `lib/src/shared/` para utilitários transversais (`exceptions/exception.dart`, `internal/asserts/*`, `internal/internal_logs.dart`, e `internal/setup.dart` — o holder de flags `SetupModular`, que é consumido pelo DI e pelos eventos, portanto pertence a `shared/` e não a `bootstrap/`, para não criar dependência `di → bootstrap`).
- Atualizar todos os imports internos e o barril público `lib/go_router_modular.dart` (e `lib/testing.dart`) para os novos caminhos, preservando a superfície de símbolos exportados.
- Atualizar as guardas existentes (passo C: sem import de barril; passo B: sem ciclos) para os novos caminhos de arquivo.
- **Sem mudança de comportamento**: nenhuma lógica, assinatura pública ou símbolo exportado muda. Apenas a localização dos arquivos e seus imports.

Justificativa SOLID/Clean Code: a estrutura passa a comunicar a arquitetura (subsistemas coesos, fronteiras nítidas), eliminando a gaveta `core/` (que agregava responsabilidades sem relação) e tornando explícita a fronteira do DI.

## Capabilities

### New Capabilities
<!-- Nenhuma capability nova de comportamento. -->

### Modified Capabilities
- `package-layering`: estende a disciplina de camadas com a organização por subsistema — `lib/src/` é estruturado em `di/`, `module/`, `routing/`, `bootstrap/`, `events/`, `ui/`, `shared/` (e `testing/`), sem a pasta `core/`, e o motor de DI fica consolidado em `di/`.

## Impact

- **Código de produção**: movimentação de ~30 arquivos entre pastas; atualização dos `import`/`export` que os referenciam (interno) e do barril público.
- **Barril público** `lib/go_router_modular.dart` e `lib/testing.dart`: caminhos de `export` atualizados; superfície de símbolos preservada.
- **Testes**: as guardas dos passos B e C têm caminhos de arquivo atualizados; a suíte existente continua sendo a verificação de comportamento.
- **Comportamento**: nenhum. Verificado por `flutter analyze` + suíte completa + paridade de símbolos exportados.
- **Habilitação futura**: a fronteira de DI consolidada em `di/` aproxima diretamente o `extract-modular-di-package`.
- **Riscos**: médios-baixos — muita movimentação mecânica, mas sem alteração de lógica; mitigado por fases por subsistema com `flutter analyze` entre elas.

## Não-objetivos

- Não alterar comportamento, assinaturas públicas nem símbolos exportados.
- Não refatorar lógica interna de qualquer subsistema — apenas mover arquivos e ajustar imports.
- Não extrair o micropackage de DI (`extract-modular-di-package`); apenas deixar a fronteira pronta.
- Não introduzir barris por subsistema (arquivos `di.dart`, `routing.dart` internos) salvo se necessário para os imports — a consolidação de pastas é o foco; barris internos podem ser um passo posterior.
- Não mover o diretório `testing/` (já é coeso e exportado por `lib/testing.dart`).
