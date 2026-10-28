import 'package:flutter/material.dart';

import '../logic/scoring.dart';
import '../logic/session.dart';
import '../models.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'exam_intro.dart';
import 'review.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.exam, required this.attempt});

  final Exam exam;
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final r = ScoreReport.compute(exam, attempt.answers);
    final d = attempt.date;
    final dateText = '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Text('Kết quả · ${exam.title}'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        ZenCard(
          child: Column(children: [
            PassStamp(passed: r.passed, size: 104),
            const SizedBox(height: 12),
            Text(r.passed ? 'Chúc mừng! Bạn đã đỗ' : 'Chưa đạt — cố lên nhé!', style: Zen.hMD),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '${r.total}', style: Zen.hXL.copyWith(fontSize: 44, color: r.passed ? Zen.green : Zen.primary)),
                TextSpan(text: ' / ${N5Rules.totalMax}', style: Zen.hMD.copyWith(color: Zen.ink2)),
              ]),
            ),
            Text('Điểm đỗ ${N5Rules.passTotal} · Đúng ${r.correct}/${r.questions} câu', style: Zen.small),
            const SizedBox(height: 4),
            Text('$dateText · ${formatClock(attempt.durationSec).replaceFirst(':', ' phút ')} giây', style: Zen.small),
            if (!r.passed) ...[
              const SizedBox(height: 12),
              for (final reason in r.failReasons)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.info_outline, size: 16, color: Zen.primary),
                    const SizedBox(width: 6),
                    Flexible(child: Text(reason, style: Zen.small.copyWith(color: Zen.primary, locale: Zen.jaLocale))),
                  ]),
                ),
            ],
          ]),
        ),
        const SectionTitle('Điểm theo phần'),
        ZenCard(
          child: Column(children: [
            _ScoreBar(
              title: '言語知識（文字・語彙・文法）・読解',
              score: r.languageScore,
              max: N5Rules.languageMax,
              min: N5Rules.languageMin,
              detail: 'Đúng ${r.languageCorrect}/${r.languageTotal} câu',
            ),
            const SizedBox(height: 20),
            _ScoreBar(
              title: '聴解',
              score: r.listeningScore,
              max: N5Rules.listeningMax,
              min: N5Rules.listeningMin,
              detail: 'Đúng ${r.listeningCorrect}/${r.listeningTotal} câu',
            ),
            const SizedBox(height: 14),
            Text('Điểm quy đổi ước tính theo tỉ lệ câu đúng.', style: Zen.small),
          ]),
        ),
        const SectionTitle('Chi tiết từng dạng bài'),
        for (final section in exam.sections) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(section.titleJa, style: Zen.ja(13, weight: FontWeight.w700, color: Zen.ink2, height: 1.3)),
          ),
          ZenCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: [
              for (final m in r.mondai.where((e) => e.section == section)) _MondaiRow(score: m),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReviewScreen(exam: exam, answers: attempt.answers),
          )),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Xem lại đáp án'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ExamIntroScreen(examId: exam.id)),
          ),
          icon: const Icon(Icons.replay),
          label: const Text('Làm lại đề'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Về trang chủ'),
        ),
      ]),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.title, required this.score, required this.max, required this.min, required this.detail});

  final String title;
  final int score;
  final int max;
  final int min;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ok = score >= min;
    final color = ok ? Zen.green : Zen.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(title, style: Zen.ja(14, weight: FontWeight.w700, height: 1.4))),
        Text('$score', style: Zen.hLG.copyWith(color: color)),
        Text(' / $max', style: Zen.small),
      ]),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 30,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(height: 10, decoration: BoxDecoration(color: Zen.subtle, borderRadius: BorderRadius.circular(5))),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: w * (score / max).clamp(0.0, 1.0),
                height: 10,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
              ),
            ),
            Positioned(
              left: w * min / max - 1,
              top: -3,
              child: Container(width: 2, height: 16, color: Zen.ink),
            ),
            Positioned(
              left: (w * min / max - 30).clamp(0.0, w - 60),
              top: 15,
              child: SizedBox(
                width: 60,
                child: Text('liệt $min', textAlign: TextAlign.center, style: Zen.labelSm.copyWith(color: Zen.ink)),
              ),
            ),
          ]),
        );
      }),
      Text(detail, style: Zen.small),
    ]);
  }
}

class _MondaiRow extends StatelessWidget {
  const _MondaiRow({required this.score});

  final MondaiScore score;

  @override
  Widget build(BuildContext context) {
    final ratio = score.total == 0 ? 0.0 : score.correct / score.total;
    final color = ratio >= 0.7 ? Zen.green : (ratio >= 0.4 ? Zen.amber : Zen.primary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(
          width: 150,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${score.mondai.label} ${score.mondai.titleJa}', style: Zen.ja(13, weight: FontWeight.w600, height: 1.3)),
            Text(score.mondai.titleVi, style: Zen.small.copyWith(fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: Zen.subtle, color: color),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text('${score.correct}/${score.total}', textAlign: TextAlign.right, style: Zen.label),
        ),
      ]),
    );
  }
}
