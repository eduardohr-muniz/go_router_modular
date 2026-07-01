## Why

Quando a **mesma instância de módulo** aparece mais de uma vez na pilha de navegação (ex.: `A → B → A`, empilhando a rota de A sobre si mesma), os binds de A são **descartados prematuramente** ao dar pop na entrada de cima — mesmo com a entrada de baixo de A ainda viva na pilha. Reproduzido e confirmado:

```
[3] push A  (pilha A,B,A)   ServiceA=ok
[4] pop topo A (pilha A,B)  ServiceA=NULO  ← A de baixo ainda precisa de ServiceA  (BUG)
```

A causa é uma **assimetria entre registro e descarte**: o registro de binds é idempotente por instância de módulo (`if (moduleBindTypes.containsKey(module)) return;` — registra 1×), mas o descarte é disparado **por página** pelo `ParentWidgetObserver` (N×). Com a mesma instância de módulo em duas entradas, o primeiro pop já remove o módulo do tracker e descarta seus binds, quebrando a outra entrada que usa a mesma instância. A proteção `didChangeGoingReference` cobre apenas transições rápidas (janela de microtask), não o caso de repetição na pilha; e o `BindContextTracker` conta módulos-por-bind, não entradas-de-rota-por-instância-de-módulo.

Esta mudança corrige o descarte prematuro introduzindo **contagem de referências por instância de módulo**: registra na primeira entrada, descarta apenas quando a última entrada sai. É um bug de ciclo de vida, não uma feature.

## What Changes

- Introduzir um **refcount por instância de módulo** no `InjectionManager` (mapa de identidade `Module → int`).
- `registerBindsModule(M)` **incrementa** o refcount a cada entrada; o trabalho de registro (coletar binds, commit, mapear, `initState`) ocorre **apenas na transição 0→1**.
- `unregisterModule(M)` **decrementa** o refcount; o descarte real (`module.dispose()`, remoção de binds, limpeza do tracker) ocorre **apenas na transição 1→0**.
- Tornar registro e descarte **simétricos**: N entradas → N incrementos; N saídas → N decrementos; trabalho efetivo uma única vez em cada ponta.
- Preservar as garantias existentes: AppModule nunca descartado, proteção `didChangeGoingReference` para transições rápidas, descarte em cascata de branches de shell stateful, e `resetForTesting` limpando o refcount.
- Adicionar testes do cenário `A → B → A` (e `A → A`) cobrindo: binds resolvem em cada nível, sobrevivem ao pop da entrada de cima, e só são descartados no pop da última entrada.

Justificativa SOLID/Clean Code: corrige uma invariante de ciclo de vida (registro/descarte balanceados), eliminando estado inconsistente; falha do tipo "use-after-dispose" deixa de ocorrer.

## Capabilities

### Modified Capabilities
- `module-lifecycle`: o descarte de um módulo passa a respeitar a contagem de entradas ativas daquela instância na pilha — um módulo só é descartado quando sua última entrada sai, corrigindo o descarte prematuro quando a mesma instância aparece múltiplas vezes.

## Impact

- **Código de produção**: `lib/src/di/injection_manager.dart` (refcount no registro/descarte) e, se necessário, `bind_context_tracker.dart` (armazenar o contador) — sem alterar o caminho de resolução nem a mecânica de binds.
- **Comportamento**: corrige o descarte prematuro; o caso comum (módulo aparece uma vez) permanece idêntico (1 incremento, 1 decremento).
- **Testes**: novos testes do cenário `A → B → A`/`A → A`; a suíte existente valida a não-regressão do ciclo de vida.
- **Riscos**: médios — interação com a proteção `didChangeGoingReference` (garantir que dispose pulado não dessincronize o contador) e com o descarte em cascata de shell stateful; mitigados por testes específicos.

## Não-objetivos

- Não alterar a resolução de binds nem introduzir escopo por módulo (isso é a proposta `escopo-estrito-de-binds-por-modulo`).
- Não mudar a mecânica de imports, commit em batch ou descarte polimórfico de instâncias.
- Não suportar instâncias distintas do mesmo módulo como se fossem a mesma (o refcount é por **identidade de instância**, coerente com o route tree, onde cada `ModuleRoute` tem uma instância).
