## Context

Bug confirmado empiricamente (pilha `A → B → A`): ao dar pop na entrada de cima de A, `ServiceA` é descartado mesmo com a entrada de baixo de A ainda viva.

Causa raiz no `InjectionManager`:

```
_registerBindsModuleInternal (linha 64):  if (moduleBindTypes.containsKey(module)) return;   ← idempotente: registra 1×
_unregisterModuleInternal (linha 132-135): module.dispose(); _unregisterBinds(module);        ← por página: descarta a cada chamada
                                            moduleBindTypes.remove(module);
```

O `ParentWidgetObserver` dispara `unregisterModule` por **página** (N×), mas o registro é idempotente (1×). Com a mesma instância de módulo em duas entradas, o primeiro pop descarta tudo. A proteção `didChangeGoingReference` cobre só transição rápida (microtask). O `BindContextTracker` conta módulos-por-bind (para binds compartilhados entre módulos **distintos**), não entradas-por-instância.

Restrições: pt-BR; preservar comportamento do caso comum; sem abreviações.

## Goals / Non-Goals

**Goals:**

- Balancear registro/descarte por **identidade de instância de módulo** via refcount.
- Corrigir o descarte prematuro no caso de instância repetida na pilha, sem mudar o caso comum.
- Preservar: AppModule nunca descartado, proteção de transição, cascata de shell stateful, reset de testes.

**Non-Goals:**

- Não tocar na resolução de binds nem em escopo por módulo.
- Não mudar imports, commit em batch ou descarte polimórfico.

## Decisions

### Decisão 1: Refcount por identidade de instância no InjectionManager

Adicionar `Map<Module, int> _referenceCount` (identidade). 

```
registerBindsModule(M):
  _referenceCount[M] = (_referenceCount[M] ?? 0) + 1
  if (_referenceCount[M] == 1)  → faz o registro real (corpo atual de _registerBindsModuleInternal)
  else                          → no-op (apenas incrementou)

unregisterModule(M):
  if (M é AppModule) return                 // guarda existente
  final count = (_referenceCount[M] ?? 0) - 1
  if (count > 0) { _referenceCount[M] = count; return }   // ainda referenciado → NÃO descarta
  _referenceCount.remove(M)
  → faz o descarte real (corpo atual de _unregisterModuleInternal)
```

- **Por quê:** torna register/dispose simétricos; o trabalho efetivo ocorre só nas transições 0→1 e 1→0. Identidade de instância casa com o route tree (uma instância por `ModuleRoute`).
- **Nota:** a checagem idempotente atual (`moduleBindTypes.containsKey`) é substituída pela transição de contagem; o no-op de re-registro continua existindo, agora contabilizado.

### Decisão 2: Onde o incremento/decremento acontece — na fila de operações

O incremento/decremento e a decisão de fazer o trabalho ocorrem **dentro** das operações enfileiradas (`_queue.enqueue`), preservando a serialização atual e evitando corrida entre register/unregister concorrentes.

- **Por quê:** registro e descarte já passam pela `OperationQueue`; manter o refcount no mesmo ponto garante ordem determinística (um push e um pop quase simultâneos não dessincronizam o contador).

### Decisão 3: Interação com a proteção de transição

O `_disposeModule` (no route builder) já pula `unregisterModule` quando o módulo está em `didChangeGoingReference`. Esse skip é correto e **não** deve decrementar (não houve saída real — é re-entrada). O refcount permanece consistente porque cada chamada efetiva de `unregisterModule` corresponde a uma saída real; chamadas puladas pela proteção simplesmente não entram na fila.

- **Cuidado:** garantir que o par "registro extra na re-entrada" / "dispose pulado" não gere drift. Cobrir com teste de transição rápida em instância repetida.

### Decisão 4: Cascata de shell stateful

`disposeStatefulShellModule` chama `unregisterModule` para cada módulo de branch + o shell. Com refcount, cada um decrementa; descarta só quem chega a 0. Comportamento de cascata preservado.

## Risks / Trade-offs

- **[Drift do contador]** (decrementos sem incremento correspondente, ou vice-versa) → Centralizar incremento/decremento exclusivamente em `registerBindsModule`/`unregisterModule`, dentro da fila; cobrir com testes de pilha repetida e transição rápida. Em caso de drift, o pior caso é vazamento (não descarta) — preferível a use-after-dispose.
- **[Re-registro que não recria binds]** → Na transição >1 não há trabalho; garantir que a primeira referência já deixou tudo registrado (é o caso). Se a primeira referência falhou, o contador não deve ter subido.
- **[AppModule]** → Guarda existente mantém AppModule fora do descarte; o refcount dele é irrelevante.
- **[Compatibilidade]** → Caso comum (1 entrada) inalterado: 1 incremento → registra; 1 decremento → descarta. Nenhuma mudança observável.

## Migration Plan

1. Reproduzir o bug com um teste `A → B → A` (e `A → A`) que hoje falha no pop intermediário.
2. Adicionar `_referenceCount` e mover a checagem idempotente para a transição 0→1 no registro.
3. Adicionar a transição 1→0 no descarte (decrementa; só descarta em 0).
4. Garantir `resetForTesting` limpando `_referenceCount`.
5. Validar: o teste do bug passa; suíte completa verde; cenário de transição rápida em instância repetida estável.
6. Rollback trivial: remover o refcount restaura o comportamento anterior.

## Open Questions

- O contador vive no `InjectionManager` ou no `BindContextTracker` (junto do demais estado de módulo)? (Recomendação: `InjectionManager`, onde register/unregister moram; ou `BindContextTracker` se preferir centralizar o estado de módulo — decidível na implementação.)
- Vale logar (em debug) quando uma instância repetida é detectada (count > 1), para tornar o padrão visível ao desenvolvedor?
- Instâncias **distintas** do mesmo módulo (raro, fora do route tree) permanecem independentes — confirmar que nenhum fluxo depende de tratá-las como a mesma.
