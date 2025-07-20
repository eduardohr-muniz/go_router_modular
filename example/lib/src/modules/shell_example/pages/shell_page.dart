import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ShellPage extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const ShellPage({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final result = GoRouterModular.getCurrentPathOf(context);

    print(result);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = widget.state.fullPath!;
    if (location.contains('/shell/dashboard')) {
      _selectedIndex = 0;
    } else if (location.contains('/shell/profile')) {
      _selectedIndex = 1;
    } else if (location.contains('/shell/settings')) {
      _selectedIndex = 2;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.pushReplacement('/shell/dashboard');
        break;
      case 1:
        context.pushReplacement('/shell/profile');
        break;
      case 2:
        context.pushReplacement('/shell/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shell Router Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
