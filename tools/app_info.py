#!/usr/bin/env python3
"""In cấu hình của một app dạng KEY=VALUE (dùng cho $GITHUB_OUTPUT / $GITHUB_ENV).

    python3 tools/app_info.py n4            # in toàn bộ
    python3 tools/app_info.py n4 VERSION    # in một giá trị
    python3 tools/app_info.py --list        # liệt kê các app
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

if len(sys.argv) > 1 and sys.argv[1] == "--list":
    for p in sorted((ROOT / "apps").glob("*/config.json")):
        print(p.parent.name)
    sys.exit(0)

app = sys.argv[1] if len(sys.argv) > 1 else "n5"
path = ROOT / "apps" / app / "config.json"
if not path.exists():
    sys.exit(f"Không có app '{app}' (thiếu apps/{app}/config.json)")
cfg = json.loads(path.read_text(encoding="utf-8"))
if len(sys.argv) > 2:
    print(cfg[sys.argv[2]])
else:
    for k, v in cfg.items():
        print(f"{k}={v}")
