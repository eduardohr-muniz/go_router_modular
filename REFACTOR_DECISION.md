# Bind Locator / Registry — documento de decisão

Documento de trabalho para avaliar as correções aplicadas durante a investigação do travamento no `i.get`. Cada seção é **revertivelmente independente**. Use este documento para decidir o que manter, o que reverter e o que adiar.

---

## Resumo executivo

A investigação produziu **três** alterações independentes, da menos para a mais invasiva:

| # | Alteração | Risco | Quebra código do usuário? |
|---|---|---|---|
| 1 | Bloquear bind durante probe (correção do loop) | baixo | não |
| 2 | Pilha de invocação tipada + erro claro de dep. circular + refactor DRY | médio | sim — código com **dependências circulares latentes** agora lança exceção em vez de silenciosamente NotFound |
| 3 | Pular factory binds na busca por compatibilidade + slot canônico usa tipo declarado | **alto** | sim — `addFactory((i) => Impl()) + get<ISupertype>()` agora lança exceção |

O travamento em produção reportado é corrigido **apenas pela #1**. As alterações #2 e #3 são melhorias de qualidade que encontraram bugs reais, mas exigem breaking changes de semver major.

---

## Problema original

Relato do usuário:
> "fizemos o ajuste no i.get porém tá travando a aplicação em prod, acho que entrou em um loop infinito"

Gatilho: navegação para `/home/pos`, `HomeModule` registrado com binds `EstablishmentApi`, `WsApi`, `MainTerminalCubit`, `SupportChatCubit` (mistura factory + singleton). Tela trava após o log `INJECTED MODULE: HomeModule`.

**Causa raiz confirmada por teste de reprodução** (`test/probe_side_effect_reproduction_test.dart`):

`BindLocator._searchCompatibleBind` (Estratégia 5) estava invocando o factory de cada bind em `bindsMap` sempre que um supertipo não mapeado era buscado. Para cada candidato factory, chamava `factoryFunction(Injector())` apenas para checar o tipo do resultado. Contagens confirmadas antes da correção:

| Configuração | Resultado |
|---|---|
| 1 factory bind, 1 `get<INaoRegistrado>` | 1 instância fantasma criada |
| 2 factory binds, 1 `get<INaoRegistrado>` | 1 de cada |
| 1 factory bind, 5 `get<INaoRegistrado>` | 5 instâncias fantasmas (sem amortização) |

No travamento: cada Cubit construído como fantasma executava um construtor com efeitos colaterais (disparo de evento, conexão websocket, registro de listener). No mínimo vazava instâncias; no pior caso (evento disparado acionava outro `get<>` dentro de um handler), cascateava.

---

## Alteração #1 — Bloquear bind durante probe (correção do loop)

### O que foi feito
Adicionado `_protection.pushInvocation(candidate, T) / try / finally / popInvocation(candidate)` em torno de cada invocação de factory em `BindLocator`:
- `_singletonProducesT` (antes chamado `_candidateProducesT`)
- `_discoverFromObjectBinds`
- `_discoverFromPendingBinds`

O padrão já existia em `_invokeFactoryWithSelfRefGuard`.

### Por quê
O probe do candidato C podia chamar recursivamente `i.get<T>()` de dentro do factory de C. A busca recursiva reentraria em `_searchCompatibleBind`, encontraria C novamente (não bloqueado), reinvocaria seu factory, etc. Cada `attempts >= 3` limpava o contador, então o próximo probe começava do zero — loop infinito real possível. Mesmo quando limitado, invocações em cascata com efeitos colaterais = travamento visível.

### Alternativas consideradas
Nenhuma relevante — é visivelmente uma proteção ausente. O `_invokeFactoryWithSelfRefGuard` existente já provou o padrão.

### O que quebra
**Nada.** Proteção puramente aditiva.

### Arquivos modificados
- `lib/src/core/bind/bind_locator.dart` (3 pontos, ~10 linhas)

