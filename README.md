# JLPT N5 Thi Thử (ManabiHub)

App Flutter thi thử JLPT N5, giao diện theo design system **Zen Vermilion Study** (Stitch).

## Tính năng
- Đề thi đầy đủ đúng cấu trúc N5: 文字・語彙 (20 phút) → 文法・読解 (40 phút) → 聴解 (30 phút), 67 câu/đề.
- Đồng hồ từng phần, đánh dấu câu, lưới chuyển câu, lưu bài làm dở.
- Chấm điểm theo quy tắc JLPT: 言語知識・読解 0–120 (liệt 38), 聴解 0–60 (liệt 19), đỗ khi ≥ 80/180
  (điểm quy đổi ước tính theo tỉ lệ câu đúng).
- Xem lại đáp án với giải thích tiếng Việt, lời thoại bài nghe, sổ ôn tập.
- Luyện riêng 14 dạng 問題.
- Nghe hiểu dùng giọng đọc tiếng Nhật của thiết bị (flutter_tts), giọng nam/nữ/người dẫn khác cao độ.

## Nội dung đề
Câu hỏi là nội dung **tự soạn** theo format JLPT (không sao chép đề thật), viết trong `tools/content/*.py`.
Sinh lại JSON:

```bash
python3 tools/build_exams.py   # kiểm tra số câu từng dạng, đáp án, giải thích
```

Quy ước soạn: đáp án đúng luôn đặt đầu tiên — script tự xáo trộn cố định theo id câu.

## Build
Thư mục `android/` và `ios/` được sinh tự động:

```bash
flutter create --platforms=android,ios --org com.manabihub --project-name jlpt_mock_test .
python3 tools/configure_native.py   # tên app, bundle id com.manabihub.jlptn5mock, icon, quyền TTS
flutter pub get && flutter test
flutter build apk --release
```

CI (`.github/workflows/ci.yml`) chạy analyze, test và build APK ở mỗi lần push.

Font Plus Jakarta Sans: SIL Open Font License 1.1.

## Cập nhật đề không cần build lại app
App tải đề từ GitHub Pages: `https://hainc08.github.io/jlpt-content/exams/n5/` (repo `jlpt-content`, thư mục `D:\100.JLPT\content`).
Thêm/sửa/xoá đề chỉ cần sửa JSON + `index.json` ở đó — xem `exams/HUONG_DAN.md` trong repo đó.
Xuất đề soạn bằng Python sang thư mục đó:

```bash
python3 tools/build_exams.py --publish ../../content/exams
```

Khi offline, app dùng đề đã tải lần trước hoặc đề đóng sẵn trong `assets/exams/`.
