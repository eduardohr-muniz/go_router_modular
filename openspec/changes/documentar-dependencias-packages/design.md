## Context

O `go_router_modular` é um pacote Dart/Flutter que adiciona DI modular, roteamento por módulos e comunicação por eventos sobre o `go_router`. Seu `pubspec.yaml` declara seis dependências de runtime e duas de desenvolvimento, mas o propósito de cada uma — e quais ainda estão vivas no código — nunca foi documentado.

Uma auditoria do `lib/` (grep de imports + leitura dos pontos de uso) revelou três classes de dependência:

- **Ativas e estruturais:** `event_bus` (base do sistema de eventos), `go_router` (motor de roteamento encapsulado), `go_transitions` (transições de página e de branches).
- **Framework/ferramentas:** `flutter` (SDK de UI), `flutter_test` e `flutter_lints` (qualidade/desenvolvimento).
- **Órfãs:** `web` e `flutter_web_plugins` — declaradas em `dependencies`, sem nenhum import em `lib/`. O histórico Git mostra que foram adicionadas para `web_channel.dart`/`BrowserReplaceObserver` (commit `2dec3f5`) e ficaram sem uso após esse recurso ser removido (commit `d6626c6`).

Esta mudança documenta esse mapa como especificação executável, sem tocar no `pubspec.yaml` nem no código.

## Goals / Non-Goals

**Goals:**

- Catalogar, de forma verificável, cada dependência declarada: o que é consumido, onde, o papel arquitetural e o impacto de sua ausência.
- Tornar explícito o estado de uso de cada dependência (ativa vs. órfã) com base em evidência do código e do histórico Git.
- Ligar cada dependência ativa à capability do pacote que a consome, sem duplicar o comportamento já documentado nessas specs.

**Non-Goals:**

- Não alterar o `pubspec.yaml` (versões, remoções, adições) nem qualquer arquivo em `lib/`.
- Não remover as dependências órfãs — apenas registrá-las; a limpeza é decisão futura.
- Não catalogar dependências transitivas.
- Não reescrever a documentação de eventos, roteamento ou DI.

## Decisions

### Decisão 1: Uma única capability com um requisito por dependência

Optou-se por `package-dependencies` como capability única, com um `### Requirement` por package (ou grupo de packages de mesma natureza, como o trio Flutter).

- **Por quê:** o domínio é coeso — "quais dependências o pacote tem e por quê". Um requisito por dependência mantém cada bloco testável isoladamente (Single Responsibility do requisito) sem fragmentar em pastas de capability minúsculas.
- **Alternativa considerada:** uma capability por dependência. Rejeitada por excesso de cerimônia para um catálogo; o leitor quer uma visão única.

### Decisão 2: Documentar dependências órfãs como requisito de primeira classe

`web` e `flutter_web_plugins` ganham um requisito próprio que afirma a ausência de uso e registra a origem histórica.

- **Por quê:** documentar o que NÃO é usado é tão valioso quanto o que é (Clean Code: tornar visível dependência morta). Vira um achado acionável (candidata a remoção) sem executar a remoção fora de escopo.
- **Alternativa considerada:** omitir as órfãs. Rejeitada porque um catálogo incompleto induz à crença errada de que toda dependência é necessária.

### Decisão 3: Cenários verificáveis por inspeção (grep + pubspec + Git)

Cada cenário é escrito para ser conferível mecanicamente: presença no `pubspec.yaml`, existência de imports/símbolos em arquivos nomeados, ausência de imports para as órfãs.

- **Por quê:** mantém a spec ancorada em evidência objetiva e detectável por regressão (se um import for removido, o cenário falha na revisão).
- **Alternativa considerada:** descrições prosa sem critério verificável. Rejeitada por não ser testável (regra do projeto: requisito mensurável).

### Como o desenho respeita SOLID

- **Single Responsibility:** cada requisito cobre exatamente uma dependência (ou um grupo homogêneo), com um único motivo para mudar — a versão/uso daquela dependência.
- **Dependency Inversion (observado no alvo documentado):** a spec evidencia onde o pacote depende de abstrações das libs externas (ex.: `GoRouterState`, `EventBus`, `GoTransition`) e as encapsula atrás de tipos modulares próprios (`ModularRoute`, `EventModule`), em vez de espalhar o acoplamento.
- **Open/Closed (ponto de extensão):** acrescentar uma nova dependência ao catálogo é adicionar um novo `### Requirement`, sem alterar os existentes.

## Risks / Trade-offs

- **Divergência spec ↔ pubspec/código** → As dependências podem evoluir; mitigação: cada requisito cita o arquivo de referência e a versão declarada, e os cenários são verificáveis por grep na revisão.
- **Citação de hashes de commit** → Hashes (`2dec3f5`, `d6626c6`) podem parecer frágeis; mitigação: servem apenas como rastro histórico do achado órfão, não como contrato — o critério vivo é "nenhum import em `lib/`".
- **Risco de o leitor agir e remover as órfãs aqui** → Mitigação: a spec e os Não-objetivos afirmam explicitamente que a remoção é fora de escopo desta mudança documental.

## Migration Plan

Não aplicável a runtime — mudança puramente documental. Passos de entrega:

1. Criar `openspec/changes/documentar-dependencias-packages/specs/package-dependencies/spec.md`.
2. Validar o catálogo contra o `pubspec.yaml` e os imports de `lib/` (sem editar nada).
3. Ao aplicar (`/opsx:apply`), sincronizar para `openspec/specs/package-dependencies` via `/opsx:sync`.

Rollback: remover o arquivo de spec adicionado; nenhum código nem `pubspec.yaml` é afetado.

## Open Questions

- Remover de fato `web` e `flutter_web_plugins` do `pubspec.yaml` é desejável? Fora de escopo aqui; deve ser uma mudança separada que valide o build web após a remoção.
