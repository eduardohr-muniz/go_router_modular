# Page Transitions

Beautiful page transitions made simple using the `go_transitions` package. Add smooth animations between pages with just a few lines of code.

## What You Get

- Built-in transitions: fade, slide, scale, rotate, and more
- Smart inheritance: child routes inherit from parent modules
- Easy customization: duration and curves
- Platform defaults: automatic fallbacks
- Powered by `go_transitions` package

## Quick Start

### 1. Default Transition

Set a default transition for your entire app:

```dart
await Modular.configure(
  appModule: AppModule(),
  initialRoute: '/',
  defaultTransition: GoTransitions.fadeUpwards,
);
```

### 2. Child Route Transitions

Override for specific routes:

```dart
// Uses default transition
ChildRoute('/', child: (_, __) => HomePage()),

// Custom transition
ChildRoute('/details', 
  child: (_, __) => DetailsPage(),
  transition: GoTransitions.slide.toRight.withFade,
)
```

## Available Transitions

```dart
// Basic transitions
GoTransitions.fade
GoTransitions.fadeUpwards
GoTransitions.slide.toRight
GoTransitions.scale
GoTransitions.rotate

// Platform styles
GoTransitions.cupertino  // iOS/macOS
GoTransitions.material   // Android

// Combined effects
GoTransitions.slide.toRight.withFade
GoTransitions.scale.withRotation
```

## How Inheritance Works

Child routes automatically use the default transition configured in `Modular.configure()`, but can override it:

```dart
// Configure default
await Modular.configure(
  appModule: AppModule(),
  initialRoute: '/',
  defaultTransition: GoTransitions.fadeUpwards,
);

// Child uses default
ChildRoute('/', child: (_, __) => HomePage())

// Child overrides
ChildRoute('/profile', child: (_, __) => ProfilePage(),
  transition: GoTransitions.slide.toRight)
```

## Global Setup

Set defaults for your entire app using `go_transitions`:

```dart
class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Configure go_transitions defaults
    GoTransition.defaultDuration = Duration(milliseconds: 400);
    GoTransition.defaultCurve = Curves.easeInOut;
    
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: GoTransitions.fadeUpwards,
            TargetPlatform.iOS: GoTransitions.cupertino,
            TargetPlatform.macOS: GoTransitions.cupertino,
          },
        ),
      ),
    );
  }
}
```

## Migration

```dart
// Old way (using PageTransition enum)
ChildRoute('/', child: (_, __) => HomePage(), 
  pageTransition: PageTransition.fade)

// New way (using GoTransitions)
ChildRoute('/', child: (_, __) => HomePage(), 
  transition: GoTransitions.fade)
```

## Transition Examples

### Basic Examples

**Fade Transition**
```dart
ChildRoute('/home', 
  child: (_, __) => HomePage(),
  transition: GoTransitions.fade)
```

**Slide Transition**
```dart
ChildRoute('/products', 
  child: (_, __) => ProductsPage(),
  transition: GoTransitions.slide.toRight)
```

**Scale Transition**
```dart
ChildRoute('/profile', 
  child: (_, __) => ProfilePage(),
  transition: GoTransitions.scale.withFade)
```

### Combined Effects

**Slide + Fade**
```dart
ChildRoute('/details', 
  child: (_, __) => DetailsPage(),
  transition: GoTransitions.slide.toRight.withFade)
```

**Scale + Rotation**
```dart
ChildRoute('/settings', 
  child: (_, __) => SettingsPage(),
  transition: GoTransitions.scale.withRotation)
```

### Platform-Specific

**iOS Style**
```dart
ChildRoute('/ios', 
  child: (_, __) => IOSPage(),
  transition: GoTransitions.cupertino)
```

**Android Style**
```dart
ChildRoute('/android', 
  child: (_, __) => AndroidPage(),
  transition: GoTransitions.fadeUpwards)
```

## Complete App Example

```dart
class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', 
      child: (_, __) => HomePage(),
      transition: GoTransitions.fadeUpwards),
    
    ChildRoute('/products', 
      child: (_, __) => ProductsPage(),
      transition: GoTransitions.slide.toRight.withFade),
    
    ChildRoute('/profile', 
      child: (_, __) => ProfilePage(),
      transition: GoTransitions.scale.withFade),
  ];
}

// In main.dart
await Modular.configure(
  appModule: AppModule(),
  initialRoute: '/',
  defaultTransition: GoTransitions.fadeUpwards, // Default for all routes
);
```

## Performance Tips

**Lightweight for Frequent Routes**
```dart
ChildRoute('/home', 
  child: (_, __) => HomePage(),
  transition: GoTransitions.fade) // Simple fade is fastest
```

**Special Occasions**
```dart
ChildRoute('/celebration', 
  child: (_, __) => CelebrationPage(),
  transition: GoTransitions.rotate.withScale.withFade)
```

## Documentation

For more details about available transitions and customization options, see the [go_transitions package documentation](https://pub.dev/packages/go_transitions).
