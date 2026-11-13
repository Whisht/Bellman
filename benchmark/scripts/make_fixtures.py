#!/usr/bin/env python3
"""生成对比测试用的 fixture、命令脚本与答案真值。

约束：
- 只用标准库；同一 --seed 重复运行结果逐字节一致。
- 真值写在 workspace 之外，被测模型读不到答案。
- 生成结果由 --selfcheck 重新扫描校验，不依赖写入时的记录。
"""

from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

SEED_DEFAULT = 20261112

BUILD_LOG_LINES = 12000
BUILD_LOG_WARN_LINES = 240
BUILD_LOG_TRACE_LINE = 8213
BUILD_LOG_FINAL_LINE = BUILD_LOG_LINES - 2
INVENTORY_ROWS = 9000
INVENTORY_DRIFT_ROWS = 512
SKU_LINE = 7342  # 1 起算，含表头
SKU_NAME = "ZQ-0007341"
SKU_QTY = 9137
CORPUS_FILES = 40

CODE_FILES_PY = {
    "eventstore.py": 48000,
    "replay.py": 64000,
    "ledger.py": 32000,
    "projection.py": 24000,
}
CODE_FILES_TS = {
    "transport.ts": 40000,
    "codec.ts": 28000,
    "index.ts": 20000,
}

# 检索语料里植入的词及每个词的总出现次数。词池与正文都不含这些词，
# 所以出现次数只由植入决定；每个植入词单独占一行，grep -c 与出现次数一致。
PLANTED_TERMS = {
    "zephyrquorum": [5, 4, 3, 3, 1, 1],
    "quorum_drift_ms": [4, 3, 2, 2],
    "helio-cache-ttl": [5, 4, 3, 3, 2, 2, 2, 1, 1],
}

ANCHOR_FILES = {
    "replay.py": (1200, "replay"),
    "eventstore.py": (900, "eventstore"),
    "ledger.py": (500, "ledger"),
}

VERBS = ["load", "merge", "apply", "replay", "fold", "derive", "compact", "verify", "emit", "scan", "index", "flush"]
NOUNS = ["batch", "segment", "ledger", "snapshot", "cursor", "window", "manifest", "offset", "shard", "digest"]
REGIONS = ["ap-east", "ap-south", "eu-west", "us-east", "us-west", "sa-east"]
QUIET_STATUSES = ["ok", "stale", "unknown"]
WORDS = [
    "shard", "segment", "cursor", "manifest", "epoch", "digest", "window", "offset", "latency",
    "pipeline", "replica", "quota", "backfill", "snapshot", "planner", "executor", "tombstone",
    "watermark", "lease", "handoff", "fence", "stripe", "barrier", "fanout", "checkpoint",
    "compaction", "retention", "tailer", "applier", "scheduler", "admission", "budget",
]

GENERATED_HEADER = {
    "py": "# 自动生成的 fixture，供 token 优化对比测试读取；不要手工修改。",
    "ts": "// 自动生成的 fixture，供 token 优化对比测试读取；不要手工修改。",
    "md": "<!-- 自动生成的 fixture，供 token 优化对比测试读取；不要手工修改。 -->",
}

# eventstore.py 的前置片段。apply_batch 是 T3 的编辑目标，
# 条件行必须逐字固定，评分脚本按它定位改动。
EVENTSTORE_HEAD = '''\
def shard_of(event: dict[str, object]) -> str:
    """按事件键推导分片名。"""
    return str(event.get("shard", "s0"))


def apply_batch(store: dict[str, list[dict[str, object]]], batch: list[dict[str, object]]) -> int:
    """写入一批事件，返回写入条数。"""
    if not batch:
        return 0
    written = 0
    for event in batch:
        store.setdefault(shard_of(event), []).append(event)
        written += 1
    return written


def read_batch(store: dict[str, list[dict[str, object]]], shard: str) -> list[dict[str, object]]:
    """读取单个分片的全部事件。"""
    return list(store.get(shard, []))


'''


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def rng_for(seed: int, tag: str) -> random.Random:
    return random.Random(f"{seed}:{tag}")


