/// Mô hình dữ liệu đề thi (đọc từ `assets/exams/<level>/*.json`).
library;

class ExamSummary {
  final String id;
  final String title;
  final String titleJa;
  final String file;
  final int questions;
  final int minutes;

  const ExamSummary({
    required this.id,
    required this.title,
    required this.titleJa,
    required this.file,
    required this.questions,
    required this.minutes,
  });

  factory ExamSummary.fromJson(Map<String, dynamic> j) => ExamSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        titleJa: j['titleJa'] as String,
        file: j['file'] as String,
        questions: j['questions'] as int,
        minutes: j['minutes'] as int,
      );
}

class Exam {
  final String id;
  final String level;
  final String title;
  final String titleJa;
  final List<Section> sections;

  Exam({required this.id, required this.level, required this.title, required this.titleJa, required this.sections});

  factory Exam.fromJson(Map<String, dynamic> j) {
    final exam = Exam(
      id: j['id'] as String,
      level: j['level'] as String,
      title: j['title'] as String,
      titleJa: j['titleJa'] as String,
      sections: [for (final s in j['sections'] as List) Section.fromJson(s as Map<String, dynamic>)],
    );
    return exam;
  }

  int get totalMinutes => sections.fold(0, (a, s) => a + s.minutes);
  int get totalQuestions => sections.fold(0, (a, s) => a + s.questions.length);

  /// Tất cả câu hỏi kèm ngữ cảnh (phần thi, mondai).
  Iterable<QuestionRef> get refs sync* {
    for (final s in sections) {
      for (final m in s.mondai) {
        for (final q in m.questions) {
          yield QuestionRef(this, s, m, q);
        }
      }
    }
  }

  QuestionRef? find(String questionId) {
    for (final r in refs) {
      if (r.question.id == questionId) return r;
    }
    return null;
  }
}

class Section {
  final String id;
  final String titleJa;
  final String titleVi;
  final int minutes;

  /// 'language' (言語知識・読解, 0–120) hoặc 'listening' (聴解, 0–60).
  final String scoreGroup;
  final List<Mondai> mondai;

  Section({
    required this.id,
    required this.titleJa,
    required this.titleVi,
    required this.minutes,
    required this.scoreGroup,
    required this.mondai,
  });

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: j['id'] as String,
        titleJa: j['titleJa'] as String,
        titleVi: j['titleVi'] as String,
        minutes: j['minutes'] as int,
        scoreGroup: j['scoreGroup'] as String,
        mondai: [for (final m in j['mondai'] as List) Mondai.fromJson(m as Map<String, dynamic>)],
      );

  bool get isListening => scoreGroup == 'listening';

  List<Question> get questions => [for (final m in mondai) ...m.questions];
}

class Mondai {
  final String id;
  final String label;
  final String type;
  final String titleJa;
  final String titleVi;
  final String instructionJa;
  final String instructionVi;
  final String? passage;
  final InfoTable? table;
  final List<Question> questions;

  Mondai({
    required this.id,
    required this.label,
    required this.type,
    required this.titleJa,
    required this.titleVi,
    required this.instructionJa,
    required this.instructionVi,
    required this.questions,
    this.passage,
    this.table,
  });

  factory Mondai.fromJson(Map<String, dynamic> j) => Mondai(
        id: j['id'] as String,
        label: j['label'] as String,
        type: j['type'] as String,
        titleJa: j['titleJa'] as String,
        titleVi: j['titleVi'] as String,
        instructionJa: j['instructionJa'] as String,
        instructionVi: j['instructionVi'] as String,
        passage: j['passage'] as String?,
        table: j['table'] == null ? null : InfoTable.fromJson(j['table'] as Map<String, dynamic>),
        questions: [for (final q in j['questions'] as List) Question.fromJson(q as Map<String, dynamic>)],
      );
}

class InfoTable {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  InfoTable({required this.title, required this.headers, required this.rows});

  factory InfoTable.fromJson(Map<String, dynamic> j) => InfoTable(
        title: j['title'] as String,
        headers: [for (final h in j['headers'] as List) h as String],
        rows: [
          for (final r in j['rows'] as List) [for (final c in r as List) c as String]
        ],
      );
}

class ScriptLine {
  /// N = người dẫn, M = nam, F = nữ.
  final String speaker;
  final String text;

  const ScriptLine(this.speaker, this.text);

  String get speakerLabel => switch (speaker) {
        'M' => '男',
        'F' => '女',
        _ => 'ナレーター',
      };
}

class Question {
  final String id;
  final int no;
  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;
  final List<ScriptLine> script;
  final String? scene;
  final String? passage;
  final InfoTable? table;
  final bool audioOptions;

  /// Chỉ dùng cho dạng 文の組み立て.
  final List<int>? order;
  final int? star;

  Question({
    required this.id,
    required this.no,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.script = const [],
    this.scene,
    this.passage,
    this.table,
    this.audioOptions = false,
    this.order,
    this.star,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        no: j['no'] as int,
        prompt: j['prompt'] as String,
        options: [for (final o in j['options'] as List) o as String],
        answer: j['answer'] as int,
        explanation: j['explanation'] as String,
        script: [
          for (final l in (j['script'] as List?) ?? const [])
            ScriptLine((l as List)[0] as String, l[1] as String)
        ],
        scene: j['scene'] as String?,
        passage: j['passage'] as String?,
        table: j['table'] == null ? null : InfoTable.fromJson(j['table'] as Map<String, dynamic>),
        audioOptions: (j['audioOptions'] as bool?) ?? false,
        order: (j['order'] as List?)?.map((e) => e as int).toList(),
        star: j['star'] as int?,
      );

  bool get isListening => script.isNotEmpty;
  bool get isOrdering => order != null;
}

/// Câu hỏi kèm ngữ cảnh đầy đủ.
class QuestionRef {
  final Exam exam;
  final Section section;
  final Mondai mondai;
  final Question question;

  const QuestionRef(this.exam, this.section, this.mondai, this.question);

  String get key => '${exam.id}|${question.id}';
}

/// Tên dạng bài cho màn luyện tập.
const mondaiTypeOrder = [
  'kanji_yomi', 'hyouki', 'bunmyaku', 'iikae',
  'bunpou_keishiki', 'narabekae', 'bunshou',
  'tanbun', 'chuubun', 'jouhou',
  'kadai', 'point', 'hatsuwa', 'sokuji',
];
