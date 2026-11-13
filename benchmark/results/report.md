# tokless 与 token-optimizer 对比基准：结果报告

- 对象：tokless v1.0.13（本地快照 `tokless/`，HEAD `c9a7b82`）与 token-optimizer v5.13.71（`token-optimizer/`，rev `58ceaf0`）
- 规模：6 任务 × 3 臂 × 3 轮 = 54 格，另有每臂 1 轮预热（不计分）
- 宿主：Claude Code 2.1.311；服务端：本地路由 `group/smart-split[1m]`
- 判分：`score.py` 按 fixture 真值判 4 项/任务，不看工具自报数据
- 明细证据：`benchmark/docs/mechanism-notes.md`（附录 A 逐格证据、附录 B 逐格机制观测、附录 C 环境效应）

## 0 一句话结论

在本 fixture 上，三臂的**任务完成度没有差别**（18/18、18/18、17/18），token 总量的差别也**不是被测机制造成的**：模型实际看到的大输出几乎全被宿主自己的落盘层截断，两边工具在本轮采样里都**几乎没有真正替换过模型可见内容**（54 格内 `updatedToolOutput` 计数为 0）。测出来的差异主要来自模型每轮的命令形状与轮数波动，其次是钩子对 token 结构的副作用。

## 1 结论摘要

1. **机制触发 ≠ 节省。** 两套工具都频繁触发（optimizer 284 次钩子调用，tokless 123 次、其中 22 次真的改写了命令），但真正改变模型可见内容的次数：tokless 7 次 `wc` 摘要、optimizer 0 次。本 fixture 上最大的 token 削减来自宿主层（>30 000 字符的结果落盘为 ~2 KB 预览），三臂同等受益。
2. **optimizer 的 Bash 压缩路径是活的，但在真实命令形状下过不了自己的门。** 直接探针（同一 fixture、直接调钩子）能稳定产出 `tier=measured, verified=1` 的压缩（`cat codec/replay.py` 20 495→627 token）；54 格里 116 次 Bash 调用中 92 次带管线/分号/`&&`，纯只读单命令只有 7 条，且全部落在 `error_or_short` 或 `under_10pct` 门下。
3. **tokless 的收益集中在检索类输出**（`grep -rn` 17 690→1 934 B、22 250→2 411 B，均 -89 %），optimizer 在同一探针上对这些不替换；反过来 optimizer 压文件读取、tokless 不压（`cat codec/replay.py` 两侧分别是 2 065 B 与 67 501 B 原样）。
4. **两个工具都会「触发但零生效」**：tokless 的增量模式检测到 3 次重复读、替换 0 次；optimizer 的 Structure Map 44 次进入钩子、0 次向模型输出。
5. **token 口径下 tokless 的均值更差、成本更低。** 原始均值 130 286 / 165 904 / 124 561（baseline / tokless / optimizer）；去掉 3 个离群格后 tokless 总量 -15.8 %、成本 -29.1 %，optimizer 总量 -7.9 %、成本 +3.7 %。差异主要由轮数与输出长度解释，不由机制解释。
6. **完成度已饱和**（天花板效应），因此本报告以「机制是否真的改变了模型可见内容」为主结论轴，token/成本为辅。

## 2 方法

### 2.1 三臂

| 臂 | 安装 | 说明 |
| --- | --- | --- |
| baseline | 无 | 只写入 `ANTHROPIC_*` 路由 env，其余为空 |
| tokless | `tokless --agents claude --yes --no-autostart` | 8 组件默认安装；`rtk` 二进制来自快照源码构建（go 1.26.11） |
| optimizer | 插件默认安装 | `token-optimizer` 插件默认配置，不调任何开关 |

三臂使用同一 `HOME` 隔离布局、同一 fixture 绝对路径、同一模型与 effort（medium）。臂顺序按 (任务序号 + 轮次) 旋转，抵消顺序偏差；预热轮丢弃。

### 2.2 六个任务与工具面

