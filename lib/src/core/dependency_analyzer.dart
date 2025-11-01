import 'dart:collection';
import 'dart:math';

/// Analisador de dependências com cálculos probabilísticos e análise de grafos
class DependencyAnalyzer {
  /// Histórico de tentativas por tipo
  static final Map<Type, _TypeHistory> _typeHistory = {};

  /// Tipos atualmente em busca
  static final Set<Type> _activeSearches = {};

  /// Rastreamento de dependências (grafo direcionado)
  static final Map<Type, Set<Type>> _dependencyGraph = {};

  /// Configurações de análise
  static const double _baseSuccessProbability = 0.95;
  static const double _circularDependencyPenalty = 0.15;
  static const double _concurrentSearchPenalty = 0.10;
  static const int _historyWindow = 10;

  /// Registra uma tentativa de busca
  static void recordSearchAttempt(Type type, bool success) {
    final history = _typeHistory.putIfAbsent(type, () => _TypeHistory());
    history.addAttempt(success);
  }

  /// Registra uma dependência entre tipos
  static void recordDependency(Type from, Type to) {
    _dependencyGraph.putIfAbsent(from, () => <Type>{}).add(to);
  }

  /// Registra início de busca
  static void startSearch(Type type) {
    _activeSearches.add(type);
  }

  /// Registra fim de busca
  static void endSearch(Type type) {
    _activeSearches.remove(type);
  }

  /// Calcula a probabilidade de sucesso para uma busca baseado em:
  /// - Histórico de tentativas anteriores
  /// - Detecção de dependências circulares
  /// - Número de buscas simultâneas
  /// - Complexidade do grafo de dependências
  static double calculateSuccessProbability(Type type) {
    final history = _typeHistory[type];
    final hasHistory = history != null && history.attempts.isNotEmpty;

    // Probabilidade base
    double probability = _baseSuccessProbability;

    // Ajuste baseado em histórico
    if (hasHistory) {
      final successRate = history.successRate;
      // Se taxa de sucesso histórica é baixa, reduz probabilidade
      if (successRate < 0.5) {
        probability *= (0.3 + successRate * 0.4); // Reduz drasticamente
      } else {
        probability *= (0.7 + successRate * 0.3); // Ajuste moderado
      }
    }

    // Penalidade por dependência circular detectada
    if (_hasCircularDependency(type)) {
      probability *= (1.0 - _circularDependencyPenalty);
    }

    // Penalidade por múltiplas buscas simultâneas do mesmo tipo
    if (_activeSearches.contains(type)) {
      probability *= (1.0 - _concurrentSearchPenalty);
    }

    // Penalidade por alta complexidade do grafo
    final complexity = _calculateDependencyComplexity(type);
    if (complexity > 5) {
      final complexityPenalty = min(0.2, (complexity - 5) * 0.03);
      probability *= (1.0 - complexityPenalty);
    }

    return probability.clamp(0.0, 1.0);
  }

  /// Detecta dependências circulares usando DFS
  static bool _hasCircularDependency(Type type) {
    final visited = <Type>{};
    final recStack = <Type>{};

    bool dfs(Type node) {
      if (recStack.contains(node)) {
        return true; // Ciclo detectado
      }
      if (visited.contains(node)) {
        return false;
      }

      visited.add(node);
      recStack.add(node);

      final dependencies = _dependencyGraph[node] ?? {};
      for (final dep in dependencies) {
        if (dfs(dep)) {
          return true;
        }
      }

      recStack.remove(node);
      return false;
    }

    return dfs(type);
  }

  /// Calcula complexidade do grafo de dependências para um tipo
  static int _calculateDependencyComplexity(Type type) {
    final visited = <Type>{};
    int depth = 0;

    void dfs(Type node, int currentDepth) {
      if (visited.contains(node)) {
        return;
      }
      visited.add(node);
      depth = max(depth, currentDepth);

      final dependencies = _dependencyGraph[node] ?? {};
      for (final dep in dependencies) {
        dfs(dep, currentDepth + 1);
      }
    }

    dfs(type, 0);
    return depth;
  }

  /// Calcula o número máximo de tentativas baseado em análise probabilística
  /// Usa distribuição binomial negativa para estimar tentativas necessárias
  static int calculateMaxAttempts({
    required int totalBinds,
    required int unresolvedBinds,
    required double historicalSuccessRate,
  }) {
    if (totalBinds == 0) return 1;

    // Taxa de resolução estimada
    final resolutionRate = historicalSuccessRate > 0
        ? historicalSuccessRate
        : _baseSuccessProbability;

    // Fator de complexidade baseado no número de binds
    final complexityFactor = 1.0 + (log(totalBinds + 1) / log(10)) * 0.3;

    // Fator baseado em binds não resolvidos
    final unresolvedFactor = unresolvedBinds > 0
        ? 1.0 + (log(unresolvedBinds + 1) / log(10)) * 0.5
        : 1.0;

    // Estimativa usando distribuição binomial negativa
    // Esperança: E[X] = r * (1-p) / p, onde r = número de sucessos desejados
    // Para nosso caso: r = totalBinds, p = resolutionRate
    final expectedAttempts = totalBinds * (1.0 - resolutionRate) / resolutionRate;

    // Aplicar fatores de complexidade
    final adjustedAttempts = expectedAttempts * complexityFactor * unresolvedFactor;

    // Limites razoáveis: mínimo 3 para casos normais, máximo baseado em análise estatística
    final maxAttempts = adjustedAttempts.ceil();
    // Garante que maxAttempts seja pelo menos 3 para casos normais, mas permite 1 apenas em casos extremos
    final boundedMaxAttempts = maxAttempts < 1 
        ? 1 
        : (maxAttempts < 3 && totalBinds > 0 ? 3 : maxAttempts.clamp(1, totalBinds * 2));

    return boundedMaxAttempts;
  }

  /// Calcula maxAttempts para _recursiveRegisterBinds baseado em:
  /// - Número de binds pendentes
  /// - Taxa de resolução histórica
  /// - Complexidade estimada do grafo
  static int calculateRecursiveMaxAttempts(List<dynamic> binds) {
    if (binds.isEmpty) return 1;

    final totalBinds = binds.length;
    final unresolvedBinds = binds.length;

    // Calcular taxa de sucesso histórica média
    double avgSuccessRate = 0.0;
    int typesWithHistory = 0;

    for (final bind in binds) {
      try {
        final type = bind.instance.runtimeType;
        final history = _typeHistory[type];
        if (history != null && history.attempts.isNotEmpty) {
          avgSuccessRate += history.successRate;
          typesWithHistory++;
        }
      } catch (_) {
        // Ignorar erros ao acessar tipo
      }
    }

    final historicalSuccessRate = typesWithHistory > 0
        ? avgSuccessRate / typesWithHistory
        : _baseSuccessProbability;

    return calculateMaxAttempts(
      totalBinds: totalBinds,
      unresolvedBinds: unresolvedBinds,
      historicalSuccessRate: historicalSuccessRate,
    );
  }

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

  /// Verifica se deve permitir nova tentativa baseado em probabilidade
  static bool shouldAllowRetry(Type type, int currentAttempt) {
    final probability = calculateSuccessProbability(type);
    
    // Limite máximo rigoroso: máximo 3 tentativas baseado em probabilidade
    const maxAttemptsByProbability = 3;
    
    // Se probabilidade é muito baixa (< 0.2), não permite mais tentativas após primeira
    if (probability < 0.2 && currentAttempt > 1) {
      return false;
    }
    
    return currentAttempt <= maxAttemptsByProbability;
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

