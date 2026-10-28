import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/repository.dart';
import 'services/listening.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final services = Services(
    storage: await Storage.open(),
    repo: ExamRepository(),
    player: ListeningPlayer(),
  );
  runApp(MockTestApp(services: services));
}
