import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

enum QuestionMode { exam, practice, review }

/// Hiển thị một câu hỏi (dùng chung cho phòng thi, luyện tập, xem lại).
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.examId,
    required this.mondai,
    required this.question,
    required this.mode,
    this.selected,
    this.onSelect,
    this.showHeader = true,
  });

  final String examId;
  final Mondai mondai;
  final Question question;
  final QuestionMode mode;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final bool showHeader;

  bool get _reveal => mode == QuestionMode.review || (mode == QuestionMode.practice && selected != null);

  OptionState _stateFor(int i) {
    if (!_reveal) return selected == i ? OptionState.selected : OptionState.normal;
    if (i == question.answer) return OptionState.correct;
    if (i == selected) return OptionState.wrong;
    return OptionState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final q = question;
    final table = q.table ?? mondai.table;
    final canTap = onSelect != null && !(mode == QuestionMode.practice && selected != null) && mode != QuestionMode.review;
    final hidePrompt = q.isListening && mode == QuestionMode.exam;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (showHeader) ...[MondaiHeader(mondai), const SizedBox(height: 16)],
      if (mondai.passage != null) ...[PassageView(mondai.passage!), const SizedBox(height: 16)],
      if (q.passage != null) ...[PassageView(q.passage!), const SizedBox(height: 16)],
      if (table != null) ...[InfoTableView(table), const SizedBox(height: 16)],
      if (q.scene != null) ...[_SceneCard(scene: q.scene!), const SizedBox(height: 12)],
      if (q.isListening) ...[
        AudioBar(
          playKey: '$examId|${q.id}|${mode.name}',
          script: q.script,
          readOptions: q.audioOptions ? q.options : null,
          maxPlays: mode == QuestionMode.exam ? 2 : null,
        ),
        const SizedBox(height: 12),
      ],
      ZenCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Câu ${q.no}', style: Zen.labelSm),
          const SizedBox(height: 6),
          if (hidePrompt)
            Text(
              q.audioOptions ? 'Nghe và chọn câu trả lời phù hợp.' : 'Câu hỏi được đọc trong bài nghe.',
              style: Zen.body.copyWith(color: Zen.ink2),
            )
          else if (q.prompt.isNotEmpty)
            JpText(q.prompt)
          else
            Text('Nghe câu nói và chọn câu đáp lại.', style: Zen.body.copyWith(color: Zen.ink2)),
        ]),
      ),
      if (q.isOrdering && mode != QuestionMode.review) ...[
        const SizedBox(height: 12),
        _OrderingBoard(key: ValueKey('board-${q.id}'), question: q, onStar: canTap ? onSelect : null),
      ],
      const SizedBox(height: 14),
      if (q.isOrdering)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text('Chọn thành phần ở vị trí ★', style: Zen.labelSm),
        ),
      for (var i = 0; i < q.options.length; i++)
        OptionTile(
          number: i + 1,
          text: (q.audioOptions && !_reveal) ? null : q.options[i],
          state: _stateFor(i),
          onTap: canTap ? () => onSelect!(i) : null,
          note: _reveal && i == selected && i != q.answer ? 'Bạn đã chọn' : null,
        ),
      if (_reveal) ...[
        if (selected == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Bạn chưa trả lời câu này.', style: Zen.small.copyWith(color: Zen.amber)),
          ),
        const SizedBox(height: 6),
        _ExplanationCard(examId: examId, question: q),
      ],
    ]);
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene});

  final String scene;

  @override
  Widget build(BuildContext context) {
    return ZenCard(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFCFBF8),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Zen.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.east_rounded, color: Zen.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tình huống', style: Zen.labelSm),
            const SizedBox(height: 2),
            Text(scene, style: Zen.bodyLg),
          ]),
        ),
      ]),
    );
  }
}

/// Bảng xếp thẻ cho dạng 文の組み立て: chạm thẻ để điền lần lượt vào ô.
class _OrderingBoard extends StatefulWidget {
  const _OrderingBoard({super.key, required this.question, this.onStar});

  final Question question;
  final ValueChanged<int>? onStar;

  @override
  State<_OrderingBoard> createState() => _OrderingBoardState();
}

class _OrderingBoardState extends State<_OrderingBoard> {
  final List<int?> slots = [null, null, null, null];

  void _place(int token) {
    if (widget.onStar == null) return;
    final free = slots.indexOf(null);
    if (free < 0 || slots.contains(token)) return;
    setState(() => slots[free] = token);
    if (free == widget.question.star) widget.onStar!(token);
  }

  void _clear(int slot) {
    if (widget.onStar == null) return;
    setState(() => slots[slot] = null);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return ZenCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nháp: chạm thẻ để xếp câu, chạm ô để gỡ', style: Zen.labelSm),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => _clear(i),
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == q.star ? Zen.primary.withValues(alpha: 0.05) : Zen.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == q.star ? Zen.primary : Zen.border, width: i == q.star ? 1.5 : 1),
                  ),
                  child: slots[i] == null
                      ? Text(i == q.star ? '★' : '＿', style: Zen.ja(16, color: i == q.star ? Zen.primary : Zen.ink3))
                      : Text(q.options[slots[i]!], style: Zen.ja(15, weight: FontWeight.w600, height: 1.2)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var t = 0; t < q.options.length; t++)
            ActionChip(
              onPressed: slots.contains(t) ? null : () => _place(t),
              label: Text('${t + 1}  ${q.options[t]}', style: Zen.ja(15, weight: FontWeight.w600, height: 1.2)),
              backgroundColor: Zen.surface,
              disabledColor: Zen.subtle,
            ),
        ]),
      ]),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.examId, required this.question});

  final String examId;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    final key = '$examId|${question.id}';
    final q = question;
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final saved = storage.inNotebook(key);
        return ZenCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.lightbulb_outline, color: Zen.amber, size: 20),
              const SizedBox(width: 6),
              Text('Giải thích chi tiết', style: Zen.label),
            ]),
            const SizedBox(height: 10),
            if (q.isOrdering) ...[
              Text('Thứ tự đúng:', style: Zen.labelSm),
              const SizedBox(height: 4),
              Text(q.order!.map((i) => q.options[i]).join('　'), style: Zen.ja(17, weight: FontWeight.w600)),
              const SizedBox(height: 10),
            ],
            Text(q.explanation, style: Zen.body.copyWith(height: 1.6)),
            if (q.isListening) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              Text('Lời thoại (スクリプト)', style: Zen.labelSm),
              const SizedBox(height: 6),
              for (final l in q.script)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 64,
                      child: Text(l.speakerLabel, style: Zen.ja(12, weight: FontWeight.w600, color: Zen.ink2)),
                    ),
                    Expanded(child: Text(l.text, style: Zen.ja(15, weight: FontWeight.w400, height: 1.6))),
                  ]),
                ),
              if (q.audioOptions)
                for (var i = 0; i < q.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 64, child: Text('${i + 1}', style: Zen.label.copyWith(color: Zen.ink2))),
                      Expanded(child: Text(q.options[i], style: Zen.ja(15, weight: FontWeight.w400, height: 1.6))),
                    ]),
                  ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => storage.toggleNotebook(key),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined, color: Zen.primary, size: 20),
              label: Text(saved ? 'Đã lưu vào sổ ôn tập' : 'Thêm vào sổ ôn tập'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
            ),
          ]),
        );
      },
    );
  }
}