### Como reverter
```
git diff <commit> lib/src/core/bind/bind_locator.dart
```
Remover os pares `pushInvocation / popInvocation` dos três métodos listados acima.

### Veredito
**Manter.** Esta é a correção real para produção. O usuário já confirmou: "sumiu sim agora está ok".

---

## Alteração #2 — Pilha de invocação tipada + erro claro de dep. circular + DRY

### O que foi feito
Três alterações acopladas:

1. **Reescrita de `BindSearchProtection`** (`lib/src/core/bind/bind_search_protection.dart`):
   - Substituído `Set<Object> _blockedBinds` por `Map<Object,int> _blockedCounts` (contador — seguro para reentrância).
   - Adicionado `List<({Object bind, Type requestedType})> _invocationStack`.
   - Removidos os métodos públicos `blockBind` / `unblockBind`. Adicionados `pushInvocation(bind, requestedType)` / `popInvocation(bind)` / `isTopInvocationFor(type)`.

2. **Validação de bypass mais precisa** em `_validateCanStartSearch`:
   - Antes: bypass do `currentlySearching` quando havia qualquer bind em execução (`hasBlockedBinds`).
   - Agora: bypass apenas quando `isTopInvocationFor(type)` — ou seja, o factory do topo da pilha está produzindo exatamente este tipo (auto-referência verdadeira).
   - Dependências circulares entre tipos diferentes agora lançam `"Dependência circular detectada ao resolver tipo \"A\". Cadeia: A -> B -> A."` em vez de cair silenciosamente em NotFound.

3. **Extração de helper** em `BindLocator`:
   - Adicionado `_withInvocation(bind, requestedType, action)` — ponto único que faz push/pop.
   - Substitui 4 blocos try/finally duplicados.

### Por quê
- **Contador**: defensivo. `Set.add` é idempotente mas `Set.remove` sempre remove — se o mesmo bind aparecesse na pilha duas vezes, o primeiro `pop` o desbloquearia prematuramente. Não explorado hoje, mas uma armadilha.
- **Bypass tipado**: o bypass global `hasBlockedBinds` era muito amplo. Dizia "se qualquer coisa está executando, get recursivo é OK". Isso escondia dependências circulares reais `A → B → A` como confusos NotFound. O bypass tipado distingue auto-referência legítima (`addFactory<I>((i) => i.get())`) de ciclos reais.
- **Helper**: remove risco de divergência — qualquer novo ponto de chamada de factory automaticamente recebe a proteção.

### Alternativas consideradas
- **Manter bloqueio baseado em `Set`**, aceitar o caso extremo de reentrância. Mais barato, mas qualidade inconsistente.
- **Não adicionar bypass tipado**, manter o `hasBlockedBinds` amplo. Então `A↔B` continua silenciosamente como NotFound. Menos surpreendente para usuários que dependem do comportamento de mascaramento.
- **Não extrair helper**, aceitar a duplicação. Tolerável hoje, vira divergência depois.

### O que quebra
**Código com dependências circulares latentes entre tipos começa a lançar exceção.**

Antes:
```dart
i.addSingleton<A>((i) => A(i.get<B>()));
i.addSingleton<B>((i) => B(i.get<A>()));
// O código "funcionava": commitBatch engolia a exceção, depois i.get<A>() lançava
// "Bind not found for type A" no fundo da pilha.
```
Depois:
```dart
// O mesmo código agora lança na primeira tentativa:
// "Dependência circular detectada ao resolver tipo A.
//  Cadeia: A -> B -> A.
//  Quebre o ciclo injetando uma abstração..."
```

Isso é **tecnicamente uma breaking change** para usuários que entregaram código quebrado que estava em caminhos frios. Em código correto, nenhuma diferença.

