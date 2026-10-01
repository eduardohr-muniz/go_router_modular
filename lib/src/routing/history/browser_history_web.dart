import 'package:go_router_modular/src/routing/history/browser_history.dart';
import 'package:web/web.dart' as web;

class _WebBrowserHistory extends BrowserHistory {
  const _WebBrowserHistory();

  @override
  bool go(int delta) {
    if (delta == 0) return false;
    web.window.history.go(delta);
    return true;
  }
}

/// Web: delegates to `window.history.go`.
BrowserHistory createPlatformBrowserHistory() => const _WebBrowserHistory();
