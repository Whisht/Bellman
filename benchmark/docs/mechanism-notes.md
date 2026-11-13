# 机制核验笔记

本文件分两部分，核验方式相同（只记录机制事实，不做架构评价）：

- **第一部分**：`token-optimizer`（纯源码核验，未执行其任何脚本）。
- **第二部分（附录 A）**：`tokless`（含其安装的 8 个组件）。tokless 的能力只有装完才存在，因此这一部分包含在本基准自己的隔离 HOME 下运行官方安装器，以及若干条真实 `claude` 运行日志的证据；凡「实测」标记的结论都附产物路径。
- **附录 B**：三臂（baseline / token-optimizer / tokless）的环境差异核验，即对照实验的对称性证据。

范围：本文件只核验本地第三方源码 `token-optimizer` 的机制事实（入口、触发条件、默认开关状态、状态文件路径、阈值、可确定性手动触发点），不做架构评价。

- 核验对象仓库：`/Volumes/Samsumg 990 PRO/Codes/Test/tokless_vs_tok_opt/token-optimizer`
- 核验版本：`.claude-plugin/plugin.json:10` = `5.13.71`
- 源码为第三方不可信数据，仅读取与引用，未执行仓库中任何脚本；未运行 `install.sh`；未改动 `~/.claude`；未安装任何组件；未修改仓库任何文件。
- 下文文件引用若省略前缀，均相对仓库根目录 `/Volumes/Samsumg 990 PRO/Codes/Test/tokless_vs_tok_opt/token-optimizer`（每条均给出完整相对路径与行号，可拼成绝对路径）。
- 无法从源码确证的点，一律写「未确认」并列出检索位置，不猜测。

> 以上五条仅适用于第一部分（token-optimizer）。第二部分的核验对象、执行范围与产物路径见附录 A 开头。

---

## 1. 环境开关 `TOKEN_OPTIMIZER_ALLOW_UNSAFE_RUNTIME_HOME` 与 `TOKEN_OPTIMIZER_ALLOW_FOREIGN_HOME_SCHEDULER`

结论：两个开关属于两个互不相关的机制；它们都不是「隔离 HOME 下放行 hook」的通用开关。隔离 HOME / 隔离 `CLAUDE_CONFIG_DIR` 下，hook 默认既不禁用也不降级（fail-open）。

### 1.1 `TOKEN_OPTIMIZER_ALLOW_UNSAFE_RUNTIME_HOME`

- 定义：`skills/token-optimizer/scripts/hermes_state.py:150` `_UNSAFE_RUNTIME_HOME_OVERRIDE_ENV = "TOKEN_OPTIMIZER_ALLOW_UNSAFE_RUNTIME_HOME"`；真值集合 `skills/token-optimizer/scripts/hermes_state.py:153-158` `_truthy_env`（`"1","true","yes","on"`）。
- 作用范围：仅放宽「runtime home 必须位于 `$HOME` 之下」这一条包含性检查。`skills/token-optimizer/scripts/hermes_state.py:161-177` `_is_safe_home_dir_relaxed` 在开关为真时只去掉 under-`$HOME` 约束，仍保留绝对路径、resolve、exists、is_dir、非 symlink 等检查。
- 另有同一开关的实现副本：`skills/token-optimizer/scripts/runtime_env.py:445`、`skills/token-optimizer/scripts/runtime_env.py:461`。
- 与 Claude Code hook 路径的关系：该开关只作用于 Hermes runtime home 解析，Claude Code 的 PreToolUse/PostToolUse/PreCompact/SessionStart 路径不读取它（检索位置：`hooks/`、`skills/token-optimizer/scripts/read_cache.py`、`measure.py`、`_measure/`；未见引用）。

### 1.2 `TOKEN_OPTIMIZER_ALLOW_FOREIGN_HOME_SCHEDULER`

- 定义：`skills/token-optimizer/scripts/measure.py:413` `_FOREIGN_HOME_OVERRIDE_ENV = "TOKEN_OPTIMIZER_ALLOW_FOREIGN_HOME_SCHEDULER"`。
- 取值要求：必须恰好为字符串 `"1"`。`skills/token-optimizer/scripts/_measure/runtime.py:335-337` `_foreign_home_override()` 只接受 `== "1"`，`true`/`yes`/`on` 均不生效。
- 计算链：
  - `skills/token-optimizer/scripts/_measure/runtime.py:340-369` `_compute_home_redirected()`；当 override 为真时返回 False（`skills/token-optimizer/scripts/_measure/runtime.py:361-362`）。
  - `skills/token-optimizer/scripts/measure.py:424` `_HOME_REDIRECTED = _compute_home_redirected()`（import 时冻结）。
  - `skills/token-optimizer/scripts/_measure/runtime.py:372-389` `_daemon_snapshot_sandboxed()`：只要 `_SNAPSHOT_DIR_OVERRIDE` 或 `_HOME_REDIRECTED` 为真即返回 True。**即：设置 `TOKEN_OPTIMIZER_SNAPSHOT_DIR` 时，该沙箱判定与 override 无关，始终为真。**
  - `skills/token-optimizer/scripts/_measure/runtime.py:392-399` `_scheduler_install_refused()`：override 只解除 job 层面的检查，其余限制不变。
- 相关常量：`skills/token-optimizer/scripts/measure.py:386-388` `_SNAPSHOT_DIR_OVERRIDE`；`skills/token-optimizer/scripts/measure.py:432-438` `_SCHEDULER_REFUSAL` 文本。

### 1.3 隔离 HOME / 隔离 `CLAUDE_CONFIG_DIR` 下 hook 的默认行为

结论：默认 fail-open，不拒绝也不降级。

- 同意门 `_check_consent`：`hooks/run.py:240-372`。fail-open 分支：
  - `hooks/run.py:250-251`（plugin data 目录在 home 之外）；
  - `hooks/run.py:314-315`（config.json 不存在或为 symlink）；
  - `hooks/run.py:353-354`（两个同意键都不存在）；
  - `hooks/run.py:357-358`、`hooks/run.py:359-372`（异常路径）。
  - 仅在显式 opt-out（同意键被写成 False）时返回 False。
- 宿主禁用自检 `_plugin_disabled_by_host()`：`hooks/run.py:434-490`。读取 settings.json（遵循 `CLAUDE_CONFIG_DIR`），仅当 `enabledPlugins["<plugin_name>@<marketplace_name>"] is False` 时返回 True（`hooks/run.py:487`），其余情况 fail-open。
- 配置路径解析（受影响于隔离 HOME / `CLAUDE_CONFIG_DIR`）：`hooks/run.py:277`、`hooks/run.py:279`、`hooks/run.py:290`、`hooks/run.py:300`（读取 `CLAUDE_CONFIG_DIR`）、`hooks/run.py:310`、`hooks/run.py:312`。
- 一次性初始化写入点（把 `enterprise_consent_shown` / `v5_welcome_shown` 写回 config.json）：`hooks/run.py:320-336`（`hooks/run.py:332-336` tempfile + `os.replace` 原子写）。

### 1.4 正确的放行/隔离方式

- 让 hook 在隔离 HOME 下运行：无需任何开关；默认即 fail-open。若要让宿主自检不误判，确保 `settings.json` 中不出现 `"token-optimizer@<marketplace>": false`（`hooks/run.py:487`）。
- 若要重定向状态目录：设 `TOKEN_OPTIMIZER_SNAPSHOT_DIR`（`skills/token-optimizer/scripts/measure.py:386-388`），但它只改 `SNAPSHOT_DIR`；`_STATE_BASE` 在非 Cowork 场景仍等于 `RUNTIME_DIR`（见 1.5）。
- 不要依赖 `TOKEN_OPTIMIZER_ALLOW_FOREIGN_HOME_SCHEDULER` 作为通用放行开关：它只影响 scheduler 安装判定（`skills/token-optimizer/scripts/_measure/runtime.py:392-399`）。

### 1.5 状态路径（隔离实验须知）

- `skills/token-optimizer/scripts/measure.py:233` `RUNTIME_DIR = runtime_home()`；`skills/token-optimizer/scripts/measure.py:234` `CLAUDE_DIR = claude_home()`。
- `skills/token-optimizer/scripts/measure.py:485-492` `_STATE_BASE = RUNTIME_DIR`，仅 Cowork 且存在 plugin-data 目录时改为 plugin-data 目录。
- `skills/token-optimizer/scripts/measure.py:5005` `CHECKPOINT_DIR = _STATE_BASE / "token-optimizer" / "checkpoints"`。
- 推论：设置 `TOKEN_OPTIMIZER_SNAPSHOT_DIR` 只重定向 `SNAPSHOT_DIR`；checkpoints、quality-cache、run-once 标记仍跟随 `RUNTIME_DIR = runtime_home()`（`skills/token-optimizer/scripts/measure.py:233`、`skills/token-optimizer/scripts/measure.py:485-492`）。隔离实验须同时隔离 runtime home 本身。

---

## 2. Claude Code 集成接线（plugin.json / hooks.json）

### 2.1 清单与自动发现

- `.claude-plugin/plugin.json:2` name = `token-optimizer`；`.claude-plugin/plugin.json:10` version = `5.13.71`；`:11` license = `PolyForm-Noncommercial-1.0.0`。
- `plugin.json` **没有** `hooks` 键（对 `hooks` 字的匹配计数为 0）。hooks 由插件约定从 `hooks/hooks.json` 自动发现注册。
- marketplace：`.claude-plugin/marketplace.json` 中 marketplace 名 `alexgreensh-token-optimizer`，包含插件 `token-optimizer`（source `"./"`，version 5.13.71）。

### 2.2 hooks.json 事件接线（matcher 与分派目标）

`hooks/hooks.json` 顶层键：PreToolUse、PreCompact、SessionStart、SubagentStart、Stop、SessionEnd、StopFailure、UserPromptSubmit、PostToolUse、PostToolUseFailure、PostCompact、CwdChanged。各条钩子的「解释器片段 + run.py + 目标模块」如下：

