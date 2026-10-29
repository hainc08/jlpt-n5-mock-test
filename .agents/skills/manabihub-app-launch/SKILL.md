---
name: "manabihub-app-launch"
description: "Thêm và phát hành một app học tiếng Nhật mới của ManabiHub (vd Kanji N4, N3) trong repo nhiều app hainc08/jlptkanjin5, lên App Store và Google Play."
---

# Thêm app ManabiHub mới trong repo nhiều app

Mọi app Kanji JLPT nằm chung một repo: `https://github.com/hainc08/jlptkanjin5` (bản làm việc ở máy người dùng: `D:\100.JLPT\apps\kanji_flashcard`, người dùng tự `git push`). **Không tạo repo mới cho mỗi app.** Code `lib/` dùng chung; mỗi app là một thư mục `apps/<app>/`.

## Bố cục D:\100.JLPT (đọc trước)
```
README.md                 bản đồ tổng
apps\kanji_flashcard\     repo jlptkanjin5 (app Kanji N5, N4 …)  — có CLAUDE.md bàn giao
apps\mock_test\           app JLPT Thi Thử (skill manabihub-mock-test)
content\                  repo hainc08/jlpt-content (GitHub Pages, đề thi)
store_assets\             ảnh/mô tả store gốc
_secrets\                 khoá, chứng chỉ (không commit, không in ra)
_archive\  _other\         file cũ, dự án khác
```
Mỗi app làm trong một phiên chat riêng; đầu phiên đọc `CLAUDE.md` của thư mục app, cuối phiên cập nhật lại mục *Trạng thái* và *Việc tiếp theo* trong đó.

## Thông tin cố định
- Nhà phát triển: ManabiHub. Thông tin liên hệ review (tên, điện thoại, email): lấy từ App Store Connect hoặc hỏi người dùng — không ghi vào repo công khai.
- Apple Team ID `SLR7396ZXZ`; Play developer account: D_Monkey; AdMob publisher `pub-2898831437808228`
- Bundle ID: `com.manabihub.kanji<level>` (vd `com.manabihub.kanjin4`); profile iOS tên `Kanji <LEVEL> AppStore`
- App miễn phí, có Google AdMob (banner + interstitial, UMP consent, ATT)
- Play Console: tài khoản **D_Monkey** ở `/console/u/1/` (tài khoản "mts studio" đã bị khoá — không dùng). App N5 id 4973817237859693440, N4 id 4974739520135758241.
- Ngôn ngữ store chính: Tiếng Việt (vi); danh mục EDUCATION / REFERENCE; tuổi 4+ (Apple), đối tượng 16+ (Play, tránh chính sách Families)
- Khóa bí mật nằm ở `D:\100.JLPT\_secrets` (ngoài repo) và GitHub Repository Secrets. Không bao giờ in mật khẩu/khóa vào chat hay repo.

## Cấu trúc repo
```
apps/<app>/config.json      APP, LEVEL, APP_NAME, STORE_NAME, BUNDLE_ID, VERSION, IOS_PROFILE,
                            ACCENT, ACCENT_DARK (0xAARRGGBB), ADMOB_APP_ID_*/ADMOB_BANNER_*/ADMOB_INTERSTITIAL_* (ANDROID/IOS)
apps/<app>/icons/android/   mipmap-* (ic_launcher + adaptive fg/bg/monochrome, anydpi-v26 xml)
apps/<app>/icons/ios/       icon-1024.png (không alpha)
apps/<app>/store/ios/       metadata/ (fastlane deliver) + screenshots/vi/0N_iphone69.png, 0N_ipad13.png
apps/<app>/store/android/   vi/{title,short_description,full_description}.txt, changelogs/default.txt,
                            images/{icon.png 512, featureGraphic.png 1024x500, phoneScreenshots/N.png}
lib/data/kanji_<app>.dart   dữ liệu; đăng ký trong lib/data/levels.dart (switch AppConfig.id)
lib/app_config.dart         đọc String/int.fromEnvironment từ --dart-define-from-file
docs/<app>/                 index.html + privacy-policy.html (GitHub Pages /docs; N5 dùng docs/ gốc)
tools/configure_native.py <app>   đặt bundle ID, tên, AdMob App ID, chép icon vào android/ ios/
tools/app_info.py, write_export_options.py, check_metadata.py
```
Build/chạy: `python tools/configure_native.py <app>` rồi `flutter run --dart-define-from-file=apps/<app>/config.json`. Sau khi chạy app khác, chạy lại `configure_native.py n5` trước khi commit.

