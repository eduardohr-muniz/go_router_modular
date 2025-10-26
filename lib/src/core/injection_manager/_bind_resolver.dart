import 'package:auto_injector/auto_injector.dart';
import 'package:go_router_modular/src/core/injection_manager/_module_registry.dart';
import 'package:go_router_modular/src/core/injection_manager/injection_manager.dart';

/// Resolve binds com isolamento de módulos
/// Cada módulo só pode acessar:
/// 1. Seus próprios binds
/// 2. Binds dos módulos importados (via imports)
/// 3. Binds do AppModule (sempre disponível)
class BindResolver {
  final AutoInjector _autoInjector;
  final ModuleRegistry _registry;

  BindResolver(this._autoInjector, this._registry);

  T resolve<T extends Object>({String? key}) {
    final currentContext = _registry.currentContext;

    // Se não há contexto definido, tentar resolver no AppModule
    if (currentContext == null) {
      try {
        return _autoInjector.get<T>(key: key);
      } catch (e) {
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    // Se o contexto é o AppModule, resolver no injector principal
    if (currentContext == _registry.appModule?.runtimeType) {
      try {
        return _autoInjector.get<T>(key: key);
      } catch (e) {
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    // Buscar o injector do módulo atual
    final moduleInjector = _getModuleInjector(currentContext);

    if (moduleInjector != null) {
      try {
        // Tentar resolver no injector do módulo atual (que inclui seus próprios binds e imports)
        return moduleInjector.get<T>(key: key);
      } catch (e) {
        // Não encontrou no módulo atual ou nos imports
        // TENTAR NO APPMODULE GLOBAL (sempre disponível)
        if (_registry.appModule != null) {
          try {
            return _autoInjector.get<T>(key: key);
          } catch (e2) {
            // Gerar mensagem de erro detalhada
            final errorMessage = _generateDetailedErrorMessage<T>(currentContext, key, e2);
            throw Exception(errorMessage);
          }
        }
        // Gerar mensagem de erro detalhada
        final errorMessage = _generateDetailedErrorMessage<T>(currentContext, key, e);
        throw Exception(errorMessage);
      }
    }

    // Se não conseguiu encontrar o injector do módulo, tentar no injector principal
    // (fallback para casos onde o moduleInjector é null)
    if (_registry.appModule != null) {
      try {
        return _autoInjector.get<T>(key: key);
      } catch (e) {
        throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
      }
    }

    throw Exception('Bind not found for type: ${T.toString()}${key != null ? ' with key: $key' : ''}');
  }

  /// Obtém o injector de um módulo específico
  AutoInjector? _getModuleInjector(Type moduleType) {
    // Buscar o injector do módulo no mapa de injectors
    try {
      final moduleInjectors = InjectionManager.instance.moduleInjectors;
      return moduleInjectors[moduleType];
    } catch (e) {
      return null;
    }
  }

  /// Gera mensagem de erro detalhada com orientações ao usuário
  String _generateDetailedErrorMessage<T extends Object>(Type? moduleContext, String? key, [dynamic originalError]) {
    final typeName = T.toString();

    final sb = StringBuffer();

    // Título
    sb.writeln('Dependency Injection Error');
    sb.writeln('Bind not found for type: `$typeName` | Module: `${moduleContext?.toString() ?? "Global"}`');

    // Descrição
    sb.writeln('The dependency `$typeName` is not registered in the DI container.');

    // Incluir trace do auto_injector se disponível
    String? chain;
    if (originalError != null) {
      final errorStr = originalError.toString();
      final traceMatch = RegExp(r'Trace: (.*)', multiLine: true).firstMatch(errorStr);
      if (traceMatch != null) {
        chain = traceMatch.group(1);
        if (chain != null) {
          sb.writeln('$chain');
        }
      }
    }

    // Tentar extrair arquivo .dart mais provável do stack trace
    String? mostLikelyFile;
    if (originalError != null) {
      final errorStr = originalError.toString();
      // Procurar por padrão: package:package_name/path/file.dart
      final fileMatch = RegExp(r'(package:[^\s]+\.dart)').firstMatch(errorStr);
      if (fileMatch != null) {
        mostLikelyFile = fileMatch.group(1);
      }
    }

    // Recomendação de fix
    sb.writeln('');
    sb.writeln('RECOMMENDED FIX:');
    sb.writeln('Ensure all required dependencies are registered before usage:');

    // Gerar exemplos de registros baseados na cadeia de dependências
    if (chain != null) {
      final types = chain.split('->');
      for (var i = 0; i < types.length; i++) {
        final type = types[i].trim();
        sb.writeln('  i.add<$type>(() => YourImplementation());');
      }
    } else {
      sb.writeln('  i.add<$typeName>(() => YourImplementation());');
    }

    // Adicionar arquivo mais provável se encontrado
    if (mostLikelyFile != null) {
      sb.writeln('');
      sb.writeln('📍 Most likely file: $mostLikelyFile');
    }

    return sb.toString();
  }
}
