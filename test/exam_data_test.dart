import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_mock_test/logic/scoring.dart';
import 'package:jlpt_mock_test/models.dart';

/// Số câu chuẩn của từng dạng bài N5.
const n5Counts = {
  'kanji_yomi': 7, 'hyouki': 5, 'bunmyaku': 6, 'iikae': 3,
  'bunpou_keishiki': 9, 'narabekae': 4, 'bunshou': 4,
  'tanbun': 2, 'chuubun': 2, 'jouhou': 1,
  'kadai': 7, 'point': 6, 'hatsuwa': 5, 'sokuji': 6,
};

List<Exam> loadExams() {
  final index = jsonDecode(File('assets/exams/n5/index.json').readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final e in index['exams'] as List)
      Exam.fromJson(jsonDecode(File((e as Map)['file'] as String).readAsStringSync()) as Map<String, dynamic>)
  ];
}

void main() {
  final exams = loadExams();

  test('có ít nhất 2 đề N5', () {
    expect(exams.length, greaterThanOrEqualTo(2));
  });

  for (final exam in exams) {
    group(exam.id, () {
      test('đúng cấu trúc 3 phần 20/40/30 phút', () {
        expect(exam.sections.map((s) => s.minutes), [20, 40, 30]);
        expect(exam.sections.last.isListening, isTrue);
      });

      test('đủ số câu từng dạng bài', () {
        final counts = <String, int>{};
        for (final r in exam.refs) {
          counts[r.mondai.type] = (counts[r.mondai.type] ?? 0) + 1;
        }
        expect(counts, n5Counts);
      });

      test('đáp án hợp lệ, id không trùng, có giải thích', () {
        final ids = <String>{};
        for (final r in exam.refs) {
          final q = r.question;
          expect(ids.add(q.id), isTrue, reason: 'trùng id ${q.id}');
          expect(q.answer, inInclusiveRange(0, q.options.length - 1));
          expect(q.explanation.trim(), isNotEmpty);
          expect(q.options.toSet().length, q.options.length, reason: 'trùng lựa chọn ${q.id}');
          if (r.section.isListening) expect(q.script, isNotEmpty, reason: q.id);
          if (q.isOrdering) {
            expect(q.order!.toList()..sort(), [0, 1, 2, 3]);
            expect(q.order![q.star!], q.answer);
          }
        }
      });

      test('chấm điểm: đúng hết = 180 đỗ, bỏ trống = 0 trượt', () {
        final all = {for (final r in exam.refs) r.question.id: r.question.answer};
        final full = ScoreReport.compute(exam, all);
        expect(full.total, 180);
        expect(full.passed, isTrue);
        final empty = ScoreReport.compute(exam, {});
        expect(empty.total, 0);
        expect(empty.passed, isFalse);
      });
    });
  }

  test('trượt vì điểm liệt nghe dù tổng điểm cao', () {
    final exam = exams.first;
    final answers = <String, int>{
      for (final r in exam.refs)
        if (!r.section.isListening) r.question.id: r.question.answer,
    };
    final report = ScoreReport.compute(exam, answers);
    expect(report.languageScore, 120);
    expect(report.listeningScore, 0);
    expect(report.total, 120);
    expect(report.passed, isFalse);
    expect(report.failReasons.length, 1);
  });
}
