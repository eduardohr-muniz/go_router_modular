import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routeController = RouteController({
      '/': (context, params) => const HomePage(),
      '/user/:user_id': (context, params) => UserPage(userId: params['user_id']!),
      '/product/:product_id/details': (context, params) => ProductPage(productId: params['product_id']!),
    });

    return MaterialApp(
      title: 'Flutter test',
      onGenerateRoute: routeController.generateRoute,
      initialRoute: '/',
    );
  }
}

class RouteController {
  final Map<String, Widget Function(BuildContext, Map<String, String>)> routes;

  RouteController(this.routes);

  Route<dynamic>? generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name!);

    for (var routePattern in routes.keys) {
      final routeUri = Uri.parse(routePattern);

      if (uri.pathSegments.length == routeUri.pathSegments.length) {
        var params = <String, String>{};
        var isMatch = true;

        for (var i = 0; i < uri.pathSegments.length; i++) {
          final routeSegment = routeUri.pathSegments[i];
          final uriSegment = uri.pathSegments[i];

          if (routeSegment.startsWith(':')) {
            final paramName = routeSegment.substring(1);
            params[paramName] = uriSegment;
          } else if (routeSegment != uriSegment) {
            isMatch = false;
            break;
          }
        }

        if (isMatch) {
          return MaterialPageRoute(
            builder: (context) => routes[routePattern]!(context, params),
            settings: settings,
          );
        }
      }
    }

    return MaterialPageRoute(builder: (context) => const NotFoundPage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/user/123');
              },
              child: const Text('Go to User 123'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/product/456/details');
              },
              child: const Text('Go to Product 456 Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserPage extends StatelessWidget {
  final String userId;

  const UserPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User $userId')),
      body: Center(
        child: Text('User ID: $userId'),
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $productId Details')),
      body: Center(
        child: Text('Product ID: $productId'),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(child: Text('Page not found')),
    );
  }
}