### Arquivos modificados
- `lib/src/core/bind/bind_search_protection.dart` (reescrita completa, ~95 linhas)
- `lib/src/core/bind/bind_locator.dart` (`_validateCanStartSearch`, `_invokeFactoryWithSelfRefGuard`, helper, `_probeAs`)
- `test/circular_dependency_test.dart` (novo, 2 testes)
- `test/factory_probe_side_effects_test.dart` (novo, 3 testes)

### Como reverter
1. Restaurar `bind_search_protection.dart` para usar `Set<Object>` e expor `blockBind`/`unblockBind`/`hasBlockedBinds`/`isBlocked`/`clearAll`/`clearForType` (API original).
2. Em `bind_locator.dart`, restaurar `_validateCanStartSearch` para usar `if (_protection.hasBlockedBinds) return;`.
3. Substituir as chamadas `_withInvocation(bind, T, () { ... })` por `_protection.blockBind(bind); try { ... } finally { _protection.unblockBind(bind); }`.
4. Excluir `circular_dependency_test.dart`.

### Veredito
**Reversível. Valor independente.** Tendência a manter o bypass tipado e o helper; o contador é defensivo — manter ou remover é questão de gosto.

---

## Alteração #3 — Pular factory binds na busca por compatibilidade + correção do slot canônico

### O que foi feito
Duas alterações acopladas:

1. **`_searchCompatibleBind` pula factory binds** (`lib/src/core/bind/bind_locator.dart`):
   ```dart
   if (!candidate.isSingleton) continue;
   ```
   Renomeado `_candidateProducesT` → `_singletonProducesT` pois agora trata apenas singletons. Armazena em cache a instância do probe para preservar identidade do singleton.

2. **`BindRegistry.register` indexa binds tipados sob o tipo declarado** (`lib/src/core/bind/bind_registry.dart`):
   ```dart
   final canonicalType = bind.type != Object ? bind.type : discoveredType;
   _writeToCanonicalSlot(canonicalType, bind);
   _indexDiscoveredType(discoveredType, bind);
   ```
   Antes o slot canônico era sempre o tipo de runtime descoberto — então `Bind.factory<IService>((i) => ServiceImpl())` era indexado sob `ServiceImpl`, fazendo `get<IService>` perder a Estratégia 2 e depender do probe de factory (agora removido).

### Por quê
Fazer probe de um factory bind exige invocar seu factory para checar o tipo do resultado. Invocar cria uma instância descartável com todos os efeitos colaterais do construtor (publicação de evento, assinatura de stream, chamadas HTTP) — pelo motivo errado (uma chamada `get<>` não relacionada). A instância é então descartada.

Isso se aplica a **qualquer relação de supertipo**, não apenas interfaces:
- Interfaces (`class Cat implements IAnimal`)
- Classes abstratas (`abstract class Repository; class UserRepository extends Repository`)
- Superclasses concretas (`class Dog extends Animal`)
- Mixins (`class MyService with Loggable`)

A correção do registro é necessária porque pular probes de factory quebraria `Bind.factory<IService>(...)` se ainda indexado sob `ServiceImpl` — a mudança no registro mantém o caminho de **factory tipado** funcionando via Estratégia 2 (busca direta, sem probe).

### Alternativas consideradas

- **Cache de negativas de probe** (`Map<(Bind, Type), bool>`): primeiro lookup ainda tem o efeito colateral, apenas lookups subsequentes pulam. Ganho marginal. Memória cresce com pares (bind × tipo). Não resolve o vazamento na primeira chamada.
- **Promover factory a singleton no primeiro probe**: viola silenciosamente a semântica declarada pelo usuário (`factory` = nova instância por chamada). Armadilha disfarçada de correção.
- **Suprimir efeitos colaterais com Zone**: não funciona — efeitos colaterais síncronos em construtores não passam pelas APIs de Zone (`stream.listen`, `controller.add`, etc.).
- **Geração de código / reflexão**: `dart:mirrors` indisponível no Flutter; codegen requer build_runner e anotações — mudança arquitetural maior.
- **Não fazer nada**: bug latente permanece. Usuários com construtores com efeitos colaterais continuam pagando custo espúrio. Já custou um incidente em produção (de certa forma — o travamento foi o loop, mas o spam subjacente estava relacionado).

