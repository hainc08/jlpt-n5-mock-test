import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_mock_test/app.dart';
import 'package:jlpt_mock_test/data/repository.dart';
import 'package:jlpt_mock_test/logic/session.dart';
import 'package:jlpt_mock_test/screens/exam_room.dart';
import 'package:jlpt_mock_test/services/listening.dart';
import 'package:jlpt_mock_test/services/storage.dart';
import 'package:jlpt_mock_test/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_data_test.dart' show loadExams;

Future<Services> makeServices() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await Storage.open();
  final repo = ExamRepository(prefs: storage.prefs);
  await repo.init();
  return Services(storage: storage, repo: repo, player: ListeningPlayer());
}

void main() {
  testWidgets('trang chủ hiển thị', (tester) async {
    final services = await makeServices();
    await tester.pumpWidget(MockTestApp(services: services));
    await tester.pump();
    expect(find.text('Thi thử JLPT N5'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });

  testWidgets('phòng thi: chọn đáp án và chuyển câu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final services = await makeServices();
    final exam = loadExams().first;
    final session = ExamSession(exam);
    await tester.pumpWidget(AppScope(
      services: services,
      child: MaterialApp(theme: Zen.theme, home: ExamRoomScreen(session: session)),
    ));
    await tester.pump();

    expect(find.text('Câu 1/21'), findsOneWidget);
    expect(find.textContaining('20:00'), findsOneWidget);

    final firstOption = session.question.options.first;
    await tester.tap(find.text(firstOption).first);
    await tester.pump();
    expect(session.answers[session.question.id], 0);

    await tester.tap(find.text('Tiếp →'));
    await tester.pump();
    expect(find.text('Câu 2/21'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(session.remainingSec, lessThan(20 * 60));

    // Dọn dẹp: gỡ widget để huỷ đồng hồ.
    await tester.pumpWidget(const SizedBox());
  });
}
