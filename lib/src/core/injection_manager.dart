import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:go_router_modular/src/di/bind_indentifier.dart';
import 'package:go_router_modular/src/internal/setup.dart';
import 'package:go_router_modular/src/internal/internal_logs.dart';
import 'package:go_router_modular/src/core/dependency_analyzer.dart';

/// ValueObject para representar um bind único (Type + Key)

class InjectionManager {
  static InjectionManager? _instance;
  InjectionManager._();
  static InjectionManager get instance => _instance ??= InjectionManager._();

  final Map<BindIdentifier, int> _bindReferences = {};
  Module? _appModule;

  final Injector _injector = Injector();

  final Map<Module, Set<BindIdentifier>> _moduleBindTypes = {};

  final List<Function> _bindsToValidate = [];

  bool get debugLog => SetupModular.instance.debugLogGoRouterModular;

  // Sistema de fila sequencial para operações de módulos
  final Queue<Future<void> Function()> _operationQueue = Queue<Future<void> Function()>();
  bool _isProcessingQueue = false;

  // Processa operações na fila sequencialmente
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _operationQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    try {
      while (_operationQueue.isNotEmpty) {
        final operation = _operationQueue.removeFirst();

        try {
          await operation();
        } catch (e) {
          // Se for GoRouterModularException, propaga para o usuário
          if (e is GoRouterModularException) {
            rethrow;
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  // Adiciona operação à fila e garante processamento sequencial
  Future<T> _enqueueOperation<T>(Future<T> Function() operation) async {
    final completer = Completer<T>();

    _operationQueue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        // Sempre propaga exceptions via completer para que sejam vistas pelo usuário
        completer.completeError(e);
      }
    });

    // Inicia processamento se não estiver rodando
    _processQueue();

    return completer.future;
  }

  void addValidateQueue(void Function() validate, String moduleName) {
    _bindsToValidate.add(validate);

    if (debugLog) {
      iLog('⏰ Validação agendada para $moduleName (janela: 500ms)', name: "BIND_VALIDATION");
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      final removed = _bindsToValidate.remove(validate);
      if (removed && debugLog) {
        iLog('⏭️ Validação expirada para $moduleName - nenhum dispose detectado', name: "BIND_VALIDATION");
      }
    });
  }

  bool _isBindForAppModule(BindIdentifier bindId) {
    final isForAppModule = _moduleBindTypes[_appModule]?.contains(bindId) ?? false;
    return isForAppModule;
  }

  Future<void> registerAppModule(Module module) async {
    if (_appModule != null) {
      return;
    }
    _appModule = module;

    await registerBindsModule(module);
  }

  /// Coleta recursivamente todos os binds de imports aninhados
  Future<List<Bind<Object>>> _getAllImportedBindsRecursively(Module module, [Set<Module>? visited]) async {
    visited ??= <Module>{};
    Set<Bind<Object>> allImportedBinds = {};

    if (visited.contains(module)) {
      return allImportedBinds.toList();
    }
    visited.add(module);

    final imports = await module.imports();

    await Future.forEach(imports, (module) async {
      final binds = await module.binds();
      allImportedBinds.addAll(binds);
      allImportedBinds.addAll(await _getAllImportedBindsRecursively(module, visited));
    });

    return allImportedBinds.toList();
  }

  Future<void> registerBindsModule(Module module) async {
    return _enqueueOperation(() => _registerBindsModuleInternal(module));
  }

