# 📚 Absorção de Conhecimento: auto_injector & get_it

Este documento resume os principais padrões, técnicas e conceitos aprendidos dos pacotes `auto_injector` e `get_it` que podem ser aplicados ao projeto `go_router_modular`.

---

## 🎯 **1. Detecção Automática de Dependências**

### **auto_injector: Análise Estática de Construtores**

**Conceito Chave:** O `auto_injector` analisa a string de representação do construtor para extrair tipos de parâmetros:

```dart
// auto_injector/lib/src/bind.dart
static List<Param> _extractParams(String constructorString) {
  final params = <Param>[];
  
  // Extrai parâmetros posicionais e nomeados usando regex
  final allArgsRegex = RegExp(r'\((.+)\) => .+');
  final allArgsMatch = allArgsRegex.firstMatch(constructorString);
  
  // Processa parâmetros nomeados: {required Type name}
  // Processa parâmetros posicionais: Type param
  // ...
}
```

**Aplicação no Projeto:**
- ✅ Já implementamos algo similar em `TypeInference._inferTypeFromFactory`
- 🔄 **Melhorar:** Criar um sistema mais robusto que extrai TODOS os tipos de dependências do construtor, não apenas o tipo de retorno

---

## 🎯 **2. Sistema de Parâmetros (Param System)**

### **auto_injector: Param e ParamTransform**

**Conceito Chave:** Classes especializadas para representar parâmetros e permitir transformações:

```dart
abstract class Param {
  final String className;  // Tipo do parâmetro
  final bool isNullable;
  final bool isRequired;
  final dynamic value;
  
  bool get injectableParam => !isNullable && isRequired;
}

class PositionalParam extends Param { ... }
class NamedParam extends Param { ... }

typedef ParamTransform = Param? Function(Param param);
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Sistema de transformação de parâmetros para testes (mock injection)
- ✅ **Benefício:** Permite substituir dependências em runtime para testes

---

## 🎯 **3. Resolução de Dependências com Function.apply**

### **auto_injector: Resolução Dinâmica**

**Conceito Chave:** Usa `Function.apply` para chamar construtores com parâmetros resolvidos dinamicamente:

```dart
Bind _resolveBind(Bind bind, ParamTransform? transform) {
  final params = _resolveParam(bind.params, transform);
  
  final positionalParams = params
      .whereType<PositionalParam>()
      .map((param) => param.value)
      .toList();
  
  final namedParams = params
      .whereType<NamedParam>()
      .map((param) => {param.named: param.value})
      .fold(<Symbol, dynamic>{}, (value, element) => value..addAll(element));
  
  final instance = Function.apply(
    bind.constructor,
    positionalParams,
    namedParams,
  );
  return bind.withInstance(instance);
}
```

**Aplicação no Projeto:**
- ✅ **Já temos:** `bind.factoryFunction(Injector())` funciona similarmente
- 🔄 **Melhorar:** Suportar parâmetros nomeados explicitamente
- 🔄 **Melhorar:** Validar tipos de parâmetros antes de aplicar

---

## 🎯 **4. Sistema de Escopos (Scopes)**

### **get_it: Hierarchical Scoping**

**Conceito Chave:** Permite criar escopos hierárquicos onde registros podem ser "sombreados" (shadowed):

```dart
// Push novo escopo
void pushNewScope({
  void Function(GetIt getIt)? init,
  String? scopeName,
  ScopeDisposeFunc? dispose,
});

// Pop escopo (remove registros desse escopo)
Future<void> popScope();
```

**Características:**
- ✅ Busca primeiro no escopo mais alto
- ✅ Permite "shadowing" (objetos de escopo superior escondem inferiores)
- ✅ Callbacks de dispose por escopo
- ✅ Notificação quando objeto é shadowed/unshadowed

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Sistema de escopos para módulos (similar ao que já temos, mas mais robusto)
- ✅ **Benefício:** Melhor isolamento entre módulos e lifecycle management

---

## 🎯 **5. Registros Assíncronos e Sincronização**

### **get_it: Async Singletons e allReady**

**Conceito Chave:** Suporte para Singletons que precisam inicialização assíncrona:

```dart
// Registrar singleton assíncrono
void registerSingletonAsync<T>(
  FactoryFuncAsync<T> factoryfunc, {
  String? instanceName,
  Iterable<Type> dependsOn,  // Dependências que devem estar prontas primeiro
  bool signalsReady = false,
});

// Aguardar todas as inicializações
Future<void> allReady({Duration? timeout});

