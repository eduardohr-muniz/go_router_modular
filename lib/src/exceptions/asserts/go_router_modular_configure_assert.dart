class GoRouterModularConfigureAssert {
  GoRouterModularConfigureAssert._();

  static String goRouterModularConfigureAssert() {
    return '''
Add GoRouterModular.configure in main.dart and AppWidget app_widget.dart

Example of correct setup in main.dart:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await GoRouterModular.configure(
    appModule: AppModule(),
    initialRoute: '/',
  );
  
  runApp(AppWidget());
}
```

Example of correct setup in app_widget.dart:
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      title: 'Modular GoRoute Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```

Make sure to call GoRouterModular.configure() before accessing routerConfig.
''';
  }
}
