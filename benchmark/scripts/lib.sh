#!/usr/bin/env bash
# 公共常量与前置检查。被其他脚本 source，不单独执行。
# shellcheck shell=bash

set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$LIB_DIR/../.." && pwd)"
BENCH="$ROOT/benchmark"

# 运行时目录放在 /tmp 而不是仓库内：仓库路径含空格，会把 settings 里未加引号的
# hook 命令拆散，造成与被测工具无关的失败。三臂使用完全相同的路径，公平性不受影响。
BASE="/tmp/tokbench"
FIXTURE_WS="$BASE/fixture/workspace"
FACTS="$BASE/fixture/facts.tsv"
ARMS="$BASE/arms"
RUNS="$BASE/runs"
BELLMAN="$ROOT/bellman"
TOKLESS_SRC="$ROOT/tokless"
TOKLESS_BIN="$BASE/toolchain/tokless"
OPTIMIZER_PLUGIN="$ROOT/token-optimizer"

ARMS_ALL=(baseline tokless optimizer)
# t1b 是 t1 去掉凭据那一步的对照片：同样的三条大输出命令，用来把「压缩效率」
# 与「凭据脱敏引发的复核循环」分开测量（原因见 report.md 的环境效应一节）。
TASKS_ALL=(t1 t1b t2 t3 t4 t5)

# 每个任务的允许工具集。三臂相同，来自方案第 5 节的表。
# 每个任务只给会走到被测机制的那一个/几个工具，避免模型绕开机制后三臂趋同：
#   t1/t2/t4 只给 Bash —— 走命令行输出，压缩机制才有机会生效（内置 Read/Grep 不经 Bash 压缩）。
#   t3/t5 只给 Read（t3 另给 Edit）—— 强制走 Read 路径，delta/结构图/长上下文压缩才有机会生效。
tools_for () {
  case "$1" in
    t1) echo "Bash" ;;
    t1b) echo "Bash" ;;
    t2) echo "Bash" ;;
    t3) echo "Read,Edit" ;;
    t4) echo "Bash" ;;
    t5) echo "Read" ;;
    *) echo "未知任务：$1" >&2; return 1 ;;
  esac
}

# 只有 T5 需要真实自动压缩；其余任务必须显式清掉该变量，避免继承到外部取值。
window_for () {
  case "$1" in
    t5) echo "100000" ;;
    *) echo "" ;;
  esac
}

MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-group/smart-split[1m]}"
EFFORT="medium"
TIMEOUT_SECS="${BENCH_TIMEOUT:-900}"

require_routing_env () {
  # 只检查存在性，绝不打印取值。
  : "${ANTHROPIC_BASE_URL:?ANTHROPIC_BASE_URL 未设置，无法访问本地路由}"
  : "${ANTHROPIC_AUTH_TOKEN:?ANTHROPIC_AUTH_TOKEN 未设置，无法访问本地路由}"
}

# 把真实 ~/.claude/settings.json 的 env 块中 ANTHROPIC_* 键写入目标 settings.json。
# 只复制路由面（ANTHROPIC_*），不复制 CLAUDE_CODE_* 等用户个性化设置，避免污染测量。
seed_routing_env () {
  local dest="$1"
  python3 - "$dest" <<'PY'
import json, os, sys

dest = sys.argv[1]
src = os.path.expanduser("~/.claude/settings.json")
with open(src, encoding="utf-8") as fh:
    env = (json.load(fh).get("env") or {})
routing = {k: v for k, v in env.items() if k.startswith("ANTHROPIC_") and isinstance(v, str) and v}
if not routing:
    sys.exit("真实 settings.json 的 env 块里没有 ANTHROPIC_* 键")
os.makedirs(os.path.dirname(dest), exist_ok=True)
with open(dest, "w", encoding="utf-8") as fh:
    json.dump({"env": routing}, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
print(f"{dest}: 写入 {len(routing)} 个 ANTHROPIC_* 键（取值不打印）")
PY
}
