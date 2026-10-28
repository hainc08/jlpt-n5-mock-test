import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/scoring.dart';
import '../logic/session.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'exam_room.dart';

/// Màn hướng dẫn trước giờ thi.
class ExamIntroScreen extends StatelessWidget {
  const ExamIntroScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn trước giờ thi')),
      body: FutureBuilder<Exam>(
        future: services.repo.load(examId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exam = snap.data!;
          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  Row(children: [
                    const N5Badge(),
                    const SizedBox(width: 8),
                    Text(exam.titleJa, style: Zen.ja(13, color: Zen.ink2, height: 1.3)),
                  ]),
                  const SizedBox(height: 6),
                  Text(exam.title, style: Zen.hXL),
                  const SizedBox(height: 4),
                  Text('${exam.totalQuestions} câu · ${exam.totalMinutes} phút · 3 phần thi', style: Zen.small),
                  const SectionTitle('Các phần thi'),
                  for (var i = 0; i < exam.sections.length; i++) ...[
                    _SectionRow(index: i, section: exam.sections[i]),
                    const SizedBox(height: 10),
                  ],
                  const SectionTitle('Cách tính điểm'),
                  ZenCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _rule('言語知識（文字・語彙・文法）・読解', '0–120 điểm · điểm liệt ${N5Rules.languageMin}'),
                      const SizedBox(height: 8),
                      _rule('聴解', '0–60 điểm · điểm liệt ${N5Rules.listeningMin}'),
                      const SizedBox(height: 8),
                      _rule('Tổng', 'Đỗ khi ≥ ${N5Rules.passTotal}/${N5Rules.totalMax} và không phần nào bị liệt'),
                      const SizedBox(height: 10),
                      Text(
                        'Điểm trong app được quy đổi theo tỉ lệ câu đúng để ước tính. Kỳ thi thật dùng thang điểm chuẩn hóa nên có thể chênh lệch.',
                        style: Zen.small,
                      ),
                    ]),
                  ),
                  const SectionTitle('Lưu ý'),
                  ZenCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _note(Icons.timer_outlined, 'Mỗi phần có đồng hồ riêng. Hết giờ, bài tự chuyển sang phần tiếp theo.'),
                      _note(Icons.flag_outlined, 'Có thể đánh dấu câu để xem lại và nhảy nhanh bằng lưới câu hỏi.'),
                      _note(Icons.headphones_outlined,
                          'Phần nghe dùng giọng đọc tiếng Nhật của máy, mỗi câu nghe tối đa 2 lần. Hãy bật âm lượng và thử âm thanh trước.'),
                      _note(Icons.pause_circle_outline, 'Thoát giữa chừng sẽ được lưu để làm tiếp sau.'),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => services.player.test(),
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('Thử âm thanh'),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Zen.surface,
                  border: Border(top: BorderSide(color: Zen.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await services.storage.clearSession();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ExamRoomScreen(session: ExamSession(exam))),
                      );
                    },
                    child: const Text('Bắt đầu làm bài'),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _rule(String a, String b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 5, child: Text(a, style: Zen.ja(13, weight: FontWeight.w700, height: 1.4))),
        const SizedBox(width: 8),
        Expanded(flex: 5, child: Text(b, style: Zen.small.copyWith(color: Zen.ink))),
      ]);

  Widget _note(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Zen.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Zen.body)),
        ]),
      );
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.index, required this.section});

  final int index;
  final Section section;

  @override
  Widget build(BuildContext context) {
    return ZenCard(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Zen.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Text('${index + 1}', style: Zen.hMD.copyWith(color: Zen.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section.titleJa, style: Zen.ja(15, weight: FontWeight.w700, height: 1.4)),
            Text(section.titleVi, style: Zen.small),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final m in section.mondai) Tag('${m.titleJa} ${m.questions.length}'),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${section.minutes}', style: Zen.hLG),
          Text('phút', style: Zen.small),
        ]),
      ]),
    );
  }
}
