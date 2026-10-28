"""Sinh assets/exams/<level>/*.json từ nội dung soạn trong tools/content.

Chạy: python3 tools/build_exams.py
"""

import importlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "content"))

from exam_dsl import validate  # noqa: E402

MODULES = {"n5": ["n5_01", "n5_02"]}


def main():
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
            index.append({"id": exam["id"], "title": exam["title"], "titleJa": exam["titleJa"],
                          "file": f"assets/exams/{level}/{exam['id']}.json",
                          "questions": total,
                          "minutes": sum(s["minutes"] for s in exam["sections"])})
            print(f"{exam['id']}: {total} câu")
        (out_dir / "index.json").write_text(
            json.dumps({"level": level.upper(), "exams": index}, ensure_ascii=False, indent=1),
            encoding="utf-8")
    if all_errors:
        print("\n".join(all_errors))
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
