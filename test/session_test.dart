import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_mock_test/logic/session.dart';

import 'exam_data_test.dart' show loadExams;

void main() {
  final exam = loadExams().first;

  test('chọn đáp án, đánh dấu, chuyển câu', () {
    final s = ExamSession(exam);
    expect(s.remainingSec, 20 * 60);
    s.select(2);
    expect(s.answers[s.question.id], 2);
    s.toggleFlag();
    expect(s.flagged, contains(s.question.id));
    s.next();
    expect(s.index, 1);
    s.goTo(999);
    expect(s.index, 1);
    s.dispose();
  });

  test('nộp phần → nghỉ → phần tiếp theo → kết thúc', () {
    final s = ExamSession(exam);
    s.endSection();
    expect(s.phase, SessionPhase.sectionBreak);
    s.startNextSection();
    expect(s.sectionIndex, 1);
    expect(s.remainingSec, 40 * 60);
    expect(s.phase, SessionPhase.inSection);
    s.pause();
    s.endSection();
    s.startNextSection();
    s.pause();
    expect(s.section.isListening, isTrue);
    s.endSection();
    expect(s.phase, SessionPhase.finished);
    s.dispose();
  });

  test('lưu và khôi phục bài làm dở', () {
    final s = ExamSession(exam);
    s.select(1);
    s.next();
    s.select(3);
    s.toggleFlag();
    s.remainingSec = 321;
    final json = s.toJson();
    final r = ExamSession.fromJson(exam, json);
    expect(r.index, 1);
    expect(r.remainingSec, 321);
    expect(r.answers, s.answers);
    expect(r.flagged, s.flagged);
    s.dispose();
    r.dispose();
  });

  test('định dạng đồng hồ', () {
    expect(formatClock(0), '00:00');
    expect(formatClock(1225), '20:25');
  });
}
