"""Sinh assets/exams/<level>/*.json từ nội dung soạn trong tools/content.

Chạy:
  python3 tools/build_exams.py                          # sinh + kiểm tra đề đóng sẵn trong app
  python3 tools/build_exams.py --publish <thư mục docs>  # đồng thời xuất lên thư mục GitHub Pages
        ví dụ: --publish ../kanji_n5_flashcard/docs/exams
"""

import importlib
import argparse
import json
import pathlib
import shutil
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "content"))

from exam_dsl import validate  # noqa: E402

MODULES = {"n5": ["n5_01", "n5_02"]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--publish", help="thư mục exams trên GitHub Pages (vd ../kanji_n5_flashcard/docs/exams)")
    args = ap.parse_args()
    all_errors = []
    for level, mods in MODULES.items():
        out_dir = ROOT / "assets" / "exams" / level
        out_dir.mkdir(parents=True, exist_ok=True)
        index = []
        for name in mods:
            exam = importlib.import_module(name).EXAM
            all_errors += validate(exam)
            path = out_dir / f"{exam['id']}.json"
            path.write_text(json.dumps(exam, ensure_ascii=False, indent=1), encoding="utf-8")
            total = sum(len(m["questions"]) for s in exam["sections"] for m in s["mondai"])
            index.append(path.name)
            print(f"{exam['id']}: {total} câu")
        idx = {"schema": 1, "level": level.upper(), "exams": index}
        (out_dir / "index.json").write_text(json.dumps(idx, ensure_ascii=False, indent=1), encoding="utf-8")
        if args.publish and not all_errors:
            pub = pathlib.Path(args.publish) / level
            pub.mkdir(parents=True, exist_ok=True)
            remote_idx = pub / "index.json"
            # Giữ nguyên các đề chỉ có trên web (thêm trực tiếp trên GitHub), thêm đề mới vào cuối.
            existing = []
            if remote_idx.exists():
                existing = json.loads(remote_idx.read_text(encoding="utf-8")).get("exams", [])
            merged = existing + [f for f in index if f not in existing]
            for f in index:
                shutil.copy(out_dir / f, pub / f)
            remote_idx.write_text(json.dumps({"schema": 1, "level": level.upper(), "exams": merged},
                                             ensure_ascii=False, indent=1), encoding="utf-8")
            print(f"Đã xuất {len(index)} đề sang {pub}")
    if all_errors:
        print("\n".join(all_errors))
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
