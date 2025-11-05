import 'package:go_router_modular/src/core/bind/bind_search_validator.dart';
import 'package:go_router_modular/src/core/bind/bind_key_searcher.dart';
import 'package:go_router_modular/src/core/bind/bind_type_searcher.dart';
import 'package:go_router_modular/src/core/bind/bind_type_discoverer.dart';
import 'package:go_router_modular/src/core/bind/bind_compatibility_searcher.dart';
import 'package:go_router_modular/src/core/bind/bind_instance_validator.dart';
import 'package:go_router_modular/src/core/bind/bind_error_handler.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';

/// Responsável APENAS por orquestrar a busca de binds
/// Responsabilidade única: Coordenar as diferentes estratégias de busca
class BindLocator {
  final BindSearchValidator _validator = BindSearchValidator();
  final BindKeySearcher _keySearcher = BindKeySearcher();
  final BindTypeSearcher _typeSearcher = BindTypeSearcher();
  final BindTypeDiscoverer _discoverer = BindTypeDiscoverer();
  final BindCompatibilitySearcher _compatibilitySearcher = BindCompatibilitySearcher();
  final BindInstanceValidator _instanceValidator = BindInstanceValidator();
  final BindErrorHandler _errorHandler = BindErrorHandler();
  final BindStorage _storage = BindStorage.instance;

  /// Busca um bind por tipo e key
  /// Orquestra as diferentes estratégias de busca
  T find<T>({String? key}) {
    final type = T;

    _validator.validateCanStartSearch(type);
    final attemptCount = _validator.startSearchTracking(type);

    try {
      final instance = _locateBind<T>(type, key, attemptCount);
      _validator.endSearchSuccess(type);
      return instance;
    } catch (e) {
      _validator.endSearchFailure(type);
      rethrow;
    } finally {
      _validator.cleanupSearchState(type);
    }
  }

  /// Localiza o bind usando diferentes estratégias
  T _locateBind<T>(Type type, String? key, int attemptCount) {
    // Estratégia 1: Busca por key (se fornecida)
    if (key != null) {
      final bind = _keySearcher.searchByKey<T>(type, key);
      if (bind != null) {
        final instance = _keySearcher.createInstanceFromKeyBind<T>(bind);
        DependencyAnalyzer.recordSearchAttempt(type, true);
        DependencyAnalyzer.endSearch(type);
        return instance;
      }
    }

    // Estratégia 2: Busca por tipo direto
    final bind = _typeSearcher.searchByType<T>(type, key);
    if (bind != null) {
      return _typeSearcher.createInstanceFromTypeBind<T>(bind);
    }

    // Estratégia 3: Descobre de Object binds
    final discoveredFromObject = _discoverer.discoverFromObjectBinds<T>(type);
    if (discoveredFromObject != null) {
      final instance = _discoverer.createInstanceFromDiscoveredBind<T>(discoveredFromObject);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);
      return instance;
    }

    // Estratégia 4: Descobre de binds pendentes
    final discoveredFromPending = _discoverer.discoverFromPendingBinds<T>(type);
    if (discoveredFromPending != null) {
      final instance = _discoverer.createInstanceFromDiscoveredBind<T>(discoveredFromPending);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);
      return instance;
    }

    // Estratégia 5: Busca por compatibilidade
    final compatibleBind = _compatibilitySearcher.searchCompatibleBind<T>(type);
    if (compatibleBind != null) {
      final instance = _compatibilitySearcher.createInstanceFromCompatibleBind<T>(compatibleBind);
      DependencyAnalyzer.recordSearchAttempt(type, true);
      DependencyAnalyzer.endSearch(type);
      return instance;
    }

    // Não encontrou - lança exceção
    _errorHandler.throwNotFound(type, key, attemptCount);
  }

  /// Método público get (delega para find)
  T get<T>({String? key}) {
    final instance = find<T>(key: key);

    // Validação extra de ChangeNotifier
    if (key == null) {
      _instanceValidator.validateChangeNotifier(instance);
    }

    return instance;
  }

  /// Tenta obter uma instância sem lançar exceção se não encontrar
  T? tryGet<T>({String? key}) {
    try {
      return get<T>(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se um bind está registrado para o tipo especificado
  bool isRegistered<T>({String? key}) {
    if (key != null) {
      return _storage.bindsMapByKey.containsKey(key);
    }
    return _storage.bindsMap.containsKey(T);
  }
}
