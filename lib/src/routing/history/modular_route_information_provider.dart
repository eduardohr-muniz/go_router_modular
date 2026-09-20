import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_modular/src/routing/history/browser_history.dart';

/// [RouteInformationProvider] that keeps the browser history mirrored on
/// go_router's page stack, so that the browser back button behaves like the
/// back button of every other platform.
///
/// Plain go_router creates **one history entry per URL change** (`go`, `push`,
/// `pop`, redirects…). So `go('/b')` from `/a` leaves `/a` in the browser
/// history even though the page was removed from the stack, and pressing back
/// reopens a route that was already disposed. This provider compares the stack
/// signature (the `pageKey` of each page) before and after every navigation and
/// decides:
///
/// - the stack **grew** from the current one (`push`, `go` to a nested route):
///   `pushState`, so browser back pops, as on mobile;
/// - the stack **shrank** to an entry already known (`pop`): `history.go(-n)`,
///   and the resulting `popstate` is swallowed, with no re-parse and no guards
///   re-run;
/// - the stack **changed** (`go` to another route, `replace`): `replaceState`,
///   after going back to the deepest entry that is still a prefix of the new
///   stack, so what is left in the history is exactly what is left in the stack.
///
/// Off the web `BrowserHistory.go` is a no-op and the provider degrades to the
/// default behaviour (the engine ignores `routeInformationUpdated`).
class ModularRouteInformationProvider extends GoRouteInformationProvider {
  ModularRouteInformationProvider({
    required super.initialLocation,
    required super.initialExtra,
    super.refreshListenable,
    super.routerNeglect,
    required RouteMatchList Function() currentConfiguration,
    required BrowserHistory history,
  })  : _currentConfiguration = currentConfiguration,
        _history = history;

  /// Deadline for the `popstate` of a step back that we requested ourselves.
  ///
  /// `history.go` is asynchronous and does not report whether the move is
  /// possible: when the target entry has already left the session history (the
  /// browser drops the oldest ones), no `popstate` ever arrives. Without this
  /// deadline the provider would wait forever and stop reporting the URL.
  static const Duration _popstateTimeout = Duration(seconds: 1);

  final RouteMatchList Function() _currentConfiguration;
  final BrowserHistory _history;

  /// One record per history entry created by the app, in browser order.
  final List<_HistoryEntry> _entries = <_HistoryEntry>[];

  /// Current position within [_entries] (-1 = nothing reported yet).
  int _index = -1;

  /// `popstate`s we caused ourselves that have not arrived yet.
  int _pendingPops = 0;

  /// Report held back until the pending `popstate` arrives, because the
  /// `pushState`/`replaceState` has to happen *after* the browser steps back.
  _PendingReport? _pendingReport;

  /// Releases [_pendingReport] if the expected `popstate` never arrives.
  Timer? _popstateWatchdog;

  /// Steps back that [_popstateTimeout] gave up on and that can still land as a
  /// late `popstate`, for as long as [_abandonedPopsTimer] runs.
  int _abandonedPops = 0;
  Timer? _abandonedPopsTimer;

  /// Reports received while a step back is still in flight, processed in order.
  final Queue<_HistoryEntry> _buffer = Queue<_HistoryEntry>();

  /// Whether the next report must *replace* the entry the browser is already on
  /// (after a forward move or an unknown entry handled as a `go`).
  bool _adoptNextReport = false;

  /// Signatures of the history records, for diagnostics and tests.
  @visibleForTesting
  List<List<String>> get debugEntries => _entries.map((e) => List<String>.unmodifiable(e.signature)).toList();

  /// Current position in the history, for diagnostics and tests.
  @visibleForTesting
  int get debugIndex => _index;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    if (type != RouteInformationReportingType.none) {
      // Explicit `Router.neglect` / `Router.navigate`: honour the app's intent.
      super.routerReportsNewRouteInformation(routeInformation, type: type);
      _recordExplicit(type, routeInformation);
      return;
    }
    if (!_hasChanged(routeInformation)) return;