  Future<void> _registerBindsModuleInternal(Module module) async {
    if (_moduleBindTypes.containsKey(module)) {
      return;
    }

    final moduleBinds = await module.binds();

    final importedBinds = await _getAllImportedBindsRecursively(module);

    List<Bind<Object>> allBinds = [...moduleBinds, ...importedBinds];

    _recursiveRegisterBinds(allBinds);
    // Usa tipos descobertos ou tenta criar instância para descobrir tipo
    _moduleBindTypes[module] = allBinds.map((e) {
      try {
        final instance = e.factoryFunction(_injector);
        final type = instance.runtimeType;
        return BindIdentifier(type, e.key ?? type.toString());
      } catch (_) {
        // Se não conseguir criar instância, usa Object como fallback
        return BindIdentifier(Object, e.key ?? 'Object');
      }
    }).toSet();

    module.initState(_injector);

    if (debugLog) {
      log(
          '💉 INJECTED 🧩 MODULE: ${module.runtimeType} \nBINDS: { \n${allBinds.isEmpty ? '😴 EMPTY' : ''}${allBinds.map(
                (e) {
                  try {
                    final instance = e.factoryFunction(_injector);
                    final type = instance.runtimeType.toString();
                    return '♻️ $type(${e.key != null ? (e.key == type ? '' : 'key: ${e.key}') : ''})';
                  } catch (_) {
                    return '♻️ Object(${e.key != null ? 'key: ${e.key}' : ''})';
                  }
                },
              ).toList().join('\n')} \n}',
          name: "GO_ROUTER_MODULAR");
    }

    // Validação simples após 500ms
    addValidateQueue(() => _validateModuleBinds(module, allBinds), module.runtimeType.toString());
  }

  void _validateModuleBinds(Module module, List<Bind<Object>> moduleBinds) {
    if (debugLog) {
      iLog('🧪 Iniciando validação de ${moduleBinds.length} binds do ${module.runtimeType}', name: "BIND_VALIDATION");
    }

    // Lista para rastrear instâncias temporárias (evitar memory leak)
    List<dynamic> tempInstances = [];

    int successCount = 0;
    int errorCount = 0;

    try {
      // Testar cada bind FORÇANDO nova criação
      for (Bind<Object> bind in moduleBinds) {
        Type? bindType;
        try {
          // Tenta criar instância para descobrir tipo
          var newInstance = bind.factoryFunction(_injector);
          bindType = newInstance.runtimeType;

          // Adicionar à lista temporária para limpeza posterior
          tempInstances.add(newInstance);
          successCount++;

          if (debugLog) {
            iLog('✅ $bindType validado', name: "BIND_VALIDATION");
          }
        } catch (e) {
          if (bindType == null) {
            try {
              bindType = bind.instance.runtimeType;
            } catch (_) {
              bindType = Object;
            }
          }
          errorCount++;

          if (debugLog) {
            final stackTrace = bind.stackTrace.toString();
            final normalizedStack = _normalizeStackTrace(stackTrace);
            log('❌ $bindType FAILED: $e \n🔎STACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
            throw GoRouterModularException('❌ Bind not found for type ${bindType.toString()}');
          }
        }
      }
    } finally {
      // DESCARTAR todas as instâncias criadas para validação
      final instanceCount = tempInstances.length;
      tempInstances.clear();

      if (debugLog) {
        iLog('🧹 $instanceCount instâncias temporárias descartadas', name: "BIND_VALIDATION");
      }
    }

    // Resultado final da validação
    if (debugLog) {
      if (errorCount == 0) {
        iLog('🎉 ${module.runtimeType}: Validação completa - todos os binds OK (✅$successCount)', name: "BIND_VALIDATION");
      } else {
        iLog('⚠️ ${module.runtimeType}: Validação completa - ✅$successCount ❌$errorCount', name: "BIND_VALIDATION");
      }
    }
  }

  // Normaliza caminhos do stacktrace para o formato padrão
  String _normalizeStackTrace(String stackTrace) {
    return stackTrace
        .split('\n')
        .where((line) => line.contains('binds') || line.contains('imports'))
        .map((line) {
          // Remove prefixos como "../" e normaliza o caminho
          String normalized = line
              .replaceAll('../packages/', 'packages/')
              .replaceAll(RegExp(r'^\s*\.\.\/'), '') // Remove ../ do início
              .trim();

          // Extrair apenas a parte a partir de 'lib/'
          if (normalized.contains('/lib/')) {
            final libIndex = normalized.indexOf('/lib/');
            return normalized.substring(libIndex + 1); // +1 para remover a barra inicial
          }

          // Se já começa com 'lib/', manter como está
          if (normalized.startsWith('lib/')) {
            return normalized;
          }

          // Se começar com packages/ mas não tiver /lib/, inserir lib/ e extrair
          if (normalized.startsWith('packages/')) {
            final parts = normalized.split('/');
            if (parts.length >= 3) {
              // packages/nome_projeto/src/... -> lib/src/...
              if (!parts.contains('lib')) {
                parts.insert(2, 'lib');
              }
              // Pegar apenas a partir de 'lib/'
              final libIndexInParts = parts.indexOf('lib');
              if (libIndexInParts != -1) {
                return parts.sublist(libIndexInParts).join('/');
              }
            }
          }

          return normalized;
        })
        .take(4)
        .join('\n');
  }

  /// Registra binds recursivamente usando cálculo probabilístico inteligente
  /// para determinar o número máximo de tentativas baseado em:
  /// - Número total de binds
  /// - Taxa de resolução histórica
  /// - Complexidade estimada do grafo de dependências
  void _recursiveRegisterBinds(List<Bind<Object>> binds) {
    if (binds.isEmpty) {
      return;
    }

    // Calcula maxAttempts usando análise probabilística
    final maxAttempts = DependencyAnalyzer.calculateRecursiveMaxAttempts(binds);

    if (debugLog) {
      iLog('🔄 _recursiveRegisterBinds: Iniciando registro de ${binds.length} binds com maxAttempts calculado: $maxAttempts', name: 'BIND_REGISTER');
    }

    _recursiveRegisterBindsInternal(binds, maxAttempts);
  }

  void _recursiveRegisterBindsInternal(List<Bind<Object>> binds, int maxAttempts) {
    if (binds.isEmpty || maxAttempts <= 0) {
      if (debugLog && binds.isNotEmpty) {
        iLog('⚠️ _recursiveRegisterBinds: MaxAttempts atingido ($maxAttempts) com ${binds.length} binds pendentes', name: 'BIND_REGISTER');
      }
      return;
    }

    List<Bind<Object>> failedBinds = [];
    int successCount = 0;

    for (var bind in binds) {
      try {
        // Registra o bind sem tentar criar instância primeiro
        Bind.register(bind);

        // Após registrar, tenta descobrir o tipo real criando a instância
        // Se falhar (dependências não disponíveis), continua e tenta depois
        Type? discoveredType;
        try {
          final instance = bind.factoryFunction(_injector);
          discoveredType = instance.runtimeType;

          // Se descobriu um tipo diferente de Object, atualiza o registro
          // Nota: Não podemos acessar _bindsMap diretamente pois é privado em Bind
          // O Bind.register já trata isso internamente

          final key = bind.key ?? discoveredType.toString();
          final bindId = BindIdentifier(discoveredType, key);
          _incrementBindReference(bindId);
          DependencyAnalyzer.recordSearchAttempt(discoveredType, true);
          successCount++;
        } catch (e) {
          // Se não conseguir criar instância agora, ainda considera sucesso
          // porque o bind foi registrado. O tipo será descoberto quando necessário
          iLog('⚠️ Não foi possível criar instância após registro: $e. Tipo será descoberto quando necessário.', name: 'BIND_REGISTER');
          DependencyAnalyzer.recordSearchAttempt(Object, true); // Registra tentativa como sucesso genérico
          successCount++;
        }
      } catch (e) {
        failedBinds.add(bind);
        DependencyAnalyzer.recordSearchAttempt(Object, false);
      }
    }

    if (debugLog) {
      iLog('📊 _recursiveRegisterBinds: Iteração completa - ✅$successCount sucessos, ❌${failedBinds.length} falhas (maxAttempts restantes: ${maxAttempts - 1})', name: 'BIND_REGISTER');
    }

    // Se ainda há binds que falharam, calcula novo maxAttempts baseado em progresso
    if (failedBinds.isNotEmpty && failedBinds.length < binds.length) {
      // Taxa de progresso nesta iteração
      final progressRate = successCount / binds.length;

      // Se houve progresso significativo (>50%), permite mais tentativas
      // Caso contrário, reduz drasticamente
      final adjustedMaxAttempts = progressRate > 0.5 ? maxAttempts - 1 : max(1, (maxAttempts * 0.5).ceil());

      if (debugLog) {
        iLog('🔄 _recursiveRegisterBinds: Recursão com ${failedBinds.length} binds pendentes (taxa progresso: ${(progressRate * 100).toStringAsFixed(1)}%, novo maxAttempts: $adjustedMaxAttempts)', name: 'BIND_REGISTER');
      }

      _recursiveRegisterBindsInternal(failedBinds, adjustedMaxAttempts);
    } else if (failedBinds.isNotEmpty) {
      // Nenhum progresso foi feito - todos falharam
      for (var bind in failedBinds) {
        final stackTrace = bind.stackTrace.toString();
        final normalizedStack = _normalizeStackTrace(stackTrace);
        try {
          final instance = bind.factoryFunction(_injector);
          final type = instance.runtimeType;
          log('❌ $type FAILED:  \n🔎STACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
          throw GoRouterModularException('❌ Bind not found for type ${type.toString()}');
        } catch (e) {
          if (e is GoRouterModularException) rethrow;
          log('❌ Object FAILED:  \n🔎STACKTRACE: \n$normalizedStack', name: "GO_ROUTER_MODULAR");
          throw GoRouterModularException('❌ Bind not found for type Object');
        }
      }
    }
  }

  Future<void> unregisterBinds(Module module) async {
    if (_appModule != null && module == _appModule!) {
      return;
    }

    final Set<BindIdentifier> bindsToDispose = _moduleBindTypes[module] ?? {};

    List<BindIdentifier> disposedBinds = [];

    // Decrementar referências para cada bind único
    for (var bindId in bindsToDispose) {
      try {
        // Decrementar a referência para cada bind do módulo
        final disposed = _decrementBindReference(bindId);

        if (disposed) {
          disposedBinds.add(bindId);
          // Só fazer dispose quando não há mais referências
          final isForAppModule = _isBindForAppModule(bindId);

          if (!isForAppModule) {
            Bind.disposeByType(bindId.type);
            // Limpar estado de busca para prevenir loops infinitos quando módulo é re-registrado
            Bind.cleanSearchAttemptsForType(bindId.type);
          }
        }
      } catch (_) {}
    }

    if (debugLog) {
      log('🗑️ DISPOSED 🧩 MODULE: ${module.runtimeType} \nBINDS: { \n${disposedBinds.isEmpty ? '😴 EMPTY' : ''}${disposedBinds.map((e) => '💥 ${e.toString()}').toList().join('\n')} \n}', name: "GO_ROUTER_MODULAR");
    }

    // Remover o código problemático que sempre fazia dispose
    // bindsToDispose.map((type) {
    //   if (_isBindForAppModule(type)) {
    //     return;
    //   }
    //   Bind.disposeByType(type);
    // }).toList();
    bindsToDispose.clear();
  }

  void _incrementBindReference(BindIdentifier bindId) {
    if (_bindReferences.containsKey(bindId)) {
      _bindReferences[bindId] = (_bindReferences[bindId] ?? 0) + 1;
    } else {
      _bindReferences[bindId] = 1;
    }
  }

  bool _decrementBindReference(BindIdentifier bindId) {
    if (_bindReferences.containsKey(bindId)) {
      _bindReferences[bindId] = (_bindReferences[bindId] ?? 1) - 1;

      if (_bindReferences[bindId] == 0) {
        _bindReferences.remove(bindId);
        return true;
      }
    }
    return false;
  }

  Future<void> unregisterModule(Module module) async {
    if (module.runtimeType == _appModule?.runtimeType) return;
    return _enqueueOperation(() => _unregisterModuleInternal(module));
  }

  Future<void> _unregisterModuleInternal(Module module) async {
    module.dispose();
    unregisterBinds(module);
    _moduleBindTypes.remove(module);

    // Executar todas as validações pendentes se houver dispose
    if (_bindsToValidate.isNotEmpty) {
      if (debugLog) {
        iLog('🔍 Dispose detectado - executando ${_bindsToValidate.length} validações pendentes', name: "BIND_VALIDATION");
      }

      // Executar todas as validações
      final validationsToRun = List<Function>.from(_bindsToValidate);
      for (var validation in validationsToRun) {
        try {
          validation();
        } catch (e) {
          // Se for GoRouterModularException, propaga para o usuário
          if (e is GoRouterModularException) {
            rethrow;
          }
        }
      }

      // Limpar fila após execução
      _bindsToValidate.clear();

      if (debugLog) {
        iLog('🧹 Fila de validações limpa', name: "BIND_VALIDATION");
      }
    } else {
      if (debugLog) {
        iLog('⏭️ Nenhuma validação pendente', name: "BIND_VALIDATION");
      }
    }
  }
}
