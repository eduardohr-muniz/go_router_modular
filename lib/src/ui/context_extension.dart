import 'package:flutter/material.dart';
import 'package:go_router_modular/src/di/bind.dart';

extension BindContextExtension on BuildContext {
  T read<T>() {
    final bind = Bind.get<T>();
    return bind;
  }
}
