---
name: go-router-modular
description: Best practices and project structure for the go_router_modular Flutter package. Use this whenever you scaffold or edit a go_router_modular app — creating a feature's routes, adding a ChildRoute or ModuleRoute, registering a Module's binds/imports, writing navigation code (go/push), setting up main.dart / AppModule / AppWidget, or wiring debug logs — even if the user doesn't explicitly ask for "best practices". It enforces the project convention: the lib/src/modules/<feature>/ layout, a feature route file per feature, named-only navigation, name on every ChildRoute, synchronous modules with binds via the `..` cascade, and Modular.configure logs gated on kDebugMode.
---

# go_router_modular conventions

This project uses **go_router_modular** (DI + modular routing on top of `go_router`).
When you touch routes, modules, or navigation, follow the conventions below so the
generated code matches the rest of the codebase and stays refactor-safe.

Source of truth (read when you need detail, don't duplicate it here):

- Docs: `nextra_docs/content/en/routes/navigation.mdx`, `nextra_docs/content/en/routes/routes-system.mdx`
- Specs: `openspec/specs/routing-navigation/spec.md`, `openspec/specs/routing-routes/spec.md`

## The three rules

1. **Navigate only by name.** Never call `context.go('/raw-path')`. Every navigation
   goes through a feature's `*Route` class, which delegates to `goNamed`/`pushNamed`.
   Raw path strings scatter route literals across the app and break silently when a
   path changes; a named route + a single constants file means one place to edit.
2. **Every `ChildRoute` declares a `name`.** Without `name`, named navigation can't
   resolve the route. The name lives on the leaf `ChildRoute`.
3. **Keep modules synchronous.** Prefer synchronous `binds(Injector i)` and `imports()`.
   An `async`/`Future`-returning module delays route registration and the first frame;
   use it only when genuinely unavoidable, and keep the async scope as small as possible.

## Project structure

Standard layout: a thin `lib/` root that boots the app, with everything else under
`src/` and one folder per feature inside `src/modules/`.

```
lib/
├── main.dart                     // bootstrap: Modular.configure + runApp
└── src/
    ├── app_module.dart           // root module: composes feature modules via ModuleRoute
    ├── app_widget.dart           // the MaterialApp via ModularApp.router
    └── modules/
        └── my/                    // one folder per feature
            ├── my_module.dart     // the Module (binds, imports, routes)
            ├── my_route.dart      // MyRouteRelative (constants + readers) + MyRoute (navigation)
            └── pages/
                └── my_page.dart
```

`my_route.dart` holds two classes with distinct, semantic jobs:

- `MyRouteRelative` — path/name constants, param keys, and the static path-param readers
  (e.g. `getMyIdParam(state)`). No navigation, no context. Keeping the reader here puts it
  next to the param key it reads.
- `MyRoute` — the navigation surface, built from a `BuildContext` (`MyRoute.of(context)`).
  It answers "how do I go there?" and is the only place that calls `goNamed`/`pushNamed`.

## App bootstrap — wire debug logs to `kDebugMode`

`main.dart` configures the app once and gates every diagnostic log on `kDebugMode`, so
logs are rich while developing and completely silent in release builds.

```dart
// lib/main.dart
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'src/app_module.dart';
import 'src/app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: '/',
    // Logs only in debug builds — release stays quiet.
    debugLogDiagnostics: kDebugMode,         // go_router_modular logs
    debugLogDiagnosticsGoRouter: kDebugMode, // underlying go_router logs
    debugLogEventBus: kDebugMode,            // event bus logs
  );

  runApp(const AppWidget());
}
```

```dart
// lib/src/app_widget.dart — ModularApp.router wires Modular.routerConfig + the loader.
class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) => ModularApp.router(title: 'My App');
}
```

`AppModule` is the composition root: it registers app-wide binds (via the `..` cascade,
see Rule 3) and mounts each feature module with `ModuleRoute` at its `*Module` path.

```dart
// lib/src/app_module.dart
class AppModule extends Module {
  @override
  void binds(Injector i) {
    i
      // Services
      ..addSingleton<DioClient>((i) => DioClient())
      ..addSingleton<AuthStore>((i) => AuthStore());
  }

  @override
  List<ModularRoute> get routes => [
        ModuleRoute(MyRouteRelative.myModule, module: MyModule()),
        // ...other feature modules
      ];
}
```

### Canonical `feature_route.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Path/name constants, param keys, and the static param readers. No navigation here.
class MyRouteRelative {
  MyRouteRelative._();

  // params
  static const String param$id = 'id';

  /// Mount path of this module inside the parent module.
  static const String myModule = '/my';

  /// Relative path mounted as a ChildRoute (usually '/').
  static const String my = '/';
  static const String myNamed = 'my-feature';

  /// Relative path with a path param.
  static const String myDetail$id = '/detail/:${param$id}';
  static const String myDetailNamed = 'detail';

  /// Reads the `id` path param from the current route state.
  static String getMyIdParam(GoRouterState state) =>
      state.pathParameters[param$id] as String;
}

/// Navigation entry point. Built from a BuildContext.
class MyRoute {
  MyRoute.of(this.context);
  final BuildContext context;

  void go() => context.goNamed(MyRouteRelative.myNamed);
  void push() => context.pushNamed(MyRouteRelative.myNamed);

  // Route with a parameter: arguments go through the method, never the call site.
  void pushMyDetail({required String id}) => context.pushNamed(
        MyRouteRelative.myDetailNamed,
        pathParameters: {MyRouteRelative.param$id: id},
      );
}
```

## Rule 1 — navigate only by name

Always navigate through the feature's `*Route` class. Pass `pathParameters` and `extra`
through its methods, so call sites never assemble route strings or parameter maps.

**Incorrect — raw path string:**

```dart
context.go('/my');
context.push('/my/detail/42');
```

**Correct — named, via the navigation class:**

```dart
MyRoute.of(context).go();
MyRoute.of(context).pushMyDetail(id: '42');
```

## Rule 2 — `name` on `ChildRoute`, and module composition

In `Module.routes`, set each `ChildRoute`'s `path` from a relative constant and its `name`
from the matching `*Named` constant. Read path params via the `*RouteRelative` static reader.

```dart
class MyModule extends Module {
  @override
  void binds(Injector i) {
    i
      // DataSources
      ..addSingleton<MyDataSource>((i) => MyDataSource(i.get<DioClient>()))
      // Repositories
      ..addSingleton<MyRepository>((i) => MyRepository(i.get<MyDataSource>()))
      // Controllers
      ..add<MyController>((i) => MyController(i.get<MyRepository>()));
  }

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          MyRouteRelative.my,
          name: MyRouteRelative.myNamed,
          child: (context, _) => MyPage(controller: Modular.get<MyController>()),
        ),
        ChildRoute(
          MyRouteRelative.myDetail$id,
          name: MyRouteRelative.myDetailNamed,
          child: (context, state) => MyDetailPage(
            controller: Modular.get<MyController>(),
            id: MyRouteRelative.getMyIdParam(state),
          ),
        ),
      ];
}
```

The `*Module` constant defines where this module is mounted in its parent:

```dart
// In the parent module:
ModuleRoute(MyRouteRelative.myModule, module: MyModule());
```

`ModuleRoute` also accepts a `name` if you need to target the module mount point itself;
prefer naming the leaf `ChildRoute` you actually navigate to.

## Rule 3 — synchronous modules, binds via the `..` cascade

Prefer synchronous `binds`/`imports`. They register immediately, so routes are ready
without delaying the first frame. Use a **block body** for `binds` and register on the
injector with the cascade operator (`..`) — one `i` followed by a chain of `..addX`,
**grouped by layer with comments** (`// Services`, `// DataSources`, `// Repositories`,
`// Controllers`). It reads as one declarative block, avoids repeating `i.` per line, and
keeps each layer easy to scan. Do not use an arrow body (`=> i ..`) for binds.

