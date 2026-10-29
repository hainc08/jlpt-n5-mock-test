import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một lần làm đề đã nộp.
class Attempt {
  final String examId;
  final String examTitle;
  final DateTime date;
  final Map<String, int> answers;
  final int durationSec;
  final int total;
  final int languageScore;
  final int listeningScore;
  final bool passed;

  Attempt({
    required this.examId,
    required this.examTitle,
    required this.date,
    required this.answers,
    required this.durationSec,
    required this.total,
    required this.languageScore,
    required this.listeningScore,
    required this.passed,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'examTitle': examTitle,
        'date': date.toIso8601String(),
        'answers': answers,
        'durationSec': durationSec,
        'total': total,
        'languageScore': languageScore,
        'listeningScore': listeningScore,
        'passed': passed,
      };

  factory Attempt.fromJson(Map<String, dynamic> j) => Attempt(
        examId: j['examId'] as String,
        examTitle: j['examTitle'] as String,
        date: DateTime.parse(j['date'] as String),
        answers: (j['answers'] as Map).map((k, v) => MapEntry(k as String, v as int)),
        durationSec: j['durationSec'] as int,
        total: j['total'] as int,
        languageScore: j['languageScore'] as int,
        listeningScore: j['listeningScore'] as int,
        passed: j['passed'] as bool,
      );
}

/// Lưu trữ cục bộ: lịch sử thi, sổ ôn tập, bài thi đang làm dở.
class Storage extends ChangeNotifier {
  Storage._(this._prefs);

  static const _kAttempts = 'attempts_v1';
  static const _kNotebook = 'notebook_v1';
  static const _kSession = 'session_v1';
  static const _kPractice = 'practice_v1';

  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  static Future<Storage> open() async => Storage._(await SharedPreferences.getInstance());

  // ---- Lịch sử thi ----
  List<Attempt> get attempts {
    final raw = _prefs.getStringList(_kAttempts) ?? const [];
    final list = <Attempt>[];
    for (final s in raw) {
      try {
        list.add(Attempt.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addAttempt(Attempt a) async {
    final raw = _prefs.getStringList(_kAttempts) ?? <String>[];
    raw.add(jsonEncode(a.toJson()));
    await _prefs.setStringList(_kAttempts, raw);
    notifyListeners();
  }

  Attempt? bestFor(String examId) {
    Attempt? best;
    for (final a in attempts) {
      if (a.examId == examId && (best == null || a.total > best.total)) best = a;
    }
    return best;
  }

  // ---- Sổ ôn tập (key = examId|questionId) ----
  Set<String> get notebook => (_prefs.getStringList(_kNotebook) ?? const []).toSet();

  bool inNotebook(String key) => notebook.contains(key);

  Future<void> toggleNotebook(String key) async {
    final set = notebook;
    if (!set.remove(key)) set.add(key);
    await _prefs.setStringList(_kNotebook, set.toList());
    notifyListeners();
  }

  // ---- Bài thi đang làm dở ----
  Map<String, dynamic>? get savedSession {
    final s = _prefs.getString(_kSession);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(Map<String, dynamic> json) async {
    await _prefs.setString(_kSession, jsonEncode(json));
    notifyListeners();
  }

  Future<void> clearSession() async {
    await _prefs.remove(_kSession);
    notifyListeners();
  }

  // ---- Thống kê luyện tập theo dạng bài: type -> [đúng, đã làm] ----
  Map<String, List<int>> get practiceStats {
    final s = _prefs.getString(_kPractice);
    if (s == null) return {};
    try {
      return (jsonDecode(s) as Map).map((k, v) => MapEntry(k as String, [for (final x in v as List) x as int]));
    } catch (_) {
      return {};
    }
  }

  Future<void> recordPractice(String type, bool correct) async {
    final stats = practiceStats;
    final cur = stats[type] ?? [0, 0];
    stats[type] = [cur[0] + (correct ? 1 : 0), cur[1] + 1];
    await _prefs.setString(_kPractice, jsonEncode(stats));
    notifyListeners();
  }
}
