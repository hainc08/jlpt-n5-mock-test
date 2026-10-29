"""Kiểm tra các file đề trên GitHub Pages (docs/exams/<level>/).

Chạy: python3 docs/exams/check_exams.py   (GitHub Actions tự chạy mỗi lần push)

Kiểm tra:
- index.json hợp lệ, mọi file được liệt kê đều tồn tại
- JSON đọc được, id đề không trùng
- mỗi câu: đủ lựa chọn (4, hoặc 3 với 発話表現/即時応答), đáp án nằm trong phạm vi,
  có giải thích; câu nghe có lời thoại; câu sắp xếp ★ hợp lệ
- cảnh báo (không chặn) nếu số câu từng dạng khác chuẩn N5
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent

N5_COUNTS = {
    "kanji_yomi": 7, "hyouki": 5, "bunmyaku": 6, "iikae": 3,
    "bunpou_keishiki": 9, "narabekae": 4, "bunshou": 4,
    "tanbun": 2, "chuubun": 2, "jouhou": 1,
    "kadai": 7, "point": 6, "hatsuwa": 5, "sokuji": 6,
}


def check_exam(path, errors, warnings):
    try:
        exam = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        errors.append(f"{path.name}: JSON lỗi — {e}")
        return None
    name = path.name
    for key in ("id", "title", "titleJa", "sections"):
        if key not in exam:
            errors.append(f"{name}: thiếu trường '{key}'")
    counts = {}
    qids = set()
    for s in exam.get("sections", []):
        for key in ("id", "titleJa", "titleVi", "minutes", "scoreGroup", "mondai"):
            if key not in s:
                errors.append(f"{name}: phần thi thiếu '{key}'")
        if s.get("scoreGroup") not in ("language", "listening"):
            errors.append(f"{name}: scoreGroup phải là 'language' hoặc 'listening'")
        for m in s.get("mondai", []):
            mtype = m.get("type", "?")
            for key in ("id", "label", "type", "titleJa", "titleVi", "instructionJa", "instructionVi", "questions"):
                if key not in m:
                    errors.append(f"{name} {m.get('id', '?')}: mondai thiếu '{key}'")
            for q in m.get("questions", []):
                qid = q.get("id", "?")
                where = f"{name} câu {qid}"
                counts[mtype] = counts.get(mtype, 0) + 1
                if qid in qids:
                    errors.append(f"{where}: trùng id câu hỏi")
                qids.add(qid)
                opts = q.get("options", [])
                want = 3 if mtype in ("hatsuwa", "sokuji") else 4
                if len(opts) != want:
                    errors.append(f"{where}: có {len(opts)} lựa chọn, cần {want}")
                ans = q.get("answer")
                if not isinstance(ans, int) or not 0 <= ans < max(len(opts), 1):
                    errors.append(f"{where}: 'answer' phải là số 0..{len(opts) - 1} (0 = lựa chọn thứ nhất)")
                if not str(q.get("explanation", "")).strip():
                    errors.append(f"{where}: thiếu giải thích")
                if not isinstance(q.get("no"), int):
                    errors.append(f"{where}: thiếu 'no' (số thứ tự câu)")
                if s.get("scoreGroup") == "listening" and not q.get("script"):
                    errors.append(f"{where}: câu nghe thiếu 'script'")
                if mtype == "narabekae":
                    order, star = q.get("order"), q.get("star")
                    if sorted(order or []) != [0, 1, 2, 3] or not isinstance(star, int):
                        errors.append(f"{where}: câu sắp xếp cần 'order' (hoán vị 0..3) và 'star'")
                    elif order[star] != ans:
                        errors.append(f"{where}: 'answer' phải bằng order[star] = {order[star]}")
    for t, c in N5_COUNTS.items():
        if exam.get("level", "N5") == "N5" and counts.get(t, 0) != c:
            warnings.append(f"{name}: dạng {t} có {counts.get(t, 0)} câu (chuẩn N5: {c})")
    return exam.get("id")


def main():
    errors, warnings = [], []
    levels = [d for d in ROOT.iterdir() if d.is_dir()]
    for level in levels:
        idx_path = level / "index.json"
        if not idx_path.exists():
            continue
        try:
            idx = json.loads(idx_path.read_text(encoding="utf-8"))
        except Exception as e:  # noqa: BLE001
            errors.append(f"{level.name}/index.json: JSON lỗi — {e}")
            continue
        files = idx.get("exams", [])
        if not files:
            errors.append(f"{level.name}/index.json: danh sách 'exams' trống")
        ids = {}
        for f in files:
            name = f if isinstance(f, str) else f.get("file", "")
            p = level / name
            if not p.exists():
                errors.append(f"{level.name}/index.json: không có file '{name}'")
                continue
            eid = check_exam(p, errors, warnings)
            if eid in ids:
                errors.append(f"{level.name}: id đề '{eid}' bị trùng ở {ids[eid]} và {name}")
            ids[eid] = name
        listed = {f if isinstance(f, str) else f.get("file") for f in files}
        for p in level.glob("*.json"):
            if p.name != "index.json" and p.name not in listed:
                warnings.append(f"{level.name}/{p.name}: chưa có trong index.json nên app sẽ không hiển thị")
        print(f"{level.name}: {len(files)} đề")
    for w in warnings:
        print("CẢNH BÁO:", w)
    for e in errors:
        print("LỖI:", e)
    if errors:
        sys.exit(1)
    print("OK — tất cả đề hợp lệ")


if __name__ == "__main__":
    main()