| 任务 | 工具面 | 主要考的量 |
| --- | --- | --- |
| t1 | Bash | 大输出读取 + 凭据文件读取（含假凭据复核） |
| t1b | Bash | t1 去掉凭据那一步的对照片 |
| t2 | Bash | 检索类输出（多文件 `grep`） |
| t3 | Read, Edit | 同文件重复读 + 定点改一行 |
| t4 | Bash | 中等体积读取与统计 |
| t5 | Read | 两个 ~63 KB 长文档 + 强制真实压缩（window 100 000） |

每个任务只开放会走到被测工具的那一种工具，避免模型绕开钩子后三臂趋同。

### 2.3 判分与口径

- 每任务 4 项真值，来自 `make_fixtures.py` 生成后由 `--selfcheck` 重新扫描校验的事实表；真值文件在 workspace 之外，模型读不到。
- `task_pass` 只看答案正确性。凭据两条观测轴（工具结果里凭据串是否原样保留、最终答复引用的串是否等于磁盘真值）**不计入** `task_pass`，因为它们受本地路由出口脱敏影响（见 7.2）。
- token 口径：`gross_input = input + cache_creation + cache_read`，取自 stream-json 的 usage，不读工具自报数据。

## 3 任务完成

| 臂 | 通过格数 | 失败格 | 备注 |
| --- | --- | --- | --- |
| baseline | 18/18 | — | |
| tokless | 18/18 | — | |
| optimizer | 17/18 | t5/optimizer/r3（3/4） | 缺一项：长文档定点事实 |

三臂在 t1–t4 全部满分，t5 只有一格失分。**完成度指标已饱和**，无法区分工具好坏；能区分的只有「机制有没有真的改变模型看到的内容」。

## 4 token 与成本

### 4.1 总量（18 格/臂）

| 臂 | gross_input 合计 | 均值 | 输出 token | 成本 USD | 墙钟秒 | 轮数 | 钩子调用 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| baseline | 2 345 156 | 130 286 | 87 913 | 11.42 | 1 691 | 192 | 0 |
| tokless | 2 986 277 | 165 904 | 30 958 | 10.50 | 973 | 168 | 123 |
| optimizer | 2 242 093 | 124 561 | 71 749 | 11.22 | 1 422 | 188 | 284 |

### 4.2 分散度

| 臂 | 中位数 | 标准差 | 最大格 |
| --- | --- | --- | --- |
| baseline | 57 641 | 157 541 | 517 276（t5/r2） |
| tokless | 60 180 | 293 416 | 1 275 965（t5/r1） |
| optimizer | 71 829 | 133 497 | 408 563（t5/r2） |

三格离群主导了均值：t5/tokless/r1（1 275 965，33 轮）、t4/baseline/r3（314 449）、t1/optimizer/r2（371 454）。

### 4.3 去掉 3 个离群格后

| 臂 | gross_input 合计 | 相对 baseline | 输出 token | 成本 USD | 相对 baseline |
| --- | --- | --- | --- | --- | --- |
| baseline | 2 030 707 | — | 33 138 | 9.54 | — |
| tokless | 1 710 312 | -15.8 % | 25 524 | 6.76 | -29.1 % |
| optimizer | 1 870 639 | -7.9 % | 42 554 | 9.89 | +3.7 % |

### 4.4 逐任务中位数 gross_input

| 任务 | baseline | tokless | optimizer |
| --- | --- | --- | --- |
| t1 | 28 580 | 45 553 | 74 757 |
| t1b | 46 992 | 55 678 | 20 892 |
| t2 | 20 734 | 30 158 | 16 637 |
| t3 | 72 058 | 86 976 | 71 940 |
| t4 | 113 718 | 61 548 | 107 101 |
| t5 | 479 205 | 468 517 | 407 731 |

### 4.5 逐任务成本（USD，18 格/3 轮合计）

| 任务 | baseline | tokless | optimizer |
| --- | --- | --- | --- |
| t1 | 0.30 | 0.34 | 1.65 |
| t1b | 0.38 | 0.32 | 0.27 |
| t2 | 0.30 | 0.20 | 0.19 |
| t3 | 0.75 | 0.81 | 0.89 |
| t4 | 2.37 | 0.46 | 1.03 |
| t5 | 7.33 | 8.37 | 7.19 |

