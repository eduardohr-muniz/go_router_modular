import 'package:flutter/material.dart';

class StatefulHomePage extends StatefulWidget {
  const StatefulHomePage({Key? key}) : super(key: key);

  @override
  State<StatefulHomePage> createState() => _StatefulHomePageState();
}

class _StatefulHomePageState extends State<StatefulHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    print('📱 StatefulHomePage initState - _counter: $_counter');
  }

  @override
  void dispose() {
    print('📱 StatefulHomePage dispose - _counter: $_counter');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📱 StatefulHomePage build - _counter: $_counter');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Tab'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Home Page - State Persistence Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Counter (Should persist when switching tabs)',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_counter',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() => _counter++);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Increment Counter'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _counter = 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Reset Counter'),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    '💡 Test: Click the button, then switch to another tab.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When you come back, the counter should still be the same!',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