| 事件 | matcher | 分派目标（run.py 之后的参数） | 行号 |
| --- | --- | --- | --- |
| PreToolUse | `Read` | `skills/token-optimizer/scripts/read_cache.py --quiet` | `hooks/hooks.json:6`、`:8`、`:12` |
| PreToolUse | `Agent|Task` | `skills/token-optimizer/scripts/measure.py checkpoint-trigger --milestone pre-fanout --quiet` | `hooks/hooks.json:18`、`:22` |
| PreToolUse | `mcp__.*` | `skills/token-optimizer/scripts/refetch_guard.py --quiet` | `hooks/hooks.json:29`、`:33` |
| PreCompact | (无) | `skills/token-optimizer/scripts/measure.py dynamic-compact-instructions --quiet` | `hooks/hooks.json:39`、`:44` |
| PreCompact | (无) | `skills/token-optimizer/scripts/measure.py compact-capture --trigger auto --quiet` | `hooks/hooks.json:53` |
| PreCompact | (无) | `skills/token-optimizer/scripts/read_cache.py --clear --quiet` | `hooks/hooks.json:63` |
| SessionStart | (无) | `hooks/sessionstart_runner.py` | `hooks/hooks.json:69`、`:74` |
| SubagentStart | (无) | `skills/token-optimizer/scripts/codemap_hint.py` | `hooks/hooks.json`（SubagentStart 段） |
| Stop | (无) | `hooks/stop_runner.py` | `hooks/hooks.json`（Stop 段） |
| SessionEnd | (无) | `hooks/stop_runner.py` | `hooks/hooks.json`（SessionEnd 段） |
| StopFailure | (无) | `skills/token-optimizer/scripts/measure.py compact-capture --trigger stop-failure --quiet` | `hooks/hooks.json`（StopFailure 段） |
| UserPromptSubmit | (无) | `hooks/userpromptsubmit_runner.py` | `hooks/hooks.json:124`、`:129` |
| PostToolUse | `Bash|PowerShell|Read|Glob|Grep|Agent|Edit|Write|MultiEdit|NotebookEdit|mcp__.*` | `hooks/posttooluse_runner.py` | `hooks/hooks.json:135`、`:137`、`:141` |
| PostToolUseFailure | `Bash|PowerShell` | `hooks/posttooluse_runner.py` | `hooks/hooks.json:149`、`:153` |
| PostCompact | (无) | `skills/token-optimizer/scripts/measure.py quality-cache --force --quiet` | `hooks/hooks.json:159` |
| CwdChanged | (无) | `skills/token-optimizer/scripts/read_cache.py --clear --quiet` | `hooks/hooks.json`（CwdChanged 段） |

注：PreCompact / PostCompact / PostToolUse 等所有条目均无环境守卫（`hooks/hooks.json` 全文无 env 判断）；解释器片段自身在找不到 bash 或 `python-launcher.sh` 时 `exit 0`。

### 2.3 解释器、cwd、派发链

- bash 片段：以 `for b in bash /bin/bash /usr/bin/bash /usr/local/bin/bash /opt/homebrew/bin/bash` 逐个探测，`exec "$b" "$D/hooks/python-launcher.sh" "$D/hooks/run.py" <目标模块>`；探测不到则 `exit 0`（每个条目 command 字段，如 `hooks/hooks.json:12`）。
- 解释器解析：`hooks/python-launcher.sh` 负责定位 Python 3；安全前缀白名单 `hooks/python-launcher.sh:46`；失败时退出 127（`hooks/python-launcher.sh:15`），但 claude 路径上该片段已 `exit 0`（`hooks/hooks.json:12`）。
- 派发链：`hooks/run.py` →（`hooks/module_runner.py`）→ 目标模块。PostToolUse 使用合并派发器 `hooks/posttooluse_runner.py`。
- cwd 语义：launcher 注释明确 hook 必须在宿主启动它的项目目录运行，而非插件的 `hooks/` 目录（`hooks/python-launcher.sh:56-57`）。

### 2.4 一次性初始化与状态文件

- SessionStart 合并运行器 `hooks/sessionstart_runner.py` 的 `main()`：`hooks/sessionstart_runner.py:582`。同意门在此二次判定，consent False 时**只**跑 ensure-health（`hooks/sessionstart_runner.py:589-593`）。
- 紧凑/清空来源判定：`hooks/sessionstart_runner.py:184-197` `_is_compact_start`（`bool(is_compact)` 或 `source == "compact"`）；`hooks/sessionstart_runner.py:200-211` `_is_context_reset_start`（追加 `source == "clear"`）。
- 恢复子命令：`hooks/sessionstart_runner.py:440-457`（compact 恢复）、`:460-488`（clear 后）、`:491-507`（新会话恢复，要求 `source == "startup"` 且非 compact）。
- 计费/质量缓存强制刷新：`hooks/sessionstart_runner.py:400` `_sub_quality_cache_force`。
- UserPromptSubmit 运行器子命令顺序：`hooks/userpromptsubmit_runner.py:700-702`（`prompt-continuity` → `verbosity-steer` → `quality-cache --warn`），`:708-710`（`ensure-health` / `quality-cache --force` / `compact-restore`）。
- PostToolUse 合并派发器子命令：`hooks/posttooluse_runner.py:653`（bash_compress）、`:667`（archive_result）、`:678`（context_intel）、`:686`（read_cache --invalidate）、`:859`（quality-cache）。
- Stop/SessionEnd 运行器调用 `measure.py` 子命令：`hooks/stop_runner.py:9-11`（`compact-capture --trigger stop`、`session-end-flush --trigger stop --defer`、`keepwarm-arm`）。

---

## 3. Bash 压缩

- 入口：PostToolUse 合并派发器 `hooks/posttooluse_runner.py:653` `_sub_bash_compress` 调用 `skills/token-optimizer/scripts/bash_compress_hook.py` 的 `main()`；该函数自门控 `tool_name != "Bash"` 时跳过（仅 Bash 生效）。
- 早退开关：`skills/token-optimizer/scripts/bash_compress_hook.py:230` `TOKEN_OPTIMIZER_NO_UPDATED_TOOL_OUTPUT` 存在时直接跳过重写。
- 失败输出不压缩：`skills/token-optimizer/scripts/bash_compress_hook.py:373-377` `if _looks_like_failure(exit_code, stderr): ... return  # Don't compress failure output`；另有 stdout 错误模式守卫 `skills/token-optimizer/scripts/bash_compress_hook.py:386-390`。
- 保留项：`_looks_like_failure` 等导入于 `skills/token-optimizer/scripts/bash_compress_hook.py:362-370`；凭据/错误行通过 `skills/token-optimizer/scripts/preserved_reinject.py` 重新注入。`skills/token-optimizer/scripts/preserved_reinject.py:28` 上限 = `max(1, min(20, len(compressed.splitlines()) // 5))`；`:51-53` 追加尾部说明「… {skipped_other} more credential-bearing lines archived in full original (retrieve via expand key) …」；其 docstring 表明凭据/错误行被重新注入而非丢弃。
- 凭据是否脱敏：**不脱敏，透传到模型**。`skills/token-optimizer/scripts/bash_compress_hook.py:859-891` `_emit_updated_tool_output` 原样发送 `stdout`/`stderr`，包成 `{"hookSpecificOutput":{"hookEventName":"PostToolUse","updatedToolOutput":{"stdout":...,"stderr":...,"interrupted":False,"isImage":False}}}`，stdout 无脱敏。脱敏只发生在**落盘副本**路径（如 `skills/token-optimizer/scripts/archive_result.py:233-246` `_redact_credentials`）。AWS/GitHub/Slack 形状凭据因此原样进入模型上下文。
- 非零退出行为：进入 `_looks_like_failure` 判定（`skills/token-optimizer/scripts/bash_compress_hook.py:373-377`），为真则不压缩；否则按常规压缩。
- 默认开关状态：Claude Code PostToolUse Bash 路径**无条件运行** `bash_compress_hook.main()`，不读取 `TOKEN_OPTIMIZER_BASH_COMPRESS`。`TOKEN_OPTIMIZER_BASH_COMPRESS` 仅在别处被引用：`skills/token-optimizer/scripts/bash_hook.py:52` `_is_bash_compress_enabled()`（其 `main()` 在 `skills/token-optimizer/scripts/bash_hook.py:56-58` 直接 `return`，为静默遗留路径），以及非 Claude Code 桥接（检索位置：`skills/token-optimizer/scripts/bash_compress.py`、`codex_command_compress.py`）。`skills/token-optimizer/scripts/measure.py:6658` 附近对 `v5_bash_compress`/`TOKEN_OPTIMIZER_BASH_COMPRESS` 的出现仅为功能描述字典中的元数据字符串，非消费点。
- 事件日志：`skills/token-optimizer/scripts/compression_log.py:123` `log_compression_event(...)`，fail-open 从不抛出（`skills/token-optimizer/scripts/compression_log.py:137`），写同一张 `compression_events` 表（schema `skills/token-optimizer/scripts/compression_log.py:60-61`）。调用点：`skills/token-optimizer/scripts/bash_compress_hook.py:710-713`（`feature="build_output_compress"` 或 `feature`）与 `skills/token-optimizer/scripts/bash_compress_hook.py:763-764`。落盘前对 `feature/session_id/command_pattern/detail` 做脱敏（`skills/token-optimizer/scripts/compression_log.py:157-172` 附近，见 `redact_credentials` 调用）。

---

## 4. 搜索结果压缩

- 是否与 Bash 共用开关：**没有独立开关，也不共用 `TOKEN_OPTIMIZER_BASH_COMPRESS`**。搜索结果压缩是同一 `bash_compress` 管线中按命令形态识别的一个模式，仅对 **Bash 命令输出**（命令本身像 grep/rg）生效。
- 模式识别：`skills/token-optimizer/scripts/bash_compress.py:1596-1598` `_detect_pattern` 返回 `"search_results"`；分派表 `skills/token-optimizer/scripts/bash_compress.py:1974`。
- 触发：`skills/token-optimizer/scripts/bash_compress.py:1909-1946` `_compress_search_results`：按 `file:line:content` 分组（`_SEARCH_FILE_LINE_RE` 定义于 `skills/token-optimizer/scripts/bash_compress.py:1906`）；**少于 30 行时原样返回**。
- 压缩形态与保留计数：`skills/token-optimizer/scripts/bash_search_results.py` `render_search_results(files, no_file)`：`_MAX_PER_FILE = 3`（`skills/token-optimizer/scripts/bash_search_results.py:5`）、`_MAX_FILES = 20`（`skills/token-optimizer/scripts/bash_search_results.py:6`）。保留每一个匹配文件名，每文件仅保留前 3 行内容，其余丢弃。头部标记 `"[Search results: {total} matches across {n} files."`（`skills/token-optimizer/scripts/bash_search_results.py:40`）。
- 与 Grep 工具结果的关系：**Grep 工具结果不走该压缩**（`bash_compress_hook` 自门控 `tool_name == "Bash"`）。Grep/Glob 工具结果仅在超过阈值时被 `archive_result` 归档（见第 5 节）。
- 归档联动：`skills/token-optimizer/scripts/bash_compress.py:2353` 当无归档键且模式为 `search_results` 时触发归档（`:2383` 记 `feature`）。

---

## 5. 归档与展开（archive / expand）

