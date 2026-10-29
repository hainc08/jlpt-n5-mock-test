---
name: "flutter-store-release"
description: "Soạn nội dung gửi review và dựng fastlane + GitHub Actions để tự build, upload IPA/AAB của app Flutter lên App Store và Google Play."
---

# Flutter Store Release

Dùng cho app Flutter, người dùng làm việc trên Windows. Build và upload chạy trên GitHub Actions: Android trên máy ubuntu, iOS trên máy macos. Không cần máy Mac.
Skill này đi kèm `app-store-assets-designer`: icon và screenshot từ skill đó được chép vào thư mục metadata của fastlane.

## Nguyên tắc an toàn (bắt buộc)
- KHÔNG bao giờ yêu cầu người dùng dán khóa, mật khẩu, file .p8, .p12, .jks hay JSON service account vào chat. Người dùng tự thêm chúng vào GitHub → Settings → Secrets and variables → Actions.
- KHÔNG commit secret vào repo. Thêm các file nhạy cảm vào .gitignore.
- Gửi review là thao tác công khai, không rút lại được. Chỉ người dùng bấm chạy workflow với `submit_review = true`. Nếu Claude có quyền kích hoạt workflow, phải hỏi xác nhận rõ ràng trước.

## Bước 0 — Hỏi thông tin (gộp một lần)
- Tên app, bundle ID (iOS), package name (Android), Team ID Apple
- Ngôn ngữ store (vd: vi, en-US, ja)
- Tính năng chính; nhóm đối tượng; app có đăng nhập không (nếu có cần tài khoản demo cho Apple review: hỏi username, còn password để người dùng tự đặt vào secret DEMO_PASSWORD)
- URL chính sách quyền riêng tư và URL hỗ trợ (bắt buộc)
- App thu thập dữ liệu gì: tài khoản, vị trí, ảnh, analytics, quảng cáo, crash log...
- Repo GitHub của app (owner/repo). Nếu có: add_repo với access push, tạo nhánh `release-setup` và mở PR. Nếu push bị từ chối (403 — chưa cài Claude GitHub App, API ghi bị chặn): commit cục bộ, chuyển sang máy người dùng bằng `git bundle` + device_commit_files, người dùng tự `git push`. Nếu không có repo: giao file .zip.
- Repo chứa nhiều app (vd `apps/<app>/config.json` của ManabiHub): làm theo skill `manabihub-app-launch` — tag dạng `<app>-vX.Y.Z`, Fastfile đọc `ENV["APP"]`, workflow có input `app` và `platform`.

## Bước 1 — Soạn nội dung store
Viết theo từng ngôn ngữ, đúng giới hạn ký tự. Nội dung phải phản ánh đúng app; không dùng tên thương hiệu khác trong keywords; không ghi giá hay "#1", "best" trong tiêu đề.

App Store: `ios/fastlane/metadata/<locale>/` (locale dạng `vi`, `en-US`, `ja`)
| File | Giới hạn |
|---|---|
| name.txt | 30 |
| subtitle.txt | 30 |
| keywords.txt | 100, phân cách bằng dấu phẩy, không khoảng trắng, không lặp từ trong name |
| description.txt | 4000 |
| promotional_text.txt | 170 |
| release_notes.txt | 4000 |
| privacy_url.txt, support_url.txt, marketing_url.txt | URL |

`ios/fastlane/metadata/copyright.txt`, `primary_category.txt` (vd: PRODUCTIVITY)
`ios/fastlane/metadata/review_information/`: first_name.txt, last_name.txt, phone_number.txt (+84...), email_address.txt, demo_user.txt, notes.txt. File demo_password.txt KHÔNG commit; CI tạo nó từ secret.
notes.txt: hướng dẫn reviewer từng bước test các tính năng chính, giải thích quyền truy cập (camera, vị trí...) và tính năng cần phần cứng hay vùng địa lý đặc biệt.

Google Play: `android/fastlane/metadata/android/<locale>/` (locale dạng `vi-VN`, `en-US`, `ja-JP`)
| File | Giới hạn |
|---|---|
| title.txt | 30 |
| short_description.txt | 80 |
| full_description.txt | 4000 |
| changelogs/default.txt | 500 |
| images/icon.png | 512×512 |
| images/featureGraphic.png | 1024×500 |
| images/phoneScreenshots/1.png… | 2–8 ảnh |

Ảnh iOS: `ios/fastlane/screenshots/<locale>/01_xxx.png` (1320×2868, iPad 2064×2752).

