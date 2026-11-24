# README/BUILD box alignment + file encoding checks (INI2MAP Tester).
# Located in <project>/tools/ - run from anywhere:
#   python tools/check_boxes.py
#   - README.md     : UTF-8 without BOM, LF line endings
#   - README.ru.md  : UTF-8 without BOM, CRLF line endings
#   - README.zh.md  : UTF-8 without BOM, LF line endings
#   - BUILD*.md     : UTF-8 without BOM, LF line endings
#   - *.ps1         : ASCII only
#   - box blocks    : every line of a box has the same VISUAL width
#     (East-Asian wide chars and emoji count as 2 columns, Cyrillic as 1)
import io, os, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

WIDE_RANGES = [
    (0x1100, 0x115F), (0x2E80, 0x303E), (0x3041, 0x33FF),
    (0x3400, 0x4DBF), (0x4E00, 0x9FFF), (0xA000, 0xA4CF),
    (0xAC00, 0xD7A3), (0xF900, 0xFAFF), (0xFE10, 0xFE19),
    (0xFE30, 0xFE6F), (0xFF00, 0xFF60), (0xFFE0, 0xFFE6),
    (0x1F004, 0x1F004), (0x1F0CF, 0x1F0CF), (0x1F18E, 0x1F18E),
    (0x1F191, 0x1F19A), (0x1F200, 0x1F202), (0x1F210, 0x1F23B),
    (0x1F240, 0x1F248), (0x1F250, 0x1F251), (0x1F260, 0x1F265),
    (0x1F300, 0x1F64F), (0x1F680, 0x1F6FF), (0x1F900, 0x1F9FF),
    (0x1FA70, 0x1FAFF), (0x20000, 0x2FFFD), (0x30000, 0x3FFFD),
    # emoji/misc picked individually: U+2705 is wide, U+2713 (check mark)
    # and U+25CB (white circle) are narrow in these boxes
    (0x2705, 0x2705), (0x270A, 0x270B), (0x2728, 0x2728),
    (0x274C, 0x274C), (0x274E, 0x274E), (0x2753, 0x2755),
    (0x2757, 0x2757), (0x2795, 0x2797), (0x27B0, 0x27B0),
    (0x27BF, 0x27BF), (0x2B1B, 0x2B1C), (0x2B50, 0x2B50),
    (0x2B55, 0x2B55),
]

def vwidth(s):
    w = 0
    for ch in s:
        cp = ord(ch)
        w += 2 if any(a <= cp <= b for a, b in WIDE_RANGES) else 1
    return w

def check_encoding(path, encoding, newline_name, allow_crlf, allow_lf):
    errors = []
    if not os.path.exists(path):
        return ["%s: missing" % path]
    data = io.open(path, "rb").read()
    if data[:3] == b"\xef\xbb\xbf":
        errors.append("%s: UTF-8 BOM present" % path)
    try:
        data.decode(encoding)
    except UnicodeDecodeError as e:
        errors.append("%s: not %s (%s)" % (path, encoding, e))
        return errors
    crlf = data.count(b"\r\n")
    lf = data.count(b"\n") - crlf
    if allow_crlf and lf:
        errors.append("%s: %d bare LF line ending(s) (expected CRLF)" % (path, lf))
    if allow_lf and crlf:
        errors.append("%s: %d CRLF line ending(s) (expected LF)" % (path, crlf))
    return errors

def check_ascii(path):
    errors = []
    data = io.open(path, "rb").read()
    try:
        data.decode("ascii")
    except UnicodeDecodeError as e:
        errors.append("%s: non-ASCII byte at offset %d" % (path, e.start))
    return errors

def check_boxes(path):
    errors = []
    if not os.path.exists(path):
        return ["%s: missing" % path]
    text = io.open(path, "r", encoding="utf-8", newline="").read()
    lines = text.split("\n")
    left = set("\u250c\u251c\u2514\u2502")
    right = set("\u2510\u2524\u2518\u2502")
    block = []
    def flush(block):
        if len(block) < 2:
            return
        widths = {}
        for ln, s in block:
            widths.setdefault(vwidth(s), []).append(ln)
        if len(widths) > 1:
            detail = "; ".join("%d cols: lines %s" % (w, ",".join(str(x) for x in v))
                               for w, v in sorted(widths.items()))
            errors.append("%s:%d box block is not aligned (%s)" % (path, block[0][0], detail))
    for i, raw in enumerate(lines, 1):
        s = raw.rstrip("\r")
        if s and s[0] in left and s[-1] in right and len(s) >= 2:
            block.append((i, s))
        else:
            flush(block)
            block = []
    flush(block)
    return errors

errors = []
errors += check_encoding(os.path.join(ROOT, "README.md"), "utf-8", "LF", False, True)
errors += check_encoding(os.path.join(ROOT, "README.ru.md"), "utf-8", "CRLF", True, False)
errors += check_encoding(os.path.join(ROOT, "README.zh.md"), "utf-8", "LF", False, True)
errors += check_boxes(os.path.join(ROOT, "README.md"))
errors += check_boxes(os.path.join(ROOT, "README.ru.md"))
errors += check_boxes(os.path.join(ROOT, "README.zh.md"))
for build_md in ("BUILD.md", "BUILD.ru.md", "BUILD.zh.md"):
    errors += check_encoding(os.path.join(ROOT, build_md), "utf-8", "LF", False, True)
    errors += check_boxes(os.path.join(ROOT, build_md))
for ps1 in glob.glob(os.path.join(ROOT, "**", "*.ps1"), recursive=True):
    errors += check_ascii(ps1)

if errors:
    for e in errors:
        print("FAIL", e)
    sys.exit(1)
print("check_boxes: OK (README/BUILD UTF-8, EN+zh LF, RU CRLF, boxes aligned, ps1 ASCII)")
