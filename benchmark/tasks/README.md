# 任务集

6 个任务，每个任务在 3 个臂（`baseline` / `tokless` / `optimizer`）上各跑 3 轮，共 54 格。任务文本在 `t*.txt`，判分逻辑在 `../scripts/score.py`。

## 工作区（fixture）

由 `../scripts/make_fixtures.py` 生成，写在 `/tmp/tokbench/fixture/workspace`，每次运行前完整复制一份到 `/tmp/tokbench/run/workspace`（运行结束后与 fixture 做 `diff -ru`，得到 `workspace.diff` 用于越界改动判定）。内容取自 `bellman/` 的真实文件，另加少量合成产物：

| 路径 | 体积 | 作用 |
| --- | --- | --- |
| `assets/build.log` | 469 kB / 12 000 行 | 超大只读输出，几乎必然触发宿主落盘层；含 `FINAL_SIG`、`TRACE-ANCHOR`、`WARN` 行 |
| `assets/inventory.csv` | 367 kB / 9 001 行 | 第二个超大输出；含 SKU `ZQ-0007341` 与 `drift` 行 |
| `codec/*.py`（4 个） | 25–68 kB | 中大型源码；`ledger.py` 61 个顶层 `def`、`ANCHOR:`；`eventstore.py` 含唯一的目标行 |
| `codec/client/src/*.ts`（3 个） | 20–40 kB | 按字节数计的第三个大输出；同时是 t5 的读取对象 |
| `corpus/note-01..40.md` | 1–3 kB 各 | 检索语料；`zephyrquorum` / `quorum_drift_ms` 密集出现 |
| `main.typ`、`bellman-equation-notes.md`、`*_副本.md` | 61–153 kB | t5 的长上下文来源（出自 `bellman/`） |
| `secrets/canary.env` | 408 B | 含一条**假**凭据（运行时随机生成，不提交、不入产物） |
| `bin/emit_*.sh` | ~250 B | 把产物文件 `cat` 出来，让模型走 Bash 而不是内置 Read |

## 任务与对应机制

| 任务 | 工具 | 强制窗口 | 目标机制 | 判分键 | 判分口径 |
| --- | --- | --- | --- | --- | --- |
| `t1` | Bash | — | #1 Bash 输出压缩 + 凭据安全 | `warn_count`、`final_sig`、`codec_py_lines` | 三个答案全部正确 |
| `t1b` | Bash | — | #1 的对照（同一组大输出命令，去掉凭据那一步） | 同 t1 | 同上；用于把「压缩是否吃掉细节」与「凭据引发的行为」分开测量 |
| `t2` | Bash | — | #5 搜索结果压缩 | `zephyrquorum_hits`、`quorum_drift_ms_hits`、`zq_top_file`、`zq_top_file_first_line` | 四个答案全部正确 |
| `t3` | Read, Edit | — | #2 Delta（重读已修改文件）、#3 结构图（大文件重读给骨架） | `condition`、`condition_line`、`ledger_defs`、`ledger_anchor` | 四个答案全部正确，**且** `workspace.diff` 恰好只有这一行的改动（`edit_exact`） |
| `t4` | Bash | — | #1 + #6 超大工具结果的处理 | `trace_anchor`、`sku_qty`、`drift_rows`、`ts_bytes_total` | 四个答案全部正确 |
| `t5` | Read | 100 000 | #7 精简提示、#10 渐进式检查点、#11 压缩指令 | `main_typ_import_lines`、`replay_anchor`、`eventstore_anchor`、`ts_files` | 四个答案全部正确 |

## 设计要点

1. **工具集是按机制选的，不是按方便选的。** 只给会走到被测路径的工具：`t1/t1b/t2/t4` 只给 Bash（内置 Read/Grep 不经 Bash 压缩）；`t3` 只给 Read+Edit（强制走 Read 路径，delta/结构图才有机会生效）；`t5` 只给 Read（长上下文本身是压力源）。三臂工具集完全相同。
2. **任务文本显式禁止截断。** 每条命令都要求读完整输出、不许 `head`/`tail`/`grep` 截断，否则模型可以用「只读一部分」绕开压缩机制，三臂随之趋同。
3. **`t1b` 是 `t1` 去掉凭据那一步的对照片。** `t1` 的凭据项在本地路由下无法充当判分依据（详见 `../docs/mechanism-notes.md` 的环境效应一节），因此凭据相关的观测改成两条独立轴（`canary_preserved` / `canary_quote`），不计入 `task_pass`；`t1b` 提供同一组大输出命令的干净对照。
4. **`t3` 同时考正确性与改动范围。** `edit_exact=yes` 要求新增的非空行恰好是目标行、删除的非空行恰好是原行；越界改动（例如顺带格式化）会被判为未通过。
5. **`t5` 的窗口压到 100 000。** 这是为了在不放大 fixture 的前提下让自动压缩真实发生；三臂使用同一个值，该值通过 `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 传入，其余任务显式清空该变量。

## 运行

```bash
bash ../scripts/prepare.sh     # 生成 fixture、三臂 HOME、tokless 与 token-optimizer 的安装面
bash ../scripts/run_all.sh     # 3 轮 × 6 任务 × 3 臂（先每臂跑 1 格预热并丢弃）
python3 -I ../scripts/score.py
python3 -I ../scripts/summarize.py
```
