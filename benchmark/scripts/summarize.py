#!/usr/bin/env python3
"""把逐格指标与判分汇总成臂间对比表。

输入是两个已被前面步骤写入的产物，本脚本不重新测量、不重新判分：

  runs/index.tsv    每格一行：token、轮次、钩子、工具、耗时、成本（run_one.sh 写入）
  runs/scores.tsv   每格一行：task_pass、各键是否答对、t1 的凭据两条观测轴（score.py 写入）

输出（默认写 benchmark/results/summary.tsv 并在 stdout 打出同一张表）：

  task    按任务分组的均值，外加 arm=ALL 的总体行
  gross_input  = input + cache_creation + cache_read，即「模型上下文总吞吐」
  cache_read / output / turns / hooks / seconds / cost 为逐格均值或合计

基线相对节省在 ALL 行给出：saving_% = (baseline - arm) / baseline。

用法：
  python3 -I summarize.py                     # 读 /tmp/tokbench/runs，写默认产物
  python3 -I summarize.py --base /tmp/tokbench --out benchmark/results/summary.tsv
"""

from __future__ import annotations

import argparse
import csv
import statistics
from collections import defaultdict
from pathlib import Path

ARMS = ("baseline", "tokless", "optimizer")
SUMMED = ("total_cost_usd", "gross_input", "output", "cache_read", "input")


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8") as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


def as_float(value: str) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def cell_keys(row: dict[str, str]) -> tuple[str, str, str]:
    return row["task"], row["arm"], row["round"]


def mean(values: list[float]) -> float:
    return statistics.fmean(values) if values else 0.0


def summarize(base: Path) -> tuple[list[list[str]], list[dict[str, str]]]:
    index = read_tsv(base / "runs" / "index.tsv")
    scores = {}
    scores_path = base / "runs" / "scores.tsv"
    if scores_path.is_file():
        for row in read_tsv(scores_path):
            scores[cell_keys(row)] = row

    by_task_arm: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in index:
        if row.get("arm") not in ARMS:
            continue
        by_task_arm[(row["task"], row["arm"])].append(row)

    def line(task: str, arm: str, rows: list[dict[str, str]]) -> list[str]:
        # 只统计已判分的格子；未判分的格子单列，避免「还没判分」被误读成「答错」。
        scored = [r for r in rows if cell_keys(r) in scores]
        passes = sum(1 for r in scored if scores[cell_keys(r)]["task_pass"] == "yes")
        pass_text = f"{passes}/{len(scored)}"
        if len(scored) != len(rows):
            pass_text += f" (+{len(rows) - len(scored)} 未判分)"
        fields = {
            "n": len(rows),
            "pass": pass_text,
            "gross_input": mean([as_float(r["gross_input"]) or 0 for r in rows]),
            "cache_read": mean([as_float(r["cache_read"]) or 0 for r in rows]),
            "output": mean([as_float(r["output"]) or 0 for r in rows]),
            "turns": mean([as_float(r["num_turns"]) or 0 for r in rows]),
            "hooks": mean([as_float(r["hook_started"]) or 0 for r in rows]),
            "seconds": mean([(as_float(r["duration_ms"]) or 0) / 1000 for r in rows]),
            "cost": sum(as_float(r["total_cost_usd"]) or 0 for r in rows),
        }
        return [
            task, arm, str(fields["n"]), fields["pass"],
            f"{fields['gross_input']:.0f}", f"{fields['cache_read']:.0f}",
            f"{fields['output']:.0f}", f"{fields['turns']:.1f}", f"{fields['hooks']:.1f}",
            f"{fields['seconds']:.0f}", f"{fields['cost']:.2f}", "",
        ]

    tasks = sorted({t for t, _ in by_task_arm})
    table: list[list[str]] = []
    totals: dict[str, list[dict[str, str]]] = defaultdict(list)
    for task in tasks:
        base_rows = by_task_arm.get((task, "baseline"), [])
        base_gross = mean([as_float(r["gross_input"]) or 0 for r in base_rows])
        for arm in ARMS:
            rows = by_task_arm.get((task, arm), [])
            if not rows:
                continue
            totals[arm].extend(rows)
            out = line(task, arm, rows)
            if base_gross and arm != "baseline":
                out[-1] = f"{(base_gross - (as_float(out[4]) or 0)) / base_gross * 100:+.1f}%"
            elif arm != "baseline":
                out[-1] = "n/a"
            table.append(out)

    base_gross = mean([as_float(r["gross_input"]) or 0 for r in totals["baseline"]])
    for arm in ARMS:
        rows = totals.get(arm, [])
        if not rows:
            continue
        out = line("ALL", arm, rows)
        if base_gross and arm != "baseline":
            out[-1] = f"{(base_gross - (as_float(out[4]) or 0)) / base_gross * 100:+.1f}%"
        table.append(out)
    return table, index


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="/tmp/tokbench")
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    table, index = summarize(Path(args.base))
    header = ["task", "arm", "n", "pass", "gross_input", "cache_read", "output", "turns",
              "hooks", "seconds", "cost_usd", "saving_vs_baseline"]
    text = "\t".join(header) + "\n" + "\n".join("\t".join(r) for r in table) + "\n"
    out = Path(args.out) if args.out else Path(args.base) / "findings" / "summary.tsv"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")
    print(text, end="")
    print(f"\n{len(index)} 格 → {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