t5 占三臂成本的一半以上（强制真实压缩的代价）；t4 的巨大差异来自 baseline 那一格的 23 轮漫游，不是机制差异。

### 4.6 Bash 结果交付量（54 格内）

| 臂 | Bash 调用 | 交付字节 | 均字节/次 |
| --- | --- | --- | --- |
| baseline | 112 | 84 504 | 754 |
| tokless | 78 | 60 287 | 772 |
| optimizer | 116 | 86 610 | 746 |

每格平均交付量几乎一致（746–772 B/次）：**压缩没有把 Bash 交付量拉开差距**，tokless 总量低只是因为它调用次数少。真正的大输出（469 KB 构建日志、367 KB 清单）在三臂都以宿主落盘的 ~2 KB 预览形式交付。

## 5 十二项功能逐项判定

判定用四态：**生效**（改变了模型可见内容）/ **触发未生效**（代码路径执行但结果被丢弃或不注入）/ **未触发**（条件未满足，路径存在）/ **无对应**（该工具没有这一机制，或只有需要手工执行的等价物）。已装工具的「无对应」项都另做了能力存在性核对（源码检索 + 直接探针）。

| # | 功能 | tokless | token-optimizer |
| --- | --- | --- | --- |
| 1 | Bash 输出压缩（凭据安全），默认开 | 生效（小：22 次改写 / 7 次可见；`grep -rn` -89 %） | 触发未生效（153 条覆盖记录，0 条 `compressed`，54 格 0 次 `updatedToolOutput`） |
| 2 | Delta 模式（重复读改后文件 → 只给差异），默认开 | 无对应（`rtk read` 是读取改写，非差异） | 触发未生效（检测 3 次 `redundant_read_2`，替换 0 次） |
| 3 | Structure Map（大文件重读 → 骨架），默认开，软拦截 | 无对应 | 触发未生效（44 次进钩子，0 次输出；6 条 shadow 骨架测量） |
| 4 | 首次读取重定向 | 部分（`cat/sed` 改写为 `rtk read`，字节未变） | 触发未生效（在 #3 同一软拦截路径内） |
| 5 | 搜索结果压缩 | 生效（`grep -rn` 17 690→1 934 B、22 250→2 411 B） | 触发未生效（1 条 `search_results` 候选 243 token，`under_10pct` 被拒） |
| 6 | 工具结果归档 + `expand`，默认开 | 无对应 | 生效（归档 44 条 / 2 299 289 B）但 `expand` 从未被调用（0/470） |
| 7 | 高上下文时的「精简作答」提示 | 无对应 | 触发未生效（会话身份守卫两次跳过；`savings_events` 0 行） |
| 8 | JSONL 裁剪与去重，默认 dry-run | 无对应 | 未触发（手工 CLI，dry-run 默认；54 格 0 引用） |
| 9 | 检查点捕获/恢复 | 无对应 | 生效（47 个检查点 / 22 会话；恢复侧注入 12+3+3 格） |
| 10 | 20/35/50/65/80 % 渐进检查点 | 无对应 | 部分（只出现 50 % 与 80 % 两档，且只在 t5） |
| 11 | 压缩指令注入 | 无对应 | 触发未生效（PreCompact 三条命令 status 0，宿主报无 response payload） |
| 12 | 活动模式 + 决策提取（≤10 条） | 无对应 | 触发未生效（47/47 检查点 `decisions` 为空） |

### 5.1 #1 Bash 输出压缩

optimizer 侧：`bash_coverage` 153 行（16 个会话），门分布 `error_or_short` 25、`not_read_only` 114、`under_10pct` 14（合计 153），**`compressed` 0 行**，`removed_tokens` 全为 0。`not_read_only` 的细分：`mixed_output` 70、`never-read-only` 23、`glued-operator-in-token` 12、`not-whitelisted` 6、`contains-newline-injection` 3。会话内 `updatedToolOutput` 计数为 0（54 格、三臂）。

