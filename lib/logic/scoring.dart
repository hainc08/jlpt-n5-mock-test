import '../models.dart';

/// Quy tắc đậu JLPT N5: tổng ≥ 80/180, 言語知識・読解 ≥ 38/120, 聴解 ≥ 19/60.
class N5Rules {
  static const languageMax = 120;
  static const listeningMax = 60;
  static const totalMax = 180;
  static const passTotal = 80;
  static const languageMin = 38;
  static const listeningMin = 19;
}

class MondaiScore {
  final Section section;
  final Mondai mondai;
  final int correct;
  final int total;

  const MondaiScore(this.section, this.mondai, this.correct, this.total);
}

/// Kết quả một lần thi. Điểm quy đổi là ƯỚC TÍNH theo tỉ lệ câu đúng —
/// JLPT thật dùng thang điểm chuẩn hóa (scaled score).
class ScoreReport {
  final int languageCorrect;
  final int languageTotal;
  final int listeningCorrect;
  final int listeningTotal;
  final List<MondaiScore> mondai;

  const ScoreReport({
    required this.languageCorrect,
    required this.languageTotal,
    required this.listeningCorrect,
    required this.listeningTotal,
    required this.mondai,
  });

  factory ScoreReport.compute(Exam exam, Map<String, int> answers) {
    var lc = 0, lt = 0, sc = 0, st = 0;
    final rows = <MondaiScore>[];
    for (final s in exam.sections) {
      for (final m in s.mondai) {
        var c = 0;
        for (final q in m.questions) {
          if (answers[q.id] == q.answer) c++;
        }
        rows.add(MondaiScore(s, m, c, m.questions.length));
        if (s.isListening) {
          sc += c;
          st += m.questions.length;
        } else {
          lc += c;
          lt += m.questions.length;
        }
      }
    }
    return ScoreReport(
      languageCorrect: lc,
      languageTotal: lt,
      listeningCorrect: sc,
      listeningTotal: st,
      mondai: rows,
    );
  }

  static int _scale(int correct, int total, int max) => total == 0 ? 0 : (correct * max / total).round();

  int get languageScore => _scale(languageCorrect, languageTotal, N5Rules.languageMax);
  int get listeningScore => _scale(listeningCorrect, listeningTotal, N5Rules.listeningMax);
  int get total => languageScore + listeningScore;
  int get correct => languageCorrect + listeningCorrect;
  int get questions => languageTotal + listeningTotal;

  bool get languageOk => languageScore >= N5Rules.languageMin;
  bool get listeningOk => listeningScore >= N5Rules.listeningMin;
  bool get passed => total >= N5Rules.passTotal && languageOk && listeningOk;

  /// Lý do trượt (nếu có), tiếng Việt.
  List<String> get failReasons => [
        if (total < N5Rules.passTotal) 'Tổng điểm dưới ${N5Rules.passTotal}/${N5Rules.totalMax}',
        if (!languageOk) '言語知識・読解 dưới điểm liệt ${N5Rules.languageMin}',
        if (!listeningOk) '聴解 dưới điểm liệt ${N5Rules.listeningMin}',
      ];
}
