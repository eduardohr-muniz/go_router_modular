<div align="center">

<p align="center">
  <img src="https://raw.githubusercontent.com/eduardohr-muniz/go_router_modular/master/assets/go-router-modular-banner.png" alt="Go Router Modular Banner" />
</p>

# 🧩 GoRouter Modular 💉

<h3>Dependency injection and route management</h3>
<p style="margin-top: 4px;">
  <em>Perfect for micro-frontends and event-driven communication</em>
  
</p>

[![Pub Version](https://img.shields.io/pub/v/go_router_modular?color=blue&style=for-the-badge)](https://pub.dev/packages/go_router_modular)
[![GitHub Stars](https://img.shields.io/github/stars/eduardohr-muniz/go_router_modular?color=yellow&style=for-the-badge)](https://github.com/eduardohr-muniz/go_router_modular)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

**GoRouter Modular** brings modular architecture on top of **GoRouter** with per-module **dependency injection** and auto-dispose. Perfect for **micro frontends** and large-scale apps. 🚀

<div align="center">

**💡 Inspired by [flutter_modular](https://pub.dev/packages/flutter_modular)**  
GoRouter Modular is inspired by the modular architecture approach from [flutter_modular](https://pub.dev/packages/flutter_modular) by [Flutterando](https://flutterando.com.br). We are grateful for their contribution to the Flutter ecosystem.

</div>

</div>

---
## Complete Documentation

<div align="left">

[![Open the Docs](https://gist.githubusercontent.com/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/docs.svg)](https://eduardohr-muniz.github.io/go_router_modular)

</div>

## Contents

- [Key Features](#key-features)
- [Migration Guide (v4 → v5)](#migration-guide-v4--v5)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Key Features

- 🧩 **Modular Architecture** - Independent, reusable modules
- 💉 **Dependency Injection** - Built-in DI with auto-dispose
- 🛣️ **GoRouter Integration** - Type-safe and declarative navigation
- 🎭 **Event System** - Event-driven communication between modules
- 🚀 **Performance** - Lazy loading and efficient memory management
- 🛡️ **Type Safety** - Fully type-safe with compile-time error detection

## 🔄 Migration Guide (v4 → v5)

Migrate from the old `FutureOr<List<Bind<Object>>> binds()` list to the new `FutureBinds binds(Injector i)` function.

### What Changed?

Starting with v5.0, GoRouter Modular features a **completely redesigned dependency injection system** built from the ground up. The bind registration system changed from returning a list to using a function with an injector for better async support and improved type inference. This new implementation provides **4x faster performance** and is significantly more robust.

**Why the migration?**
- ✅ **Better async support** - Native support for asynchronous bind initialization
- ✅ **Improved type inference** - Enhanced type safety and better compile-time checks
- ✅ **4x faster performance** - Optimized dependency resolution and injection
- ✅ **More robust** - Better error handling and dependency cycle detection

### ❌ Old Way (v4.x)

```dart
class MyModule extends Module {
  @override
  FutureOr<List<Bind<Object>>> binds() => [
    Bind.factory<ApiService>((i) => ApiService()),
    Bind.singleton<DatabaseService>((i) => DatabaseService()),
  ];
}
```

### ✅ New Way (v5.x)

```dart
class MyModule extends Module {
  @override
  FutureBinds binds(Injector i) {
    i.add<ApiService>((i) => ApiService());
    i.addSingleton<DatabaseService>((i) => DatabaseService());
  }
}
```

### Migration Steps

**1. Change Method Signature**

```dart
// Old (v4.x)
@override
FutureOr<List<Bind<Object>>> binds() => [
  Bind.singleton<MyService>((i) => MyService()),
];

// New (v5.x) - Using the new injector API
@override
FutureBinds binds(Injector i) {
  i.addSingleton<MyService>((i) => MyService());
}
```


**2. Update Registration Syntax**

```dart
// Old (v4.x)
Bind.singleton<ApiService>((i) => ApiService())

// New (v5.x) - Using the new injector API
i.addSingleton<ApiService>((i) => ApiService())
```

**3. Use Keys When Needed**

```dart
@override
FutureBinds binds(Injector i) {
  i.addSingleton<ApiService>((i) => ApiService(), key: 'main');
  i.addSingleton<ApiService>((i) => ApiService(), key: 'backup');
}
```

### Benefits

- ✅ **4x faster performance** - Optimized dependency resolution and injection
- ✅ **Better async support** - Native support for asynchronous bind initialization
- ✅ **Improved type inference** - Enhanced type safety with better compile-time checks
- ✅ **More robust** - Better error handling and dependency cycle detection
- ✅ **Cleaner syntax** - More intuitive API without Bind wrapper overhead
- ✅ **Same functionality** - All features preserved with better performance


## 🤝 Contributing

Contributions are very welcome! Open an issue to discuss major changes and submit a PR with clear descriptions of the edits.

- Follow the project conventions and keep docs updated.
- Add small usage examples when introducing new features.

## 📄 License

This project is distributed under the **MIT** license. See [`LICENSE`](LICENSE) for details.

---

<div align="center">

### 🎉 **Happy Coding with GoRouter Modular!** 🎉

*Transform your Flutter app into a scalable, modular masterpiece* ✨

<div style={{textAlign: 'center', margin: '2rem 0'}}>
  <a href="https://github.com/eduardohr-muniz/go_router_modular/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=eduardohr-muniz/go_router_modular" alt="Contributors" />
  </a>
  <p style={{marginTop: '1rem', fontSize: '0.9rem', color: 'var(--ifm-color-emphasis-600)'}}>
    <strong>Made with <a href="https://contrib.rocks" target="_blank">contrib.rocks</a></strong>
  </p>
</div>

</div>

---