@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';
import 'package:web/web.dart' as web;

/// Verifica a implementação REAL de [BrowserHistory] no navegador.
///
/// `browser_history_web.dart` só é compilado para web, então a suíte da VM
/// nunca o carrega: nela o provider só enxerga `BrowserHistory` através de um
/// fake (ver `test/web_browser_history_test.dart`). Estes testes fecham essa
/// lacuna exercitando `window.history` de verdade.
///
/// Rode com: `flutter test --platform chrome test/browser_history_web_test.dart`
void main() {
  final history = createBrowserHistory();

  /// Marca a entrada atual do histórico, para reconhecê-la depois de um `go`.
  void stamp(String label) {
    web.window.history.replaceState(label.toJS, '', web.window.location.href);
  }

  String? currentStamp() => (web.window.history.state as JSString?)?.toDart;

  /// Espera o `popstate` que o navegador entrega de forma assíncrona depois de
  /// um `history.go`.
  Future<void> awaitPopState() {
    final popped = Completer<void>();
    late final JSFunction listener;
    void onPop(web.Event _) {
      web.window.removeEventListener('popstate', listener);
      if (!popped.isCompleted) popped.complete();
    }

    listener = onPop.toJS;
    web.window.addEventListener('popstate', listener);
    return popped.future.timeout(const Duration(seconds: 5));
  }

  test('go(0) é no-op e não mexe no histórico', () {
    final lengthBefore = web.window.history.length;

    expect(history.go(0), isFalse, reason: 'delta 0 não é um movimento');
    expect(web.window.history.length, lengthBefore);
  });

  test('go(-1) volta para a entrada anterior', () async {
    stamp('primeira');
    web.window.history.pushState('segunda'.toJS, '', web.window.location.href);
    expect(currentStamp(), 'segunda');

    final popped = awaitPopState();
    expect(history.go(-1), isTrue);
    await popped;

    expect(currentStamp(), 'primeira', reason: 'o popstate do go(-1) entrega o estado da entrada anterior');
  });

  test('go(-n) volta n entradas de uma vez', () async {
    stamp('base');
    for (final label in ['a', 'b', 'c']) {
      web.window.history.pushState(label.toJS, '', web.window.location.href);
    }
    expect(currentStamp(), 'c');

    final popped = awaitPopState();
    expect(history.go(-3), isTrue);
    await popped;

    expect(currentStamp(), 'base', reason: 'um único go(-3) colapsa três entradas');
  });

  test('go não muda a URL: o histórico do Modular espelha a pilha, não o endereço', () async {
    final urlBefore = web.window.location.href;
    stamp('antes');
    web.window.history.pushState('depois'.toJS, '', urlBefore);

    final popped = awaitPopState();
    expect(history.go(-1), isTrue);
    await popped;

    expect(web.window.location.href, urlBefore);
  });
}