命令形状统计说明了根因：116 次 Bash 调用中 92 次带 `;`/`|`/`&&`/重定向，17 次是脚本或 `cd`，**纯只读单命令只有 7 条**（5 条 `wc -l` ≤231 B、2 条 `cat secrets/canary.env` 407 B），全部落入 `error_or_short` 或 `under_10pct`。

探针对照（同一 fixture，直接调钩子、绕过对话）：每个探针会话稳定产出 4 条 `tier=measured, verified=1` 记录（`cat codec/replay.py` 20 495→627 token、`sed -n '1,200p'` 1 693→638、`grep -rn 'def ' .` 8 606→877、`sed -n '1,700p' build.log` 8 239→750）。大载荷另有 0.625 s 钩子预算上限：`cat assets/build.log`（468 877 B）与 `cat assets/inventory.csv`（366 756 B）都以 `reason=hook_budget` 放弃，体积扫描显示拐点在 262 KB 与 327 KB 之间。结论：**代码是活的，选中的门与预算把真实会话里的候选全数拒绝**。

tokless 侧：钩子 123 次调用（`PreToolUse:Bash` 78 次产出），22 次命令改写（`wc→rtk` 8、`cat→rtk` 7、`grep→rtk` 6、`ls→rkt` 1）。可见收益：

| 命令 | tokless 交付 | baseline 交付 | 说明 |
| --- | --- | --- | --- |
| `wc -l codec/*.py codec/client/src/*.ts` | 154 B | 231 B | 去掉路径前缀并附加合计行 |
| `grep -rn 'WARN' .` | 2 411 B | 22 250 B | 探针条件（-89 %），压缩检索结果 |
| `grep -rn ANCHOR codec/` | 159 B | 159 B | 原样透传 |
| `cat secrets/canary.env` | 407 B | 407 B | 原样透传（凭据串保留） |
| 469 KB / 367 KB 大输出 | ~2 KB 预览 | ~2 KB 预览 | 宿主落盘，与工具无关 |

凭据安全：三臂的工具结果里 fixture 假凭据均原样存在（t1 9/9 格）；tokless 对凭据文件不改写内容，optimizer 在本轮 54 格里没有替换过任何凭据相关输出。两个探针对照中均未观察到凭据被改写或外泄；出口脱敏由本地路由承担（7.2）。

### 5.2 #2 Delta 模式

optimizer 侧 `read-cache/decisions/*.jsonl` 共 11 条：3 条为重复读检测（`reason: redundant_read_2`，文件 `codec/eventstore.py`，`net_saved_tokens_est` 15 108，三次 t3 轮次各一条），其余 8 条为 `first_read`。3 条重复读记录全部 `eligible: false` / `actual_substitution: false`，`reason_code: partial_range_not_supported`——模型第二次读用了 `limit`/`offset` 的部分区间，该形状不被支持。**检测成立，替换从未发生。**

### 5.3 #3 / #4 Structure Map 与首次读取重定向

`structure_funnel.jsonl` 44 行：`mode=soft_block` 44、`hook_entered=true` 44、`output_emitted=false` 44、`event_written=false` 44。`exit_reason`：`first_read` 39、`nonblocking` 5；5 条 `nonblocking` 都是 `structure_eligible=false`（`partial_range_not_supported` 3、`unsupported_language` 2）。软拦截按设计不阻断，本轮也没有任何骨架注入。

`compression_events` 6 行全是 `first_read_skeleton`（`command_pattern=markdown`、`tier=opportunity`、`quality_preserved=1`、`verified=0`），detail `shadow size_bytes=62102` / `69864`，对应 19 325→372 与 21 804→384 token 的**影子测量**——即：骨架能力对 t5 的两个长文档算得出结果，但没有进入模型上下文。

tokless 侧没有骨架或重定向机制：`rtk read` 只做读取等价改写，不改内容（探针 67 501 B → 67 501 B）。

### 5.4 #5 搜索结果压缩

