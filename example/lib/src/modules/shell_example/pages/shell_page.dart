import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ShellPage extends StatefulWidget {
  final Widget child;

  const ShellPage({
    super.key,
    required this.child,
  });

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = context.getPath ?? '';
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
        context.push('/shell/dashboard');
        break;
      case 1:
        context.push('/shell/profile');
        break;
      case 2:
        context.push('/shell/settings');
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
