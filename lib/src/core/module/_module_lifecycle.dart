part of 'module.dart';

/// Gerenciamento do ciclo de vida do módulo
extension ModuleLifecycle on Module {
  Future<void> _registerModule(Module module) async {
    await InjectionManager.instance.registerBindsModule(module);
  }

  void _disposeModule(Module module) {
    if (didChangeGoingReference.contains(module)) return;
    InjectionManager.instance.unregisterModule(module);
  }

  void _onDidChange(Module module) {
    didChangeGoingReference.add(module);
    Future.microtask(() {
      didChangeGoingReference.remove(module);
    });
  }
}
