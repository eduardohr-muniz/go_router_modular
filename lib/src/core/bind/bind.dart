import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/core/bind/bind_registry.dart';
import 'package:go_router_modular/src/core/bind/bind_disposer.dart';
import 'package:go_router_modular/src/core/bind/bind_locator.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Representa um bind (ligação) entre um tipo e sua factory function
/// Responsabilidade única: Representar um bind e gerenciar SUA PRÓPRIA instância
class Bind<T> {
  final T Function(Injector i) factoryFunction;
  final bool isSingleton;
  final bool isLazy;
  final String? key;
  final StackTrace stackTrace;

  // Exposto para permitir acesso controlado pelas classes especializadas
  T? _cachedInstance;

  Bind(this.factoryFunction, {this.isSingleton = true, this.isLazy = false, this.key}) : stackTrace = StackTrace.current;

  T get instance {
    if (_cachedInstance == null || !isSingleton) {
      _cachedInstance = factoryFunction(Injector());
    }

    // Verifica se a instância foi disposta (para ChangeNotifier e similares)
    if (_cachedInstance != null) {
      try {
        // Tenta verificar se é um ChangeNotifier disposto
        if (_cachedInstance is ChangeNotifier) {
          final notifier = _cachedInstance as ChangeNotifier;
          // Tenta usar um método que lança exceção se disposto
          // Apenas testa se o objeto ainda está válido sem acessar propriedades protegidas
          try {
            // Se conseguir adicionar um listener temporário (que será removido imediatamente),
            // o objeto ainda está válido. Se não conseguir, foi disposto.
            final testListener = () {};
            notifier.addListener(testListener);
            notifier.removeListener(testListener);
          } catch (e) {
            // Se lançar exceção, o objeto foi disposto - cria nova instância
            if (!isSingleton) {
              final newInstance = factoryFunction(Injector());
              return newInstance;
            }
            _cachedInstance = factoryFunction(Injector());
          }
        }
      } catch (e) {
        // Se falhar ao verificar, assume que está válido
      }
    }

    return _cachedInstance!;
  }

  /// Obtém a instância cacheada (sem criar nova)
  T? get cachedInstance => _cachedInstance;

  /// Define a instância cacheada
  set cachedInstance(T? value) => _cachedInstance = value;

  /// Limpa a instância cacheada (usado quando o bind é disposto)
  void clearCache() {
    _cachedInstance = null;
  }

  // ==================== DELEGAÇÃO PARA CLASSES ESPECIALIZADAS ====================
  // Cada classe tem UMA responsabilidade única

  static final BindRegistry _registry = BindRegistry();
  static final BindDisposer _disposer = BindDisposer();
  static final BindLocator _locator = BindLocator();
  static final BindStorage _storage = BindStorage.instance;
  static final BindSearchProtection _protection = BindSearchProtection.instance;

  // ==================== MÉTODOS ESTÁTICOS (DELEGAÇÃO) ====================

  /// Registra um bind preservando seu tipo genérico original
  static void register(dynamic bind) => _registry.register(bind);

  /// Versão genérica para compatibilidade (usa o tipo genérico se fornecido)
  static void registerTyped<T>(Bind<T> bind) => _registry.registerTyped<T>(bind);

  /// Faz dispose de um bind por tipo genérico
  static void dispose<T>() => _disposer.dispose<T>();

  /// Faz dispose de um bind por key
  static void disposeByKey(String key) => _disposer.disposeByKey(key);

  /// Faz dispose de todos os binds de um tipo específico
  static void disposeByType(Type type) => _disposer.disposeByType(type);

  /// Limpa todos os binds do sistema
  static void clearAll() => _disposer.clearAll();

  /// Busca e retorna uma instância do tipo especificado
  static T get<T>({String? key}) => _locator.get<T>(key: key);

  /// Tenta obter uma instância sem lançar exceção se não encontrar
  static T? tryGet<T>({String? key}) => _locator.tryGet<T>(key: key);

  /// Verifica se um bind está registrado para o tipo especificado
  static bool isRegistered<T>({String? key}) => _locator.isRegistered<T>(key: key);

  /// Obtém todas as keys registradas
  static List<String> getAllKeys() => _storage.bindsMapByKey.keys.toList();

  /// Limpa todo o estado de busca
  static void cleanSearchAttempts() => _protection.clearAll();

  /// Limpa estado de busca para um tipo específico
  static void cleanSearchAttemptsForType(Type type) {
    _protection.clearForType(type);
    DependencyAnalyzer.clearTypeHistory(type);
  }

  // ==================== FACTORY METHODS ====================

  /// Cria um singleton (instância única, criada imediatamente)
  static Bind<T> singleton<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: false, key: key);
  }

  /// Cria um lazy singleton (instância única, criada quando necessário)
  static Bind<T> lazySingleton<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: true, isLazy: true, key: key);
  }

  /// Cria um factory bind (nova instância a cada chamada)
  @Deprecated('Use Bind.add instead')
  static Bind<T> factory<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }

  /// Cria um transient bind (nova instância a cada chamada)
  static Bind<T> add<T>(T Function(Injector i) builder, {String? key}) {
    return Bind<T>(builder, isSingleton: false, isLazy: false, key: key);
  }
}
