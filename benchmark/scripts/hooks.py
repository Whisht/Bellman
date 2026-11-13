#!/usr/bin/env python3
"""从逐格 stream.jsonl 里量「钩子实际做了什么」。

报告里关于「机制是否真的触发」的每条结论都由本脚本重算，不靠读源码推断。

每个 `hook_response` 都带 `output`（钩子写到 stdout 的内容）。两条臂的注入形式不同：

  token-optimizer  用 additionalContext 往会话里注入文本（SessionStart / UserPromptSubmit /
                   PostToolUse / PreCompact …），本脚本量注入字节数。
  tokless          PreToolUse 返回改写后的命令（hookSpecificOutput.updatedInput 之类），
                   本脚本比对「模型原本要跑的命令」与「钩子改写后的命令」是否不同。

用法：
  python3 -I hooks.py                 # 读 /tmp/tokbench/runs，打印逐格表
  python3 -I hooks.py --out /tmp/tokbench/findings/hooks.tsv
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


def hook_output(rec: dict) -> str:
    out = rec.get("output")
    if isinstance(out, str):
        return out
    return ""


def rewritten_command(output: str) -> str:
    """从钩子的 stdout 里取出它要求替换成的命令（没有则返回空串）。"""
    try:
        obj = json.loads(output)
    except json.JSONDecodeError:
        return ""
    for key in ("updatedInput", "updated_input", "input"):
        holder = obj.get("hookSpecificOutput") or obj
        if isinstance(holder, dict) and isinstance(holder.get(key), dict):
            cmd = holder[key].get("command")
            if isinstance(cmd, str):
                return cmd
    return ""


def cell_stats(stream: Path) -> dict[str, object]:
    """单次顺序遍历，把每个 `PreToolUse` 响应绑到它拦下的那次工具调用上。

    钩子事件里没有 `tool_use_id`，且流内顺序是「tool_use 先记、hook_started/hook_response 后记」，
    所以规则是：响应按先来后到，归属「它之前尚未配对的同工具调用」中最靠前的一次。
    （一条消息里发多个工具调用时，两个调用会先全部入队、两个响应再依次到达，因此必须用先进先出，
    用「最近一次」会把同一消息里的两次调用对调。）
    """
    events: collections.Counter[str] = collections.Counter()
    rewrites: collections.Counter[str] = collections.Counter()
    injected = 0
    unmatched: dict[str, list[str]] = collections.defaultdict(list)
    for rec in read_jsonl(stream):
        if rec.get("type") == "assistant":
            for block in rec.get("message", {}).get("content", []):
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                arg = block.get("input") or {}
                unmatched[str(block.get("name"))].append(str(arg.get("command") or arg.get("file_path") or ""))
            continue
        if rec.get("type") != "system":
            continue
        subtype = str(rec.get("subtype") or "")
        if subtype not in ("hook_started", "hook_response"):
            continue
        name = str(rec.get("hook_name") or rec.get("hook_event") or "?")
        if subtype == "hook_started":
            events[name] += 1
            continue
        output = hook_output(rec)
        if not output:
            continue
        injected += len(output.encode())
        new = rewritten_command(output)
        if not new:
            continue
        tool = name.split(":")[-1]
        if not unmatched[tool]:
            continue
        original = unmatched[tool].pop(0)
        if new != original:
            rewrites[_shape(original, new)] += 1
    return {
        "events": events,
        "injected_bytes": injected,
        "rewrites": rewrites,
    }


def _shape(old: str, new: str) -> str:
    """把一次改写归成一个可读的类别，例如 `cat → rtk`、`grep → rtk`。

    复合命令行（`a && b; c`）只改其中一段，因此取第一个发生变化的词对。
    """
    old_tokens, new_tokens = old.split(), new.split()
    for a, b in zip(old_tokens, new_tokens):
        if a != b:
            return f"{a} → {b}"
    if len(old_tokens) != len(new_tokens):
        return f"词数 {len(old_tokens)} → {len(new_tokens)}"
    return "仅空白/引号变化"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=str(BASE))
    ap.add_argument("--out", default="")
    args = ap.parse_args()
    base = Path(args.base)

    rows: list[list[str]] = []
    by_arm: dict[str, dict[str, collections.Counter[str]]] = collections.defaultdict(
        lambda: {"events": collections.Counter(), "injected": collections.Counter(),
                 "n": collections.Counter(), "shapes": collections.Counter()}
    )
    for stream in sorted(base.glob("runs/*/*/r*/stream.jsonl")):
        task, arm, rnd = stream.parts[-4], stream.parts[-3], stream.parts[-2]
        stats = cell_stats(stream)
        events: collections.Counter[str] = stats["events"]  # type: ignore[assignment]
        shapes: collections.Counter[str] = stats["rewrites"]  # type: ignore[assignment]
        rows.append(
            [
                task, arm, rnd,
                str(sum(events.values())),
                str(stats["injected_bytes"]),
                str(sum(shapes.values())),
                ",".join(f"{k}={v}" for k, v in sorted(events.items())),
                "; ".join(f"{k}×{v}" for k, v in shapes.most_common()),
            ]
        )
        agg = by_arm[arm]
        agg["n"]["cells"] += 1
        agg["events"].update(events)
        agg["injected"]["bytes"] += int(stats["injected_bytes"])  # type: ignore[arg-type]
        agg["shapes"].update(shapes)

    header = ["task", "arm", "round", "hook_calls", "hook_output_bytes", "changed_commands",
              "by_event", "rewrite_shapes"]
    lines = ["\t".join(header)] + ["\t".join(r) for r in rows]
    print("\n".join(lines))
    print()
    for arm in sorted(by_arm):
        agg = by_arm[arm]
        events = ", ".join(f"{k}={v}" for k, v in sorted(agg["events"].items()))
        print(f"{arm}: {agg['n']['cells']} 格，钩子调用 {sum(agg['events'].values())} 次，"
              f"钩子输出合计 {agg['injected']['bytes']} 字节")
        print(f"   事件分布：{events}")
        print(f"   改写形态：{dict(agg['shapes'].most_common())}")
    if args.out:
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
