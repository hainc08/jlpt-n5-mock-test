import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../services/listening.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/question_view.dart';

/// Danh sách dạng bài để luyện riêng.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện theo dạng bài')),
      body: FutureBuilder<List<Exam>>(
        future: services.repo.loadAll(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final refs = [for (final e in snap.data!) ...e.refs];
          final byType = <String, List<QuestionRef>>{};
          for (final r in refs) {
            byType.putIfAbsent(r.mondai.type, () => []).add(r);
          }
          final groups = <String, List<String>>{};
          final groupTitle = <String, String>{};
          for (final t in mondaiTypeOrder) {
            final list = byType[t];
            if (list == null) continue;
            final s = list.first.section;
            groups.putIfAbsent(s.id, () => []).add(t);
            groupTitle[s.id] = s.titleJa;
          }
          return ListenableBuilder(
            listenable: services.storage,
            builder: (context, _) {
              final stats = services.storage.practiceStats;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text('Luyện từng dạng 問題 không giới hạn thời gian, xem đáp án và giải thích ngay sau mỗi câu.',
                      style: Zen.small.copyWith(locale: Zen.jaLocale)),
                  for (final g in groups.entries) ...[
                    SectionTitle(groupTitle[g.key]!),
                    for (final t in g.value) ...[
                      _TypeTile(
                        mondai: byType[t]!.first.mondai,
                        count: byType[t]!.length,
                        stat: stats[t],
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PracticeScreen(
                            title: '${byType[t]!.first.mondai.titleJa} · ${byType[t]!.first.mondai.titleVi}',
                            refs: byType[t]!,
                            shuffle: true,
                          ),
                        )),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.mondai, required this.count, required this.stat, required this.onTap});

  final Mondai mondai;
  final int count;
  final List<int>? stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = stat?[1] ?? 0;
    final correct = stat?[0] ?? 0;
    return ZenCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mondai.titleJa, style: Zen.ja(16, weight: FontWeight.w700, height: 1.3)),
            Text(mondai.titleVi, style: Zen.small),
            const SizedBox(height: 6),
            Text(
              done == 0 ? '$count câu · chưa luyện' : '$count câu · đã làm $done lượt · đúng ${(correct * 100 / done).round()}%',
              style: Zen.labelSm,
            ),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Zen.ink3),
      ]),
    );
  }
}

/// Luyện tập: chọn đáp án → hiện ngay đúng/sai và giải thích.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.title, required this.refs, this.shuffle = false});

  final String title;
  final List<QuestionRef> refs;
  final bool shuffle;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<QuestionRef> items;
  final Map<String, int> picked = {};
  int index = 0;

  @override
  void initState() {
    super.initState();
    items = List.of(widget.refs);
    if (widget.shuffle) items.shuffle(Random());
  }

  late ListeningPlayer _player;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _player = AppScope.of(context).player;
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  int get correct => items.where((r) => picked[r.key] == r.question.answer).length;

  void _pick(QuestionRef r, int i) {
    if (picked.containsKey(r.key)) return;
    setState(() => picked[r.key] = i);
    AppScope.of(context).storage.recordPractice(r.mondai.type, i == r.question.answer);
  }

  void _go(int i) {
    _player.stop();
    setState(() => index = i);
  }

  Future<void> _finish() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành'),
        content: Text('Bạn trả lời đúng $correct/${items.length} câu.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = items[index];
    final sel = picked[r.key];
    final last = index == items.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: Zen.ja(16, weight: FontWeight.w700, height: 1.3)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Tag('✓ $correct', color: Zen.green)),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            Text('Câu ${index + 1}/${items.length}', style: Zen.label),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (index + 1) / items.length,
                  minHeight: 5,
                  backgroundColor: Zen.border,
                  color: Zen.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(r.exam.title.replaceAll('Đề chuẩn số ', 'Đề '), style: Zen.small),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey('p-${r.key}'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: QuestionView(
              key: ValueKey('pv-${r.key}'),
              examId: r.exam.id,
              mondai: r.mondai,
              question: r.question,
              mode: QuestionMode.practice,
              selected: sel,
              onSelect: (i) => _pick(r, i),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(color: Zen.surface, border: Border(top: BorderSide(color: Zen.border))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: index == 0 ? null : () => _go(index - 1),
                    child: const Text('← Trước'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: last ? _finish : () => _go(index + 1),
                    child: Text(last ? 'Hoàn thành' : (sel == null ? 'Bỏ qua →' : 'Câu tiếp →')),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
