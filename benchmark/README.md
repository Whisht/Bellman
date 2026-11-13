# tokless 与 token-optimizer 对比基准

在 iOS/macOS 上、同一本地路由与模型下，对 tokless（v1.0.13 快照）与 token-optimizer（v5.13.71）做默认安装的端到端对比：6 个任务 × 3 臂（baseline / tokless / optimizer）× 3 轮，共 54 格。

结论见 [results/report.md](results/report.md)，机制证据见 [docs/mechanism-notes.md](docs/mechanism-notes.md)。

## 快速开始

```bash
bash benchmark/scripts/prepare.sh all           # fixture + tokless 快照二进制 + 三臂隔离 HOME
bash benchmark/scripts/run_all.sh               # 54 格 + 每臂 1 轮预热，交错轮换、断点续跑
python3 -I benchmark/scripts/score.py           # 按 fixture 真值判分
python3 -I benchmark/scripts/summarize.py       # 聚合表
```

运行时产物全部在 `/tmp/tokbench/`，不进仓库。采样需要 `ANTHROPIC_BASE_URL` 与 `ANTHROPIC_AUTH_TOKEN`（只做存在性检查，不打印取值）。

## 目录

| 路径 | 内容 |
| --- | --- |
| `scripts/` | 准备、采样、判分与四个机制探针脚本 |
| `tasks/` | 6 个任务提示词与 fixture 设计说明 |
| `docs/` | 机制证据明细（含环境层附录） |
| `results/` | 结论报告 |

## 关键前提

- 三臂使用完全相同的绝对路径、模型、effort 与工具面；臂顺序按 (任务序号 + 轮次) 旋转。
- 判分只看任务真值；凭据相关的两条观测轴受本地路由出口脱敏影响，不计入通过判据。
- 服务端是本地路由 `group/smart-split`（非 Claude 官方后端），结论不外推。
