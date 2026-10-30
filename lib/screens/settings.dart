import 'package:flutter/material.dart';

import '../app.dart';
import '../app_config.dart';
import '../data/repository.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'exam_list.dart';

/// Cài đặt: nguồn đề (GitHub Pages), đồng bộ thủ công, xoá đề đã tải.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController? _url;
  String? _error;

  ExamRepository get _repo => AppScope.of(context).repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _url ??= TextEditingController(text: _repo.remoteBase);
  }

  @override
  void dispose() {
    _url?.dispose();
    super.dispose();
  }

  Future<void> _saveAndSync() async {
    final repo = _repo;
    final ok = await repo.setRemoteBase(_url!.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = 'Địa chỉ không hợp lệ. Cần dạng https://…/exams/${AppConfig.id}/');
      return;
    }
    setState(() => _error = null);
    _url!.text = repo.remoteBase;
    FocusScope.of(context).unfocus();
    await ExamListScreen.refresh(context);
  }

  Future<void> _reset() async {
    final repo = _repo;
    await repo.setRemoteBase(null);
    if (!mounted) return;
    setState(() => _error = null);
    _url!.text = repo.remoteBase;
    await ExamListScreen.refresh(context);
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá đề đã tải?'),
        content: const Text(
            'Chỉ còn các đề đóng sẵn trong app. Lịch sử thi của đề đã tải sẽ không mở lại được chi tiết. Bạn vẫn tải lại được bằng cách đồng bộ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _repo.clearDownloaded();
    messenger.showSnackBar(const SnackBar(content: Text('Đã xoá đề đã tải.')));
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final last = repo.lastSync;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SectionTitle('Nguồn đề thi'),
              ZenCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Địa chỉ thư mục chứa index.json (GitHub Pages).', style: Zen.small),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(repo.usesCustomBase ? 'Đang dùng địa chỉ tuỳ chỉnh.' : 'Đang dùng địa chỉ mặc định.', style: Zen.small),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: repo.syncing ? null : _saveAndSync,
                        child: const Text('Lưu & đồng bộ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: repo.syncing || !repo.usesCustomBase ? null : _reset,
                      child: const Text('Mặc định'),
                    ),
                  ]),
                ]),
              ),
              const SectionTitle('Đồng bộ'),
              ZenCard(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.cloud_sync_outlined, color: Zen.ink2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${repo.exams.length} đề · ${last == null ? 'chưa đồng bộ lần nào' : 'đồng bộ lần cuối ${_fmt(last)}'}',
                        style: Zen.body,
                      ),
                    ),
                  ]),
                  if (repo.lastError != null) ...[
                    const SizedBox(height: 8),
                    Text('Lỗi lần gần nhất: ${repo.lastError}', style: Zen.small.copyWith(color: Zen.primary)),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: repo.syncing ? null : () => ExamListScreen.refresh(context),
                        icon: const Icon(Icons.refresh),
                        label: Text(repo.syncing ? 'Đang đồng bộ…' : 'Kiểm tra đề mới'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: repo.syncing ? null : _clear,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xoá đề đã tải'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
