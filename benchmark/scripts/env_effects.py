#!/usr/bin/env python3
"""量化「环境层」的影响：宿主落盘层、本地路由的出口脱敏层、分类路由层。

这三层不属于任何一个被测工具，但会改变模型实际看到什么、以及 token 账目怎么记。
报告里相关数字全部由本脚本重算。

数据来源（全部只读）：
  /tmp/tokbench/runs/<task>/<arm>/r<n>/stream.jsonl   Claude Code 的流事件（含 session_id）
  /tmp/tokbench/arms/<arm>/home/.claude/projects/*/tool-results/*.txt  宿主落盘的工具结果
  ~/.config/magpie/usage.jsonl    本地路由的逐请求账本
  ~/.config/magpie/masking/<日期>.jsonl   出口脱敏账本（含被替换值的字面量）

凭据安全：脚本不打印任何凭据取值。canary 只以「出现次数」「长度」「形状」三类形式出现。

用法：
  python3 -I env_effects.py --base /tmp/tokbench --out /tmp/tokbench/findings/env_effects.txt
"""

from __future__ import annotations

import argparse
import collections
import json
import os
import re
import statistics
from pathlib import Path

CANARY_SHAPE = re.compile(r"^ghp_[0-9a-f]+$")
MASK_LOG_DIR = Path("~/.config/magpie/masking").expanduser()
USAGE_LOG = Path("~/.config/magpie/usage.jsonl").expanduser()