    final entry = _HistoryEntry(_signatureOf(_currentConfiguration()), routeInformation);
    if (_pendingPops > 0) {
      _buffer.add(entry);
      return;
    }
    _process(entry);
  }

  /// Plans [entry], applies the plan to the records and reports it to the
  /// browser, holding the report back when the history has to step back first.
  void _process(_HistoryEntry entry) {
    final plan = _planFor(entry);
    _adoptNextReport = false;

    final stepsBack = _applyPlan(plan, entry);
    final report = _PendingReport(plan.report, entry);
    if (stepsBack > 0 && _history.go(-stepsBack)) {
      _deferUntilPopstate(report);
      return;
    }
    _emit(report);
  }

  /// Compares the stack of [entry] with the recorded ones and decides where the
  /// browser steps back to and what to report. Pure: touches no state.
  _HistoryPlan _planFor(_HistoryEntry entry) {
    if (_entries.isEmpty || _adoptNextReport) {
      return _HistoryPlan(targetIndex: _index, ledger: _LedgerOp.append, report: _ReportKind.replace);
    }

    final current = _entries[_index].signature;
    if (_sameSignature(current, entry.signature)) {
      return _HistoryPlan(targetIndex: _index, ledger: _LedgerOp.replaceCurrent, report: _ReportKind.replace);
    }
    if (_isPrefix(current, entry.signature)) {
      return _HistoryPlan(targetIndex: _index, ledger: _LedgerOp.append, report: _ReportKind.push);
    }

    // The stack shrank or changed: walk back to the deepest entry that is still
    // a prefix of (or equal to) the new stack.
    var target = _index - 1;
    while (target >= 0 && !_isPrefixOrSame(_entries[target].signature, entry.signature)) {
      target--;
    }
    if (target < 0) {
      // Nothing recorded relates to the new stack, so collapse onto the first
      // entry: browser back then leaves the app, as it would on mobile.
      return const _HistoryPlan(targetIndex: 0, ledger: _LedgerOp.replaceCurrent, report: _ReportKind.replace);
    }
    if (_sameSignature(_entries[target].signature, entry.signature)) {
      // Stepping back already puts the browser on the right entry, but the
      // report still has to go out: it is what resyncs the base provider's
      // `value`, which `GoRouter.refresh` and `refreshListenable` re-parse. The
      // URL is unchanged, so the `replaceState` is a no-op for the browser.
      return _HistoryPlan(targetIndex: target, ledger: _LedgerOp.replaceCurrent, report: _ReportKind.replace);
    }
    return _HistoryPlan(targetIndex: target, ledger: _LedgerOp.append, report: _ReportKind.push);
  }

  /// Moves the records to the target of [plan] and applies its entry operation.
  /// Returns how many entries the browser has to step back.
  int _applyPlan(_HistoryPlan plan, _HistoryEntry entry) {
    final stepsBack = _index - plan.targetIndex;
    _index = plan.targetIndex;
    _truncateAfterIndex();

    switch (plan.ledger) {
      case _LedgerOp.append:
        _entries.add(entry);
        _index++;
      case _LedgerOp.replaceCurrent:
        _entries[_index] = entry;
    }
    return stepsBack;
  }

  void _emit(_PendingReport report) {
    switch (report.kind) {
      case _ReportKind.replace:
        super.routerReportsNewRouteInformation(
          report.entry.routeInformation,
          type: RouteInformationReportingType.neglect,
        );
      case _ReportKind.push:
        super.routerReportsNewRouteInformation(
          report.entry.routeInformation,
          type: RouteInformationReportingType.navigate,
        );
    }
  }

  /// Holds [report] until the `popstate` of the step back arrives, under the
  /// safety deadline of [_popstateTimeout].
  void _deferUntilPopstate(_PendingReport report) {
    _pendingPops++;
    _pendingReport = report;
    _popstateWatchdog?.cancel();
    _popstateWatchdog = Timer(_popstateTimeout, _recoverFromMissingPopstate);
  }

  /// The expected `popstate` arrived: emit the held report and resume the queue.
  void _onExpectedPopstate() {
    _popstateWatchdog?.cancel();
    _popstateWatchdog = null;
    _flushPendingReport();
  }

  /// The step back never happened, so the browser is still on the previous
  /// entry.
  ///
  /// Replacing that entry keeps the history at the right size instead of
  /// stacking one more, and brings the provider back to a working state.
  void _recoverFromMissingPopstate() {
    _popstateWatchdog = null;
    _abandonedPops = _pendingPops;
    _abandonedPopsTimer?.cancel();
    _abandonedPopsTimer = Timer(_popstateTimeout, () {
      _abandonedPops = 0;
      _abandonedPopsTimer = null;
    });
    _pendingPops = 0;
    final pending = _pendingReport;
    if (pending != null) {
      _pendingReport = _PendingReport(_ReportKind.replace, pending.entry);
    }
    _flushPendingReport();
  }

  void _flushPendingReport() {
    final pending = _pendingReport;
    _pendingReport = null;
    if (pending != null) _emit(pending);
    while (_buffer.isNotEmpty && _pendingPops == 0) {
      _process(_buffer.removeFirst());
    }
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    if (_pendingPops > 0) {
      // A `popstate` we caused: the browser is already on the right entry and so
      // is go_router's stack, so there is nothing to re-parse.
      _pendingPops--;
      if (_pendingPops == 0) _onExpectedPopstate();
      return SynchronousFuture<bool>(true);
    }
    if (_abandonedPops > 0) {
      // A step back we had already given up on landed after all. The browser
      // moved, so stamp the entry it reached with the location on screen
      // instead of navigating away from it.
      _abandonedPops--;
      if (_index >= 0) _emit(_PendingReport(_ReportKind.replace, _entries[_index]));
      return SynchronousFuture<bool>(true);
    }

    final target = _indexOf(routeInformation);
    final current = _signatureOf(_currentConfiguration());
    if (target >= 0 && target <= _index && _isPrefixOrSame(_entries[target].signature, current)) {
      // A real back press onto an entry whose pages are still mounted (every
      // entry is a prefix of the next one): go_router's restore only pops, just
      // like the native back button.
      _index = target;
      return super.didPushRouteInformation(routeInformation);
    }

    // A forward move (pages already disposed) or an unknown entry (created
    // before a reload): the stored state cannot be trusted, because go_router
    // would restore pushed pages without running their redirects, and therefore
    // without their binds. Navigate to the URL as a fresh `go` so guards and
    // redirects run for the whole chain, and the resulting report replaces the
    // entry the browser is already on.
    if (target >= 0) {
      _entries.removeRange(target, _entries.length);
      _index = target - 1;
    } else {
      _entries.clear();
      _index = -1;
    }
    _adoptNextReport = true;
    return super.didPushRouteInformation(RouteInformation(uri: routeInformation.uri));
  }

  @override
  void dispose() {
    _popstateWatchdog?.cancel();
    _popstateWatchdog = null;
    _abandonedPopsTimer?.cancel();
    _abandonedPopsTimer = null;
    super.dispose();
  }

  int _indexOf(RouteInformation routeInformation) {
    for (var i = _entries.length - 1; i >= 0; i--) {
      final stored = _entries[i].routeInformation;
      if (stored.uri.toString() == routeInformation.uri.toString() && _deepEquals(stored.state, routeInformation.state)) {
        return i;
      }
    }
    return -1;
  }

  void _recordExplicit(RouteInformationReportingType type, RouteInformation routeInformation) {
    final entry = _HistoryEntry(_signatureOf(_currentConfiguration()), routeInformation);
    if (type == RouteInformationReportingType.navigate || _entries.isEmpty) {
      _truncateAfterIndex();
      _entries.add(entry);
      _index++;
      return;
    }
    _entries[_index] = entry;
  }

  void _truncateAfterIndex() {
    if (_index + 1 < _entries.length) {
      _entries.removeRange(_index + 1, _entries.length);
    }
  }

  /// The same check go_router runs before reporting to the engine.
  bool _hasChanged(RouteInformation routeInformation) {
    final current = value;
    return current.uri.path != routeInformation.uri.path ||
        !mapEquals(current.uri.queryParameters, routeInformation.uri.queryParameters) ||
        current.uri.fragment != routeInformation.uri.fragment ||
        !_deepEquals(current.state, routeInformation.state);
  }

  /// Signature of the stack: the `pageKey` of every page, including the ones
  /// nested in shells. A `pageKey` identifies the page in the Navigator, so
  /// "same sequence of keys" means "same stack".
  ///
  /// Routes stacked with `push` (`ImperativeRouteMatch`) contribute their own
  /// `pageKey`, which is already unique per push; the routes they wrap are not
  /// visited because they do not become pages of their own in the Navigator.
  static List<String> _signatureOf(RouteMatchList configuration) {
    final signature = <String>[];
    void visit(List<RouteMatchBase> matches) {
      for (final match in matches) {
        signature.add(match.pageKey.value);
        if (match is ShellRouteMatch) visit(match.matches);
      }
    }

    visit(configuration.matches);
    return signature;
  }

  static bool _sameSignature(List<String> a, List<String> b) => listEquals(a, b);

  static bool _isPrefixOrSame(List<String> prefix, List<String> full) => _sameSignature(prefix, full) || _isPrefix(prefix, full);

  /// `true` when [prefix] is a strict prefix of [full].
  static bool _isPrefix(List<String> prefix, List<String> full) {
    if (prefix.length >= full.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i] != full[i]) return false;
    }
    return true;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}

class _HistoryEntry {
  const _HistoryEntry(this.signature, this.routeInformation);

  final List<String> signature;
  final RouteInformation routeInformation;
}

/// How the recorded entries change when a [_HistoryPlan] is applied.
enum _LedgerOp {
  /// Add an entry after the target.
  append,

  /// Replace the entry at the target.
  replaceCurrent,
}

/// What to report to the browser after a [_HistoryPlan] is applied.
enum _ReportKind {
  /// `replaceState`: swap the current entry.
  replace,

  /// `pushState`: create an entry.
  push,
}

/// Decision about one navigation: where the browser steps back to, how the
/// records change and what is reported afterwards.
class _HistoryPlan {
  const _HistoryPlan({
    required this.targetIndex,
    required this.ledger,
    required this.report,
  });

  final int targetIndex;
  final _LedgerOp ledger;
  final _ReportKind report;
}

/// Report held back while the `popstate` of a step back has not arrived.
class _PendingReport {
  const _PendingReport(this.kind, this.entry);

  final _ReportKind kind;
  final _HistoryEntry entry;
}
