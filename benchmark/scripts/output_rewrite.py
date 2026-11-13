#!/usr/bin/env python3
"""量 PostToolUse 钩子有没有改写**工具结果本身**（而不是命令）。

`hooks.py` 量的是 PreToolUse 对**命令**的改写（tokless 的形态）。但 token-optimizer 的
Bash 压缩走的是另一条路：PostToolUse 返回 `updatedToolOutput`，直接替换模型将看到的结果正文。
只看命令改写会把这条路径整个漏掉，因此单列本脚本。

配对规则与 `hooks.py` 相同且同样必要：钩子事件里没有 `tool_use_id`，流内顺序是
「tool_use 先记 → hook_started/hook_response 后记」，因此响应按先来后到，归属它之前
尚未配对的同工具调用中最靠前的一次（先进先出）。

判定「改写是否真的生效」只靠字节数不够，必须比对正文：模型最终看到的 `tool_result` 正文若与
钩子给出的 `updatedToolOutput.stdout` 一致，则改写生效；若是 `<persisted-output>` 预览，
则宿主落盘层覆盖了钩子结果。

用法：
  python3 -I output_rewrite.py
  python3 -I output_rewrite.py --out /tmp/tokbench/findings/output_rewrite.tsv
"""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path

BASE = Path("/tmp/tokbench")


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


def updated_output(output: str) -> tuple[str, str]:
    """从钩子 stdout 里取出 `updatedToolOutput` 的 stdout/stderr（没有则返回两个空串）。"""
    try:
        obj = json.loads(output)
    except json.JSONDecodeError:
        return "", ""
    holder = obj.get("hookSpecificOutput") if isinstance(obj, dict) else None
    if not isinstance(holder, dict):
        return "", ""
    payload = holder.get("updatedToolOutput")
    if not isinstance(payload, dict):
        return "", ""
    return str(payload.get("stdout") or ""), str(payload.get("stderr") or "")


def body_text(block: dict) -> str:
    content = block.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(p.get("text", "") for p in content if isinstance(p, dict))
    return ""


def cell_stats(stream: Path) -> dict[str, object]:
    """返回一格内「结果被改写」的次数、字节对比，以及改写是否在最终正文里生效。"""
    uses: dict[str, str] = {}
    pending: dict[str, list[tuple[str, int]]] = collections.defaultdict(list)
    rewrites = 0
    before = after = 0
    took_effect = 0
    overridden_by_host = 0
    calls: collections.Counter[str] = collections.Counter()
    for rec in read_jsonl(stream):
        if rec.get("type") == "assistant":
            for block in rec.get("message", {}).get("content", []):
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    uses[str(block.get("id"))] = str(block.get("name"))
            continue
        if rec.get("type") == "user":
            for block in rec.get("message", {}).get("content", []) or []:
                if not isinstance(block, dict) or block.get("type") != "tool_result":
                    continue
                tool = uses.get(str(block.get("tool_use_id")), "?")
                pending[tool].append((body_text(block), len(body_text(block).encode())))
            continue
        if rec.get("subtype") != "hook_response":
            continue
        stdout, stderr = updated_output(str(rec.get("output") or ""))
        if not stdout and not stderr:
            continue
        tool = str(rec.get("hook_name") or "").split(":")[-1]
        if not pending[tool]:
            continue
        seen, seen_bytes = pending[tool].pop(0)
        rewrites += 1
        calls[tool] += 1
        before += seen_bytes
        after += len((stdout + stderr).encode())
        if seen.strip() == stdout.strip():
            took_effect += 1
        elif "<persisted-output>" in seen:
            overridden_by_host += 1
    return {
        "rewrites": rewrites,
        "before": before,
        "after": after,
        "took_effect": took_effect,
        "overridden": overridden_by_host,
        "calls": calls,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=str(BASE))
    ap.add_argument("--out", default="")
    args = ap.parse_args()
    base = Path(args.base)

    rows: list[list[str]] = []
    agg: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    calls_by_arm: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    for stream in sorted(base.glob("runs/*/*/r*/stream.jsonl")):
        task, arm, rnd = stream.parts[-4], stream.parts[-3], stream.parts[-2]
        stats = cell_stats(stream)
        rows.append(
            [
                task, arm, rnd,
                str(stats["rewrites"]), str(stats["before"]), str(stats["after"]),
                str(stats["took_effect"]), str(stats["overridden"]),
                ",".join(f"{k}={v}" for k, v in sorted(stats["calls"].items())),
            ]
        )
        a = agg[arm]
        a["cells"] += 1
        a["rewrites"] += int(stats["rewrites"])  # type: ignore[arg-type]
        a["before"] += int(stats["before"])  # type: ignore[arg-type]
        a["after"] += int(stats["after"])  # type: ignore[arg-type]
        a["took_effect"] += int(stats["took_effect"])  # type: ignore[arg-type]
        a["overridden"] += int(stats["overridden"])  # type: ignore[arg-type]
        calls_by_arm[arm].update(stats["calls"])  # type: ignore[arg-type]

    header = ["task", "arm", "round", "result_rewrites", "model_sees_before_bytes",
              "hook_gave_bytes", "took_effect", "overridden_by_host", "by_tool"]
    lines = ["\t".join(header)] + ["\t".join(r) for r in rows]
    print("\n".join(lines))
    print()
    for arm in sorted(agg):
        a = agg[arm]
        print(f"{arm}: {a['cells']} 格，结果改写 {a['rewrites']} 次，"
              f"改写前模型可见 {a['before']} 字节 → 钩子给出 {a['after']} 字节；"
              f"其中生效 {a['took_effect']} 次、被宿主预览覆盖 {a['overridden']} 次")
        print(f"   按工具：{dict(calls_by_arm[arm])}")
    if args.out:
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
