# Bàn giao — JLPT Thi Thử (app thi thử, hiện có N5)

## Tổng quan
App Flutter thi thử JLPT, giao diện theo design system **Zen Vermilion Study** (Stitch project `13594785216952493333` "JLPT N5 Thi Thử").
Bundle `com.manabihub.jlptn5mock`, tên "JLPT N5 Thi Thử". Chưa có repo GitHub, chưa phát hành, chưa gắn AdMob.

## Mã nguồn
- `lib/models.dart` (Exam/Section/Mondai/Question), `lib/logic/scoring.dart` (luật N5: 言語知識・読解 0–120 liệt 38, 聴解 0–60 liệt 19, đỗ ≥80), `lib/logic/session.dart` (đồng hồ từng phần, lưu bài dở).
- `lib/data/repository.dart`: đề đóng sẵn (`assets/exams/n5/`) + đề tải từ `https://hainc08.github.io/jlpt-content/exams/<level>/` (ETag, cache offline, đề bị gỡ vẫn xem lại được lịch sử). Tự đồng bộ ≤ 3 giờ/lần, kéo làm mới ở màn Chọn đề.
- `lib/services/listening.dart`: nghe hiểu bằng TTS tiếng Nhật (flutter_tts), cao độ khác nhau cho N/M/F.
- Màn: home, exam_list, exam_intro, exam_room, result, review, practice (14 dạng 問題), notebook, history.
- `android/`, `ios/`, `web/` do `flutter create` sinh ra (không commit); `tools/configure_native.py` đặt tên, bundle, icon, quyền INTERNET + TTS_SERVICE, `kotlin.incremental=false` (lỗi cache khác ổ đĩa trên Windows).

## Nội dung đề
- Soạn bằng Python DSL: `tools/content/n5_01.py`, `n5_02.py` (67 câu/đề, đáp án đúng viết đầu tiên, script tự xáo). Câu hỏi tự soạn, không chép đề thật.
- `python tools/build_exams.py` → sinh + kiểm tra `assets/exams/n5/`; thêm `--publish ../../content/exams` để xuất sang repo jlpt-content.

## Build / chạy (Windows)
- `BUILD_N5.bat`: flutter create → configure_native → analyze → test → build APK (log `_build\build.log`).
- `RUN_WEB.bat`: chạy trên Chrome.
- Lần build gần nhất: analyze sạch, 16 test qua; APK lỗi Kotlin cache (đã sửa, chưa build lại). Test repository (6 test) chưa chạy trên máy thật.

## Việc tiếp theo
1. Dời thư mục vào `D:\100.JLPT\apps\mock_test` (đang bị khoá vì cửa sổ đang mở), chạy `flutter clean`.
2. Build lại APK, kiểm tra trên Chrome/điện thoại.
3. Chuyển sang nhiều cấp như app Kanji: `apps/<level>/config.json`, luật chấm theo cấp (N3–N1: 3 phần 0–60, liệt 19, đỗ N3 95 / N2 90 / N1 100; N4 như N5, đỗ 90), cấu trúc phần thi và dạng 問題 theo cấp.
4. AdMob, store listing, tạo repo GitHub + CI.

## Quy tắc
Như `D:\100.JLPT\apps\kanji_flashcard\CLAUDE.md` (không lộ khoá, người dùng tự bấm đồng ý pháp lý, người dùng tự push).