Always pass the **explicit type** — `addSingleton<MyRepository>((i) => ...)`. The bind is
then indexed under that exact type and resolves via direct lookup; without it the container
falls back to runtime-type discovery (probing factories), which can run constructors as a
side effect. Typing also lets you register an implementation behind its interface, e.g.
`addSingleton<AuthRepository>((i) => AuthRepositoryImpl(i.get<AuthApi>()))`.

Resolve dependencies with the explicit type too — `i.get<MyRepository>()` inside a factory,
and `Modular.get<MyController>()` (or `context.read<MyController>()`) at the call site.

**Prefer:**

```dart
@override
void binds(Injector i) {
  i
    // Services
    ..addSingleton<AnalyticsService>((i) => AnalyticsService())
    // DataSources
    ..addSingleton<MyRemoteDataSource>((i) => MyRemoteDataSource(i.get<DioClient>()))
    // Repositories
    ..addSingleton<MyRepository>((i) => MyRepository(i.get<MyRemoteDataSource>()))
    // Controllers
    ..add<MyController>((i) => MyController(i.get<MyRepository>()));
}

@override
List<Module> imports() => [SharedModule()];
```

**When a dependency needs an awaited resource, do NOT make the module async.** Instead,
`await` it in `main()` before `Modular.configure`, then pass the ready instance into
`AppModule` through its constructor and register it synchronously. The module stays
synchronous and routes register without delay.

