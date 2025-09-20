# Sistema de Keys

O sistema de injeção de dependência do go_router_modular agora suporta keys para permitir múltiplas instâncias do mesmo tipo.

## Visão Geral

O sistema de keys permite:
- Registrar múltiplas instâncias do mesmo tipo com identificadores únicos
- Buscar instâncias específicas por key
- Manter compatibilidade com o sistema existente (binds sem keys)

## Registrando Binds com Keys

### Singleton com Key

```dart
Bind.singleton<UserService>((i) => UserService(), key: 'user_service')
Bind.singleton<UserService>((i) => AdminUserService(), key: 'admin_user_service')
```

### Factory com Key

```dart
Bind.factory<ApiService>((i) => ApiService(), key: 'api_service')
Bind.factory<ApiService>((i) => MockApiService(), key: 'mock_api_service')
```

## Buscando por Key Específica

```dart
final injector = Injector();

// Busca por key específica
final userService = injector.get<UserService>(key: 'user_service');
final adminService = injector.get<UserService>(key: 'admin_user_service');
```



## Casos de Uso Comuns

### 1. Múltiplas Implementações do Mesmo Tipo

```dart
// Registrando diferentes implementações
Bind.singleton<DatabaseService>((i) => PostgreSQLService(), key: 'postgres_db');
Bind.singleton<DatabaseService>((i) => MySQLService(), key: 'mysql_db');
Bind.singleton<DatabaseService>((i) => SQLiteService(), key: 'sqlite_db');

// Usando em diferentes contextos
final postgresDb = injector.get<DatabaseService>(key: 'postgres_db');
final mysqlDb = injector.get<DatabaseService>(key: 'mysql_db');
```

### 2. Serviços por Ambiente

```dart
// Produção
Bind.singleton<ApiService>((i) => ProductionApiService(), key: 'prod_api');

// Desenvolvimento
Bind.singleton<ApiService>((i) => DevelopmentApiService(), key: 'dev_api');

// Teste
Bind.singleton<ApiService>((i) => MockApiService(), key: 'test_api');
```



## Compatibilidade

O sistema mantém total compatibilidade com o código existente:

```dart
// Código antigo continua funcionando
Bind.singleton<LoggerService>((i) => LoggerService());
final logger = injector.get<LoggerService>(); // Sem key

// Novo código com keys
Bind.singleton<LoggerService>((i) => FileLoggerService(), key: 'file_logger');
final fileLogger = injector.get<LoggerService>(key: 'file_logger');
```

## Logs de Debug

O sistema fornece logs detalhados para debug:

```
🔍 Procurando bind para tipo: UserService com key: user_service
📊 Binds disponíveis no mapa: [UserService, ApiService, ...]
🔑 Binds disponíveis por key: [user_service, admin_user_service, ...]
✅ Bind encontrado por key: user_service
🎯 Retornando instância: UserService para UserService
```

## Considerações de Performance

- Busca por key é mais rápida que busca por padrão
- Binds sem keys são mais eficientes que binds com keys
- Use keys apenas quando necessário (múltiplas instâncias do mesmo tipo)
- O sistema mantém caches internos para otimizar buscas repetidas

## Boas Práticas

1. **Use keys descritivas**: `user_service`, `admin_user_service` em vez de `service1`, `service2`
2. **Padronize nomenclatura**: Use prefixos ou sufixos consistentes
3. **Documente keys importantes**: Mantenha documentação das keys principais
4. **Use keys apenas quando necessário**: Para múltiplas instâncias do mesmo tipo
5. **Teste buscas por key**: Valide que as keys retornam os binds esperados 