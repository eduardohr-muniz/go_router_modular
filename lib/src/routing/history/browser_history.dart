import 'package:flutter/foundation.dart';
import 'package:go_router_modular/src/routing/history/browser_history_stub.dart'
    if (dart.library.js_interop) 'package:go_router_modular/src/routing/history/browser_history_web.dart' as platform;

/// Minimal access to the browser's session history (`window.history`).
///
/// On platforms without a browser (mobile/desktop) the implementation is a
/// no-op that returns `false`, and the provider falls back to go_router's
/// default behaviour.
abstract class BrowserHistory {
  const BrowserHistory();

  /// Moves the session history by [delta] entries (negative goes back).
  ///
  /// Returns `true` when the platform has a browser history and the move was
  /// requested. The matching `popstate` arrives later and asynchronously,
  /// through `didPushRouteInformation`.
  bool go(int delta);
}

/// Replaces the platform implementation in tests.
@visibleForTesting
BrowserHistory? debugBrowserHistoryOverride;

/// Resolves the [BrowserHistory] implementation for the current platform.
BrowserHistory createBrowserHistory() => debugBrowserHistoryOverride ?? platform.createPlatformBrowserHistory();
