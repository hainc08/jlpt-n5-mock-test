import 'dart:convert';

import 'package:flutter/services.dart';

import '../models.dart';

/// Đọc danh sách đề & nội dung đề từ assets (có cache).
class ExamRepository {
  ExamRepository({AssetBundle? bundle, this.level = 'n5'}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String level;
  List<ExamSummary>? _index;
  final Map<String, Exam> _cache = {};

  Future<List<ExamSummary>> index() async {
    if (_index != null) return _index!;
    final raw = await _bundle.loadString('assets/exams/$level/index.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    _index = [for (final e in j['exams'] as List) ExamSummary.fromJson(e as Map<String, dynamic>)];
    return _index!;
  }

  Future<Exam> load(String examId) async {
    final cached = _cache[examId];
    if (cached != null) return cached;
    final summary = (await index()).firstWhere((e) => e.id == examId);
    final raw = await _bundle.loadString(summary.file);
    final exam = Exam.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[examId] = exam;
    return exam;
  }

  Future<List<Exam>> loadAll() async => [for (final s in await index()) await load(s.id)];
}