Kiểm tra độ dài bằng script `tools/check_metadata.py`:
```python
import glob, os, sys
L = {"name.txt":30,"subtitle.txt":30,"keywords.txt":100,"description.txt":4000,"promotional_text.txt":170,"release_notes.txt":4000,
     "title.txt":30,"short_description.txt":80,"full_description.txt":4000,"default.txt":500}
bad = 0
for f in glob.glob("**/fastlane/metadata/**/*.txt", recursive=True):
    n = os.path.basename(f)
    if n in L:
        c = len(open(f, encoding="utf-8").read().strip())
        if c > L[n]: bad += 1; print(f"QUÁ DÀI {f}: {c}/{L[n]}")
        if c == 0: bad += 1; print(f"TRỐNG {f}")
sys.exit(1 if bad else 0)
```

## Bước 2 — Soạn câu trả lời cho các bảng khai báo làm tay
Các mục sau không gửi được bằng API key, người dùng điền tay MỘT lần trong console. Soạn sẵn câu trả lời vào một Docs artifact "Checklist khai báo store":
- Apple: App Privacy (loại dữ liệu, mục đích, có liên kết danh tính không, có tracking không), Age Rating, Export Compliance (thường: chỉ dùng mã hoá chuẩn HTTPS → thêm `ITSAppUsesNonExemptEncryption = false` vào Info.plist)
- Google: Data safety, Content rating (IARC), Target audience, Ads declaration, App access (tài khoản demo)

## Bước 3 — Tạo file cấu hình trong repo

### android/fastlane/Fastfile
```ruby
default_platform(:android)
platform :android do
  lane :internal do
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      json_key: "play.json",
      release_status: ENV.fetch("PLAY_RELEASE_STATUS", "completed")
    )
  end
  lane :production do
    upload_to_play_store(
      track: "internal", track_promote_to: "production",
      json_key: "play.json", skip_upload_aab: true,
      release_status: "completed"
    )
  end
end
```
App chưa từng phát hành → đặt biến repo `PLAY_RELEASE_STATUS=draft`.

### Ký app Android (android/app/build.gradle.kts)
```kotlin
import java.util.Properties
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties"); if (f.exists()) load(f.inputStream())
}
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
}
```
Nếu project còn dùng build.gradle (Groovy), viết bản Groovy tương đương. Chỉ sửa phần signing, giữ nguyên phần còn lại.

### ios/fastlane/Fastfile
```ruby
default_platform(:ios)
platform :ios do
  def asc_key
    app_store_connect_api_key(key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY_P8_BASE64"], is_key_content_base64: true)
  end
  lane :beta do
    upload_to_testflight(api_key: asc_key, ipa: ENV["IPA_PATH"], skip_waiting_for_build_processing: true)
  end
  lane :release do
    deliver(api_key: asc_key, app_version: ENV["APP_VERSION"], skip_binary_upload: true,
      overwrite_screenshots: true, submit_for_review: true, automatic_release: false, force: true,
      precheck_include_in_app_purchases: false,
      submission_information: { add_id_info_uses_idfa: false })
  end
end
```

### ios/ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>TEAM_ID</string>
  <key>signingStyle</key><string>manual</string>
  <key>provisioningProfiles</key><dict><key>BUNDLE_ID</key><string>TÊN_PROFILE</string></dict>
</dict></plist>
```
Trong `ios/Runner.xcodeproj/project.pbxproj`, cấu hình Release của target Runner phải là: CODE_SIGN_STYLE = Manual, DEVELOPMENT_TEAM, PROVISIONING_PROFILE_SPECIFIER = tên profile, CODE_SIGN_IDENTITY = "Apple Distribution". Sửa trực tiếp file, chỉ đụng vào config Release.

### .github/workflows/release.yml
```yaml
name: Release
on:
  push:
    tags: ['v*']
  workflow_dispatch:
    inputs:
      submit_review:
        description: 'Gửi review (iOS) và đẩy lên production (Android)'
        type: boolean
        default: false

