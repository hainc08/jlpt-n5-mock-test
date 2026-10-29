import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'practice.dart';

/// Sổ ôn tập: các câu đã lưu để luyện lại.
class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ ôn tập')),
      body: ListenableBuilder(
        listenable: services.repo,
        builder: (context, _) => FutureBuilder<List<Exam>>(
          future: services.repo.loadAll(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final all = [for (final e in snap.data!) ...e.refs];
            return ListenableBuilder(
              listenable: services.storage,
              builder: (context, _) {
                final keys = services.storage.notebook;
                final saved = all.where((r) => keys.contains(r.key)).toList();
                if (saved.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_border, size: 48, color: Zen.ink3),
                          const SizedBox(height: 12),
                          Text('Chưa có câu nào', style: Zen.hMD),
                          const SizedBox(height: 6),
                          Text(
                            'Khi xem lại đáp án hoặc luyện tập, nhấn "Thêm vào sổ ôn tập" để lưu câu cần ôn.',
                            style: Zen.small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PracticeScreen(title: 'Ôn tập sổ tay', refs: saved, shuffle: true),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Luyện lại ${saved.length} câu'),
                    ),
                    const SizedBox(height: 16),
                    for (final r in saved) ...[
                      _SavedTile(
                        refItem: r,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PracticeScreen(title: r.mondai.titleJa, refs: [r]),
                          ),
                        ),
                        onRemove: () => services.storage.toggleNotebook(r.key),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.refItem, required this.onOpen, required this.onRemove});

  final QuestionRef refItem;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final q = refItem.question;
    final preview = q.prompt.isNotEmpty
        ? q.prompt.replaceAll(RegExp(r'[{}]'), '').replaceAll('\n', ' ')
        : (q.script.isNotEmpty ? q.script.first.text : '');
    return ZenCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${refItem.exam.title} · ${refItem.mondai.titleJa} · Câu ${q.no}',
                  style: Zen.labelSm.copyWith(locale: Zen.jaLocale),
                ),
                const SizedBox(height: 4),
                Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: Zen.ja(15, height: 1.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bỏ khỏi sổ',
            onPressed: onRemove,
            icon: const Icon(Icons.bookmark_remove_outlined, color: Zen.ink2),
          ),
        ],
      ),
    );
  }
}