optimizer 有专用路径（`bash_compress.py:1598` 分类为 `search_results`、`:1909 _compress_search_results`、`:1945 render_search_results`、`:1974/:2003` 注册表、`bash_compress_hook.py:451` 归档特例）。`bash_coverage` 里只有 1 条 `search_results` 候选（243 token，`under_10pct/read_only`），被 ≥10 % 门拒绝。

tokless 的对应能力表现在改写后的 `rtk grep`：探针中 `grep -n WARN assets/build.log` 17 690→1 934 B、`grep -rn WARN .` 22 250→2 411 B、`grep -rn 'def ' .` 28 348→9 381 B，均 -89 % 以内。**这是 tokless 在整个基准里唯一稳定领先的能力面。**

### 5.5 #6 工具结果归档与 `expand`

44 个 `call_*.json`（2 299 289 B，Bash 19 / Read 25），键含 `archived_from, chars, original_chars, tokens_est, truncated, tool_use_id` 等；`truncated:false` 44/44，且每一条 `chars == original_chars`——即归档的是**宿主已经截断过的载荷**（Bash 类固定 30 008 字符，而非 468 877/366 756 B 的原始输出），不是模型产生的全量输出。分布：t1 2/2/2、t1b 2/2/2、t3 2/2/1、t4 1/1/1、t5 1/10/9、t2 0，另有 2 个未归属预热目录。

注入侧：`## Archived Tool Results` 只在 t5 的 3 格里出现（各 15–20 条链接）；`expand ` 这个提示串出现 92 次，但 470 次工具调用中**没有一次真的调用 `expand`**。归档写盘成立，回读路径未被使用。

### 5.6 #7 精简作答提示

`run_verbosity_steer` 每个 prompt 都跑（`userpromptsubmit_runner.py:701`），但会话身份守卫先比 cache 推导出的 `have_sid` 与当前 `want_sid`：`data/userpromptsubmit_diagnostics.log`（364 B）里恰好两条 `Skipping nudge: resolved session <A> does not match the live session <B>.`（A 是 t5 会话，B 是当轮在跑的 t1 会话）。`savings_events` 表 0 行；54 格流里 `spartan` / `ADHD` / `[Token Optimizer] Context` 出现 0 次。填充率条件（≥75 % 温和、≥90 % 强）与冷却（3 次/5 分钟）在这两个事件之后，未能有机会生效。判定：**触发未生效**，卡在会话身份守卫。

### 5.7 #8 JSONL 裁剪与去重

`jsonl_trim(arg, apply, threshold)`（`_measure/quality_archive.py:2302`）是手工 CLI，默认 dry-run，阈值按字符（默认 4000），另去重重复的 `system_reminder` 注入（:2469）。54 格流里 `jsonl-trim` 与 `measure.py` 出现 **0 次**。默认开启的自动路径不存在，判定「未触发（仅有手工等价物）」。

### 5.8 #9 / #10 / #12 检查点、渐进档与决策提取

47 个检查点 JSON，分布在 22 个会话目录（18 个正式格 + 4 个预热会话）。触发来源：`stop` 38、`auto` 5、`progressive-50` 2、`progressive-80` 1、`quality-80` 1；t1–t4 全是 `{stop: n}`；t5/r1 `{auto, progressive-80, quality-80, stop×2}`，t5/r2 与 t5/r3 `{progressive-50, auto×2, stop×2}`。**20 % / 35 % / 65 % 三档从未触发。** 20 个字段齐全，`continuation` 非空 45/47（最长 500 字符）。恢复侧：12 格注入 `Cross-session checkpoint`、3 格 `Post-compact recovery`、3 格 `Prior session hint`（t3/r3、t5/r2、t5/r3）。

`decisions` 在 47/47 检查点里为空数组；`activity_dating_v1_journal` 0 行；dashboard（663 440 B）里没有任何决策记录。**#12 的写入侧从未产出内容。**

### 5.9 #11 压缩指令注入

