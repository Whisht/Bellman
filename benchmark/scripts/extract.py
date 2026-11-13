#!/usr/bin/env python3
"""把一次运行的 stream-json 解析成指标，并追加到运行索引。

用途：run_one.sh 在每次运行结束后调用。所有数字都来自 stream-json 本身，
不读取仓库里的任何文件，也不依赖被测工具的自报数据。

输出：
  <run-dir>/metrics.tsv   key<TAB>value，便于人工核对
  <run-dir>/final.txt     模型的最终答复文本，供 score.py 判分
  <index>                 一行一次运行，供 summarize.py 聚合
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# 压缩信号：不同版本用不同措辞，全部作为"发生过压缩"的证据收集。
COMPACT_TEXT_PATTERNS = (
    "continued from a previous conversation",
    "conversation was summarized",
    "context has been compacted",
)

INDEX_COLUMNS = (
    "task", "arm", "round", "exit_code", "is_error", "num_turns", "duration_ms",
    "input", "cache_creation", "cache_read", "output", "gross_input",
    "total_cost_usd", "hook_started", "hook_response", "tool_calls", "tool_names",
    "compact_signals", "plugin", "tools", "window",
)


def load_events(path: Path) -> list[dict]:
    events: list[dict] = []
    with path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return events


def walk_text(node: object):
    """递归产出所有字符串值，用于在任意嵌套结构里找压缩措辞。"""
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for value in node.values():
            yield from walk_text(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk_text(value)


def parse_usage(result: dict) -> dict[str, int]:
    usage = result.get("usage") or {}
    return {
        "input": int(usage.get("input_tokens") or 0),
        "cache_creation": int(usage.get("cache_creation_input_tokens") or 0),
        "cache_read": int(usage.get("cache_read_input_tokens") or 0),
        "output": int(usage.get("output_tokens") or 0),
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stream", required=True)
    ap.add_argument("--run-dir", required=True)
    ap.add_argument("--index", required=True)
    ap.add_argument("--task", required=True)
    ap.add_argument("--arm", required=True)
    ap.add_argument("--round", required=True)
    ap.add_argument("--exit-code", required=True)
    ap.add_argument("--plugin", default="")
    ap.add_argument("--tools", default="")
    ap.add_argument("--window", default="")
    args = ap.parse_args()

    run_dir = Path(args.run_dir)
    events = load_events(Path(args.stream))

    results = [e for e in events if e.get("type") == "result"]
    result = results[-1] if results else {}
    usage = parse_usage(result)

    hook_started = hook_response = 0
    tool_counts: dict[str, int] = {}
    compact_signals = 0
    assistant_texts: list[str] = []

    for event in events:
        if event.get("type") == "system":
            subtype = str(event.get("subtype") or "")
            if subtype == "hook_started":
                hook_started += 1
            elif subtype == "hook_response":
                hook_response += 1
        elif event.get("type") == "assistant":
            content = (event.get("message") or {}).get("content") or []
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    name = str(block.get("name") or "?")
                    tool_counts[name] = tool_counts.get(name, 0) + 1
                elif block.get("type") == "text" and block.get("text"):
                    assistant_texts.append(block["text"])
        # 压缩摘要会以 isCompactSummary 标记出现在 user/system 事件上。
        if event.get("isCompactSummary"):
            compact_signals += 1

    haystack = "\n".join(walk_text([e for e in events if e.get("type") != "assistant"]))
    for pattern in COMPACT_TEXT_PATTERNS:
        compact_signals += len(re.findall(re.escape(pattern), haystack, flags=re.IGNORECASE))

    final_text = result.get("result") or (assistant_texts[-1] if assistant_texts else "")
    name_counts = ",".join(f"{k}:{v}" for k, v in sorted(tool_counts.items()))
    metrics = {
        "task": args.task,
        "arm": args.arm,
        "round": args.round,
        "exit_code": args.exit_code,
        "is_error": str(bool(result.get("is_error"))).lower() if result else "unknown",
        "num_turns": str(result.get("num_turns") or 0),
        "duration_ms": str(result.get("duration_ms") or 0),
        **{k: str(v) for k, v in usage.items()},
        "gross_input": str(usage["input"] + usage["cache_creation"] + usage["cache_read"]),
        "total_cost_usd": f"{float(result.get('total_cost_usd') or 0):.6f}",
        "hook_started": str(hook_started),
        "hook_response": str(hook_response),
        "tool_calls": str(sum(tool_counts.values())),
        "tool_names": name_counts,
        "compact_signals": str(compact_signals),
        "plugin": args.plugin,
        "tools": args.tools,
        "window": args.window,
    }

    run_dir.mkdir(parents=True, exist_ok=True)
    with (run_dir / "metrics.tsv").open("w", encoding="utf-8") as fh:
        for key, value in metrics.items():
            fh.write(f"{key}\t{value}\n")
    (run_dir / "final.txt").write_text(final_text, encoding="utf-8")

    index = Path(args.index)
    index.parent.mkdir(parents=True, exist_ok=True)
    new_file = not index.exists()
    with index.open("a", encoding="utf-8") as fh:
        if new_file:
            fh.write("\t".join(INDEX_COLUMNS) + "\n")
        fh.write("\t".join(metrics[c] for c in INDEX_COLUMNS) + "\n")

    print(f"  gross_input={metrics['gross_input']} output={metrics['output']} "
          f"turns={metrics['num_turns']} hooks={hook_started}/{hook_response} "
          f"tools={metrics['tool_calls']} compact={metrics['compact_signals']}")


if __name__ == "__main__":
    main()
