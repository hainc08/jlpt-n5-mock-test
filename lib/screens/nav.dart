import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/session.dart';
import '../services/storage.dart';
import 'exam_intro.dart';
import 'exam_room.dart';
import 'result.dart';

/// Các thao tác điều hướng dùng chung.
class Nav {
  static Future<void> openIntro(BuildContext context, String examId) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamIntroScreen(examId: examId)));
  }

  static Future<void> openResult(BuildContext context, Attempt attempt) async {
    final exam = await AppScope.of(context).repo.load(attempt.examId);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(exam: exam, attempt: attempt)));
  }

  static Future<void> resume(BuildContext context) async {
    final services = AppScope.of(context);
    final saved = services.storage.savedSession;
    if (saved == null) return;
    try {
      final exam = await services.repo.load(saved['examId'] as String);
      final session = ExamSession.fromJson(exam, saved);
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamRoomScreen(session: session)));
    } catch (_) {
      await services.storage.clearSession();
    }
  }
}
