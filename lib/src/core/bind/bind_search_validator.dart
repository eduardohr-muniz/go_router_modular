import 'package:go_router_modular/src/core/bind/bind_search_protection.dart';
import 'package:go_router_modular/src/core/dependency_analyzer/dependency_analyzer.dart';
import 'package:go_router_modular/src/exceptions/exception.dart';

/// Responsável APENAS por validar limites de busca
/// Responsabilidade única: Validação de estado de busca para prevenir loops
class BindSearchValidator {
  final BindSearchProtection _protection = BindSearchProtection.instance;
  static const int maxAbsoluteAttempts = 3;

  /// Valida se pode iniciar uma busca
  /// Lança exceção se limites forem atingidos
  void validateCanStartSearch(Type type) {
    final currentAttempts = _protection.searchAttempts[type] ?? 0;

    if (currentAttempts >= maxAbsoluteAttempts) {
      // Limpa estado e lança exceção imediatamente
      _protection.searchAttempts.remove(type);
      _protection.currentlySearching.remove(type);
      DependencyAnalyzer.recordSearchAttempt(type, false);
      DependencyAnalyzer.endSearch(type);
      throw GoRouterModularException('❌ Too many search attempts ($currentAttempts) for type "${type.toString()}". '
          'Possible infinite loop detected. Please ensure the bind is registered before use.');
    }

    // Proteção contra múltiplas buscas simultâneas do mesmo tipo
    if (_protection.currentlySearching.contains(type)) {
      throw GoRouterModularException('❌ Type "${type.toString()}" is already being searched. '
          'Possible infinite loop detected. Please ensure the bind is registered before use.');
    }
  }

  /// Inicia o rastreamento de uma busca
  int startSearchTracking(Type type) {
    final currentAttempts = _protection.searchAttempts[type] ?? 0;
    _protection.searchAttempts[type] = currentAttempts + 1;
    _protection.currentlySearching.add(type);
    DependencyAnalyzer.startSearch(type);
    return _protection.searchAttempts[type]!;
  }

  /// Finaliza busca com sucesso
  void endSearchSuccess(Type type) {
    _protection.searchAttempts.remove(type);
    DependencyAnalyzer.recordSearchAttempt(type, true);
    DependencyAnalyzer.endSearch(type);
  }

  /// Finaliza busca com falha
  void endSearchFailure(Type type) {
    _protection.searchAttempts.remove(type);
    DependencyAnalyzer.recordSearchAttempt(type, false);
    DependencyAnalyzer.endSearch(type);
  }

  /// Limpa estado de busca (usado no finally)
  void cleanupSearchState(Type type) {
    _protection.currentlySearching.remove(type);
    DependencyAnalyzer.endSearch(type);
  }
}