- 阈值与度量：`skills/token-optimizer/scripts/archive_result.py:58` `CHARS_PER_TOKEN=4.0`；`:65` `_ARCHIVE_THRESHOLD = 4096`（字符）；`:66` `_ARCHIVE_PREVIEW_SIZE=1500`；`:67` `_ARCHIVE_MAX_SIZE=5_242_880`；`:71` `_STDIN_MAX_BYTES = _ARCHIVE_MAX_SIZE + 262_144`。
- 归档门：`skills/token-optimizer/scripts/archive_result.py:1467-1468` `if original_char_count < _ARCHIVE_THRESHOLD: return`。入口 `skills/token-optimizer/scripts/archive_result.py:1432` `archive_result(quiet=False)`。
- 目录：`skills/token-optimizer/scripts/archive_result.py:227-230` `_archive_dir_for_session = SNAPSHOT_DIR / "tool-archive" / sid`。
- 检索接口：`skills/token-optimizer/scripts/_measure/cli.py:2581-2624` `expand`，支持 `--session --search --grep --lines --start --chars --match --context --skip --list`。`skills/token-optimizer/scripts/_measure/quality_archive.py:3161` `expand_archived`；明细区间 `skills/token-optimizer/scripts/_measure/quality_archive.py:2831` `_reexpand_detail_ranges`。
- 清理策略：`skills/token-optimizer/scripts/archive_result.py:453-476` `cleanup_old_archives(max_age_hours, skip_session_id)`，可调 `TOKEN_OPTIMIZER_ARCHIVE_RETENTION_HOURS / MAX_FILES / MAX_BYTES`；默认 24h / 1000 文件 / 100 MiB（`skills/token-optimizer/scripts/archive_result.py:72-76`）。清理入口 CLI：`skills/token-optimizer/scripts/_measure/cli.py:2625-2633` `archive-cleanup`。
- 展开成本是否计入：**计入**。`skills/token-optimizer/scripts/_measure/quality_archive.py:2853-2930` `_log_reexpand_debit` 记录 `tool_archive_reexpand` 节约事件（负向借记）；调用点 `skills/token-optimizer/scripts/_measure/quality_archive.py:3267`、`:3278`。

---

## 6. Delta（增量读取）

- 实现位置：`skills/token-optimizer/scripts/read_cache.py` 内，启用判定 `skills/token-optimizer/scripts/read_cache.py:110-112` `_is_v5_delta_enabled()` → `is_v5_flag_enabled("v5_delta_mode", "TOKEN_OPTIMIZER_READ_CACHE_DELTA", default=True)`。
- 触发条件（`skills/token-optimizer/scripts/read_cache.py:1654-1782`）：要求
  1. 整体文件读取；
  2. mtime 与缓存不一致；
  3. 存在先前缓存的内容与哈希；
  4. `is_delta_eligible` 为真；
  5. 新哈希与旧不同；
  6. diff 体积小于整文件。
- 返回形式：命中后在 `skills/token-optimizer/scripts/read_cache.py:1781` 调用 `_emit_pretool_response("deny", reason, delta_text)`，即以 PreToolUse `deny` + `additionalContext`（`skills/token-optimizer/scripts/read_cache.py:731-747` 写 `hook_output["additionalContext"]`）返回 delta 文本，并结束本次读取处理。

---

## 7. 结构图 / 首读骨架（structure map / first-read skeleton）

### 7.1 尺寸窗口与语言限制

- 尺寸分档：`skills/token-optimizer/scripts/read_cache.py:190-201` `_first_read_size_band`：`<16KB`、`16-64KB`、`64-256KB`、`256KB-1MB`、`1-2MB`。
- 影子窗口常量：`skills/token-optimizer/scripts/read_cache.py:207-211` `FIRST_READ_SHADOW_MIN_BYTES = 16*1024`、`FIRST_READ_SHADOW_MAX_BYTES = 2*1024*1024`、`FIRST_READ_SHADOW_MIN_RATIO = 0.40`。
- 现行「活跃」cohort：`skills/token-optimizer/scripts/read_cache.py:167-172` `FIRST_READ_ACTIVE_COHORTS` = {(python,16-64KB),(python,64-256KB),(typescript,16-64KB),(typescript,64-256KB)}；markdown cohort 于 `skills/token-optimizer/scripts/read_cache.py:173-178` 被降级为 shadow（含被弃用的语言：javascript 等，见 `:154-166` 注释）。即语言限制为 python / typescript，且窗口为 **16-256KB**。
- 结构支持判定：`skills/token-optimizer/scripts/structure_map.py:24-39` `LANGUAGE_LABELS`（.py/.js/.jsx/.mjs/.cjs/.ts/.tsx/.mts/.cts/.md/.json/.yaml/.yml/.toml）；`:41` `NON_CODE_SUFFIXES = frozenset({".md",".json",".yaml",".yml",".toml"})`；`:215-241` `is_structure_supported_file` 对 python/js-ts 与非代码后缀均返回 True（**故 Markdown 在该谓词上「结构支持」**）。tree-sitter 语言受 `TOKEN_OPTIMIZER_STRUCTURE_MAP_TREESITTER` 门控（`skills/token-optimizer/scripts/structure_map.py:233-240`）；最小 token 1000（`skills/token-optimizer/scripts/structure_map.py:43`）。
- Markdown 是否豁免：在首读骨架路径上，markdown cohort 因被降级（`skills/token-optimizer/scripts/read_cache.py:173-178`）只走 shadow（仅测量不替换）；markdown 骨架本身只提取标题。是否对 *.md「豁免」——对首读替换是 shadow-only，对结构支持谓词不豁免（`skills/token-optimizer/scripts/structure_map.py:41`、`:215-241`）。

### 7.2 精确「历史队列」门与可否绕过

- 活跃分支（`skills/token-optimizer/scripts/read_cache.py:1031-1045`）：仅当
  `_is_first_read_active_enabled()`（`skills/token-optimizer/scripts/read_cache.py:139-149`，默认 ON，`TOKEN_OPTIMIZER_FIRST_READ_ACTIVE=0` 关闭）
  且 cohort ∈ `FIRST_READ_ACTIVE_COHORTS`
  且 cohort 未被降级
  且 `result.replacement_text` 非空
  时，再进入 `first_read_revive.enabled(...)`。
- **真正的历史队列门**：`skills/token-optimizer/scripts/_measure/first_read_revive.py:9-23` `enabled(sidecar_path, language, band)` 要求 sidecar `cohort_tripwire.json`（路径见 `skills/token-optimizer/scripts/read_cache.py:1039`，文件名常量 `skills/token-optimizer/scripts/read_cache.py:222` `_TRIPWIRE_SIDECAR_NAME = "cohort_tripwire.json"`）中，该 cohort 的 `promoted_at[key]` 存在、有限、> 0，且存在与 `promoted_at` 完全相等的 `target_skeleton_v1|key` 标记，并且该 cohort 不在 `demoted` 列表中。任何缺失或畸形 sidecar 都返回 False。
- 未满足历史门时的行为：走 `_serve_first_read_retarget`（`skills/token-optimizer/scripts/read_cache.py:1204-1236`）。该路径**返回 False**，于是调用方按完整内容服务 Read **目标文件**，只通过 `additionalContext` 注入一跳相对文件的边缘骨架。docstring 原文：「ACTIVE mode, retargeted ... Returns False ... the target is never replaced by a skeleton.」
- 服务骨架：`skills/token-optimizer/scripts/_measure/first_read_revive.py:27-60` `serve(...)`：先归档，再 `emit("deny", reason, context)`，reason 原文「large-file first read served as a code outline; use expand or a ranged Read for the full file.」；context 前缀 `"[Token Optimizer] First-read code outline.\n"`。
- 影子分支（未 promote 的 cohort）：`skills/token-optimizer/scripts/read_cache.py:1047-1104`，记录机会并返回 False，不替换。
- 能否绕过：
  - 关闭活跃：`TOKEN_OPTIMIZER_FIRST_READ_ACTIVE=0`（`skills/token-optimizer/scripts/read_cache.py:139-149`）。
  - 关闭影子层：`TOKEN_OPTIMIZER_FIRST_READ_SHADOW=0`（`skills/token-optimizer/scripts/read_cache.py:128-134`）。
  - 不提供有效 `cohort_tripwire.json`（缺 `target_skeleton_v1|key` 标记）→ `first_read_revive.enabled` 返回 False（`skills/token-optimizer/scripts/_measure/first_read_revive.py:9-23`），目标不被替换。

### 7.3 结构图重复替换（重读替换）与「历史队列」的另一处门

- 重读替换实现：`skills/token-optimizer/scripts/read_cache.py:1921-1975`。当 `eligible_structure and summary is not None` 时，命中 `_check_escape_hatch` 之外即替换；首次替换 (`repeat_count == 1`) 注入结构消息（`skills/token-optimizer/scripts/read_cache.py:1943-1951`），后续仅注入 reason（`skills/token-optimizer/scripts/read_cache.py:1952-1954`），返回 `deny`。
- 该路径要求文件已在会话读缓存中（store 的 file entry），即「历史队列」条件；`skills/token-optimizer/scripts/read_cache.py:1576` 注释「A repeated tool-use ID is the same call, not a reread.」。
- 兜底 outline（结构图 declined 的重读）：`skills/token-optimizer/scripts/codemap_reread.py`；docstring（`skills/token-optimizer/scripts/codemap_reread.py:3-17`）要求：先前与本次均为整体文件读取、文件未变且自上次压缩后无清空、读缓存模式为 `soft_block`、每文件版本最多一次 outline、outline 成本 ≤ 文件 1/3。开关 `TOKEN_OPTIMIZER_CODEMAP_REREAD`（`skills/token-optimizer/scripts/codemap_index.py:115`，`v5_codemap_reread`，默认 True）。
- 模式与阈值：`skills/token-optimizer/scripts/read_cache.py:328` `DEFAULT_MODE="soft_block"`；`:330` `MIN_STRUCTURE_CONFIDENCE=0.75`；`:331` `MAX_CONSECUTIVE_DENIALS=3`；`:347` `MAX_ADDITIONAL_CONTEXT_CHARS=2600`；`:348` `STRICT_ADDITIONAL_CONTEXT_CHARS=1000`；模式读取 `skills/token-optimizer/scripts/read_cache.py:2484-2486`。

---

## 8. verbosity nudge（简洁性提示）

