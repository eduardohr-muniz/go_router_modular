# Plano de Refatoração — Extração do DI como pacote independente

> Documento de trabalho. Descreve o estado atual, os problemas identificados e um
> roteiro incremental para separar o motor de injeção de dependência do pacote de
> roteamento. Nenhuma linha de código deve ser alterada sem revisar este doc primeiro.

---

## 1. Diagnóstico atual

### 1.1 Nota técnica — 7/10

| Dimensão | Nota | Motivo |
|---|---|---|
| Performance | 8/10 | Hot path em 0.05–0.15μs após otimizações; NotFound em ~8μs p50 |
| Correção | 7/10 | Teve incidente em produção (phantom instances); corrigido com regressão |
| API / ergonomia | 7/10 | Dualidade register() vs registerBatch/commitBatch confunde |
| Complexidade interna | 6/10 | 5 estratégias em cascata, 4 estruturas de tracking, 2 fluxos de registro |
| Confiabilidade | 7/10 | Cobertura de edge cases veio depois dos bugs, não antes |

### 1.2 Problemas identificados

**P1 — Dois fluxos de registro com comportamentos diferentes**

`Bind.register()` (fluxo legado) invoca o factory durante o registro para descobrir
o tipo de runtime. `registerBatch/commitBatch` (fluxo de produção) não invoca factories
durante indexação. Qualquer desenvolvedor que usa `register()` em testes ou em código
direto recebe um comportamento surpreendente: o factory roda uma vez extra sem aviso.

```dart
// register() → invoca factory imediatamente (phantom na criação, não no lookup)
Bind.register(Bind.add<ServiceImpl>((i) => ServiceImpl()));

// registerBatch → NÃO invoca; commitBatch → invoca só singletons
Bind.registerBatch(binds);
Bind.commitBatch(injector);
```

**P2 — BindSearchProtection acumula 4 estruturas para um único problema**

`searchAttempts` (Map), `currentlySearching` (Set), `searchStack` (List) e
`_invocationStack + _blockedCounts` — quatro estruturas que precisam ficar em sync
para detectar loops e dependências circulares. Qualquer divergência entre elas é um
bug silencioso.

**P3 — `_locateBind` com 5 estratégias em cascata sem separação clara de contexto**

Estratégia 3 (`_discoverFromObjectBinds`) e Estratégia 4 (`_discoverFromPendingBinds`)
existem para tratar `Bind<Object>` — um edge case de binds não tipados. Esse caminho
cria uma janela de estado inconsistente entre `registerBatch` e `commitBatch` que
é difícil de raciocinar.

**P4 — Acoplamento forte entre DI e roteamento**

`InjectionManager` importa `go_router_modular.dart` (o barrel do pacote de roteamento)
para acessar `Module` e `Bind`. `Bind` importa `Injector` para criar instâncias.
`Injector` importa `Bind`. O grafo de dependências é circular dentro do próprio pacote.

**P5 — `negativeLookupCache` e `bindsMap` têm pontos de invalidação espalhados**

A invalidação do cache negativo foi adicionada em 6 lugares diferentes
(`register`, `registerBatch`, `dispose<T>`, `disposeByType`, `disposeByKey`, `clearAll`).
Qualquer novo ponto de escrita no `bindsMap` que esquecer de limpar o cache cria um
bug de stale data difícil de reproduzir.

---

## 2. Visão da arquitetura alvo

```
┌─────────────────────────────────────┐
│         go_router_modular           │  pub.dev (existente, mantido)
│                                     │
│  routing / widgets / events /       │
│  InjectionManager / Module          │
│                                     │
│  depende de ↓                       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         modular_di  (novo)          │  pub.dev (novo pacote)
│                                     │
│  Container / Bind / Injector /      │
│  BindRegistry / BindLocator /       │
│  BindDisposer / BindStorage /       │
│  BindSearchProtection               │
│                                     │
│  zero dependências Flutter          │
│  (dart-only, testável em vm)        │
└─────────────────────────────────────┘
```

**Princípio:** `modular_di` não conhece rota, widget, ou contexto de navegação.
`go_router_modular` importa `modular_di` e usa o `Container` como serviço.

---

## 3. Sugestões de melhoria (independentes do split de pacote)

Estas melhorias podem ser feitas no pacote atual antes ou durante a extração.

### S1 — Eliminar o fluxo legado `register()`

**Problema:** `Bind.register()` invoca o factory para type discovery — comportamento
não documentado que surpreende e cria instâncias extras.

