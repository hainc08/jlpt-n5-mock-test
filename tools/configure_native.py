#!/usr/bin/env python3
"""Cấu hình android/ và ios/ (do `flutter create` sinh ra) cho một app trong apps/.

    python3 tools/configure_native.py n4     (hoặc đặt biến môi trường APP=n4)

Không truyền gì thì cấu hình app n5. Chạy lại bao nhiêu lần cũng được (idempotent),
dùng cả ở máy bạn lẫn trên CI. Đọc apps/<app>/config.json để:
- đặt tên hiển thị, applicationId / bundle ID
- khai báo <queries> TTS_SERVICE (Android 11+ cần để flutter_tts tìm engine đọc)
- bật ký bản phát hành bằng android/key.properties (CI tự tạo, không commit)
- chép icon của app (apps/<app>/icons) và fastlane (tools/fastlane) vào android/ ios/
"""

import json
import os
import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("APP")) or "n5"
APP_DIR = ROOT / "apps" / APP
if not (APP_DIR / "config.json").exists():
    sys.exit(f"Không thấy apps/{APP}/config.json")
CFG = json.loads((APP_DIR / "config.json").read_text(encoding="utf-8"))

APP_ID = CFG["BUNDLE_ID"]
APP_NAME = CFG["APP_NAME"]
SHORT_NAME = CFG.get("SHORT_NAME") or APP_NAME


def log(msg: str) -> None:
    print(f"[configure_native] {msg}")


def patch_android() -> None:
    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if manifest.exists():
        s = manifest.read_text(encoding="utf-8")
        s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', s, count=1)
        if "android.permission.INTERNET" not in s:
            # Bản release cần quyền mạng để tải đề mới từ GitHub Pages.
            s = re.sub(r"(<manifest[^>]*>\r?\n)", r'\1    <uses-permission android:name="android.permission.INTERNET"/>\n', s, count=1)
        if "TTS_SERVICE" not in s:
            tts = ('        <intent>\n'
                   '            <action android:name="android.intent.action.TTS_SERVICE"/>\n'
                   '        </intent>\n')
            if "<queries>" in s:
                s = s.replace("<queries>\n", "<queries>\n" + tts, 1)
            else:
                s = s.replace("</manifest>", "    <queries>\n" + tts + "    </queries>\n</manifest>")
        manifest.write_text(s, encoding="utf-8")

    for name in ("build.gradle.kts", "build.gradle"):
        g = ROOT / "android/app" / name
        if not g.exists():
            continue
        s = g.read_text(encoding="utf-8")
        s = re.sub(r'applicationId\s*=?\s*"[^"]+"',
                   lambda m: f'applicationId = "{APP_ID}"' if "=" in m.group(0) else f'applicationId "{APP_ID}"',
                   s, count=1)
        if name.endswith(".kts") and "keystoreProperties" not in s:
            s = _enable_release_signing(s)
        g.write_text(s, encoding="utf-8")

    # Kotlin incremental cache lỗi trên Windows khi project và pub cache khác ổ đĩa.
    props = ROOT / "android/gradle.properties"
    if props.exists():
        p = props.read_text(encoding="utf-8")
        if "kotlin.incremental" not in p:
            props.write_text(p.rstrip() + "\nkotlin.incremental=false\n", encoding="utf-8")

    src = APP_DIR / "icons/android"
    res = ROOT / "android/app/src/main/res"
    if src.exists() and res.exists():
        for d in src.iterdir():
            shutil.copytree(d, res / d.name, dirs_exist_ok=True)
        log(f"Icon Android: chép từ apps/{APP}/icons/android")

    _copy_fastlane("android")
    log(f"Android: {APP_ID} · {APP_NAME}")


def _enable_release_signing(g: str) -> str:
    """Thêm khai báo ký release (đọc android/key.properties). Không có file thì vẫn ký debug."""
    header = "import java.util.Properties\nimport java.io.FileInputStream\n\n"
    loader = (
        "\n// Khóa ký bản phát hành: android/key.properties (CI tự tạo, không commit).\n"
        "val keystoreProperties = Properties()\n"
        'val keystorePropertiesFile = rootProject.file("key.properties")\n'
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    signing = (
        "android {\n"
        "    signingConfigs {\n"
        '        create("release") {\n'
        '            keyAlias = keystoreProperties["keyAlias"] as String?\n'
        '            keyPassword = keystoreProperties["keyPassword"] as String?\n'
        '            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }\n'
        '            storePassword = keystoreProperties["storePassword"] as String?\n'
        "        }\n"
        "    }\n"
    )
    g = header + g
    g = g.replace("\nandroid {\n", "\n" + loader + signing, 1)
    return g.replace(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") '
        'else signingConfigs.getByName("debug")',
    )


def patch_ios() -> None:
    plist = ROOT / "ios/Runner/Info.plist"
    if not plist.exists():
        log("Bỏ qua iOS (chưa có thư mục ios/).")
        return
    s = plist.read_text(encoding="utf-8")
    s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{SHORT_NAME}\g<2>", s)
    if "ITSAppUsesNonExemptEncryption" not in s:
        s = s.replace("</dict>\n</plist>", "\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n</dict>\n</plist>")
    plist.write_text(s, encoding="utf-8")

    pbx = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if pbx.exists():
        s = pbx.read_text(encoding="utf-8")
        s = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = [^;]*RunnerTests;", f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID}.RunnerTests;", s)
        s = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*RunnerTests)[^;]+;", f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID};", s)
        pbx.write_text(s, encoding="utf-8")

    icons = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    src = APP_DIR / "icons/ios"
    if icons.exists() and src.exists():
        for f in src.iterdir():
            shutil.copy(f, icons / f.name)
        log(f"Icon iOS: chép từ apps/{APP}/icons/ios")

    _copy_fastlane("ios")
    log(f"iOS: {APP_ID} · {SHORT_NAME}")


def _copy_fastlane(platform: str) -> None:
    """Fastlane dùng chung cho mọi app nằm ở tools/fastlane/<nền tảng>; chép vào thư mục nền tảng vừa sinh."""
    src = ROOT / "tools/fastlane" / platform
    dst = ROOT / platform / "fastlane"
    if src.exists() and (ROOT / platform).exists():
        shutil.copytree(src, dst, dirs_exist_ok=True)


if __name__ == "__main__":
    log(f"App: {APP} ({APP_ID})")
    patch_android()
    patch_ios()