// Sinalizar que está pronto manualmente
void signalReady(Object instance);
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Sistema de inicialização assíncrona de binds
- ✅ **Benefício:** Suportar serviços que precisam inicialização assíncrona (BD, API, etc)

---

## 🎯 **6. Sistema de Disposable**

### **get_it: Interface Disposable**

**Conceito Chave:** Interface para objetos que precisam cleanup:

```dart
abstract mixin class Disposable {
  FutureOr onDispose();
}

// Ao fazer dispose, chama automaticamente se implementado
if (instance is Disposable) {
  return (instance as Disposable).onDispose();
}
```

**Aplicação no Projeto:**
- ✅ **Já temos:** `CleanBind.fromInstance()` similar
- 🔄 **Melhorar:** Criar interface `Disposable` para tornar mais explícito
- 🔄 **Melhorar:** Suportar dispose assíncrono nativamente

---

## 🎯 **7. Shadow Change Handlers**

### **get_it: Notificação de Shadowing**

**Conceito Chave:** Objetos podem ser notificados quando são "sombreados" por outros:

```dart
abstract mixin class ShadowChangeHandlers {
  void onGetShadowed(Object shadowing);
  void onLeaveShadow(Object shadowing);
}

// Quando objeto é shadowed
if (objectThatWouldbeShadowed is ShadowChangeHandlers) {
  objectThatWouldbeShadowed.onGetShadowed(instance!);
}
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Sistema de notificação quando binds são substituídos
- ✅ **Benefício:** Permitir que objetos cancelem subscriptions quando não estão mais ativos

---

## 🎯 **8. Validação de Tipos em Runtime**

### **get_it: Validação de Parâmetros de Factory**

**Conceito Chave:** Valida tipos de parâmetros em debug mode:

```dart
void _validateFactoryParams(dynamic param1, dynamic param2) {
  if (!_isDebugMode) return;
  
  if (param1 != null || <P1?>[] is! List<P1>) {
    if (param1 is! P1) {
      throw ArgumentError(
        "GetIt: Cannot use parameter value of type '${param1.runtimeType}' "
        "as type '$P1' for factory of type '$T'."
      );
    }
  }
  // ...
}
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Validação de tipos em debug mode
- ✅ **Benefício:** Catch erros de tipo mais cedo e com mensagens melhores

---

## 🎯 **9. Weak References para Cached Factories**

### **get_it: WeakReference para Cached Factories**

**Conceito Chave:** Usa `WeakReference` para cached factories:

```dart
WeakReference<T>? weakReferenceInstance;

@override
T? get instance =>
    weakReferenceInstance != null && weakReferenceInstance!.target != null
        ? weakReferenceInstance!.target
        : _instance;
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Suporte para cached factories com weak references
- ✅ **Benefício:** Melhor gerenciamento de memória

---

## 🎯 **10. Múltiplas Instâncias do Mesmo Tipo**

### **get_it: enableRegisteringMultipleInstancesOfOneType**

**Conceito Chave:** Permite registrar múltiplas instâncias do mesmo tipo:

```dart
getIt.enableRegisteringMultipleInstancesOfOneType();

// Registrar múltiplas instâncias
getIt.registerLazySingleton<MyBase>(() => ImplA());
getIt.registerLazySingleton<MyBase>(() => ImplB());

// Buscar todas
final Iterable<MyBase> instances = getIt.getAll<MyBase>();
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Sistema para registrar múltiplas instâncias de um tipo
- ✅ **Benefício:** Útil para plugins, módulos, etc.

---

## 🎯 **11. Sistema de Commit**

### **auto_injector: commit() e uncommit()**

**Conceito Chave:** Garante que todas as dependências foram registradas antes de usar:

```dart
void commit();  // Marca como pronto para uso
void uncommit(); // Volta ao estado de edição

@override
T get<T>({ParamTransform? transform, String? key}) {
  _checkAutoInjectorIsCommitted(); // Lança erro se não commitado
  // ...
}
```

**Aplicação no Projeto:**
- ✅ **Já temos:** Similar com `_recursiveRegisterBinds`
- 🔄 **Melhorar:** Tornar mais explícito com métodos `commit()`/`uncommit()`

---

## 🎯 **12. Layers Graph (Grafo de Camadas)**

### **auto_injector: LayersGraph**

**Conceito Chave:** Grafo que gerencia múltiplos injectors hierárquicos:

```dart
final layersGraph = LayersGraph();

// Adiciona injector a uma camada
void addInjector(AutoInjector injector);

// Busca bind através do grafo
final data = layersGraph.getBindByKey(this, bindKey: key);
```

