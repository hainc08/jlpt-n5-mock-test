import 'package:flutter/material.dart';

import '../app.dart';
import '../app_config.dart';
import '../logic/scoring.dart';
import '../models.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'history.dart';
import 'nav.dart';
import 'settings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onTab});

  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return SafeArea(
      child: Builder(
        builder: (context) {
          return ListenableBuilder(
            listenable: Listenable.merge([services.storage, services.repo]),
            builder: (context, _) {
              final exams = services.repo.exams;
              final storage = services.storage;
              final attempts = storage.attempts;
              final saved = storage.savedSession;
              final done = attempts.map((a) => a.examId).toSet();
              final nextExam = exams.where((e) => !done.contains(e.id)).firstOrNull ?? exams.firstOrNull;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('こんにちは！', style: Zen.ja(14, color: Zen.ink2, height: 1.3)),
                        const SizedBox(height: 2),
                        Text('Thi thử JLPT ${AppConfig.level}', style: Zen.hXL),
                      ]),
                    ),
                    const N5Badge(),
                    IconButton(
                      tooltip: 'Cài đặt',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      icon: const Icon(Icons.settings_outlined, color: Zen.ink2),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('Đề chuẩn cấu trúc kỳ thi thật · chấm điểm · giải thích tiếng Việt', style: Zen.small),
                  const SizedBox(height: 18),
                  if (saved != null) ...[
                    ZenCard(
                      borderColor: Zen.amber.withValues(alpha: 0.5),
                      onTap: () => Nav.resume(context),
                      child: Row(children: [
                        const Icon(Icons.play_circle_fill, color: Zen.amber, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Bài thi đang làm dở', style: Zen.label),
                            Text('${saved['examTitle']} · Phần ${(saved['sectionIndex'] as int) + 1}/3', style: Zen.small),
                          ]),
                        ),
                        const Text('Tiếp tục', style: TextStyle(color: Zen.amber, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _HeroCard(
                    exam: nextExam,
                    onStart: nextExam == null ? null : () => Nav.openIntro(context, nextExam.id),
                  ),
                  if (attempts.isNotEmpty) ...[
                    SectionTitle('Kết quả gần nhất',
                        trailing: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                          child: const Text('Lịch sử'),
                        )),
                    _LastResult(attempt: attempts.first),
                  ],
                  const SectionTitle('Luyện tập'),
                  Row(children: [
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.category_outlined,
                        title: 'Theo dạng bài',
                        subtitle: '14 dạng 問題',
                        onTap: () => onTab(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.bookmark_outline,
                        title: 'Sổ ôn tập',
                        subtitle: '${storage.notebook.length} câu đã lưu',
                        onTap: () => onTab(3),
                      ),
                    ),
                  ]),
                  SectionTitle('Cấu trúc đề thi ${AppConfig.level}'),
                  const _StructureCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.exam, required this.onStart});

  final ExamSummary? exam;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Zen.surface,
        borderRadius: BorderRadius.circular(Zen.radiusCard),
        border: Border.all(color: Zen.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Zen.primary, borderRadius: BorderRadius.circular(14)),
            child: Text('試', style: Zen.ja(26, weight: FontWeight.w700, color: Colors.white, height: 1.1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam?.title ?? 'Đề thi thử', style: Zen.hMD),
              Text(exam?.titleJa ?? '', style: Zen.ja(13, color: Zen.ink2, height: 1.4)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _Stat(value: '3', label: 'phần thi'),
          _Stat(value: '${exam?.minutes ?? 90}', label: 'phút'),
          _Stat(value: '${exam?.questions ?? 67}', label: 'câu hỏi'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Bắt đầu thi thử'),
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: Zen.hLG.copyWith(color: Zen.primary)),
          Text(label, style: Zen.small),
        ]),
      );
}

class _LastResult extends StatelessWidget {
  const _LastResult({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final a = attempt;
    return ZenCard(
      onTap: () => Nav.openResult(context, a),
      child: Row(children: [
        PassStamp(passed: a.passed, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.examTitle, style: Zen.label),
            const SizedBox(height: 4),
            Text('${a.total}/${N5Rules.totalMax} điểm', style: Zen.hMD),
            Text('言語知識・読解 ${a.languageScore} · 聴解 ${a.listeningScore}', style: Zen.small.copyWith(locale: Zen.jaLocale)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Zen.ink3),
      ]),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ZenCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Zen.primary),
          const SizedBox(height: 10),
          Text(title, style: Zen.label),
          const SizedBox(height: 2),
          Text(subtitle, style: Zen.small),
        ]),
      );
}

class _StructureCard extends StatelessWidget {
  const _StructureCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('言語知識（文字・語彙）', '20 phút', '漢字読み · 表記 · 文脈規定 · 言い換え類義'),
      ('言語知識（文法）・読解', '40 phút', '文法形式 · 文の組み立て · 文章の文法 · 短文 · 中文 · 情報検索'),
      ('聴解', '30 phút', '課題理解 · ポイント理解 · 発話表現 · 即時応答'),
    ];
    return ZenCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Zen.subtle, borderRadius: BorderRadius.circular(8)),
              child: Text('${i + 1}', style: Zen.label),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(rows[i].$1, style: Zen.ja(14, weight: FontWeight.w700, height: 1.4))),
                  Text(rows[i].$2, style: Zen.labelSm),
                ]),
                const SizedBox(height: 4),
                Text(rows[i].$3, style: Zen.ja(12, weight: FontWeight.w400, color: Zen.ink2, height: 1.5)),
              ]),
            ),
          ]),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        Text(
          'Đỗ khi tổng ≥ ${N5Rules.passTotal}/${N5Rules.totalMax} và không phần nào dưới điểm liệt '
          '(言語知識・読解 ${N5Rules.languageMin}/120 · 聴解 ${N5Rules.listeningMin}/60).',
          style: Zen.small.copyWith(locale: Zen.jaLocale),
        ),
      ]),
    );
  }
}
