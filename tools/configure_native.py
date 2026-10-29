"""Cấu hình thư mục native sau khi `flutter create` sinh android/ ios/.

- Tên hiển thị, applicationId / bundle id
- Khai báo <queries> TTS_SERVICE (Android 11+ cần để flutter_tts tìm engine đọc)
- Copy icon app

Chạy: python3 tools/configure_native.py
"""

import pathlib
import re
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent

APP_NAME = "JLPT N5 Thi Thử"
SHORT_NAME = "N5 Thi Thử"
APP_ID = "com.manabihub.jlptn5mock"


def patch_android():
    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if manifest.exists():
        s = manifest.read_text(encoding="utf-8")
        s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', s, count=1)
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
        if g.exists():
            s = g.read_text(encoding="utf-8")
            s = re.sub(r'applicationId\s*=?\s*"[^"]+"',
                       lambda m: f'applicationId = "{APP_ID}"' if "=" in m.group(0) else f'applicationId "{APP_ID}"',
                       s, count=1)
            g.write_text(s, encoding="utf-8")

    # Kotlin incremental cache lỗi trên Windows khi project và pub cache khác ổ đĩa.
    props = ROOT / "android/gradle.properties"
    if props.exists():
        p = props.read_text(encoding="utf-8")
        if "kotlin.incremental" not in p:
            props.write_text(p.rstrip() + "\nkotlin.incremental=false\n", encoding="utf-8")

    src = ROOT / "native/icons/android"
    res = ROOT / "android/app/src/main/res"
    if res.exists():
        for d in src.iterdir():
            shutil.copy(d / "ic_launcher.png", res / d.name / "ic_launcher.png")


def patch_ios():
    plist = ROOT / "ios/Runner/Info.plist"
    if plist.exists():
        s = plist.read_text(encoding="utf-8")
        s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{SHORT_NAME}\g<2>", s)
        plist.write_text(s, encoding="utf-8")
    pbx = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if pbx.exists():
        s = pbx.read_text(encoding="utf-8")
        s = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = [^;]*RunnerTests;", f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID}.RunnerTests;", s)
        s = re.sub(r"PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*RunnerTests)[^;]+;", f"PRODUCT_BUNDLE_IDENTIFIER = {APP_ID};", s)
        pbx.write_text(s, encoding="utf-8")
    icons = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    if icons.exists():
        for f in (ROOT / "native/icons/ios").iterdir():
            shutil.copy(f, icons / f.name)


if __name__ == "__main__":
    patch_android()
    patch_ios()
    print("Native configured:", APP_ID)
