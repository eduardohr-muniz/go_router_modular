# 🎭 EventModule: Like a Magical Phone Central! 

Imagine that EventModule is like a **magical phone central** in your city! 📞✨

## 🏠 What is an EventModule?

Think of EventModule as **different houses** in your city. Each house (module) can:
- 👂 **Listen** to special phone calls
- 📢 **Send** messages to other houses
- 🔔 **Receive** important notifications

```dart
class LoginEventModule extends EventModule {
  @override
  void listen() {
    // This house listens when someone logs in! 👋
    on<LoginEvent>((LoginEvent event, BuildContext? context) {
      print('🎉 Welcome, ${event.username}!');
      if (context != null) {
        context.go('/home'); // Goes to home page
      }
    });
  }
}
```

## 📞 How Does the Phone Central Work?

### 1. 📢 Sending Messages (Firing Events)

When something important happens, you "shout" to the whole city:

```dart
// 🗣️ "HEY EVERYONE! John just logged in!"
ModularEvent.fire(LoginEvent(username: 'John'));

// 🗣️ "ATTENTION! A new message arrived!"
ModularEvent.fire(NotificationEvent(message: 'You have a gift!'));

// 🗣️ "CAREFUL! Something went wrong!"
ModularEvent.fire(ErrorEvent(error: 'Slow internet'));
```

### 2. 👂 Listening to Messages (Listening Events)

Each house can choose which types of "shouts" it wants to listen to:

```dart
class NotificationModule extends EventModule {
  @override
  void listen() {
    // Listen to login events
    on<LoginEvent>((LoginEvent event, BuildContext? context) {
      print('📱 User ${event.username} is online!');
      _showWelcomeNotification(event.username);
    });

    // Listen to error events
    on<ErrorEvent>((ErrorEvent event, BuildContext? context) {
      print('❌ Error: ${event.error}');
      _showErrorDialog(event.error);
    });
  }

  void _showWelcomeNotification(String username) {
    // Show welcome notification
  }

  void _showErrorDialog(String error) {
    // Show error dialog
  }
}
```

## 🎪 Real World Examples

### 🎮 Video Game Example

Imagine you're creating a video game with the EventModule:

```dart
// 🏆 Events in your game
class PlayerLevelUpEvent {
  final String playerName;
  final int newLevel;
  final int experience;
  
  PlayerLevelUpEvent({
    required this.playerName,
    required this.newLevel,
    required this.experience,
  });
}

class EnemyDefeatedEvent {
  final String enemyType;
  final int points;
  
  EnemyDefeatedEvent({
    required this.enemyType,
    required this.points,
  });
}

// 🏠 Game modules listening to events
class ScoreModule extends EventModule {
  @override
  void listen() {
    on<PlayerLevelUpEvent>((PlayerLevelUpEvent event, BuildContext? context) {
      print('🎉 ${event.playerName} reached level ${event.newLevel}!');
      _updateScore(event.experience);
    });

    on<EnemyDefeatedEvent>((EnemyDefeatedEvent event, BuildContext? context) {
      print('💀 Defeated ${event.enemyType} for ${event.points} points!');
      _addPoints(event.points);
    });
  }
}

class SoundModule extends EventModule {
  @override
  void listen() {
    on<PlayerLevelUpEvent>((PlayerLevelUpEvent event, BuildContext? context) {
      _playLevelUpSound(); // 🔊 "Level up!"
    });

    on<EnemyDefeatedEvent>((EnemyDefeatedEvent event, BuildContext? context) {
      _playDefeatSound(); // 🔊 "Enemy defeated!"
    });
  }
}
```

### 🛍️ Shopping App Example