### O que quebra
**Um padrão de sintaxe**:
```dart
i.addFactory((i) => ServiceImpl());  // sem tipo, T inferido como ServiceImpl
i.get<IService>();                    // ❌ agora lança NotFound
```

Três migrações documentadas:
```dart
// Opção A — tipar o factory explicitamente (recomendado)
i.addFactory<IService>((i) => ServiceImpl());
i.get<IService>();  // ✅

// Opção B — registrar como singleton (se semântica singleton for OK)
i.addSingleton((i) => ServiceImpl());
i.get<IService>();  // ✅

// Opção C — delegação explícita (se múltiplos consumidores precisam do mesmo concreto)
i.addFactory<ServiceImpl>((i) => ServiceImpl());
i.addFactory<IService>((i) => i.get<ServiceImpl>());
i.get<IService>();  // ✅
```

**Sem mudança** (sem necessidade de migração):
- Todos os padrões singleton (tipados ou não)
- Factory tipado + get correspondente (`addFactory<I>(...) + get<I>()`)
- Auto-referência (`addFactory<I>((i) => i.get())` com concreto registrado separadamente)
- Lookups por key
- Factory sem tipo + lookup por tipo concreto (`addFactory((i) => Impl()) + get<Impl>()`)

### Alcance — o que os usuários tipicamente têm

Execute isso no projeto que quebrou para estimar o impacto:
```bash
grep -rn "addFactory((i)\|\.add((i)\|Bind\.factory((i)\|Bind\.add((i)" lib --include='*.dart'
```
Conte os registros de factory sem tipo. Cada um é uma migração potencial. Se a contagem for pequena, a Alteração #3 é barata. Se for grande, considere manter apenas a Alteração #1 + #2.

### Arquivos modificados
- `lib/src/core/bind/bind_locator.dart` (`_searchCompatibleBind` ~10 linhas, renomeação do helper)
- `lib/src/core/bind/bind_registry.dart` (`register` ~5 linhas)
- `test/probe_side_effect_reproduction_test.dart` (asserts invertidos, count == 0)
- `test/typed_factory_interface_lookup_test.dart` (novo, 6 testes)
- `test/bind_interface_test.dart` (1 teste migrado do comportamento antigo para o novo)
- `CHANGELOG.md` (entrada 5.2.0 com nota de breaking)
- `pubspec.yaml` (5.1.0+3 → 5.2.0)

### Como reverter
1. Em `bind_locator.dart`, remover `if (!candidate.isSingleton) continue;` de `_searchCompatibleBind`. Restaurar o ramo de delegação de factory:
   ```dart
   if (candidate.isSingleton) {
     _storage.bindsMap[type] = candidate;
     return candidate;
   }
   final delegate = Bind<T>(
     (injector) => candidate.factoryFunction(injector) as T,
     isSingleton: false,
     isLazy: candidate.isLazy,
     key: candidate.key,
   );
   _storage.bindsMap[type] = delegate;
   return delegate;
   ```
   Renomear `_singletonProducesT` de volta para `_candidateProducesT`. Remover a atribuição de cache apenas para singleton (ou manter — ainda é correto).

2. Em `bind_registry.dart`, reverter `register`:
   ```dart
   Type registrationType = bind.type;
   try {
     final instance = bind.factoryFunction(Injector());
     registrationType = instance.runtimeType;
     _processInstance(bind, instance);
   } catch ...
   _writeToCanonicalSlot(registrationType, bind);
   _indexDiscoveredType(registrationType, bind);
   ```

