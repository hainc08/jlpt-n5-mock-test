---
name: manabihub-mock-test
description: Làm app JLPT Thi Thử (ManabiHub): soạn và đăng đề thi thử N5–N1, thêm cấp mới, build và kiểm tra app Flutter thi thử, cập nhật đề qua repo jlpt-content.
---

# App JLPT Thi Thử (ManabiHub)

App Flutter thi thử JLPT cho người Việt, giao diện theo design system **Zen Vermilion Study** (Stitch, project `13594785216952493333`). Bản làm việc: `D:\100.JLPT\apps\mock_test` (nếu chưa dời: `D:\100.JLPT\jlpt_n5_mock_test`). Đầu phiên đọc `CLAUDE.md` trong thư mục đó; cuối phiên cập nhật mục *Trạng thái* / *Việc tiếp theo*.

## Kiến trúc
- `lib/models.dart` Exam → Section(scoreGroup) → Mondai(type, passage, table) → Question(options, answer, explanation, script, scene, audioOptions, order/star).
- `lib/logic/scoring.dart` luật chấm; `lib/logic/session.dart` đồng hồ từng phần + lưu bài dở; `lib/services/listening.dart` nghe hiểu bằng TTS (flutter_tts, `ja-JP`, cao độ N 1.0 / M 0.78 / F 1.3; không dùng `dart:io` để chạy được web).
- `lib/data/repository.dart`: đề đóng sẵn `assets/exams/<level>/` + đề từ `https://hainc08.github.io/jlpt-content/exams/<level>/` (ETag, cache trong SharedPreferences, đề bị gỡ khỏi index vẫn mở được lịch sử; tự đồng bộ ≤3 giờ/lần, kéo làm mới ở màn Chọn đề).
- `android/ ios/ web/` sinh bằng `flutter create`, không commit; `tools/configure_native.py` đặt tên, bundle `com.manabihub.jlpt<level>mock`, icon, quyền INTERNET + `<queries>` TTS_SERVICE, `kotlin.incremental=false`.
- Thiết kế: token màu/chữ trong `lib/theme.dart` (vermilion #B9343F, xanh tre #15803D, nền washi #F7F7F4, Plus Jakarta Sans đóng gói trong assets/fonts; chữ Nhật dùng `Zen.ja()` có `locale: ja` để hiện đúng Kanji Nhật).

## Cấu trúc đề chuẩn
| Cấp | Phần thi (phút) | Nhóm điểm | Đỗ |
|---|---|---|---|
| N5 | 文字・語彙 20 · 文法・読解 40 · 聴解 30 | 言語知識・読解 0–120 (liệt 38) · 聴解 0–60 (liệt 19) | 80 |
| N4 | 文字・語彙 25 · 文法・読解 55 · 聴解 35 | như N5 | 90 |
| N3 | 文字・語彙 30 · 文法・読解 70 · 聴解 40 | 言語知識 · 読解 · 聴解, mỗi phần 0–60, liệt 19 | 95 |
| N2 | 言語知識・読解 105 · 聴解 50 | như N3 | 90 |
| N1 | 言語知識・読解 110 · 聴解 55 | như N3 | 100 |
Số câu từng dạng 問題 thay đổi theo năm — tra lại trang chính thức jlpt.jp trước khi làm cấp mới. N5 hiện dùng: 漢字読み7 表記5 文脈規定6 言い換え3 · 文法形式9 文の組み立て4 文章の文法4 · 短文2 中文2 情報検索1 · 課題理解7 ポイント理解6 発話表現5 即時応答6 (67 câu). Với N3–N1, `scoreGroup` phải gán được theo mondai (読解 nằm cùng phần thi với 文法 nhưng chấm riêng). Điểm trong app là quy đổi ước tính theo tỉ lệ câu đúng — luôn ghi rõ là ước tính.

## Soạn đề mới
1. Nội dung **tự soạn** theo format JLPT, không chép đề thật hay sách luyện thi. Từ vựng/ngữ pháp đúng cấp. Mỗi câu có giải thích tiếng Việt (nghĩa câu, vì sao đúng, bẫy ở lựa chọn sai); câu nghe có lời thoại.
2. Viết `tools/content/<level>_NN.py` bằng DSL trong `tools/exam_dsl.py`: `q(prompt, opts, exp)`, `mondai(type, label, questions, passage=, table=)`, nghe `L(situation, question, lines, opts, exp)`, 発話表現 `H(scene_vi, situation_ja, opts, exp)`, 即時応答 `S(speaker, line, opts, exp)`. **Đáp án đúng luôn viết đầu tiên**; script tự xáo cố định theo id. `{...}` = gạch chân, `［1］` = ô trống đoạn văn. 文の組み立て: `opts` là 4 thẻ theo thứ tự hiển thị, `order=` thứ tự đúng, `star=` vị trí ★. Giải thích không nhắc số thứ tự lựa chọn (vì bị xáo).
3. Thêm module vào `MODULES` trong `tools/build_exams.py`, chạy `python3 tools/build_exams.py` (kiểm tra đủ số câu từng dạng, đáp án, giải thích, script nghe).
4. Đăng lên mạng (không cần build lại app): `python3 tools/build_exams.py --publish ../../content/exams` → trong `D:\100.JLPT\content` chạy `python exams/check_exams.py`, commit; người dùng `git push` (Claude chưa push được GitHub). Thứ tự hiển thị = thứ tự trong `exams/<level>/index.json`; xoá đề = bỏ tên khỏi index; sửa đề = giữ nguyên `id`.
5. Không bao giờ đổi đường dẫn `exams/<level>/` sau khi app đã phát hành.

## Build và kiểm tra
- Trên máy người dùng (Windows, Flutter `C:\Users\admin\develop`): người dùng nhấp đúp `BUILD_N5.bat` (create → configure_native → analyze → test → build APK, log `_build\build.log`, trạng thái `_build\status.txt`) hoặc `RUN_WEB.bat` (Chrome). Claude đọc log qua device_bash. Nếu cửa sổ đứng ở bước "Doi Claude cau hinh native": chạy `python3 tools/configure_native.py` qua device_bash rồi tạo `_build/configured.txt`.
- Trong container (không có Flutter): type-check bằng bộ phân tích dựng tay (flutter stable clone + sky_engine tự ráp + Dart SDK từ conda-forge + package từ GitHub dart-lang/*; stub `shared_preferences`) → `dart analyze lib test`. Không khẳng định "test đã qua" khi chưa chạy `flutter test` thật.
- Test hiện có: dữ liệu đề (cấu trúc, đáp án, chấm điểm), session (nộp phần, lưu/khôi phục), repository (thêm/sửa/xoá đề, offline, file hỏng), widget (trang chủ, phòng thi).

## Đồng bộ code giữa container và D:
Bản trên D: là gốc. Lấy về: device_bash `git bundle create ../../_archive/x.bundle <branch>` → device_stage_files → `git fetch`/`reset` trong container. Gửi đi: `git bundle create … <base>..<branch>` → device_commit_files vào `D:\100.JLPT\_archive` → device_bash `git pull --ff-only`. Xin quyền xoá `D:\100.JLPT` mỗi phiên cho file lock của git.

## Việc còn lại (tính tới 29/10/2026)
Chuyển sang nhiều cấp (`apps/<level>/config.json` như app Kanji, luật chấm theo cấp), AdMob, store listing, repo GitHub + CI, rồi phát hành theo skill `manabihub-app-launch` / `flutter-store-release`.