```dart
// lib/main.dart — same bootstrap as above, with the resource resolved before configuring.
final prefs = await SharedPreferences.getInstance(); // await up front
await Modular.configure(
  appModule: AppModule(prefs: prefs), // pass it in; other params (logs, etc.) unchanged
  initialRoute: '/',
);
```

```dart
// lib/src/app_module.dart
class AppModule extends Module {
  AppModule({required this.prefs});
  final SharedPreferences prefs;

  @override
  void binds(Injector i) {
    i
      // Services
      ..addSingleton<SharedPreferences>((i) => prefs); // already resolved, just registered
  }
}
```

The package _does_ support an `async` `binds` (`Future<void> binds(Injector i) async {...}`),
but prefer the pattern above — async modules delay route registration and the first frame.
Reach for async `binds` only when an awaited resource genuinely cannot be hoisted into
`main()`, and keep the awaited work minimal.

## Naming conventions

| Element                  | Convention                                 | Example                    |
| ------------------------ | ------------------------------------------ | -------------------------- |
| Constants + readers class | suffix `*RouteRelative`                   | `MyRouteRelative`          |
| Navigation class          | suffix `*Route` (built via `.of(context)`)| `MyRoute`, `ProfileRoute`  |
| Route name string        | kebab-case                                 | `my-feature`, `detail`     |
| Param key constant       | prefix `param$`                            | `param$id`                 |
| Relative path constant   | the feature/leaf name                      | `my`                       |
| Module mount constant    | suffix `*Module`                           | `myModule`                 |
| Name constant            | suffix `*Named`                            | `myNamed`, `myDetailNamed` |
| Param-bearing path       | suffix `*$<param>`                         | `myDetail$id`              |

## Checklist before finishing a routing change

- The feature lives under `lib/src/modules/<feature>/`, with `<feature>_module.dart`,
  `<feature>_route.dart`, and a `pages/` folder; the app boots from `lib/main.dart` with
  `AppModule`/`AppWidget` under `lib/src/`.
- Each feature with routes has a `*_route.dart` next to its `*_module.dart`, with a
  `*RouteRelative` constants/readers class and a `*Route` navigation class.
- Every `ChildRoute` has both `path` (from a relative constant) and `name` (from a `*Named` constant).
- No `context.go('/...')` / `context.push('/...')` with raw path strings — navigation goes through `*Route`.
- Path params are read via the `*RouteRelative` static reader (e.g. `MyRouteRelative.getMyIdParam(state)`),
  not inline `state.pathParameters[...]` at the call site.
- `binds`/`imports` are synchronous. Async resources (e.g. `SharedPreferences`) are awaited
  in `main()` and passed into `AppModule` via its constructor — not resolved in an async `binds`.
- `binds` uses a **block body** with the `..` cascade on the injector (never `=> i ..`),
  grouped by layer with comments (`// Services`, `// DataSources`, `// Repositories`, `// Controllers`).
- Binds and lookups are **typed**: `addSingleton<T>`/`add<T>` on registration, and
  `i.get<T>()` / `Modular.get<T>()` / `context.read<T>()` on resolution — never untyped.
- `Modular.configure` gates `debugLogDiagnostics` / `debugLogDiagnosticsGoRouter` /
  `debugLogEventBus` on `kDebugMode` so release builds stay silent.
