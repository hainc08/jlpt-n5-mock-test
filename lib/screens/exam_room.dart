import 'package:flutter/material.dart';

import '../app.dart';
import '../app_config.dart';
import '../logic/scoring.dart';
import '../logic/session.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/question_view.dart';
import 'result.dart';

/// Phòng thi: làm lần lượt 3 phần, mỗi phần có đồng hồ riêng.
class ExamRoomScreen extends StatefulWidget {
  const ExamRoomScreen({super.key, required this.session});

  final ExamSession session;

  @override
  State<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends State<ExamRoomScreen> with WidgetsBindingObserver {
  ExamSession get s => widget.session;
  late Services services;
  bool _finishing = false;
  String _lastSig = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    s.onTimeUp = _onTimeUp;
    s.addListener(_onChange);
    if (s.phase == SessionPhase.inSection) s.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    services = AppScope.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    s.removeListener(_onChange);
    services.player.stop();
    s.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) _save();
  }

  void _onChange() {
    // Lưu khi đáp án / vị trí / phần thi thay đổi (không lưu mỗi giây).
    final sig = '${s.phase.name}|${s.sectionIndex}|${s.index}|${s.answers.length}|${s.flagged.length}';
    if (sig != _lastSig) {
      if (_lastSig.isNotEmpty && sig.split('|')[2] != _lastSig.split('|')[2]) services.player.stop();
      _lastSig = sig;
      _save();
    }
    if (s.phase == SessionPhase.finished) _finish();
  }

  Future<void> _save() async {
    if (_finishing || s.phase == SessionPhase.finished) return;
    await services.storage.saveSession(s.toJson());
  }

  void _onTimeUp() {
    services.player.stop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hết giờ phần ${s.sectionIndex + 1}. Bài làm đã được lưu.')),
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    services.player.stop();
    final report = ScoreReport.compute(s.exam, s.answers);
    final attempt = Attempt(
      examId: s.exam.id,
      examTitle: s.exam.title,
      date: DateTime.now(),
      answers: Map.of(s.answers),
      durationSec: s.elapsedSec,
      total: report.total,
      languageScore: report.languageScore,
      listeningScore: report.listeningScore,
      passed: report.passed,
    );
    await services.storage.addAttempt(attempt);
    await services.storage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(exam: s.exam, attempt: attempt)),
    );
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạm dừng bài thi?'),
        content: const Text('Bài làm và thời gian còn lại sẽ được lưu. Bạn có thể làm tiếp từ Trang chủ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Làm tiếp')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu & thoát')),
        ],
      ),
    );
    if (leave == true) {
      s.pause();
      await _save();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmSubmitSection() async {
    final left = s.count - s.answeredInSection;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isLastSection ? 'Nộp bài thi?' : 'Nộp phần ${s.sectionIndex + 1}?'),
        content: Text(left > 0
            ? 'Bạn còn $left câu chưa trả lời. Sau khi nộp sẽ không quay lại phần này được.'
            : 'Sau khi nộp sẽ không quay lại phần này được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xem lại')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nộp')),
        ],
      ),
    );
    if (ok == true) {
      services.player.stop();
      s.endSection();
    }
  }

  void _openGrid() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Zen.surface,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: s,
        builder: (ctx, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phần ${s.sectionIndex + 1} · ${s.section.titleJa}', style: Zen.ja(15, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                _legend(Zen.subtle, 'Đã làm'),
                _legend(Zen.surface, 'Chưa làm', border: true),
                _legend(Zen.amber, 'Đánh dấu'),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < s.count; i++) _gridCell(ctx, i),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmSubmitSection();
                  },
                  child: Text(s.isLastSection ? 'Nộp bài thi' : 'Nộp phần này'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color c, String t, {bool border = false}) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(3),
              border: border ? Border.all(color: Zen.border) : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(t, style: Zen.small),
        ]),
      );

  Widget _gridCell(BuildContext ctx, int i) {
    final q = s.items[i].$2;
    final answered = s.answers.containsKey(q.id);
    final flagged = s.flagged.contains(q.id);
    final current = i == s.index;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        s.goTo(i);
        Navigator.pop(ctx);
      },
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: answered ? Zen.subtle : Zen.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: current ? Zen.primary : Zen.border, width: current ? 1.8 : 1),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Text('${q.no}', style: Zen.label.copyWith(color: current ? Zen.primary : Zen.ink)),
          if (flagged)
            const Positioned(
              right: -10,
              top: -8,
              child: Icon(Icons.flag, size: 12, color: Zen.amber),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && s.phase != SessionPhase.finished) _confirmExit();
      },
      child: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          if (s.phase == SessionPhase.sectionBreak) return _buildBreak();
          if (s.phase == SessionPhase.finished) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return _buildRoom();
        },
      ),
    );
  }

  Widget _buildRoom() {
    final q = s.question;
    final flagged = s.flagged.contains(q.id);
    final answeredRatio = s.count == 0 ? 0.0 : s.answeredInSection / s.count;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Phần ${s.sectionIndex + 1}: ${s.section.titleJa}',
              style: Zen.ja(15, weight: FontWeight.w700, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${s.exam.title} · JLPT ${AppConfig.level}', style: Zen.small, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu xem lại',
            onPressed: s.toggleFlag,
            icon: Icon(flagged ? Icons.flag : Icons.outlined_flag, color: flagged ? Zen.amber : Zen.ink2),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TimerPill(text: formatClock(s.remainingSec), warn: s.remainingSec <= 180),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            Row(children: [
              Text('Câu ${s.index + 1}/${s.count}', style: Zen.label),
              const Spacer(),
              Text('Đã làm ${s.answeredInSection}/${s.count}', style: Zen.small),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: answeredRatio,
                minHeight: 5,
                backgroundColor: Zen.border,
                color: Zen.primary,
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey('q-${q.id}'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: QuestionView(
              key: ValueKey(q.id),
              examId: s.exam.id,
              mondai: s.mondai,
              question: q,
              mode: QuestionMode.exam,
              selected: s.answers[q.id],
              onSelect: s.select,
            ),
          ),
        ),
        _bottomBar(),
      ]),
    );
  }

  Widget _bottomBar() {
    final last = s.index == s.count - 1;
    return Container(
      decoration: BoxDecoration(
        color: Zen.surface,
        border: const Border(top: BorderSide(color: Zen.border)),
        boxShadow: [BoxShadow(color: Zen.ink.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: s.index == 0 ? null : s.prev,
                child: const Text('← Trước'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _openGrid,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), padding: const EdgeInsets.symmetric(horizontal: 12)),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: Text('${s.index + 1}/${s.count}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: last ? _confirmSubmitSection : s.next,
                child: Text(last ? (s.isLastSection ? 'Nộp bài' : 'Nộp phần') : 'Tiếp →'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBreak() {
    final done = s.section;
    final next = s.exam.sections[s.sectionIndex + 1];
    final answered = done.questions.where((q) => s.answers.containsKey(q.id)).length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        title: Text(s.exam.title),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ZenCard(
          child: Column(children: [
            const Icon(Icons.check_circle_rounded, color: Zen.green, size: 56),
            const SizedBox(height: 12),
            Text('Hoàn thành Phần ${s.sectionIndex + 1}', style: Zen.hLG),
            const SizedBox(height: 4),
            Text(done.titleJa, style: Zen.ja(14, color: Zen.ink2)),
            const SizedBox(height: 12),
            Text('Đã trả lời $answered/${done.questions.length} câu', style: Zen.body),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Phần tiếp theo', style: Zen.labelSm),
        const SizedBox(height: 8),
        ZenCard(
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Zen.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text('${s.sectionIndex + 2}', style: Zen.hMD.copyWith(color: Zen.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(next.titleJa, style: Zen.ja(15, weight: FontWeight.w700, height: 1.4)),
                Text('${next.titleVi} · ${next.minutes} phút · ${next.questions.length} câu', style: Zen.small),
              ]),
            ),
          ]),
        ),
        if (next.isListening) ...[
          const SizedBox(height: 12),
          ZenCard(
            color: Zen.subtle,
            borderColor: Zen.subtle,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.headphones, color: Zen.ink),
              const SizedBox(width: 10),
              Expanded(child: Text('Hãy bật âm lượng hoặc đeo tai nghe trước khi bắt đầu.', style: Zen.body)),
              TextButton(onPressed: () => services.player.test(), child: const Text('Thử')),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: s.startNextSection,
          child: Text('Bắt đầu Phần ${s.sectionIndex + 2}'),
        ),
      ]),
    );
  }
}
