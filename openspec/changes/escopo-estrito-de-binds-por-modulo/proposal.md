## Why

Hoje o container de DI resolve binds de forma **global e plana**: qualquer bind registrado e vivo é resolvível por qualquer código, independentemente de qual módulo o declarou. Isso permite uma má prática silenciosa: um módulo B pode resolver um bind que ele não injetou nem importou — desde que outro módulo (ex.: A, ainda na pilha após um `push`) o tenha registrado. O desenvolvedor "esquece" de importar/injetar e o app funciona por acidente, até o módulo dono ser descartado e tudo quebrar.

Reproduzimos e confirmamos esse comportamento: `ModuleB` resolve `ServiceB` que pertence a `ModuleA`, sem qualquer aviso. A regra desejada é explícita e simples de comunicar:

> **O `AppModule` (e os imports dele) é o único escopo global, acessível por todos.** Qualquer outro módulo só pode acessar os binds que **ele mesmo injetou ou importou**.

Esta mudança implementa essa regra como comportamento do pacote, lançando uma exceção clara quando um módulo resolve um bind fora do seu escopo — transformando uma má prática silenciosa em erro imediato e orientado.

## What Changes

- Introduzir **resolução com escopo por módulo**: a visibilidade de um módulo M é `binds próprios de M ∪ binds importados por M ∪ binds do AppModule (e imports do AppModule)`.
- Computar o conjunto visível de cada módulo a partir do `BindContextTracker`, que **já registra** `moduleBindTypes[M]` como (próprios + importados); o global é `moduleBindTypes[AppModule]`.
- Enforçar a regra nos três pontos de entrada de resolução:
  - **Factory (`i.get<T>()`)**: o `Injector` recebido em `binds()`/factories passa a ser **escopado** ao módulo dono — resolver fora do escopo lança erro.
  - **Widget (`context.read<T>()`)**: o `ParentWidgetObserver` (que já envolve cada módulo) expõe o módulo via `InheritedWidget`; `context.read` resolve no escopo daquele módulo.
  - **Estático (`Modular.get<T>()` / `Bind.get<T>()`)**: sem contexto de módulo, resolve **apenas no escopo do AppModule** (o "global"); tipos de módulos de feature exigem `context.read`/`i.get`.
- Lançar `GoRouterModularException` clara ao violar o escopo, com mensagem acionável: _"ModuleB resolveu ServiceB que não declarou nem importou — importe ModuleA ou injete ServiceB em ModuleB."_
- **BREAKING / padrão**: a regra é ligada por padrão (não é opt-in). Apps e testes que dependem da resolução cross-module global precisarão declarar imports/binds corretos.

Justificativa SOLID/Clean Code: torna explícitas e verificáveis as dependências entre módulos (Dependency Inversion via contrato de import), elimina acoplamento implícito por bind "vazado" e falha rápido (fail-fast) em vez de erro tardio no descarte.

## Capabilities

### New Capabilities
- `module-bind-scope`: Resolução de binds com escopo por módulo — definição do conjunto visível (próprios + importados + AppModule), enforcement nos três pontos de entrada (factory, widget, estático) e a exceção de violação de escopo.

### Modified Capabilities
- `dependency-injection`: a resolução (`get`/`tryGet`) deixa de ser puramente global e passa a respeitar o escopo do solicitante.

## Impact

- **Código de produção**: alterações no caminho de resolução (`BindLocator`/`Bind.get`), no `Injector` (escopo), no `ParentWidgetObserver`/`context.read` (escopo via `InheritedWidget`), no façade estático (escopo AppModule) e no `BindContextTracker`/`InjectionManager` (expor o conjunto visível e o módulo dono de cada bind).
- **Comportamento**: **BREAKING** — resolução cross-module não declarada passa a lançar. `tryGet` retorna `null` fora do escopo.
- **Testes/exemplos**: testes/exemplos que resolvem binds entre módulos sem import explícito precisarão ser corrigidos (declarar import ou injetar) — parte do trabalho.
- **Performance**: checagem de pertencimento em `Set<BindIdentifier>` (O(1)); conjunto visível pré-computado por módulo no registro.
- **Riscos**: altos (mudança de comportamento central de DI, raio de impacto amplo, especialmente o escopo do `Modular.get` estático); mitigados por fases verificáveis e pela suíte.

## Não-objetivos

- Não criar armazenamento separado por módulo (instâncias distintas por escopo) — a mudança é de **visibilidade/acesso**, não de isolamento de instâncias; o `BindStorage` global permanece.
- Não tornar a regra opt-in (a decisão foi ligá-la por padrão).
- Não alterar o ciclo de vida/descarte de binds, nem a mecânica de imports.
- Não suportar resolução cross-module via "vazamento" como fallback — a violação é erro, não aviso.
