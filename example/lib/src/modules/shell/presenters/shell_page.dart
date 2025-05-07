import 'package:flutter/material.dart';
import 'package:example/src/core/routes.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shell Example'),
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Config'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
            selectedIndex: _getSelectedIndex(context),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go(Routes.shellHome);
                  break;
                case 1:
                  context.go(Routes.shellConfig);
                  break;
                case 2:
                  context.go(Routes.shellProfile);
                  break;
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).fullPath ?? '';
    if (location.contains('/config')) return 1;
    if (location.contains('/profile')) return 2;
    return 0;
  }
}
