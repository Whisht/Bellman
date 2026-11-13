#!/usr/bin/env bash
# 用途：按「任务 × 臂 × 轮次」交错轮换跑完整套基准，先跑一轮预热并丢弃。
# 运行：bash benchmark/scripts/run_all.sh [--rounds N] [--tasks "t1 t2"] [--arms "baseline tokless optimizer"] [--no-warmup] [--force]
# 说明：
#   - 交错轮换：臂的顺序按 (任务序号 + 轮次) 旋转，抵消固定顺序带来的缓存/限流偏差。
#   - 断点续跑：默认跳过已有 metrics.tsv 的格子；--force 重跑。
#   - 预热轮的产物写到 $RUNS/warmup，不进入正式 index.tsv。
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

RUN_ONE="$BENCH/scripts/run_one.sh"

rounds=3
tasks=("${TASKS_ALL[@]}")
arms=("${ARMS_ALL[@]}")
warmup=1
force=0

while [ $# -gt 0 ]; do
  case "$1" in
    --rounds) rounds="$2"; shift 2 ;;
    --tasks) read -r -a tasks <<< "$2"; shift 2 ;;
    --arms) read -r -a arms <<< "$2"; shift 2 ;;
    --no-warmup) warmup=0; shift ;;
    --force) force=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "未知参数：$1" >&2; exit 2 ;;
  esac
done

mkdir -p "$RUNS" "$BASE/logs"

if [ "$warmup" -eq 1 ]; then
  echo "== 预热轮（产物进 $RUNS/warmup，丢弃）=="
  for arm in "${arms[@]}"; do
    BENCH_RUN_ROOT="$RUNS/warmup" bash "$RUN_ONE" "$arm" "${tasks[0]}" "w"
  done
fi

total=$(( ${#tasks[@]} * ${#arms[@]} * rounds ))
done_count=0
echo "== 正式运行：${#tasks[@]} 任务 × ${#arms[@]} 臂 × $rounds 轮 = $total 次 =="

for (( r=1; r<=rounds; r++ )); do
  for (( ti=0; ti<${#tasks[@]}; ti++ )); do
    task="${tasks[$ti]}"
    n=${#arms[@]}
    for (( k=0; k<n; k++ )); do
      arm="${arms[$(( (ti + r + k) % n ))]}"
      dir="$RUNS/$task/$arm/r$r"
      done_count=$((done_count + 1))
      if [ "$force" -eq 0 ] && [ -s "$dir/metrics.tsv" ]; then
        echo "[$done_count/$total] 跳过（已有产物）：$task/$arm/r$r"
        continue
      fi
      echo "[$done_count/$total] ==="
      bash "$RUN_ONE" "$arm" "$task" "$r" || echo "  run_one 返回非零：$task/$arm/r${r}（样本保留）"
    done
  done
done

echo "== 全部结束 =="
