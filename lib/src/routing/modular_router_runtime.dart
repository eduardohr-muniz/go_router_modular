import 'package:flutter/widgets.dart';
import 'package:go_transitions/go_transitions.dart';

/// Estado de runtime neutro do roteador modular.
///
/// Escrito por `GoRouterModular.configure` e lido por `routing/` e `events/`
/// sem importar o façade `GoRouterModular`/`Modular` — quebra o acoplamento
/// `config ⇄ route_builder` (Dependency Inversion: subsistemas leem estado de
/// um holder neutro, não do composition root).

/// Chave global do navegador raiz, definida em `GoRouterModular.configure`.
late GlobalKey<NavigatorState> modularNavigatorKey;

/// Transição padrão aplicada a rotas sem transição própria, definida em
/// `GoRouterModular.configure` via `defaultTransition`.
GoTransition? modularDefaultTransition;