**Aplicação no Projeto:**
- ✅ **Já temos:** Sistema de módulos similar
- 🔄 **Melhorar:** Implementar grafo de camadas mais robusto para módulos aninhados

---

## 🎯 **13. Registros com Nome (Named Registration)**

### **get_it & auto_injector: instanceName**

**Conceito Chave:** Permite registrar múltiplas instâncias do mesmo tipo com nomes diferentes:

```dart
// Registrar com nome
getIt.registerSingleton<RestService>(() => RestService1(), instanceName: "rest1");
getIt.registerSingleton<RestService>(() => RestService2(), instanceName: "rest2");

// Buscar por nome
final rest1 = getIt.get<RestService>(instanceName: "rest1");
```

**Aplicação no Projeto:**
- ✅ **Já temos:** Sistema de `key` em binds
- ✅ **OK:** Funciona bem, apenas melhorar documentação

---

## 🎯 **14. tryGet() - Busca Segura**

### **auto_injector: tryGet**

**Conceito Chave:** Busca que retorna `null` em vez de lançar exceção:

```dart
T? tryGet<T>({ParamTransform? transform, String? key}) {
  try {
    return get<T>(transform: transform, key: key);
  } catch (e) {
    return null;
  }
}
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Método `tryGet()` para busca segura
- ✅ **Benefício:** Código mais limpo quando dependência é opcional

---

## 🎯 **15. Callable Class**

### **get_it: Callable Class**

**Conceito Chave:** Permite chamar GetIt como função:

```dart
final getIt = GetIt.instance;

// Em vez de
final instance = getIt.get<MyService>();

// Pode usar
final instance = getIt<MyService>();
```

**Aplicação no Projeto:**
- ❌ **NÃO implementado**
- ✅ **Implementar:** Tornar `Bind` ou `Injector` callable
- ✅ **Benefício:** API mais concisa

---

## 🎯 **16. Referência por Tipo Runtime**

### **get_it: get(type: Type)**

**Conceito Chave:** Permite buscar por tipo em runtime:

```dart
final instance = getIt.get(type: TestClass);
```

**Aplicação no Projeto:**
- ✅ **Já temos:** Similar com `_find<T>()`
- ✅ **OK:** Funciona bem

---

## 📋 **Prioridades de Implementação**

### **🔥 Alta Prioridade (Melhorias Imediatas)**

1. ✅ **Sistema de Parâmetros (Param System)** - Para testes e transformações
2. ✅ **tryGet()** - Busca segura
3. ✅ **Validação de Tipos em Runtime** - Melhor debugging
4. ✅ **Interface Disposable** - Mais explícito e robusto

### **⚡ Média Prioridade (Melhorias Importantes)**

5. ✅ **Sistema de Escopos** - Melhor isolamento de módulos
6. ✅ **Registros Assíncronos** - Suporte a inicialização assíncrona
7. ✅ **Melhor Detecção de Dependências** - Extrair todos os tipos do construtor
8. ✅ **Callable Class** - API mais concisa

### **💡 Baixa Prioridade (Nice to Have)**

9. ✅ **Weak References** - Para cached factories
10. ✅ **Múltiplas Instâncias do Mesmo Tipo** - Para plugins
11. ✅ **Shadow Change Handlers** - Notificações avançadas
12. ✅ **Layers Graph** - Grafo de camadas mais robusto

---

## 🎓 **Conceitos Arquiteturais Importantes**

### **1. Separação de Responsabilidades**
- **Bind:** Representa o registro de uma dependência
- **Injector:** Resolve e cria instâncias
- **LayersGraph/Scopes:** Gerencia hierarquia de registros

### **2. Lazy Evaluation**
- Singletons são criados apenas quando necessário
- Factories são criados a cada chamada
- LazySingletons são criados na primeira chamada

### **3. Error Handling**
- Mensagens de erro claras e informativas
- Stack traces detalhados mostrando cadeia de dependências
- Validação em debug mode para catch erros cedo

### **4. Performance**
- Cache de instâncias quando apropriado
- Weak references para evitar memory leaks
- Validação apenas em debug mode

---

## 📝 **Notas Finais**

Ambos os pacotes são muito bem arquitetados e oferecem funcionalidades robustas. O `auto_injector` é mais focado em injeção automática de dependências (análise estática), enquanto o `get_it` é mais um service locator com funcionalidades avançadas (scopes, async, etc).

**Recomendação:** Combinar os melhores aspectos de ambos:
- **Detecção automática** do `auto_injector`
- **Robustez e features** do `get_it`

