# Hướng dẫn phát hành – app JLPT Thi Thử (ManabiHub)

Repo: `https://github.com/hainc08/jlpt-n5-mock-test`. **Mỗi cấp N5…N1 là một app riêng** (bundle ID, tên, icon,
listing riêng) nhưng chung một mã nguồn `lib/` và chung một bộ CI/CD. Làm theo đúng khuôn của repo Kanji
(`hainc08/jlptkanjin5`, xem `RELEASE.md` ở đó cho phần tài khoản store).

| App | Thư mục | Bundle ID / package |
|---|---|---|
| JLPT N5 Thi Thử | `apps/n5` | `com.manabihub.jlptn5mock` |
| N4 … N1 | `apps/n4` … `apps/n1` | `com.manabihub.jlpt<cấp>mock` (thêm khi có nội dung đề) |

```
apps/<app>/config.json      APP, LEVEL, APP_NAME, SHORT_NAME, STORE_NAME, BUNDLE_ID, VERSION, IOS_PROFILE, ADMOB_*
apps/<app>/icons/           android/mipmap-*/ic_launcher.png, ios/Icon-App-*.png
apps/<app>/store/ios/       metadata/ (fastlane deliver) + screenshots/   (chưa có → bước metadata bị bỏ qua)
apps/<app>/store/android/   vi/{title,short_description,full_description}.txt, changelogs/, images/
assets/exams/<level>/       đề đóng sẵn của cấp (đăng ký trong pubspec.yaml)
tools/configure_native.py   <app>: đặt bundle ID, tên, icon, quyền, ký release; chép tools/fastlane vào android/ ios/
tools/fastlane/{android,ios}  Fastfile + Appfile dùng chung cho mọi app (đọc apps/$APP/config.json)
tools/app_info.py, write_export_options.py, check_metadata.py   dùng chung
.github/workflows/ci.yml      CI: tự lấy danh sách app từ apps/*/config.json
.github/workflows/release.yml build + upload + gửi review, chọn app bằng tag hoặc ô "app"
```

`android/` và `ios/` **không commit**: CI (và máy bạn) sinh bằng `flutter create` rồi chạy `configure_native.py <app>`.

Chạy thử một app trên máy:
```
python tools/configure_native.py n5
flutter run --dart-define-from-file=apps/n5/config.json
```

## 1. GitHub Secrets / Variables (dùng chung mọi app)
Secrets của GitHub **không tự chia sẻ giữa các repo**. Repo này cần dán lại cùng bộ secret với repo Kanji
(cùng keystore upload Android, cùng chứng chỉ iOS, cùng ASC API key, cùng service account Play).
Settings → Secrets and variables → Actions → **Repository secrets** (không phải Environment):

| Secret | Giá trị |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | base64 của `upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` · `ANDROID_KEY_PASSWORD` · `ANDROID_KEY_ALIAS` | mật khẩu và alias của keystore |
| `PLAY_SERVICE_ACCOUNT_JSON` | nội dung file JSON service account (`manabihub-play-ci`) |
| `ASC_KEY_ID` · `ASC_ISSUER_ID` · `ASC_KEY_P8_BASE64` | App Store Connect API key |
| `IOS_DIST_CERT_P12_BASE64` · `IOS_DIST_CERT_PASSWORD` | chứng chỉ Apple Distribution (.p12) |

Variables: `PLAY_RELEASE_STATUS=draft` khi app Play chưa từng phát hành (xoá sau lần đầu); `APPLE_TEAM_ID` không bắt buộc
(mặc định `SLR7396ZXZ`). Khoá thật nằm ở `D:\100.JLPT\_secrets`; không bao giờ commit hay in ra chat.

## 2. Thêm một cấp mới (vd N4)
1. Chép `apps/n5` → `apps/n4`; sửa `config.json` (APP, LEVEL, APP_NAME, SHORT_NAME, STORE_NAME, BUNDLE_ID `com.manabihub.jlptn4mock`, VERSION `1.0.0`, IOS_PROFILE `JLPT N4 Mock AppStore`; để trống AdMob tới khi tạo xong). Thay icon trong `apps/n4/icons/`.
2. Nội dung: `tools/content/n4_NN.py`, `assets/exams/n4/`, khai báo trong `pubspec.yaml`; luật chấm/cấu trúc theo cấp (xem skill `manabihub-mock-test`).
3. **CI tự nhận** `apps/n4` (không sửa `ci.yml`). Chỉ cần thêm `n4` vào danh sách `options` của ô `app` trong `release.yml` (nếu chưa có).
4. Việc tay cho bundle ID mới (một lần): AdMob (2 app + 4 ad unit), Apple App ID + profile `JLPT N4 Mock AppStore`, app trên App Store Connect (SKU `jlptn4mock`), app trên Play Console, cấp quyền service account cho app mới, upload AAB đầu tiên bằng tay vào Internal testing. Secrets **không cần thêm**.
5. Mọi bảng khai báo (App Privacy, Data safety, Age rating) trả lời như repo Kanji (cùng AdMob).

## 3. Mỗi lần phát hành
1. Sửa `VERSION` trong `apps/<app>/config.json` (build number do CI tự đánh).
2. Ghi changelog vào `apps/<app>/store/android/vi/changelogs/default.txt` và `…/store/ios/metadata/vi/release_notes.txt`.
3. Đẩy tag `<app>-v<VERSION>` (phải khớp `config.json`):
   ```
   git tag n5-v1.0.0
   git push origin n5-v1.0.0
   ```
   → iOS lên **TestFlight**, Android lên **Internal testing**.
4. Test trên máy thật.
5. Actions → **Release** → Run workflow → chọn **app** → tick **submit_review** → Apple review + Google Production.
