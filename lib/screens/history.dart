import 'package:flutter/material.dart';

import '../app.dart';
import '../logic/scoring.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'nav.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thi')),
      body: ListenableBuilder(
        listenable: storage,
        builder: (context, _) {
          final attempts = storage.attempts;
          if (attempts.isEmpty) {
            return Center(child: Text('Chưa có lần thi nào.', style: Zen.body.copyWith(color: Zen.ink2)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = attempts[i];
              final d = a.date;
              return ZenCard(
                onTap: () => Nav.openResult(context, a),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  PassStamp(passed: a.passed, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.examTitle, style: Zen.label),
                      Text('${d.day}/${d.month}/${d.year}', style: Zen.small),
                    ]),
                  ),
                  Text('${a.total}', style: Zen.hLG.copyWith(color: a.passed ? Zen.green : Zen.primary)),
                  Text('/${N5Rules.totalMax}', style: Zen.small),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
