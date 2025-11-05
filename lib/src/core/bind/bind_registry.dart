import 'package:go_router_modular/src/core/bind/bind.dart';
import 'package:go_router_modular/src/core/bind/bind_storage.dart';
import 'package:go_router_modular/src/di/clean_bind.dart';
import 'package:go_router_modular/src/di/injector.dart';

/// Responsável APENAS por registrar binds
/// Responsabilidade única: Lógica de registro de binds
class BindRegistry {
  final BindStorage _storage = BindStorage.instance;

  /// Registra um bind preservando seu tipo genérico original
  /// Este método descobre o tipo através da análise da função factory ou tentativa de criação
  void register(dynamic bind) {
    if (bind is! Bind) {
      throw ArgumentError('Bind.register espera um Bind, mas recebeu ${bind.runtimeType}');
    }

    Type registrationType = Object;

    // Primeiro, tenta descobrir o tipo através da análise da função factory
    // Analisa a string da função para encontrar o tipo de retorno
    final factoryString = bind.factoryFunction.toString();

    // Tenta extrair tipo de retorno da factory function
    // Padrões: => TypeName( ou => new TypeName(
    final returnTypePatterns = [
      RegExp(r'=>\s*(\w+)\s*\('),
      RegExp(r'=>\s*new\s+(\w+)\s*\('),
      RegExp(r'=>\s*(\w+)\s*\.'),
    ];

    String? potentialTypeName;
    for (final pattern in returnTypePatterns) {
      final match = pattern.firstMatch(factoryString);
      if (match != null && match.groupCount > 0) {
        potentialTypeName = match.group(1);
        // Verifica se não é uma palavra reservada
        const excludedWords = {'i', 'Injector', 'null', 'return', 'get', 'set', 'if', 'else'};
        if (potentialTypeName != null && !excludedWords.contains(potentialTypeName) && potentialTypeName[0].toUpperCase() == potentialTypeName[0]) {
          break;
        }
        potentialTypeName = null;
      }
    }

    // Se encontrou um tipo potencial, tenta criar instância para confirmar
    // Se não encontrou ou falhou, tenta criar instância diretamente
    try {
      final instance = bind.factoryFunction(Injector());
      registrationType = instance.runtimeType;
      
      // Se for singleton, armazena a instância criada no cache
      // para evitar instâncias órfãs
      if (bind.isSingleton && bind.cachedInstance == null) {
        bind.cachedInstance = instance;
      }
      
      // Para factory, dispõe a instância temporária criada
      if (!bind.isSingleton) {
        try {
          CleanBind.fromInstance(instance);
        } catch (_) {
          // Ignora erros ao dispor instância temporária
        }
      }
    } catch (e) {
      // Se falhar ao criar instância, registra como Object temporariamente
      // Mas adiciona à lista de pending para descoberta posterior
      registrationType = Object;
      _storage.pendingObjectBinds.add(bind);
    }

    if (bind.isSingleton) {
      final singleton = _storage.bindsMap[registrationType];
      if (singleton != null && singleton.key == bind.key) {
        return;
      }
    }

    // Verifica se já existe um bind deste tipo antes de substituir
    final existingBind = _storage.bindsMap[registrationType];
    if (existingBind != null) {
      // REGRA: Bind com key só pode ser chamado com key
      // Bind sem key só pode ser chamado sem key
      // Se o bind existente tem key diferente do novo, não substitui
      // Se ambos têm key ou ambos não têm key, substitui
      if (existingBind.key != bind.key) {
        // Se um tem key e outro não, não substitui - mantém ambos
        // O bind com key fica apenas no _bindsMapByKey
        // O bind sem key fica no _bindsMap
        if (bind.key != null) {
          // Novo bind tem key, existente não tem - mantém existente no _bindsMap
          _storage.bindsMapByKey[bind.key!] = bind;
          return;
        }
        
        // Novo bind não tem key, existente tem - REMOVE o existente do _bindsMap e coloca o sem key
        // Remove o bind com key do _bindsMap (mas mantém no _bindsMapByKey)
        _storage.bindsMap.remove(registrationType);
        // Registra o bind sem key no _bindsMap
        _storage.bindsMap[registrationType] = bind;
        return;
      }

      // Se chegar aqui, ambos têm a mesma key (ou ambos não têm key)
      // Limpa o cache do bind antigo antes de substituir
      existingBind.clearCache();
    }

    // Só registra no _bindsMap se não tem key
    // Se tem key, será registrado apenas no _bindsMapByKey
    if (bind.key != null) {
      // Bind com key: só registra no _bindsMapByKey, NÃO no _bindsMap
      // Isso garante que get<T>() sem key não pegue binds com key
      _storage.bindsMapByKey[bind.key!] = bind;
      return;
    }
    
    _storage.bindsMap[registrationType] = bind;
  }

  /// Versão genérica para compatibilidade (usa o tipo genérico se fornecido)
  void registerTyped<T>(Bind<T> bind) {
    // Se T é Object, usa o método não genérico
    if (T == Object) {
      register(bind);
      return;
    }
    
    // Se T não é Object, usa T diretamente
    if (bind.isSingleton) {
      final singleton = _storage.bindsMap[T];
      if (singleton != null && singleton.key == bind.key) {
        return;
      }
    }

    // Verifica se já existe um bind deste tipo
    final existingBind = _storage.bindsMap[T];
    if (existingBind != null) {
      // REGRA: Bind com key só pode ser chamado com key
      // Bind sem key só pode ser chamado sem key
      if (existingBind.key != bind.key) {
        if (bind.key != null) {
          // Novo bind tem key, existente não tem - mantém existente no _bindsMap
          _storage.bindsMapByKey[bind.key!] = bind;
          return;
        }
        
        // Novo bind não tem key, existente tem - REMOVE o existente do _bindsMap
        _storage.bindsMap.remove(T);
        _storage.bindsMap[T] = bind;
        return;
      }
    }

    // Só registra no _bindsMap se não tem key
    if (bind.key != null) {
      // Bind com key: só registra no _bindsMapByKey, NÃO no _bindsMap
      _storage.bindsMapByKey[bind.key!] = bind;
      return;
    }
    
    _storage.bindsMap[T] = bind;
  }
}

