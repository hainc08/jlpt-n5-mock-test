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
- **Mỗi cấp một app riêng, chung một repo** `hainc08/jlpt-n5-mock-test` (như `jlptkanjin5`): `apps/<n5…n1>/config.json` (+ `icons/`, `store/`), `lib/` dùng chung, `lib/app_config.dart` đọc `APP/LEVEL/APP_NAME/VERSION` từ `--dart-define-from-file=apps/<app>/config.json` (mặc định n5). Đề đóng sẵn `assets/exams/<level>/`, repository dùng `AppConfig.id` làm cấp.
- `android/ ios/ web/` sinh bằng `flutter create`, không commit; `tools/configure_native.py <app>` đặt tên, bundle `com.manabihub.jlpt<level>mock`, icon (`apps/<app>/icons`), quyền INTERNET + `<queries>` TTS_SERVICE, ký release bằng `android/key.properties`, chép `tools/fastlane/{android,ios}` vào `android/fastlane`, `ios/fastlane`; `kotlin.incremental=false`.
- Cài đặt trong app (`lib/screens/settings.dart`): đổi nguồn đề (prefs `setting_remote_base_<level>`), đồng bộ thủ công, xoá đề đã tải.
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

## CI/CD và thêm cấp mới (đọc `RELEASE.md` trong repo)
- `ci.yml` (push main / PR): job `content` (đề sinh lại phải trùng bản commit), job `apps` lấy danh sách cấp từ `apps/*/config.json`, job `check` chạy matrix theo danh sách đó: `flutter create` → `configure_native.py <app>` → analyze → `flutter test --dart-define-from-file` → build APK debug. **Thêm cấp = thêm thư mục `apps/<cấp>/`, không sửa `ci.yml`.**
- `release.yml`: tag `<app>-v<VERSION>` (khớp `config.json`) hoặc Run workflow chọn app → AAB lên Play Internal, IPA lên TestFlight; tick `submit_review` → Apple review + Play Production. Fastlane dùng chung ở `tools/fastlane/` (đọc `apps/$APP/config.json`); thiếu `apps/<app>/store/...` thì bỏ qua metadata thay vì lỗi.
- **GitHub Secrets dùng chung mọi app nhưng không tự chia sẻ giữa các repo**: mỗi repo mới phải dán lại cùng bộ secret (ANDROID_KEYSTORE_*, PLAY_SERVICE_ACCOUNT_JSON, ASC_*, IOS_DIST_CERT_*). Khoá thật ở `D:\100.JLPT\_secrets`, không in ra chat.
- Thêm cấp mới (N4…N1): chép `apps/n5` → `apps/<cấp>`, sửa `config.json` (BUNDLE_ID `com.manabihub.jlpt<cấp>mock`, IOS_PROFILE `JLPT <CẤP> Mock AppStore`, VERSION `1.0.0`, AdMob trống), thay icon, thêm nội dung đề + luật chấm theo cấp, thêm `<cấp>` vào `options` của `release.yml`, rồi làm việc tay một lần trên AdMob/Apple/Play (xem skill `manabihub-app-launch`). Mỗi quy trình đổi phải cập nhật cả skill này (bản `.agents` và bản trên claude.ai) lẫn `RELEASE.md`.

## Đồng bộ code giữa container và D:
Bản trên D: là gốc. Lấy về: device_bash `git bundle create ../../_archive/x.bundle <branch>` → device_stage_files → `git fetch`/`reset` trong container. Gửi đi: `git bundle create … <base>..<branch>` → device_commit_files vào `D:\100.JLPT\_archive` → device_bash `git pull --ff-only`. Xin quyền xoá `D:\100.JLPT` mỗi phiên cho file lock của git.

## Việc còn lại (tính tới 30/10/2026)
Đã có: màn Cài đặt, cấu trúc `apps/<cấp>/`, CI matrix, release + fastlane (chưa chạy thật trên GitHub). Còn: AdMob (lib + mã thật), luật chấm/cấu trúc đề theo cấp N4–N1 (hiện `N5Rules` cố định), store listing + trang chính sách, tạo app trên Apple/Play, dán secrets vào repo, chạy Release lần đầu.
