import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models.dart';

/// Phát bài nghe bằng giọng đọc tiếng Nhật của thiết bị (TTS).
/// Mỗi người nói có cao độ giọng riêng để phân biệt nam/nữ/người dẫn.
class ListeningPlayer extends ChangeNotifier {
  ListeningPlayer();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool? _jaAvailable;
  int _token = 0;

  bool playing = false;
  int currentLine = -1;
  int totalLines = 0;
  String? playingKey;

  /// Số lần đã nghe theo câu hỏi.
  final Map<String, int> playCounts = {};

  bool? get japaneseAvailable => _jaAvailable;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      if (Platform.isIOS) {
        // Vẫn phát tiếng khi iPhone bật chế độ im lặng.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker, IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        );
      }
      final ok = await _tts.isLanguageAvailable('ja-JP');
      _jaAvailable = ok == true || ok == 1;
      await _tts.setLanguage('ja-JP');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
    } catch (_) {
      _jaAvailable = false;
    }
  }

  static double _pitch(String speaker) => switch (speaker) {
        'M' => 0.78,
        'F' => 1.3,
        _ => 1.0,
      };

  static const _kanaNumbers = ['いち', 'に', 'さん', 'よん'];

  /// Phát toàn bộ kịch bản; với dạng 発話表現/即時応答 đọc thêm các lựa chọn.
  Future<void> play(String key, List<ScriptLine> script, {List<String>? readOptions}) async {
    await _init();
    await stop();
    final token = ++_token;
    final lines = <ScriptLine>[
      ...script,
      if (readOptions != null)
        for (var i = 0; i < readOptions.length; i++) ScriptLine('N', '${_kanaNumbers[i]}。${readOptions[i]}'),
    ];
    playing = true;
    playingKey = key;
    totalLines = lines.length;
    currentLine = 0;
    playCounts[key] = (playCounts[key] ?? 0) + 1;
    notifyListeners();
    for (var i = 0; i < lines.length; i++) {
      if (token != _token) return;
      currentLine = i;
      notifyListeners();
      try {
        await _tts.setPitch(_pitch(lines[i].speaker));
        await _tts.speak(lines[i].text);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    if (token != _token) return;
    playing = false;
    currentLine = totalLines;
    notifyListeners();
  }

  Future<void> stop() async {
    _token++;
    if (playing) {
      playing = false;
      notifyListeners();
    }
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Đọc thử một câu để kiểm tra âm thanh.
  Future<void> test() => play('__test__', const [ScriptLine('N', 'これから ちょうかいの テストを はじめます。')]);

  @override
  void dispose() {
    _token++;
    _tts.stop();
    super.dispose();
  }
}