## Quy trình thêm app mới (vd N3)
Tạo task list theo các bước dưới.

### A. Code và nội dung (Claude tự làm)
1. Lấy bản mới nhất: `git fetch https://github.com/hainc08/jlptkanjin5.git main` (repo public). Kiểm tra trạng thái thư mục D: qua device_bash (`git log`, `git status`). Working tree trên D: thường có thay đổi android/ cục bộ do configure_native — **không reset/checkout**; chỉ `git add` đúng file mình sửa. Claude không push được GitHub (chưa cài Claude GitHub App, API ghi bị chặn) → commit cục bộ, người dùng push.
2. Chép `apps/n4` → `apps/n3`, sửa `config.json`: APP, LEVEL, tên, BUNDLE_ID, VERSION `1.0.0`, IOS_PROFILE, màu nhấn mới (mỗi app một màu); để trống mã AdMob cho tới bước B.
3. Dữ liệu `lib/data/kanji_n3.dart`: `Kanji('字', 'HÁN VIỆT', 'nghĩa tiếng Việt', 'On、On', 'kun(okurigana)')`. Loại chữ đã có ở các cấp thấp hơn. Kiểm tra bằng script: không trùng chữ, không trùng nghĩa, có Hán Việt và On. Thêm `'n3' => kanjiN3` vào `levels.dart` và thêm vào `test/widget_test.dart`.
4. Ảnh: sinh lại bằng bộ sinh HTML + Playwright (Noto Sans CJK JP + Inter): đổi màu, ví dụ chữ, tên app, số chữ; xuất iPhone 6.9" 1320×2868, iPad 13" 2064×2752, Play phone 1080×1920, feature graphic 1024×500, icon 1024 (iOS không alpha), 512 (Play) và mipmap. Xem bản ghép thử trước khi chép vào `apps/n3/`.
5. Mô tả store: chép từ app trước, đổi cấp/số chữ/đối tượng; keywords ≤100 byte, phân cách bằng dấu phẩy không cách; privacy_url `https://hainc08.github.io/jlptkanjin5/n3/privacy-policy.html`, support_url `.../n3/`. Tạo `docs/n3/` bằng cách thay chữ từ docs gốc. Chạy `python3 tools/check_metadata.py`.
6. Thêm `n3` vào ô chọn `app` trong `.github/workflows/release.yml` và matrix `ci.yml`.
7. Chạy thử `configure_native.py n3` rồi `n5`; xác nhận android/ ios/ trở về như cũ. Commit (tác giả haimv <hainc08@gmail.com>).
8. Đồng bộ về D: bằng `git bundle create … <base>..main` → device_commit_files vào `D:\100.JLPT\_archive` → device_bash `git pull --ff-only ../x.bundle main` (cần xin quyền xoá thư mục `D:\100.JLPT` mỗi phiên vì git xoá file lock; nếu chưa có quyền, đổi tên `.git/*.lock` còn sót thành `.git/stale-*` chứ đừng để lại). Các file chỉ khác ký tự xuống dòng CRLF là bình thường. Nhắc người dùng `git push`.

