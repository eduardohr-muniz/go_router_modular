import 'package:flutter/material.dart';

class ModularLoaderController extends ValueNotifier<bool> {
  ModularLoaderController() : super(false);

  void show() => value = true;
  void hide() => value = false;
}

abstract class CustomModularLoader {
  Color get backgroundColor;
  Widget get child;
}

class ModularLoader {
  static ModularLoaderController? _controller;

  static ModularLoaderController get controller {
    _controller ??= ModularLoaderController();
    return _controller!;
  }

  static void show() {
    controller.show();
  }

  static void hide() {
    controller.hide();
  }

  static Widget builder(BuildContext context, Widget? child, {CustomModularLoader? customModularLoader}) {
    final materialChild = child ?? const SizedBox.shrink();
    return Stack(
      children: [
        materialChild,
        ModularLoader.buildLoader(customModularLoader),
      ],
    );
  }

  static Widget buildLoader(CustomModularLoader? loader) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller,
      builder: (context, isLoading, child) {
        if (!isLoading) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: loader?.backgroundColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              if (loader != null) loader.child,
              if (loader == null)
                const Center(
                  child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
