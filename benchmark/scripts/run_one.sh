#!/usr/bin/env bash
# 用途：跑一次基准运行（一个臂 × 一个任务 × 一轮）。
# 运行：bash benchmark/scripts/run_one.sh <baseline|tokless|optimizer> <t1..t5> <轮次>
# 说明：
#   - 每次运行都把 fixture 复制到固定的 $BASE/run/workspace，三臂使用完全相同的绝对路径，
#     避免路径长度差异混进 token 计数。
#   - 臂的 HOME 跨任务保留（真实的缓存/归档目录需要续存），靠交错轮换来抵消顺序效应。
#   - 运行结束后把 workspace 与 pristine 的差异写成 workspace.diff，供 score.py 判定改动范围。
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

arm="${1:-}"; task="${2:-}"; round="${3:-}"
[ -n "$arm" ] && [ -n "$task" ] && [ -n "$round" ] || {
  echo "用法：run_one.sh <baseline|tokless|optimizer> <t1..t5> <轮次>" >&2; exit 2
}
tools="$(tools_for "$task")" || exit 2
window="$(window_for "$task")"
home="$ARMS/$arm/home"
[ -d "$home" ] || { echo "臂 HOME 不存在：${home}（先跑 prepare.sh arms）" >&2; exit 2; }

require_routing_env
RUN_WS="$BASE/run/workspace"
# 预热轮的产物放进独立根目录，避免混进正式样本的 index.tsv。
RUN_ROOT="${BENCH_RUN_ROOT:-$RUNS}"
RUN_DIR="$RUN_ROOT/$task/$arm/r$round"
mkdir -p "$RUN_DIR"

# 固定路径的 workspace：先清空再复制，保证每次起点一致。
rm -rf "$BASE/run"
mkdir -p "$BASE/run"
cp -R "$FIXTURE_WS" "$RUN_WS"

# 只有 T5 需要真实自动压缩；其余任务显式清掉，避免继承外部取值。
if [ -n "$window" ]; then
  export CLAUDE_CODE_AUTO_COMPACT_WINDOW="$window"
else
  unset CLAUDE_CODE_AUTO_COMPACT_WINDOW
fi

plugin_args=()
if [ "$arm" = "optimizer" ]; then
  plugin_args=(--plugin-dir "$OPTIMIZER_PLUGIN")
fi
# bash 3.2 下空数组的展开（${arr[*]}）也会触发 set -u，所以另存一个标量做日志。
# 注意：这个值会被当作 argparse 参数值传给 extract.py，不能以 "-" 开头。
if [ ${#plugin_args[@]} -gt 0 ]; then plugin_desc="plugin-dir"; else plugin_desc="none"; fi

echo "[$arm/$task/r$round] tools=$tools window=${window:-未设置} plugin=$plugin_desc"
started="$(date +%s)"
set +e
(
  cd "$RUN_WS" || exit 1
  HOME="$home" CLAUDE_CONFIG_DIR="$home/.claude" \
  perl -e 'alarm shift; exec @ARGV' "$TIMEOUT_SECS" \
    "$(command -v claude)" -p "$(cat "$BENCH/tasks/$task.txt")" \
    --model "$MODEL" \
    --effort "$EFFORT" \
    --tools "$tools" \
    --permission-mode bypassPermissions \
    --setting-sources user \
    --settings '{}' \
    --strict-mcp-config \
    --disable-slash-commands \
    ${plugin_args[@]+"${plugin_args[@]}"} \
    --output-format stream-json \
    --include-hook-events \
    --verbose \
    --debug-file "$RUN_DIR/debug.log" \
    > "$RUN_DIR/stream.jsonl" 2> "$RUN_DIR/stderr.log"
)
exit_code=$?
set -e
elapsed=$(( $(date +%s) - started ))

# 与 pristine 比较：只保留文本差异，便于人工复核改动范围。
diff -ru "$FIXTURE_WS" "$RUN_WS" > "$RUN_DIR/workspace.diff" 2>&1 || true

python3 -I "$BENCH/scripts/extract.py" \
  --stream "$RUN_DIR/stream.jsonl" \
  --run-dir "$RUN_DIR" \
  --index "$RUN_ROOT/index.tsv" \
  --task "$task" --arm "$arm" --round "$round" \
  --exit-code "$exit_code" \
  --plugin "$plugin_desc" --tools "$tools" --window "$window"

{
  printf 'task\t%s\narm\t%s\nround\t%s\nstarted_epoch\t%s\nelapsed_secs\t%s\n' \
    "$task" "$arm" "$round" "$started" "$elapsed"
  printf 'workspace_diff_lines\t%s\n' "$(wc -l < "$RUN_DIR/workspace.diff" | tr -d ' ')"
  printf 'stream_bytes\t%s\n' "$(wc -c < "$RUN_DIR/stream.jsonl" | tr -d ' ')"
  printf 'stderr_head\t%s\n' "$(head -c 200 "$RUN_DIR/stderr.log" | tr '\n' ' ')"
} >> "$RUN_DIR/metrics.tsv"
echo "  用时 ${elapsed}s，退出码 ${exit_code}，产物：$RUN_DIR"
[ "$exit_code" -eq 0 ] || echo "  注意：非零退出码，样本按方案保留并在报告中披露。"