def hex_token(rng: random.Random, chars: int) -> str:
    return "".join(rng.choice("0123456789abcdef") for _ in range(chars))


def py_function(idx: int, rng: random.Random) -> list[str]:
    verb = rng.choice(VERBS)
    noun = rng.choice(NOUNS)
    name = f"{verb}_{noun}_{idx:02d}"
    step = rng.randint(2, 97)
    lines = [
        f"def {name}(items: list[dict[str, object]]) -> int:",
        f'    """{verb} {noun} 聚合，累加同 kind 的条目数。"""',
        "    total = 0",
        "    for item in items:",
    ]
    for _ in range(rng.randint(1, 5)):
        lines.append(f'        if item.get("kind") == "{noun}":')
        lines.append(f"            total += {step}")
        lines.append("        else:")
        lines.append(f"            total -= {step}")
    lines.append(f'    logger.debug("{name} total=%s items=%s", total, len(items))')
    lines.append("    return total")
    lines.append("")
    lines.append("")
    return lines


def ts_function(idx: int, rng: random.Random) -> list[str]:
    verb = rng.choice(VERBS)
    noun = rng.choice(NOUNS)
    name = f"{verb}{noun.capitalize()}{idx:02d}"
    step = rng.randint(2, 97)
    lines = [
        f"export function {name}(rows: readonly Row[]): number {{",
        "  let total = 0;",
        "  for (const row of rows) {",
        f'    if (row.kind === "{noun}") {{',
        f"      total += {step};",
        "    } else {",
        f"      total -= {step};",
        "    }",
        "  }",
        "  return total;",
        "}",
        "",
        "",
    ]
    return lines


def gen_code_file(kind: str, target: int, rng: random.Random, head: str = "") -> str:
    if kind == "py":
        lines = [
            GENERATED_HEADER["py"],
            "",
            "from __future__ import annotations",
            "",
            "import logging",
            "from collections.abc import Iterable",
            "from dataclasses import dataclass, field",
            "",
            "logger = logging.getLogger(__name__)",
            "",
            f"MAX_INFLIGHT = {rng.randint(64, 4096)}",
            f"DEFAULT_WINDOW = {rng.randint(8, 512)}",
            "",
            "",
        ]
        body = py_function
    else:
        lines = [
            GENERATED_HEADER["ts"],
            "",
            'import type { Clock } from "./clock";',
            'import { Row } from "./row";',
            "",
            "export interface Row {",
            "  readonly kind: string;",
            "  readonly weight: number;",
            "}",
            "",
            "export type RowId = string;",
            "",
            f"export const MAX_INFLIGHT = {rng.randint(64, 4096)};",
            "",
        ]
        body = ts_function

    if head:
        lines.extend(head.splitlines())
        lines.append("")

    idx = 0
    size = sum(len(line) + 1 for line in lines)
    while size < target:
        idx += 1
        block = body(idx, rng)
        lines.extend(block)
        size += sum(len(line) + 1 for line in block)

    if kind == "py":
        lines.extend(
            [
                'if __name__ == "__main__":',
                "    logging.basicConfig(level=logging.DEBUG)",
                "    logger.debug(\"standalone run\")",
                "",
            ]
        )
    return "\n".join(lines)


def insert_anchor(text: str, line_no: int, token: str) -> tuple[str, int]:
    lines = text.split("\n")
    index = min(line_no - 1, len(lines) - 1)
    prefix = "# " if not lines[index].startswith("//") else "// "
    lines.insert(index, f"{prefix}ANCHOR: {token}")
    return "\n".join(lines), index + 1


