#!/usr/bin/env python3
"""Replace or remove the branding line in JX item description files.

Default target: server1/settings/item/**/*.txt, excluding backup files.
The script works on bytes to preserve legacy TCVN3/ABC encoded item files.
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT_DEFAULT = Path("/home/jxser/server1/settings/item")

# Current byte sequence used by this server for "Vo Lam Offline" in TCVN3.
CURRENT_BRAND = b"V\xe2 L\xa9m Offline"

# Common wrappers found in item description columns.
BRAND_PATTERNS = [
    b"<enter><enter><color=white><bclr=pink>" + CURRENT_BRAND + b"<bclr><color>",
    b"<enter><enter><bclr=pink>" + CURRENT_BRAND + b"<bclr>",
    b"<color=white><bclr=pink>" + CURRENT_BRAND + b"<bclr><color>",
    b"<bclr=pink>" + CURRENT_BRAND + b"<bclr>",
]

# Enough UTF-8 -> TCVN3 mapping for Vietnamese display strings.
TCVN3 = {
    "à":"µ","á":"¸","ả":"¶","ã":"·","ạ":"¹",
    "ă":"¨","ằ":"»","ắ":"¾","ẳ":"¼","ẵ":"½","ặ":"Æ",
    "â":"©","ầ":"Ç","ấ":"Ê","ẩ":"È","ẫ":"É","ậ":"Ë",
    "đ":"®",
    "è":"Ì","é":"Ð","ẻ":"Î","ẽ":"Ï","ẹ":"Ñ",
    "ê":"ª","ề":"Ò","ế":"Õ","ể":"Ó","ễ":"Ô","ệ":"Ö",
    "ì":"×","í":"Ý","ỉ":"Ø","ĩ":"Ü","ị":"Þ",
    "ò":"ß","ó":"ã","ỏ":"á","õ":"â","ọ":"ä",
    "ô":"«","ồ":"å","ố":"è","ổ":"æ","ỗ":"ç","ộ":"é",
    "ơ":"¬","ờ":"ê","ớ":"í","ở":"ë","ỡ":"ì","ợ":"î",
    "ù":"ï","ú":"ó","ủ":"ñ","ũ":"ò","ụ":"ô",
    "ư":"­","ừ":"õ","ứ":"ø","ử":"ö","ữ":"÷","ự":"ù",
    "ỳ":"ú","ý":"ý","ỷ":"û","ỹ":"ü","ỵ":"þ",
    "À":"µ","Á":"¸","Ả":"¶","Ã":"·","Ạ":"¹",
    "Ă":"¡","Ằ":"¡»","Ắ":"¡¾","Ẳ":"¡¼","Ẵ":"¡½","Ặ":"¡Æ",
    "Â":"¢","Ầ":"¢Ç","Ấ":"¢Ê","Ẩ":"¢È","Ẫ":"¢É","Ậ":"¢Ë",
    "Đ":"§",
    "È":"Ì","É":"Ð","Ẻ":"Î","Ẽ":"Ï","Ẹ":"Ñ",
    "Ê":"£","Ề":"£Ò","Ế":"£Õ","Ể":"£Ó","Ễ":"£Ô","Ệ":"£Ö",
    "Ì":"×","Í":"Ý","Ỉ":"Ø","Ĩ":"Ü","Ị":"Þ",
    "Ò":"ß","Ó":"ã","Ỏ":"á","Õ":"â","Ọ":"ä",
    "Ô":"¤","Ồ":"¤å","Ố":"¤è","Ổ":"¤æ","Ỗ":"¤ç","Ộ":"¤é",
    "Ơ":"¥","Ờ":"¥ê","Ớ":"¥í","Ở":"¥ë","Ỡ":"¥ì","Ợ":"¥î",
    "Ù":"ï","Ú":"ó","Ủ":"ñ","Ũ":"ò","Ụ":"ô",
    "Ư":"¦","Ừ":"¦õ","Ứ":"¦ø","Ử":"¦ö","Ữ":"¦÷","Ự":"¦ù",
    "Ỳ":"ú","Ý":"ý","Ỷ":"û","Ỹ":"ü","Ỵ":"þ",
}

def to_tcvn3_bytes(text: str) -> bytes:
    converted = "".join(TCVN3.get(ch, ch) for ch in text)
    return converted.encode("latin-1")

def iter_item_files(root: Path):
    for path in sorted(root.rglob("*.txt")):
        if ".bak" in path.name:
            continue
        if path.is_file():
            yield path

def build_replacement(args: argparse.Namespace) -> bytes:
    if args.remove:
        return b""
    brand = to_tcvn3_bytes(args.text)
    return args.prefix.encode("ascii") + brand + args.suffix.encode("ascii")

def replace_data(data: bytes, replacement: bytes) -> tuple[bytes, int]:
    count = 0
    for pattern in BRAND_PATTERNS:
        data, n = data.replace(pattern, replacement), data.count(pattern)
        count += n
    return data, count

def main() -> int:
    parser = argparse.ArgumentParser(description="Replace/remove Vo Lam Offline branding in item descriptions.")
    parser.add_argument("--root", default=str(ROOT_DEFAULT), help="item settings root")
    parser.add_argument("--text", default="Võ Lâm Offline", help="new branding text, UTF-8 input; ignored with --remove")
    parser.add_argument("--remove", action="store_true", help="remove the branding line entirely")
    parser.add_argument("--dry-run", action="store_true", help="show counts without writing files")
    parser.add_argument("--prefix", default="<enter><enter><color=white><bclr=pink>", help="ASCII prefix for replacement")
    parser.add_argument("--suffix", default="<bclr><color>", help="ASCII suffix for replacement")
    args = parser.parse_args()

    root = Path(args.root)
    replacement = build_replacement(args)
    files_changed = 0
    replacements = 0
    for path in iter_item_files(root):
        data = path.read_bytes()
        new_data, count = replace_data(data, replacement)
        if count == 0:
            continue
        files_changed += 1
        replacements += count
        if not args.dry_run:
            path.write_bytes(new_data)
        print(f"{path}: {count}")

    mode = "DRY-RUN" if args.dry_run else "UPDATED"
    print(f"{mode}: files={files_changed}, replacements={replacements}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
