#!/usr/bin/env python3
"""Tạo ios/ExportOptions.plist cho app đang build (APP=n4 hoặc tham số đầu tiên)."""
import json
import os
import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
app = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("APP")) or "n5"
cfg = json.loads((ROOT / "apps" / app / "config.json").read_text(encoding="utf-8"))

team = os.environ.get("APPLE_TEAM_ID") or "SLR7396ZXZ"
profile = os.environ.get("IOS_PROFILE_NAME") or cfg["IOS_PROFILE"]

with open(ROOT / "ios/ExportOptions.plist", "wb") as f:
    plistlib.dump({
        "method": "app-store-connect",
        "teamID": team,
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "provisioningProfiles": {cfg["BUNDLE_ID"]: profile},
        "uploadSymbols": True,
    }, f)
print(f"Đã tạo ios/ExportOptions.plist ({cfg['BUNDLE_ID']} → {profile})")
