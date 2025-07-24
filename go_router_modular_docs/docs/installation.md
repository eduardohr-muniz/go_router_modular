---
sidebar_position: 2
title: Installation
description: Add GoRouter Modular to your Flutter project in just a few steps
---

# 📦 Installation

Add GoRouter Modular to your Flutter project in just a few steps.

## Add Dependencies

Add the following to your `pubspec.yaml` file:

```yaml title="pubspec.yaml"
dependencies:
  flutter:
    sdk: flutter
  go_router_modular: ^4.0.0
  event_bus: ^2.0.0
```

## Install Packages

```bash
# Using Flutter CLI
flutter pub get

# Or using Dart CLI
dart pub get
```

## Import in Dart Files

```dart
import 'package:go_router_modular/go_router_modular.dart';
```

:::info 📋 Requirements
- **Flutter SDK:** >= 3.0.0
- **Dart SDK:** >= 2.17.0  
- **event_bus:** ^2.0.0 (for Event Module system)
:::

## Platform Support

GoRouter Modular works on all Flutter platforms:

| Platform | Support | Status |
|----------|---------|--------|
| 📱 **Mobile** | iOS & Android | ✅ Full Support |
| 🌐 **Web** | Progressive Web Apps | ✅ Full Support |
| 🖥️ **Desktop** | Windows, macOS, Linux | ✅ Full Support |

## Verify Installation

Create a simple test to verify everything is working:

```dart title="test/installation_test.dart"
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  test('GoRouter Modular should be importable', () {
    // If this compiles, the installation is successful
    expect(Module, isNotNull);
    expect(Modular, isNotNull);
    expect(EventModule, isNotNull);
  });
}
```

Run the test:

```bash
flutter test test/installation_test.dart
```

:::tip 🎉 Success!
If the test passes, GoRouter Modular is properly installed and ready to use!
:::

## What's Next?

Now that you have GoRouter Modular installed, let's create your first modular application:

import DocCardList from '@theme/DocCardList';

<DocCardList /> 