def gen_build_log() -> tuple[str, dict[str, object]]:
    rng = rng_for(SEED_DEFAULT, "buildlog")
    warn_rng = rng_for(SEED_DEFAULT, "buildlog-warn")
    candidates = [
        i
        for i in range(30, BUILD_LOG_LINES - 20)
        if i not in (BUILD_LOG_TRACE_LINE, BUILD_LOG_FINAL_LINE)
    ]
    warn_lines = set(warn_rng.sample(candidates, BUILD_LOG_WARN_LINES))

    trace_token = hex_token(rng_for(SEED_DEFAULT, "trace"), 32)
    final_token = hex_token(rng_for(SEED_DEFAULT, "final"), 32)
    phases = ["CC", "LD", "AR", "PY", "WR", "GEN"]
    warnings = [
        "unused variable `pending` in {}-{}",
        "implicit declaration of function `fold_shard`",
        "comparison between signed and unsigned integer expressions",
        "narrowing conversion of `offset` from `long` to `int`",
        "unused parameter `retries` in template instantiation",
    ]
    lines = []
    for i in range(1, BUILD_LOG_LINES + 1):
        stamp = i * 0.0371
        if i == BUILD_LOG_TRACE_LINE:
            lines.append(f"[ {stamp:9.3f}] trace TRACE-ANCHOR={trace_token}")
            continue
        if i == BUILD_LOG_FINAL_LINE:
            lines.append(f"[ {stamp:9.3f}] FINAL_SIG={final_token} toolchain manifest digest")
            continue
        if i in warn_lines:
            text = warnings[i % len(warnings)].format(VERBS[i % len(VERBS)], NOUNS[i % len(NOUNS)])
            lines.append(f"[ {stamp:9.3f}] WARN {text}")
            continue
        if i == BUILD_LOG_LINES:
            lines.append(f"[ {stamp + 4.2:9.3f}] done in {stamp + 4.2:.1f}s")
            continue
        phase = phases[i % len(phases)]
        noun = NOUNS[i % len(NOUNS)]
        lines.append(f"[ {stamp:9.3f}] {phase} src/core/{noun}_{i % 997:03d}.o")
    facts = {
        "build_log_lines": BUILD_LOG_LINES,
        "warn_count": BUILD_LOG_WARN_LINES,
        "trace_anchor": trace_token,
        "final_sig": final_token,
    }
    return "\n".join(lines) + "\n", facts


def gen_inventory() -> tuple[str, dict[str, object]]:
    rng = rng_for(SEED_DEFAULT, "inventory")
    drift_lines = set(rng.sample(range(2, INVENTORY_ROWS + 1), INVENTORY_DRIFT_ROWS))
    drift_lines.discard(SKU_LINE)
    rows = ["sku,region,qty,status,updated"]
    for i in range(2, INVENTORY_ROWS + 2):
        sku = f"ZQ-{i - 1:07d}"
        region = REGIONS[i % len(REGIONS)]
        if i == SKU_LINE:
            sku, qty, status = SKU_NAME, SKU_QTY, "ok"
        else:
            qty = 100 + (i * 37) % 8900
            status = "drift" if i in drift_lines else QUIET_STATUSES[i % len(QUIET_STATUSES)]
        rows.append(f"{sku},{region},{qty},{status},2026-{(i % 12) + 1:02d}-{(i % 28) + 1:02d}")
    facts = {
        "inventory_rows": INVENTORY_ROWS,
        "drift_rows": INVENTORY_DRIFT_ROWS,
        "sku_name": SKU_NAME,
        "sku_qty": SKU_QTY,
        "sku_line": SKU_LINE,
    }
    return "\n".join(rows) + "\n", facts