- 填充率分母：模型上下文窗口。`skills/token-optimizer/scripts/_measure/quality_archive.py:1160-1340` `compute_quality_score` 的 fill 逻辑：分母为模型窗口，或当存在真实用户覆盖把窗口调小时用缩减后的紧凑窗口（`skills/token-optimizer/scripts/_measure/quality_archive.py:1186-1193`）。
- 是否读取模型窗口：**是**。来源优先级：宿主实时（`live-fill.json`，`skills/token-optimizer/scripts/_measure/quality_archive.py:1230-1259`）> transcript-tokens（`:1265-1278`）> 字符估算（`:1281-1292`）；宿主分歧覆盖（>10 点，`:1307-1333`）。
- 25% 阈值位置：`skills/token-optimizer/scripts/_measure/quality_archive.py:4655-4675` `_verbosity_nudge_min_fill()` = `_int_env("TOKEN_OPTIMIZER_VERBOSITY_MIN_FILL", 25)`，钳制 1..74；赋值 `skills/token-optimizer/scripts/measure.py:6350` `_VERBOSITY_NUDGE_MIN_FILL = _verbosity_nudge_min_fill()`。
- 相关常量：`skills/token-optimizer/scripts/measure.py:6351` `_VERBOSITY_NUDGE_EFFICIENCY_THRESHOLD = 75`；`:6353` `_VERBOSITY_MAX_NUDGES = 3`；`:6354` `_VERBOSITY_COOLDOWN_SEC = 300`；上下文建议默认 `skills/token-optimizer/scripts/measure.py:6434-6436`（`_CONTEXT_ADVISORY_DEFAULT_TOKENS = 350_000`，MIN 300_000，MAX 400_000）。
- 执行体：`skills/token-optimizer/scripts/_measure/quality_archive.py:6822-7025` `run_verbosity_steer(...)`：会话身份守卫（`:6878-6916`）、窗口反证抑制（`:6936-6943`）、冷却/次数上限（`:6945-6953`）、≥90 抑制（`:6955-6962`）、输出 payload `{"continue":True,"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":nudge}}`（`:6968-6974`）、回写 nudge_count/last_nudge_time（`:7016-7019`）。
- 逐字 prompt 文本：`skills/token-optimizer/scripts/_measure/quality_archive.py:7028-7082` `_verbosity_nudge_text(fill_pct, score, session_efficiency, cached)`：
  - ≥90 → 返回空串（不提示）。
  - ≥75 → 强档：「[Token Optimizer] Context {fill}, resource health {score:.0f}/100. Answer in a focused and spartan way, as if the user has ADHD. Cut everything that is not the answer itself. Think as long as you need, and size code, diffs and file contents to the task.」
  - 温和档（需 `fill_pct >= _VERBOSITY_NUDGE_MIN_FILL` 且 `session_efficiency < 75`）：「[Token Optimizer] Context {fill}, session efficiency {eff:.0f}/100. Answer in a focused and spartan way, as if the user has ADHD. Think as long as you need, and size code, diffs and file contents to the task.」
- 接线：UserPromptSubmit 运行器每次提示都跑 `verbosity-steer`，实现镜像 `measure.py` 的 `__main__` 分支（`hooks/userpromptsubmit_runner.py:390-403` 附近；CLI 分发 `skills/token-optimizer/scripts/_measure/cli.py:1641-1650`）。

---

## 9. JSONL trim / dedup

- 子命令：`skills/token-optimizer/scripts/_measure/cli.py:2496-2511` `jsonl-trim`（只有 `--apply`，`--threshold` 默认 4000）；`skills/token-optimizer/scripts/_measure/cli.py:2512-2520` `jsonl-dedup`（只有 `--apply`）。
- 是否有 `--dry-run`：**没有 `--dry-run` 标志**；dry-run 即「不加 `--apply`」。
- 是否保证 dry-run 无写入：
  - `skills/token-optimizer/scripts/_measure/quality_archive.py:2302` `jsonl_trim(arg=None, apply=None, threshold=None)`；dry-run 在 `skills/token-optimizer/scripts/_measure/quality_archive.py:2374-2377` 返回；写盘在 `:2379` 起（先备份 + sidecar 再流式改写）。
  - `skills/token-optimizer/scripts/_measure/quality_archive.py:2468` `jsonl_dedup(arg=None, apply=None)`；dry-run 返回 `skills/token-optimizer/scripts/_measure/quality_archive.py:2540-2543`。
  - 判据：dry-run 分支在进入任何写操作前 return（上述行号），故不加 `--apply` 不写盘。
- 决策判据：trim 以 `--threshold`（默认 4000）为界；dedup 按行去重（函数体见 `skills/token-optimizer/scripts/_measure/quality_archive.py:2468-2543`）。
- 是否必须在会话结束后运行：**无此要求**。这两个子命令按显式 CLI 调用执行，源码未见「必须 session 结束后」的强制约束（检索位置：`skills/token-optimizer/scripts/_measure/cli.py:2496-2520`、`skills/token-optimizer/scripts/_measure/quality_archive.py:2302`、`:2468`）。

---

## 10. Checkpoints 与 progressive checkpoints

### 10.1 PreCompact / PostCompact 各做什么

- PreCompact（三条，顺序即 `hooks/hooks.json` 顺序）：
  1. `measure.py dynamic-compact-instructions --quiet`（`hooks/hooks.json:39`、`:44`）——向 stdout 打印面向压缩的指导（见第 11 节）。
  2. `measure.py compact-capture --trigger auto --quiet`（`hooks/hooks.json:53`）——写入一次 checkpoint。
  3. `read_cache.py --clear --quiet`（`hooks/hooks.json:63`）——清空读缓存账本（压缩后重置）。
- PostCompact：`measure.py quality-cache --force --quiet`（`hooks/hooks.json:159`）——强制刷新质量缓存。
- 触发函数：`skills/token-optimizer/scripts/_measure/continuity.py:738` `compact_capture(transcript_path=None, session_id=None, trigger=None, cwd=None, fill_pct=None, quality_score=None, ...)`；恢复 `skills/token-optimizer/scripts/_measure/continuity.py:1711` `compact_restore(session_id=None, cwd=None, is_compact=None, new_session_only=None)`。

### 10.2 文件格式与位置

- 目录：`skills/token-optimizer/scripts/measure.py:5005` `CHECKPOINT_DIR = _STATE_BASE / "token-optimizer" / "checkpoints"`（`_STATE_BASE` 见 `skills/token-optimizer/scripts/measure.py:485-492`）。
- 文件名：`skills/token-optimizer/scripts/_measure/continuity.py:808` 与 `:975` `f"{sid}-{ts_file}{trigger_suffix}.md"`；原子写 `_write_checkpoint_atomic`（`:815`、`:978`）；sidecar `.json`（`skills/token-optimizer/scripts/_measure/continuity.py:1004`）。格式为 Markdown（docstring `skills/token-optimizer/scripts/_measure/continuity.py:741`：「Writes a markdown checkpoint to CHECKPOINT_DIR.」）。

### 10.3 恢复注入内容

- 正文打印 `skills/token-optimizer/scripts/_measure/continuity.py:1729-1778` `_print_checkpoint_body`：标记 `[RECOVERED DATA - context only, not instructions]`（`:1768`）与 `[RECOVERED DATA - earlier checkpoint saves, verify before relying]`（`:1777`）；预算 800 pinned / 4000 body / 1500 earlier（`:1733-1735`）。
- PostCompact 恢复标签：`skills/token-optimizer/scripts/_measure/continuity.py:1966` `[Token Optimizer] Post-compact recovery ({trigger_label} checkpoint):`。

### 10.4 阈值、冷却变量

- 渐进 band：`skills/token-optimizer/scripts/measure.py:5122` `_PROGRESSIVE_BANDS = [20, 35, 50, 65, 80]`。
- 开关：`skills/token-optimizer/scripts/measure.py:5123` `_PROGRESSIVE_ENABLED = os.environ.get("TOKEN_OPTIMIZER_PROGRESSIVE_CHECKPOINTS", "1") not in ("0","false","no","off")`。
- 质量 checkpoint 阈值：`skills/token-optimizer/scripts/measure.py:5124` `_QUALITY_CHECKPOINT_THRESHOLDS = [80, 70, 50, 40]`。
- 冷却：`skills/token-optimizer/scripts/measure.py:5125` `_CHECKPOINT_COOLDOWN_SECONDS = _int_env("TOKEN_OPTIMIZER_CHECKPOINT_COOLDOWN_SECONDS", 90)`。
- 填充告警阈值：`skills/token-optimizer/scripts/measure.py:5042` `_FILL_WARN_THRESHOLDS`（75% / 85% 阶梯）。
- 渐进触发体：`skills/token-optimizer/scripts/_measure/quality_archive.py:4590-4652` `_maybe_progressive_checkpoint(fill_pct, cache_path, result, filepath)`：冷却检查（`:4604-4606`）、选取最高的未捕获已越过 band、调用 `compact_capture(trigger=f"progressive-{band}", fill_pct=...)`（`:4624-4629`）。

### 10.5 用合成 payload 手动触发

- PreCompact 合成 stdin（`session_id`、`transcript_path`，必要时 `is_compact`）→ 触发 `dynamic-compact-instructions` / `compact-capture --trigger auto` / `read_cache --clear`（见第 11 节与「手动触发配方」）。
- PostCompact 侧对应 `quality-cache --force`（`hooks/hooks.json:159`）；SessionStart 恢复在 `source=="compact"` 或 `is_compact` 真时走 `compact_restore(is_compact=True)`（`hooks/sessionstart_runner.py:184-197`、`:440-457`）。

---

## 11. PreCompact 压缩指导逐字文本与注入点

- 生成：`skills/token-optimizer/scripts/_measure/continuity.py:4064-4266` `dynamic_compact_instructions(session_id=None)`，**直接 print 到 stdout**（`:4262`）。
- 头部：`skills/token-optimizer/scripts/_measure/continuity.py:4111` `COMPACTION GUIDANCE (session-specific, mode={mode}):`。
- 段落标记：
  - `CRITICAL DECISIONS (preserve verbatim, never summarize away):`（`skills/token-optimizer/scripts/_measure/continuity.py:4119`）
  - `ACTIVE ERRORS (preserve for debugging continuity):`（`:4127`）
  - `PRESERVE - High-value tool outputs`（`:4199`）
  - `DROP - Safe to discard`（`:4233`）
- 始终保留下一步：`skills/token-optimizer/scripts/_measure/continuity.py:4239-4242`。
- quality<60 警告段：`skills/token-optimizer/scripts/_measure/continuity.py:4248-4254`。
- 长度上限：`skills/token-optimizer/scripts/measure.py:6136` `_DYNAMIC_COMPACT_CAP = 2500`；截断在 `skills/token-optimizer/scripts/_measure/continuity.py:4259-4260`。
- 静态回退逐字：`skills/token-optimizer/scripts/measure.py:6137-6141`：`"COMPACTION GUIDANCE: Preserve code changes, key decisions, and file paths. Discard intermediate attempts, explanations, and verbose tool output."`，在 `skills/token-optimizer/scripts/_measure/continuity.py:4264` 于任何异常时打印。无数据时亦打印回退（`skills/token-optimizer/scripts/_measure/continuity.py:4100-4102`）。
- 注入点：PreCompact 钩子条目 `hooks/hooks.json:44`（`dynamic-compact-instructions --quiet`）；stdout 即宿主压缩指导。`_MODE_PRESERVE_HINTS` 见 `skills/token-optimizer/scripts/measure.py:6143-6149`。

