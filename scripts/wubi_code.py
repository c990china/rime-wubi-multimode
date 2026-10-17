# -*- coding: utf-8 -*-
"""
五笔86 词组编码生成器（Rime 极点五笔86 词库维护用）

用法：
    python wubi_code.py 词1 词2 词3        # 计算这些词的编码
    python wubi_code.py --check            # 校验词库现有编码是否合规
    python wubi_code.py --list             # 列出词库现有词条
    python wubi_code.py --dict <路径> ...  # 指定词库文件（默认取 Rime 用户目录）

路径约定：
    主码表与词库默认取 %APPDATA%\\Rime\\（Rime 用户目录，Windows 标准位置），
    不写死盘符；可用 --dict 覆盖词库路径。

规则来源：主码表 wubi86_jidian.dict.yaml 的 encoder.rules
    二字词      AaAbBaBb   第一字首二码 + 第二字首二码
    三字词      AaBaCaCb   第一字首码 + 第二字首码 + 第三字前二码
    4-10 字词   AaBaCaZa   第一、二、三字首码 + 末字首码
单字码取自主码表，同一字取最长码（即全码）。
"""
import os
import sys

RIME_USER_DIR = os.path.join(
    os.environ.get("APPDATA") or os.path.expanduser("~"), "Rime")
DEFAULT_MAIN_DICT = os.path.join(RIME_USER_DIR, "wubi86_jidian.dict.yaml")
DEFAULT_USER_DICT = os.path.join(RIME_USER_DIR, "wubi86_jidian_user.dict.yaml")


def load_chars(path):
    """单字 -> 最长码（全码）"""
    chars = {}
    with open(path, encoding="utf-8") as f:
        started = False
        for line in f:
            line = line.rstrip("\n")
            if not started:
                if line.strip() == "...":
                    started = True
                continue
            if not line or line.startswith("#"):
                continue
            p = line.split("\t")
            if len(p) < 2:
                continue
            t, c = p[0], p[1]
            if len(t) == 1 and c.isalpha():
                if t not in chars or len(c) > len(chars[t]):
                    chars[t] = c
    return chars


def load_user_rows(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        started = False
        for line in f:
            line = line.rstrip("\n")
            if not started:
                if line.strip() == "...":
                    started = True
                continue
            if not line or line.startswith("#"):
                continue
            p = line.split("\t")
            if len(p) >= 2:
                rows.append((p[0], p[1], p[2] if len(p) > 2 else ""))
    return rows


def word_code(word, chars):
    """返回 (编码, 原因)；无法计算时编码为 None"""
    n = len(word)
    if n < 2:
        return None, "单字请直接查码表"
    if n > 10:
        return None, "超过 10 字，五笔规则不适用"
    codes = [chars.get(ch) for ch in word]
    missing = [ch for ch, c in zip(word, codes) if c is None]
    if missing:
        return None, "这些字不在码表: " + "".join(missing)
    if n == 2:
        return codes[0][:2] + codes[1][:2], None
    if n == 3:
        return codes[0][:1] + codes[1][:1] + codes[2][:2], None
    return codes[0][:1] + codes[1][:1] + codes[2][:1] + codes[-1][:1], None


def main():
    args = sys.argv[1:]

    # 解析 --dict
    user_dict = DEFAULT_USER_DICT
    if "--dict" in args:
        i = args.index("--dict")
        if i + 1 >= len(args):
            raise SystemExit("--dict 后面要跟路径")
        user_dict = args[i + 1]
        del args[i:i + 2]

    main_dict = os.environ.get("RIME_MAIN_DICT") or DEFAULT_MAIN_DICT

    if not args:
        print(__doc__)
        return

    if not os.path.isfile(main_dict):
        raise SystemExit("找不到主码表：%s\n可用环境变量 RIME_MAIN_DICT 指定。" % main_dict)
    chars = load_chars(main_dict)

    if args[0] == "--list":
        if not os.path.isfile(user_dict):
            raise SystemExit("找不到词库：%s" % user_dict)
        for w, c, wt in load_user_rows(user_dict):
            print("%s\t%s\t%s" % (w, c, wt))
        return

    if args[0] == "--check":
        if not os.path.isfile(user_dict):
            raise SystemExit("找不到词库：%s" % user_dict)
        ok = bad = 0
        for w, c, wt in load_user_rows(user_dict):
            calc, why = word_code(w, chars)
            if calc is None:
                print("[跳过] %s\t%s\t(%s)" % (w, c, why))
                bad += 1
            elif calc == c:
                ok += 1
            else:
                print("[不符] %s\t实际=%s\t规则=%s" % (w, c, calc))
                bad += 1
        print("\n合规 %d 条，异常 %d 条" % (ok, bad))
        return

    # 默认：算码
    for w in args:
        calc, why = word_code(w, chars)
        if calc is None:
            print("%s\t—\t(%s)" % (w, why))
        else:
            print("%s\t%s\t1000000" % (w, calc))


if __name__ == "__main__":
    main()