def gen_corpus() -> tuple[dict[str, str], dict[str, object]]:
    rng = rng_for(SEED_DEFAULT, "corpus")
    term_rng = rng_for(SEED_DEFAULT, "corpus-terms")
    files: dict[str, list[str]] = {f"note-{i:02d}.md": [] for i in range(1, CORPUS_FILES + 1)}
    assignment: dict[str, list[str]] = {}
    for term, counts in PLANTED_TERMS.items():
        picks = sorted(term_rng.sample(list(files), len(counts)))
        assignment[term] = picks
        for path, count in zip(picks, counts):
            files[path].extend([term] * count)

    out: dict[str, str] = {}
    for name, terms in files.items():
        paragraphs = []
        rng.shuffle(terms)
        title = f"# {name.removesuffix('.md')} 运维笔记"
        paragraphs.append(title)
        paragraphs.append("")
        body_blocks = rng.randint(5, 11) + len(terms)
        slots = rng.sample(range(body_blocks), len(terms))
        term_slot = dict(zip(slots, terms))
        for block in range(body_blocks):
            if block in term_slot:
                term = term_slot[block]
                paragraphs.append(f"The {term} counter is reset on every shard handoff in {rng.choice(REGIONS)}.")
                paragraphs.append("")
                continue
            sentences = []
            for _ in range(rng.randint(2, 5)):
                sentences.append(
                    f"The {rng.choice(WORDS)} {rng.choice(WORDS)} keeps the {rng.choice(WORDS)} "
                    f"within {rng.randint(2, 900)} ms during {rng.choice(WORDS)}."
                )
            paragraphs.append(" ".join(sentences))
            paragraphs.append("")
        text = GENERATED_HEADER["md"] + "\n\n" + "\n".join(paragraphs).rstrip("\n") + "\n"
        out[f"corpus/{name}"] = text

    counts_per_file: dict[str, int] = {}
    for path, text in out.items():
        hits = sum(1 for line in text.split("\n") if "zephyrquorum" in line)
        if hits:
            counts_per_file[path] = hits
    top_file = sorted(counts_per_file.items(), key=lambda item: (-item[1], item[0]))[0][0]
    first_line = next(
        i for i, line in enumerate(out[top_file].split("\n"), start=1) if "zephyrquorum" in line
    )
    facts = {
        "corpus_files": CORPUS_FILES,
        "zephyrquorum_hits": sum(PLANTED_TERMS["zephyrquorum"]),
        "quorum_drift_ms_hits": sum(PLANTED_TERMS["quorum_drift_ms"]),
        "helio_cache_ttl_hits": sum(PLANTED_TERMS["helio-cache-ttl"]),
        "zq_top_file": top_file,
        "zq_top_file_first_line": first_line,
    }
    return out, facts


def gen_bellman_facts(bellman: Path) -> dict[str, object]:
    facts: dict[str, object] = {}
    typ = sorted(bellman.glob("*.typ"))
    if typ:
        text = typ[0].read_text(encoding="utf-8")
        lines = text.split("\n")
        facts["main_typ_lines"] = len(lines) - 1 if text.endswith("\n") else len(lines)
        facts["main_typ_import_lines"] = sum(1 for line in lines if line.strip().startswith("#import"))
        facts["main_typ_name"] = typ[0].name
    notes = sorted(p for p in bellman.glob("*.md"))
    for path in notes:
        text = path.read_text(encoding="utf-8")
        lines = text.split("\n")
        facts[f"lines::{path.name}"] = len(lines) - 1 if text.endswith("\n") else len(lines)
    return facts


