import 'package:flutter/material.dart';

import 'app_config.dart';
import 'data/repository.dart';
import 'screens/root_shell.dart';
import 'services/listening.dart';
import 'services/storage.dart';
import 'theme.dart';

/// Các dịch vụ dùng chung toàn app.
class Services {
  Services({required this.storage, required this.repo, required this.player});

  final Storage storage;
  final ExamRepository repo;
  final ListeningPlayer player;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final Services services;

  static Services of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}

class MockTestApp extends StatelessWidget {
  const MockTestApp({super.key, required this.services});

  final Services services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: AppConfig.name,
        debugShowCheckedModeBanner: false,
        theme: Zen.theme,
        home: const RootShell(),
      ),
    );
  }
}
