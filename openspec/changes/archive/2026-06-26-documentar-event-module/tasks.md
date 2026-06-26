## 1. Preparação e leitura de referência

- [ ] 1.1 Ler os arquivos de referência do sistema de eventos: `lib/src/events/event_module.dart`, `lib/src/events/modular_event.dart`, `lib/src/events/modular_event_listener.dart`, `lib/src/events/modular_event_mixin.dart`, `lib/src/events/event_state.dart`.
- [ ] 1.2 Ler os arquivos de suporte a teste: `lib/src/testing/event_recorder.dart`, `lib/src/testing/modular_event_bus.dart`, `lib/src/testing/recorded_event_list.dart` e a configuração `lib/src/internal/setup.dart`.
- [ ] 1.3 Mapear os testes existentes que já cobrem eventos (`test/event_module_test.dart`, `test/modular_event_mixin_test.dart`) para identificar lacunas de cobertura frente aos cenários das specs.

## 2. Documentar capability events-event-module

- [ ] 2.1 Revisar `specs/events-event-module/spec.md` confirmando que cada requisito (construtor com barramento, `initState` registrando `eventImports`/`listen`/`onAfterListen`, `ModularEventListener` delegante, `dispose` seletivo) corresponde ao código.
- [ ] 2.2 Garantir teste cobrindo `EventModule` sem barramento usa `defaultModularEventBus` e com barramento customizado usa o barramento fornecido.
- [ ] 2.3 Garantir teste cobrindo a ordem de inicialização: ouvintes de `eventImports()` e ouvintes do próprio `listen()` ativos após `initState`, incluindo módulo sem ouvintes e `eventImports` vazio.
- [ ] 2.4 Garantir teste cobrindo `dispose` que cancela ouvinte com auto-descarte e preserva ouvinte com `autoDispose: false`.

## 3. Documentar capability events-listening

- [ ] 3.1 Revisar `specs/events-listening/spec.md` confirmando os requisitos de `on`, `autoDispose`, `broadcast` depreciado, ouvintes regulares, ouvintes exclusivos em fila e `ModularEventMixin`.
- [ ] 3.2 Garantir teste cobrindo `on<T>` invocando o callback com o evento e o `BuildContext` opcional, incluindo o caso de contexto nulo, e a substituição do callback ao registrar o mesmo tipo duas vezes.
- [ ] 3.3 Garantir teste cobrindo `autoDispose` por ouvinte sobrepondo o padrão global `SetupModular.autoDisposeEvents` (ambos os sentidos).
- [ ] 3.4 Garantir teste cobrindo o parâmetro `broadcast` depreciado mapeando para `exclusive` (`exclusive = broadcast ?? exclusive`).
- [ ] 3.5 Garantir teste cobrindo ouvintes regulares: múltiplos módulos recebendo o mesmo evento e o caso de ouvinte regular ignorado quando já existe stream exclusivo do tipo.
- [ ] 3.6 Garantir teste cobrindo ouvintes exclusivos: apenas o ativo recebe, reativação do próximo da fila ao descartar o ativo, e limpeza do estado quando a fila esvazia.
- [ ] 3.7 Garantir teste cobrindo `ModularEventMixin`: recebimento com widget montado (contexto não nulo), cancelamento no `dispose` do `State` e substituição do listener ao registrar o mesmo tipo.

## 4. Documentar capability events-bus

- [ ] 4.1 Revisar `specs/events-bus/spec.md` confirmando os requisitos de `defaultModularEventBus`, isolamento por barramento, singleton `ModularEvent`, `ModularEvent.fire` e `EventState`.
- [ ] 4.2 Garantir teste cobrindo disparo e escuta sem barramento comunicando-se pelo barramento global, e estabilidade da instância de `defaultModularEventBus`.
- [ ] 4.3 Garantir teste cobrindo isolamento: evento de um barramento não alcança ouvinte de outro, e o mesmo tipo coexistindo em barramentos diferentes.
- [ ] 4.4 Garantir teste cobrindo `ModularEvent.instance.on` e `ModularEvent.instance.dispose<T>` (registro e remoção da escuta global).
- [ ] 4.5 Garantir teste cobrindo `ModularEvent.fire` no barramento padrão e em barramento customizado.
- [ ] 4.6 Garantir teste cobrindo `EventState.clearAll()` cancelando assinaturas e zerando os mapas, e a não colisão de estado entre módulos distintos no mesmo barramento.

## 5. Documentar capability events-testing

- [ ] 5.1 Revisar `specs/events-testing/spec.md` confirmando os requisitos de `clearEventModuleState`, `EventRecorder`, `ModularEventBus.fire` e `debugLogEventBus`.
- [ ] 5.2 Garantir teste cobrindo `clearEventModuleState()` evitando vazamento entre testes e completando sem erro quando não há ouvintes.
- [ ] 5.3 Garantir teste cobrindo `EventRecorder`: gravação de eventos do tipo escutado, lista vazia para tipo não escutado e `dispose` cancelando a gravação.
- [ ] 5.4 Garantir teste cobrindo `ModularEventBus.fire` no barramento padrão e em barramento customizado.
- [ ] 5.5 Garantir teste cobrindo `debugLogEventBus`: logs de disparo e recebimento emitidos quando habilitado e ausentes quando desabilitado.

## 6. Validação final

- [ ] 6.1 Verificar que nenhum arquivo em `lib/` foi alterado (mudança puramente documental).
- [ ] 6.2 Rodar `flutter analyze` e garantir ausência de avisos novos.
- [ ] 6.3 Rodar `flutter test --coverage` e conferir no `coverage/lcov.info` a cobertura de 100% (linhas e branches) dos arquivos do sistema de eventos.
- [ ] 6.4 Conferir consistência entre cada cenário das specs e um teste correspondente; registrar eventuais lacunas como tarefas adicionais.