def build(workspace: Path, bellman: Path | None, seed: int) -> dict[str, object]:
    facts: dict[str, object] = {"seed": seed}
    generated: dict[str, str] = {}

    for name, target in CODE_FILES_PY.items():
        rng = rng_for(seed, f"py:{name}")
        head = EVENTSTORE_HEAD if name == "eventstore.py" else ""
        generated[f"codec/{name}"] = gen_code_file("py", target, rng, head)
    for name, target in CODE_FILES_TS.items():
        rng = rng_for(seed, f"ts:{name}")
        generated[f"codec/client/src/{name}"] = gen_code_file("ts", target, rng)
    facts["ts_files"] = len(CODE_FILES_TS)

    for rel, (line_no, tag) in ANCHOR_FILES.items():
        token = f"{tag}-{hex_token(rng_for(seed, f'anchor:{tag}'), 12)}"
        text, actual_line = insert_anchor(generated[f"codec/{rel}"], line_no, token)
        generated[f"codec/{rel}"] = text
        facts[f"{tag}_anchor"] = token
        facts[f"{tag}_anchor_line"] = actual_line

    corpus, corpus_facts = gen_corpus()
    generated.update(corpus)
    facts.update(corpus_facts)

    build_log, build_facts = gen_build_log()
    facts.update(build_facts)
    generated["assets/build.log"] = build_log

    inventory, inventory_facts = gen_inventory()
    facts.update(inventory_facts)
    generated["assets/inventory.csv"] = inventory

    eventstore_lines = generated["codec/eventstore.py"].split("\n")
    facts["apply_batch_if_line"] = next(
        i for i, line in enumerate(eventstore_lines, start=1) if line.strip() == "if not batch:"
    )
    facts["codec_py_lines"] = sum(
        len(generated[f"codec/{name}"].split("\n")) - 1 for name in CODE_FILES_PY
    )
    facts["ledger_defs"] = sum(
        1 for line in generated["codec/ledger.py"].split("\n") if line.startswith("def ")
    )
    facts["ts_bytes_total"] = sum(
        len(generated[f"codec/client/src/{name}"].encode("utf-8")) for name in CODE_FILES_TS
    )

    generated["bin/emit_buildlog.sh"] = EMIT_BUILDLOG
    generated["bin/emit_inventory.sh"] = EMIT_INVENTORY
    generated["bin/emit_code_stats.sh"] = EMIT_CODE_STATS
    generated["secrets/canary.env"] = gen_canary()

    for rel, text in generated.items():
        write_text(workspace / rel, text)
    for script in ("bin/emit_buildlog.sh", "bin/emit_inventory.sh", "bin/emit_code_stats.sh"):
        (workspace / script).chmod(0o755)

    if bellman is not None and bellman.is_dir():
        facts.update(gen_bellman_facts(bellman))
    return facts


EMIT_BUILDLOG = """#!/usr/bin/env bash
# 打印构建日志全文，并给出总行数。脚本按自身位置定位文件，可从任意目录调用。
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wc -l "$root/assets/build.log"
cat "$root/assets/build.log"
"""

EMIT_INVENTORY = """#!/usr/bin/env bash
# 打印库存表全文。脚本按自身位置定位文件，可从任意目录调用。
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat "$root/assets/inventory.csv"
"""

EMIT_CODE_STATS = """#!/usr/bin/env bash
# 打印各源文件的行数与字节数。脚本按自身位置定位文件，可从任意目录调用。
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wc -lc "$root"/codec/*.py "$root"/codec/client/src/*.ts
"""


def gen_canary() -> str:
    """生成假凭据，用于检查压缩链路是否泄漏或改写敏感值。

    值全部随机生成，每次构建不同，不进入仓库。
    """
    rng = rng_for(SEED_DEFAULT, "canary")
    body = [
        GENERATED_HEADER["md"].replace("<!-- ", "# ").replace(" -->", ""),
        f"AWS_ACCESS_KEY_ID=AKIA{hex_token(rng, 16).upper()}",
        f"AWS_SECRET_ACCESS_KEY={hex_token(rng, 40)}",
        f"GITHUB_TOKEN=ghp_{hex_token(rng, 36)}",
        f"SLACK_BOT_TOKEN=xoxb-{rng.randint(10**11, 10**12 - 1)}-{rng.randint(10**11, 10**12 - 1)}",
        f"DATABASE_URL=postgres://bench:{hex_token(rng, 16)}@127.0.0.1:5432/bench",
        f"ANTHROPIC_API_KEY=sk-ant-{hex_token(rng, 24)}",
    ]
    return "\n".join(body) + "\n"


def read_facts(path: Path) -> dict[str, str]:
    facts: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        key, _, value = line.partition("\t")
        facts[key] = value
    return facts


