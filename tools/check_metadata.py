#!/usr/bin/env python3
"""Kiểm tra độ dài nội dung store (apps/*/store) trước khi upload."""
import glob
import os
import sys

LIMITS = {
    # App Store
    "name.txt": 30, "subtitle.txt": 30, "keywords.txt": 100,
    "description.txt": 4000, "promotional_text.txt": 170, "release_notes.txt": 4000,
    # Google Play
    "title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000,
    "default.txt": 500,
}

bad = 0
for f in sorted(glob.glob("apps/*/store/**/*.txt", recursive=True)):
    name = os.path.basename(f)
    if name not in LIMITS:
        continue
    text = open(f, encoding="utf-8").read().strip()
    n = len(text)
    status = "OK  "
    if n == 0:
        status, bad = "TRỐNG", bad + 1
    elif n > LIMITS[name]:
        status, bad = "DÀI ", bad + 1
    if name == "keywords.txt" and (", " in text or len(text.encode()) > 100):
        # Giữ keywords dưới 100 byte cho chắc (tiếng Việt có dấu tốn 2–3 byte/ký tự).
        status, bad = "KW  ", bad + 1
    print(f"{status} {n:>5}/{LIMITS[name]:<5} {f}")

sys.exit(1 if bad else 0)
