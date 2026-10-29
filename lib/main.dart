import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/repository.dart';
import 'services/listening.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await Storage.open();
  final repo = ExamRepository(prefs: storage.prefs);
  await repo.init();
  runApp(MockTestApp(services: Services(storage: storage, repo: repo, player: ListeningPlayer())));
  // Kiểm tra đề mới trên GitHub ở nền, không chặn giao diện.
  unawaited(repo.maybeSync());
}