def write_facts(path: Path, facts: dict[str, object]) -> None:
    lines = [f"{key}\t{value}" for key, value in sorted(facts.items())]
    write_text(path, "\n".join(lines) + "\n")


def selfcheck(workspace: Path, facts: dict[str, str]) -> list[str]:
    problems: list[str] = []

    def scan(path: Path) -> list[str]:
        return path.read_text(encoding="utf-8").split("\n")

    for name in CODE_FILES_PY:
        path = workspace / "codec" / name
        size = path.stat().st_size
        if not 16000 <= size <= 90000:
            problems.append(f"{name} 尺寸 {size} 不在 16-90KB 内")
    for name in CODE_FILES_TS:
        path = workspace / "codec" / "client" / "src" / name
        size = path.stat().st_size
        if not 16000 <= size <= 60000:
            problems.append(f"{name} 尺寸 {size} 不在 16-60KB 内")

    corpus_paths = sorted((workspace / "corpus").glob("*.md"))
    if len(corpus_paths) != CORPUS_FILES:
        problems.append(f"语料文件数 {len(corpus_paths)} != {CORPUS_FILES}")

    corpus_texts = {path: scan(path) for path in corpus_paths}
    for term, key in (
        ("zephyrquorum", "zephyrquorum_hits"),
        ("quorum_drift_ms", "quorum_drift_ms_hits"),
        ("helio-cache-ttl", "helio_cache_ttl_hits"),
    ):
        hits = sum(1 for lines in corpus_texts.values() for line in lines if term in line)
        if hits != int(facts[key]):
            problems.append(f"语料 {term} 命中 {hits} != {facts[key]}")
        doubles = [
            path.name
            for path, lines in corpus_texts.items()
            for line in lines
            if line.count(term) > 1
        ]
        if doubles:
            problems.append(f"{term} 有同一行多次出现：{doubles[:3]}")
    top = sorted(
        (
            (sum(1 for line in lines if "zephyrquorum" in line), path.name)
            for path, lines in corpus_texts.items()
        ),
        key=lambda item: (-item[0], item[1]),
    )[0]
    if top[1] != Path(facts["zq_top_file"]).name:
        problems.append(f"zephyrquorum 最多命中的文件 {top[1]} != {facts['zq_top_file']}")
    if top[0] == sorted(
        (sum(1 for line in lines if "zephyrquorum" in line) for lines in corpus_texts.values()),
        reverse=True,
    )[1]:
        problems.append("zephyrquorum 首位与次位并列，top_file 不唯一")

    lines = scan(workspace / "assets" / "build.log")
    line_count = len(lines) - 1
    if line_count != BUILD_LOG_LINES:
        problems.append(f"构建日志行数 {line_count} != {BUILD_LOG_LINES}")
    warn_lines = [i for i, line in enumerate(lines, start=1) if line.split("] ", 1)[-1].startswith("WARN ")]
    if len(warn_lines) != BUILD_LOG_WARN_LINES:
        problems.append(f"WARN 行数 {len(warn_lines)} != {BUILD_LOG_WARN_LINES}")
    noisy = [
        i
        for i, line in enumerate(lines, start=1)
        if "warn" in line.lower() and i not in set(warn_lines)
    ]
    if noisy:
        problems.append(f"非 WARN 行出现 warn 字样：{noisy[:3]}")
    for key in ("trace_anchor", "final_sig"):
        hits = [i for i, line in enumerate(lines, start=1) if facts[key] in line]
        if len(hits) != 1:
            problems.append(f"{key} 在构建日志出现 {len(hits)} 次")
    if not lines[BUILD_LOG_TRACE_LINE - 1].endswith(facts["trace_anchor"]):
        problems.append(f"trace_anchor 不在第 {BUILD_LOG_TRACE_LINE} 行")
    if not lines[BUILD_LOG_FINAL_LINE - 1].startswith(f"[") or f"FINAL_SIG={facts['final_sig']}" not in lines[BUILD_LOG_FINAL_LINE - 1]:
        problems.append(f"final_sig 不在第 {BUILD_LOG_FINAL_LINE} 行")

    rows = scan(workspace / "assets" / "inventory.csv")
    data_rows = [row for row in rows if row]
    if len(data_rows) - 1 != INVENTORY_ROWS:
        problems.append(f"库存数据行数 {len(data_rows) - 1} != {INVENTORY_ROWS}")
    drift = sum(1 for row in rows if "drift" in row)
    if drift != INVENTORY_DRIFT_ROWS:
        problems.append(f"drift 行数 {drift} != {INVENTORY_DRIFT_ROWS}")
    sku_rows = [row for row in rows if row.startswith(f"{SKU_NAME},")]
    if len(sku_rows) != 1 or f",{SKU_QTY}," not in sku_rows[0]:
        problems.append(f"SKU {SKU_NAME} 行异常：{sku_rows[:2]}")
    if rows.index(sku_rows[0]) + 1 != SKU_LINE:
        problems.append(f"SKU 行号 {rows.index(sku_rows[0]) + 1} != {SKU_LINE}")

    for rel, (_, tag) in ANCHOR_FILES.items():
        text = (workspace / "codec" / rel).read_text(encoding="utf-8")
        hits = text.count(facts[f"{tag}_anchor"])
        if hits != 1:
            problems.append(f"{tag} anchor 出现 {hits} 次")
        if text.count("ANCHOR:") != 1:
            problems.append(f"{rel} 里 ANCHOR 标记数 != 1")

    py_lines = 0
    for name in CODE_FILES_PY:
        text = (workspace / "codec" / name).read_text(encoding="utf-8")
        if not text.endswith("\n"):
            problems.append(f"{name} 末尾缺少换行，wc -l 会少算一行")
        py_lines += len(text.split("\n")) - 1
    if py_lines != int(facts["codec_py_lines"]):
        problems.append(f"codec/*.py 行数 {py_lines} != {facts['codec_py_lines']}")

    eventstore = (workspace / "codec" / "eventstore.py").read_text(encoding="utf-8").split("\n")
    if eventstore[int(facts["apply_batch_if_line"]) - 1].strip() != "if not batch:":
        problems.append("apply_batch 的条件行位置与真值不符")

    ledger = (workspace / "codec" / "ledger.py").read_text(encoding="utf-8")
    defs = sum(1 for line in ledger.split("\n") if line.startswith("def "))
    if defs != int(facts["ledger_defs"]):
        problems.append(f"ledger.py 顶层 def 数 {defs} != {facts['ledger_defs']}")
    ts_bytes = sum(
        (workspace / "codec" / "client" / "src" / name).stat().st_size for name in CODE_FILES_TS
    )
    if ts_bytes != int(facts["ts_bytes_total"]):
        problems.append(f"ts 字节数 {ts_bytes} != {facts['ts_bytes_total']}")

    canary = (workspace / "secrets" / "canary.env").read_text(encoding="utf-8")
    if "AKIA" not in canary or "ghp_" not in canary:
        problems.append("canary 文件缺少假凭据")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description="生成 benchmark fixture 与真值")
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--facts-out", type=Path)
    parser.add_argument("--bellman", type=Path)
    parser.add_argument("--seed", type=int, default=SEED_DEFAULT)
    parser.add_argument("--selfcheck", action="store_true")
    args = parser.parse_args()

    facts = build(args.workspace, args.bellman, args.seed)
    if args.facts_out:
        args.facts_out.parent.mkdir(parents=True, exist_ok=True)
        write_facts(args.facts_out, facts)
    if args.selfcheck:
        stored = read_facts(args.facts_out) if args.facts_out else {k: str(v) for k, v in facts.items()}
        problems = selfcheck(args.workspace, stored)
        for problem in problems:
            print(f"FAIL {problem}")
        print(f"selfcheck: {len(problems)} 个问题")
        return 1 if problems else 0
    print(f"fixture 已生成：{args.workspace}（{len(facts)} 条真值）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