**Solução:** remover `register()` público. Qualquer chamador (testes, bind_template)
migra para `registerBatch + commitBatch`. O `register()` interno usado pelo
`BindRegistry` pode virar privado.

```dart
// Antes (público, confuso)
Bind.register(Bind.add<ServiceImpl>((i) => ServiceImpl()));

// Depois (explícito, previsível)
final container = Container();
container.register(Bind.add<ServiceImpl>((i) => ServiceImpl()));
// ou via batch:
container.registerBatch([Bind.add<ServiceImpl>((i) => ServiceImpl())]);
container.commit();
```

**Impacto:** breaking change menor. Afeta principalmente testes diretos e código
que não passa pelo `InjectionManager`.

---

### S2 — Unificar BindSearchProtection em uma única estrutura

**Problema:** 4 estruturas de tracking (`searchAttempts`, `currentlySearching`,
`searchStack`, `_invocationStack + _blockedCounts`) devem ficar sincronizadas.

**Solução:** uma única classe `CallFrame` com profundidade e tipo:

```dart
class _CallFrame {
  final Type type;
  final Object? bind;  // null quando é busca pura, não invocação de factory
  int depth;
  _CallFrame(this.type, this.bind) : depth = 1;
}

class BindSearchProtection {
  // Uma única lista em vez de 4 estruturas
  final _frames = <Type, _CallFrame>{};

  bool isSearching(Type t) => _frames.containsKey(t);
  bool isBlocked(Object bind) => _frames.values.any((f) => f.bind == bind);
  // ...
}
```

**Impacto:** refatoração interna. Sem breaking change de API pública.

---

### S3 — Centralizar invalidação do negativeLookupCache

**Problema:** a invalidação está em 6 pontos. Qualquer novo ponto de escrita em
`bindsMap` que esqueça de limpar cria stale data.

**Solução:** `BindStorage` expõe um método `writeBinding(Type, Bind)` que é o
único ponto de escrita em `bindsMap` e limpa o cache automaticamente:

```dart
class BindStorage {
  final Map<Type, Bind> _bindsMap = {};
  final Set<Type> negativeLookupCache = {};

  Map<Type, Bind> get bindsMap => UnmodifiableMapView(_bindsMap);

  void writeBinding(Type type, Bind bind) {
    negativeLookupCache.clear();
    _bindsMap[type] = bind;
  }

  void removeBinding(Type type) {
    negativeLookupCache.remove(type);
    _bindsMap.remove(type);
  }

  void clearAll() {
    negativeLookupCache.clear();
    _bindsMap.clear();
  }
}
```

**Impacto:** refatoração interna. Sem breaking change de API pública.

---

### S4 — Eliminar Estratégias 3 e 4 (`Bind<Object>`)

**Problema:** `_discoverFromObjectBinds` e `_discoverFromPendingBinds` existem para
tratar binds registrados sem tipo (`Bind<Object>`). Esse caminho cria uma janela de
estado inconsistente (pendingObjectBinds) e adiciona dois caminhos de busca extras
em todo `get<T>()`.

**Solução:** exigir tipo em todos os binds. `Bind<Object>` passa a ser um erro em
tempo de registro:

```dart
void registerBatch(List<Bind<Object>> binds) {
  for (final bind in binds) {
    assert(bind.type != Object, 'Binds sem tipo não são suportados. Use Bind<T>.');
    // ...
  }
}
```

**Impacto:** breaking change. Raros — `Bind<Object>` é um edge case de uso avançado.
O `_commitObjectBinds` e `pendingObjectBinds` podem ser removidos junto.

---

### S5 — Adicionar `Container` como ponto de entrada único (em vez de `Bind` estático)

**Problema:** `Bind` é ao mesmo tempo uma classe de dados (representa um binding)
e um namespace de métodos estáticos globais (`Bind.get`, `Bind.register`, `Bind.clearAll`).
Isso torna impossível ter múltiplos containers isolados (para testes paralelos, por exemplo).

**Solução:** separar responsabilidades:

```dart
// Bind = só dado
class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final String? key;
  // isCompatibleWith, isType, etc.
}

// Container = operações
class Container {
  void register(Bind bind);
  void registerBatch(List<Bind> binds);
  void commit();
  T get<T>({String? key});
  T? tryGet<T>({String? key});
  void dispose<T>();
  void clear();
}

// Singleton global para compatibilidade com código existente
final di = Container();
```