```dart
// 🛒 Shopping events
class AddToCartEvent {
  final String productName;
  final double price;
  final int quantity;
  
  AddToCartEvent({
    required this.productName,
    required this.price,
    required this.quantity,
  });
}

class PurchaseCompletedEvent {
  final String orderId;
  final List<String> items;
  final double total;
  
  PurchaseCompletedEvent({
    required this.orderId,
    required this.items,
    required this.total,
  });
}

// 🏠 Shopping modules
class CartModule extends EventModule {
  @override
  void listen() {
    on<AddToCartEvent>((AddToCartEvent event, BuildContext? context) {
      print('🛒 Added ${event.productName} to cart!');
      _updateCartCounter();
    });
  }
}

class EmailModule extends EventModule {
  @override
  void listen() {
    on<PurchaseCompletedEvent>((PurchaseCompletedEvent event, BuildContext? context) {
      print('📧 Sending purchase confirmation email...');
      _sendConfirmationEmail(event.orderId);
    });
  }
}

// 🔥 When user adds something to cart
ModularEvent.fire(AddToCartEvent(
  productName: 'Cool Sneakers',
  price: 99.99,
  quantity: 1,
));
```

## 🎪 The Magic of Events

### 🎯 Events are like Magic Spells

Each event is like a **magic spell** that you can cast:

```dart
// ✨ Cast the "User Login" spell
ModularEvent.fire(LoginEvent(username: 'Alice'));

// ✨ Cast the "Message Received" spell  
ModularEvent.fire(MessageEvent(from: 'Bob', text: 'Hello!'));

// ✨ Cast the "Achievement Unlocked" spell
ModularEvent.fire(AchievementEvent(name: 'First Victory'));
```

### 🏠 Houses React to Magic

Each house (module) can choose which spells to react to:

```dart
class MagicHouse extends EventModule {
  @override
  void listen() {
    // React to login spell
    on<LoginEvent>((LoginEvent event, BuildContext? context) {
      print('🪄 The magic house glows when ${event.username} enters!');
    });

    // React to achievement spell
    on<AchievementEvent>((AchievementEvent event, BuildContext? context) {
      print('🏆 Fireworks appear for achievement: ${event.name}!');
    });
  }
}
```

## 🎭 Special Powers of EventModule

### 1. 🔐 Exclusive Power (exclusive: true)

Sometimes you want only ONE house to hear your message:

```dart
class SpecialModule extends EventModule {
  @override
  void listen() {
    // Only THIS house will hear secret messages
    on<SecretEvent>((SecretEvent event, BuildContext? context) {
      print('🤫 I heard the secret: ${event.secret}');
    }, exclusive: true);
  }
}
```

### 2. 🔄 Auto-Cleanup Power (autoDispose: true)

The magic house can clean itself automatically:

```dart
class SelfCleaningModule extends EventModule {
  @override
  void listen() {
    // This listener cleans itself when the house is destroyed
    on<MessageEvent>((MessageEvent event, BuildContext? context) {
      print('📧 Message: ${event.text}');
    }, autoDispose: true);
  }
}
```

### 3. 🎯 Different Phone Lines (Custom EventBus)

You can have different phone lines for different types of calls:

```dart
class PrivateModule extends EventModule {
  final EventBus _privatePhone = EventBus();

  @override
  EventBus get eventBus => _privatePhone; // Use private phone

  @override
  void listen() {
    on<PrivateMessageEvent>((PrivateMessageEvent event, BuildContext? context) {
      print('📞 Private message: ${event.message}');
    });
  }
}
```

## 🎪 Building Your Event City

### 🏗️ Step 1: Create Your Houses (Modules)

```dart
// 🏠 House for handling user actions
class UserHouse extends EventModule {
  @override
  void listen() {
    on<UserJoinedEvent>((UserJoinedEvent event, BuildContext? context) {
      print('👋 ${event.name} joined the party!');
    });
  }
}

// 🏠 House for handling game actions
class GameHouse extends EventModule {
  @override
  void listen() {
    on<GameStartedEvent>((GameStartedEvent event, BuildContext? context) {
      print('🎮 Game ${event.gameName} started!');
    });
  }
}

// 🏠 House for handling notifications
class NotificationHouse extends EventModule {
  @override
  void listen() {
    on<UserJoinedEvent>((UserJoinedEvent event, BuildContext? context) {
      _showNotification('${event.name} is now online!');
    });

    on<GameStartedEvent>((GameStartedEvent event, BuildContext? context) {
      _showNotification('Game ${event.gameName} is starting!');
    });
  }
}
```

