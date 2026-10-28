import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/question_view.dart';

enum ReviewFilter { all, wrong, saved }

/// Xem lại đáp án sau khi thi.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.exam, required this.answers});

  final Exam exam;
  final Map<String, int> answers;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ReviewFilter filter = ReviewFilter.wrong;
  int index = 0;

  bool _isWrong(QuestionRef r) => widget.answers[r.question.id] != r.question.answer;

  List<QuestionRef> _list(Set<String> notebook) {
    final all = widget.exam.refs.toList();
    return switch (filter) {
      ReviewFilter.all => all,
      ReviewFilter.wrong => all.where(_isWrong).toList(),
      ReviewFilter.saved => all.where((r) => notebook.contains(r.key)).toList(),
    };
  }

  @override
  void initState() {
    super.initState();
    if (!widget.exam.refs.any(_isWrong)) filter = ReviewFilter.all;
  }

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final notebook = storage.notebook;
        final list = _list(notebook);
        final all = widget.exam.refs.toList();
        final wrongCount = all.where(_isWrong).length;
        final savedCount = all.where((r) => notebook.contains(r.key)).length;
        if (index >= list.length) index = list.isEmpty ? 0 : list.length - 1;
        final ref = list.isEmpty ? null : list[index];
        return Scaffold(
          appBar: AppBar(title: const Text('Xem lại đáp án')),
          body: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                _chip('Tất cả (${all.length})', ReviewFilter.all),
                _chip('Câu sai ($wrongCount)', ReviewFilter.wrong),
                _chip('Đã lưu ($savedCount)', ReviewFilter.saved),
              ]),
            ),
            Expanded(
              child: ref == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          filter == ReviewFilter.wrong ? 'Không có câu sai. Tuyệt vời!' : 'Chưa có câu nào.',
                          style: Zen.body.copyWith(color: Zen.ink2),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      key: PageStorageKey('review-${ref.question.id}-${filter.name}'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Tag(ref.section.titleJa, color: Zen.ink2),
                          const Spacer(),
                          if (widget.answers[ref.question.id] == ref.question.answer)
                            const Tag('Đúng ✓', color: Zen.green)
                          else
                            const Tag('Sai ✗', color: Zen.primary),
                        ]),
                        const SizedBox(height: 12),
                        QuestionView(
                          key: ValueKey('rv-${ref.question.id}'),
                          examId: widget.exam.id,
                          mondai: ref.mondai,
                          question: ref.question,
                          mode: QuestionMode.review,
                          selected: widget.answers[ref.question.id],
                        ),
                      ]),
                    ),
            ),
            if (list.isNotEmpty)
              Container(
                decoration: const BoxDecoration(
                  color: Zen.surface,
                  border: Border(top: BorderSide(color: Zen.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: index == 0 ? null : () => setState(() => index--),
                          child: const Text('← Câu trước'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${index + 1}/${list.length}', style: Zen.label),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: index >= list.length - 1 ? null : () => setState(() => index++),
                          child: const Text('Câu tiếp →'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _chip(String label, ReviewFilter f) {
    final selected = filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: Zen.label.copyWith(color: selected ? Colors.white : Zen.ink),
        selectedColor: Zen.primary,
        onSelected: (_) => setState(() {
          filter = f;
          index = 0;
        }),
      ),
    );
  }
}
