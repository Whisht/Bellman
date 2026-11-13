#!/usr/bin/env bash
# 用途：准备 P3 所需的全部静态材料——fixture 工作区、tokless 快照二进制、三臂隔离 HOME。
#   fixtures  重新生成 fixture 工作区与真值（含 bellman 文本源）
#   arms      重建三臂隔离 HOME（tokless 臂会真的跑一次安装，需要网络）
#   all       先 fixtures 再 arms
# 运行：bash benchmark/scripts/prepare.sh all [--force]
# 说明：所有产物都在 $BASE=/tmp/tokbench 下，不进仓库；重复运行前会先清空对应目录。
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage () {
  sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}/  /'
}

build_fixtures () {
  echo "== fixtures =="
  rm -rf "$BASE/fixture"
  mkdir -p "$BASE/fixture"
  # -I：隔离模式，避免工作目录或 PYTHONPATH 里的同名模块被加载。
  python3 -I "$BENCH/scripts/make_fixtures.py" \
    --workspace "$FIXTURE_WS" \
    --facts-out "$FACTS" \
    --bellman "$BELLMAN"

  # 方案第 5 节：工作区 = bellman 的文本源 + fixture 覆盖层。PDF 不复制。
  local name
  for name in main.typ README.md Guidelines.md bellman-equation-notes.md bellman-equation-notes_副本.md; do
    cp "$BELLMAN/$name" "$FIXTURE_WS/$name"
  done

  python3 -I "$BENCH/scripts/make_fixtures.py" \
    --workspace "$FIXTURE_WS" \
    --facts-out "$FACTS" \
    --bellman "$BELLMAN" \
    --selfcheck

  echo "  workspace 文件数：$(find "$FIXTURE_WS" -type f | wc -l | tr -d ' ')"
  echo "  真值条数        ：$(wc -l < "$FACTS" | tr -d ' ')"
}

build_tokless_bin () {
  echo "== tokless 快照二进制 =="
  if [ -x "$TOKLESS_BIN" ] && [ "${FORCE:-0}" = "0" ]; then
    echo "  已存在：${TOKLESS_BIN}（$("$TOKLESS_BIN" --version | head -1)）"
    return 0
  fi
  mkdir -p "$BASE/toolchain"
  # go 1.22 的链接器在 macOS 26 上产出的二进制被 dyld 拒绝（missing LC_UUID），用 1.26.11。
  ( cd "$TOKLESS_SRC" && mise exec go@1.26.11 -- go build -trimpath \
      -ldflags "-s -w -X github.com/HoangP8/tokless/internal/util.Version=1.0.13-snapshot" \
      -o "$TOKLESS_BIN" ./cmd/tokless )
  echo "  构建完成：$TOKLESS_BIN [$("$TOKLESS_BIN" --version | head -1)]"
  echo "  sha256  ：$(shasum -a 256 "$TOKLESS_BIN" | cut -c1-16)"
  echo "  快照 HEAD：$(git -C "$TOKLESS_SRC" rev-parse HEAD)"
}

arm_home () { echo "$ARMS/$1/home"; }

build_arms () {
  echo "== 隔离 HOME（三臂）=="
  local arm
  for arm in "${ARMS_ALL[@]}"; do
    rm -rf "${ARMS:?}/$arm"
    mkdir -p "$ARMS/$arm/home/.claude"
    # 三臂起点完全一致：相同的 ANTHROPIC_* 路由面，其余为空。
    seed_routing_env "$(arm_home "$arm")/.claude/settings.json"
  done

  build_tokless_arm
  verify_arms
}

build_tokless_arm () {
  echo "== tokless 臂：默认安装 8 组件 =="
  local home log
  home="$(arm_home tokless)"
  log="$ARMS/tokless/install.log"
  # --no-autostart：不写登录自启，避免影响本机；代理由 run_one.sh 按需启动。
  if HOME="$home" CLAUDE_CONFIG_DIR="$home/.claude" "$TOKLESS_BIN" \
      --agents claude --yes --no-autostart --verbose > "$log" 2>&1; then
    echo "  安装退出码 0，日志：$log"
  else
    echo "  安装失败，保留日志：${log}（后续按实际接线情况继续）"
  fi
  # 安装后重新握手一次 info，记录实际接线状态。
  HOME="$home" CLAUDE_CONFIG_DIR="$home/.claude" "$TOKLESS_BIN" info > "$ARMS/tokless/info.log" 2>&1 || true
}

verify_arms () {
  echo "== 接线核对 =="
  local arm home
  for arm in "${ARMS_ALL[@]}"; do
    home="$(arm_home "$arm")"
    python3 - "$arm" "$home/.claude/settings.json" <<'PY'
import json, sys, os
arm, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as fh:
    d = json.load(fh)
hooks = d.get("hooks") or {}
n = sum(len(g.get("hooks", [])) for groups in hooks.values() for g in groups if isinstance(g, dict))
env = sorted((d.get("env") or {}).keys())
extra = sorted(k for k in d if k not in ("hooks", "env"))
extra_files = []
for dirpath, _dirs, files in os.walk(os.path.dirname(path)):
    for f in files:
        extra_files.append(os.path.relpath(os.path.join(dirpath, f), os.path.dirname(path)))
print(f"  {arm:9s} hook事件={len(hooks):2d} hook命令={n:2d} env={','.join(env) or '-'}"
      f" 其他键={','.join(extra) or '-'} 文件={len(extra_files)}")
PY
  done
}

FORCE=0
cmd="${1:-}"
[ "${2:-}" = "--force" ] && FORCE=1
require_routing_env
mkdir -p "$BASE"
case "$cmd" in
  fixtures) build_fixtures ;;
  arms)     build_tokless_bin; build_arms ;;
  all)      build_fixtures; build_tokless_bin; build_arms ;;
  *)        usage; exit 1 ;;
esac
