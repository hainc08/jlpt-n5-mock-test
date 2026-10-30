import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import '../models.dart';

/// Kho đề thi: đề đóng sẵn trong app + đề tải từ GitHub Pages.
///
/// Trên server chỉ cần:
///   `<remoteBase>/index.json`  → `{"exams": ["n5-01.json", "n5-02.json", ...]}`
///   `<remoteBase>/n5-01.json`  → nội dung đề
/// Thêm đề = thêm file + thêm tên vào index; xoá đề = bỏ tên khỏi index;
/// sửa đề = sửa file. App tự nhận thay đổi khi mở (hoặc kéo để làm mới).
class ExamRepository extends ChangeNotifier {
  ExamRepository({
    AssetBundle? bundle,
    SharedPreferences? prefs,
    http.Client? client,
    this.level = AppConfig.id,
    String? remoteBase,
  })  : _bundle = bundle ?? rootBundle,
        _prefs = prefs,
        _client = client ?? http.Client(),
        defaultRemoteBase = remoteBase ?? 'https://hainc08.github.io/jlpt-content/exams/$level/';

  /// Phiên bản cấu trúc dữ liệu app hiểu được. Đề có `minSchema` lớn hơn sẽ bị bỏ qua.
  static const supportedSchema = 1;

  /// Khoảng cách tối thiểu giữa 2 lần tự đồng bộ (kéo làm mới thì luôn đồng bộ).
  static const autoSyncInterval = Duration(hours: 3);

  final AssetBundle _bundle;
  final SharedPreferences? _prefs;
  final http.Client _client;
  final String level;

  /// Nguồn đề mặc định (có thể đổi trong Cài đặt — xem [setRemoteBase]).
  final String defaultRemoteBase;

  String get _kBase => 'setting_remote_base_$level';

  /// Nguồn đề đang dùng: địa chỉ người dùng đặt trong Cài đặt, hoặc mặc định.
  String get remoteBase => _prefs?.getString(_kBase) ?? defaultRemoteBase;

  bool get usesCustomBase => _prefs?.getString(_kBase) != null;

  /// Chuẩn hoá địa chỉ nguồn: bắt buộc http(s), tự thêm `/` cuối. Trả về null nếu không hợp lệ.
  static String? normalizeBase(String input) {
    final s = input.trim();
    final uri = Uri.tryParse(s);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
    final noQuery = s.split(RegExp(r'[?#]')).first;
    return noQuery.endsWith('/') ? noQuery : '$noQuery/';
  }