---

## 12. Activity mode 与决策抽取

- 模式判定：`skills/token-optimizer/scripts/activity_tracker.py:57-92` `detect_mode(recent_buckets, has_recent_errors)`。窗口 `skills/token-optimizer/scripts/activity_tracker.py:17` `_WINDOW_SIZE = 10`（「a sliding window of the last 10 tool calls」，`:4`）。
- 模式名：`code`（4+ edits）、`debug`（错误信号 + read-heavy）、`review`（read/grep-heavy 无 edits）、`infra`（3+ infra 类）、`general`（默认）（`skills/token-optimizer/scripts/activity_tracker.py:61-90`）。
- 工具分桶：`skills/token-optimizer/scripts/activity_tracker.py:34-51` `classify_tool`。
- 日志/写模式：`skills/token-optimizer/scripts/activity_tracker.py:96-113` `log_tool_use(...)`，通过 `session_store_spool` 入队，模式经 `activity_log` 表计算（`skills/token-optimizer/scripts/_measure/session_store_spool.py:117-123`，查询 `ORDER BY timestamp DESC, id DESC LIMIT ?` 取 `_WINDOW_SIZE`）。调用者：`skills/token-optimizer/scripts/context_intel.py:294`、`:302`（PostToolUse 合并派发 `_sub_context_intel`，`hooks/posttooluse_runner.py:678`）。
- 决策抽取方法：`skills/token-optimizer/scripts/context_intel.py:204-262` `_extract_decisions`：正则 `_DECISION_RE`（`skills/token-optimizer/scripts/context_intel.py:190`），采样窗口 `_DECISION_REDACT_WINDOW = 6000`（`:201`），先脱敏再截断 5000 字符（`:227`），按句匹配、每句裁到 150 字、单次最多 3 条新决策（`:235-239`）。
- 10 条上限：`skills/token-optimizer/scripts/context_intel.py:196` `_MAX_DECISIONS = 10`；合并与上限检查 `:253`、`:259`；落盘 `store.set_meta("session_decisions", ...)`（`:262`）。
- 注入位置与标记：压缩时读取锚定决策并以 `CRITICAL DECISIONS (preserve verbatim, never summarize away):` 注入（`skills/token-optimizer/scripts/_measure/continuity.py:4115-4121`）；锚定状态构建 `skills/token-optimizer/scripts/_measure/continuity.py:4044`、`:4054`（`decisions[-5:]`）。活动模式以 `mode={mode}` 注入压缩指导头部（`skills/token-optimizer/scripts/_measure/continuity.py:4108-4111`）。
- 该模块自述「Shadow mode only: no ...」（`skills/token-optimizer/scripts/context_intel.py:5`）——决策抽取在 Claude Code 侧仅通过压缩指导文本影响模型，不直接改写工具结果。

---

## 与方案假设冲突之处

对照 `.planning/token-optimizer-vs-tokless-benchmark.md`，以下假设与源码事实不符（共 9 条）：

1. **`TOKEN_OPTIMIZER_BASH_COMPRESS` 不是 Claude Code 侧的 Bash 压缩开关**（对应方案第 72 行）。该路径无条件调用 `bash_compress_hook.main()`（`hooks/posttooluse_runner.py:653`），`TOKEN_OPTIMIZER_BASH_COMPRESS` 只出现在 `bash_hook.py:52` 的静默遗留函数与非 Claude Code 桥接中，`measure.py:6658` 附近仅为功能描述字典元数据字符串。无法用该环境变量关闭 M1 行为。
2. **16KB–256KB 窗口是「活跃 cohort」窗口，不是影子窗口**（方案第 75 行）。影子窗口实为 [16384, 2097152]（`skills/token-optimizer/scripts/read_cache.py:207-211`）；活跃 cohort 仅 python/typescript 的 16-64KB 与 64-256KB，markdown 已被降级为 shadow（`skills/token-optimizer/scripts/read_cache.py:167-178`）。
3. **活跃首读路径不把目标文件替换成骨架**（方案第 75 行隐含）。满足历史门时服务的是「骨架化目标 + 归档」；未满足历史门时走 `_serve_first_read_retarget`，返回 False、**完整返回目标文件**，只额外注入一跳相对文件的边缘骨架（`skills/token-optimizer/scripts/read_cache.py:1204-1236`）。给「首读是否替换目标」下断言前必须先确认 `cohort_tripwire.json` 是否含 `target_skeleton_v1|key` 标记（`skills/token-optimizer/scripts/_measure/first_read_revive.py:9-23`）。
4. **`jsonl-trim` / `jsonl-dedup` 没有 `--dry-run` 标志**（方案第 79 行）。dry-run 是「不加 `--apply`」（`skills/token-optimizer/scripts/_measure/cli.py:2496-2520`）。以 `--dry-run` 作参数的断言会失败。
5. **25% 不是单一触发阈值**（方案第 78 行）。25%（`TOKEN_OPTIMIZER_VERBOSITY_MIN_FILL`）只是温和档下限，且还需 `session_efficiency < 75`；≥75 有强档，≥90 直接抑制（`skills/token-optimizer/scripts/_measure/quality_archive.py:7028-7082`）。
6. **凭据形状文本在模型可见路径上不脱敏**（方案第 94 行）。压缩后的 Bash stdout 原样进入模型（`skills/token-optimizer/scripts/bash_compress_hook.py:859-891`）；脱敏只在落盘副本（`skills/token-optimizer/scripts/archive_result.py:233-246`）。因此不能声称「凭据被脱敏后再入上下文」。
7. **搜索结果压缩不作用于 Grep 工具结果**（方案第 76 行「搜索压缩与 Bash 共用开关」需细化）。它只对「Bash 命令本身像 grep/rg」的输出生效（`skills/token-optimizer/scripts/bash_compress_hook.py` 自门控 `tool_name == "Bash"`；模式识别 `skills/token-optimizer/scripts/bash_compress.py:1596-1598`）。Grep 工具结果仅被 `archive_result` 在 >4096 字符时归档。
8. **两个「ALLOW」开关都不是实验用的通用放行开关**（方案第 38/54-63 行的隔离假设）。`TOKEN_OPTIMIZER_ALLOW_UNSAFE_RUNTIME_HOME` 只放宽 Hermes runtime home 的 under-`$HOME` 检查（`skills/token-optimizer/scripts/hermes_state.py:150-177`，Claude Code 路径不读）；`TOKEN_OPTIMIZER_ALLOW_FOREIGN_HOME_SCHEDULER` 必须恰为 `"1"` 且只解除 scheduler 安装的 job 检查（`skills/token-optimizer/scripts/measure.py:413`、`skills/token-optimizer/scripts/_measure/runtime.py:392-399`）。而 hook 在隔离 HOME 下默认即 fail-open（`hooks/run.py:240-372`、`:434-490`），无需任何 ALLOW 开关。
9. **`TOKEN_OPTIMIZER_SNAPSHOT_DIR` 不足以隔离全部状态**（方案第 38 行隔离假设）。它只重定向 `SNAPSHOT_DIR`；checkpoints / quality-cache / run-once 标记仍写 `RUNTIME_DIR`（`skills/token-optimizer/scripts/measure.py:233`、`:485-492`、`:5005`）。隔离实验须同时隔离 runtime home。

（另有非冲突但需注意的细化项：结构图重复替换需要文件已在会话读缓存中，即方案第 74 行的「历史队列门槛」在重读路径上真实存在，见 `skills/token-optimizer/scripts/read_cache.py:1921-1975`；Markdown 在 `is_structure_supported_file` 上返回 True，但在首读替换上是 shadow-only，见 `skills/token-optimizer/scripts/structure_map.py:41`、`:215-241` 与 `skills/token-optimizer/scripts/read_cache.py:173-178`。）

---

## 手动触发配方（仅列出命令与 payload，不执行）

> 以下命令一律加 `--plugin-dir` 加载本地插件；不写 `enabledPlugins`；隔离 HOME 置于 `.tmp/benchmark-runs/`；任何命令均未在本核验中执行。

1. 启用/关闭各特性（作为 host 环境变量传入 Claude Code 进程）：
   - 首读活跃：`TOKEN_OPTIMIZER_FIRST_READ_ACTIVE=0`（关闭）。
   - 首读影子：`TOKEN_OPTIMIZER_FIRST_READ_SHADOW=0`（关闭）。
   - 结构图 beta：`TOKEN_OPTIMIZER_STRUCTURE_MAP_TREESITTER=1`。
   - codemap 重读：`TOKEN_OPTIMIZER_CODEMAP_REREAD=0`（关闭）。
   - delta：`TOKEN_OPTIMIZER_READ_CACHE_DELTA=0`（关闭）。
   - 渐进 checkpoint：`TOKEN_OPTIMIZER_PROGRESSIVE_CHECKPOINTS=0`（关闭）；冷却 `TOKEN_OPTIMIZER_CHECKPOINT_COOLDOWN_SECONDS=0`（缩短以便观测）。
   - verbosity 下限：`TOKEN_OPTIMIZER_VERBOSITY_MIN_FILL=25`。
   - 快照目录隔离：`TOKEN_OPTIMIZER_SNAPSHOT_DIR=<隔离目录>`（注意不隔离 checkpoints，见冲突 9）。

2. 直接以合成 payload 调用 `measure.py` 各子命令（stdin 传 hook JSON，cwd 置于被测项目）：
   - 压缩指导：`python3 skills/token-optimizer/scripts/measure.py dynamic-compact-instructions --quiet`，stdin 示例：
     `{"session_id":"bench-01","transcript_path":"<path>","cwd":"<proj>","hook_event_name":"PreCompact"}`
   - checkpoint 捕获：`python3 skills/token-optimizer/scripts/measure.py compact-capture --trigger auto --quiet`，stdin 同上。
   - 质量缓存强刷：`python3 skills/token-optimizer/scripts/measure.py quality-cache --force --quiet`。
   - PostCompact 路径即上一条（`hooks/hooks.json:159`）。
   - 渐进 checkpoint 观测：把填充推到越过 20/35/50/65/80 的 band（合成大 transcript 或直接调用 `_maybe_progressive_checkpoint` 的入口），冷却用 `TOKEN_OPTIMIZER_CHECKPOINT_COOLDOWN_SECONDS` 控制。

3. 读缓存 / 结构图（PreToolUse Read）：
   - `python3 skills/token-optimizer/scripts/read_cache.py --quiet`，stdin 示例：
     `{"session_id":"bench-01","tool_name":"Read","tool_use_id":"tu-1","tool_input":{"file_path":"<abs>","offset":0,"limit":0}}`
   - 注入 `cohort_tripwire.json`（仅在隔离 `SNAPSHOT_DIR` 内）以打开首读目标替换：结构
     `{"promoted_at":{"python|16-64KB":<ts>,"target_skeleton_v1|python|16-64KB":<同ts>},"demoted":[]}`。
     不写该 sidecar 时目标不被替换（`skills/token-optimizer/scripts/_measure/first_read_revive.py:9-23`）。
   - 清空账本：`python3 skills/token-optimizer/scripts/read_cache.py --clear --quiet`。