t5 每格 PreCompact 注册 3 条异步钩子，`debug.log` 显示三条都 `completed with status 0`：`measure.py compact-capture --trigger auto --quiet`、`read_cache.py --clear --quiet`、`measure.py dynamic-compact-instructions --quiet`；紧随其后宿主输出 `Hooks: async_hook_40630 (PreCompact:auto) produced no response payload — skipping attachment`。PostCompact 跑 `measure.py quality-cache --force --quiet`。PreCompact 次数：t1–t4 为 0；t5 optimizer r1=2、r2=3、r3=3。

流内 `When summarizing this session, pay special attention to:` / `COMPACTION GUIDANCE` / `# Token Optimizer additions:` 出现 0 次。判定：**钩子执行成功，但指令没有进入压缩上下文**——宿主把无 payload 的异步钩子输出丢弃了。

## 6 钩子实际动作

| 臂 | 钩子调用 | 字节 | 分布 |
| --- | --- | --- | --- |
| baseline | 0 | 0 | — |
| tokless | 123 | 20 140 | 只有 `PreToolUse:Bash` 78 次产出，命令改写 22 次 |
| optimizer | 284 | 48 376 | PostToolUse:Bash 116、PostToolUse:Read 42、PreToolUse:Read 44、Stop 18、SessionStart:startup 18、UserPromptSubmit 36、SessionStart:compact 7、PostToolUse:Edit 3 |

tokless 的钩子覆盖面窄（只拦 Bash，且只对白名单读命令），但改写在 7 次里真的改变了交付字节；optimizer 的钩子覆盖面宽（284 次），但**54 格里没有一次返回 `updatedToolOutput`**——所有机制都停在「观测/记录」层。

`--include-hook-events` 的盲区：它不把 PreCompact/PostCompact 写进 `stream.jsonl`，这两个事件的证据只能从 `debug.log` 取（t5 的压缩行为因此必须以 debug.log 为准）。

## 7 环境层（三臂同等受益或同等受影响）

### 7.1 宿主落盘层

claude 2.1.311 对超过 ~30 000 字符的 Bash/Read 结果自动落盘，只把约 2 KB 预览交给模型。

| 臂 | 命中格 | 落盘文件 | 磁盘全量字节 | 模型可见字节 | 占比 |
| --- | --- | --- | --- | --- | --- |
| baseline | 9 | 18 | 7 521 199 | 40 257 | 0.54 % |
| tokless | 9 | 18 | 7 521 183 | 40 239 | 0.54 % |
| optimizer | 9 | 17 | 7 154 674 | 38 042 | 0.53 % |

27 格命中（`build.log` 增量 `{54: 27}`）。Read 结果不落盘，因此逐字节一致（108 208 B）。这一层的效果（>99.4 % 削减）远大于两个被测工具在本 fixture 上的任何机制效果——报告里所有「大输出被压缩」的观感都应先归因到这一层。

### 7.2 出口脱敏层（本地路由）

319 次请求经出口脱敏：SECRET 243/4 857、HOSTNAME 282/282、USERNAME 292/462、API_KEY 232/863、PASSWORD 58/127，2 个 canary 形状的假名共 844 次使用；canary 真值进入台账 0 次。中位延迟 160 ms（最大 2 047 ms）。替换比中位 1.000、p95 1.000、最大 2.000（n=513，同尺寸替换）。

对判分的影响：`canary_quote`（最终答复引用的串是否等于磁盘真值）在本轮受这一层影响，t1 的 9/9 格工具结果里真值仍在，但答复侧不可比，故该轴与 `canary_preserved` 一起排除在 `task_pass` 之外。**凭据安全是「出口路径」的属性，不是被测工具的属性**；本报告不据任何一臂宣称凭据安全优势。

### 7.3 分类路由层

`group/smart-split` 把 513 次请求分发到 503 次 `deepseek-v4-1-flash` 与 10 次 `kimi-k3-1-pro`；HTTP 200×510、499×3；token 合计 in 4 547 775 / out 297 480 / cache_read 4 789 120 / cache_write 91 392。两格中途换过后端（t5/baseline/r2 13/5、t5/tokless/r3 11/5）。