### 🏗️ Step 2: Connect Your Houses to the City

```dart
// 🏛️ Your main city (App Module)
class MyCityModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, state) => HomePage()),
  ];

  @override
  List<Module> get imports => [
    UserHouse(),           // Import user house
    GameHouse(),           // Import game house  
    NotificationHouse(),   // Import notification house
  ];
}
```

### 🏗️ Step 3: Make Events Happen!

```dart
// 🎉 Someone joins the party
ModularEvent.fire(UserJoinedEvent(name: 'Alice'));

// 🎮 A game starts
ModularEvent.fire(GameStartedEvent(gameName: 'Super Adventure'));
```

### 🎯 What Happens?

1. **UserHouse** hears "Alice joined" → prints welcome message
2. **NotificationHouse** hears "Alice joined" → shows notification
3. **GameHouse** hears "Super Adventure started" → prints game message  
4. **NotificationHouse** hears "Super Adventure started" → shows game notification

**It's like magic! ✨ All houses automatically do their jobs!**

## 🎪 Fun EventModule Games

### 🎮 Game 1: The Echo House

```dart
class EchoHouse extends EventModule {
  @override
  void listen() {
    on<SayHelloEvent>((SayHelloEvent event, BuildContext? context) {
      print('Echo: ${event.message}');
      // Echo back after 1 second
      Future.delayed(Duration(seconds: 1), () {
        ModularEvent.fire(EchoBackEvent(message: 'Echo: ${event.message}'));
      });
    });
  }
}
```

### 🎮 Game 2: The Counting House

```dart
class CountingHouse extends EventModule {
  int _count = 0;

  @override
  void listen() {
    on<CountEvent>((CountEvent event, BuildContext? context) {
      _count++;
      print('🔢 Count is now: $_count');
      
      if (_count >= 10) {
        ModularEvent.fire(CountReachedTenEvent());
      }
    });
  }
}
```

### 🎮 Game 3: The Color House

```dart
class ColorHouse extends EventModule {
  @override
  void listen() {
    on<ChangeColorEvent>((ChangeColorEvent event, BuildContext? context) {
      print('🎨 Changing color to ${event.color}');
      _changeBackgroundColor(event.color);
    });
  }
}

// Fire color events
ModularEvent.fire(ChangeColorEvent(color: 'red'));
ModularEvent.fire(ChangeColorEvent(color: 'blue'));
ModularEvent.fire(ChangeColorEvent(color: 'green'));
```

## 🎊 Why EventModule is Awesome

### 🌟 It's Like Having Super Powers!

- 🎯 **One message, many listeners** - Shout once, everyone who cares will hear
- 🏠 **Independent houses** - Each module does its own thing
- 🔧 **Easy to add new features** - Just add a new house that listens
- 🎪 **Fun to use** - Makes coding feel like playing with magic!

### 🎮 Real Benefits for Your App

- 📱 **Better organization** - Everything has its place
- 🚀 **Faster development** - Add features without breaking existing code
- 🐛 **Fewer bugs** - Houses don't know about each other directly
- 🎨 **More fun** - Coding becomes like building a magical city!

## 🎯 Your EventModule Adventure Starts Now!

1. 🏗️ **Build your first house** (EventModule)
2. 👂 **Make it listen** to events you care about
3. 📢 **Fire some events** and watch the magic happen
4. 🎪 **Add more houses** for more features
5. 🌟 **Enjoy your magical event city!**

---

**Remember: EventModule is like having a magical phone system where houses in your city can talk to each other without knowing each other's addresses! 🎭✨**

*Now go build your own magical event city!* 🏙️🎪