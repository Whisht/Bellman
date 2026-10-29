# 强化学习笔记：贝尔曼方程的完整推导

> Some Derivations for Bellman-Equation from the naive probability. 一些从基本概率论出发的贝尔曼方程推导

从概率论基础与马尔可夫决策过程（MDP）的基本定义出发，系统推导强化学习中的两组核心方程：**贝尔曼期望方程**与**贝尔曼最优方程**。全文使用 [Typst](https://typst.app/) 排版，共 22 页。

📄 **成品 PDF**：[`bellman-notes.pdf`](./bellman-notes.pdf)　｜　📝 **源文件**：[`main.typ`](./main.typ)

## 内容概览

| 章节 | 主题                                                                             |
| ---- | -------------------------------------------------------------------------------- |
| 1    | 马尔可夫决策过程与基本记号（折扣回报 $G_t$、状态价值 $v_\pi$、动作价值 $q_\pi$） |
| 2    | 数学预备知识：概率性质 P1–P19 与三条核心引理                                     |
| 3    | 贝尔曼期望方程（条件期望形式）                                                   |
| 4    | 贝尔曼方程（显式展开形式）                                                       |
| 5    | 常见误区辨析：为何 $p(g \mid s) \neq p(g)$                                       |
| 6    | 贝尔曼最优方程：条件期望形式与显式展开形式                                       |
| 7    | 方程结构、计算复杂度与算法选型建议                                               |

笔记覆盖状态价值与动作价值之间的四类递推关系（$v \to v$、$q \to v$、$v \to q$、$q \to q$），每一步推导都标注所依据的性质或引理，并区分两种等价的写法：

- **条件期望形式**：结构紧凑，便于推导时序差分（TD）等采样算法。
- **显式展开形式**：直接使用环境模型 $p(s', r \mid s, a)$ 与策略 $\pi(a \mid s)$ 求和，对应动态规划。

## 编译

需要 [Typst](https://github.com/typst/typst) 0.15 或更新版本：

```bash
typst compile main.typ bellman-notes.pdf

# 边改边预览
typst watch main.typ bellman-notes.pdf
```

仓库中的 `typst` 是 macOS 可执行文件，也可以直接用 `./typst compile main.typ bellman-notes.pdf`。

### 字体

排版使用下列字体，缺失时 Typst 会回退到系统字体，版式可能略有不同：

- 西文与公式：New Computer Modern（Typst 自带）
- 中文正文：思源宋体 Source Han Serif SC（回退到 Songti SC）
- 标题：思源黑体 Source Han Sans SC（回退到 PingFang SC）

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `main.typ` | 笔记源文件，样式定义在文件开头 |
| `bellman-notes.pdf` | 编译产物 |
