import 'package:go_router_modular/src/routing/history/browser_history.dart';

class _NoBrowserHistory extends BrowserHistory {
  const _NoBrowserHistory();

  @override
  bool go(int delta) => false;
}

/// Platforms without a browser: there is no session history to move.
BrowserHistory createPlatformBrowserHistory() => const _NoBrowserHistory();
