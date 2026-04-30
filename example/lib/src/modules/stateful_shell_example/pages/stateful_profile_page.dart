import 'package:flutter/material.dart';

class StatefulProfilePage extends StatefulWidget {
  const StatefulProfilePage({Key? key}) : super(key: key);

  @override
  State<StatefulProfilePage> createState() => _StatefulProfilePageState();
}

class _StatefulProfilePageState extends State<StatefulProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _notificationsEnabled = true;
  String _selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'John Doe');
    _emailController = TextEditingController(text: 'john@example.com');
    print('👤 StatefulProfilePage initState');
  }

  @override
  void dispose() {
    print('👤 StatefulProfilePage dispose - name: ${_nameController.text}');
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('👤 StatefulProfilePage build - name: ${_nameController.text}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Tab'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Page - State Persistence Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple.shade100,
                child: const Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            // Settings
            const Text(
              'Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_selectedTheme),
              trailing: DropdownButton<String>(
                value: _selectedTheme,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTheme = value);
                  }
                },
                items: ['Light', 'Dark', 'Auto']
                    .map((theme) => DropdownMenuItem(
                          value: theme,
                          child: Text(theme),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Test: Edit the fields and change settings',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Then switch to another tab. When you return, all changes should persist!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Display current values
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Values:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Name: ${_nameController.text}'),
                  Text('Email: ${_emailController.text}'),
                  Text('Notifications: ${_notificationsEnabled ? "On" : "Off"}'),
                  Text('Theme: $_selectedTheme'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