  /// Đổi nguồn đề rồi đồng bộ ngay. `null` hoặc địa chỉ mặc định = quay về mặc định.
  /// Trả về false nếu địa chỉ không hợp lệ.
  Future<bool> setRemoteBase(String? url) async {
    final prefs = _prefs;
    if (prefs == null) return false;
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_kBase);
    } else {
      final norm = normalizeBase(url);
      if (norm == null) return false;
      if (norm == defaultRemoteBase) {
        await prefs.remove(_kBase);
      } else {
        await prefs.setString(_kBase, norm);
      }
    }
    // Quên mốc đồng bộ + ETag cũ để lần tải tới lấy mới hoàn toàn từ nguồn mới.
    await prefs.remove(_kLastSync);
    for (final f in _cachedFiles) {
      await prefs.remove(_kEtag(f));
    }
    notifyListeners();
    return true;
  }

  /// Xoá đề đã tải về, quay về đề đóng sẵn trong app. (Lịch sử thi của đề đã tải sẽ không mở lại được.)
  Future<void> clearDownloaded() async {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final f in _cachedFiles) {
      await prefs.remove(_kSrc(f));
      await prefs.remove(_kEtag(f));
    }
    await prefs.remove(_kFiles);
    await prefs.remove(_kKnown);
    await prefs.remove(_kLastSync);
    lastError = null;
    _byId.clear();
    _idByFile.clear();
    _ready = false;
    await init();
    notifyListeners();
  }

  String get _kFiles => 'remote_files_$level';
  String get _kKnown => 'remote_known_$level';
  String get _kLastSync => 'remote_sync_$level';
  String _kSrc(String file) => 'remote_src_${level}_$file';
  String _kEtag(String file) => 'remote_etag_${level}_$file';

  /// Đề theo id (gồm cả đề đã bị gỡ khỏi danh sách nhưng còn cache — để xem lại lịch sử).
  final Map<String, Exam> _byId = {};
  final Map<String, String> _idByFile = {};
  List<String> _bundledFiles = const [];
  List<ExamSummary> _exams = const [];
  bool _ready = false;
  bool syncing = false;
  String? lastError;

  List<ExamSummary> get exams => _exams;

  DateTime? get lastSync {
    final ms = _prefs?.getInt(_kLastSync);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool isBundled(String examId) => _bundledFiles.any((f) => _idByFile[f] == examId);

  /// Đọc đề đóng sẵn + đề đã cache. Gọi một lần khi mở app.
  Future<void> init() async {
    if (_ready) return;
    final raw = jsonDecode(await _bundle.loadString('assets/exams/$level/index.json')) as Map<String, dynamic>;
    _bundledFiles = _fileList(raw);
    for (final f in _bundledFiles) {
      final exam = _parse(await _bundle.loadString(_assetPath(f)));
      if (exam != null) _put(f, exam);
    }
    for (final f in _cachedFiles) {
      final src = _prefs?.getString(_kSrc(f));
      final exam = src == null ? null : _parse(src);
      if (exam != null) _put(f, exam);
    }
    _ready = true;
    _rebuild();
  }

  /// Danh sách tên file đề trong index (chấp nhận chuỗi hoặc object có trường `file`).
  static List<String> _fileList(Map<String, dynamic> index) {
    final out = <String>[];
    for (final e in (index['exams'] as List?) ?? const []) {
      if (e is String) {
        out.add(e.split('/').last);
      } else if (e is Map && e['file'] is String) {
        out.add((e['file'] as String).split('/').last);
      }
    }
    return out;
  }

  String _assetPath(String file) => 'assets/exams/$level/$file';

  /// Mọi file từng tải về (kể cả đề đã bị gỡ) — để vẫn mở được lịch sử thi cũ.
  List<String> get _cachedFiles => {...?_prefs?.getStringList(_kKnown), ...?_prefs?.getStringList(_kFiles)}.toList();

  Exam? _parse(String src) {
    try {
      final j = jsonDecode(src) as Map<String, dynamic>;
      if (((j['minSchema'] as int?) ?? 1) > supportedSchema) return null;
      final exam = Exam.fromJson(j);
      if (exam.sections.isEmpty || exam.totalQuestions == 0) return null;
      return exam;
    } catch (_) {
      return null;
    }
  }

  void _put(String file, Exam exam) {
    _byId[exam.id] = exam;
    _idByFile[file] = exam.id;
  }

  void _rebuild() {
    final files = _prefs?.getStringList(_kFiles) ?? _bundledFiles;
    final seen = <String>{};
    final list = <ExamSummary>[];
    for (final f in files) {
      final id = _idByFile[f];
      final exam = id == null ? null : _byId[id];
      if (exam == null || !seen.add(exam.id)) continue;
      list.add(ExamSummary.fromExam(exam, file: f));
    }
    _exams = list;
  }

  Future<List<ExamSummary>> index() async {
    await init();
    return _exams;
  }

  Future<Exam> load(String examId) async {
    await init();
    final exam = _byId[examId];
    if (exam == null) throw StateError('Không tìm thấy đề $examId');
    return exam;
  }

  Future<List<Exam>> loadAll() async {
    await init();
    return [for (final s in _exams) _byId[s.id]!];
  }

  /// Tự đồng bộ nếu đã lâu chưa đồng bộ.
  Future<void> maybeSync() async {
    final last = lastSync;
    if (last != null && DateTime.now().difference(last) < autoSyncInterval) return;
    await sync();
  }

  /// Tải danh sách đề mới nhất. Trả về số đề được thêm/cập nhật, -1 nếu lỗi mạng.
  Future<int> sync() async {
    final prefs = _prefs;
    if (prefs == null || syncing) return 0;
    await init();
    syncing = true;
    lastError = null;
    notifyListeners();
    var changed = 0;
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final res = await _client.get(Uri.parse('${remoteBase}index.json?t=$stamp')).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw Exception('index.json: HTTP ${res.statusCode}');
      final index = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final files = _fileList(index);
      if (files.isEmpty) throw Exception('index.json không có đề nào');

      final kept = <String>[];
      for (final f in files) {
        final ok = await _syncFile(prefs, f, stamp);
        if (ok == null) {
          // Tải lỗi: vẫn giữ nếu đã có bản cache / bản đóng sẵn.
          if (_idByFile[f] != null) kept.add(f);
          continue;
        }
        if (ok) changed++;
        kept.add(f);
      }
      final before = _exams.map((e) => e.id).toList();
      await prefs.setStringList(_kFiles, kept);
      await prefs.setInt(_kLastSync, DateTime.now().millisecondsSinceEpoch);
      _rebuild();
      if (!listEquals(before, _exams.map((e) => e.id).toList()) && changed == 0) changed = 1;
      return changed;
    } catch (e) {
      lastError = '$e';
      return -1;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  /// true = đề mới/đã thay đổi, false = không đổi, null = lỗi.
  Future<bool?> _syncFile(SharedPreferences prefs, String file, int stamp) async {
    try {
      final etag = prefs.getString(_kEtag(file));
      final cached = prefs.getString(_kSrc(file));
      final headers = <String, String>{
        // Trình duyệt sẽ tự gửi điều kiện ETag; header tuỳ chỉnh gây CORS preflight.
        if (!kIsWeb && etag != null && cached != null) 'If-None-Match': etag,
      };
      final url = kIsWeb ? '$remoteBase$file?t=$stamp' : '$remoteBase$file';
      final res = await _client.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 20));
      if (res.statusCode == 304) return false;
      if (res.statusCode != 200) return null;
      final src = utf8.decode(res.bodyBytes);
      final exam = _parse(src);
      if (exam == null) return null;
      final newEtag = res.headers['etag'];
      if (newEtag != null) await prefs.setString(_kEtag(file), newEtag);
      final previous = cached ?? (_bundledFiles.contains(file) ? await _bundle.loadString(_assetPath(file)) : null);
      if (previous != null && _sameJson(previous, src)) {
        if (cached == null) await prefs.setString(_kSrc(file), src);
        return false;
      }
      await prefs.setString(_kSrc(file), src);
      final known = prefs.getStringList(_kKnown) ?? <String>[];
      if (!known.contains(file)) await prefs.setStringList(_kKnown, [...known, file]);
      _put(file, exam);
      return true;
    } catch (_) {
      return null;
    }
  }

  static bool _sameJson(String a, String b) {
    try {
      return jsonEncode(jsonDecode(a)) == jsonEncode(jsonDecode(b));
    } catch (_) {
      return a == b;
    }
  }
}
