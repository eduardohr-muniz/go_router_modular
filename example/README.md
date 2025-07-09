# 🧪 Exemplo do Sistema Modular

Este exemplo demonstra o funcionamento completo do sistema `go_router_modular` com ciclo de vida de módulos.

## 🚀 Como Executar

1. **Execute o app:**
   ```bash
   cd example
   flutter run
   ```

2. **Siga o fluxo de teste:**
   - O app abrirá com um guia passo a passo
   - Cada passo testa uma funcionalidade específica
   - Observe os logs no console para acompanhar o processo

## 📋 O que o Exemplo Demonstra

### ✅ Funcionalidades Testadas

1. **Inicialização de Módulos**
   - `initState()` é chamado automaticamente
   - Binds são injetados corretamente
   - Logs mostram o processo

2. **Injeção de Dependências**
   - Serviços são injetados automaticamente
   - Dependências entre módulos funcionam
   - Tratamento de erros de injeção

3. **Disposição de Módulos**
   - `dispose()` é chamado automaticamente
   - Recursos são limpos corretamente
   - Logs mostram o processo de limpeza

4. **Reutilização de Módulos**
   - Módulos são reutilizados quando necessário
   - Não são reinicializados desnecessariamente
   - Performance otimizada

5. **Tratamento de Erros**
   - Binds inexistentes
   - Rotas inexistentes
   - Parâmetros ausentes

## 🏗️ Estrutura do Exemplo

```
example/lib/src/
├── app_module.dart          # Módulo principal
├── modules/
│   ├── auth/               # Módulo de autenticação
│   │   ├── auth_module.dart
│   │   ├── auth_store.dart
│   │   └── pages/
│   │       ├── login_page.dart
│   │       └── splash_page.dart
│   ├── user/               # Módulo de usuário
│   │   ├── user_module.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── user_repository.dart
│   │   └── presenters/
│   │       ├── user_page.dart
│   │       └── user_name_page.dart
│   ├── shared/             # Módulo compartilhado
│   │   └── shared_module.dart
│   └── home/               # Módulo da página inicial
│       ├── home_module.dart
│       └── pages/
│           ├── home_page.dart
│           └── demo_page.dart
└── app_widget.dart         # Widget principal
```

## 🔍 Observando os Logs

Os logs importantes aparecem no console com emojis:

- 🚀 **Inicialização**: `initState()` sendo chamado
- 🗑️ **Disposição**: `dispose()` sendo chamado
- 🔄 **Navegação**: Mudanças de rota
- ❌ **Erros**: Tratamento de exceções
- ✅ **Sucesso**: Operações bem-sucedidas

## 🧪 Fluxo de Teste

1. **Introdução**: Explicação do sistema
2. **Inicialização**: Teste de `initState()` e injeção
3. **Disposição**: Teste de `dispose()` ao sair dos módulos
4. **Reutilização**: Teste de reutilização de módulos
5. **Erros**: Teste de tratamento de erros

## 🎯 Pontos de Atenção

- **Console**: Mantenha o console aberto para ver os logs
- **Navegação**: Use os botões da interface para navegar
- **Logs**: Observe os logs em tempo real
- **Reutilização**: Volte e navegue novamente para ver a reutilização

## 🔧 Personalização

Para testar seu próprio código:

1. **Adicione seus módulos** em `modules/`
2. **Crie seus binds** nos módulos
3. **Implemente initState/dispose** conforme necessário
4. **Teste a navegação** entre seus módulos

O sistema modular garante que o ciclo de vida seja gerenciado automaticamente!

## 📊 Módulos do Exemplo

### AppModule
- **Binds globais**: GlobalAppService, AppConfig
- **Imports**: SharedModule
- **Rotas**: HomeModule, AuthModule, UserModule

### SharedModule
- **Binds compartilhados**: SharedService, LoggerService
- **Usado por**: Todos os outros módulos

### AuthModule
- **Binds**: AuthStore, AuthService
- **Imports**: SharedModule
- **Rotas**: SplashPage, LoginPage

### UserModule
- **Binds**: UserRepository, UserService
- **Imports**: SharedModule
- **Rotas**: UserPage, UserNamePage (com parâmetros)

### HomeModule
- **Binds**: Nenhum
- **Imports**: SharedModule
- **Rotas**: HomePage (interface de teste), DemoPage
