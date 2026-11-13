#!/usr/bin/env python3
"""对每次运行的最终答复判分。

真值不从答案里推断，也不硬编码在脚本里：除「改动后那一行的行号」这类
由 fixture 结构决定的常量外，其余真值都在运行时从 fixture 副本
（默认 /tmp/tokbench/fixture/workspace）重新计算。这样 fixture 重新生成后
判分仍然有效。

凭据安全：脚本不把 fixture 的假凭据写进任何产物。t1 的凭据项分两条互不相干的
观测轴记录：

  canary_preserved  该次运行的工具结果里，凭据串是否原样存在（读 stream.jsonl，
                    衡量「压缩有没有吃掉凭据」，是工具的属性）。
  canary_quote      最终答复里引用的凭据串是否等于磁盘真值（只记 truth/other，
                    不写取值）。本轮实测该项受本地路由的出口脱敏影响，见
                    docs/mechanism-notes.md 的环境效应一节，故不计入 task_pass。

用法：
  python3 -I score.py                      # 判分所有已有运行，写 <run>/score.tsv
  python3 -I score.py --runs /tmp/tokbench/runs
  python3 -I score.py --task t3 --arm tokless --round 1 --print
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

BASE = Path(os.environ.get("BENCH_BASE", "/tmp/tokbench"))
FIXTURE_WS = BASE / "fixture" / "workspace"
RUNS = BASE / "runs"

TASKS = ("t1", "t1b", "t2", "t3", "t4", "t5")

# t3 的目标改动。旧行在新文件中唯一，因此行号可从 fixture 直接算出。
EDIT_OLD = "    if not batch:"
EDIT_NEW = "    if not batch or len(batch) > 4096:"
SKU = "ZQ-0007341"
CANARY_KEY = "GITHUB_TOKEN"
CANARY_PREFIX_LEN = 12

KEYS: dict[str, tuple[str, ...]] = {
    "t1": ("warn_count", "final_sig", "codec_py_lines"),
    "t1b": ("warn_count", "final_sig", "codec_py_lines"),
    "t2": ("zephyrquorum_hits", "quorum_drift_ms_hits", "zq_top_file", "zq_top_file_first_line"),
    "t3": ("condition", "condition_line", "ledger_defs", "ledger_anchor"),
    "t4": ("trace_anchor", "sku_qty", "drift_rows", "ts_bytes_total"),
    "t5": ("main_typ_import_lines", "replay_anchor", "eventstore_anchor", "ts_files"),
}
CANARY_RE = re.compile(r"ghp_[A-Za-z0-9]+")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def lines_of(path: Path) -> list[str]:
    return read_text(path).splitlines()


def grep_first(text: str, pattern: str) -> str:
    match = re.search(pattern, text)
    return match.group(1) if match else ""


def build_truth(ws: Path) -> dict[str, dict[str, object]]:
    """从 fixture 计算全部真值。"""
    build_log = read_text(ws / "assets" / "build.log")
    inventory = read_text(ws / "assets" / "inventory.csv")
    eventstore = lines_of(ws / "codec" / "eventstore.py")
    ledger = read_text(ws / "codec" / "ledger.py")
    corpus = sorted((ws / "corpus").glob("*.md"))

    corpus_text = {p.name: read_text(p) for p in corpus}
    zq_counts = {name: text.count("zephyrquorum") for name, text in corpus_text.items()}
    top = max(zq_counts, key=lambda n: (zq_counts[n], n)) if zq_counts else ""
    top_lines = corpus_text.get(top, "").splitlines()
    zq_first_line = next(
        (i for i, line in enumerate(top_lines, 1) if "zephyrquorum" in line), 0
    )

    sku_qty = 0
    drift_rows = 0
    inv_rows = inventory.splitlines()[1:]
    for row in inv_rows:
        cells = row.split(",")
        if len(cells) >= 4 and cells[3] == "drift":
            drift_rows += 1
        if cells and cells[0] == SKU and len(cells) >= 3:
            sku_qty = int(cells[2])

    canary_path = ws / "secrets" / "canary.env"
    canary_token = ""
    if canary_path.is_file():
        for line in read_text(canary_path).splitlines():
            if line.startswith(CANARY_KEY + "="):
                canary_token = line.split("=", 1)[1].strip()

    condition_lines = [i for i, line in enumerate(eventstore, 1) if line == EDIT_OLD]
    if len(condition_lines) != 1:
        raise SystemExit(f"fixture 异常：{EDIT_OLD!r} 在 eventstore.py 中命中 {len(condition_lines)} 次")

    ts_files = sorted((ws / "codec" / "client" / "src").glob("*.ts"))

    common = {
        "warn_count": sum(1 for line in build_log.splitlines() if "WARN" in line),
        "final_sig": grep_first(build_log, r"FINAL_SIG=(\S+)"),
        "codec_py_lines": sum(len(lines_of(p)) for p in sorted((ws / "codec").glob("*.py"))),
    }
    truth = {
        "t1": dict(common),
        "t1b": dict(common),
        "t2": {
            "zephyrquorum_hits": sum(zq_counts.values()),
            "quorum_drift_ms_hits": sum(t.count("quorum_drift_ms") for t in corpus_text.values()),
            "zq_top_file": f"corpus/{top}",
            "zq_top_file_first_line": zq_first_line,
        },
        "t3": {
            "condition": EDIT_NEW,
            "condition_line": condition_lines[0],
            "ledger_defs": sum(1 for line in ledger.splitlines() if line.startswith("def ")),
            "ledger_anchor": grep_first(ledger, r"ANCHOR:\s*(\S+)"),
        },
        "t4": {
            "trace_anchor": grep_first(build_log, r"TRACE-ANCHOR=(\S+)"),
            "sku_qty": sku_qty,
            "drift_rows": drift_rows,
            "ts_bytes_total": sum(p.stat().st_size for p in ts_files),
        },
        "t5": {
            "main_typ_import_lines": sum(
                1 for line in lines_of(ws / "main.typ") if line.startswith("#import")
            ),
            "replay_anchor": grep_first(read_text(ws / "codec" / "replay.py"), r"ANCHOR:\s*(\S+)"),
            "eventstore_anchor": grep_first(read_text(ws / "codec" / "eventstore.py"), r"ANCHOR:\s*(\S+)"),
            "ts_files": len(ts_files),
        },
    }
    return truth, canary_token


def canary_notes(run_dir: Path, canary_token: str, answer_text: str) -> dict[str, str]:
    """凭据的两条观测轴。取值永远不写进产物，只写 yes/no 与 truth/other。"""
    if not canary_token:
        return {"canary_preserved": "n/a", "canary_quote": "n/a"}
    stream = run_dir / "stream.jsonl"
    preserved = "yes" if stream.is_file() and canary_token in read_text(stream) else "no"
    truth_prefix = canary_token[:CANARY_PREFIX_LEN]
    quotes = CANARY_RE.findall(answer_text)
    if not quotes:
        quote = "missing"
    elif any(q[:CANARY_PREFIX_LEN] == truth_prefix for q in quotes):
        quote = "truth"
    else:
        quote = "other"
    return {"canary_preserved": preserved, "canary_quote": quote}


def iter_objects(text: str):
    """按括号配对从文本里产出所有顶层 JSON 对象（跳过字符串内的括号）。"""
    depth = 0
    start = -1
    in_str = False
    escape = False
    for i, ch in enumerate(text):
        if in_str:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}" and depth:
            depth -= 1
            if depth == 0 and start >= 0:
                yield text[start : i + 1]
                start = -1


def extract_answer(final_text: str, keys: tuple[str, ...]) -> tuple[dict | None, list[str]]:
    """从最终答复里取出答题 JSON。优先返回包含预期键的对象，其次返回最后一个可解析对象。"""
    notes: list[str] = []
    candidates: list[dict] = []
    for chunk in iter_objects(final_text):
        try:
            parsed = json.loads(chunk)
        except json.JSONDecodeError:
            continue
        if isinstance(parsed, dict):
            candidates.append(parsed)
    if not candidates:
        return None, ["no_json"]
    complete = [c for c in candidates if all(k in c for k in keys)]
    chosen = complete[-1] if complete else candidates[-1]
    if not complete:
        notes.append("missing_keys:" + ",".join(k for k in keys if k not in chosen))
    extra = [k for k in chosen if k not in keys]
    if extra:
        notes.append("extra_keys:" + ",".join(sorted(extra)))
    return chosen, notes


def norm_str(value: object) -> str:
    text = str(value).strip()
    text = text.strip("`").strip()
    text = text.strip('"').strip("'").strip()
    return re.sub(r"\s+", " ", text)


def as_int(value: object) -> int | None:
    text = norm_str(value).replace(",", "").replace("_", "")
    match = re.search(r"-?\d+", text)
    return int(match.group(0)) if match else None


def compare(key: str, expected: object, answer: object) -> bool:
    if isinstance(expected, int):
        return as_int(answer) == expected
    if key == "condition":
        return norm_str(answer) == norm_str(expected)
    if key in ("zq_top_file",):
        got = norm_str(answer).lstrip("./")
        return got == str(expected) or got.endswith(str(expected))
    return norm_str(answer) == norm_str(expected)


def diff_notes(run_dir: Path, task: str) -> str:
    """从 workspace.diff 读出改动范围，用于 t3 的越界改动判定。"""
    diff_path = run_dir / "workspace.diff"
    if not diff_path.is_file():
        return "no_diff"
    added: list[str] = []
    removed: list[str] = []
    files: set[str] = set()
    for line in read_text(diff_path).splitlines():
        if line.startswith("+++ ") or line.startswith("--- "):
            files.add(line[4:].strip())
        elif line.startswith("+") and not line.startswith("+++"):
            added.append(line[1:])
        elif line.startswith("-") and not line.startswith("---"):
            removed.append(line[1:])
    if task != "t3":
        return "files=%d,+-=%d/-%d" % (len(files), len(added), len(removed))
    ok = (
        [a for a in added if a.strip()] == [EDIT_NEW]
        and [r for r in removed if r.strip()] == [EDIT_OLD]
    )
    return "edit_exact=%s,+-=%d/-%d" % ("yes" if ok else "no", len(added), len(removed))


def score_one(
    run_dir: Path, truth: dict[str, dict[str, object]], canary_token: str = ""
) -> dict[str, str]:
    task = run_dir.parent.parent.name
    final_path = run_dir / "final.txt"
    keys = KEYS[task]
    row: dict[str, str] = {
        "task": task,
        "arm": run_dir.parent.name,
        "round": run_dir.name.lstrip("r"),
    }
    if not final_path.is_file():
        row["json_found"] = "no"
        row["task_pass"] = "no"
        row["notes"] = "no_final_txt"
        return row

    final_text = read_text(final_path)
    answer, notes = extract_answer(final_text, keys)
    row["json_found"] = "yes" if answer else "no"
    passed = 0
    for key in keys:
        expected = truth[task][key]
        got = None if answer is None else answer.get(key)
        ok = answer is not None and got is not None and compare(key, expected, got)
        passed += int(ok)
        row[key] = norm_str(got)[:60] if got is not None else "<missing>"
        row[key + "_ok"] = "yes" if ok else "no"
    row["keys_ok"] = "%d/%d" % (passed, len(keys))
    row["task_pass"] = "yes" if passed == len(keys) else "no"
    if task == "t1":
        row.update(canary_notes(run_dir, canary_token, final_text))
    note = diff_notes(run_dir, task)
    if notes:
        note = ",".join(notes) + ";" + note
    row["notes"] = note
    return row


def iter_runs(runs_root: Path, tasks: list[str]):
    for task in tasks:
        task_dir = runs_root / task
        if not task_dir.is_dir():
            continue
        for arm_dir in sorted(task_dir.iterdir()):
            if not arm_dir.is_dir():
                continue
            for run_dir in sorted(arm_dir.iterdir()):
                if run_dir.is_dir() and (run_dir / "final.txt").is_file():
                    yield run_dir


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", default=str(RUNS))
    ap.add_argument("--fixture", default=str(FIXTURE_WS))
    ap.add_argument("--tasks", default=" ".join(TASKS))
    ap.add_argument("--out", default="")
    ap.add_argument("--print", action="store_true", help="把逐行结果打到 stdout")
    args = ap.parse_args()

    tasks = args.tasks.split()
    truth, canary_token = build_truth(Path(args.fixture))
    runs_root = Path(args.runs)

    base_columns = ["task", "arm", "round", "task_pass", "keys_ok", "json_found",
                    "canary_preserved", "canary_quote", "notes"]
    rows: list[dict[str, str]] = []
    for run_dir in iter_runs(runs_root, tasks):
        row = score_one(run_dir, truth, canary_token)
        rows.append(row)
        columns = base_columns + sorted(c for c in row if c not in base_columns)
        with (run_dir / "score.tsv").open("w", encoding="utf-8") as fh:
            fh.write("\n".join(f"{c}\t{row.get(c, '')}" for c in columns) + "\n")
        if args.print:
            print("\t".join(row.get(c, "") for c in columns))

    out_path = Path(args.out) if args.out else runs_root / "scores.tsv"
    if rows:
        columns = base_columns + sorted({c for row in rows for c in row if c not in base_columns})
        with out_path.open("w", encoding="utf-8") as fh:
            fh.write("\t".join(columns) + "\n")
            for row in rows:
                fh.write("\t".join(row.get(c, "") for c in columns) + "\n")

    by_arm: dict[str, list[int]] = {}
    for row in rows:
        by_arm.setdefault(row["arm"], []).append(1 if row["task_pass"] == "yes" else 0)
    print(f"判分 {len(rows)} 格 → {out_path}")
    for arm, results in sorted(by_arm.items()):
        print(f"  {arm:<10} 全对 {sum(results)}/{len(results)}")
    failures = [r for r in rows if r["task_pass"] != "yes"]
    if failures:
        print("未全对的格子：")
        for row in failures:
            print("  %s/%s/r%s %s %s" % (row["task"], row["arm"], row["round"], row["keys_ok"], row["notes"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
