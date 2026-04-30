/// Testing utilities for go_router_modular.
///
/// Importe esta biblioteca nos seus testes para ter acesso a toda a
/// infraestrutura de teste do pacote:
///
/// ```dart
/// import 'package:go_router_modular/testing.dart';
/// ```
///
/// ## Principais classes
///
/// - [ModularTestScope] — Facade que gerencia DI + eventos + ciclo de vida.
/// - [EventRecorder]    — Grava eventos disparados no EventBus durante testes.
/// - [RecordedEventList]— Coleção de primeira classe de eventos gravados.
/// - [FakeInjector]     — Implementação falsa de [InjectorReader] para testes unitários.
/// - [ModularEventBus]  — Utilitário estático para disparar eventos no bus global.
library;

export 'src/testing/modular_test_scope.dart';
export 'src/testing/event_recorder.dart';
export 'src/testing/recorded_event_list.dart';
export 'src/testing/fake_injector.dart';
export 'src/testing/modular_event_bus.dart';

// Re-exports úteis do pacote principal para não precisar de dois imports em testes.
export 'src/events/modular_event.dart' show clearEventModuleState, defaultModularEventBus;
