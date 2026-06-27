import 'package:event_bus/event_bus.dart';
import 'package:go_router_modular/src/di/bind.dart';
import 'package:go_router_modular/src/di/dependency_analyzer.dart';
import 'package:go_router_modular/src/di/injection_manager.dart';
import 'package:go_router_modular/src/events/modular_event.dart';
import 'package:go_router_modular/src/testing/modular_event_bus.dart';
import 'package:go_router_modular/src/testing/bind_template.dart';
import 'package:go_router_modular/src/testing/event_recorder.dart';
import 'package:go_router_modular/src/testing/recorded_event_list.dart';

/// Facade principal da testing API.
///
/// Centraliza o ciclo de vida de DI e eventos em testes, garantindo isolamento
/// entre cada execução sem boilerplate manual.
///
/// ## Padrão com template (binds compartilhados entre todos os testes):
/// ```dart
/// final scope = ModularTestScope.fresh()
///     .withInstance<AppConfig>(AppConfig.test())
///     .withLazySingleton<ApiClient>(() => ApiClient());
///
/// setUp(scope.setUp);
/// tearDown(scope.tearDown);
///
/// test('...', () {
///   scope.registerInstance<MyService>(FakeMyService()); // per-test override
///   expect(scope.get<MyService>(), isA<FakeMyService>());
/// });
/// ```
///
/// ## Padrão simples (tudo configurado no setUp):
/// ```dart
/// final scope = ModularTestScope.fresh();
///
/// setUp(() {
///   scope.setUp();
///   scope.registerInstance<MyService>(FakeMyService());
///   scope.listenFor<MyEvent>();
/// });
/// tearDown(scope.tearDown);
/// ```
///
/// Object Calisthenics:
///   - Duas variáveis de instância (Regra 8)
///   - Métodos `withXxx` retornam novo scope (imutável por template — Regra 9)
///   - Registros diretos via `registerXxx` são operações explícitas (sem magia)
class ModularTestScope {
  final BindTemplate _template;
  final EventRecorder _recorder;

  ModularTestScope._(this._template, this._recorder);

  /// Cria um scope limpo, sem nenhum bind ou listener pré-configurado.
  factory ModularTestScope.fresh() {
    return ModularTestScope._(BindTemplate.empty(), EventRecorder.fresh());
  }

  // ── Template (fluente, imutável) ─────────────────────────────────────────

  /// Adiciona um singleton ao template — reaplicado a cada [setUp].
  ModularTestScope withInstance<T>(T instance) {
    return ModularTestScope._(
      _template.withInstance<T>(instance),
      _recorder,
    );
  }

  /// Adiciona uma factory ao template — reaplicada a cada [setUp].
  ModularTestScope withFactory<T>(T Function() factory) {
    return ModularTestScope._(
      _template.withFactory<T>(factory),
      _recorder,
    );
  }

  /// Adiciona um lazy singleton ao template — reaplicado a cada [setUp].
  ModularTestScope withLazySingleton<T>(T Function() factory) {
    return ModularTestScope._(
      _template.withLazySingleton<T>(factory),
      _recorder,
    );
  }

  // ── Registro direto (pós-setUp, por-teste) ───────────────────────────────

  /// Registra um singleton imediatamente no container global.
  void registerInstance<T>(T instance) {
    Bind.register(Bind.singleton<T>((_) => instance));
  }

  /// Registra uma factory imediatamente no container global.
  void registerFactory<T>(T Function() factory) {
    Bind.register(Bind.add<T>((_) => factory()));
  }

  /// Registra um lazy singleton imediatamente no container global.
  void registerLazySingleton<T>(T Function() factory) {
    Bind.register(Bind.lazySingleton<T>((_) => factory()));
  }

  // ── DI — resolução ───────────────────────────────────────────────────────

  /// Resolve o tipo [T] do container global.
  T get<T>({String? key}) => Bind.get<T>(key: key);

  /// Retorna `true` se o tipo [T] está registrado no container global.
  bool isRegistered<T>({String? key}) => Bind.isRegistered<T>(key: key);

  // ── Eventos ──────────────────────────────────────────────────────────────

  /// Inicia a gravação de eventos do tipo [E].
  ///
  /// Deve ser chamado após [setUp] ou dentro do callback de setUp.
  void listenFor<E>({EventBus? eventBus}) {
    _recorder.listenFor<E>(eventBus: eventBus);
  }

  /// Dispara um evento no EventBus global.
  void fireEvent<E>(E event, {EventBus? eventBus}) {
    ModularEventBus.fire<E>(event, eventBus: eventBus);
  }

  /// Retorna os eventos gravados do tipo [E].
  RecordedEventList<E> eventsOf<E>() => _recorder.eventsOf<E>();

  /// Apaga os eventos gravados sem cancelar os listeners.
  void clearRecordedEvents() => _recorder.clear();

  // ── Ciclo de vida ────────────────────────────────────────────────────────

  /// Limpa todo o estado global e aplica o template de binds.
  ///
  /// Deve ser chamado no `setUp` de cada grupo de testes.
  void setUp() {
    InjectionManager.instance.resetForTesting();
    DependencyAnalyzer.clearAll();
    clearEventModuleState();
    _template.registerAll();
  }

  /// Cancela listeners de eventos, limpa o container de DI e o estado de eventos.
  ///
  /// Deve ser chamado no `tearDown` de cada grupo de testes.
  void tearDown() {
    _recorder.dispose();
    InjectionManager.instance.resetForTesting();
    DependencyAnalyzer.clearAll();
    clearEventModuleState();
  }
}