def as_int(value: object) -> int:
    try:
        return int(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return 0


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


def bench_runs(base: Path) -> dict[str, tuple[str, str, str, Path]]:
    """session_id → (task, arm, round, run_dir)。"""
    runs: dict[str, tuple[str, str, str, Path]] = {}
    for stream in sorted(base.glob("runs/*/*/r*/stream.jsonl")):
        task, arm, rnd = stream.parts[-4], stream.parts[-3], stream.parts[-2]
        for rec in read_jsonl(stream):
            sid = rec.get("session_id") or rec.get("sessionId")
            if sid:
                runs[str(sid)] = (task, arm, rnd, stream.parent)
                break
    return runs


def canary_token(fixture: Path) -> str:
    env = fixture / "workspace" / "secrets" / "canary.env"
    if not env.is_file():
        return ""
    for line in env.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("GITHUB_TOKEN="):
            return line.split("=", 1)[1].strip()
    return ""


def host_layer(arms_root: Path, sessions: dict[str, tuple[str, str, str, Path]]) -> list[str]:
    """宿主落盘层：工具结果超过 30 000 字符时被写到磁盘，模型只看到 2 KB 预览。

    两个都要量：磁盘上的全文（工具管线交出来的字节），和模型实际看到的预览字节。
    二者之差就是宿主替所有臂一起省下的上下文。
    """
    lines = ["## 宿主落盘层（tool-results）", ""]
    fixture_sizes = {
        p.name: p.stat().st_size
        for p in sorted((Path("/tmp/tokbench/fixture/workspace/assets")).glob("*"))
    }
    lines.append(f"- fixture 中两个超大输出的字节数：{fixture_sizes}")
    per_arm: dict[str, list[tuple[str, str, str, int, int]]] = collections.defaultdict(list)
    previews: dict[str, list[int]] = collections.defaultdict(list)
    buildlog_delta: list[int] = []
    inventory_delta: list[int] = []
    for sid, (task, arm, rnd, run_dir) in sorted(sessions.items()):
        files = sorted(
            (arms_root / arm / "home" / ".claude" / "projects").glob(f"*/{sid}/tool-results/*.txt")
        )
        if not files:
            continue
        full = sum(p.stat().st_size for p in files)
        for path in files:
            size = path.stat().st_size
            if abs(size - fixture_sizes["build.log"]) < 4096:
                buildlog_delta.append(size - fixture_sizes["build.log"])
            elif abs(size - fixture_sizes["inventory.csv"]) < 4096:
                inventory_delta.append(size - fixture_sizes["inventory.csv"])
        seen = 0
        for rec in read_jsonl(run_dir / "stream.jsonl"):
            for item in (rec.get("message") or {}).get("content") or []:
                if not isinstance(item, dict):
                    continue
                body = item.get("content")
                if isinstance(body, str) and "<persisted-output>" in body:
                    seen += len(body.encode())
        previews[arm].append(seen)
        per_arm[arm].append((task, arm, rnd, len(files), full))
    for arm in sorted(per_arm):
        cells = per_arm[arm]
        files = sum(c[3] for c in cells)
        full = sum(c[4] for c in cells)
        seen = sum(previews[arm])
        lines.append(
            f"- {arm}: {len(cells)} 格命中落盘，{files} 个文件，磁盘全文合计 {full} 字节，"
            f"模型实际看到的预览合计 {seen} 字节（压缩到 {seen / full * 100:.2f}%）"
        )
    all_cells = sorted({c[:3] for cells in per_arm.values() for c in cells})
    lines.append(f"- 命中落盘的格子（{len(all_cells)} 格）：{all_cells}")
    lines.append(
        f"- build.log 落盘文件相对源文件的字节差：{collections.Counter(buildlog_delta)}"
        "（脚本自己先打印一行 wc -l，故恒为正的小增量）"
    )
    lines.append(
        f"- inventory.csv 落盘文件相对源文件的字节差：{collections.Counter(inventory_delta)}"
        "（0 = 宿主原样落盘；非 0 的两格是模型在同一次 Bash 调用里追加了 echo/wc 输出）"
    )
    return lines


def masking_layer(base: Path, sessions: dict[str, tuple[str, str, str, Path]]) -> list[str]:
    """出口脱敏层：本地路由把身份/凭据替换成定长伪值后再发出，本地记录保留真值。"""
    token = canary_token(base / "fixture")
    entries = 0
    by_kind: collections.Counter[str] = collections.Counter()
    by_kind_units: collections.Counter[str] = collections.Counter()
    latencies: list[float] = []
    canary_shaped: collections.Counter[str] = collections.Counter()
    truth_in_log = 0
    models: collections.Counter[str] = collections.Counter()
    for path in sorted(MASK_LOG_DIR.glob("*.jsonl")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if token:
            truth_in_log += text.count(token)
        for rec in read_jsonl(path):
            if str(rec.get("session") or "") not in sessions:
                continue
            entries += 1
            models[str(rec.get("model"))] += 1
            latencies.append(float(rec.get("took") or 0) / 1000.0)
            for item in rec.get("values") or []:
                kind = str(item.get("k"))
                by_kind[kind] += 1
                by_kind_units[kind] += as_int(item.get("n")) or 1
                pseudonym = str(item.get("p") or "")
                if kind == "SECRET" and CANARY_SHAPE.match(pseudonym):
                    canary_shaped[pseudonym] += as_int(item.get("n")) or 1

    streams_hit = 0
    for _, (task, arm, rnd, run_dir) in sessions.items():
        if task != "t1" or not token:
            continue
        if token in (run_dir / "stream.jsonl").read_text(encoding="utf-8", errors="replace"):
            streams_hit += 1
    t1_runs = sum(1 for v in sessions.values() if v[0] == "t1")

    lines = ["## 出口脱敏层（本地路由 masking）", ""]
    lines.append(f"- 基准会话在脱敏账本中的请求条数：{entries}")
    lines.append(f"- 脱敏项（按 kind，条目数 / 被替换值的出现次数）：")
    for kind, count in sorted(by_kind.items()):
        lines.append(f"  - {kind}: {count} / {by_kind_units[kind]}")
    distinct = len(canary_shaped)
    units = sum(canary_shaped.values())
    lines.append(f"- 形状为 canary 的伪值（`ghp_` + 十六进制，定长）：{distinct} 个不同值，共出现 {units} 次")
    lines.append(f"- canary 真值在脱敏账本中的出现次数：{truth_in_log}（0 = 只发伪值，不下发真值）")
    if latencies:
        lines.append(f"- 脱敏耗时（账本 `took`，毫秒）：中位 {statistics.median(latencies):.0f}，最大 {max(latencies):.0f}")
    lines.append(f"- t1 运行中工具结果仍含 canary 真值的：{streams_hit}/{t1_runs}")
    lines.append(f"- 脱敏请求涉及的模型：{dict(models.most_common(3))}")
    return lines


ALIAS_SUFFIX = re.compile(r"-\d+$")


def canonical_backend(label: str) -> str:
    """把同一个后端的多种别名归并成一个名字。

    本地路由对同一后端会出现大小写、`.`/`-` 写法、以及带构建号后缀的不同标签
    （例如 `DeepSeek-V4.1-Flash` / `deepseek-v4.1-flash-1017` / `deepseek-v4-1-flash-260910`）。
    不归并的话，「单次运行里换了后端」会被这些别名本身刷出几十条假记录。
    """
    name = label.lower().replace("_", "-").replace(".", "-")
    return ALIAS_SUFFIX.sub("", name)


def routing_layer(sessions: dict[str, tuple[str, str, str, Path]]) -> list[str]:
    """分类路由层：`group/smart-split` 把请求分给不同后端，客户端只看到组名。"""
    served: collections.Counter[str] = collections.Counter()
    canonical: collections.Counter[str] = collections.Counter()
    status: collections.Counter[str] = collections.Counter()
    request_models: collections.Counter[str] = collections.Counter()
    per_run: dict[tuple[str, str, str], collections.Counter[str]] = collections.defaultdict(collections.Counter)
    tokens = collections.Counter()
    ratios: list[float] = []
    for rec in read_jsonl(USAGE_LOG):
        sid = str(rec.get("session") or rec.get("native_session") or "")
        if sid not in sessions:
            continue
        task, arm, rnd, _ = sessions[sid]
        label = str(rec.get("served") or rec.get("model") or "?")
        served[label] += 1
        canonical[canonical_backend(label)] += 1
        request_models[str(rec.get("model") or "?")] += 1
        per_run[(task, arm, rnd)][canonical_backend(label)] += 1
        status[str(rec.get("status"))] += 1
        for field in ("in", "out", "cache_read", "cache_write"):
            tokens[field] += as_int(rec.get(field))
        plain, up = as_int(rec.get("plain_bytes")), as_int(rec.get("up_bytes"))
        if plain > 0:
            ratios.append(up / plain)

    lines = ["## 分类路由层（`group/smart-split`）", ""]
    lines.append(f"- 基准请求条数：{sum(served.values())}")
    lines.append("- 实际后端分布（归并别名前 → 归并后）：")
    for label, count in served.most_common():
        lines.append(f"  - {label}: {count} → {canonical_backend(label)}")
    lines.append(f"- 归并后的后端分布：{dict(canonical.most_common())}")
    lines.append(f"- 客户端上报的模型名：{dict(request_models.most_common())}")
    lines.append(f"- HTTP 状态分布：{dict(status.most_common())}")
    lines.append(f"- token 合计：{dict(tokens)}")
    if ratios:
        ratios.sort()
        p95 = ratios[min(len(ratios) - 1, int(len(ratios) * 0.95))]
        lines.append(
            f"- 上行字节 / 明文字节（脱敏是否改变体积）：中位 {statistics.median(ratios):.3f}，"
            f"p95 {p95:.3f}，最大 {max(ratios):.3f}，n={len(ratios)}"
        )
    mixed = {k: dict(v) for k, v in per_run.items() if len(v) > 1}
    lines.append(f"- 单次运行内出现多个后端的运行：{mixed if mixed else '无'}")
    return lines


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="/tmp/tokbench")
    ap.add_argument("--out", default="")
    args = ap.parse_args()
    base = Path(args.base)

    sessions = bench_runs(base)
    lines = [
        "# 环境层实测（不属于任一被测工具）",
        "",
        f"- 基准运行格数（含未完成）：{len(sessions)}",
        "",
    ]
    lines += host_layer(base / "arms", sessions)
    lines.append("")
    lines += masking_layer(base, sessions)
    lines.append("")
    lines += routing_layer(sessions)
    text = "\n".join(lines) + "\n"
    if args.out:
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
    print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