**服务臂不是 Claude**，因此本报告的所有结论都应读作「在这套本地路由与模型下的测量」，不外推到 Claude 官方服务；跨臂比较仍然有效，因为三臂同路由、同模型、同采样参数。

## 8 威胁与限制

1. **完成度饱和**：18/18、18/18、17/18，无法用完成度区分工具质量；结论轴只有「模型可见内容是否真的被改变」。
2. **样本量与离群**：每臂 18 格，3 个离群格（t5/tokless/r1、t4/baseline/r3、t1/optimizer/r2）主导均值；4.3 节给了去掉离群的口径，两套数字都列出。
3. **命令形状主导**：模型每轮生成的命令形状直接决定机制能否触发（92/116 带粘合操作符）。这是被测工具的真实使用条件，但也意味着结论对任务提示措辞敏感。
4. **状态持久化带来的不可复现**：optimizer 的探针在 11:33 与 12:37 两次运行给出不同的压缩幅度（`cat codec/replay.py` 一次 417 B、一次 2 065 B），更早一次连 `wc -l`/`ls`/凭据文件都替换过。工具按会话落状态，**同一 fixture 在不同历史状态下行为不同**，单次探针结论不能外推。
5. **归档载荷被宿主截断**：#6 归档的是 30 008 字符的落盘载荷，评估「归档省了多少」时应以原始输出为分母另行计算，本报告不据此下结论。
6. **钩子事件盲区**：`--include-hook-events` 不产出 PreCompact/PostCompact，涉及压缩的第 9–11 项证据部分来自 `debug.log`。
7. **服务端非 Claude**：见 7.3。

## 9 复现

```bash
# 1 生成 fixture、构建 tokless 快照二进制、建三臂隔离 HOME（tokless 臂会真的安装一次）
bash benchmark/scripts/prepare.sh all

# 2 全量采样（6 任务 × 3 臂 × 3 轮 + 1 轮预热，交错轮换，断点续跑）
bash benchmark/scripts/run_all.sh

# 3 判分与聚合
python3 -I benchmark/scripts/score.py
python3 -I benchmark/scripts/summarize.py

# 4 机制侧证据
python3 -I benchmark/scripts/hooks.py            # 钩子调用与命令改写
python3 -I benchmark/scripts/compression.py      # 结果交付量
python3 -I benchmark/scripts/output_rewrite.py   # updatedToolOutput 是否生效
python3 -I benchmark/scripts/env_effects.py      # 宿主层 / 脱敏层 / 路由层
python3 -I benchmark/scripts/probe_m1.py --out /tmp/tokbench/findings/probe_m1.tsv
```

运行时产物全部在 `/tmp/tokbench/`（仓库路径含空格会拆散未加引号的 hook 命令，故不放在仓库内）。采样需要 `ANTHROPIC_BASE_URL` 与 `ANTHROPIC_AUTH_TOKEN` 存在（脚本只做存在性检查，不打印取值）。

## 附录 A 数据文件索引

| 内容 | 位置 |
| --- | --- |
| 逐格原始流与指标 | `/tmp/tokbench/runs/<task>/<arm>/r<N>/{stream.jsonl,metrics.tsv,score.tsv,debug.log,workspace.diff}` |
| 机制证据明细 | `benchmark/docs/mechanism-notes.md`（附录 A/B/C） |
| 钩子/压缩/改写/环境层聚合 | `/tmp/tokbench/findings/*.tsv` |
| optimizer 状态库 | `/tmp/tokbench/arms/optimizer/home/.claude/plugins/data/token-optimizer-inline/data/trends.db` |
| 检查点 | `/tmp/tokbench/arms/optimizer/home/.claude/token-optimizer/checkpoints/` |
| tokless 安装日志与接线 | `/tmp/tokbench/arms/tokless/{install.log,info.log}` |

真值、fixture 生成脚本与判分脚本都在仓库内（`benchmark/scripts/`），原始运行日志含认证配置项名称，不归档、不外传。
