import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ModularApp extends MaterialApp {
  ModularApp.router({
    super.key,
    Widget Function(BuildContext, Widget?)? builder,
    CustomModularLoader? customModularLoader,
    super.title,
    super.onGenerateTitle,
    super.color,
    super.theme,
    super.darkTheme,
    super.highContrastTheme,
    super.highContrastDarkTheme,
    super.themeMode,
    super.themeAnimationDuration,
    super.themeAnimationCurve,
    super.locale,
    super.localizationsDelegates,
    super.localeListResolutionCallback,
    super.localeResolutionCallback,
    super.supportedLocales,
    super.debugShowMaterialGrid,
    super.showPerformanceOverlay,
    super.checkerboardRasterCacheImages,
    super.checkerboardOffscreenLayers,
    super.showSemanticsDebugger,
    super.debugShowCheckedModeBanner,
    super.shortcuts,
    super.actions,
    super.restorationScopeId,
    super.scrollBehavior,
    super.themeAnimationStyle,
    super.backButtonDispatcher,
    super.onNavigationNotification,
    super.routeInformationParser,
    super.routerDelegate,
    super.routeInformationProvider,
    super.scaffoldMessengerKey,
  }) : super.router(
          routerConfig: Modular.routerConfig,
          builder: (context, child) {
            final materialChild = builder?.call(context, child) ?? child ?? const SizedBox.shrink();
            return Stack(
              children: [
                materialChild,
                ModularLoader.buildLoader(customModularLoader),
              ],
            );
          },
        );
}
