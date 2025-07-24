# GoRouter Modular - Exemplo de Uso

Este exemplo demonstra como usar o GoRouter Modular com os novos métodos `initState` e `dispose` para controle do ciclo de vida dos módulos.

## 📁 Estrutura do Projeto

```
example/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── app_module.dart
│       ├── app_widget.dart
│       └── modules/
│           ├── auth/
│           │   ├── auth_module.dart
│           │   ├── auth_store.dart
│           │   └── pages/
│           │       ├── login_page.dart
│           │       └── splash_page.dart
│           ├── home/
│           │   ├── home_module.dart
│           │   └── pages/
│           │       ├── home_page.dart
│           │       └── demo_page.dart
│           ├── user/
│           │   ├── user_module.dart
│           │   ├── domain/
│           │   │   └── repositories/
│           │   │       └── user_repository.dart
│           │   └── presenters/
│           │       ├── user_page.dart
│           │       └── user_name_page.dart
│           └── shared/
│               ├── shared_module.dart
│               └── shared_service.dart
```

## 🔄 Ciclo de Vida dos Módulos

### initState(Injector i)

O método `initState` é chamado automaticamente quando os bindings do módulo são injetados pela primeira vez.

**Exemplo de uso:**

```dart
class AuthModule extends Module {
  bool _isInitialized = false;

  @override
  void initState(Injector i) {
    if (_isInitialized) return;

    try {
      // Obtém dependências injetadas
      final authStore = i.get<AuthStore>();
      
      // Configura listeners
      _setupAuthListeners();
      
      // Carrega configurações
      _loadAuthConfig();
      
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }
}
```

### dispose()

O método `dispose` é chamado automaticamente quando o módulo é disposado.

**Exemplo de uso:**

```dart
class AuthModule extends Module {
  Timer? _authTimer;
  StreamSubscription? _authSubscription;

  @override
  void dispose() {
    if (!_isInitialized) return;

    try {
      // Cancela timers
      _authTimer?.cancel();
      
      // Cancela subscriptions
      _authSubscription?.cancel();
      
      // Limpa dados
      _clearTempAuthData();
      
      // Fecha conexões
      _closeAuthConnections();
    } catch (e) {
      rethrow;
    }
  }
}
```

## 🚀 Como Executar

1. **Configure o projeto:**
   ```bash
   cd example
   flutter pub get
   ```

2. **Execute o app:**
   ```bash
   flutter run
   ```

3. **Navegue entre as rotas para ver os logs:**
   - `/` - Home Module
   - `/auth` - Auth Module  
   - `/user` - User Module

## 📊 Logs de Exemplo

Quando você navega entre as rotas, verá logs como:

```
🚀 [AUTH_MODULE] initState chamado
🔐 [AUTH_MODULE] AuthStore obtido: AuthStore
🔧 [AUTH_MODULE] Configurando listeners de autenticação
⚙️ [AUTH_MODULE] Carregando configurações de autenticação
🔍 [AUTH_MODULE] Verificando token salvo
✅ [AUTH_MODULE] AuthModule inicializado com sucesso

// ... navegação para outra rota ...

🗑️ [AUTH_MODULE] dispose chamado
⏰ [AUTH_MODULE] Timer de autenticação cancelado
📡 [AUTH_MODULE] Subscription de autenticação cancelado
🧹 [AUTH_MODULE] Limpando dados temporários de autenticação
🔌 [AUTH_MODULE] Fechando conexões de autenticação
✅ [AUTH_MODULE] AuthModule disposto com sucesso
```

## 🎯 Casos de Uso

### 1. **Módulo de Autenticação**
- Configura listeners de autenticação
- Carrega configurações de segurança
- Verifica tokens salvos
- Limpa dados sensíveis na disposição

### 2. **Módulo Home**
- Carrega dados iniciais
- Configura analytics
- Gerencia timers de atualização
- Limpa cache de dados

### 3. **Módulo User**
- Configura permissões de usuário
- Carrega dados de perfil
- Gerencia listeners de mudanças
- Limpa dados pessoais

### 4. **Módulo Shared**
- Configura serviços globais
- Carrega configurações compartilhadas
- Gerencia recursos compartilhados
- Limpa recursos globais

## ⚠️ Boas Práticas

1. **Controle de Estado:** Use uma flag `_isInitialized` para evitar inicializações múltiplas
2. **Tratamento de Erros:** Sempre use try-catch nos métodos `initState` e `dispose`
3. **Limpeza de Recursos:** Sempre cancele timers, subscriptions e feche conexões no `dispose`
4. **Acesso a Dependências:** Use o `Injector` passado no `initState` para acessar dependências injetadas
5. **Logs Informativos:** Use logs para debug e monitoramento do ciclo de vida

## 🔧 Configuração

O exemplo está configurado no `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
  );

  runApp(AppWidget());
}
```

Isso garante que o sistema de módulos seja inicializado corretamente e que os métodos `initState` e `dispose` sejam chamados nos momentos apropriados.
