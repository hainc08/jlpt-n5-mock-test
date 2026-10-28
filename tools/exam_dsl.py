"""DSL nhỏ để soạn đề thi thử JLPT.

Quy ước soạn:
- Đáp án đúng LUÔN viết ở vị trí đầu tiên của `opts`; script tự xáo trộn
  (cố định theo id câu hỏi) và tính lại `answer`.
- `{...}` trong câu hỏi = phần gạch chân.
- Câu sắp xếp (文の組み立て): `tokens` theo thứ tự hiển thị, `order` là thứ tự
  đúng (chỉ số 0-based của tokens), `star` là vị trí ★ trong các ô trống.
- Nghe hiểu: `script` là danh sách (người nói, câu). N = người dẫn,
  M = nam, F = nữ.
"""

import hashlib
import random

INSTR = {
    "kanji_yomi": (
        "＿＿の ことばは ひらがなで どう かきますか。1・2・3・4から いちばん いい ものを ひとつ えらんで ください。",
        "Từ gạch chân được đọc (viết bằng hiragana) thế nào? Chọn đáp án đúng nhất.",
    ),
    "hyouki": (
        "＿＿の ことばは どう かきますか。1・2・3・4から いちばん いい ものを ひとつ えらんで ください。",
        "Từ gạch chân được viết (bằng Kanji/Katakana) thế nào? Chọn đáp án đúng nhất.",
    ),
    "bunmyaku": (
        "（　）に なにが はいりますか。1・2・3・4から いちばん いい ものを ひとつ えらんで ください。",
        "Chọn từ thích hợp điền vào chỗ trống (　).",
    ),
    "iikae": (
        "＿＿の ぶんと だいたい おなじ いみの ぶんが あります。1・2・3・4から いちばん いい ものを ひとつ えらんで ください。",
        "Chọn câu có nghĩa gần nhất với câu gạch chân.",
    ),
    "bunpou_keishiki": (
        "（　）に 何を 入れますか。1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Chọn từ/cấu trúc ngữ pháp điền vào chỗ trống (　).",
    ),
    "narabekae": (
        "★に 入る ものは どれですか。1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Sắp xếp 4 thành phần thành câu đúng, rồi chọn thành phần nằm ở vị trí ★.",
    ),
    "bunshou": (
        "［1］から［4］に 何を 入れますか。ぶんしょうの いみを かんがえて、1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Đọc đoạn văn, chọn từ thích hợp điền vào các chỗ trống [1]–[4].",
    ),
    "tanbun": (
        "つぎの ぶんしょうを 読んで、しつもんに こたえて ください。こたえは、1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Đọc đoạn văn ngắn và trả lời câu hỏi.",
    ),
    "chuubun": (
        "つぎの ぶんしょうを 読んで、しつもんに こたえて ください。こたえは、1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Đọc đoạn văn vừa và trả lời câu hỏi.",
    ),
    "jouhou": (
        "下の あんないを 見て、しつもんに こたえて ください。こたえは、1・2・3・4から いちばん いい ものを 一つ えらんで ください。",
        "Đọc bảng thông tin và trả lời câu hỏi (tìm thông tin).",
    ),
    "kadai": (
        "もんだい1では、はじめに しつもんを 聞いて ください。それから 話を 聞いて、もんだいようしの 1から4の 中から、いちばん いい ものを 一つ えらんで ください。",
        "Nghe câu hỏi trước, sau đó nghe hội thoại và chọn đáp án đúng nhất.",
    ),
    "point": (
        "もんだい2では、はじめに しつもんを 聞いて ください。それから 話を 聞いて、もんだいようしの 1から4の 中から、いちばん いい ものを 一つ えらんで ください。",
        "Nghe câu hỏi trước, sau đó nghe hội thoại để tìm điểm then chốt.",
    ),
    "hatsuwa": (
        "もんだい3では、ばめんを 見ながら しつもんを 聞いて ください。➡の 人は 何と 言いますか。1から3の 中から、いちばん いい ものを 一つ えらんで ください。",
        "Xem tình huống và nghe câu hỏi. Người được chỉ (➡) sẽ nói gì? Các lựa chọn chỉ được đọc, không in ra.",
    ),
    "sokuji": (
        "もんだい4は、えなどが ありません。ぶんを 聞いて、1から3の 中から、いちばん いい ものを 一つ えらんで ください。",
        "Không có hình. Nghe câu nói và chọn câu đáp lại phù hợp nhất (lựa chọn chỉ được đọc).",
    ),
}

TITLES = {
    "kanji_yomi": ("漢字読み", "Đọc Kanji"),
    "hyouki": ("表記", "Cách viết"),
    "bunmyaku": ("文脈規定", "Chọn từ theo ngữ cảnh"),
    "iikae": ("言い換え類義", "Câu đồng nghĩa"),
    "bunpou_keishiki": ("文法形式の判断", "Chọn ngữ pháp"),
    "narabekae": ("文の組み立て", "Sắp xếp câu (★)"),
    "bunshou": ("文章の文法", "Ngữ pháp trong đoạn văn"),
    "tanbun": ("内容理解（短文）", "Đọc hiểu đoạn ngắn"),
    "chuubun": ("内容理解（中文）", "Đọc hiểu đoạn vừa"),
    "jouhou": ("情報検索", "Tìm thông tin"),
    "kadai": ("課題理解", "Hiểu vấn đề"),
    "point": ("ポイント理解", "Hiểu điểm chính"),
    "hatsuwa": ("発話表現", "Diễn đạt bằng lời"),
    "sokuji": ("即時応答", "Phản xạ tức thì"),
}

