import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jlpt_mock_test/data/repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Máy chủ giả lập GitHub Pages: map tên file → nội dung (null = 404).
class FakeServer {
  final Map<String, String> files = {};
  bool offline = false;
  int requests = 0;

  http.Client get client => MockClient((req) async {
        requests++;
        if (offline) throw const SocketException('offline');
        final name = req.url.pathSegments.last;
        final body = files[name];
        if (body == null) return http.Response('not found', 404);
        final etag = '"${body.hashCode}"';
        if (req.headers['If-None-Match'] == etag) return http.Response('', 304);
        return http.Response.bytes(utf8.encode(body), 200, headers: {'etag': etag});
      });

  void setIndex(List<String> names) => files['index.json'] = jsonEncode({'schema': 1, 'exams': names});
}

String examJson(String id, String title) {
  final j = jsonDecode(File('assets/exams/n5/n5-01.json').readAsStringSync()) as Map<String, dynamic>;
  j['id'] = id;
  j['title'] = title;
  return jsonEncode(j);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeServer server;
  late SharedPreferences prefs;

  Future<ExamRepository> makeRepo() async {
    final repo = ExamRepository(prefs: prefs, client: server.client, remoteBase: 'https://example.test/exams/n5/');
    await repo.init();
    return repo;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    server = FakeServer()
      ..files['n5-01.json'] = File('assets/exams/n5/n5-01.json').readAsStringSync()
      ..files['n5-02.json'] = File('assets/exams/n5/n5-02.json').readAsStringSync();
  });

  test('mất mạng: vẫn dùng đề đóng sẵn', () async {
    server.offline = true;
    final repo = await makeRepo();
    expect(await repo.sync(), -1);
    expect(repo.exams.map((e) => e.id), ['n5-01', 'n5-02']);
  });

  test('thêm đề mới trên GitHub → app thấy ngay', () async {
    server.files['n5-03.json'] = examJson('n5-03', 'Đề chuẩn số 03');
    server.setIndex(['n5-01.json', 'n5-02.json', 'n5-03.json']);
    final repo = await makeRepo();
    expect(await repo.sync(), 1);
    expect(repo.exams.map((e) => e.id), ['n5-01', 'n5-02', 'n5-03']);
    expect(repo.isBundled('n5-03'), isFalse);
    expect((await repo.load('n5-03')).title, 'Đề chuẩn số 03');

    // Mở lại app (repo mới, cùng bộ nhớ): đề đã tải vẫn còn khi không có mạng.
    server.offline = true;
    final again = await makeRepo();
    expect(again.exams.map((e) => e.id), contains('n5-03'));
  });

  test('sửa đề → tải lại bản mới; không đổi → không tải lại', () async {
    server.setIndex(['n5-01.json', 'n5-02.json']);
    final repo = await makeRepo();
    expect(await repo.sync(), 0);

    server.files['n5-01.json'] = examJson('n5-01', 'Đề 01 (đã sửa)');
    expect(await repo.sync(), 1);
    expect((await repo.load('n5-01')).title, 'Đề 01 (đã sửa)');
    expect(await repo.sync(), 0);
  });

  test('xoá đề khỏi index → ẩn khỏi danh sách nhưng lịch sử vẫn mở được', () async {
    server.files['n5-03.json'] = examJson('n5-03', 'Đề chuẩn số 03');
    server.setIndex(['n5-01.json', 'n5-02.json', 'n5-03.json']);
    final repo = await makeRepo();
    await repo.sync();

    server.setIndex(['n5-01.json', 'n5-03.json']);
    expect(await repo.sync(), greaterThanOrEqualTo(1));
    expect(repo.exams.map((e) => e.id), ['n5-01', 'n5-03']);

    server.setIndex(['n5-01.json']);
    await repo.sync();
    final again = await makeRepo();
    expect(again.exams.map((e) => e.id), ['n5-01']);
    expect((await again.load('n5-03')).id, 'n5-03');
  });

  test('file đề lỗi trên server bị bỏ qua, không làm hỏng app', () async {
    server.files['hong.json'] = '{"id": "x", ';
    server.setIndex(['n5-01.json', 'hong.json', 'n5-02.json']);
    final repo = await makeRepo();
    await repo.sync();
    expect(repo.exams.map((e) => e.id), ['n5-01', 'n5-02']);
  });

  test('index trống hoặc lỗi → giữ nguyên danh sách cũ', () async {
    server.files['index.json'] = '{"exams": []}';
    final repo = await makeRepo();
    expect(await repo.sync(), -1);
    expect(repo.exams.length, 2);
  });
}
