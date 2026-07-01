---
name: go-router-modular-events
description: Conventions for the event system of the go_router_modular Flutter package — decoupled cross-module communication via EventModule, ModularEvent, and ModularEventMixin. Use this whenever you need modules or widgets to react to something without a direct reference (e.g. "show a snackbar from another module", "notify the cart when an order is placed", "broadcast a login event", emit/listen events, fire/on, EventModule listeners). It is an optional add-on to the go-router-modular skill and assumes its conventions.
---

# go_router_modular events

The package ships an event bus for **decoupled communication** — when one part of the app
must react to something another part does, without holding a reference to it. This is an
opt-in subsystem; reach for it only when a direct call/DI dependency would couple things
that should stay independent (e.g. cross-module reactions, global UI like snackbars/modals).

Assumes the conventions of the `go-router-modular` skill (modules, DI, named routes).
Reference: `nextra_docs/content/en/event-module/`.

## Events are small, immutable classes

One class per fact that happened. Keep them tiny and `const`-constructible — they are values,
not behavior.

```dart
class OrderPlaced {
  const OrderPlaced(this.orderId);
  final String orderId;
}
```

## Emit with `ModularEvent.fire`

Fire from anywhere (a controller, a button, a service). The emitter never knows who listens.

```dart
ModularEvent.fire(const OrderPlaced('42'));
```

## Two ways to listen — pick by scope

Both cancel their subscriptions automatically, so listeners never leak:

| You need…                                   | Use                 | Disposal               |
| ------------------------------------------- | ------------------- | ---------------------- |
| A module to react while it's alive          | `EventModule`       | automatic (on dispose) |
| A widget (`State`) to react while mounted   | `ModularEventMixin` | automatic (on dispose) |

In every callback the `BuildContext` **can be null** (no navigator mounted yet, web refresh,
etc.) — always null-check before using it.

### 1. `EventModule` — module-level listeners

Make the module extend `EventModule` and register listeners in `listen()`. They are cancelled
automatically when the module is disposed. Compose another module's listeners by calling its
`listen()` synchronously inside yours — the child's listeners inherit this (host) module's
lifecycle, with no duplication when the host is recreated.

```dart
class CartModule extends EventModule {
  @override
  void binds(Injector i) {
    i..addSingleton<CartController>((i) => CartController());
  }

  @override
  void listen() {
    on<OrderPlaced>((event, context) {
      Modular.get<CartController>().clear(event.orderId);
      Modular.get<Analytics>().track('order_placed', {'id': event.orderId});
    });

    // Keep this listener alive even after the module is disposed.
    on<SessionExpired>((event, context) { /* ... */ }, autoDispose: false);

    NotificationsEventModule().listen(); // compose another module's listeners
  }
}
```

`on<T>` options: `autoDispose` (defaults to the global config; set `false` to survive dispose)
and `exclusive: true` (only the active listener of that type on the bus receives the event).

### 2. `ModularEventMixin` — widget-level listeners

Mix into a `State<StatefulWidget>` and register in `initState`; subscriptions are cancelled in
`dispose` for you.

```dart
class _CheckoutPageState extends State<CheckoutPage> with ModularEventMixin {
  @override
  void initState() {
    super.initState();
    on<OrderPlaced>((event, context) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${event.orderId} placed')),
        );
      }
    });
  }
}
```

## Checklist

- Events are small, immutable, `const`-constructible value classes — one per fact.
- Emit with `ModularEvent.fire(const SomeEvent(...))`; the emitter doesn't know its listeners.
- Listen via `EventModule` (module scope) or `ModularEventMixin` (widget scope) — both cancel
  automatically, so listeners never leak.
- `EventModule` listeners go in `listen()`; compose others via `OtherEventModule().listen()`.
- Always null-check the callback's `BuildContext` before using it.
- Use only public symbols: `EventModule`, `ModularEvent`, `ModularEventMixin`.
