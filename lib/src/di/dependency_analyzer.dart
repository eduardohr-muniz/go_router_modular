import 'dart:collection';

/// Analisador de dependências para rastreamento e estatísticas
/// Responsabilidade única: Rastrear buscas e dependências para análise
class DependencyAnalyzer {
  /// Histórico de tentativas por tipo
  static final Map<Type, _TypeHistory> _typeHistory = {};

  /// Tipos atualmente em busca
  static final Set<Type> _activeSearches = {};

  /// Rastreamento de dependências (grafo direcionado)
  static final Map<Type, Set<Type>> _dependencyGraph = {};

  /// Configurações
  static const int _historyWindow = 10;

  // ==================== RASTREAMENTO DE BUSCAS ====================

  /// Registra uma tentativa de busca
  static void recordSearchAttempt(Type type, bool success) {
    final history = _typeHistory.putIfAbsent(type, () => _TypeHistory());
    history.addAttempt(success);
  }

  /// Registra início de busca
  static void startSearch(Type type) {
    _activeSearches.add(type);
  }

  /// Registra fim de busca
  static void endSearch(Type type) {
    _activeSearches.remove(type);
  }

  // ==================== RASTREAMENTO DE DEPENDÊNCIAS ====================

  /// Registra uma dependência entre tipos
  static void recordDependency(Type from, Type to) {
    _dependencyGraph.putIfAbsent(from, () => <Type>{}).add(to);
  }

  // ==================== LIMPEZA ====================

  /// Limpa histórico de um tipo específico
  static void clearTypeHistory(Type type) {
    _typeHistory.remove(type);
    _dependencyGraph.remove(type);
    // Remove também das dependências de outros tipos
    for (final deps in _dependencyGraph.values) {
      deps.remove(type);
    }
  }

  /// Limpa todo o histórico
  static void clearAll() {
    _typeHistory.clear();
    _dependencyGraph.clear();
    _activeSearches.clear();
  }
}

/// Histórico de tentativas para um tipo específico
class _TypeHistory {
  final Queue<bool> attempts = Queue<bool>();

  void addAttempt(bool success) {
    attempts.add(success);
    // Manter apenas últimas N tentativas
    while (attempts.length > DependencyAnalyzer._historyWindow) {
      attempts.removeFirst();
    }
  }

  double get successRate {
    if (attempts.isEmpty) return 1.0;
    final successes = attempts.where((s) => s).length;
    return successes / attempts.length;
  }
}