4. 归档与展开：
   - 造 >4096 字符的工具输出触发归档（阈 `skills/token-optimizer/scripts/archive_result.py:65`、`:1467-1468`）。
   - 列出：`python3 skills/token-optimizer/scripts/measure.py expand --list`。
   - 检索：`... expand --search <pattern>` / `... expand --grep <re>` / `... expand --lines 10-40`（参数见 `skills/token-optimizer/scripts/_measure/cli.py:2581-2624`）。
   - 清理：`... archive-cleanup`（`skills/token-optimizer/scripts/_measure/cli.py:2625-2633`）。

5. Bash 压缩（PostToolUse Bash）：
   - stdin 示例（走 `hooks/posttooluse_runner.py` 或直接验证 `bash_compress_hook`）：
     `{"session_id":"bench-01","tool_name":"Bash","tool_use_id":"tu-2","tool_input":{"command":"ls -la"},"tool_response":{"stdout":"<长输出>","stderr":"","exit_code":0}}`
   - 搜索结果压缩：让 `command` 为 grep/rg 形状且输出 ≥30 行（`skills/token-optimizer/scripts/bash_compress.py:1909-1946`）。
   - 关闭重写（早退）：设 `TOKEN_OPTIMIZER_NO_UPDATED_TOOL_OUTPUT=1`（`skills/token-optimizer/scripts/bash_compress_hook.py:230`）。

6. JSONL trim / dedup（dry-run = 不加 `--apply`）：
   - `python3 skills/token-optimizer/scripts/measure.py jsonl-trim <session-id-or-path>`（默认阈值 4000）
   - `python3 skills/token-optimizer/scripts/measure.py jsonl-trim <...> --threshold 4000 --apply`
   - `python3 skills/token-optimizer/scripts/measure.py jsonl-dedup <session-id-or-path>`
   - `python3 skills/token-optimizer/scripts/measure.py jsonl-dedup <...> --apply`
   - 校验 dry-run 无写入：改前后对目标文件做哈希比对（`skills/token-optimizer/scripts/_measure/quality_archive.py:2374-2377`、`:2540-2543`）。

7. verbosity nudge（UserPromptSubmit）：
   - 直接调用：`python3 skills/token-optimizer/scripts/measure.py verbosity-steer --quiet`，stdin 示例：
     `{"session_id":"bench-01","transcript_path":"<path>","cwd":"<proj>","prompt":"hi","hook_event_name":"UserPromptSubmit"}`
   - 触发温和档需 `fill_pct >= 25` 且 `session_efficiency < 75`；强档需 `fill >= 75`；`fill >= 90` 抑制（`skills/token-optimizer/scripts/_measure/quality_archive.py:7028-7082`）。
   - 若要固定输入，可写 `live-fill.json`（来源优先级 `skills/token-optimizer/scripts/_measure/quality_archive.py:1230-1259`）或用合成 transcript 控制 fill。

8. SessionStart 恢复（合成 payload）：
   - `source:"compact"` 或 `is_compact:true` → 走 compact 恢复：`hooks/sessionstart_runner.py:184-197`、`:440-457`。
   - `source:"clear"` → 清空后恢复：`hooks/sessionstart_runner.py:200-211`、`:460-488`。
   - `source:"startup"` 且非 compact → 新会话恢复：`hooks/sessionstart_runner.py:491-507`。
   - stdin 示例：`{"session_id":"bench-01","cwd":"<proj>","source":"compact","transcript_path":"<path>"}`。

9. Activity mode / 决策抽取（PostToolUse 合并派发）：
   - stdin 示例：`{"session_id":"bench-01","tool_name":"Edit","tool_use_id":"tu-3","tool_input":{"file_path":"<abs>"},"tool_response":{...}}`
   - 连续 10 次工具调用构成滑动窗口（`skills/token-optimizer/scripts/activity_tracker.py:17`、`:57-92`）；随后 PreCompact 的 `dynamic-compact-instructions` 应在头部打印 `mode=<code|debug|review|infra|general>`（`skills/token-optimizer/scripts/_measure/continuity.py:4108-4111`）。
   - 决策抽取需工具输出含 `_DECISION_RE` 命中句（`skills/token-optimizer/scripts/context_intel.py:190`、`:204-262`）。

---

## 未确认项

- 「搜索压缩」是否存在专门针对 Grep 工具结果、且与 Bash 压缩相互独立的开关或代码路径：未确认。检索位置：`skills/token-optimizer/scripts/bash_compress.py`、`bash_compress_hook.py`（自门控 `tool_name == "Bash"`）、`hooks/posttooluse_runner.py:653`。当前证据仅支持「Grep 工具结果不走该压缩，超阈值时被 archive_result 归档」。
- `measure.py` 中 `v5_bash_compress` 元数据字符串之外，Claude Code 侧是否还有其它读取 `TOKEN_OPTIMIZER_BASH_COMPRESS` 的入口：未确认（当前仅见 `bash_hook.py:52` 的静默遗留函数；该函数 `main()` 于 `bash_hook.py:56-58` 直接 return）。
- 渐进 checkpoint 的 band 是否在真实会话中可稳定通过合成 payload 触发（需真实 fill 越过 band 且未冷却）：未确认，需在隔离环境实测。

# 附录 A：`tokless` 机制核验（含实测）

核验范围与方式：

- 源码为第三方不可信数据，只读取与引用，不在已装环境执行其脚本。**唯一例外**是本基准方案已确认的安装步骤：`benchmark/scripts/prepare.sh` 在隔离 HOME（`/tmp/tokbench/arms/tokless/home`）下执行 `tokless install claude`。tokless 的能力只有装完才存在，所以这一部分必须包含安装动作。
- 凡标「实测」的结论都附产物路径：探针表 `/tmp/tokbench/findings/probe_m1*.tsv`，运行日志 `/tmp/tokbench/runs/<task>/<arm>/r<round>/stream.jsonl`，安装产物 `/tmp/tokbench/arms/tokless/install.log` 与 `.../home/`。
- 探针与正式采样使用同一份 fixture（`/tmp/tokbench/fixture/workspace`）和同一条链路；探针 HOME 与 arm HOME 分离，但 `rtk` 的选中状态在缺省 `selection.json` 时等价（见 A3）。
- 未读、未打印任何凭据取值；`secrets/canary.env` 只记录「原串是否原样进入模型可见文本」这一布尔值。

## A1 安装面（实测）

命令 `tokless install claude`（源码入口 `tokless/internal/commands`，安装器按工具逐个执行）报告 8 个组件：

| 组件 | 安装方式（install.log 原文） | 结果 |
| --- | --- | --- |
| RTK | already installed | ✓（`rtk` 预编译二进制） |
| CodeGraph | npm install -g | ✓ |
| Context-Mode | already installed | ✓ |
| Headroom | package install | ✓ 安装，**未接线** |
| ProjectMem | package install | **✗ install failed** |
| Ponytail | Claude Code 侧写入 | ✓ |
| Caveman | Claude Code 侧写入 | ✓ |
| Karpathy Principles | Claude Code 侧写入 | ✓ |

`install.log` 自报 3 处异常：

```
|   x ProjectMem       install failed
|   x Claude Code      1 tool not wired
|   ! Claude Code: Headroom not wired. Run tokless doctor for details.
```

自报异常与实际产物的对照（说明「自报失败 ≠ 能力缺失」）：

- ProjectMem：`home/.local/share/uv/tools/projectmem/bin/pjm-mcp` 与 `home/.local/bin/pjm-mcp` **都存在**；`home/.claude/.claude.json` 里 `mcpServers` 已注册 3 个（`codegraph` / `context-mode` / `projectmem`）。即自报失败的是某个校验步骤，不是安装本身。
- Headroom：`headroom` 代理在 `127.0.0.1:8787` 启动，但 Claude 没有被指向它——三臂的 `ANTHROPIC_BASE_URL` 都是基准自己的本地路由 `http://127.0.0.1:3425`。所以 Headroom 在本基准中**全程不参与**，不算被测机制。
- 「1 tool not wired」对应 Headroom（上一条提示已点明），不是 RTK。

副作用（需在报告中如实记录）：CodeGraph 的 npm 全局安装**穿出了隔离 HOME**，落进真实用户的 npm 前缀 `~/.local/share/mise/installs/node/latest/bin/codegraph`（时间戳与本次安装一致），而隔离 HOME 里的 `.npm/bin` 为空。这是安装器未隔离 `npm prefix` 的行为，不是基准脚本的问题；为不污染用户环境，脚本未删除该文件（删除属破坏性操作），只在报告中说明。

RTK 二进制的来源不在 tokless 仓库内：`tokless/internal/tools/rtk.go:63-101` 从 `https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh` 或 GitHub releases 取预编译二进制。**改写规则不在本仓库**，只能靠实测观察（A4）。

## A2 Claude Code 侧接线（实测）

tokless 写进 arm HOME 的 `home/.claude/settings.json`（键：`env`、`hooks`、`permissions`）：

| 事件 | matcher | 命令 |
| --- | --- | --- |
| `PreToolUse` | `Bash` | `/tmp/tokbench/toolchain/tokless rtk-hook claude` |
| `UserPromptSubmit` | — | `codegraph prompt-hook` |
| `SessionStart` | — | `/tmp/tokbench/toolchain/tokless projectmem-hook claude` |

`permissions.allow` 共 14 条，全部指向 RTK 与 3 个 MCP 服务器（`Bash(rtk *)`、`mcp__codegraph__*`、`mcp__context-mode__ctx_*`、`mcp__projectmem__*`）。

此外写入了 `home/.claude/.claude.md`（14 892 字节，标题 "Agent Instructions"）：caveman 的 terse 输出要求、ponytail 的构建纪律、以及「调用 `codegraph_explore` / `ctx_*` / `projectmem` MCP 工具」的指示。baseline 与 optimizer 的 arm HOME 均无 `CLAUDE.md`。

每次真实运行的触发计数（`stream.jsonl` 内钩子事件，10 次同任务采样中的典型值）：

| arm | PreToolUse | PostToolUse | SessionStart | UserPromptSubmit | Stop |
| --- | --- | --- | --- | --- | --- |
| baseline | 0 | 0 | 0 | 0 | 0 |
| optimizer | 0（Read 路径未触发，见 B） | 20 | 2 | 4 | 2 |
| tokless | 10 | 0 | 2 | 2 | 0 |

