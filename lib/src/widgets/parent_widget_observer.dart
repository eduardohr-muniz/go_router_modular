import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ParentWidgetObserver extends StatefulWidget {
  final void Function(Module module) onDispose;
  final void Function(Module module) didChangeDependencies;

  final Widget child;
  final Module module;
  const ParentWidgetObserver({super.key, required this.onDispose, required this.child, required this.didChangeDependencies, required this.module});

  @override
  State<ParentWidgetObserver> createState() => _ParentWidgetObserverState();
}

class _ParentWidgetObserverState extends State<ParentWidgetObserver> {
  @override
  void initState() {
    super.initState();
    // IMPORTANTE: Definir o contexto ANTES do build para que os filhos possam resolver dependências
    InjectionManager.instance.setModuleContext(widget.module.runtimeType);
  }

  @override
  void dispose() {
    widget.onDispose(widget.module);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // Garantir que o contexto está definido sempre que as dependências mudam
    InjectionManager.instance.setModuleContext(widget.module.runtimeType);

    widget.didChangeDependencies(widget.module);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Garantir que o contexto está definido antes de renderizar o filho
    // Isso permite que context.read<T>() funcione no initState/build dos filhos
    InjectionManager.instance.setModuleContext(widget.module.runtimeType);
    return widget.child;
  }
}
