## Context

Investigação (explore) confirmou: resolução global e plana; `Bind.get`/`Injector.get` estáticos e sem canal de escopo; `BindLocator` não conhece o tracker de módulos. Enforcement em runtime exigiria estado ambiente de escopo + acoplar locator↔tracker + tratar binds de interface + quebra em massa de testes.

Decisão (com o usuário): abordagem **commit-time**, que evita tudo isso — valida no registro, onde o módulo é conhecido.

Achado-chave: `moduleBindTypes[M]` já contém **próprios + importados** de M (`allBinds = moduleBinds + importedBinds` → `_mapBindsToIdentifiers`). O global é `moduleBindTypes[AppModule]`. Então:

```
visibleSet(M) = moduleBindTypes[M] ∪ moduleBindTypes[AppModule]
```

Restrições: pt-BR; mensagem acionável; brecha consciente na resolução estática.

## Goals / Non-Goals

**Goals:**

- Validar, no registro de M, que os binds **declarados por M** resolvem dependências dentro de `visibleSet(M)`; senão, lançar fail-fast.
- Reusar o gancho de validação existente; não tocar no `BindLocator` nem na resolução estática.

**Non-Goals:**

- Não enforçar `Modular.get`/`Bind.get`/`context.read` (brecha consciente).
- Não isolar instâncias por módulo.

## Decisions

### Decisão 1: Conjunto visível via tracker

`BindContextTracker.isVisible(BindIdentifier bindId, Module scope)`:

```
isVisible = moduleBindTypes[scope]?.contains(bindId) == true
         || moduleBindTypes[appModule]?.contains(bindId) == true
```

Cacheável; dados já existentes.

### Decisão 2: Tag de bind para identificar o dono do resolvido

Cada `Bind` ganha `BindIdentifier? scopeId`, atribuído em `_mapBindsToIdentifiers` (que já calcula o `bindId` por `instance.runtimeType` + key). Isso permite, ao resolver uma dependência, identificar o bind concreto e checar visibilidade — cobrindo binds de interface (`get<Interface>()` → instância `Impl`, cujo `bindId(Impl)` é o que está em `moduleBindTypes`).

### Decisão 3: Validação de escopo eager no registro

Ao final de `_registerBindsModuleInternal(M)`, executar `_validateModuleScope(M, moduleBinds, visibleSet)` **síncrono** (não adiado), onde `moduleBinds` são apenas os binds **declarados por M** (não os importados):

```
para cada bind declarado por M:
   recorder = _ScopeRecordingInjector()        // grava cada get<U> com o runtimeType resolvido
   try { bind.factoryFunction(recorder) } catch (_) { /* not-found tratado pelo fluxo normal */ }
   para cada bindId resolvido pelo recorder:
      if (!tracker.isVisible(bindId, M)) → throw ModularException(mensagem acionável)
```

- Checa **dependências diretas** dos binds de M; a transitividade é coberta quando o módulo dono de cada dependência é validado no seu próprio registro.
- Efeito colateral de re-executar a factory é o mesmo já assumido por `_validateModuleBinds` (limitar a singletons já cacheados, como o código atual).

### Decisão 4: Injector de gravação

`_ScopeRecordingInjector implements InjectorReader`: cada `get<T>({key})` resolve via `Bind.get<T>` (instância real, para factories aninhadas funcionarem) e grava `BindIdentifier(instancia.runtimeType, key ?? runtimeType)`. Usado só na validação; não afeta o `Injector` de produção.

### Decisão 5: Mensagem acionável

`"<ModuloM> resolveu <Tipo> que não declarou nem importou. Importe o módulo dono ou injete <Tipo> em <ModuloM>."` Pode incluir, em debug, a stack de registro do bind (`Bind.stackTrace`).

## Risks / Trade-offs

- **[Re-executar factory na validação]** → mesmo risco já presente em `_validateModuleBinds`; restringir a singletons cacheados.
- **[Brecha estática]** → `Modular.get`/`context.read` não enforçados; documentado e aceito.
- **[Blast radius]** → só quebra testes/exemplos onde um bind de módulo depende de bind de outro módulo não importado (a própria má prática). Medir e corrigir.
- **[Bind de interface]** → coberto checando pelo `runtimeType` resolvido, alinhado a `moduleBindTypes`.
- **[Eager vs adiado]** → tornar a validação síncrona pode mudar timing; garantir que erros legítimos de "not found" continuem fluindo pelo caminho normal (não confundir com violação de escopo).

## Migration Plan

1. `isVisible` no tracker + `scopeId` no `Bind` (tag em `_mapBindsToIdentifiers`). Comportamento preservado.
2. `_ScopeRecordingInjector` + `_validateModuleScope` eager no registro; lançar na violação.
3. Teste do cenário do usuário (bind de B depende de `b` não declarado → erro no push).
4. Rodar suíte; corrigir testes/exemplos que dependiam de cross-module sem import.
5. `flutter analyze` + suíte verdes.

## Open Questions

- Validar também binds **lazy/factory** de M (que não rodam no commit) executando-os na validação, ou só os eager já cacheados? (Recomendação: começar pelos cacheados, como o código atual; estender se necessário.)
- Incluir a stack de registro do dono na mensagem de erro? (Recomendação: sim em debug.)