tokless 的 `SessionStart`（projectmem-hook）与 `UserPromptSubmit`（codegraph prompt-hook）两次调用**输出为空、退出码 0**，即没有注入任何 `additionalContext`；其唯一实际生效的钩子是 `PreToolUse/Bash`。

MCP 层：`--strict-mcp-config` 使已注册的 3 个 MCP 服务器不加载；`--tools Bash` / `--tools Read,Edit` 使 `CLAUDE.md` 里点名的 MCP 工具根本不在工具表内，因此不会产生「调用失败」的浪费回合。可测量的不对称只剩：14 892 字节常驻 `CLAUDE.md`（仅 tokless 有）与钩子数量（3 / 1 / 0）。此项在附录 B 作为威胁项列明。

## A3 rtk 改写契约（源码）

`tokless/internal/commands/rtk_hook.go`：

- `RunRtkHookCodex`（`:214-259`）是 Claude Code 与 Codex 共用的入口；Claude Code 的 `PreToolUse` 只有在 `tool_name` 是 Bash 类工具且 `tool_input.command` 非空时才处理。
- 输出形状（`:235-251`）：`hookSpecificOutput{ hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: {...原 tool_input，command 被替换} }`。注意 `permissionDecision` 固定为 `"allow"`——这个钩子顺带把命令放行，不涉及权限询问。
- `rtkRewrite`（`:118-142`）的拒绝条件：`cmdLine` 为空、`rtkUnsafeFind(cmdLine)` 为真（`:56-69`，对含危险用法的 `find` 不改写）、`hasShellPipe(cmdLine)` 为真（`shellTokens` `:25`，**任何管道都拒绝**），或解析不到 `rtk` 二进制（`util.ResolveRtkBin`，`:73-88`）。
- 改写由外部 `rtk rewrite <cmdLine>` 完成：`rtk` 以退出码 3 表示「不改写」，tokless 依此判定（`cmd.ProcessState.ExitCode() != 3` 才视为失败）；输出与原命令相同时也视为未改写。
- 入口分发 `tokless/cmd/tokless/main.go:314-331`（`rtk-hook claude` → `RunRtkHookCodex`）。`RunRtkHook`（`:166-213`）是 **Antigravity** 的变体（`run_command`、`permission/allowTool/overwrite` 形状），不要与 Claude 路径混用。

两点必须写进报告：

1. `hasShellPipe` 的存在意味着**带管道的命令在 tokless 侧永不改写**。「大输出 + `| head`」这种最常见的省 token 写法，tokless 反而没有机会介入。
2. 改写规则整体在 `rtk` 二进制内，仓库不提供规则表；本文件只能给实测样本，不能给规则全集。

## A4 实测：同一条命令在两条链路上的字节（模型可见）

产物 `/tmp/tokbench/findings/probe_m1e.tsv`。列含义：`raw` = 命令原始 stdout 字节；`tokless 字节` = 改写后命令的 stdout 字节；`→ 模型可见` = 再经宿主截断层（>30000 字符即只给 2000 字符预览 + 约 240 字节包装，见报告「环境效应」一节）后模型实际收到的字节。optimizer 未改写时模型可见量即 `raw` 经同一层。

| case | 命令 | raw | tokless 改写 | tokless 字节 → 可见 | optimizer 改写 | optimizer 字节 → 可见 |
| --- | --- | ---: | --- | ---: | --- | ---: |
| build.log | `cat assets/build.log` | 468877 | `rtk read …` | 468877 → 2240 | 否 | 468877 → 2240 |
| buildlog-script | `bash bin/emit_buildlog.sh` | 468943 | — | — | 否 | 468943 → 2240 |
| inventory.csv | `cat assets/inventory.csv` | 366756 | `rtk read …` | 366756 → 2240 | 否 | 366756 → 2240 |
| replay.py | `cat codec/replay.py` | 67501 | `rtk read …` | 67501 → 2240 | 是 | 2065 → 2065 |
| replay-head200 | `sed -n '1,200p' codec/replay.py` | 5572 | — | 5572 | 是 | 2099 |
| grep-warn-head | `grep -n WARN assets/build.log \| head -40` | 2981 | — | 2981 | 否 | 2981 |
| grep-warn-all | `grep -n WARN assets/build.log` | 17690 | `rtk grep …` | 1934 → 1934（89%） | 否 | 17690 |
| grep-warn-recurse | `grep -rn WARN .` | 22250 | `rtk grep …` | 2411 → 2411（89%） | 否 | 22250 |
| grep-def-dense | `grep -rn 'def ' .` | 28348 | `rtk grep …` | 9381 → 9381（67%） | 是 | 2846（90%） |
| grep-corpus | `grep -rn zephyrquorum corpus/` | 1531 | `rtk grep …` | 1531（原样） | 否 | 1531 |
| grep-anchor | `grep -rn ANCHOR codec/` | 159 | `rtk grep …` | 159（原样） | 否 | 159 |
| buildlog-head700 | `sed -n '1,700p' assets/build.log` | 27186 | — | 27186 | 是 | 2476 |
| wc-lines | `wc -l codec/*.py codec/client/src/*.ts` | 232 | `rtk wc …` | 155 | 否 | 232 |
| ls-assets | `ls -la assets` | 240 | `rtk ls …` | 50 | 否 | 240 |
| canary.env | `cat secrets/canary.env` | 408 | `rtk read …` | 408（原样） | 否 | 408 |

可归纳的实测结论：

1. **超过宿主上限的读取，两臂对模型的实际节省相同**：都是 ~2240 字节。tokless 的 `rtk read` 拿到的是原文字节数（`rtk read` 对 cat 类命令原样输出，不做压缩），optimizer 干脆不改写；节省全部来自宿主的落盘层。所以 feature #1/#6 在「超大读取」这一档上，本机环境下测不出工具差异。
2. **tokless 的压缩优势集中在「中体积 + 检索类」**：`rtk grep` 对密集命中压缩 67–89%，而同类命令 optimizer 完全不改写（见 A5 的原因）。`rtk wc`/`rtk ls` 对小型结构化输出也做归并（232→155、240→50）。
3. **`sed` 形式的读取，两侧都不改写**：tokless 的 `hasShellPipe`/改写规则不覆盖 `sed -n 'a,b p'`，optimizer 的 `sed` 识别另有一套（`buildlog-head700` 在 optimizer 侧压缩到 2476，说明 optimizer 认 `sed`；tokless 不认）。反过来，`cat` 形式对 optimizer 是「按体积扫描」的压缩对象（`replay.py` 67501→2065）。
4. **小输出原样通过**：`canary.env`（408）两侧都不压缩——凭据文件在本 fixture 里没有因为「压缩」而被改写，两侧的「凭据安全」体现在不同的层（tokless 不碰；optimizer 有脱敏层，见报告「环境效应」一节的脱敏层说明）。

体积阶梯（optimizer，`/tmp/tokbench/findings/probe_m1_sweep.tsv`，合成日志）：

| raw | 替换后字节 | 备注 |
| ---: | ---: | --- |
| 4096 | 1809 | |
| 8192 | 1925 | |
| 16384 | 2026 | |
| 24576 | 2140 | |
| 32768 | 2210 | |
| 65536–131072 | 2210 | |
| 222822 | 2210 | |
| 262144 | 2210 | 偶见 budget 提示 |
| 327680 / 393216 / 458752 / 524288 | 未替换 | `bash_compress_hook budget exceeded 0.625s` |

即 optimizer 的 Bash 压缩上限由**延迟预算**决定，不随输出体积增大而继续增长；实测稳定区间到 ~262 KB，超过约 327 KB 时钩子超时而放弃改写（此时模型仍受宿主 30000 字符上限保护）。

## A5 检索压缩：两套机制方向相反

token-optimizer 侧（源码）：`skills/token-optimizer/scripts/bash_compress.py`

- `_detect_pattern` 的 search 分支 `:1596-1598`；形状判定 `_SEARCH_FILE_LINE_RE = re.compile(r'^(.+?):(\d+)[:](.*)$')` `:1906`；`_compress_search_results` `:1909-1946` 要求 **≥30 行**匹配该形状，按文件分组后经 `bash_search_results.render_search_results` 输出（`bash_search_results.py:4-6`：`_MAX_PER_FILE = 3`、`_MAX_FILES = 20`）。
- 后果一：**单文件 `grep -n` 的输出形状不带文件名**，因此永不进入该分支（`grep-warn-all` 17690 原样）。
- 后果二：压缩后还要经过 `preserved_reinject`：`priority_lines = find_priority_lines(...)` `:2180` → `compressed = reinject(...)` `:2213`。`find_priority_lines`（`preserved_reinject.py:17`）把**所有** WARN/ERROR 行逐字回填，`reinject`（`:26`）把它们插回压缩结果。
- 后果三：`compress()` `:2146` 末尾有 10% 收益门 `:2223-2225`：`if original_tokens > 0 and (1.0 - compressed_tokens/original_tokens) < 0.10: return cleaned`。回填破坏收益后，整个压缩被**退回原文**。

可复现的进程内实验（同 fixture 的 WARN 密集样本）：

```
240 条 priority 行
压缩体      509 bytes
reinject 后 22477 bytes
savings     -1.0%   → 10% 门拒绝 → 返回原文
```

对照：同一形状但**不含 WARN/ERROR** 的密集检索（`grep-def-dense` 28348）走 2846 字节（90%）。结论：token-optimizer 的「搜索结果压缩」是 **warning 敏感**的，WARN 越密集越可能退化为零压缩；tokless 的 `rtk grep` 恰好相反——它对 WARN 密集输出压缩到 89%，因为它是在聚合而不是逐字回填（具体规则在 rtk 二进制内，不可审计）。

## A6 12 项能力的 tokless 侧核查

核查分三层：tokless Go 源码、安装的组件、Claude Code 侧实际接线（`settings.json` + `CLAUDE.md` + 运行日志）。判定「有对应能力」必须在这一层能到达，MCP 工具在被 `--strict-mcp-config` 关闭时不计为已接线。