SECTIONS = {
    "moji": ("言語知識（文字・語彙）", "Từ vựng – Chữ Hán", 20, "language"),
    "bunpou": ("言語知識（文法）・読解", "Ngữ pháp – Đọc hiểu", 40, "language"),
    "choukai": ("聴解", "Nghe hiểu", 30, "listening"),
}

# Số câu chuẩn của từng dạng bài trong một đề N5.
N5_COUNTS = {
    "kanji_yomi": 7, "hyouki": 5, "bunmyaku": 6, "iikae": 3,
    "bunpou_keishiki": 9, "narabekae": 4, "bunshou": 4,
    "tanbun": 2, "chuubun": 2, "jouhou": 1,
    "kadai": 7, "point": 6, "hatsuwa": 5, "sokuji": 6,
}


def _shuffle(exam_id, qid, opts):
    seed = int(hashlib.sha256(f"{exam_id}/{qid}".encode()).hexdigest(), 16)
    idx = list(range(len(opts)))
    random.Random(seed).shuffle(idx)
    new_opts = [opts[i] for i in idx]
    return new_opts, idx.index(0)


def q(prompt, opts, exp, **extra):
    d = {"prompt": prompt, "opts": opts, "exp": exp}
    d.update(extra)
    return d


def mondai(mtype, label, questions, passage=None, table=None, title=None):
    return {"type": mtype, "label": label, "questions": questions,
            "passage": passage, "table": table, "title": title}


def build(exam_id, title, title_ja, sections):
    """sections: dict section_id -> list[mondai]"""
    out_sections = []
    for sid, mlist in sections.items():
        tja, tvi, minutes, group = SECTIONS[sid]
        out_m = []
        qn = 0
        for mi, m in enumerate(mlist):
            ija, ivi = INSTR[m["type"]]
            mja, mvi = TITLES[m["type"]]
            qs = []
            for qi, raw in enumerate(m["questions"]):
                qn += 1
                qid = f"{sid}-{mi + 1}-{qi + 1}"
                item = {"id": qid, "no": qn, "prompt": raw["prompt"],
                        "explanation": raw["exp"]}
                if m["type"] == "narabekae":
                    tokens = raw["opts"]
                    order = raw["order"]
                    star = raw["star"]
                    item["options"] = tokens
                    item["answer"] = order[star]
                    item["order"] = order
                    item["star"] = star
                else:
                    opts, ans = _shuffle(exam_id, qid, raw["opts"])
                    item["options"] = opts
                    item["answer"] = ans
                for k in ("script", "scene", "passage", "table", "audioOptions"):
                    if k in raw:
                        item[k] = raw[k]
                if m["type"] in ("hatsuwa", "sokuji"):
                    item["audioOptions"] = True
                qs.append(item)
            md = {"id": f"{sid}-{mi + 1}", "label": m["label"], "type": m["type"],
                  "titleJa": m.get("title") or mja, "titleVi": mvi,
                  "instructionJa": ija, "instructionVi": ivi, "questions": qs}
            if m.get("passage"):
                md["passage"] = m["passage"]
            if m.get("table"):
                md["table"] = m["table"]
            out_m.append(md)
        out_sections.append({"id": sid, "titleJa": tja, "titleVi": tvi,
                             "minutes": minutes, "scoreGroup": group,
                             "mondai": out_m})
    return {"id": exam_id, "level": "N5", "title": title, "titleJa": title_ja,
            "sections": out_sections}


def validate(exam):
    counts = {}
    errors = []
    for s in exam["sections"]:
        for m in s["mondai"]:
            counts[m["type"]] = counts.get(m["type"], 0) + len(m["questions"])
            for qq in m["questions"]:
                n = len(qq["options"])
                want = 3 if m["type"] in ("hatsuwa", "sokuji") else 4
                if n != want:
                    errors.append(f"{exam['id']} {qq['id']}: {n} options, cần {want}")
                if not 0 <= qq["answer"] < n:
                    errors.append(f"{exam['id']} {qq['id']}: answer ngoài phạm vi")
                if len(set(qq["options"])) != n:
                    errors.append(f"{exam['id']} {qq['id']}: trùng lựa chọn")
                if not qq["explanation"].strip():
                    errors.append(f"{exam['id']} {qq['id']}: thiếu giải thích")
                if s["id"] == "choukai" and not qq.get("script"):
                    errors.append(f"{exam['id']} {qq['id']}: thiếu script nghe")
                if m["type"] == "narabekae" and sorted(qq["order"]) != [0, 1, 2, 3]:
                    errors.append(f"{exam['id']} {qq['id']}: order sai")
    for t, c in N5_COUNTS.items():
        if counts.get(t, 0) != c:
            errors.append(f"{exam['id']}: dạng {t} có {counts.get(t, 0)} câu, chuẩn {c}")
    return errors


def L(situation, question, lines, opts, exp):
    script = [["N", f"{situation}{question}"]] + [list(x) for x in lines] + [["N", question]]
    return q(question, opts, exp, script=script)


def H(scene_vi, situation_ja, opts, exp):
    return q(f"{situation_ja}何と 言いますか。", opts, exp, scene=scene_vi,
             script=[["N", f"{situation_ja}何と 言いますか。"]])


def S(speaker, line, opts, exp):
    return q("", opts, exp, script=[[speaker, line]])