jobs:
  android-build:
    if: ${{ !inputs.submit_review }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.3' }
      - run: gem install fastlane
      - name: Chuẩn bị khóa ký và service account
        env:
          KS: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          PLAY_JSON: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
        run: |
          echo "$KS" | base64 -d > android/app/upload-keystore.jks
          printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=%s\nstoreFile=upload-keystore.jks\n' \
            '${{ secrets.ANDROID_KEYSTORE_PASSWORD }}' '${{ secrets.ANDROID_KEY_PASSWORD }}' '${{ secrets.ANDROID_KEY_ALIAS }}' > android/key.properties
          echo "$PLAY_JSON" > android/play.json
      - run: python3 tools/check_metadata.py
      - run: flutter pub get
      - run: flutter build appbundle --release --build-number=${{ github.run_number }}
      - working-directory: android
        env: { PLAY_RELEASE_STATUS: '${{ vars.PLAY_RELEASE_STATUS }}' }
        run: fastlane internal

  ios-build:
    if: ${{ !inputs.submit_review }}
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - name: Cài chứng chỉ và provisioning profile
        env:
          P12: ${{ secrets.IOS_DIST_CERT_P12_BASE64 }}
          P12_PW: ${{ secrets.IOS_DIST_CERT_PASSWORD }}
          PROFILE: ${{ secrets.IOS_PROFILE_BASE64 }}
        run: |
          KC=$RUNNER_TEMP/build.keychain-db; KP=$(openssl rand -hex 16)
          echo "$P12" | base64 -d > $RUNNER_TEMP/cert.p12
          security create-keychain -p "$KP" $KC
          security set-keychain-settings -lut 21600 $KC
          security unlock-keychain -p "$KP" $KC
          security import $RUNNER_TEMP/cert.p12 -P "$P12_PW" -A -t cert -f pkcs12 -k $KC
          security set-key-partition-list -S apple-tool:,apple: -k "$KP" $KC
          security list-keychain -d user -s $KC
          for d in "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
            mkdir -p "$d"; echo "$PROFILE" | base64 -d > "$d/dist.mobileprovision"; done
      - run: flutter pub get
      - run: flutter build ipa --release --build-number=${{ github.run_number }} --export-options-plist=ios/ExportOptions.plist
      - working-directory: ios
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8_BASE64: ${{ secrets.ASC_KEY_P8_BASE64 }}
        run: IPA_PATH=$(ls $GITHUB_WORKSPACE/build/ios/ipa/*.ipa | head -1) fastlane beta

  android-submit:
    if: ${{ inputs.submit_review }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.3' }
      - run: gem install fastlane
      - env: { PLAY_JSON: '${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}' }
        run: echo "$PLAY_JSON" > android/play.json
      - working-directory: android
        run: fastlane production

  ios-submit:
    if: ${{ inputs.submit_review }}
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - env: { DEMO_PASSWORD: '${{ secrets.DEMO_PASSWORD }}' }
        run: |
          mkdir -p ios/fastlane/metadata/review_information
          printf '%s' "$DEMO_PASSWORD" > ios/fastlane/metadata/review_information/demo_password.txt
      - working-directory: ios
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8_BASE64: ${{ secrets.ASC_KEY_P8_BASE64 }}
        run: APP_VERSION=$(grep '^version:' ../pubspec.yaml | sed 's/version: *//; s/+.*//') fastlane release
```
App chỉ có một nền tảng → bỏ các job của nền tảng kia.

### Quyền mạng Android
Template Flutter chỉ khai báo `INTERNET` trong manifest debug/profile. App release cần mạng (tải dữ liệu, API) mà không dùng plugin tự thêm quyền (google_mobile_ads có thêm) → thêm `<uses-permission android:name="android.permission.INTERNET"/>` vào `android/app/src/main/AndroidManifest.xml`. App dùng flutter_tts trên Android 11+ cần thêm `<queries><intent><action android:name="android.intent.action.TTS_SERVICE"/></intent></queries>`.

### .gitignore (thêm)
```
android/key.properties
android/app/*.jks
android/play.json
ios/fastlane/metadata/review_information/demo_password.txt
*.p8
*.p12
*.mobileprovision
```

## Bước 4 — Hướng dẫn người dùng tạo secrets trên Windows
Đưa checklist sau, mỗi mục có lệnh PowerShell hoặc Git Bash. Người dùng tự thực hiện.

**Android**
1. Tạo keystore (keytool có sẵn trong JDK của Android Studio):
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   Dặn người dùng sao lưu file này và mật khẩu ở nơi an toàn: mất file là mất khả năng cập nhật app.
2. Chuyển sang base64 rồi copy vào clipboard (PowerShell):
   `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard`
   Dán vào secret ANDROID_KEYSTORE_BASE64. Thêm ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD, ANDROID_KEY_ALIAS.
3. Google Cloud: tạo service account và khóa JSON. Trong Play Console → Users and permissions: mời email của service account, cấp quyền phát hành cho app. Dán toàn bộ nội dung JSON vào secret PLAY_SERVICE_ACCOUNT_JSON.

**iOS (không cần Mac)**
1. App Store Connect → Users and Access → Integrations → tạo API key (vai trò App Manager). Ghi ASC_KEY_ID, ASC_ISSUER_ID. Mã hoá file .p8 sang base64 (lệnh như trên) → ASC_KEY_P8_BASE64.
2. Tạo chứng chỉ phân phối bằng openssl trong Git Bash:
   ```
   openssl req -new -newkey rsa:2048 -nodes -keyout dist.key -out dist.csr -subj "/emailAddress=EMAIL/CN=TÊN/C=VN"
   ```
   Upload dist.csr lên developer.apple.com → Certificates → Apple Distribution, tải file distribution.cer về, rồi:
   ```
   openssl x509 -inform DER -in distribution.cer -out dist.pem
   openssl pkcs12 -export -legacy -inkey dist.key -in dist.pem -out dist.p12
   ```
   Base64 file dist.p12 → IOS_DIST_CERT_P12_BASE64; mật khẩu đặt khi export → IOS_DIST_CERT_PASSWORD.
3. Developer portal: tạo App ID (bundle ID) và Provisioning Profile loại App Store, gắn với chứng chỉ trên. Tải về, base64 → IOS_PROFILE_BASE64. Ghi tên profile vào ExportOptions.plist.
4. Secret DEMO_PASSWORD (nếu app có đăng nhập).

## Bước 4b — Kiểm tra trước khi phát hành
- Luôn chạy `flutter analyze` + `flutter test` (và build thử) trước khi đánh tag. Không báo "đã test" nếu chưa chạy thật.
- Người dùng có Claude Code trên máy: để Claude Code chạy trực tiếp. Nếu chỉ có phiên cloud liên kết máy: viết file `.bat` (dùng `cd /d "%~dp0"`, log ra `_build\build.log`) để người dùng nhấp đúp, rồi đọc log qua device_bash.
- Lỗi đã gặp trên Windows:
  - Gradle *Could not close incremental caches* (project ở ổ D:, pub cache ở C:) → `kotlin.incremental=false` trong `android/gradle.properties`.
  - Script Python in tiếng Việt ra console cp1252 → `UnicodeEncodeError`; chỉ in ASCII.
  - keytool hiện `????` trên máy tiếng Nhật → thêm `-J-Duser.language=en` và `-dname`.
  - Secret báo "Tag number over 30" / "keystore password was incorrect" → base64 hoặc mật khẩu sai; phải là Repository secret, không phải Environment secret.

## Bước 5 — Việc làm tay một lần trước lần chạy đầu
- Apple Developer Program (trả phí theo năm); tạo app record trong App Store Connect với đúng bundle ID.
- Google Play Console (phí một lần); tạo app; **upload AAB đầu tiên bằng tay** (API không tạo được app mới).
- Tài khoản Play cá nhân mới: phải chạy closed testing với số tester tối thiểu trong số ngày tối thiểu trước khi lên production (10/2026: 12 tester × 14 ngày — WebSearch để kiểm tra lại). Cách gọn: người dùng tạo một Google Group tester rồi gắn group vào track closed của mọi app. Không tạo tài khoản tester giả.
- Mời service account vào Play Console (Users and permissions), tick cam kết pháp lý, bảng IARC, content rights trên App Store Connect: hệ thống chặn Claude bấm — hướng dẫn người dùng tự làm.
- Điền các bảng khai báo theo checklist ở Bước 2.

## Bước 6 — Quy trình phát hành
1. Tăng `version` trong pubspec.yaml (vd 1.1.0+1; build number do CI tự đánh bằng run_number). Cập nhật release_notes.txt và changelogs/default.txt.
2. `git tag v1.1.0 && git push origin v1.1.0` → CI build và upload: iOS lên TestFlight, Android lên track internal.
3. Người dùng test bản TestFlight và internal.
4. GitHub → Actions → Release → Run workflow → tick `submit_review` → iOS gửi review, Android được promote lên production (Google tự review).

## Bước 7 — Khi bị từ chối
Người dùng dán lý do từ chối (Resolution Center hoặc email Play) vào chat. Claude phân loại lý do theo guideline tương ứng, đề xuất cách sửa (code, metadata hoặc ảnh), soạn câu trả lời gửi reviewer ngắn gọn và lịch sự (tiếng Anh), rồi cập nhật file metadata.

## Giao kết quả
- Có repo: mở PR với toàn bộ file, mô tả PR có checklist secrets.
- Không có repo: zip toàn bộ (giữ đúng đường dẫn) → SendUserFile, kèm Docs artifact "Checklist khai báo store".
- Chạy `tools/check_metadata.py` trước khi giao.