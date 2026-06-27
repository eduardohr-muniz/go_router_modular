## Context

Investigação (modo explore) do caminho de resolução:

- `BindStorage` é um `Map<Type, Bind>` global e plano; a resolução (`BindLocator.get`) não conhece o solicitante.
- Pontos de entrada: `i.get<T>()` (factory), `context.read<T>()` (widget), `Modular.get<T>()`/`Bind.get<T>()` (estático). Nenhum carrega contexto de módulo hoje.
- **Achado decisivo**: o `BindContextTracker` já guarda `moduleBindTypes[M]` = identifiers dos binds **próprios + importados** de M (em `injection_manager.dart`, `allBinds = moduleBinds + importedBinds` → `_mapBindsToIdentifiers(allBinds, M)`). O "global" é `moduleBindTypes[AppModule]`.

Logo a regra do usuário reduz-se a uma checagem de pertencimento, sem reescrever o storage:

```
visibleSet(M) = moduleBindTypes[M] ∪ moduleBindTypes[AppModule]
M pode resolver T  ⇔  BindIdentifier(T, key) ∈ visibleSet(M)
```

Decisões do usuário: **padrão (breaking)**, **cobertura total** (factory + widget + estático), **lançar exceção**.

Restrições: pt-BR; mensagens de erro acionáveis; sem abreviações.

## Goals / Non-Goals

**Goals:**

- Resolução com escopo por módulo, com `AppModule` como único global.
- Enforcement nos três pontos de entrada; exceção clara na violação; `tryGet` retorna `null`.
- Reaproveitar `moduleBindTypes` (dados já existentes) para o conjunto visível.

**Non-Goals:**

- Não isolar instâncias por módulo (continua um `BindStorage` global; é controle de acesso).
- Não tornar opt-in; não manter fallback de "vazamento".

## Decisions

### Decisão 1: Conjunto visível pré-computado e módulo solicitante propagado

`visibleSet(M)` é computado uma vez no registro de M (união de `moduleBindTypes[M]` com `moduleBindTypes[AppModule]`) e cacheado no tracker. A resolução recebe o **módulo solicitante** (`scope`) e checa pertencimento antes de retornar (inclusive no fast-path de singleton cacheado).

- Assinaturas passam a aceitar o escopo: `BindLocator.get<T>({String? key, Module? scope})`, `Bind.get<T>({..., Module? scope})`. `scope == null` ⇒ escopo do `AppModule`.

### Decisão 2: Threading do solicitante por ponto de entrada

| Entrada | Como sabe o módulo | Escopo |
|--------|--------------------|--------|
| `i.get<T>()` em factory | `Injector` ganha um campo `Module? scopeModule`; o injector de `binds(M)` e o usado ao invocar a factory de um bind declarado por M são escopados a M | M |
| `context.read<T>()` | `ParentWidgetObserver` provê um `InheritedWidget` (`ModuleScope`) com o módulo; `context.read` lê o `ModuleScope` mais próximo | módulo da subárvore |
| `Modular.get`/`Bind.get` estático | sem contexto | `AppModule` |

### Decisão 3: Bind carrega seu módulo declarante (para escopo das dependências)

Ao construir a instância de um bind B (declarado por M), sua factory resolve dependências no escopo de M. Para isso, o `Bind` canônico é **tagueado com seu módulo declarante** no registro, e `BindLocator._createInstance`/`Bind.instance` invocam a factory com um `Injector` escopado a esse módulo (em vez do `Injector()` contextless atual).

- Bind compartilhado (declarado em A, importado por B): o bind canônico tem declarante A; B o vê via import; suas dependências resolvem no escopo de A. Correto.
- **Alternativa considerada**: derivar o declarante do tracker a cada resolução — rejeitada (custo e ambiguidade quando há múltiplos donos; o declarante é único e estável).

### Decisão 4: Exceção acionável e fail-fast

A violação lança `GoRouterModularException` com mensagem no formato: _"`<ModuloSolicitante>` resolveu `<Tipo>` que não declarou nem importou. Importe o módulo dono (`<ModuloDono>`) ou injete `<Tipo>` em `<ModuloSolicitante>`."_ `tryGet` captura e retorna `null`.

### Decisão 5: Fast-path respeita o escopo

O fast-path de `BindLocator.get` (retorno direto de singleton cacheado) passa a checar `visibleSet(scope)` antes de retornar; o cache negativo permanece, agora também sensível ao escopo quando aplicável.

## Risks / Trade-offs

- **[Raio de impacto amplo — quebra de testes/exemplos]** → Muitos testes exercitam resolução cross-module sem import (a própria má prática). Corrigi-los (declarar import/injetar) é parte do trabalho; a suíte guia o que precisa mudar. Risco real de volume.
- **[`Modular.get` estático escopado ao AppModule é a maior quebra]** → Código de usuário que faz `Modular.get<FeatureBind>()` passa a lançar. Documentar a migração para `context.read`/`i.get`. Registrado como o ponto mais sensível.
- **[Escopo da factory de bind compartilhado]** → Mitigado tagueando o bind com o declarante; cobrir com testes de import e de bind compartilhado.
- **[Performance no caminho quente]** → Checagem O(1) em `Set`; `visibleSet` pré-computado. O fast-path ganha uma checagem de set — impacto mínimo.
- **[Resolução durante `commitBatch`]** → Eager singletons resolvem dependências durante o commit; o escopo do declarante deve já estar disponível (computar `visibleSet` antes do commit, ou tratar AppModule sempre visível).

## Migration Plan

1. **Visibilidade**: computar e cachear `visibleSet(M)` no tracker; expor o módulo declarante por bind. (Sem mudança de comportamento ainda.)
2. **Threading**: adicionar `scope` a `BindLocator.get`/`Bind.get`/`tryGet` e o campo `scopeModule` ao `Injector`; default = AppModule (comportamento inalterado).
3. **Enforcement factory**: escopar o injector de `binds()` e das factories ao módulo declarante; ligar a checagem.
4. **Enforcement widget**: `ParentWidgetObserver` provê `ModuleScope` (InheritedWidget); `context.read` resolve escopado.
5. **Enforcement estático**: `Modular.get`/`Bind.get` estáticos usam escopo do AppModule.
6. **Exceção**: mensagem acionável; `tryGet` → `null`.
7. **Corrigir testes/exemplos** que dependiam de resolução cross-module.
8. **Verificação**: `flutter analyze` + suíte + teste do cenário do usuário (push A→B; B resolve bind não declarado → erro).

## Open Questions

- `Modular.get` estático deve **lançar** para binds de feature, ou ter um modo explícito "global resolve" (escape hatch) para casos legítimos fora de árvore de widgets? (Decisão atual: lançar, conforme escolha do usuário; reavaliar se o atrito de migração for alto.)
- O conjunto visível deve incluir imports **transitivos** do AppModule e do módulo (provavelmente sim, já que `moduleBindTypes` é coletado recursivamente) — confirmar na implementação que a recursão de imports cobre transitividade.
- Mensagem de erro: incluir a stack do registro do bind (já disponível em `Bind.stackTrace`) para apontar onde o dono o declarou?
