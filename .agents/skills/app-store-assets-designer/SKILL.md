---
name: "app-store-assets-designer"
description: "Thiết kế màn hình app (web, iOS, Android) bằng Claude Design hoặc Stitch rồi xuất bộ icon và screenshot đúng chuẩn App Store và Google Play."
---

# App Store Assets Designer

Mục tiêu: từ một brief app, tạo (1) thiết kế màn hình cho web / iOS / Android trong Claude Design hoặc Stitch, (2) bộ icon đầy đủ cho cả 3 nền tảng, (3) screenshot marketing + feature graphic đúng kích thước để upload lên App Store Connect và Google Play Console. Kết quả cuối là một file .zip có cấu trúc thư mục sẵn sàng upload.

## Bước 0 — Thu thập brief (hỏi 1 lần, gộp bằng AskUserQuestion nếu có)
- Tên app, mô tả 1 câu, đối tượng người dùng
- Nền tảng cần: iOS / Android / Web (multi-select); có hỗ trợ iPad / tablet không
- 3–6 màn hình chính (vd: Onboarding, Home, Chi tiết, Thanh toán, Profile)
- Màu thương hiệu, font, logo (nếu có file thì đính kèm)
- Ngôn ngữ caption screenshot (vd: vi, en, ja) — mỗi ngôn ngữ = 1 bộ screenshot riêng
- 3–6 thông điệp marketing cho caption screenshot
Nếu người dùng không trả lời: tự chọn mặc định hợp lý và ghi rõ ở đầu kết quả.

## Bước 1 — Kiểm tra quy cách hiện hành
Quy cách store thay đổi theo thiết bị mới. Mỗi lần chạy, WebSearch nhanh: "App Store Connect screenshot specifications" và "Google Play preview assets requirements". Nếu kết quả khác bảng dưới, dùng số liệu mới và báo người dùng.

Bảng tham chiếu (kiểm tra 10/2026):
| Asset | Kích thước | Ghi chú |
|---|---|---|
| iPhone 6.9" | 1320×2868 (hoặc 1290×2796) | Bắt buộc; Apple tự scale xuống máy nhỏ |
| iPad 13" | 2064×2752 (hoặc 2048×2732) | Chỉ khi app chạy trên iPad |
| App Store icon | 1024×1024 PNG | KHÔNG trong suốt, không bo góc |
| Play phone screenshot | 1080×1920 (9:16) | 2–8 ảnh, cạnh 320–3840px, không alpha |
| Play tablet 7" / 10" | 1200×1920 / 1600×2560 | Nếu hỗ trợ tablet |
| Play feature graphic | 1024×500 | JPEG hoặc PNG 24-bit, không alpha, bắt buộc |
| Play hi-res icon | 512×512 | PNG 32-bit CÓ alpha, ≤1MB, vuông đủ (Play tự bo góc) |
| Apple screenshot | tối đa 10 ảnh/kích thước, ≤10MB, RGB, không trong suốt | |

## Bước 2 — Thiết kế màn hình trong Claude Design
1. Gọi Artifact action "list" scope "types". Nếu có Design System đánh dấu default → dùng nó. Nếu người dùng muốn bộ nhận diện mới → tạo từ type Design System trước (màu, font, spacing, component).
2. Tạo thiết kế từ type **Design** (không tự viết HTML tay khi type có sẵn). Làm theo SKILL.md mà type trả về.
3. Tổ chức thành các khung:
   - iOS: khung 393×852pt (iPhone 15/16/17), theo Human Interface Guidelines — tab bar dưới, large title, SF-style typography, safe area cho Dynamic Island.
   - Android: khung 412×915dp, theo Material 3 — top app bar, navigation bar, FAB nếu hợp, bo góc M3.
   - Web: desktop 1440×900 + mobile 390×844, responsive.
4. Dùng dữ liệu mẫu thực tế (tên, số liệu, ảnh minh hoạ trung tính) — không lorem ipsum, không ảnh người nổi tiếng, không logo/thương hiệu của bên thứ ba.
5. Gửi bản nháp sớm để người dùng góp ý trước khi xuất asset.

