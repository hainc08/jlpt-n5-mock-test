import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/scoring.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'nav.dart';

class ExamListScreen extends StatelessWidget {
  const ExamListScreen({super.key});

  static Future<void> refresh(BuildContext context) async {
    final repo = AppScope.of(context).repo;
    final messenger = ScaffoldMessenger.of(context);
    final n = await repo.sync();
    messenger.showSnackBar(SnackBar(
      content: Text(n < 0
          ? 'Không kết nối được máy chủ đề. Đang dùng đề đã tải.'
          : (n == 0 ? 'Danh sách đề đã là mới nhất.' : 'Đã cập nhật $n đề.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn đề thi'),
        actions: [
          ListenableBuilder(
            listenable: services.repo,
            builder: (context, _) => services.repo.syncing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    tooltip: 'Kiểm tra đề mới',
                    onPressed: () => refresh(context),
                    icon: const Icon(Icons.refresh),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([services.storage, services.repo]),
        builder: (context, _) {
          final exams = services.repo.exams;
          final saved = services.storage.savedSession;
          final last = services.repo.lastSync;
          return RefreshIndicator(
            color: Zen.primary,
            onRefresh: () => refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text('Mỗi đề gồm 3 phần thi như kỳ thi thật: 文字・語彙 20 phút · 文法・読解 40 phút · 聴解 30 phút.',
                    style: Zen.small.copyWith(locale: Zen.jaLocale)),
                const SizedBox(height: 12),
                for (final e in exams) ...[
                  _ExamCard(
                    exam: e,
                    isNew: !services.repo.isBundled(e.id),
                    inProgress: saved != null && saved['examId'] == e.id,
                    onTap: () => saved != null && saved['examId'] == e.id ? Nav.resume(context) : Nav.openIntro(context, e.id),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                ZenCard(
                  color: Zen.subtle,
                  borderColor: Zen.subtle,
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.cloud_sync_outlined, color: Zen.ink2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đề mới được cập nhật tự động, không cần cập nhật app. Kéo xuống để kiểm tra ngay.'
                        '${last == null ? '' : '\nKiểm tra lần cuối: ${_fmt(last)}'}',
                        style: Zen.small,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.day}/${d.month}';
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.inProgress, required this.onTap, this.isNew = false});

  final ExamSummary exam;
  final bool isNew;
  final bool inProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    final best = storage.bestFor(exam.id);
    final Widget status;
    if (inProgress) {
      status = const Tag('Đang làm dở', color: Zen.amber);
    } else if (best == null) {
      status = isNew ? const Tag('Mới', color: Zen.amber, filled: true) : const Tag('Chưa làm', color: Zen.ink2);
    } else if (best.passed) {
      status = Tag('合格 · ${best.total}/${N5Rules.totalMax}', color: Zen.green);
    } else {
      status = Tag('不合格 · ${best.total}/${N5Rules.totalMax}', color: Zen.primary);
    }
    return ZenCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(exam.title, style: Zen.hMD)),
          status,
        ]),
        const SizedBox(height: 2),
        Text(exam.titleJa, style: Zen.ja(13, color: Zen.ink2, height: 1.4)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.schedule, size: 16, color: Zen.ink2),
          const SizedBox(width: 4),
          Text('${exam.minutes} phút', style: Zen.small),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, size: 16, color: Zen.ink2),
          const SizedBox(width: 4),
          Text('${exam.questions} câu', style: Zen.small),
          const Spacer(),
          Text(inProgress ? 'Tiếp tục' : (best == null ? 'Làm bài' : 'Làm lại'),
              style: Zen.label.copyWith(color: Zen.primary)),
          const Icon(Icons.chevron_right, color: Zen.primary, size: 20),
        ]),
      ]),
    );
  }
}
