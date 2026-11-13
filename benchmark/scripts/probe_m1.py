#!/usr/bin/env python3
"""M1（Bash 输出压缩）两侧机制的直接探针。

对同一条 fixture 命令，分别走两条链路，测量「模型最终看到的字节数」：

  tokless   PreToolUse(Bash) -> `tokless rtk-hook claude` 改写命令 -> 执行改写后的命令
  optimizer PostToolUse(Bash) -> hooks/posttooluse_runner.py 返回 updatedToolOutput

两条链路的产物之后都要经过宿主（Claude Code 2.1.311）自己的结果上限层：
超过 bash 输出上限（默认 30000 字符）时，宿主把全文落盘，只把前 2000 字符
的预览交给模型。本脚本用 host_view() 复现这一层，以便比较「模型实际看到多少」。

注意：命令原文与输出可能包含 fixture 里的假凭据。脚本只记录字节数与
「原字符串是否原样保留」的布尔值，不把凭据内容写进任何产物。
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

BASE = Path(os.environ.get("BENCH_BASE", "/tmp/tokbench"))
FIXTURE_WS = BASE / "fixture" / "workspace"
TOKLESS_BIN = BASE / "toolchain" / "tokless"
# 探针用独立的 HOME，避免把状态写进正式采样用的 arm HOME。
# tokless 的 arm HOME 有 2.4G，不便复制；rtk 钩子只依赖 rtk 二进制与
# selection.json（缺省即视为选中），空 HOME 与 arm 的选中状态一致。
# token-optimizer 的压缩路径有本地缓存，探针 HOME 预先用 arm HOME 的副本
# 填充，以免冷启动差异混进预算测量。
TOKLESS_HOME = Path(os.environ.get("PROBE_TOKLESS_HOME", str(BASE / "probe" / "home-tokless")))
OPTIMIZER_HOME = Path(os.environ.get("PROBE_OPTIMIZER_HOME", str(BASE / "probe" / "home-optimizer")))
OPTIMIZER_ROOT = Path(
    os.environ.get(
        "BENCH_OPTIMIZER_ROOT",
        str(Path(__file__).resolve().parents[2] / "token-optimizer"),
    )
)

# 宿主层常量（从 claude 2.1.311 二进制中读出）
HOST_BASH_OUTPUT_MAX_CHARS = 30000
HOST_PREVIEW_CHARS = 2000
HOST_WRAPPER_OVERHEAD = 240  # <persisted-output> 头尾约 240 字节
CMD_TIMEOUT = 180

# token-optimizer 会按会话落状态（重复执行同一命令时直接返回「与上次相同」
# 的占位）。为了让每个探针项互相独立、结果可复现，每个探针项使用独立会话 id。
RUN_STAMP = time.strftime("%Y%m%dT%H%M%S", time.localtime())
SESSION_ID = "probe-m1"

# 会话 id 必须匹配 ^[a-zA-Z0-9_-]+$。token-optimizer 的
# session_store._sanitize_session_id 会把不合格的 id 映射成一个「每次调用都
# 重新生成随机」的 fallback-<uuid12>（session_store.py:168-174，目的是避免
# 不同会话共用一个库）；于是「归档写入」与「写入后校验」落在两个不同目录，
# 校验失败后压缩结果被退回为原文。真实 Claude Code 的会话 id 是 UUID，符合
# 该约束；探针的标签里带 . 或空格，所以这里先做归一化。
_TOKEN_SAFE = re.compile(r"[^A-Za-z0-9_-]+")


def new_session(label: str) -> str:
    global SESSION_ID
    safe = _TOKEN_SAFE.sub("_", label).strip("_") or "case"
    SESSION_ID = "probe-m1-%s-%s" % (RUN_STAMP, safe)
    return SESSION_ID

COMMANDS = [
    ("build.log", "cat assets/build.log"),
    ("buildlog-script", "bash bin/emit_buildlog.sh"),
    ("inventory.csv", "cat assets/inventory.csv"),
    ("replay.py", "cat codec/replay.py"),
    ("replay-head200", "sed -n '1,200p' codec/replay.py"),
    ("grep-warn-head", "grep -n WARN assets/build.log | head -40"),
    # 无管线的 grep：rtk 才会改写（hasShellPipe 会挡住上面那条）。用来观察
    # 「搜索结果压缩」在 tokless 侧到底有没有对应能力。
    ("grep-warn-all", "grep -n WARN assets/build.log"),
    # 多文件、`文件:行号:内容` 形状的检索输出：才是 token-optimizer
    # `_compress_search_results` 认的形状（bash_compress.py:1909-1946，
    # 要求 ≥30 行且匹配 ^(.+?):(\d+):(.*)$）。
    ("grep-warn-recurse", "grep -rn WARN ."),
    # 多文件、密集命中、且不含 WARN/ERROR 的检索输出：用来把「检索压缩」与
    # token-optimizer 的「告警行逐字回填」分开测量（回填见 bash_compress.py
    # 中 preserved_reinject.find_priority_lines 的调用）。
    ("grep-def-dense", "grep -rn 'def ' ."),
    ("grep-corpus", "grep -rn zephyrquorum corpus/"),
    ("grep-anchor", "grep -rn ANCHOR codec/"),
    # 落在宿主「全量呈现」区（<30000 字符）内的中等体积读取：两侧都不过
    # 宿主落盘层，是最能看出压缩差异的一档。
    ("buildlog-head700", "sed -n '1,700p' assets/build.log"),
    ("wc-lines", "wc -l codec/*.py codec/client/src/*.ts"),
    ("ls-assets", "ls -la assets"),
    ("canary.env", "cat secrets/canary.env"),
]


def run_shell(command: str, cwd: Path) -> tuple[bytes, bytes]:
    proc = subprocess.run(
        ["bash", "-c", command],
        cwd=str(cwd),
        capture_output=True,
        timeout=CMD_TIMEOUT,
    )
    return proc.stdout, proc.stderr


def host_view(nbytes: int) -> int:
    """宿主截断层之后模型看到的字节数。"""
    if nbytes <= HOST_BASH_OUTPUT_MAX_CHARS:
        return nbytes
    return HOST_PREVIEW_CHARS + HOST_WRAPPER_OVERHEAD


def _decode(raw: bytes) -> str:
    return raw.decode("utf-8", "replace")


def tokless_front(command: str, cwd: Path, capture: bool = False) -> dict:
    """走 tokless 的 PreToolUse 钩子，返回改写后的命令与其输出。

    capture=True 时把改写后命令的 stdout 一并返回（仅在需要判定凭据是否
    原样进入模型可见文本时使用，调用方不得把内容写进产物）。
    """
    payload = json.dumps(
        {
            "session_id": SESSION_ID,
            "transcript_path": str(BASE / "probe" / "transcript.jsonl"),
            "cwd": str(cwd),
            "hook_event_name": "PreToolUse",
            "tool_name": "Bash",
            "tool_input": {"command": command},
        }
    )
    env = dict(os.environ)
    env["HOME"] = str(TOKLESS_HOME)
    env["CLAUDE_CONFIG_DIR"] = str(TOKLESS_HOME / ".claude")
    proc = subprocess.run(
        [str(TOKLESS_BIN), "rtk-hook", "claude"],
        input=payload,
        capture_output=True,
        text=True,
        cwd=str(cwd),
        env=env,
        timeout=CMD_TIMEOUT,
    )
    rewritten = command
    decision = ""
    try:
        out = json.loads(proc.stdout or "{}")
        hso = out.get("hookSpecificOutput") or {}
        decision = hso.get("permissionDecision", "")
        new_cmd = (hso.get("updatedInput") or {}).get("command")
        if isinstance(new_cmd, str) and new_cmd.strip():
            rewritten = new_cmd
    except Exception as exc:  # noqa: BLE001 - 钩子输出不可解析时按未改写处理
        decision = f"parse-error:{type(exc).__name__}"
    if rewritten == command:
        return {
            "rewritten": False,
            "command": rewritten,
            "decision": decision,
            "bytes": None,
            "text": None,
            "stderr_note": (proc.stderr or "").strip()[:120],
        }
    stdout, _stderr = run_shell(rewritten, cwd)
    return {
        "rewritten": True,
        "command": rewritten,
        "decision": decision,
        "bytes": len(stdout),
        "text": _decode(stdout) if capture else None,
        "stderr_note": (proc.stderr or "").strip()[:120],
    }


def optimizer_front(stdout: bytes, stderr: bytes, command: str, cwd: Path) -> dict:
    """走 token-optimizer 的 PostToolUse 钩子，返回替换后的输出。"""
    payload = json.dumps(
        {
            "session_id": SESSION_ID,
            "transcript_path": str(BASE / "probe" / "transcript.jsonl"),
            "cwd": str(cwd),
            "hook_event_name": "PostToolUse",
            "tool_name": "Bash",
            "tool_input": {"command": command},
            "tool_response": {
                "stdout": stdout.decode("utf-8", "replace"),
                "stderr": stderr.decode("utf-8", "replace"),
                "interrupted": False,
                "isImage": False,
            },
        }
    )
    env = dict(os.environ)
    env["HOME"] = str(OPTIMIZER_HOME)
    env["CLAUDE_CONFIG_DIR"] = str(OPTIMIZER_HOME / ".claude")
    env["CLAUDE_PLUGIN_ROOT"] = str(OPTIMIZER_ROOT)
    env["CLAUDE_SESSION_ID"] = SESSION_ID
    launcher = OPTIMIZER_ROOT / "hooks" / "python-launcher.sh"
    proc = subprocess.run(
        [str(launcher), str(OPTIMIZER_ROOT / "hooks" / "run.py"), "hooks/posttooluse_runner.py"],
        input=payload,
        capture_output=True,
        text=True,
        cwd=str(cwd),
        env=env,
        timeout=CMD_TIMEOUT,
    )
    replaced = False
    new_text = None
    try:
        out = json.loads(proc.stdout or "{}")
        uto = (out.get("hookSpecificOutput") or {}).get("updatedToolOutput") or {}
        if isinstance(uto, dict) and isinstance(uto.get("stdout"), str):
            replaced = True
            new_text = uto["stdout"]
    except Exception:  # noqa: BLE001 - 空输出即未替换
        pass
    note = ""
    for line in (proc.stderr or "").splitlines():
        if "budget exceeded" in line:
            note = line.strip()[:120]
            break
    return {
        "replaced": replaced,
        "bytes": None if new_text is None else len(new_text.encode("utf-8")),
        "stderr_note": note,
        "text": new_text,
    }


def run_sweep(ws_root: Path, out_path: Path) -> int:
    """按输出体积扫描 token-optimizer 的 Bash 压缩，找出延迟预算的实际上限。"""
    # 阶梯覆盖三个区间：宿主全量呈现区（<30000 字符）、宿主落盘区（>30000
    # 字符）、以及实测中在 262KB 与 469KB 之间出现的预算超时拐点。
    sizes = [4096, 8192, 16384, 24576, 32768, 65536, 131072, 222822, 262144,
             327680, 393216, 458752, 524288]
    rows = []
    for target in sizes:
        text = []
        total = 0
        i = 0
        while total < target:
            line = "[%9.3f] CC src/core/shard_%03d.o\n" % (i * 0.037, i % 1000)
            if i % 97 == 0:
                line = "[%9.3f] WARN narrowing conversion of `offset`\n" % (i * 0.037)
            text.append(line)
            total += len(line)
            i += 1
        blob = "".join(text)
        stdout_b = blob.encode()
        new_session("sweep-%d" % target)
        started = time.monotonic()
        opt = optimizer_front(stdout_b, b"", "cat synthetic.log", ws_root)
        elapsed = time.monotonic() - started
        note = opt.get("stderr_note") or ""
        rows.append(
            [
                target,
                len(stdout_b),
                "yes" if opt["replaced"] else "no",
                "" if opt["bytes"] is None else opt["bytes"],
                "" if opt["bytes"] is None else host_view(opt["bytes"]),
                "%.2f" % elapsed,
                note,
            ]
        )
        if opt.get("text"):
            sample = opt["text"][:60].replace("\n", "\\n")
        else:
            sample = ""
        print("\t".join(str(c) for c in rows[-1]) + "\t" + sample, file=sys.stderr)

    header = ["target_bytes", "raw_bytes", "opt_replaced", "opt_bytes", "opt_host_bytes", "opt_seconds", "notes"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        fh.write("\t".join(header) + "\n")
        for row in rows:
            fh.write("\t".join(str(c) for c in row) + "\n")
    print("wrote", out_path, file=sys.stderr)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ws", default=str(FIXTURE_WS))
    ap.add_argument("--out", default=str(BASE / "findings" / "probe_m1.tsv"))
    ap.add_argument(
        "--sweep",
        action="store_true",
        help="按输出体积扫描 optimizer 的 Bash 压缩上限（产物为体积阶梯表）",
    )
    args = ap.parse_args()
    ws = Path(args.ws)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    if args.sweep:
        return run_sweep(ws, out_path)

    canary_token = ""
    canary = ws / "secrets" / "canary.env"
    if canary.is_file():
        for line in canary.read_text(encoding="utf-8").splitlines():
            if line.startswith("GITHUB_TOKEN="):
                canary_token = line.split("=", 1)[1].strip()

    rows = []
    header = [
        "case", "command", "raw_bytes", "host_bytes",
        "rtk_rewritten", "rtk_cmd", "rtk_bytes", "rtk_host_bytes",
        "opt_replaced", "opt_bytes", "opt_host_bytes", "notes",
    ]
    for case, command in COMMANDS:
        new_session(case)
        stdout, stderr = run_shell(command, ws)
        raw = len(stdout)
        rtk = tokless_front(command, ws, capture=True)
        opt = optimizer_front(stdout, stderr, command, ws)
        notes = []
        if rtk.get("stderr_note"):
            notes.append("rtk:" + rtk["stderr_note"])
        if opt.get("stderr_note"):
            notes.append("opt:" + opt["stderr_note"])
        if canary_token and case == "canary.env":
            # 判定凭据是否原样进入「模型可见文本」。可见文本 = 压缩后的输出，
            # 没有压缩时 = 实际执行的命令的 stdout。只记录布尔值。
            if opt["replaced"] and opt.get("text") is not None:
                visible = opt["text"]
                source = "opt"
            elif rtk["rewritten"] and rtk.get("text") is not None:
                visible = rtk["text"]
                source = "rtk"
            else:
                visible = _decode(stdout)
                source = "raw"
            notes.append(
                "token_verbatim=%s@%s" % ("yes" if canary_token in visible else "no", source)
            )
        rows.append(
            [
                case,
                command,
                raw,
                host_view(raw),
                "yes" if rtk["rewritten"] else "no",
                rtk["command"] if rtk["rewritten"] else "",
                "" if rtk["bytes"] is None else rtk["bytes"],
                "" if rtk["bytes"] is None else host_view(rtk["bytes"]),
                "yes" if opt["replaced"] else "no",
                "" if opt["bytes"] is None else opt["bytes"],
                "" if opt["bytes"] is None else host_view(opt["bytes"]),
                " | ".join(notes),
            ]
        )

    with out_path.open("w", encoding="utf-8") as fh:
        fh.write("\t".join(header) + "\n")
        for row in rows:
            fh.write("\t".join(str(c) for c in row) + "\n")

    print("\t".join(header))
    for row in rows:
        print("\t".join(str(c) for c in row))
    print("\nwrote", out_path, file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
