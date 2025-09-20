# 🎭 EventModule: Como uma Central Telefônica Mágica! 

Imagine que o EventModule é como uma **central telefônica mágica** da sua cidade! 📞✨

## 🏠 O que é um EventModule?

Pense no EventModule como **casas diferentes** na sua cidade. Cada casa (módulo) pode:
- 👂 **Escutar** ligações telefônicas especiais
- 📢 **Mandar** mensagens para outras casas
- 🔔 **Receber** notificações importantes

```dart
class LoginEventModule extends EventModule {
  @override
  void listen() {
    // Esta casa escuta quando alguém faz login! 👋
    on<LoginEvent>((event, context) {
      print('🎉 Bem-vindo, ${event.username}!');
      if (context != null) {
        context.go('/home'); // Vai para a página inicial
      }
    });
  }
}
```

## 📞 Como Funciona a Central Telefônica?

### 1. 📢 Mandando Mensagens (Firing Events)

Quando algo importante acontece, você "grita" para toda a cidade:

```dart
// 🗣️ "OI PESSOAL! João acabou de fazer login!"
ModularEvent.fire(LoginEvent(username: 'João'));

// 🗣️ "ATENÇÃO! Chegou uma mensagem nova!"
ModularEvent.fire(NotificationEvent(message: 'Você tem um presente!'));

// 🗣️ "CUIDADO! Algo deu errado!"
ModularEvent.fire(ErrorEvent(error: 'Internet lenta'));
```

### 2. 👂 Escutando Mensagens (Listening Events)

Cada casa pode escolher quais tipos de "gritos" ela quer escutar:

```dart
class NotificationModule extends EventModule {
  @override
  void listen() {
    // 🔔 Esta casa escuta notificações
    on<NotificationEvent>((event, context) {
      showDialog(
        context: context!,
        builder: (context) => AlertDialog(
          title: Text('📬 Nova Mensagem!'),
          content: Text(event.message),
        ),
      );
    });

    // ❌ Esta casa também escuta erros
    on<ErrorEvent>((event, context) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('💥 Ops! ${event.error}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
```

## 🎵 O Sistema Exclusive: Como um Rádio Especial

Imagine que você tem um **rádio muito especial** que só pode tocar uma música por vez! 🎵

### 📻 Modo Normal (Non-Exclusive)
```dart
// 🎶 TODAS as casas escutam a mesma música ao mesmo tempo
on<MusicEvent>((event, context) {
  print('🎵 Tocando: ${event.songName}');
}); // exclusive: false (padrão)
```

**O que acontece:**
- Casa do João: 🎵 "Tocando: Parabéns pra você"
- Casa da Maria: 🎵 "Tocando: Parabéns pra você"  
- Casa do Pedro: 🎵 "Tocando: Parabéns pra você"

### 📻 Modo Exclusive (Fila do Rádio)
```dart
// 🎯 Apenas UMA casa pode ouvir por vez!
on<MusicEvent>((event, context) {
  print('🎵 Só eu escuto: ${event.songName}');
}, exclusive: true);
```

**O que acontece:**
1. 🏠 **Casa do João** entra na fila primeiro → 🎵 Ele escuta a música
2. 🏠 **Casa da Maria** entra na fila → ⏳ Fica esperando
3. 🏠 **Casa do Pedro** entra na fila → ⏳ Fica esperando

```
📋 FILA DO RÁDIO:
┌─────────────────────────┐
│ 🎵 João (tocando agora) │ ← Ativo
│ ⏳ Maria (esperando)    │ ← Próxima
│ ⏳ Pedro (esperando)    │ ← Depois
└─────────────────────────┘
```

### 🏃‍♂️ Quando Alguém Sai da Fila

Se João sair de casa (dispose), o rádio **automaticamente** vai para Maria:

```
📋 APÓS JOÃO SAIR:
┌─────────────────────────┐
│ 🎵 Maria (tocando agora)│ ← Agora é ativa!
│ ⏳ Pedro (esperando)    │ ← Próximo
└─────────────────────────┘
```

## 🎪 Exemplos do Mundo Real

### 🔐 Sistema de Login
```dart
class LoginModule extends EventModule {
  @override
  void listen() {
    // Quando alguém faz login
    on<LoginEvent>((event, context) {
      print('👋 Olá, ${event.username}!');
      // Ir para a tela principal
      context?.go('/dashboard');
    });

    // Quando alguém faz logout  
    on<LogoutEvent>((event, context) {
      print('👋 Tchau, ${event.username}!');
      // Voltar para tela de login
      context?.go('/login');
    });
  }
}

// Como usar:
ModularEvent.fire(LoginEvent(username: 'Ana'));
ModularEvent.fire(LogoutEvent(username: 'Ana'));
```

### 🛒 Carrinho de Compras
```dart
class ShoppingModule extends EventModule {
  @override
  void listen() {
    // Quando adiciona produto
    on<AddToCartEvent>((event, context) {
      print('🛒 Adicionado: ${event.productName}');
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(content: Text('✅ ${event.productName} no carrinho!'))
      );
    });

    // Quando finaliza compra
    on<PurchaseEvent>((event, context) {
      print('💳 Compra de R\$ ${event.total} finalizada!');
      context?.go('/success');
    });
  }
}

// Como usar:
ModularEvent.fire(AddToCartEvent(productName: 'Bicicleta', price: 500.0));
ModularEvent.fire(PurchaseEvent(total: 500.0));
```