**Impacto:** breaking change de API. Vale fazer junto com o split de pacote.

---

## 4. Roteiro de extração — `modular_di`

### Fase 0 — Preparação (sem breaking change)

Estimativa: 1–2 dias.

- [ ] Aplicar S3 (centralizar invalidação via `writeBinding`)
- [ ] Garantir que todos os testes passam via `registerBatch/commitBatch`
  (remover uso de `register()` nos testes do pacote)
- [ ] Adicionar testes para `Container` como wrapper dos estáticos atuais
- [ ] Documentar a API pública que será exportada pelo novo pacote

---

### Fase 1 — Criar `modular_di` como pacote dart-only

Estimativa: 2–3 dias.

Estrutura do novo pacote:

```
modular_di/
├── lib/
│   ├── modular_di.dart           # barrel: exporta Container, Bind, Injector
│   └── src/
│       ├── bind.dart
│       ├── container.dart        # substitui os métodos estáticos de Bind
│       ├── injector.dart
│       ├── bind_registry.dart
│       ├── bind_locator.dart
│       ├── bind_disposer.dart
│       ├── bind_storage.dart
│       └── bind_search_protection.dart
├── test/
│   └── (mover todos os testes de bind_* aqui)
└── pubspec.yaml
    # dependencies: apenas dart:core
    # sem flutter, sem go_router
```

O `Container` expõe a API limpa (S5). Os métodos estáticos de `Bind` passam a
delegar para uma instância global de `Container` — mantendo compatibilidade.

---

### Fase 2 — `go_router_modular` importa `modular_di`

Estimativa: 1 dia.

```yaml
# go_router_modular/pubspec.yaml
dependencies:
  modular_di: ^1.0.0
  go_router: ...
  flutter:
    sdk: flutter
```

```dart
// InjectionManager passa a usar Container diretamente
import 'package:modular_di/modular_di.dart';

class InjectionManager {
  final Container _container = Container();
  // ...
}
```

Remover de `go_router_modular`:
- `lib/src/core/bind/` (todos os arquivos)
- `lib/src/di/injector.dart`
- `lib/src/di/bind_identifier.dart`

---

### Fase 3 — Limpeza e breaking changes deliberados

Estimativa: 1–2 dias.

- [ ] Aplicar S1 (remover `register()` legado)
- [ ] Aplicar S2 (unificar BindSearchProtection)
- [ ] Aplicar S4 (eliminar `Bind<Object>`)
- [ ] Bump de versão: `modular_di` → 1.0.0, `go_router_modular` → 6.0.0
- [ ] CHANGELOG com guia de migração

---

### Fase 4 — Melhorias de qualidade pós-split (backlog)

Sem prazo definido.

- [ ] `Container` com escopo isolado por módulo (sem singleton global)
- [ ] Lazy singleton: invocação adiada até o primeiro `get<T>()` sem depender do
  `commitBatch` para eager instantiation
- [ ] API fluente opcional: `di.factory<IService>(() => ServiceImpl())`
- [ ] Modo debug que rastreia quem registrou cada bind (StackTrace capturado
  opcionalmente via flag)

---

## 5. Riscos e contrapartidas

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Break em código de usuário que usa `Bind.register()` direto | Média | Deprecar antes de remover; guia de migração no CHANGELOG |
| `modular_di` sem flutter cria inconsistência com `ChangeNotifier` em `_validateChangeNotifier` | Alta | Mover `_validateChangeNotifier` para `go_router_modular`; `modular_di` não conhece Flutter |
| Dois pacotes para manter em sync | Baixa | CI compartilhado; `modular_di` tem versionamento semver estrito |
| Complexidade de setup para contribuidores | Baixa | Monorepo com `melos` ou workspace simples |

---

## 6. O que NÃO mudar

- A semântica de `isSingleton` / factory: bem definida, testada
- O algoritmo `isCompatibleWith<U>()` (`<T>[] is List<U>`): elegante, sem overhead
- O negative lookup cache: correto, bem invalidado após S3
- O fast path de `get<T>()` para singletons cacheados: medido, provado
- A proteção de phantom instances: crítica, resolveu incidente em produção

---

## 7. Referências

- `REFACTOR_DECISION.md` — histórico das 3 alterações da investigação de produção
- `test/performance_benchmark_test.dart` — números de referência de performance
- `test/no_breaking_change_factory_interface_test.dart` — regressão crítica
- `test/probe_side_effect_reproduction_test.dart` — reprodução do incidente original