## Bước 2b — Thiết kế bằng Stitch (khi người dùng chọn Stitch hoặc đã có design system trên Stitch)
- Công cụ: `mcp__…stitch__*` (trên Claude Desktop cấu hình qua `mcp-remote` + header `X-Goog-Api-Key`; không in API key ra chat). Bắt đầu bằng `list_projects` / `list_design_systems`.
- Tạo màn hình: `generate_screen_from_text(projectId, prompt, designSystem="assets/<id>", deviceType="MOBILE")`. Prompt mô tả đầy đủ từng khối giao diện, dữ liệu mẫu thật, ngôn ngữ hiển thị.
- Mỗi lần sinh mất 1–3 phút; lời gọi thường báo hết giờ sau 60s nhưng Stitch vẫn sinh tiếp. **Không gọi lại ngay** (sẽ ra bản trùng): chờ rồi kiểm tra bằng `get_screen`. `list_screens` có thể trả về rỗng — ghi lại id màn hình từ mỗi kết quả trả về. Có thể gọi song song nhiều màn.
- Lấy ảnh/HTML: `download_file(name)` với `screenshot.name` / `htmlCode.name` (không tải `downloadUrl` trực tiếp).
- Đã có của ManabiHub: design system **Zen Vermilion Study** (`assets/3c19487b2be3403ab24a19a569bfbca1`; vermilion #B9343F, xanh tre #15803D, nền washi #F7F7F4, Plus Jakarta Sans + Noto Sans JP), project "JLPT N5 Thi Thử" `13594785216952493333`.
- Khi dựng app thật từ thiết kế: chuyển token màu/chữ/bo góc của design system thành file theme của app (vd `lib/theme.dart`) thay vì chép HTML.

## Bước 3 — Thiết kế icon master
- Vẽ icon dạng SVG 1024×1024 (trong Design hoặc file SVG riêng): hình đơn giản, đọc rõ ở 48px, không chữ nhỏ.
- Tạo thêm 2 lớp cho Android adaptive icon: foreground (nội dung nằm trong vùng an toàn đường kính 66% ở giữa) và background (màu/hoạ tiết).
- Bản monochrome (một màu) cho Android themed icon.
- Icon có chữ Hán/Nhật (vd con dấu 試, chữ Kanji): vẽ bằng Pillow với font CJK **mặt chữ JP** — trong file `.ttc` Noto CJK chọn đúng index có tên chứa "JP" (đọc bằng `fontTools.ttLib.TTCollection`), nếu không glyph sẽ ra kiểu Trung Quốc. Kiểm tra bằng cách Read ảnh 1024 trước khi sinh các cỡ.

## Bước 4 — Dựng screenshot marketing
Với mỗi kích thước store, tạo 1 file HTML/template riêng có viewport đúng pixel:
- Nền gradient/màu thương hiệu, caption lớn ở trên (≤ 2 dòng, cỡ chữ ≥ 6% chiều rộng), màn hình app đặt trong khung thiết bị vẽ bằng CSS (tự vẽ, không dùng mockup có logo Apple/Google).
- Screenshot đầu tiên = giá trị cốt lõi của app.
- Feature graphic 1024×500: logo + tagline, nội dung chính trong vùng giữa; KHÔNG dùng chữ "#1", "Best", "Top", "Free", "New", số lượt tải, nút "Download" hay badge store.
- Đa ngôn ngữ: tách caption ra JSON `captions/{lang}.json`, render lặp theo ngôn ngữ.

## Bước 5 — Xuất file bằng Bash
Cài đặt: `pip install playwright pillow cairosvg --break-system-packages && python -m playwright install chromium`

Render HTML → PNG đúng pixel (`render.py`):
```python
import asyncio, sys, json
from playwright.async_api import async_playwright
# jobs: [{"html": "shots/ios_1.html", "out": "out/ios/iphone69/01.png", "w": 1320, "h": 2868}]
async def main(jobs):
    async with async_playwright() as p:
        b = await p.chromium.launch()
        for j in jobs:
            pg = await b.new_page(viewport={"width": j["w"], "height": j["h"]}, device_scale_factor=1)
            await pg.goto("file://" + __import__('os').path.abspath(j["html"]))
            await pg.wait_for_timeout(400)
            await pg.screenshot(path=j["out"], full_page=False, omit_background=False)
            await pg.close()
        await b.close()
asyncio.run(main(json.load(open(sys.argv[1]))))
```

Sinh toàn bộ icon từ master (`icons.py`):
```python
import cairosvg, os, json
from PIL import Image
def png(svg, size, out, alpha=True):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    cairosvg.svg2png(url=svg, write_to=out, output_width=size, output_height=size)
    if not alpha:
        im = Image.open(out).convert("RGBA"); bg = Image.new("RGB", im.size, (255,255,255))
        bg.paste(im, mask=im.split()[3]); bg.save(out)
M = "icon/master.svg"
# iOS (Xcode 15+ chấp nhận single-size 1024)
png(M, 1024, "out/ios/AppIcon.appiconset/icon-1024.png", alpha=False)
json.dump({"images":[{"filename":"icon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}, open("out/ios/AppIcon.appiconset/Contents.json","w"), indent=2)
png(M, 1024, "out/appstore/icon-1024.png", alpha=False)
# Android legacy + adaptive
for d, s in {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}.items():
    png(M, s, f"out/android/res/mipmap-{d}/ic_launcher.png")
    png("icon/foreground.svg", s*9//4, f"out/android/res/mipmap-{d}/ic_launcher_foreground.png")
    png("icon/background.svg", s*9//4, f"out/android/res/mipmap-{d}/ic_launcher_background.png")
os.makedirs("out/android/res/mipmap-anydpi-v26", exist_ok=True)
open("out/android/res/mipmap-anydpi-v26/ic_launcher.xml","w").write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n  <background android:drawable="@mipmap/ic_launcher_background"/>\n  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n  <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
png(M, 512, "out/playstore/icon-512.png", alpha=True)
# Web / PWA
for s, n in [(16,"favicon-16.png"),(32,"favicon-32.png"),(180,"apple-touch-icon.png"),(192,"icon-192.png"),(512,"icon-512.png")]:
    png(M, s, f"out/web/{n}", alpha=(n!="apple-touch-icon.png"))
Image.open("out/web/favicon-32.png").save("out/web/favicon.ico", sizes=[(16,16),(32,32),(48,48)])
```
Thêm `out/web/manifest.webmanifest` (name, icons 192/512 + 1 icon `purpose: maskable`, theme_color, background_color).

## Bước 6 — Kiểm tra tự động trước khi giao (`validate.py`)
```python
from PIL import Image; import glob, os
rules = {"out/appstore/iphone69/*.png": [(1320,2868),(1290,2796)], "out/appstore/ipad13/*.png": [(2064,2752),(2048,2732)],
         "out/playstore/phone/*.png": None, "out/playstore/feature-graphic.png": [(1024,500)], "out/playstore/icon-512.png": [(512,512)], "out/appstore/icon-1024.png": [(1024,1024)]}
for pat, sizes in rules.items():
    for f in glob.glob(pat):
        im = Image.open(f); ok = True
        if sizes and im.size not in sizes: ok=False; print("SAI KÍCH THƯỚC", f, im.size)
        if sizes is None and not (320 <= min(im.size) and max(im.size) <= 3840): ok=False; print("NGOÀI 320–3840", f)
        if "icon-512" not in f and im.mode in ("RGBA","LA"):
            im.convert("RGB").save(f); print("Đã bỏ alpha:", f)
        if os.path.getsize(f) > 8*1024*1024: print("QUÁ NẶNG", f)
        if ok: print("OK", f, im.size)
```
Mở xem (Read) ít nhất 1 ảnh mỗi loại để kiểm tra trực quan: chữ không bị cắt, caption đúng ngôn ngữ, không còn placeholder.
Caption/nội dung tiếng Nhật trong HTML: đặt `lang="ja"` và font Noto Sans CJK JP để Kanji hiện đúng kiểu Nhật; caption tiếng Việt cần font có đủ dấu (Plus Jakarta Sans, Inter, Be Vietnam Pro…).

## Bước 7 — Đóng gói và giao
Cấu trúc:
```
store-assets/
  appstore/  icon-1024.png, iphone69/{lang}/01..png, ipad13/{lang}/01..png
  playstore/ icon-512.png, feature-graphic.png, phone/{lang}/..., tablet7/, tablet10/
  ios/AppIcon.appiconset/        (kéo thả vào Xcode Assets.xcassets)
  android/res/mipmap-*/          (chép đè vào app/src/main/res)
  web/ favicon.ico, icons, manifest.webmanifest
  README.md  (bảng: file nào upload vào đâu)
```
Zip lại → SendUserFile. Tin nhắn cuối: 1–2 câu tóm tắt + link Design artifact để chỉnh tiếp. Đề xuất bước tiếp theo nếu có (vd: thêm ngôn ngữ, làm app preview video).

## Lưu ý
- Không dùng hình thiết bị/logo chính thức của Apple, Google; không vẽ nhân vật/thương hiệu có bản quyền.
- Screenshot phải phản ánh đúng app thật (Apple 2.3.3 / chính sách Play) — nếu app đã có bản build, ưu tiên dùng ảnh chụp thật làm nội dung trong khung. App Flutter: chạy `flutter run -d chrome` (hoặc máy ảo) ở kích thước điện thoại rồi chụp màn hình thật; ảnh từ Stitch chỉ là thiết kế, không dùng thay ảnh app thật.
- Khi người dùng sửa thiết kế trong Design artifact, đọc lại artifact rồi chạy lại Bước 4–7.