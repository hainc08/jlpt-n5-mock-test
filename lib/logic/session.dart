import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';

enum SessionPhase { inSection, sectionBreak, finished }

/// Trạng thái một lần thi: phần thi hiện tại, đồng hồ, đáp án, câu đánh dấu.
class ExamSession extends ChangeNotifier {
  ExamSession(this.exam, {DateTime? startedAt}) : startedAt = startedAt ?? DateTime.now() {
    remainingSec = section.minutes * 60;
  }

  final Exam exam;
  final DateTime startedAt;

  int sectionIndex = 0;
  int index = 0;
  int remainingSec = 0;
  SessionPhase phase = SessionPhase.inSection;
  final Map<String, int> answers = {};
  final Set<String> flagged = {};

  /// Được gọi khi hết giờ một phần thi.
  VoidCallback? onTimeUp;

  Timer? _timer;

  Section get section => exam.sections[sectionIndex];
  bool get isLastSection => sectionIndex == exam.sections.length - 1;

  late List<(Mondai, Question)> _items = _buildItems();

  List<(Mondai, Question)> _buildItems() => [
        for (final m in section.mondai)
          for (final q in m.questions) (m, q)
      ];

  List<(Mondai, Question)> get items => _items;
  Mondai get mondai => _items[index].$1;
  Question get question => _items[index].$2;
  int get count => _items.length;
  int get answeredInSection => _items.where((e) => answers.containsKey(e.$2.id)).length;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() => _timer?.cancel();

  void _tick() {
    if (phase != SessionPhase.inSection) return;
    if (remainingSec > 0) {
      remainingSec--;
      notifyListeners();
    }
    if (remainingSec <= 0) {
      _timer?.cancel();
      endSection();
      onTimeUp?.call();
    }
  }

  void select(int option) {
    answers[question.id] = option;
    notifyListeners();
  }

  void toggleFlag() {
    final id = question.id;
    if (!flagged.remove(id)) flagged.add(id);
    notifyListeners();
  }

  void goTo(int i) {
    if (i < 0 || i >= count) return;
    index = i;
    notifyListeners();
  }

  void next() => goTo(index + 1);
  void prev() => goTo(index - 1);

  /// Kết thúc phần hiện tại (nộp sớm hoặc hết giờ).
  void endSection() {
    _timer?.cancel();
    phase = isLastSection ? SessionPhase.finished : SessionPhase.sectionBreak;
    notifyListeners();
  }

  /// Bắt đầu phần thi kế tiếp sau màn nghỉ.
  void startNextSection() {
    if (isLastSection) return;
    sectionIndex++;
    index = 0;
    _items = _buildItems();
    remainingSec = section.minutes * 60;
    phase = SessionPhase.inSection;
    start();
    notifyListeners();
  }

  int get elapsedSec => DateTime.now().difference(startedAt).inSeconds;

  Map<String, dynamic> toJson() => {
        'examId': exam.id,
        'examTitle': exam.title,
        'startedAt': startedAt.toIso8601String(),
        'sectionIndex': sectionIndex,
        'index': index,
        'remainingSec': remainingSec,
        'phase': phase.name,
        'answers': answers,
        'flagged': flagged.toList(),
      };

  factory ExamSession.fromJson(Exam exam, Map<String, dynamic> j) {
    final s = ExamSession(exam, startedAt: DateTime.tryParse(j['startedAt'] as String? ?? ''));
    s.sectionIndex = (j['sectionIndex'] as int).clamp(0, exam.sections.length - 1);
    s._items = s._buildItems();
    s.index = (j['index'] as int).clamp(0, s._items.length - 1);
    s.remainingSec = j['remainingSec'] as int;
    s.phase = SessionPhase.values.firstWhere((p) => p.name == j['phase'], orElse: () => SessionPhase.inSection);
    s.answers.addAll((j['answers'] as Map).map((k, v) => MapEntry(k as String, v as int)));
    s.flagged.addAll([for (final f in j['flagged'] as List) f as String]);
    return s;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

String formatClock(int sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