| # | 能力 | tokless 侧 | 证据 |
| --- | --- | --- | --- |
| 1 | Bash 输出压缩（默认开） | **有**（改写命令，非改写结果） | `PreToolUse/Bash` + A4 表 |
| 2 | Delta（重读已修改文件只给 diff） | **无**（Claude Code 侧） | 无 `PostToolUse`/`Read` 钩子；Go 源码无 delta 实现 |
| 3 | Structure Map（重读大文件给骨架） | **无** | `checkpoint`/`skeleton` 在 `tokless/**/*.go` 中零实现命中（唯一命中是 `internal/tools/projectmem_bounded_test.go` 的无关字串） |
| 4 | 首读重定向 | **无**（Claude Code 侧） | 同上；CodeGraph 为 MCP 服务器，被 `--strict-mcp-config` 关闭 |
| 5 | 搜索结果压缩 | **有** | 与 #1 同一路径：`rtk grep`（A4、A5） |
| 6 | 工具结果归档 + `expand` | **无** | 无 `PostToolUse`，无法接触工具结果；`expand` 无实现 |
| 7 | 高上下文精简提示 | **有替代物，但机制不同** | 不是按 fill 触发；是 14 892 字节常驻 `CLAUDE.md` 的 caveman 规则（全程生效） |
| 8 | JSONL 修剪与去重 | **无** | 相关 wiring 只在 Codex 路径（`internal/tools/contextmode.go:387`、`:759` 是 `removeCodexContextModeHooks` / `writeCodexAgentsMd` / `ctxVerifyCodexShape`） |
| 9 | 检查点捕获/恢复 | **无**（Claude Code 侧） | 无 `PreCompact`/`PostCompact` 钩子；ProjectMem MCP 未加载 |
| 10 | 渐进检查点 20/35/50/65/80% | **无** | 无填充度钩子；ProjectMem 未加载 |
| 11 | 压缩指令注入 | **无** | 无 `PreCompact` 钩子 |
| 12 | 活动模式 + 决策提取（≤10） | **无** | 仅在 ProjectMem 的 `add_decision` MCP 工具上（已注册但未加载）；无自动提取 |

因此基准的比较框架是：

- #1、#5：两侧都有 → 直接比较。
- #2、#3、#4、#6、#7、#8、#9、#10、#11、#12：token-optimizer 有、tokless 无 → 记 N/A，但保留「能力存在性核查」（上表即核查结果，全部为「无」而非「未查」）。
- 仅 #7 需在报告中注明 tokless 的替代物（常驻 CLAUDE.md），否则「N/A」会掩盖它对输出的实际影响。

## A7 探针产物：会话 id 含 `.` 时 token-optimizer 归档失效（探针 artifact）

探针早期用形如 `probe-m1:grep-...` 的会话标签，观察到压缩结果被退回原文。根因不在压缩逻辑：

- `skills/token-optimizer/scripts/session_store.py:168-174` 的 `_sanitize_session_id` 对不匹配 `^[a-zA-Z0-9_-]+$` 的 id，返回**每次调用都重新随机生成**的 `fallback-<uuid12>`。
- 于是「归档写入」（`archive_result.py:195-234` / `:1055-1124`）与「写入后校验」（`bash_compress.py:2344` 附近的 `archive_entry_exists`）落在两个不同目录，校验失败，压缩被退回原文。
- 真实 Claude Code 的会话 id 是 UUID，符合该约束；正式采样未出现该现象。探针脚本已把标签归一化为 `_TOKEN_SAFE`（`benchmark/scripts/probe_m1.py:62-69`）后重跑，A4 表为归一化后的结果。

结论按「探针 artifact」记录：仅当调用方传入非法 id 时才触发，属窄边界行为，不进入报告的主结论。

## A8 未确认项（tokless）

- `rtk` 改写规则的完整集合：未确认。规则在预编译二进制内，仓库不含规则表；本文件只有 A4 的样本。检索位置：`tokless/internal/tools/rtk.go:63-101`（只给出安装来源）。
- `rtk read --level none` 是否在任何情况下压缩：未确认。样本中 4 个大文件均原样输出（468877/366756/67501/408）。`rtk read` 的可选级别未在 tokless 仓库中出现，无法从源码确认参数语义。
- CodeGraph 的 `prompt-hook` 为何在实测中输出为空：未确认。可能依赖安装后缓存或选择状态；本基准未进一步触发。检索位置：`tokless/internal/tools/codegraph.go`（安装与钩子写入），`/tmp/tokbench/arms/tokless/home/.claude/settings.json`。
- ProjectMem 的 `install failed` 具体失败点：未确认（产物存在且 MCP 已注册）。检索位置：`/tmp/tokbench/arms/tokless/install.log:25`、`.../home/.claude/.claude.json`。
- tokless 在 **Read 工具路径**（t3/t5）是否有任何机制：未确认。当前证据是「无 Pre/PostToolUse(Read) 钩子」，因此预期为纯 baseline 行为；正式采样会给出直接证据（三臂在 t3/t5 的差异应归零）。

# 附录 B：三臂环境差异（对称性核验）

三臂使用完全相同的：模型与 effort、提示词字节、绝对工作区路径、工具集、超时、本地路由、无网络、禁用技能与子命令、无子代理；每臂独立 HOME 与 `CLAUDE_CONFIG_DIR`；预热样本丢弃；三臂交错轮转；失败样本保留。

已核验的差异（均属被测工具自身安装行为，不是基准引入）：

| 项 | baseline | optimizer | tokless |
| --- | --- | --- | --- |
| `settings.json` 顶层键 | `env` | `cleanupPeriodDays`、`env`、`hooks`、`statusLine` | `env`、`hooks`、`permissions` |
| `settings.json` 内钩子 | — | `UserPromptSubmit`（`measure.py quality-cache`） | `PreToolUse/Bash`、`UserPromptSubmit`、`SessionStart` |
| 插件钩子（`--plugin-dir`，`hooks/hooks.json`） | — | `PreToolUse`×3（Read / Agent|Task / mcp）、`PreCompact`×3、`SessionStart`、`SubagentStart`、`Stop`、`SessionEnd`、`StopFailure`、`UserPromptSubmit`、`PostToolUse`×1（含 Bash）、`PostToolUseFailure`、`PostCompact`、`CwdChanged` | — |
| 常驻 `CLAUDE.md` | 无 | 无 | 14 892 字节 |
| MCP 服务器注册 | 无 | 无 | 3 个（被 `--strict-mcp-config` 关闭） |
| 每次运行的注入上下文 | 0 | SessionStart `additionalContext` 639–940 字符 | 钩子输出为空 |

两点必须在报告中说明：

1. **注入上下文的不对称**：optimizer 的 `SessionStart` 每次向模型注入 639–940 字符（如 "Code map available…" / "Cross-session checkpoint…"），baseline 与 tokless 为 0。optimizer 的跨会话 checkpoint 还会在同一 arm HOME 内跨任务累积（t1b 收到过 t1 的状态）。这既是被测机制的一部分（feature #9/#12），也是**每轮固定成本**——报告在比较「总 token」时须把这一层单列，否则会把「机制收益」与「机制成本」混在一起。
2. **MCP 层被排除**：tokless 的能力面有相当一部分在 3 个 MCP 服务器上（CodeGraph / Context-Mode / ProjectMem），而正式的 54 格主采样统一 `--strict-mcp-config`。这样做的理由是保持三臂工具集完全相同，且 54 格进行中不可改变配置；代价是 tokless 的 MCP 能力未被测量。报告中作为威胁项列明，并给出能力存在性核查（A6）作为补充证据。

此外，宿主层对三臂一视同仁（同一 `claude` 2.1.311、同一 `HOME` 布局、同一 `BASH_MAX_OUTPUT_LENGTH`），因此「超过 30000 字符即只给 2000 字符预览」不是臂间差异；报告中把这一层单独计为「宿主提供的节省」，避免把它记到任一工具头上。

# 附录 C：环境效应（不属于任一被测工具）

本附录由 `benchmark/scripts/env_effects.py` 重算，原始输出 `/tmp/tokbench/findings/env_effects.txt`（不提交）。三层都不属于被测工具，但都会改变「模型看到什么」和「token 怎么记账」，因此报告中必须与工具效果分开列。

## C1 宿主落盘层（tool-results）

`claude` 2.1.311 对超过约 30 000 字符的工具结果，把全文写到 `<arm HOME>/.claude/projects/<slug>/<session_id>/tool-results/*.txt`，只把约 2 KB 预览交给模型。fixture 中两个超大输出：`build.log` 468 877 字节、`inventory.csv` 366 756 字节。

| 臂 | 命中格数 | 落盘文件 | 磁盘全文 | 模型看到的预览 | 比例 |
| --- | --- | --- | --- | --- | --- |
| baseline | 9 | 18 | 7 521 199 B | 40 257 B | 0.54% |
| optimizer | 9 | 17 | 7 154 674 B | 38 042 B | 0.53% |
| tokless | 9 | 18 | 7 521 183 B | 40 239 B | 0.54% |

命中格共 27 格（t1 / t1b / t4 每臂 3 轮），即三臂在超大输出上的「节省」几乎相同——差值仅来自模型当轮命令写法（`inventory.csv` 落盘字节差分布 `{0: 24, 16: 1, 247: 1}`，非 0 的两格是模型在同一次 Bash 调用里追加了 `echo`/`wc`；`build.log` 为 `{54: 27}`，因脚本先打印一行 `wc -l`）。

两点推论：

1. 本 fixture 上最大的「结果变短」发生在宿主层，且三臂一致。审计任何「压缩生效」结论时必须先排除这一层。
2. Read 工具的结果**不落盘**，因此 Read 载荷在三臂间逐字节相同（例如 t5 每次 Read 原始 108 208 字节，baseline 与 tokless 完全一致）。t3/t5 的臂间差异因此无法由宿主层解释。

## C2 出口脱敏层（本地路由 masking）

本地路由在请求出口把身份与凭据替换成定长伪值，本地账本保留真值。基准 319 条请求中：`SECRET` 243 条 / 4 857 次、`HOSTNAME` 282 / 282、`USERNAME` 292 / 462、`API_KEY` 232 / 863、`PASSWORD` 58 / 127；其中形状为 canary（`ghp_` + 十六进制，定长）的伪值 2 个，共出现 844 次；canary 真值在脱敏账本中出现 0 次。脱敏耗时中位 160 ms、最大 2047 ms。上行字节 / 明文字节中位 1.000、p95 1.000、最大 2.000（n=513），即脱敏基本不改变体积。

关键一点：脱敏只作用于**出口**，本地工具结果里 canary 真值仍在（t1 九格 9/9 命中）。因此 #1 的「对凭据安全」只能按「模型看到的是伪值、真值不出网」来判定，不能按「结果里没有凭据」判定。这就是任务设计里把 t1 的凭据项拆成 `canary_preserved` / `canary_quote` 且不计入 `task_pass` 的原因。

## C3 分类路由层（`group/smart-split`）

513 条请求经别名归并后由两个后端服务：`deepseek-v4-1-flash` 503 条、`kimi-k3-1-pro` 10 条（客户端上报名与之一致）。HTTP 状态 `{200: 510, 499: 3}`；token 合计 in 4 547 775 / out 297 480 / cache_read 4 789 120 / cache_write 91 392。两次运行中途换过后端：`t5/baseline/r2`（13 + 5）、`t5/tokless/r3`（11 + 5）。

**实际服务的后端不是 Claude**，报告中必须披露；所有臂间比较仍是同模型同路由的对照，但结论不能外推到 Claude 本身。
