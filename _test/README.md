# Testes do EventModule - go_router_modular

Este arquivo contém testes unitários abrangentes para o sistema de eventos do go_router_modular, especificamente para as classes `EventModule` e `ModularEvent`.

## Estrutura dos Testes

### 1. Testes do Parâmetro `exclusive`

**Objetivo**: Verificar o comportamento do parâmetro `exclusive` que controla se o stream é broadcast ou não.

- ✅ **exclusive=true**: Usa `asBroadcastStream()` e permite múltiplos listeners
- ✅ **exclusive=false**: Usa stream normal
- ✅ **Troca entre modos**: Verifica cancelamento correto de subscriptions anteriores

### 2. Testes de Dispose

**Objetivo**: Verificar gerenciamento de memória e limpeza de listeners.

- ✅ **Dispose automático**: `autoDispose=true` remove listeners quando módulo é destruído
- ✅ **Persist após dispose**: `autoDispose=false` mantém listeners após dispose do módulo
- ✅ **Configuração global**: Respeita `SetupModular.instance.autoDisposeEvents`
- ✅ **Dispose manual**: ModularEvent.instance.dispose<T>() funciona corretamente

### 3. Testes de Memory Leak

**Objetivo**: Detectar vazamentos de memória com múltiplos módulos e eventos.

- ✅ **Múltiplos módulos**: Criação e dispose de vários módulos simultaneamente
- ✅ **Eventos diferentes**: Gerenciamento correto de tipos diferentes de eventos
- ✅ **Limpeza de subscriptions**: Verificação de remoção correta dos mapas globais

### 4. Testes do ModularEvent Singleton

**Objetivo**: Verificar padrão singleton e funcionalidades básicas.

- ✅ **Instância única**: Verificação do padrão singleton
- ✅ **Fire de eventos**: ModularEvent.fire() funciona corretamente

### 5. Testes de EventBus Personalizado

**Objetivo**: Verificar isolamento entre diferentes instâncias de EventBus.

- ✅ **Isolamento**: Eventos em EventBus diferentes não se cruzam
- ✅ **Múltiplos EventBus**: ModularEvent suporta múltiplos EventBus corretamente

### 6. Testes de Configuração AutoDispose

**Objetivo**: Verificar override de configurações globais.

- ✅ **Override global para true**: `autoDispose=true` sobrescreve configuração global `false`
- ✅ **Override global para false**: `autoDispose=false` sobrescreve configuração global `true`

### 7. Testes de Context

**Objetivo**: Verificar comportamento do BuildContext em callbacks.

- ✅ **Context null**: Funciona corretamente quando NavigatorKey não está configurado

### 8. Testes de Debug Logging

**Objetivo**: Verificar logging quando habilitado.

- ✅ **Debug logging**: Verifica que não há errors quando debug está ligado

### 9. Testes de Edge Cases

**Objetivo**: Casos limites e situações especiais.

- ✅ **Eventos vazios**: Funciona corretamente com eventos sem propriedades
- ✅ **Múltiplos listeners no mesmo módulo**: Último listener cancela anteriores
- ✅ **Dispose sem listeners**: Não causa erros

## Bugs Identificados e Corrigidos

### ✅ Bug Corrigido: ModularEvent não inicializava mapa `_eventSubscriptions`

**Localização**: `lib/src/utils/event_module.dart`, linhas 155-156

**Problema**: A classe `ModularEvent` não inicializava o mapa `_eventSubscriptions[eventBus.hashCode]` antes de usar, causando null pointer exception.

**Solução Implementada**:
```dart
// Na classe ModularEvent, método on(), linha 156:
_eventSubscriptions[eventBusId] ??= {};
```

**Status**: ✅ **CORRIGIDO** - Todos os testes agora passam!

## Como Executar os Testes

### Executar todos os testes:
```bash
flutter test test/event_module_test.dart
```

### Executar um teste específico:
```bash
flutter test test/event_module_test.dart --plain-name "nome do teste"
```

### Executar por grupo:
```bash
# Testes de exclusive
flutter test test/event_module_test.dart --plain-name "Exclusive Parameter Tests"

# Testes de dispose
flutter test test/event_module_test.dart --plain-name "Dispose Tests"

# Testes de memory leak
flutter test test/event_module_test.dart --plain-name "Memory Leak Tests"
```

## Status Atual

- ✅ **21 testes passando** (100% dos testes implementados)
- ✅ **0 testes falhando**
- ✅ **Bug crítico corrigido** no ModularEvent

## Eventos de Teste

Os testes utilizam as seguintes classes de eventos:

```dart
class TestEvent {
  final String message;
  const TestEvent(this.message);
}

class AnotherTestEvent {
  final int value;
  const AnotherTestEvent(this.value);
}

class MemoryLeakTestEvent {
  final String data;
  const MemoryLeakTestEvent(this.data);
}

class EmptyEvent {}
```

## Módulos de Teste

### TestEventModule
Módulo básico que escuta múltiplos tipos de eventos para testar funcionalidades gerais.

### NonAutoDisposeEventModule
Módulo configurado com `autoDispose=false` para testar persistência de listeners.

### CustomEventBusModule
Módulo que usa EventBus personalizado para testar isolamento.

## Configurações de Teste

Os testes inicializam:
- `TestWidgetsFlutterBinding.ensureInitialized()` - Para suporte ao Flutter
- `modularNavigatorKey` - GlobalKey para navegação (se necessário)
- `SetupModular.instance` - Configurações globais resetadas antes de cada teste

## Próximos Passos

1. ✅ **Corrigir bug do ModularEvent**: ~~Adicionar inicialização do mapa~~ **CONCLUÍDO**
2. ✅ **Descomentar testes**: ~~Após correção, habilitar todos os testes~~ **CONCLUÍDO**
3. **Adicionar mais edge cases**: Cenários complexos de uso
4. **Testes de performance**: Para sistemas com muitos eventos
5. **Testes de concorrência**: Eventos simultâneos
6. **Testes de integração**: Testar com aplicações Flutter reais

---

**Nota**: Este sistema de testes está preparado para detectar regressões e validar novas funcionalidades do sistema de eventos do go_router_modular.