### B. Tài khoản store (Claude thao tác trình duyệt, người dùng đã đăng nhập)
1. **AdMob**: thêm 2 app (Android, iOS) chưa lên store → 4 ad unit (Banner, Interstitial mỗi nền tảng) → điền mã vào `config.json`. Gán thông điệp GDPR + IDFA explainer đã có cho 2 app mới.
2. **Apple Developer**: Identifiers → App ID `com.manabihub.kanjin3` → Profiles → App Store Connect profile tên `Kanji N3 AppStore` dùng chứng chỉ Apple Distribution có sẵn (không tạo chứng chỉ mới).
3. **App Store Connect**: New App (iOS, tên STORE_NAME, ngôn ngữ chính Vietnamese, SKU `kanjin3`). Gõ phím thay vì form_input cho ô tên/SKU. Điền App Privacy (Device ID, Advertising Data, Coarse Location: Third-Party Advertising, tracking Yes, linked No; Other Diagnostic Data: tracking No) rồi Publish; Age Rating tất cả None → 4+; giá $0, availability tất cả quốc gia; content rights: không dùng nội dung bên thứ ba.
4. **Play Console**: tạo app (vi, App, Free). App content: privacy URL, Ads Yes, Advertising ID (Advertising), app access không giới hạn, Government/Financial/Health No, target audience 16–17 và 18+, Data safety như app trước (Device IDs, App interactions, Crash logs/Diagnostics, Approximate location). Các ô cam kết pháp lý và bảng IARC: **để người dùng tự tick/điền**.
5. **Service account**: dùng lại `manabihub-play-ci`; người dùng tự bấm cấp quyền cho app mới trong Users and permissions.

### C. Phát hành
1. Secrets GitHub dùng chung, không cần thêm (cùng keystore upload Android, chứng chỉ P12 iOS, ASC API key, PLAY_SERVICE_ACCOUNT_JSON).
2. Lần đầu: Actions → Release → app=n3 (hoặc đẩy tag `n3-v1.0.0`). Biến `PLAY_RELEASE_STATUS=draft` khi app Play chưa từng phát hành. Nếu Play chưa có bản nào, tải artifact `n3-release-aab` và upload tay vào Internal testing.
3. iOS lên TestFlight tự động. Gửi review: Run workflow → app=n3, platform=ios, tick submit_review.
4. Play: closed testing (12 tester × 14 ngày với tài khoản cá nhân mới) trước Production; rồi submit_review platform=android.
5. Thử nghiệm khép kín: gắn Google Group tester (người dùng tự tạo group, vd `manabihub-testers@googlegroups.com`) vào track closed của mọi app; không tự tạo tài khoản tester giả.
6. Sau khi lên store: liên kết app trong AdMob, kiểm tra app-ads.txt.

## Build trên máy Windows (khi cần kiểm tra thật)
- Flutter của người dùng: `C:\Users\admin\develop\bin`. Claude không gõ được vào terminal (computer use cấp terminal/Explorer ở mức chỉ click) → viết file `.bat` (dùng `cd /d "%~dp0"`, ghi log vào `_build\build.log`) cho người dùng nhấp đúp, rồi đọc log qua device_bash.
- Python Windows in tiếng Việt ra console cp1252 sẽ lỗi `UnicodeEncodeError` → `print` trong script chạy trên Windows chỉ dùng ASCII.
- Gradle lỗi *Could not close incremental caches* khi project ở ổ D: còn pub cache ở C: → thêm `kotlin.incremental=false` vào `android/gradle.properties`.
- Container không cài được Flutter (storage.googleapis.com bị chặn). Muốn type-check trước: clone flutter stable từ GitHub, tự ráp `sky_engine` (copy `engine/src/flutter/lib/ui` + `_embedder.yaml` trỏ về Dart SDK lấy từ conda-forge `dart-sdk`), lấy package phụ thuộc từ các repo GitHub dart-lang/*, viết `.dart_tool/package_config.json` tay rồi `dart analyze`.

## Lỗi đã gặp
- keytool hiện `????` (máy tiếng Nhật): thêm `-J-Duser.language=en` và `-dname`.
- "Tag number over 30" / "keystore password was incorrect": secret base64 hoặc mật khẩu sai; secrets phải là Repository secrets, không phải Environment.
- deliver báo thiếu contentRightsDeclaration / pricing: đặt trong App Store Connect trước.
- Tag phải khớp VERSION trong config.json, nếu không job setup báo lỗi.
- Các thao tác cam kết pháp lý, mời người dùng, cấp quyền trên console: hệ thống chặn Claude, hướng dẫn người dùng tự bấm.