### 🎮 Sistema de Jogo
```dart
class GameModule extends EventModule {
  @override
  void listen() {
    // Sistema de pontuação (exclusive - só um contador)
    on<ScoreEvent>((event, context) {
      print('🏆 Nova pontuação: ${event.points}');
      updateScoreboard(event.points);
    }, exclusive: true);

    // Efeitos sonoros (normal - todos escutam)
    on<SoundEvent>((event, context) {
      print('🔊 Som: ${event.soundName}');
      playSound(event.soundName);
    });
  }
}

// Como usar:
ModularEvent.fire(ScoreEvent(points: 1000));
ModularEvent.fire(SoundEvent(soundName: 'coin.wav'));
```

## 🎯 Regras Importantes

### 1. 🏠 Limpeza Automática
Quando uma casa é demolida (`dispose()`), ela **automaticamente**:
- 🧹 Para de escutar todos os eventos
- 🗑️ Limpa toda a memória
- 📻 Se estava no rádio exclusive, passa para o próximo

### 2. 🌐 Context Mágico
O `context` é como um **GPS mágico** que te mostra onde você está:
```dart
on<NavigationEvent>((event, context) {
  if (context != null) {
    // 🗺️ Você sabe onde está! Pode navegar
    context.go('/new-page');
  } else {
    // 🤷‍♂️ Você não sabe onde está... 
    print('Ops! Não sei onde estou');
  }
});
```

### 3. 🔄 AutoDispose
```dart
// 🔒 Esta escuta vai embora quando a casa for demolida
on<MyEvent>((event, context) {
  // fazer algo...
}, autoDispose: true); // padrão

// 🔓 Esta escuta fica para sempre (cuidado!)
on<MyEvent>((event, context) {
  // fazer algo...
}, autoDispose: false); // perigoso!
```

## 🎨 Criando Seus Próprios Eventos

```dart
// 🎂 Evento de aniversário
class BirthdayEvent {
  final String personName;
  final int age;
  
  BirthdayEvent({required this.personName, required this.age});
}

// 🌟 Módulo que escuta aniversários
class BirthdayModule extends EventModule {
  @override
  void listen() {
    on<BirthdayEvent>((event, context) {
      print('🎉 Parabéns ${event.personName}! ${event.age} anos!');
      
      if (context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🎂 Aniversário!'),
            content: Text('${event.personName} fez ${event.age} anos!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('🎁 Legal!'),
              ),
            ],
          ),
        );
      }
    });
  }
}

// Como usar:
ModularEvent.fire(BirthdayEvent(personName: 'Maria', age: 10));
```

## 🚀 Dicas de Ouro

### ✨ Boas Práticas
```dart
// ✅ BOM: Sempre verificar context
on<NavigationEvent>((event, context) {
  if (context != null) {
    context.go(event.route);
  }
});

// ✅ BOM: Nomes claros para eventos
class UserLoginSuccessEvent { ... }
class ShoppingCartUpdatedEvent { ... }
class GameOverEvent { ... }

// ❌ RUIM: Não verificar context
on<NavigationEvent>((event, context) {
  context!.go(event.route); // Pode dar erro!
});
```

### 🎪 Exemplo Completo: App de Loja
```dart
// 📱 App completo com eventos
class ShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoRouterModularApp(
      title: '🛍️ Minha Loja',
      modules: [
        LoginModule(),      // Cuida do login
        ShoppingModule(),   // Cuida das compras  
        NotificationModule(), // Cuida das notificações
      ],
    );
  }
}

// 🏪 Módulo da loja
class ShoppingModule extends EventModule {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/shop', child: (context, state) => ShopPage()),
    ChildRoute('/cart', child: (context, state) => CartPage()),
  ];

  @override
  void listen() {
    // Quando adiciona ao carrinho
    on<AddToCartEvent>((event, context) {
      print('🛒 ${event.productName} adicionado!');
      
      // Mostrar notificação
      ModularEvent.fire(NotificationEvent(
        message: '${event.productName} no seu carrinho!'
      ));
    });

    // Quando remove do carrinho
    on<RemoveFromCartEvent>((event, context) {
      print('🗑️ ${event.productName} removido!');
    });

    // Quando finaliza compra (exclusive - só um por vez)
    on<CheckoutEvent>((event, context) {
      print('💳 Processando compra...');
      // Ir para página de sucesso
      context?.go('/success');
    }, exclusive: true);
  }
}
```

## 🎊 Conclusão

O EventModule é como uma **cidade mágica** onde:
- 🏠 **Casas** (módulos) podem escutar eventos
- 📢 **Gritos** (events) espalham informações
- 📞 **Central telefônica** (EventBus) conecta tudo
- 📻 **Rádio exclusive** garante ordem nas filas
- 🧹 **Limpeza automática** evita bagunça

**Agora você pode criar seus próprios eventos e fazer sua app conversar como uma cidade feliz!** 🏙️✨

---

*"Com grandes poderes vêm grandes responsabilidades... sempre faça dispose dos seus módulos!"* 🕷️