3. Reinverter os asserts de `probe_side_effect_reproduction_test.dart` (esperar `> 0`, documentar como reprodução de BUG e não regressão).

4. Reverter a migração de `bind_interface_test.dart` (restaurar o teste de factory sem tipo).

5. Reverter a entrada 5.2.0 do `CHANGELOG.md`.

6. Reverter `pubspec.yaml` para `5.1.0+3` (ou o que estava antes).

### Veredito
**O mais controverso.** O argumento de qualidade é forte (elimina instâncias fantasmas permanentemente). O argumento de UX é forte contra (quebra padrão documentado). Adiar a decisão.

---

## Matriz de decisão

| Cenário | Recomendação |
|---|---|
| Codebase tem zero padrões factory-sem-tipo-via-interface | Manter #1 + #2 + #3 (todos os ganhos, sem custo) |
| Poucas migrações, disposto a fazer bump major | Manter #1 + #2 + #3, publicar como 5.2.0 |
| Muitos factories sem tipo, não pode migrar agora | Manter #1 + #2, reverter #3, publicar como 5.1.1 |
| Avesso a risco, quer mudança mínima | Manter apenas #1, reverter #2 + #3, publicar como 5.1.1 |
| Não confia em nenhuma das alterações | Reverter todas as três, travamento em prod volta |

---

## Inventário de testes

Novos testes adicionados durante a investigação (todos passam atualmente com as 3 alterações aplicadas):

| Arquivo | Testes | Propósito |
|---|---|---|
| `test/circular_dependency_test.dart` | 2 | Garante que ciclos entre tipos lançam erro claro; auto-ref ainda funciona |
| `test/factory_probe_side_effects_test.dart` | 3 | Probe de singleton preserva identidade, sem re-invocação |
| `test/probe_side_effect_reproduction_test.dart` | 4 | Regressão: factory não invocado durante lookup não relacionado |
| `test/typed_factory_interface_lookup_test.dart` | 6 | Factory tipado funciona via Estratégia 2; não tipado + interface lança |

Se reverter qualquer alteração, os testes correspondentes precisam de atualização:

- Reverter #1 → nenhum desses testes precisa de atualização direta, mas testes de prevenção de loop podem ficar instáveis.
- Reverter #2 → excluir `circular_dependency_test.dart`. Testes da #3 ainda funcionam.
- Reverter #3 → inverter asserts de `probe_side_effect_reproduction_test.dart` de volta para reprodução de BUG. Excluir ou reescrever `typed_factory_interface_lookup_test.dart`. Restaurar migração de `bind_interface_test.dart`.

---

## Resumo dos arquivos modificados

```
lib/src/core/bind/bind_locator.dart            ← alterações #1, #2, #3
lib/src/core/bind/bind_search_protection.dart  ← alteração #2 (reescrita completa)
lib/src/core/bind/bind_registry.dart           ← alteração #3
CHANGELOG.md                                   ← alteração #3 (entrada 5.2.0)
pubspec.yaml                                   ← alteração #3 (bump de versão)

test/circular_dependency_test.dart             ← novo, alteração #2
test/factory_probe_side_effects_test.dart      ← novo, alterações #2/#3
test/probe_side_effect_reproduction_test.dart  ← novo, alteração #3 (asserts invertidos)
test/typed_factory_interface_lookup_test.dart  ← novo, alteração #3
test/bind_interface_test.dart                  ← 1 teste migrado, alteração #3
```

---

## Comandos de reprodução

```bash
# Verificar estado atual (todos verdes)
flutter test

# Rodar apenas a reprodução do bug
flutter test test/probe_side_effect_reproduction_test.dart

# Rodar apenas a regressão de dependência circular
flutter test test/circular_dependency_test.dart

# Ver contagens exatas de instâncias fantasmas (números pré-correção documentados no cabeçalho do teste)
flutter test test/probe_side_effect_reproduction_test.dart -r expanded
```
