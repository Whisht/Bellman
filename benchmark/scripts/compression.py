#!/usr/bin/env python3
"""量「工具自己的压缩」到底把多少字节交给了模型。

宿主层（tool-results 落盘）会把任何超过 30 000 字符的工具结果换成 2 KB 预览，所以
「结果变短了」不能直接算成被测工具的功劳。本脚本按三档给每次工具调用归类：

  raw        结果正文没有 `<persisted-output>` 头，模型看到的就是命令的真实输出。
  persisted  结果正文是宿主写的 2 KB 预览，全文在磁盘上，模型可按路径回读。
  empty      结果正文为空（命令无输出或钩子拦掉了）。

只有 `raw` 档才能用来判断被测工具是否压缩了自己的输出；`persisted` 档一律算宿主层的账。

用法：
  python3 -I compression.py                # 打印大输出的逐次调用表
  python3 -I compression.py --out <路径>    # 同时写文件
"""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

BASE = Path("/tmp/tokbench")
BIG = 100_000  # 只关心这个量级以上的源头字节数


def read_jsonl(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    out: list[dict] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            out.append(obj)
    return out


def body_text(block: dict) -> str:
    content = block.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(part.get("text", "") for part in content if isinstance(part, dict))
    return ""


def calls(stream: Path) -> list[tuple[str, str, str, int]]:
    """返回 (工具名, 入参摘要, 结果正文, 正文字节数)。

    必须按 `tool_use_id` 配对：钩子事件会让「工具调用序列」与「工具结果序列」不对齐，
    按位置配对会把结果挂到相邻的另一次调用上。
    """
    uses: dict[str, tuple[str, str]] = {}
    for rec in read_jsonl(stream):
        if rec.get("type") != "assistant":
            continue
        for block in rec.get("message", {}).get("content", []):
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            arg = block.get("input") or {}
            detail = str(arg.get("command") or arg.get("file_path") or arg.get("pattern") or "")
            uses[str(block.get("id"))] = (str(block.get("name")), detail)

    out: list[tuple[str, str, str, int]] = []
    for rec in read_jsonl(stream):
        if rec.get("type") != "user":
            continue
        for block in rec.get("message", {}).get("content", []):
            if not isinstance(block, dict) or block.get("type") != "tool_result":
                continue
            name, detail = uses.get(str(block.get("tool_use_id")), ("?", ""))
            text = body_text(block)
            out.append((name, detail, text, len(text.encode())))
    return out


def classify(text: str) -> str:
    if not text.strip():
        return "empty"
    return "persisted" if "<persisted-output>" in text else "raw"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=str(BASE))
    ap.add_argument("--out", default="")
    args = ap.parse_args()
    base = Path(args.base)

    tallies: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    rows: list[list[str]] = []
    for stream in sorted(base.glob("runs/*/*/r*/stream.jsonl")):
        task, arm, rnd = stream.parts[-4], stream.parts[-3], stream.parts[-2]
        for name, detail, text, size in calls(stream):
            kind = classify(text)
            tallies[arm][kind] += 1
            tallies[arm]["bytes_" + kind] += size
            if size < BIG and kind != "persisted":
                continue
            rows.append([task, arm, rnd, name, kind, str(size), detail[:110]])

    header = ["task", "arm", "round", "tool", "kind", "result_bytes", "detail"]
    lines = ["\t".join(header)] + ["\t".join(r) for r in rows]
    print("\n".join(lines))
    print()
    for arm in sorted(tallies):
        t = tallies[arm]
        print(f"{arm}: raw={t['raw']} 次（合计 {t['bytes_raw']} 字节）, "
              f"persisted={t['persisted']} 次（模型共看到 {t['bytes_persisted']} 字节）, empty={t['empty']} 次")
    if args.out:
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
