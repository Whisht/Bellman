// ============================================================
//  强化学习笔记：贝尔曼期望方程与贝尔曼最优方程的完整推导
// ============================================================
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/mannot:0.3.0": markhl

// ---------- 配色与字体 ----------
#let accent = rgb("#1f4e79")
#let accent-soft = accent.lighten(92%)
#let accent-mid = accent.lighten(75%)
#let muted = luma(110)

// 公式局部高亮配色
#let hl-amber-fill = rgb("#fff4d6")
#let hl-amber-stroke = rgb("#a05d14")
#let hl-blue-fill = rgb("#e6f0fa")
#let hl-blue-stroke = rgb("#2b6cb0")
#let hl-green-fill = rgb("#e6f6ec")
#let hl-green-stroke = rgb("#2b7952")
#let warn-soft = rgb("#fff4e5")
#let warn-stroke = rgb("#b25000")

#let serif-font = (
  (name: "New Computer Modern", covers: "latin-in-cjk"),
  "Source Han Serif SC",
  "Noto Serif CJK SC",
  "Songti SC",
)
#let sans-font = (
  (name: "Helvetica Neue", covers: "latin-in-cjk"),
  (name: "Liberation Sans", covers: "latin-in-cjk"),
  "Source Han Sans SC",
  "Noto Sans CJK SC",
  "PingFang SC",
)
#let mono-font = ("Menlo", "DejaVu Sans Mono", "Source Han Sans SC", "Noto Sans CJK SC", "PingFang SC")

#let doc-title = "强化学习笔记"
#let doc-subtitle = "贝尔曼期望方程与贝尔曼最优方程的完整推导"

// ---------- 页面 ----------
#set page(
  paper: "a4",
  margin: (x: 2.3cm, top: 2.8cm, bottom: 2.6cm),
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 9pt, fill: muted, font: sans-font)
      grid(
        columns: (1fr, auto),
        doc-title + " · " + doc-subtitle,
        {
          let hs = query(selector(heading.where(level: 1)).before(here()))
          if hs.len() > 0 { hs.last().body }
        },
      )
      v(-0.4em)
      line(length: 100%, stroke: 0.4pt + luma(200))
    }
  },
  footer: context {
    set text(size: 9pt, fill: muted, font: sans-font)
    align(center)[
      #counter(page).display() / #counter(page).final().first()
    ]
  },
)

// ---------- 正文 ----------
#set text(lang: "zh", font: serif-font, size: 10.5pt, weight: "regular")
#set par(justify: true, leading: 0.85em, spacing: 1em, first-line-indent: (amount: 2em, all: false))
#set strong(delta: 200)
#show strong: set text(fill: accent.darken(15%))
#show emph: set text(font: ((name: "New Computer Modern", covers: "latin-in-cjk"), "Kaiti SC", "Noto Serif CJK SC"))
#show link: set text(fill: accent)
#show ref: set text(fill: accent)
#show outline: it => {
  show link: set text(fill: luma(30))
  it
}

// 列表
#set list(marker: ([•], [‣], [–]), indent: 0.6em, body-indent: 0.6em, spacing: 0.9em)
#set enum(indent: 0.6em, body-indent: 0.6em, spacing: 0.9em)
#show list: set par(first-line-indent: 0pt)
#show enum: set par(first-line-indent: 0pt)

// ---------- 公式编号与高亮宏 ----------
#set math.equation(
  numbering: n => {
    let h1 = counter(heading).get().first()
    if h1 > 0 {
      numbering("(1.1)", h1, n)
    } else {
      numbering("(1)", n)
    }
  },
  supplement: [式],
)
#show math.equation.where(block: true): set block(above: 1.05em, below: 1.05em)
#show math.equation: set text(font: (
  "New Computer Modern Math",
  "Source Han Serif SC",
  "Noto Serif CJK SC",
  "Songti SC",
))

// 推导中重点结论的外框（内部抑制嵌套公式重复编号）
#let eqbox(body) = {
  set math.equation(numbering: none)
  box(
    stroke: 0.9pt + accent,
    fill: accent-soft,
    inset: (x: 10pt, y: 7pt),
    radius: 3pt,
    body,
  )
}

// 公式内部重点项高亮宏（基于 mannot.markhl，按公式真实包围盒绘制）：
// 琥珀色（策略算子/核心变换）、浅蓝色（条件加细/马尔可夫化简）、浅绿色（后继价值递推项）
#let _unwrap(body) = if type(body) == content and body.func() == math.equation { body.body } else { body }
#let _mk(fill, stroke) = body => {
  let b = _unwrap(body)
  {
    markhl(b, color: stroke, fill: fill, stroke: 0.5pt + stroke, radius: 2pt, outset: (x: 0.12em, y: 0.22em))
  }
}
#let mhl = _mk(hl-amber-fill, hl-amber-stroke)
#let mhlb = _mk(hl-blue-fill, hl-blue-stroke)
#let mhlg = _mk(hl-green-fill, hl-green-stroke)

// ---------- 标题 ----------
#set heading(numbering: (..n) => if n.pos().len() <= 2 { numbering("1.1", ..n) })
#show heading: set text(font: sans-font, fill: accent.darken(25%), weight: "bold")
#show heading: set par(first-line-indent: 0pt, justify: false)

#show heading.where(level: 1): it => {
  counter(math.equation).update(0)
  set text(size: 16pt)
  v(1.6em, weak: true)
  block(width: 100%, below: 1em, sticky: true)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 0.6em,
      align: horizon,
      if it.numbering != none {
        box(fill: accent, inset: (x: 7pt, y: 4pt), radius: 3pt)[
          #set text(fill: white, size: 14pt)
          #counter(heading).display(it.numbering)
        ]
      },
      it.body,
    )
    #v(-0.3em)
    #line(length: 100%, stroke: 1.2pt + accent)
  ]
}
#show heading.where(level: 2): it => {
  set text(size: 13pt)
  block(above: 1.5em, below: 0.85em, sticky: true)[
    #if it.numbering != none {
      text(fill: accent)[#counter(heading).display(it.numbering)]
      h(0.6em)
    }
    #it.body
  ]
}
#show heading.where(level: 3): it => {
  set text(size: 11.5pt)
  block(above: 1.3em, below: 0.75em, sticky: true)[
    #box(width: 3pt, height: 0.9em, fill: accent, baseline: 0.1em)
    #h(0.4em)
    #it.body
  ]
}

// ---------- 图表与题注 ----------
#set table(
  align: (x, y) => if y == 0 or x == 0 { center + horizon } else { left + horizon },
  inset: (x: 8.5pt, y: 6.5pt),
  stroke: (x, y) => (
    top: if y == 0 { 1.2pt + accent } else if y == 1 { 0.6pt + accent } else { none },
    bottom: 0.4pt + luma(210),
  ),
  fill: (_, y) => if y == 0 { accent-soft } else if calc.even(y) { luma(250) },
)
#show table.cell.where(y: 0): strong
#show table.cell.where(x: 0): set text(weight: "medium")
#show table.cell: set par(justify: false, first-line-indent: 0pt)
#show table.cell: set text(size: 9.2pt)

#show figure: set math.equation(numbering: none)
#show figure: set block(above: 1.2em, below: 1.2em)
#show figure.where(kind: table): set block(breakable: false)
#show figure.where(kind: table): it => {
  show math.equation.where(block: true): set block(above: 0.35em, below: 0.35em)
  show math.equation.where(block: true): set align(left)
  it
}
#show figure.where(kind: table): set figure(supplement: [表])
#show figure.where(kind: table): set figure.caption(position: top)
#show figure.where(kind: image): set figure(supplement: [图])
#show figure.caption: it => {
  set text(font: sans-font, size: 9pt, fill: accent.darken(15%))
  set par(first-line-indent: 0pt, justify: false)
  block(above: 0.5em, below: 0.5em)[
    #strong[#it.supplement #context it.counter.display(it.numbering)]
    #h(0.5em)
    #it.body
  ]
}

// ---------- 分隔线 ----------
#let divider() = {
  v(0.25em)
  line(length: 100%, stroke: (paint: luma(190), thickness: 0.5pt, dash: "dotted"))
  v(0.25em)
}

// ============================================================
//  封面标题与目录
// ============================================================
#align(center)[
  #v(1.2em)
  #text(font: sans-font, size: 26pt, weight: "bold", fill: accent.darken(25%))[#doc-title]
  #v(0.2em)
  #text(font: sans-font, size: 15pt, fill: accent)[#doc-subtitle]
  #v(0.6em)
  #text(size: 9.5pt, fill: muted, font: sans-font)[Bellman Expectation & Optimality Equations]
  #v(0.5em)
  #line(length: 35%, stroke: 1.5pt + accent)
]
#v(0.5em)

#figure(
  diagram(
    spacing: (38mm, 24mm),
    node-stroke: 0.9pt + accent,
    edge-stroke: 0.8pt + accent,
    node-inset: 7pt,
    node((0, 0), [$v_pi (s)$], shape: circle, fill: accent-soft),
    node((0, 1), [$q_pi (s, a)$], shape: circle, fill: accent-soft),
    node((2, 0), [$v_* (s)$], shape: circle, fill: rgb("#fdf1dc"), stroke: 0.9pt + rgb("#b7791f")),
    node((2, 1), [$q_* (s, a)$], shape: circle, fill: rgb("#fdf1dc"), stroke: 0.9pt + rgb("#b7791f")),
    // 贝尔曼期望方程
    edge((0, 0), (0, 1), "->", bend: 28deg, label-side: center, label: text(size: 7.5pt)[$v_pi -> q_pi$ \ @eq-bellman-exp-vq]),
    edge((0, 1), (0, 0), "->", bend: 28deg, label-side: center, label: text(size: 7.5pt)[$q_pi -> v_pi$ \ @eq-bellman-exp-qv]),
    edge((0, 0), (0, 0), "->", bend: 125deg, loop-angle: 180deg, label-side: center, label: text(size: 7.5pt)[$v_pi -> v_pi$ \ @eq-bellman-exp-vv]),
    edge((0, 1), (0, 1), "->", bend: 125deg, loop-angle: 180deg, label-side: center, label: text(size: 7.5pt)[$q_pi -> q_pi$ \ @eq-bellman-exp-qq]),
    // 贝尔曼最优方程
    edge((2, 0), (2, 1), "->", bend: 28deg, stroke: 0.8pt + rgb("#b7791f"), label-side: center, label: text(size: 7.5pt)[$v_* -> q_*$ \ @eq-opt-cond-vq]),
    edge((2, 1), (2, 0), "->", bend: 28deg, stroke: 0.8pt + rgb("#b7791f"), label-side: center, label: text(size: 7.5pt)[$q_* -> v_*$ \ @eq-opt-cond-qv]),
    edge((2, 0), (2, 0), "->", bend: 125deg, loop-angle: 0deg, stroke: 0.8pt + rgb("#b7791f"), label-side: center, label: text(size: 7.5pt)[$v_* -> v_*$ \ @eq-opt-cond-vv]),
    edge((2, 1), (2, 1), "->", bend: 125deg, loop-angle: 0deg, stroke: 0.8pt + rgb("#b7791f"), label-side: center, label: text(size: 7.5pt)[$q_* -> q_*$ \ @eq-opt-cond-qq]),
    // 期望 -> 最优
    edge((0, 0), (2, 0), "<->", stroke: (dash: "dashed", paint: muted, thickness: 0.8pt), label-side: center, label: text(size: 7.5pt)[$sum_a pi(a divides s) arrow.l.r max_a$]),
    edge((0, 1), (2, 1), "<->", stroke: (dash: "dashed", paint: muted, thickness: 0.8pt), label-side: center, label: text(size: 7.5pt)[$sum_(a') pi(a' divides s') arrow.l.r max_(a')$]),
    node(enclose: ((0, 0), (0, 1)), stroke: (dash: "dotted", paint: accent), inset: 38pt, corner-radius: 6pt, snap: -1),
    node((0, -0.62), text(size: 9pt, fill: accent)[*贝尔曼期望方程*（4 个）], stroke: none),
    node(enclose: ((2, 0), (2, 1)), stroke: (dash: "dotted", paint: rgb("#b7791f")), inset: 38pt, corner-radius: 6pt, snap: -1),
    node((2, -0.62), text(size: 9pt, fill: rgb("#b7791f"))[*贝尔曼最优方程*（4 个）], stroke: none),
  ),
  caption: [8 个方程的转换关系总览：左侧为 4 个贝尔曼期望方程，右侧为 4 个贝尔曼最优方程；每条边标注推导方向与公式编号，虚线表示由策略加权 $sum_a pi$ 替换为贪心 $max_a$ 的对应关系],
) <fig-eight-equations>

#v(0.5em)

#show outline.entry.where(level: 1): it => {
  v(0.5em, weak: true)
  set text(font: sans-font, weight: "bold")
  it
}
#pagebreak()

#text(font: sans-font, size: 16pt, weight: "bold", fill: accent.darken(25%))[目录]
#v(0.3em)
#outline(title: none, depth: 2, indent: 1.5em)

#pagebreak()

// ============================================================
//  导言
// ============================================================
本文档从概率论公理体系与有限马尔可夫决策过程（MDP）的基本定义出发，系统、严密地推导强化学习中的核心方程体系——#strong[贝尔曼期望方程]（Bellman Expectation Equation）与#strong[贝尔曼最优方程]（Bellman Optimality Equation）。

在强化学习经典文献（如 Sutton & Barto《强化学习：导论》）中，贝尔曼方程通常以两种等价的数学形式出现：一是以条件期望表征的#strong[紧凑形式]（基于全期望公式与塔性质），二是以状态转移概率与策略分布显式求和表征的#strong[展开形式]（基于全概率公式与链式法则）。本笔记严格区分并打通这两条推导路径，按“先单步桥接（$v arrow.r q$、$q arrow.r v$）、后复合自递推（$v arrow.r v$、$q arrow.r q$）”的统一逻辑组织方程推导（#link(<sec-mdp>)[第 1]--#link(<sec-bellman-opt>)[5 章]），核心对照见 @tab-overview；进而从#strong[期望值与不动点估计理论]出发，系统阐述基于压缩映射不动点迭代的动态规划（含值迭代）、基于大数定律的蒙特卡洛估计以及基于 Robbins-Monro 随机近似理论的时序差分（TD）估计方法，给出状态价值与动作价值估计算法结合贝尔曼期望/最优方程导出强化学习算法体系的关联谱系（#link(<sec-value-estimation>)[第 6 章]）；最后阐述不以贝尔曼不动点方程为直接求解对象的#strong[策略梯度范式]——将策略显式参数化并直接对期望回报性能目标求导，同时厘清贝尔曼方程在该范式中作为优势函数定义、Critic 辅助价值估计以及软贝尔曼不动点特例的理论边界（#link(<sec-policy-gradient>)[第 7]--#link(<sec-algo-selection>)[8 章]）。

为突出公式中的核心结构，全文采用三色标记高亮关键数学项：$mhl(pi(a divides s) \/ max_a)$（琥珀色）标记#strong[策略层算子或核心变换]，$mhlb(S_(t+1) \/ p(g divides s'))$（浅蓝色）标记#strong[新引入的条件变量或马尔可夫条件独立化简项]，$mhlg(v_pi (S_(t+1)) \/ q_star (s', a'))$（浅绿色）标记#strong[后继时刻的价值递推项]。

#figure(
  caption: [贝尔曼期望方程与贝尔曼最优方程的总体对照（以状态价值自递推 $v arrow.r v$ 为例）],
  table(
    columns: (auto, auto, 1fr),
    table.header([方程类别与性质], [形式], [$v arrow.r v$ 方程]),
    table.hline(),
    table.cell(rowspan: 2)[#strong[贝尔曼期望方程] \ 任意固定策略 $pi$ \ 价值函数的#strong[线性]方程组],
    [条件期望形式],
    [$ v_pi (s) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $],
    [显式展开形式],
    [$ v_pi (s) = sum_a #mhl($pi(a divides s)$) [sum_r p(r divides s, a) r + gamma sum_(s') p(s' divides s, a) #mhlg($v_pi (s')$)] $],
    table.cell(rowspan: 2)[#strong[贝尔曼最优方程] \ 最优策略 $pi_star$ \ 价值函数的#strong[非线性]方程组],
    [条件期望形式],
    [$ v_star (s) = #mhl($max_a$) bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [显式展开形式],
    [$ v_star (s) = #mhl($max_a$) [sum_r p(r divides s, a) r + gamma sum_(s') p(s' divides s, a) #mhlg($v_star (s')$)] $],
  ),
) <tab-overview>

#divider()

// ============================================================
//  第 1 章：马尔可夫决策过程与基本记号
// ============================================================
= 马尔可夫决策过程与基本记号
<sec-mdp>

== 有限马尔可夫决策过程
<sec-finite-mdp>
强化学习将智能体（Agent）与环境（Environment）的序列交互建模为#strong[有限马尔可夫决策过程]（Finite Markov Decision Process, Finite MDP），由五元组 $(cal(S), cal(A), cal(R), p, gamma)$ 组成。全文使用的基本记号见 @tab-mdp-notation，智能体与环境的闭环交互及时间步展开结构见 @fig-mdp-loop。

#figure(
  caption: [有限马尔可夫决策过程（MDP）的基本记号约定],
  table(
    columns: 2,
    table.header([记号], [含义]),
    table.hline(),
    [$cal(S), cal(A), cal(R)$],
    [分别为有限的#strong[状态集合]、#strong[动作集合]与#strong[奖励集合]。下文常记当前状态为 $s in cal(S)$，下一时刻状态为 $s' in cal(S)$，动作为 $a in cal(A)$，即时奖励为 $r in cal(R)$。],
    [$S_t, A_t, R_(t + 1)$],
    [离散时间步 $t in {0, 1, 2, dots.h}$ 对应的状态、动作与奖励#strong[随机变量]；小写字母 $s, a, r$ 表示其对应的#strong[具体取值]。],
    [$p(s', r divides s, a)$],
    [#strong[环境模型]（状态转移与奖励的联合条件概率）：$Pr(S_(t + 1) = s', R_(t + 1) = r divides S_t = s, A_t = a)$，表示在状态 $s$ 执行动作 $a$ 后，转移到状态 $s'$ 并获得奖励 $r$ 的概率。本文假设环境是#strong[平稳的]（Stationary），即该分布不随时间步 $t$ 变化。],
    [$p(s' divides s, a)$, $p(r divides s, a)$],
    [#strong[状态转移概率]与#strong[奖励概率]：$p(s' divides s, a) eq.dot sum_(r in cal(R)) p(s', r divides s, a)$，$p(r divides s, a) eq.dot sum_(s' in cal(S)) p(s', r divides s, a)$，即联合概率 $p(s', r divides s, a)$ 分别对奖励 $r$、下一状态 $s'$ 求和所得的边缘概率（以括号内的变量区分）。],
    [$pi(a divides s)$],
    [#strong[策略]（Policy）：$pi(a divides s) eq.dot Pr(A_t = a divides S_t = s)$，表示智能体在状态 $s$ 下选择动作 $a$ 的概率，满足 $sum_(a in cal(A)) pi(a divides s) = 1$。本文默认讨论不随时间步 $t$ 变化的#strong[平稳策略]。],
    [$gamma in [0, 1]$],
    [#strong[折扣因子]（Discount Factor），用于权衡即时奖励与未来远期奖励的相对重要程度。],
    [$G_t$],
    [从时刻 $t$ 起算的#strong[折扣回报]（Return，即累积折扣奖励）；其可能取值的集合记为 $Gamma$，具体取值记为 $g in Gamma$。],
    [$v_pi (s), q_pi (s, a)$],
    [策略 $pi$ 下的#strong[状态价值函数]（State-Value Function）与#strong[动作价值函数]（Action-Value Function）。],
  ),
) <tab-mdp-notation>

#figure(
  diagram(
    spacing: (22mm, 11mm),
    node-stroke: 0.9pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0, 0), [*智能体 (Agent)* \ 策略 $pi(a divides s)$], fill: accent-soft, corner-radius: 4pt, inset: 7pt, width: 38mm),
    node((2, 0), [*环境 (Environment)* \ 模型 $p(s', r divides s, a)$], fill: accent-soft, corner-radius: 4pt, inset: 7pt, width: 42mm),
    edge((0, 0), (2, 0), "->", [执行动作 $A_t = a$], bend: 20deg, label-side: center),
    edge((2, 0), (0, 0), "->", [状态转移 $S_(t+1) = s'$，即时奖励 $R_(t+1) = r$], bend: 20deg, label-side: center),
    node((0, 1.2), [$S_t$], radius: 11pt, fill: white),
    edge((0, 1.2), (0.65, 1.2), "->", [$pi$], label-side: left),
    node((0.65, 1.2), text(fill: white)[$A_t$], radius: 11pt, fill: accent),
    edge((0.65, 1.2), (1.35, 1.2), "->", [$p, R_(t+1)$], label-side: left),
    node((1.35, 1.2), [$S_(t+1)$], radius: 11pt, fill: white),
    edge((1.35, 1.2), (2.0, 1.2), "->", [$pi$], label-side: left),
    node((2.0, 1.2), text(fill: white)[$A_(t+1)$], radius: 11pt, fill: accent),
    edge((2.0, 1.2), (2.55, 1.2), "-->", [$R_(t+2), dots.h$], label-side: left),
  ),
  caption: [有限 MDP 的智能体-环境闭环交互与马尔可夫决策轨迹展开],
) <fig-mdp-loop>

#strong[记号约定]：期望算子的下标标明该期望#strong[实际求平均的随机变量]（即方括号内出现、且未被条件固定的随机变量），如 $bb(E)_(A_t) [q_pi (s, A_t) divides S_t = s]$ 对动作 $A_t tilde.op pi(dot.op divides s)$ 求平均，$bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s, A_t = a]$ 对环境一步转移 $(R_(t + 1), S_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 求平均；这些随机变量的分布均由智能体所遵循的策略 $pi$ 与环境模型 $p$ 共同决定。全文所有条件概率均在该前提下书写（在不引起歧义时，常将 $Pr_pi (X = x divides Y = y)$ 简记为 $p(x divides y)$）。

#strong[随机变量与具体取值的区分]：严谨推导贝尔曼方程的关键在于区分#strong[随机变量]（大写字母，如 $S_t, A_t, R_(t + 1), G_t$）与#strong[具体取值]（小写字母，如 $s, a, r, g$）。由于回报 $G_t$ 是未来奖励序列的线性组合，它本身也是一个随机变量。对于任意离散型随机变量 $X$ 与条件 ${Y = y}$，其条件期望均可写为显式求和：

$ bb(E) [X divides Y = y] = sum_x x thin #mhlb($p(x divides y)$) . $ <eq-cond-exp-basic>

#link(<sec-bellman-exp-explicit>)[第 4 章]中所有展开形式的底层推导，本质上都是利用全概率公式与乘法法则，将 @eq-cond-exp-basic 中的条件概率 $p(x divides y)$ 分解为策略 $pi(a divides s)$ 与环境转移概率 $p(s', r divides s, a)$ 的乘积组合。

#divider()

== 折扣回报 $G_t$ 的定义与一步递推性质
<sec-return>
#strong[定义 1.1（折扣回报）] <def-1.1> 设交互终止时刻为 $T$。从时刻 $t$ 开始的折扣回报定义为：

$
  G_t eq.dot sum_(k = t + 1)^T gamma^(k - t - 1) R_k = #mhl($R_(t + 1)$) + #mhlg($gamma R_(t + 2) + gamma^2 R_(t + 3) + dots.h.c$)
$ <eq-return-def>

#strong[收敛性条件]：在有限步的#strong[分幕式任务]（Episodic Tasks，$T < oo$）中，可取 $gamma = 1$；在无限步的#strong[持续性任务]（Continuing Tasks，$T = oo$）中，要求 $gamma in [0, 1)$（二者不能同时取 $T = oo$ 且 $gamma = 1$，否则无穷级数可能发散）。在有限 MDP 中，奖励集合 $cal(R)$ 有限，必存在上界 $R_max < oo$ 使得 $|R_k| lt.eq R_max$。当 $gamma in [0, 1)$ 时，由等比级数求和公式可得：

$
  |G_t| lt.eq sum_(k = 0)^oo gamma^k |R_(t + k + 1)| lt.eq sum_(k = 0)^oo gamma^k R_max = #mhl($frac(R_max, 1 - gamma)$) < oo .
$ <eq-return-bound>

@eq-return-bound 的级数绝对收敛保证了回报 $G_t$ 的期望存在且有限，同时保证了期望算子与无穷级数求和可以合法交换顺序（详见#link(<sec-series-convergence>)[第 2.3 节]性质 P13）。

#strong[命题 1.1（回报的一步递推关系）] <prop-1.1> 对任意时刻 $t$，相邻两个时刻的回报满足如下递推恒等式：

$ #eqbox([$ G_t = #mhl($R_(t + 1)$) + gamma thin #mhlg($G_(t + 1)$) $]) $ <eq-return-recursion>

#strong[证明]：将 @eq-return-def 中 $G_t$ 的定义式分离出首项 $R_(t + 1)$，并对后续项提取公因式 $gamma$：

$
  G_t & = R_(t + 1) + gamma R_(t + 2) + gamma^2 R_(t + 3) + gamma^3 R_(t + 4) + dots.h.c \
      & = R_(t + 1) + gamma #mhlb($(R_(t + 2) + gamma R_(t + 3) + gamma^2 R_(t + 4) + dots.h.c)$) \
      & = R_(t + 1) + gamma #mhlg($G_(t + 1)$) . #h(2em) square.filled.medium
$

#strong[说明]：$G_t$ 与 $G_(t + 1)$ 共享从 $R_(t + 2)$ 开始的全部后续奖励项。@eq-return-recursion 是推导所有贝尔曼方程的共同起点。

#divider()

== 状态价值函数与动作价值函数
<sec-value-functions>
#strong[定义 1.2（状态价值函数）] <def-1.2> 智能体从状态 $s in cal(S)$ 出发，此后遵循策略 $pi$ 所获得的期望回报，称为状态价值函数：

$ v_pi (s) eq.dot bb(E)_(G_t) [#mhlg($G_t$) divides #mhlb($S_t = s$)] . $ <eq-v-def>

#strong[定义 1.3（动作价值函数）] <def-1.3> 智能体在状态 $s in cal(S)$ 下执行动作 $a in cal(A)$，此后遵循策略 $pi$ 所获得的期望回报，称为动作价值函数：

$ q_pi (s, a) eq.dot bb(E)_(G_t) [#mhlg($G_t$) divides #mhlb($S_t = s, thin A_t = a$)] . $ <eq-q-def>

#strong[说明]：由于环境模型与策略均是平稳的（不随时间 $t$ 变化），@eq-v-def 与 @eq-q-def 的值仅取决于状态 $s$（及动作 $a$），与具体时刻 $t$ 无关。两者的区别仅在于#strong[当前时刻动作 $A_t$ 的随机性是否给定]：$v_pi (s)$ 中第一步动作 $A_t$ 仍需按策略 $pi(dot.op divides s)$ 采样，而 $q_pi (s, a)$ 已将第一步动作固定为 $a$。

#divider()

// ============================================================
//  第 2 章：数学预备知识：概率公理与 MDP 核心引理
// ============================================================
= 数学预备知识：概率公理与 MDP 核心引理
<sec-math-prelim>
为使后续推导做到每一步有据可依，本章汇总所需的概率论与期望基本性质（编号为 P1--P14），并在对应小节直接给出在 MDP 价值递推中反复调用的三条核心引理（#link(<lem-1>)[引理 1]--#link(<lem-3>)[引理 3]）。在有限 MDP 下，状态、动作与奖励集合均为有限集，因此所有单步求和均为有限和。

== 离散概率分布与条件全概率公式（性质 P1--P5）
<sec-prob-axioms>
设 $X, Y, Z$ 为离散型随机变量，其具体取值分别记为 $x, y, z$，简记 $Pr(X = x)$ 为 $p(x)$。

- #strong[P1（联合分布与边缘分布）]：随机变量 $(X, Y)$ 的联合分布 $p(x, y)$ 满足归一性 $sum_x sum_y p(x, y) = 1$。对联合分布关于其中一个变量求和，即可消去该变量，得到另一变量的#strong[边缘分布]（Marginal Distribution）：
  $ p(x) = sum_y p(x, y), #h(2em) p(y) = sum_x p(x, y) . $ <eq-p1-marginal>
  对多元联合分布 $p(x, y, z)$，同样可通过对部分变量求和消去对应变量；反之，在推导中常需要将边缘分布#strong[逆向还原]为更高维的联合分布之和（如将 $p(x, z)$ 展开为 $sum_y #mhlb($p(x, y, z)$)$），从而引入辅助中间变量 $Y$。

- #strong[P2（条件概率）]：当 $p(y) > 0$ 时，给定 ${Y = y}$ 下 $X$ 的条件概率定义为：
  $ p(x divides y) eq.dot frac(p(x, y), p(y)) . $ <eq-p2-cond>
  由 P1 易知条件分布同样满足归一性：$sum_x p(x divides y) = frac(sum_x p(x, y), p(y)) = frac(p(y), p(y)) = 1$。

- #strong[P3（乘法法则）]：当 $p(y) > 0$（或 $p(x) > 0$）时，将 @eq-p2-cond 两边同乘分母可得：
  $ p(x, y) = #mhl($p(x divides y) thin p(y)$) = p(y divides x) thin p(x) . $ <eq-p3-mult>

- #strong[P4（链式法则及其条件形式）]：将多个变量的联合概率逐层分解为条件概率的乘积：
  + #strong[无条件链式法则]：当 $p(y, z) > 0$ 时，连续两次应用乘法法则（P3）可得：
    $ p(x, y, z) = p(x, (y, z)) = p(x divides y, z) thin p(y, z) = #mhl($p(x divides y, z) thin p(y divides z) thin p(z)$) . $ <eq-p4-chain>
  + #strong[带公共条件的链式法则（条件链式法则）]：当所有项均带有公共条件 ${Z = z}$（满足 $p(y, z) > 0$）时，由 P2 与 @eq-p4-chain 可得：
    $
      p(x, y divides z) eq.dot frac(p(x, y, z), p(z)) = frac(p(x divides y, z) thin p(y divides z) thin p(z), p(z)) = #mhl($p(x divides y, z) thin p(y divides z)$) .
    $ <eq-p4-cond-chain>
  + #strong[多变量条件链式法则]：对公共条件 ${Z = z}$ 下的三个变量 $(X, Y, W)$，将 $(Y, W)$ 视为整体连续应用两次 @eq-p4-cond-chain，可得：
    $
      p(x, y, w divides z) = p(x divides y, w, z) thin p(y, w divides z) = #mhl($p(x divides y, w, z) thin p(y divides w, z) thin p(w divides z)$) .
    $ <eq-p4-multi-chain>

- #strong[P5（全概率公式及其条件推广）]：结合边缘分布性质（P1）与链式法则（P4），可将目标概率分解为完备中间变量各取值下的条件概率加权和：
  + #strong[基本形式（无附加条件）]：对 P1 的边缘分布展开式应用 P3，有：
    $ p(x) = sum_y p(x, y) = sum_y #mhl($p(y) thin p(x divides y)$) . $ <eq-p5-basic>
  + #strong[推广一：条件全概率公式（带公共条件 $Z = z$）]：当给定公共条件 ${Z = z}$（满足 $p(z) > 0$）时，引入中间变量 $Y$，由 P1、P2 与 @eq-p4-cond-chain 可得：
    $
      p(x divides z) = frac(sum_y p(x, y, z), p(z)) = sum_y p(x, y divides z) = sum_y #mhlb($p(y divides z) thin p(x divides y, z)$) .
    $ <eq-p5-cond>
  + #strong[推广二：多变量条件全概率公式（多层链式展开）]：当在公共条件 ${Z = z}$ 下同时引入两个中间变量 $(Y, W)$ 时，先后对 $Y$ 和 $W$ 连续应用两次 @eq-p5-cond，可得：
    $
      p(x divides z) = sum_y sum_w p(x, y, w divides z) = sum_y #mhl($p(y divides z)$) sum_w #mhlb($p(w divides y, z) thin p(x divides y, w, z)$) .
    $ <eq-p5-multi>

#divider()

== 条件期望与全期望公式（性质 P6--P11，引理 1--2）
<sec-expectation-tower>
- #strong[P6（数学期望的定义）]：当级数绝对收敛时，离散型随机变量 $X$ 的数学期望定义为：
  $ bb(E) [X] eq.dot sum_x x thin p(x) . $ <eq-p6-exp>

- #strong[P7（条件期望的定义与双重含义）]：给定 ${Y = y}$ 时，$X$ 的条件期望定义为：
  $ bb(E) [X divides Y = y] eq.dot sum_x x thin p(x divides y) . $ <eq-p7-cond-exp>
  #strong[理解条件期望的两个视角]：
  + 当 $y$ 是给定的具体取值时，$bb(E) [X divides Y = y]$ 是一个确定的#strong[实数]；若将 $y$ 视为自变量，则 $g(y) eq.dot bb(E) [X divides Y = y]$ 是一个关于 $y$ 的确定性函数。
  + 若未指定 $Y$ 的具体取值，记号 $bb(E) [X divides Y]$ 表示将函数 $g(dot.op)$ 作用于随机变量 $Y$ 上所得的#strong[复合随机变量] $g(Y)$：当 $Y$ 取值为 $y$ 时，$bb(E) [X divides Y]$ 的取值即为 $bb(E) [X divides Y = y]$。#link(<sec-bellman-exp-cond>)[第 3 章]与#link(<sec-bellman-opt>)[第 5 章]的推导均建立在这一视角之上。

- #strong[P8（条件期望的单调性）]：若随机变量满足 $X lt.eq Y$ 几乎处处成立（即当 $x > y$ 时 $p(x, y divides z) = 0$），则由 $bb(E) [Y - X divides Z = z] = sum_(x lt.eq y) (y - x) p(x, y divides z) gt.eq 0$ 及条件期望的线性性，必有：
  $ bb(E) [X divides Z] lt.eq bb(E) [Y divides Z] . $ <eq-p8-mono>

- #strong[P9（条件已知量的提取性质）]：若函数 $f(Z)$ 仅依赖于条件变量 $Z$，则在以 $Z$ 为条件的期望中，$f(Z)$ 可视为已知常数直接提到期望号外：
  $
    bb(E) [#mhlb($f(Z)$) thin X divides Z] = #mhlb($f(Z)$) thin bb(E) [X divides Z], #h(2em) upright("特别地，") #h(1.5em) bb(E) [f(Z) divides Z] = f(Z) .
  $ <eq-p9-pullout>

- #strong[P10（多重条件下的期望定义）]：对任意联合条件事件 $C$（如 ${S_t = s, A_t = a}$），有 $bb(E) [X divides C] = sum_x x thin p(x divides C)$。

- #strong[P11（条件独立性）]：若在给定 $Z$ 的条件下，$X$ 与 $Y$ 的条件分布满足 $p(x divides y, z) = p(x divides z)$（$forall x, y, z$），则称 $X$ 与 $Y$ 关于 $Z$ #strong[条件独立]，记为 $X perp Y divides Z$。由 P7 与 P10 立得，此时条件期望中多余的条件 $Y$ 可以直接略去：
  $ bb(E) [X divides #mhlb($Y, Z$)] = bb(E) [X divides #mhlb($Z$)] . $ <eq-p11-cond-indep>

=== 引理 1（条件期望的线性性）
<lem-1>
对任意常数 $a, b in bb(R)$、随机变量 $X, Y$ 与条件变量 $Z$，有：

$ #eqbox([$ bb(E) [a X + b Y divides Z] = a thin #mhl($bb(E) [X divides Z]$) + b thin #mhl($bb(E) [Y divides Z]$) $]) $ <eq-lem-1>

#strong[证明]：由条件期望定义（P7）与边缘分布性质（P1）：
$
  bb(E) [a X + b Y divides Z = z] & = sum_(x, y) (a x + b y) thin p(x, y divides z) \
  & = a sum_x x #mhlb($sum_y p(x, y divides z)$) + b sum_y y #mhlb($sum_x p(x, y divides z)$) \
  & = a sum_x x thin p(x divides z) + b sum_y y thin p(y divides z) = a thin bb(E) [X divides Z = z] + b thin bb(E) [Y divides Z = z] . #h(1.5em) square.filled.medium
$

=== 引理 2（全期望公式与条件加细塔性质）
<lem-2>
设 $X, Y, Z$ 为离散型随机变量且 $bb(E) [ abs(X) ] < oo$，则无条件全期望公式与带公共条件 $Y$ 的加细全期望公式（Tower Property）分别为：

$ #eqbox([$ bb(E) [X] = bb(E) [bb(E) [X divides Y]], #h(2.5em) bb(E) [X divides Y] = bb(E) [bb(E) [X divides Y, #mhlb($Z$)] thin divides thin Y] $]) $ <eq-lem-2>

#strong[注意]：在推导价值函数时，外层条件中已经包含当前状态 $Y = S_t$（或 $(S_t, A_t)$），因此必须使用 @eq-lem-2 右式的#strong[条件加细形式]，在保留外层条件 $Y$ 的同时，向内层期望中引入新的条件变量 $Z$（如 $A_t$ 或 $S_(t + 1)$）。反复应用该式可逐层引入多个条件变量：$bb(E) [X divides Y] = bb(E) [bb(E) [bb(E) [X divides Y, Z, W] divides Y, Z] divides Y]$。

#strong[证明]：对任意给定的 $Y = y$，按条件期望定义（P7）展开 @eq-lem-2 右式的外层期望：
$
  bb(E) [bb(E) [X divides Y, Z] thin divides thin Y = y] & = sum_z bb(E) [X divides Y = y, Z = z] thin p(z divides y) = sum_z (sum_x x thin p(x divides y, z)) p(z divides y) \
  & = sum_x x sum_z #mhlb($p(x divides y, z) thin p(z divides y)$) quad upright("（由 P12 交换求和，并由 P4 合并）") \
  & = sum_x x #mhlg($sum_z p(x, z divides y)$) = sum_x x thin p(x divides y) = bb(E) [X divides Y = y] . #h(1.5em) square.filled.medium
$
（在 @eq-lem-2 右式中取 $Y$ 为平凡常数事件，即退化为左式的无条件全期望公式 $bb(E) [X] = bb(E) [bb(E) [X divides Z]]$。）

#divider()

== 级数绝对收敛与期望交换律（性质 P12--P13）
<sec-series-convergence>
- #strong[P12（有限求和的交换律）]：对有限指标集 $I, J$ 与实数 $a_(i j)$，求和顺序可无条件交换：
  $ sum_(i in I) sum_(j in J) a_(i j) = sum_(j in J) sum_(i in I) a_(i j) . $ <eq-p12-finite-swap>
  在有限 MDP 中，关于状态 $s'$、动作 $a$、奖励 $r$ 的求和均为有限和，因此可自由交换求和顺序。

- #strong[P13（无穷级数与期望的交换）]：对随机变量序列 ${X_k}_(k = 1)^oo$，若级数满足绝对收敛条件 $sum_(k = 1)^oo bb(E) [ abs(X_k) ] < oo$，则期望算子与无穷级数求和可合法交换顺序：
  $ bb(E) [sum_(k = 1)^oo X_k] = sum_(k = 1)^oo bb(E) [X_k] . $ <eq-p13-series-swap>
  #strong[用途]：当 $|R_k| lt.eq R_max$ 且 $gamma in [0, 1)$ 时，由 @eq-return-bound 知 $sum_(k = 1)^oo gamma^(k - 1) bb(E) [ abs(R_(t + k)) ] lt.eq frac(R_max, 1 - gamma) < oo$。这保证了价值函数 $v_pi (s) = bb(E)_(G_t) [G_t divides S_t = s]$ 的良定义性，且对 $G_t = R_(t + 1) + gamma G_(t + 1)$ 两边取期望后拆分为两项之和是严格成立的。

#divider()

== 马尔可夫性与条件独立化简（性质 P14，引理 3）
<sec-markov-lemma3>
- #strong[P14（马尔可夫性，Markov Property）]：MDP 的定义性假设是“给定当前状态与动作后，未来与历史条件独立”，即下一时刻状态与奖励的分布仅取决于当前状态 $S_t$ 和动作 $A_t$，而与更早的历史轨迹无关：
  $
    Pr(S_(t + 1) = s', R_(t + 1) = r divides S_t, A_t, S_(t - 1), A_(t - 1), dots.h, S_0, A_0) = #mhlb($Pr(S_(t + 1) = s', R_(t + 1) = r divides S_t, A_t)$) .
  $ <eq-p14-markov>
  由此可知，在固定平稳策略 $pi$ 下，一旦给定了下一时刻状态 $S_(t + 1) = s'$，从时刻 $t + 1$ 开始的未来轨迹（包括未来回报 $G_(t + 1)$）就只由 $s'$ 与策略 $pi$ 决定，与时刻 $t$ 的状态 $S_t$、动作 $A_t$ 及即时奖励 $R_(t + 1)$ 条件独立，即：
  $ #mhlb($G_(t + 1) perp (S_t, A_t, R_(t + 1)) divides S_(t + 1)$) . $ <eq-markov-indep>
  若状态表示不具备马尔可夫性（如部分可观测马尔可夫决策过程 POMDP），则一步贝尔曼递推不再成立。

=== 引理 3（基于马尔可夫性的条件化简与一步交互分解）
<lem-3>
在有限 MDP 中，设 $g in Gamma$ 为下一时刻回报 $G_(t + 1)$ 的取值，则由马尔可夫性（P14）、条件独立性（P11）及多变量条件全概率公式（@eq-p5-multi）可得以下核心结论：

- #strong[结论 A（概率分布形式，用于#link(<sec-bellman-exp-explicit>)[第 4 章]显式展开推导）]：当已知下一状态 $S_(t + 1) = s'$ 时，更早的 $(s, a, r)$ 对未来回报 $G_(t + 1)$ 的分布不再提供任何额外信息，可从条件中省去：
  $ #eqbox([$ p(g divides s', r, a, s) = #mhlb($p(g divides s')$) $]) $ <eq-lem-3a>
  将 @eq-lem-3a 代入多变量条件链式法则（@eq-p4-multi-chain，取 $z = s, w = a, y = (s', r), x = g$），即得四元组 $(g, s', r, a)$ 在给定状态 $s$ 下的三层概率分解与回报分布 $p(g divides s)$ 展开式：
  $
    p(g, s', r, a divides s) & = #mhl($pi(a divides s)$) thin p(s', r divides s, a) thin #mhlb($p(g divides s')$), \
    p(g divides s) & = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) thin #mhlb($p(g divides s')$) .
  $ <eq-mdp-joint-decomp>

- #strong[结论 B（条件期望形式，用于#link(<sec-bellman-exp-cond>)[第 3 章]条件期望推导）]：在条件期望中，给定 $S_(t + 1) = s'$（或随机变量 $S_(t + 1)$）后，历史条件 $(S_t, A_t, R_(t + 1))$ 可直接略去并识别为后继状态价值：
  $
    #eqbox([$ bb(E)_(G_(t + 1)) [G_(t + 1) divides #mhlb($S_t, A_t, S_(t + 1)$)] = bb(E)_(G_(t + 1)) [G_(t + 1) divides #mhlb($S_(t + 1)$)] = #mhlg($v_pi (S_(t + 1))$) $])
  $ <eq-lem-3b>

- #strong[结论 C（含后继动作的条件期望形式，用于#link(<thm-3.4>)[定理 3.4]）]：若进一步给定后继动作 $A_(t + 1)$，由于 $A_(t + 1)$ 仅依据 $pi(dot.op divides S_(t + 1))$ 采样，且此后轨迹只由 $(S_(t + 1), A_(t + 1))$、环境模型 $p$ 与策略 $pi$ 决定（P14），有 $G_(t + 1) perp (S_t, A_t, R_(t + 1)) divides (S_(t + 1), A_(t + 1))$。由 P11 与#link(<def-1.3>)[定义 1.3]（平稳性保证其对时刻 $t + 1$ 同样成立）得：
  $
    #eqbox([$ bb(E)_(G_(t + 1)) [G_(t + 1) divides #mhlb($S_t, A_t, S_(t + 1), A_(t + 1)$)] = bb(E)_(G_(t + 1)) [G_(t + 1) divides #mhlb($S_(t + 1), A_(t + 1)$)] = #mhlg($q_pi (S_(t + 1), A_(t + 1))$) $])
  $ <eq-lem-3c>

#divider()

// ============================================================
//  第 3 章：贝尔曼期望方程（条件期望形式）
// ============================================================
= 贝尔曼期望方程（条件期望形式）
<sec-bellman-exp-cond>
本章从价值函数的定义出发，结合#strong[回报一步递推关系]（#link(<prop-1.1>)[命题 1.1]）、#strong[条件全期望公式]（#link(<lem-2>)[引理 2]）与#strong[马尔可夫性]（#link(<lem-3>)[引理 3] 结论 B、C），推导四条条件期望形式的贝尔曼期望方程（汇总见 @tab-bellman-exp-cond）。#strong[每条定理均直接从价值函数定义出发证明，不调用本章已证得的其他贝尔曼方程]，以保证各结论相互独立、只依赖#link(<sec-math-prelim>)[第 2 章]的预备知识。

为体现两层随机性的内在生成逻辑，本章与后续章节统一按照#strong[“先单步桥接（$v_pi arrow.r q_pi$、$q_pi arrow.r v_pi$），后复合自递推（$v_pi arrow.r v_pi$、$q_pi arrow.r q_pi$）”]的顺序展开。

#figure(
  caption: [贝尔曼期望方程（条件期望形式）的四类递推关系汇总（各式对所有 $s in cal(S)$ 或 $(s, a) in cal(S) times cal(A)$ 成立）],
  table(
    columns: (auto, 1fr),
    table.header([递推关系], [贝尔曼期望方程（条件期望形式）]),
    table.hline(),
    [$v_pi arrow.r q_pi$ \ #text(size: 8.2pt, fill: muted)[策略层单步转换]],
    [$ v_pi (s) = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] $],
    [$q_pi arrow.r v_pi$ \ #text(size: 8.2pt, fill: muted)[环境层单步转换]],
    [$ q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$v_pi arrow.r v_pi$ \ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ v_pi (s) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $],
    [$q_pi arrow.r q_pi$ \ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1), A_(t + 1)) [R_(t + 1) + gamma thin #mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] $],
  ),
) <tab-bellman-exp-cond>

#divider()

== 状态价值关于动作价值的表示（$v_pi arrow.r q_pi$）
<sec-cond-vq>
#strong[定理 3.1（$v_pi$ 关于 $q_pi$ 的贝尔曼期望方程）] <thm-3.1> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，状态价值等于动作价值在策略分布 $pi(dot.op divides s)$ 下的期望：

$
  #eqbox([$ v_pi (s) = bb(E)_(A_t) [#mhlg($q_pi (S_t, A_t)$) divides S_t = s] = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] $])
$ <eq-bellman-exp-vq>

#strong[证明]：本式不涉及时间步推进，只需在 $v_pi (s)$ 的定义式（@eq-v-def）中应用#link(<lem-2>)[引理 2]（取 $X = G_t, Y = S_t, Z = A_t$），引入当前动作 $A_t$ 作为内层条件：

$
  v_pi (s) & eq.dot bb(E)_(G_t) [G_t divides S_t = s] \
  & = bb(E)_(A_t) [bb(E)_(G_t) [G_t divides S_t = s, #mhlb($A_t$)] thin divides thin S_t = s] quad #[（由#link(<lem-2>)[引理 2] 引入动作条件 $A_t$）] \
  & = bb(E)_(A_t) [#mhlg($q_pi (s, A_t)$) divides S_t = s] quad #[（由#link(<def-1.3>)[定义 1.3]：$bb(E)_(G_t) [G_t divides S_t = s, A_t = a] = q_pi (s, a)$）] \
  & = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] . #h(2em) square.filled.medium
$

#strong[含义]：状态价值等于在该状态下按策略 $pi(dot.op divides s)$ 选择各动作时动作价值的加权平均。@eq-bellman-exp-vq 只涉及#strong[策略层]的动作采样，不涉及环境状态转移。

#divider()

== 动作价值关于状态价值的表示（$q_pi arrow.r v_pi$）
<sec-cond-qv>
#strong[定理 3.2（$q_pi$ 关于 $v_pi$ 的贝尔曼期望方程）] <thm-3.2> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，有：

$
  #eqbox([$ q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [#mhl($R_(t + 1)$) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] $])
$ <eq-bellman-exp-qv>

#strong[证明]：
+ #strong[代入回报递推式并做线性拆分]：由动作价值定义（@eq-q-def）、回报一步递推式（@eq-return-recursion）与#link(<lem-1>)[引理 1]：
  $
    q_pi (s, a) & eq.dot bb(E)_(G_t) [G_t divides S_t = s, A_t = a] = bb(E)_(R_(t + 1), G_(t + 1)) [#mhl($R_(t + 1) + gamma G_(t + 1)$) divides S_t = s, A_t = a] \
    & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s, A_t = a] + gamma thin bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a] .
  $
+ #strong[引入后继状态 $S_(t + 1)$ 并应用马尔可夫性]：对第二项应用#link(<lem-2>)[引理 2]（取 $Y = (S_t, A_t), Z = S_(t + 1)$）加细条件，再由#link(<lem-3>)[引理 3] 结论 B（@eq-lem-3b）省去已知 $S_(t + 1)$ 下多余的历史条件 $(S_t = s, A_t = a)$：
  $
    bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a] & = bb(E)_(S_(t + 1)) [bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a, #mhlb($S_(t + 1)$)] thin divides thin S_t = s, A_t = a] \
    & = bb(E)_(S_(t + 1)) [#mhlb($bb(E)_(G_(t + 1)) [G_(t + 1) divides S_(t + 1)]$) thin divides thin S_t = s, A_t = a] \
    & = bb(E)_(S_(t + 1)) [#mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] .
  $
+ #strong[代回合并]：将第 2 步代回第 1 步并由#link(<lem-1>)[引理 1] 合并两项期望，即得 @eq-bellman-exp-qv。$square.filled.medium$

#strong[含义]：由于当前动作 $A_t = a$ 已经给定，@eq-bellman-exp-qv 右端的一步随机性#strong[仅来自环境的状态转移与奖励] $(S_(t + 1), R_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$，策略 $pi$ 的影响已全部封装在后继状态价值 $v_pi (S_(t + 1))$ 内部。

#divider()

== 状态价值的自递推（$v_pi arrow.r v_pi$）
<sec-cond-vv>
#strong[定理 3.3（状态价值的贝尔曼期望方程）] <thm-3.3> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，状态价值函数满足：

$ #eqbox([$ v_pi (s) = bb(E)_(R_(t + 1), S_(t + 1)) [#mhl($R_(t + 1)$) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $]) $ <eq-bellman-exp-vv>

#strong[证明]：从定义 $v_pi (s) eq.dot bb(E)_(G_t) [G_t divides S_t = s]$（@eq-v-def）出发，由#link(<prop-1.1>)[命题 1.1] 与#link(<lem-1>)[引理 1] 拆分为两项后，对第二项应用#link(<lem-2>)[引理 2]（取 $Y = S_t, Z = S_(t + 1)$）引入后继状态，再由#link(<lem-3>)[引理 3] 结论 B（@eq-lem-3b）省去历史条件 $S_t = s$：
$
  v_pi (s) & eq.dot bb(E)_(G_t) [G_t divides S_t = s] = bb(E)_(R_(t + 1), G_(t + 1)) [#mhl($R_(t + 1) + gamma G_(t + 1)$) divides S_t = s] \
  & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] + gamma thin bb(E)_(S_(t + 1)) [bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, #mhlb($S_(t + 1)$)] thin divides thin S_t = s] quad #[（由#link(<lem-2>)[引理 2] 加细条件）] \
  & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] + gamma thin bb(E)_(S_(t + 1)) [#mhlg($v_pi (S_(t + 1))$) divides S_t = s] quad #[（由#link(<lem-3>)[引理 3] 结论 B 化简）] \
  & = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] . quad #[（由 P1 边缘化与#link(<lem-1>)[引理 1] 合并）] #h(1em) square.filled.medium
$

#strong[含义]：状态 $s$ 的价值，等于从 $s$ 出发执行一步交互所获得的即时奖励 $R_(t + 1)$ 加上折扣后下一状态价值 $gamma v_pi (S_(t + 1))$ 的条件期望。

#divider()

== 动作价值的自递推（$q_pi arrow.r q_pi$）
<sec-cond-qq>
#strong[定理 3.4（动作价值的贝尔曼期望方程）] <thm-3.4> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，动作价值函数满足：

$
  #eqbox([$ q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1), A_(t + 1)) [#mhl($R_(t + 1)$) + gamma thin #mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] $])
$ <eq-bellman-exp-qq>

#strong[证明]：
+ #strong[代入回报递推式并做线性拆分]：由动作价值定义（@eq-q-def）、回报一步递推式（@eq-return-recursion）与#link(<lem-1>)[引理 1]：
  $
    q_pi (s, a) & eq.dot bb(E)_(G_t) [G_t divides S_t = s, A_t = a] = bb(E)_(R_(t + 1), G_(t + 1)) [#mhl($R_(t + 1) + gamma G_(t + 1)$) divides S_t = s, A_t = a] \
    & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s, A_t = a] + gamma thin bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a] .
  $
+ #strong[同时引入后继状态与后继动作 $(S_(t + 1), A_(t + 1))$]：对第二项应用#link(<lem-2>)[引理 2]（取 $Y = (S_t, A_t), Z = (S_(t + 1), A_(t + 1))$）加细条件，再由#link(<lem-3>)[引理 3] 结论 C（@eq-lem-3c）省去历史条件 $(S_t = s, A_t = a)$：
  $
    & bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a] \
    & = bb(E)_(S_(t + 1), A_(t + 1)) [bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a, #mhlb($S_(t + 1), A_(t + 1)$)] thin divides thin S_t = s, A_t = a] \
    & = bb(E)_(S_(t + 1), A_(t + 1)) [#mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] .
  $
+ #strong[代回合并]：第 1 项可由 P1 边缘化改写为对 $(R_(t + 1), S_(t + 1), A_(t + 1))$ 联合分布的期望，再由#link(<lem-1>)[引理 1] 与第 2 步合并，即得 @eq-bellman-exp-qq。$square.filled.medium$

#strong[含义]：期望下角标中的 $(R_(t + 1), S_(t + 1))$ 来自环境层转移 $p(dot.op, dot.op divides s, a)$，$A_(t + 1)$ 来自策略层采样 $pi(dot.op divides S_(t + 1))$。若把对 $A_(t + 1)$ 的平均单独写出，@eq-bellman-exp-qq 也可写成嵌套形式 $q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma thin #mhl($bb(E)_(A_(t + 1) tilde.op pi(dot.op divides S_(t + 1)))$) [q_pi (S_(t + 1), A_(t + 1))] divides S_t = s, A_t = a]$（对内层再用一次#link(<lem-2>)[引理 2]，取 $Z = (R_(t + 1), S_(t + 1))$，并由 P14 知 $A_(t + 1) perp (S_t, A_t, R_(t + 1)) divides S_(t + 1)$）。

#strong[注（奖励下标的两种记号约定）]：本文沿用 Sutton & Barto 的约定，称在时刻 $t$ 执行 $A_t$ 后获得的奖励为 $R_(t + 1)$，它与 $S_(t + 1)$ 一起由 $p(s', r divides s, a)$ #strong[联合随机]生成，因此 @eq-bellman-exp-qq 的下角标必须包含 $R_(t + 1)$。另一常见约定（如王树森《深度强化学习》）将同一奖励记为 $R_t$，回报递推写为 $G_t = R_t + gamma G_(t + 1)$，并把奖励视为 $(S_t, A_t, S_(t + 1))$ 的确定函数，此时动作价值的贝尔曼方程写作：
$
  Q_pi (s_t, a_t) = bb(E)_(S_(t + 1), A_(t + 1)) [R_t + gamma dot.op Q_pi (S_(t + 1), A_(t + 1)) divides S_t = s_t, A_t = a_t] .
$ <eq-qq-reward-convention>
两者的区别只有两点：（1）$R_t$ 与 $R_(t + 1)$ 仅是对同一奖励的不同命名，数学内容相同；（2）下角标是否包含奖励取决于给定 $(s, a, s')$ 后奖励是否仍随机——若奖励由 $(s, a, s')$ 确定，则 $R_(t + 1)$ 不再是独立的随机变量，@eq-bellman-exp-qq 的下角标可省去 $R_(t + 1)$，与 @eq-qq-reward-convention 完全一致；若奖励本身随机（本文的一般设定），则必须同时对 $R_(t + 1)$ 求平均。

#divider()

== 两层随机性分解与价值回溯结构
<sec-two-layer-backup>
#link(<thm-3.1>)[定理 3.1] 至#link(<thm-3.4>)[定理 3.4] 清晰地揭示了智能体与环境交互的两层交替随机性（见 @fig-backup-expectation）：
- #strong[策略层转换（#link(<thm-3.1>)[定理 3.1]，$v_pi arrow.r q_pi$）]：智能体在同一时刻 $t$ 根据策略 $pi(dot.op divides S_t)$ 选择动作 $A_t$；
- #strong[环境层转换（#link(<thm-3.2>)[定理 3.2]，$q_pi arrow.r v_pi$）]：环境根据转移分布 $p(dot.op, dot.op divides S_t, A_t)$ 跨时间步产生下一状态 $S_(t + 1)$ 与即时奖励 $R_(t + 1)$。

#figure(
  {
    // 边标签统一降到 Diagram Label 层级（7.6pt），节点文字保持正文层级，
    // 使整幅图的横向尺寸由节点行（109mm + 3×17mm = 160mm）决定而不被长标签撑宽。
    let lb(body) = text(size: 7.6pt, body)
    diagram(
      spacing: (17mm, 12mm),
      node-stroke: 0.9pt + accent,
      edge-stroke: 0.8pt + accent,
      node((0, 0), [*状态价值* \ $v_pi (S_t)$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 25mm),
      node((1, 0), [*动作价值* \ $q_pi (S_t, A_t)$], fill: white, corner-radius: 4pt, inset: 6pt, width: 26mm),
      node((2, 0), [*后继状态价值* \ $v_pi (S_(t+1))$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 27mm),
      node((3, 0), [*后继动作价值* \ $q_pi (S_(t+1), A_(t+1))$], fill: white, corner-radius: 4pt, inset: 6pt, width: 31mm),
      edge((0, 0), (1, 0), "->", lb[定理 3.1 \ 策略层 $pi$], label-side: left),
      edge((1, 0), (2, 0), "->", lb[定理 3.2 \ 环境层 $p$], label-side: left),
      edge((2, 0), (3, 0), "->", lb[定理 3.1 \ 策略层 $pi$], label-side: left),
      edge((0, 0), (2, 0), "->", lb[定理 3.3（状态价值自递推 $v_pi arrow.r v_pi$：先策略层 $v_pi arrow.r q_pi$，再环境层 $q_pi arrow.r v_pi$）], bend: 32deg, label-side: left, stroke: (paint: accent, thickness: 0.8pt, dash: "dashed")),
      edge((1, 0), (3, 0), "->", lb[定理 3.4（动作价值自递推 $q_pi arrow.r q_pi$：先环境层 $q_pi arrow.r v_pi$，再策略层 $v_pi arrow.r q_pi$）], bend: -32deg, label-side: right, stroke: (paint: accent, thickness: 0.8pt, dash: "dashed")),
    )
  },
  caption: [贝尔曼期望方程的两层随机性交替转换与四类递推复合结构],
) <fig-backup-expectation>

如 @fig-backup-expectation 所示，状态价值的自递推（#link(<thm-3.3>)[定理 3.3]）与动作价值的自递推（#link(<thm-3.4>)[定理 3.4]）正是上述两步原子转换的前后复合。条件期望形式的优点是结构紧凑，便于推导时序差分（TD）等基于采样估计的无模型算法；若要利用已知的环境模型直接计算价值函数（如动态规划），则需要将条件期望展开为显式的概率求和形式。

#divider()

// ============================================================
//  第 4 章：贝尔曼期望方程（显式展开形式）
// ============================================================
= 贝尔曼期望方程（显式展开形式）
<sec-bellman-exp-explicit>
本章将#link(<sec-bellman-exp-cond>)[第 3 章]的四条条件期望方程展开为关于策略分布 $pi(a divides s)$ 与环境转移概率 $p(s', r divides s, a)$ 的#strong[显式求和形式]（汇总见 @tab-bellman-exp-explicit）。

#figure(
  caption: [贝尔曼期望方程（显式展开形式）的四类递推关系汇总（各式对所有 $s in cal(S)$ 或 $(s, a) in cal(S) times cal(A)$ 成立）],
  table(
    columns: (auto, 1fr),
    table.header([递推关系], [贝尔曼期望方程（显式展开形式）]),
    table.hline(),
    [$v_pi arrow.r q_pi$],
    [$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) thin #mhlg($q_pi (s, a)$) $],
    [$q_pi arrow.r v_pi$],
    [$ q_pi (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$) $],
    [$v_pi arrow.r v_pi$],
    [$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$)] $],
    [$q_pi arrow.r q_pi$],
    [$ q_pi (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($q_pi (s', a')$) $],
  ),
) <tab-bellman-exp-explicit>

== 两条等价推导路径：条件期望直接展开与回报分布底层推导
<sec-two-derivation-paths>
导出 @tab-bellman-exp-explicit 中的显式求和方程有两条完全等价的严格证明路径（对照见 @fig-two-paths-expansion）：

+ #strong[路径一（由第 3 章条件期望方程一步展开）]：在#link(<thm-3.3>)[定理 3.3] 的 $v_pi (s) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$ 中，期望内部仅依赖于一步随机变量 $(R_(t + 1), S_(t + 1))$。给定 $S_t = s$ 时，产生动作 $A_t = a$ 并转移到 $(S_(t + 1) = s', R_(t + 1) = r)$ 的联合条件概率为 $pi(a divides s) p(s', r divides s, a)$。直接按条件期望定义（P7）写出求和式并分解边缘概率，一步即可得到显式展开式：
  $
    v_pi (s) & = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s] \
    & = sum_(a in cal(A)) #mhl($pi(a divides s)$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$)] .
  $ <eq-direct-one-step-expand>

+ #strong[路径二（不依赖塔性质，从回报分布 $p(g divides s)$ 底层展开）]：直接从价值函数原始定义 $v_pi (s) = bb(E)_(R_(t + 1), G_(t + 1)) [R_(t + 1) + gamma G_(t + 1) divides S_t = s]$ 出发，利用条件全概率公式（P5）对未来回报分布 $p(g divides s)$ 显式引入中间变量 $(a, s', r)$，再通过#link(<lem-3>)[引理 3] 结论 A（$p(g divides s', r, a, s) = p(g divides s')$）完成约简。这一底层路径直观展示了样本空间中每一步概率是如何拆解与重组的，下文 4.2 节将完整呈现该推导过程。

#figure(
  diagram(
    spacing: (14mm, 11mm),
    node-stroke: 0.8pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0.5, 0), [*价值函数定义与回报一步递推* \ $v_pi (s) = bb(E)_(R_(t+1), G_(t+1)) [R_(t+1) + gamma G_(t+1) divides S_t = s]$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 68mm),
    node((0, 1), [*路径一：条件期望与塔性质（第 3 章）* \ 引入 $S_(t+1)$ 加细条件并由引理 3B 化简 \ $v_pi (s) = bb(E)_(R_(t+1), S_(t+1)) [R_(t+1) + gamma v_pi (S_(t+1)) divides S_t = s]$], fill: white, corner-radius: 4pt, inset: 6pt, width: 66mm),
    node((1, 1), [*路径二：回报分布与全概率公式（第 4 章）* \ 展开 $p(g divides s) = sum_(a, s', r) pi(a divides s) p(s', r divides s, a) p(g divides s')$ \ 交换有限求和与期望算子], fill: white, corner-radius: 4pt, inset: 6pt, width: 66mm),
    node((0.5, 2), [*贝尔曼期望方程（显式展开形式）* \ $v_pi (s) = sum_a pi(a divides s) [sum_r p(r divides s, a) r + gamma sum_(s') p(s' divides s, a) v_pi (s')]$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 84mm),
    edge((0.5, 0), (0, 1), "->", [引理 2 + 引理 3B], label-side: right),
    edge((0.5, 0), (1, 1), "->", [P5 全概率 + 引理 3A], label-side: left),
    edge((0, 1), (0.5, 2), "->", [按一步分布 $pi dot.op p$ 展开], label-side: right),
    edge((1, 1), (0.5, 2), "->", [内层对 $g$ 求和得 $v_pi (s')$], label-side: left),
  ),
  caption: [贝尔曼期望方程的两条等价推导路径：条件期望塔性质路径与全概率底层展开路径],
) <fig-two-paths-expansion>

#divider()

== 四类递推关系的显式展开定理（定理 4.1--4.4）
<sec-explicit-theorems>

=== 状态价值到动作价值的展开（$v_pi arrow.r q_pi$）
#strong[定理 4.1（$v_pi$ 关于 $q_pi$ 的展开形式）] <thm-4.1> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，有：

$
  #eqbox([$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) thin #mhlg($q_pi (s, a)$), quad forall s in cal(S) $])
$ <eq-exp-explicit-vq>

#strong[证明]：直接将#link(<thm-3.1>)[定理 3.1] 的期望式 $bb(E)_(A_t tilde.op pi(dot.op divides s)) [q_pi (s, A_t)]$ 按离散期望定义展开即得；若从回报分布 $p(g divides s)$ 出发，则只需引入动作变量 $a$ 应用条件全概率公式（@eq-p5-cond）：
$
  v_pi (s) & = sum_(g in Gamma) g thin p(g divides s) = sum_(g in Gamma) g sum_(a in cal(A)) #mhlb($p(g divides s, a) thin p(a divides s)$) \
  & = sum_(a in cal(A)) #mhl($pi(a divides s)$) underbrace(sum_(g in Gamma) g thin p(g divides s, a), = thin q_pi (s, a)) = sum_(a in cal(A)) #mhl($pi(a divides s)$) thin #mhlg($q_pi (s, a)$) . #h(2em) square.filled.medium
$

=== 动作价值到状态价值的展开（$q_pi arrow.r v_pi$）
#strong[定理 4.2（$q_pi$ 关于 $v_pi$ 的展开形式）] <thm-4.2> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，有：

$
  #eqbox([$ q_pi (s, a) = sum_(r in cal(R)) #mhl($p(r divides s, a) r$) + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$), quad forall (s, a) in cal(S) times cal(A) $])
$ <eq-exp-explicit-qv>

#strong[证明]：由动作价值函数的定义（@eq-q-def）、回报递推式（@eq-return-recursion）与#link(<lem-1>)[引理 1]，将 $q_pi (s, a)$ 拆分为即时奖励期望项 (A) 与未来回报期望项 (B)：
$
  q_pi (s, a) = underbrace(bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s, A_t = a], upright("记为项 (A)")) + gamma thin underbrace(bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, A_t = a], upright("记为项 (B)")) .
$
+ #strong[展开即时奖励期望项 (A)]：条件中已给定 $(s, a)$，无需对动作 $a$ 求和，只需按 P7 写出期望并联系联合分布 $p(s', r divides s, a)$：
  $
    upright("(A)") = sum_(r in cal(R)) p(r divides s, a) r = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) r .
  $
+ #strong[展开未来回报期望项 (B)]：引入 $(s', r)$ 对 $p(g divides s, a)$ 做条件全概率展开（@eq-p5-cond），再应用马尔可夫性（#link(<lem-3>)[引理 3] 结论 A，@eq-lem-3a）与有限和交换律（P12）：
  $
    upright("(B)") & = sum_(g in Gamma) g thin p(g divides s, a) = sum_(g in Gamma) g sum_(s' in cal(S), thin r in cal(R)) #mhlb($p(g divides s', r, s, a)$) thin p(s', r divides s, a) \
    & = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) underbrace(sum_(g in Gamma) g thin #mhlb($p(g divides s')$), = thin v_pi (s')) quad #[（由#link(<lem-3>)[引理 3] 结论 A 省去 $(s, a, r)$ 并交换求和）] \
    & = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) #mhlg($v_pi (s')$) = sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$) . quad #[（对 $r$ 求和得边缘概率 $p(s' divides s, a)$）]
  $
+ #strong[合并两项]：将项 (A) 与 $gamma dot.op upright("(B)")$ 相加，即得 @eq-exp-explicit-qv。$square.filled.medium$

=== 状态价值的展开递推（$v_pi arrow.r v_pi$）
#strong[定理 4.3（状态价值贝尔曼方程的展开形式）] <thm-4.3> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，有：

$
  #eqbox([$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$)], quad forall s in cal(S) $])
$ <eq-exp-explicit-vv>

#strong[证明（方法一：由定理 4.1 与定理 4.2 直接复合）]：将#link(<thm-4.2>)[定理 4.2]（@eq-exp-explicit-qv）中的 $q_pi (s, a)$ 展开式直接代入#link(<thm-4.1>)[定理 4.1]（@eq-exp-explicit-vq）的 $v_pi (s) = sum_(a in cal(A)) pi(a divides s) q_pi (s, a)$，一步即得 @eq-exp-explicit-vv。$square.filled.medium$

#strong[证明（方法二：从回报分布 $p(g divides s)$ 完整展开）]：若不借助 $q_pi (s, a)$，直接对 $v_pi (s) = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] + gamma bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s]$ 的两项分别用多变量条件全概率公式（@eq-p5-multi）与 @eq-mdp-joint-decomp 展开：
- #strong[即时奖励期望项]：引入 $(a, s')$ 展开边缘概率 $p(r divides s) = sum_(a in cal(A)) sum_(s' in cal(S)) pi(a divides s) p(s', r divides s, a)$，交换求和得：
  $
    bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] = sum_(r in cal(R)) r thin p(r divides s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(r in cal(R)) p(r divides s, a) r .
  $
- #strong[未来回报期望项]：将 @eq-mdp-joint-decomp 的 $p(g divides s) = sum_(a in cal(A)) pi(a divides s) sum_(s', r) p(s', r divides s, a) #mhlb($p(g divides s')$)$ 代入 $sum_(g in Gamma) g thin p(g divides s)$，并将关于 $g$ 的求和移至最内层：
  $
    bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s] & = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) underbrace(sum_(g in Gamma) g thin #mhlb($p(g divides s')$), = thin bb(E)_(G_(t + 1)) [G_(t + 1) divides S_(t + 1) = s'] thin = thin v_pi (s')) \
    & = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$) .
  $
将上述两项相加并提取外层公因式 $sum_(a in cal(A)) pi(a divides s)$，同样得到 @eq-exp-explicit-vv。$square.filled.medium$

=== 动作价值的展开递推（$q_pi arrow.r q_pi$）
#strong[定理 4.4（动作价值贝尔曼方程的展开形式）] <thm-4.4> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，有：

$
  #eqbox([$ q_pi (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($q_pi (s', a')$), quad forall (s, a) in cal(S) times cal(A) $])
$ <eq-exp-explicit-qq>

#strong[证明]：在#link(<thm-4.2>)[定理 4.2]（@eq-exp-explicit-qv）右端，利用#link(<thm-4.1>)[定理 4.1] 将下一状态价值 $v_pi (s')$ 展开为下一时刻动作 $a'$ 的加权平均 $v_pi (s') = sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($q_pi (s', a')$)$，代入即得 @eq-exp-explicit-qq。$square.filled.medium$

#divider()

== 显式展开形式的三种常见等价写法
<sec-explicit-variants>
在不同强化学习教材与文献中，贝尔曼方程的显式展开式常根据环境一步转移与奖励分布的边缘化程度写成以下三种等价形式（完整对照见 @tab-bellman-exp-variants）：

+ #strong[边缘分布分离形式（本章定理采用的约简形式）]：利用边缘概率 $p(r divides s, a) = sum_(s' in cal(S)) p(s', r divides s, a)$ 与 $p(s' divides s, a) = sum_(r in cal(R)) p(s', r divides s, a)$，将即时奖励期望与后继状态价值期望拆分为两个独立的单变量求和：
  $ sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) v_pi (s') . $ <eq-variant-marginal>

+ #strong[联合分布合并形式（Sutton & Barto 标准形式）]：将关于 $r$ 和 $s'$ 的两项求和逆向还原到联合分布 $p(s', r divides s, a)$ 下合并书写，使一步回报目标 $[r + gamma v_pi (s')]$ 保持整体紧凑：
  $
    sum_(s' in cal(S), thin r in cal(R)) #mhl($p(s', r divides s, a)$) [r + gamma #mhlg($v_pi (s')$)] = & sum_(r in cal(R)) underbrace((sum_(s' in cal(S)) p(s', r divides s, a)), = thin p(r divides s, a)) r \
    & + gamma sum_(s' in cal(S)) underbrace((sum_(r in cal(R)) p(s', r divides s, a)), = thin p(s' divides s, a)) v_pi (s') .
  $ <eq-variant-joint>

+ #strong[期望奖励函数形式（动态规划与矩阵运算常用形式）]：预先定义状态-动作期望奖励函数 $r(s, a) eq.dot bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s, A_t = a] = sum_(r in cal(R)) p(r divides s, a) r = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) r$（或定义依赖于后继状态的期望奖励 $r(s, a, s') eq.dot bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s, A_t = a, S_(t + 1) = s']$），从而消去对奖励集合 $cal(R)$ 的显式求和：
  $
    #mhl($r(s, a)$) + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$) = sum_(s' in cal(S)) p(s' divides s, a) [r(s, a, s') + gamma #mhlg($v_pi (s')$)] .
  $ <eq-variant-expected-reward>

#figure(
  caption: [四条贝尔曼期望方程在联合分布合并形式（Sutton & Barto）与期望奖励函数形式下的完整对照],
  table(
    columns: (auto, auto, 1fr),
    table.header([递推关系], [形式], [公式]),
    table.hline(),
    table.cell(rowspan: 2)[$v_pi arrow.r q_pi$],
    [联合分布合并形式],
    [$ v_pi (s) = sum_(a in cal(A)) pi(a divides s) q_pi (s, a) $],
    [期望奖励函数形式],
    [$ v_pi (s) = sum_(a in cal(A)) pi(a divides s) q_pi (s, a) $],
    table.cell(rowspan: 2)[$q_pi arrow.r v_pi$],
    [联合分布合并形式],
    [$ q_pi (s, a) = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma v_pi (s')] $],
    [期望奖励函数形式],
    [$ q_pi (s, a) = r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) v_pi (s') $],
    table.cell(rowspan: 2)[$v_pi arrow.r v_pi$],
    [联合分布合并形式],
    [$ v_pi (s) = sum_(a in cal(A)) pi(a divides s) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma v_pi (s')] $],
    [期望奖励函数形式],
    [$ v_pi (s) = sum_(a in cal(A)) pi(a divides s) [r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) v_pi (s')] $],
    table.cell(rowspan: 2)[$q_pi arrow.r q_pi$],
    [联合分布合并形式],
    [$ q_pi (s, a) = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma sum_(a' in cal(A)) pi(a' divides s') q_pi (s', a')] $],
    [期望奖励函数形式],
    [$ q_pi (s, a) = r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) sum_(a' in cal(A)) pi(a' divides s') q_pi (s', a') $],
  ),
) <tab-bellman-exp-variants>

#divider()

== 常见误区辨析：马尔可夫性下为何 $p(g divides s) eq.not p(g)$
<sec-misconception-pg>
在阅读 4.2 节的底层推导时，初学者常会产生如下疑问：既然在推导中利用马尔可夫性声称“未来回报 $G_(t + 1)$（取值为 $g$）不依赖于时刻 $t$ 的状态 $s$”，从而将 $p(g divides s', r, a, s)$ 写为 $p(g divides s')$，那么为何不能在一开始就直接认为 $p(g divides s) = p(g)$？

这一误区源于混淆了#strong[已知下一状态 $s'$] 与#strong[未知下一状态 $s'$] 两种截然不同的条件集合（概率图模型路径对比见 @fig-markov-d-sep）：

+ #strong[$p(g divides s', r, a, s) = p(g divides s')$（已知下一状态 $s'$，路径被阻断）]：在马尔可夫转移链 $S_t arrow.r A_t arrow.r S_(t + 1) arrow.r G_(t + 1)$ 中，由于已经给定了下一时刻状态 $S_(t + 1) = s'$，从 $t + 1$ 时刻往后的未来回报 $G_(t + 1)$ 就只由 $s'$ 和策略 $pi$ 决定。此时，智能体究竟是从哪个旧状态 $s$、通过哪个动作 $a$ 到达 $s'$ 的，属于被 $S_(t + 1) = s'$ 阻断的冗余历史信息，因此可以省去 $(s, a, r)$。
+ #strong[$p(g divides s) eq.not p(g)$（未知下一状态 $s'$，概率沿转移链传递）]：在 $p(g divides s)$ 的条件中，#strong[并未给定下一状态 $s'$]。此时，当前状态 $s$ 会直接决定智能体在下一时刻转移到各个后继状态 $s'$ 的边缘转移分布 $p(s' divides s) = sum_(a, r) pi(a divides s) p(s', r divides s, a)$，从而间接影响未来回报 $g$ 的分布。

#figure(
  stack(
    dir: ttb,
    spacing: 1.2em,
    text(size: 9pt)[*情形 1：已知 $S_(t+1) = s'$*（引理 3A）：路径被阻断，$p(g divides s', r, a, s) = p(g divides s')$],
    diagram(
      spacing: (30mm, 8mm),
      node-stroke: 0.8pt + accent,
      edge-stroke: 0.8pt + accent,
      node((0, 0), [$S_t = s$], corner-radius: 10pt, inset: 6pt, fill: white),
      edge((0, 0), (1, 0), "->", [$pi(a divides s)$], label-side: left, label-sep: 4pt),
      node((1, 0), [$A_t = a$], corner-radius: 10pt, inset: 6pt, fill: white),
      edge((1, 0), (2, 0), "->", [$p(s', r divides s, a)$], label-side: left, label-sep: 4pt),
      node((2, 0), [*$S_(t+1) = s'$* \ （已给定）], corner-radius: 4pt, fill: accent-mid, stroke: 1.3pt + accent, inset: 5pt),
      edge((2, 0), (3, 0), "->", [$p(g divides s')$], label-side: left, label-sep: 4pt),
      node((3, 0), [$G_(t+1) = g$], corner-radius: 10pt, inset: 6pt, fill: accent-soft),
      edge((0, 0), (3, 0), "-->", bend: 32deg, stroke: (paint: luma(130), thickness: 0.7pt, dash: "dashed")),
    ),
    text(size: 9pt)[*情形 2：未知 $S_(t+1)$*：$p(g divides s) eq.not p(g)$，需对所有 $s'$ 求和],
    diagram(
      spacing: (30mm, 8mm),
      node-stroke: 0.8pt + accent,
      edge-stroke: 0.8pt + accent,
      node((0, 0), [*$S_t = s$* \ （已给定）], corner-radius: 4pt, fill: accent-mid, stroke: 1.3pt + accent, inset: 5pt),
      edge((0, 0), (1.5, 0), "->", [转移分布 $p(s' divides s)$], label-side: left, label-sep: 4pt),
      node((1.5, 0), [$S_(t+1)$ \ （未给定，遍历 $s'$）], corner-radius: 4pt, fill: warn-soft, stroke: 0.9pt + warn-stroke, inset: 5pt),
      edge((1.5, 0), (3, 0), "->", [后继分布 $p(g divides s')$], label-side: left, label-sep: 4pt),
      node((3, 0), [$G_(t+1) = g$], corner-radius: 10pt, inset: 6pt, fill: accent-soft),
    ),
  ),
  caption: [已知下一状态 $S_(t+1) = s'$ 时的马尔可夫条件独立阻断与未知 $S_(t+1)$ 时的概率传递对比],
) <fig-markov-d-sep>

对 $p(g divides s)$ 与无条件分布 $p(g)$ 分别关于后继状态 $S_(t + 1) = s'$ 做全概率展开（设时刻 $t$ 的状态边缘分布为 $p(tilde(s))$）：

$
  p(g divides s) & = sum_(s' in cal(S)) p(g divides s') underbrace((sum_(a in cal(A), thin r in cal(R)) pi(a divides s) thin p(s', r divides s, a)), = thin p(s' divides s)) = sum_(s' in cal(S)) p(g divides s') thin #mhl($p(s' divides s)$), \
  p(g) & = sum_(tilde(s) in cal(S)) p(tilde(s)) thin p(g divides tilde(s)) = sum_(s' in cal(S)) p(g divides s') underbrace((sum_(tilde(s) in cal(S)) p(tilde(s)) thin p(s' divides tilde(s))), = thin p(s')) = sum_(s' in cal(S)) p(g divides s') thin #mhlb($p(s')$) .
$ <eq-pg-vs-pgs>

由 @eq-pg-vs-pgs 可见，$p(g divides s)$ 是以#strong[从特定状态 $s$ 出发的条件转移概率 $p(s' divides s)$] 为权重对 $p(g divides s')$ 加权求和，而 $p(g)$ 是以#strong[对所有起点平均后的边缘状态分布 $p(s')$] 为权重加权求和，二者的加权权重截然不同。

#divider()

// ============================================================
//  第 5 章：贝尔曼最优方程：从策略空间最大化到单步贪心递推
// ============================================================
= 贝尔曼最优方程：从策略空间最大化到单步贪心递推
<sec-bellman-opt>
#link(<sec-bellman-exp-cond>)[第 3 章]与#link(<sec-bellman-exp-explicit>)[第 4 章]针对#strong[任意固定策略] $pi$ 推导了贝尔曼期望方程。强化学习的核心控制目标是寻找能获得最大期望回报的#strong[最优策略] $pi_star$。本章从最优价值函数的定义出发，结合贝尔曼期望方程与不动点理论，推导最优价值函数 $v_star$ 与 $q_star$ 满足的四条#strong[贝尔曼最优方程]。

== 最优策略与最优价值函数
<sec-opt-policy-value>
#strong[定义 5.1（策略的偏序关系与最优价值函数）] <def-5.1> 若策略 $pi$ 在所有状态上的价值均不低于策略 $pi'$，即对任意 $s in cal(S)$ 均有 $v_pi (s) gt.eq v_(pi') (s)$，则称策略 $pi$ 优于或等价于 $pi'$（记为 $pi gt.eq pi'$）。在所有可能策略下达到的最大状态价值与最大动作价值，分别定义为#strong[最优状态价值函数] $v_star$ 与#strong[最优动作价值函数] $q_star$：

$
  v_star (s) eq.dot #mhl($max_pi$) v_pi (s), quad forall s in cal(S) ; #h(2.5em) q_star (s, a) eq.dot #mhl($max_pi$) q_pi (s, a), quad forall (s, a) in cal(S) times cal(A) .
$ <eq-opt-def>

在有限 MDP 且 $gamma in [0, 1)$ 时，有以下两条基本事实成立（其严密存在唯一性由 5.4 节的#link(<thm-5.9>)[定理 5.9] 压缩映射不动点定理保证）：

- #strong[事实 F1（最优价值的上界性）] <fact-f1>：对任意策略 $pi$ 及任意 $s in cal(S), a in cal(A)$，由最大值定义必有：
  $ v_pi (s) lt.eq #mhlg($v_star (s)$), #h(2.5em) q_pi (s, a) lt.eq #mhlg($q_star (s, a)$) . $ <eq-fact-f1>
- #strong[事实 F2（最优策略的存在性）] <fact-f2>：至少存在一个优于或等价于所有其他策略的#strong[最优策略] $pi_star$，它在所有状态和动作上#strong[同时]达到最优价值：
  $
    v_(pi_star) (s) = max_pi v_pi (s) = #mhlg($v_star (s)$), quad q_(pi_star) (s, a) = max_pi q_pi (s, a) = #mhlg($q_star (s, a)$) .
  $ <eq-fact-f2>

#link(<fact-f1>)[事实 F1] 与 #link(<fact-f2>)[事实 F2] 是将 @eq-opt-def 中“对整个策略空间取最大 $max_pi$”化简为递推式中“对单步动作取最大 $max_a$”的关键依据：由于存在同一个最优策略 $pi_star$ 在所有后继状态（或动作）上同时达到最优，带有非负权重的期望或求和算子可与 $max_pi$ 合法交换顺序。

#divider()

== 贝尔曼最优方程（条件期望形式）
<sec-opt-cond>
与#link(<sec-bellman-exp-cond>)[第 3 章]的四条贝尔曼期望方程（@tab-bellman-exp-cond）一一对应，最优价值函数 $v_star$ 与 $q_star$ 之间同样满足四条条件期望形式的贝尔曼最优方程（见 @tab-bellman-opt-cond），其回溯树结构与期望方程的对比见 @fig-expectation-vs-optimality。

#figure(
  caption: [贝尔曼最优方程（条件期望形式）的四类递推关系汇总（各式对所有 $s in cal(S)$ 或 $(s, a) in cal(S) times cal(A)$ 成立）],
  table(
    columns: (auto, 1fr),
    table.header([递推关系], [贝尔曼最优方程（条件期望形式）]),
    table.hline(),
    [$v_star arrow.r q_star$ \ #text(size: 8.2pt, fill: muted)[策略层单步贪心]],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) $],
    [$q_star arrow.r v_star$ \ #text(size: 8.2pt, fill: muted)[环境层单步转换]],
    [$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$v_star arrow.r v_star$ \ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$q_star arrow.r q_star$ \ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) thin divides thin S_t = s, A_t = a] $],
  ),
) <tab-bellman-opt-cond>

#figure(
  diagram(
    spacing: (13mm, 10.5mm),
    node-stroke: 0.8pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0.5, -0.55), [*贝尔曼期望回溯 ($v_pi arrow.r v_pi$)* \ 策略层加权求和 $sum_a pi(a divides s)$], stroke: none, width: 52mm),
    node((0.5, 0), [$v_pi (s)$], radius: 13pt, fill: white),
    edge((0.5, 0), (0, 1), "->", [$pi(a_1 divides s)$], label-side: right),
    edge((0.5, 0), (1, 1), "->", [$pi(a_2 divides s)$], label-side: left),
    node((0, 1), text(fill: white, size: 7.5pt)[$q_pi$], radius: 8.5pt, fill: accent),
    node((1, 1), text(fill: white, size: 7.5pt)[$q_pi$], radius: 8.5pt, fill: accent),
    edge((0, 1), (-0.3, 2), "->", [$p$], label-side: right),
    edge((0, 1), (0.3, 2), "->", [$p$], label-side: left),
    edge((1, 1), (0.7, 2), "->", [$p$], label-side: right),
    edge((1, 1), (1.3, 2), "->", [$p$], label-side: left),
    node((-0.3, 2), [$s'_1$], radius: 9pt, fill: accent-soft),
    node((0.3, 2), [$s'_2$], radius: 9pt, fill: accent-soft),
    node((0.7, 2), [$s'_3$], radius: 9pt, fill: accent-soft),
    node((1.3, 2), [$s'_4$], radius: 9pt, fill: accent-soft),

    node((3.0, -0.55), [*贝尔曼最优回溯 ($v_star arrow.r v_star$)* \ 策略层贪心最大化 $max_a$], stroke: none, width: 52mm),
    node((3.0, 0), [$v_star (s)$], radius: 13pt, fill: white),
    edge((3.0, 0), (2.5, 1), "->", [$a_1$], label-side: right),
    edge((3.0, 0), (3.5, 1), "->", [$a_2$], label-side: left),
    edge((2.65, 0.7), (3.35, 0.7), "-", [$max_a$], bend: 18deg, label-side: center, stroke: 1pt + warn-stroke),
    node((2.5, 1), text(fill: white, size: 7.5pt)[$q_star$], radius: 8.5pt, fill: accent),
    node((3.5, 1), text(fill: white, size: 7.5pt)[$q_star$], radius: 8.5pt, fill: accent),
    edge((2.5, 1), (2.2, 2), "->", [$p$], label-side: right),
    edge((2.5, 1), (2.8, 2), "->", [$p$], label-side: left),
    edge((3.5, 1), (3.2, 2), "->", [$p$], label-side: right),
    edge((3.5, 1), (3.8, 2), "->", [$p$], label-side: left),
    node((2.2, 2), [$s'_1$], radius: 9pt, fill: accent-soft),
    node((2.8, 2), [$s'_2$], radius: 9pt, fill: accent-soft),
    node((3.2, 2), [$s'_3$], radius: 9pt, fill: accent-soft),
    node((3.8, 2), [$s'_4$], radius: 9pt, fill: accent-soft),
  ),
  caption: [贝尔曼期望回溯树（线性加权算子 $cal(T)^pi$）与贝尔曼最优回溯树（非线性最大化算子 $cal(T)^star$）对比],
) <fig-expectation-vs-optimality>

=== 状态价值关于动作价值的最优方程（$v_star arrow.r q_star$）
#strong[定理 5.1（$v_star$ 关于 $q_star$ 的贝尔曼最优方程）] <thm-5.1> 对任意状态 $s in cal(S)$，最优状态价值等于该状态下最优动作价值关于动作 $a in cal(A)$ 的最大值：

$ #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$), quad forall s in cal(S) $]) $ <eq-opt-cond-vq>

#strong[证明]：从定义 $v_star (s) eq.dot max_pi v_pi (s)$（@eq-opt-def）出发，代入#link(<thm-3.1>)[定理 3.1] / #link(<thm-4.1>)[定理 4.1]：
$
  v_star (s) & eq.dot max_pi v_pi (s) = max_pi sum_(a in cal(A)) pi(a divides s) q_pi (s, a) \
  & = max_(pi(dot.op divides s)) sum_(a in cal(A)) pi(a divides s) #mhlb($max_pi q_pi (s, a)$) quad #[（由#link(<fact-f1>)[事实 F1]、#link(<fact-f2>)[事实 F2]，后续时刻取最优策略 $pi_star$）] \
  & = max_(pi(dot.op divides s)) sum_(a in cal(A)) pi(a divides s) #mhlg($q_star (s, a)$) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) . #h(1.5em) square.filled.medium
$
（注：因 $pi(a divides s) gt.eq 0$ 且 $sum_(a in cal(A)) pi(a divides s) = 1$，概率分布加权平均不超过最大项 $max_a q_star (s, a)$；当 $pi(dot.op divides s)$ 将全部概率赋予贪心动作 $a^star in arg max_(a in cal(A)) q_star (s, a)$ 时取等。）

=== 动作价值关于状态价值的最优方程（$q_star arrow.r v_star$）
#strong[定理 5.2（$q_star$ 关于 $v_star$ 的贝尔曼最优方程）] <thm-5.2> 对任意状态-动作对 $(s, a) in cal(S) times cal(A)$，最优动作价值函数满足：

$
  #eqbox([$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [#mhl($R_(t + 1)$) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a], quad forall (s, a) in cal(S) times cal(A) $])
$ <eq-opt-cond-qv>

#strong[证明]：从定义 $q_star (s, a) eq.dot max_pi q_pi (s, a)$ 出发，代入#link(<thm-3.2>)[定理 3.2]（@eq-bellman-exp-qv）：
$
  q_star (s, a) & eq.dot max_pi q_pi (s, a) = max_pi bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s, A_t = a] \
  & = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlb($max_pi v_pi (S_(t + 1))$) divides S_t = s, A_t = a] quad #[（由#link(<fact-f1>)[事实 F1]、#link(<fact-f2>)[F2] 移入 $max_pi$）] \
  & = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] . #h(1.5em) square.filled.medium
$
（注：给定 $S_t = s, A_t = a$ 后，一步转移 $(S_(t + 1), R_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 仅由环境决定，与策略无关，故 $max_pi$ 只作用于后继价值 $v_pi (S_(t + 1))$。）

=== 状态价值的自递推最优方程（$v_star arrow.r v_star$）
#strong[定理 5.3（状态价值的贝尔曼最优方程）] <thm-5.3> 对任意状态 $s in cal(S)$，最优状态价值函数满足：

$
  #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a], quad forall s in cal(S) $])
$ <eq-opt-cond-vv>

#strong[证明]：将#link(<thm-5.2>)[定理 5.2]（@eq-opt-cond-qv）代入#link(<thm-5.1>)[定理 5.1]（@eq-opt-cond-vq）右端的 $q_star (s, a)$，立得 @eq-opt-cond-vv。$square.filled.medium$

=== 动作价值的自递推最优方程（$q_star arrow.r q_star$）
#strong[定理 5.4（动作价值的贝尔曼最优方程）] <thm-5.4> 对任意状态-动作对 $(s, a) in cal(S) times cal(A)$，最优动作价值函数满足：

$
  #eqbox([$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a], quad forall (s, a) in cal(S) times cal(A) $])
$ <eq-opt-cond-qq>

#strong[证明]：对后继状态 $S_(t + 1)$ 应用#link(<thm-5.1>)[定理 5.1] 得 $v_star (S_(t + 1)) = max_(a' in cal(A)) q_star (S_(t + 1), a')$，将其代入#link(<thm-5.2>)[定理 5.2]（@eq-opt-cond-qv）右端，立得 @eq-opt-cond-qq。$square.filled.medium$

#divider()

== 贝尔曼最优方程（显式展开形式及等价写法）
<sec-opt-explicit>
将 5.2 节四条条件期望最优方程中的环境转移期望按概率分布 $p(r divides s, a)$ 与 $p(s' divides s, a)$ 展开，即可直接导出四条显式展开形式的贝尔曼最优方程（汇总见 @tab-bellman-opt-explicit）。

#figure(
  caption: [贝尔曼最优方程（显式展开形式）的四类递推关系汇总（各式对所有 $s in cal(S)$ 或 $(s, a) in cal(S) times cal(A)$ 成立）],
  table(
    columns: (auto, 1fr),
    table.header([递推关系], [贝尔曼最优方程（显式展开形式）]),
    table.hline(),
    [$v_star arrow.r q_star$],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) $],
    [$q_star arrow.r v_star$],
    [$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$) $],
    [$v_star arrow.r v_star$],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$)] $],
    [$q_star arrow.r q_star$],
    [$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhl($max_(a' in cal(A))$) #mhlg($q_star (s', a')$) $],
  ),
) <tab-bellman-opt-explicit>

- #strong[定理 5.5（$v_star arrow.r q_star$ 的展开形式）] <thm-5.5>：已在#link(<thm-5.1>)[定理 5.1] 中直接导出：
  $ #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$), quad forall s in cal(S) $]) $ <eq-opt-explicit-vq>

- #strong[定理 5.6（$q_star arrow.r v_star$ 的展开形式）] <thm-5.6>：由 $q_star (s, a) eq.dot max_pi q_pi (s, a)$ 与#link(<thm-4.2>)[定理 4.2]（@eq-exp-explicit-qv），因 $p(s' divides s, a) gt.eq 0$ 与策略无关，并借助#link(<fact-f2>)[事实 F2]（同一最优策略 $pi_star$ 在所有后继状态上同时最优），将 $max_pi$ 移入求和号内可得：
  $
    #eqbox([$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$), quad forall (s, a) in cal(S) times cal(A) $])
  $ <eq-opt-explicit-qv>

- #strong[定理 5.7（$v_star arrow.r v_star$ 的展开形式）] <thm-5.7>：将#link(<thm-5.6>)[定理 5.6]（@eq-opt-explicit-qv）代入#link(<thm-5.5>)[定理 5.5]（@eq-opt-explicit-vq），可得：
  $
    #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$)], quad forall s in cal(S) $])
  $ <eq-opt-explicit-vv>

- #strong[定理 5.8（$q_star arrow.r q_star$ 的展开形式）] <thm-5.8>：在#link(<thm-5.6>)[定理 5.6] 右端代入 $v_star (s') = max_(a' in cal(A)) q_star (s', a')$，对任意 $(s, a) in cal(S) times cal(A)$ 可得：
  $
    #eqbox([$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhl($max_(a' in cal(A))$) #mhlg($q_star (s', a')$), quad forall (s, a) in cal(S) times cal(A) $])
  $ <eq-opt-explicit-qq>

对比#link(<sec-bellman-exp-explicit>)[第 4 章]的 @tab-bellman-exp-explicit 与本章的 @tab-bellman-opt-explicit 可见，贝尔曼最优方程与贝尔曼期望方程共享完全相同的环境层转移结构，二者的唯一区别是将策略层的加权求和算子 $#mhl($sum_(a in cal(A)) pi(a divides s) (dot.op)$)$ 替换为贪心最大化算子 $#mhl($max_(a in cal(A)) (dot.op)$)$。其联合分布合并形式与期望奖励函数形式对照见 @tab-bellman-opt-variants。

#figure(
  caption: [四条贝尔曼最优方程在联合分布合并形式（Sutton & Barto）与期望奖励函数形式下的完整对照],
  table(
    columns: (auto, auto, 1fr),
    table.header([递推关系], [形式], [公式]),
    table.hline(),
    table.cell(rowspan: 2)[$v_star arrow.r q_star$],
    [联合分布合并形式],
    [$ v_star (s) = max_(a in cal(A)) q_star (s, a) $],
    [期望奖励函数形式],
    [$ v_star (s) = max_(a in cal(A)) q_star (s, a) $],
    table.cell(rowspan: 2)[$q_star arrow.r v_star$],
    [联合分布合并形式],
    [$ q_star (s, a) = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma v_star (s')] $],
    [期望奖励函数形式],
    [$ q_star (s, a) = r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) v_star (s') $],
    table.cell(rowspan: 2)[$v_star arrow.r v_star$],
    [联合分布合并形式],
    [$ v_star (s) = max_(a in cal(A)) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma v_star (s')] $],
    [期望奖励函数形式],
    [$ v_star (s) = max_(a in cal(A)) [r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) v_star (s')] $],
    table.cell(rowspan: 2)[$q_star arrow.r q_star$],
    [联合分布合并形式],
    [$ q_star (s, a) = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma max_(a' in cal(A)) q_star (s', a')] $],
    [期望奖励函数形式],
    [$ q_star (s, a) = r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) max_(a' in cal(A)) q_star (s', a') $],
  ),
) <tab-bellman-opt-variants>

#divider()

== 期望方程与最优方程的数学性质对比：矩阵解析解与压缩映射不动点
<sec-math-comparison-contraction>
+ #strong[贝尔曼期望方程是线性方程组（存在闭式矩阵解析解）]：
  对固定策略 $pi$，记状态空间上的期望奖励向量为 $r_pi in bb(R)^(|cal(S)|)$（其中 $[r_pi]_s eq.dot sum_(a in cal(A)) pi(a divides s) r(s, a)$），策略 $pi$ 诱导的状态转移概率矩阵为 $P_pi in bb(R)^(|cal(S)| times |cal(S)|)$（其中 $[P_pi]_(s, s') eq.dot sum_(a in cal(A)) pi(a divides s) p(s' divides s, a)$），则#link(<thm-4.3>)[定理 4.3]（@eq-exp-explicit-vv）可写成紧凑的向量-矩阵形式：
  $
    v_pi = r_pi + gamma P_pi v_pi quad arrow.l.r.double quad (I - gamma P_pi) v_pi = r_pi quad arrow.r.double quad #eqbox([$ v_pi = #mhl($(I - gamma P_pi)^(-1)$) r_pi $])
  $ <eq-matrix-bellman>
  因 $P_pi$ 为行随机矩阵（谱半径 $rho(P_pi) = 1$），当 $gamma in [0, 1)$ 时，矩阵 $(I - gamma P_pi)$ 严格行对角占优（Strictly Row Diagonally Dominant）且满秩可逆，既可通过矩阵求逆直接解出解析解（时间复杂度 $O(|cal(S)|^3)$），也可通过不动点迭代求解。

+ #strong[贝尔曼最优方程是非线性方程组（依赖压缩映射不动点迭代）]：
  由于含有最大化算子 $max_a$，贝尔曼最优方程是非线性方程组，无法直接通过矩阵求逆求解。其解的存在唯一性与迭代收敛性由如下压缩映射定理保证：

#strong[定理 5.9（贝尔曼算子的 $gamma$-压缩性与 Banach 不动点定理）] <thm-5.9> 在完备度量空间 $(bb(R)^(|cal(S)|), norm(dot.op)_oo)$（最大模范数定义为 $norm(V)_oo eq.dot max_(s in cal(S)) |V(s)|$）上，定义贝尔曼期望算子 $cal(T)^pi$ 与贝尔曼最优算子 $cal(T)^star$ 为：
$
  (cal(T)^pi V)(s) & eq.dot sum_(a in cal(A)) pi(a divides s) [r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) V(s')], \
  (cal(T)^star V)(s) & eq.dot max_(a in cal(A)) [r(s, a) + gamma sum_(s' in cal(S)) p(s' divides s, a) V(s')] .
$ <eq-bellman-operators>
当 $gamma in [0, 1)$ 时，$cal(T)^pi$ 与 $cal(T)^star$ 均满足 $gamma$-压缩性质：
$
  #eqbox([$ norm(cal(T)^pi V - cal(T)^pi U)_oo lt.eq #mhl($gamma$) norm(V - U)_oo, #h(2em) norm(cal(T)^star V - cal(T)^star U)_oo lt.eq #mhl($gamma$) norm(V - U)_oo $])
$ <eq-contraction-property>
因此，方程 $V = cal(T)^pi V$ 与 $V = cal(T)^star V$ 分别存在#strong[唯一]的不动点 $v_pi$ 与 $v_star$，且从任意初值 $V_0$ 出发的迭代序列 $V_(k + 1) = cal(T)^pi V_k$ 与 $V_(k + 1) = cal(T)^star V_k$ 必以至少 $gamma^k$ 的线性速率几何收敛于唯一解。

#strong[证明]：利用最大值差值不等式 $|max_a f(a) - max_a g(a)| lt.eq max_a |f(a) - g(a)|$ 与转移概率归一性 $sum_(s') p(s' divides s, a) = 1$，对任意状态 $s in cal(S)$ 有：
$
  |(cal(T)^star V)(s) - (cal(T)^star U)(s)| & lt.eq max_(a in cal(A)) |gamma sum_(s' in cal(S)) p(s' divides s, a) [V(s') - U(s')]| \
  & lt.eq #mhl($gamma$) max_(a in cal(A)) sum_(s' in cal(S)) p(s' divides s, a) #mhlb($norm(V - U)_oo$) = #mhl($gamma$) norm(V - U)_oo .
$
对左端关于 $s in cal(S)$ 取最大值即得 $norm(cal(T)^star V - cal(T)^star U)_oo lt.eq gamma norm(V - U)_oo$（将 $max_a$ 替换为加权和 $sum_a pi(a divides s)$ 同理可得 $cal(T)^pi$ 的 $gamma$-压缩性）。由 Banach 不动点定理立得唯一不动点的存在性与迭代收敛性。$square.filled.medium$

#divider()

// ============================================================
//  第 6 章：期望值估计理论与状态/动作价值估计方法
// ============================================================
= 期望值估计：从方程到算法
<sec-value-estimation>

#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-opt>)[5 章]建立了状态价值（$v_pi, v_star$）与动作价值（$q_pi, q_star$）满足的八条贝尔曼方程，它们构成了强化学习价值分析的理论基础。这八条方程均可统一表述为如下#strong[算子不动点方程]：方程右端的贝尔曼算子 $cal(T)$ 作用于未知价值函数，左端即为该价值函数本身。因此，求解贝尔曼方程等价于求解算子 $cal(T)$ 的唯一不动点：
$
  x = cal(T) x, #h(2em) x in {v_pi, q_pi, v_star, q_star}, #h(1em) cal(T) thin upright("为对应的贝尔曼算子") .
$ <eq-ch6-fixed-point-shell>

由此出发，价值函数求解算法具有统一的迭代骨架：#strong[不动点迭代] $x_(k + 1) = cal(T) x_k$。将算子 $cal(T)$ 展开可见，其核心运算是条件数学期望 $bb(E) [dot.op divides dot.op]$——在价值函数的原始定义中表现为 $bb(E) [G_t divides S_t = s]$，而在单步递推的条件期望形式中表现为 $bb(E) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$。因此，#strong[如何在每一步迭代中计算或估计算子作用结果 $cal(T) x_k$]，取决于以下两个正交维度上的方法选择：
1. #strong[如何计算或估计条件期望 $bb(E) [X divides C]$（环境模型是否已知）]：当环境模型 $p(s', r divides s, a)$ 已知时，条件期望可通过显式概率加权求和精确计算；当环境模型未知（Model-Free）时，则必须从智能体与环境交互产生的随机轨迹样本中#strong[估计期望值]。
2. #strong[如何处理未来回报 $G_(t + 1)$ 的递推依赖（是否采用自举递推）]：是直接采样完整轨迹直到底层终止以观测真实回报 $G_t$（#strong[不自举]，No Bootstrapping），还是利用贝尔曼方程的一步递推关系，用当前对后继价值的估计量 $V(S_(t + 1))$ 或 $Q(S_(t + 1), dot.op)$ 替代真实未来回报期望（#strong[自举]，Bootstrapping）。

上述两个正交维度的组合导出了本章的三条基本估计路线：模型已知时的“精确期望 + 自举”对应#strong[动态规划（DP）]；模型未知时的“采样 + 不自举”对应#strong[蒙特卡洛（MC）]方法；模型未知时的“采样 + 自举”对应#strong[时序差分（TD）]学习。在此基础上，针对离轨学习中的采样分布偏移、无模型最优控制中的贪心最大化以及离轨多步估计中的乘性方差失控，又进一步衍生出三项#strong[核心扩展机制]——这一整体理论脉络见 @fig-estimation-routes。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (6mm, 7mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,
      node((1, 0), text(size: 7.8pt)[*统一骨架：不动点迭代* \ $x_(k+1) = cal(T) x_k$ \ 核心问题：如何计算或估计内含的条件期望 $bb(E)[dot.op divides dot.op]$], fill: accent-soft, width: 62mm),
      node((0, 1), text(size: 7.6pt)[*路线一：精确期望 + 自举* \ （6.2 节）目标 $= cal(T) x_k$ 显式求和 \ 模型已知 $p(s', r divides s, a)$ \ 动态规划（DP）], stroke: 0.85pt + hl-blue-stroke, fill: hl-blue-fill, width: 44mm),
      node((1, 1), text(size: 7.6pt)[*路线二：采样 + 不自举* \ （6.3 节）目标 $= G_t$，采样至终止 \ 模型未知，直接依价值定义估计 \ 蒙特卡洛（MC）], stroke: 0.85pt + warn-stroke, fill: warn-soft, width: 44mm),
      node((2, 1), text(size: 7.6pt)[*路线三：采样 + 自举* \ （6.5 节）目标 $= R_(t+1) + gamma V(S_(t+1))$ \ 模型未知，以当前估计替代后继真值 \ 时序差分（TD）], stroke: 0.85pt + hl-green-stroke, fill: hl-green-fill, width: 44mm),
      node((1, 2), text(size: 7.4pt)[*三项核心扩展机制*：分布偏移修正、最优控制与多步方差控制 \ 6.4 重要性采样 · 6.6 动作价值与无模型控制 · 6.7 离轨多步方差控制], stroke: (dash: "dashed", paint: muted, thickness: 0.6pt), width: 64mm),
      edge((1, 0), (0, 1), "->", text(size: 6.8pt)[模型已知 \ 自举], label-side: right),
      edge((1, 0), (1, 1), "->", text(size: 6.8pt)[模型未知 \ 不自举], label-side: right),
      edge((1, 0), (2, 1), "->", text(size: 6.8pt)[模型未知 \ 自举], label-side: left),
      edge((1, 1), (1, 2), "->", stroke: (dash: "dashed", paint: muted, thickness: 0.6pt)),
    )
  },
  caption: [本章的理论脉络：贝尔曼方程给出统一的不动点骨架，根据“环境模型是否已知”与“是否采用自举”导出动态规划（精确期望 + 自举）、蒙特卡洛（采样 + 不自举）与时序差分（采样 + 自举）三条基本路线；针对采样分布偏移、无模型最优控制与离轨多步高方差，进一步建立三项核心扩展机制],
) <fig-estimation-routes>

本章首先建立这一统一框架所依赖的三类数学工具（#link(<sec-expectation-estimation-theory>)[第 6.1 节]）；随后依次阐述三条基本估计路线：模型已知时的精确期望与自举不动点迭代（#link(<sec-dp-fixed-point>)[第 6.2 节]）、模型未知时的完整轨迹采样估计（#link(<sec-mc-estimation>)[第 6.3 节]）、模型未知时的采样结合自举递推（#link(<sec-td-estimation>)[第 6.5 节]）；在此过程中系统论述三项核心扩展机制：离轨策略评估与重要性采样（#link(<sec-importance-sampling>)[第 6.4 节]）、动作价值估计与无模型控制算法族（#link(<sec-td-action-value>)[第 6.6 节]）、离轨多步估计的方差控制（#link(<sec-offpolicy-multistep>)[第 6.7 节]）；最后横向对比各方法的统计特征、回溯结构与理论性质（#link(<sec-estimation-comparison>)[第 6.8 节]）。

#divider()

== 期望值估计的统一视角与三类数学工具
<sec-expectation-estimation-theory>

@fig-estimation-routes 中的三类估计路线均可归纳为如下#strong[通用增量更新形式（General Incremental Update Form）]——它与#link(<sec-robbins-monro-theory>)[第 6.1.3 节]的 Robbins-Monro 随机近似迭代式（@eq-robbins-monro-update）以及蒙特卡洛的增量样本均值公式（@eq-incremental-mean）具有完全一致的代数结构：
$
  #eqbox([$ x arrow.l x + #mhl($alpha_k$) [#mhlg($y_k$) - x] $])
$ <eq-ch6-update-shell>
其中 $x$ 为待估计的价值变量，$y_k$ 为第 $k$ 次更新所构造的#strong[目标值]（Target），$alpha_k$ 为更新步长（在确定性全宽同步更新中取 $alpha_k = 1$ 即退化为直接赋值 $x arrow.l y_k$）。不同估计算法之间的本质差异体现在以下#strong[三个核心设计维度]上：

1. #strong[目标值 $y_k$ 的构造方式]：是利用已知模型显式计算后继价值估计的条件期望（路线一：DP），还是采样完整轨迹至终止状态以获取真实回报 $G_t$（路线二：MC），抑或采样单步（或有限步）转移后结合当前价值估计进行自举（路线三：TD）。这直接决定了算法#strong[是否依赖环境模型]以及#strong[更新目标是否存在自举偏差]。
2. #strong[行为策略与目标策略的一致性]：当生成样本的行为策略 $b$ 与待评估的目标策略 $pi$ 一致（同轨，On-Policy）时，轨迹样本可直接用于估计目标期望；当二者不一致（离轨，Off-Policy）且目标依赖于策略 $pi$ 下的动作期望时，必须引入#strong[重要性采样]对样本分布偏差进行修正（见#link(<sec-importance-sampling>)[第 6.4 节]核心扩展一）。
3. #strong[汇聚样本的统计更新机制]：是采用精确概率加权求和（路线一），还是基于大数定律的经验样本均值（路线二），抑或基于 Robbins-Monro 随机近似理论的在线递推更新（路线三）。三类统计机制的收敛性质分别由下文三小节的数学定理给出严格保证。

#figure(
  caption: [三条基本估计路线在核心设计维度上的特征对比。三者共享通用更新形式 @eq-ch6-update-shell，核心区别在于目标值 $y_k$ 的构造方式、是否自举及所依托的收敛理论],
  text(size: 8.6pt, table(
    columns: (26mm, 1fr, 1fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([设计维度], [路线一：动态规划（DP）], [路线二：蒙特卡洛（MC）], [路线三：时序差分（TD）]),
    table.hline(),
    [环境模型], [必须已知], [无需已知（免模型）], [无需已知（免模型）],
    [目标值 $y_k$], [$cal(T) x_k$（精确期望 + 自举）], [$G_t$（完整轨迹回报）], [$R_(t+1) + gamma V(S_(t+1))$（采样 + 自举）],
    [理论基础], [压缩映射与显式概率求和], [大数定律 · 经验样本均值], [Robbins-Monro 随机近似],
    [目标是否自举], [是（用当前估计 $V_k$ 递推）], [否（采样至轨迹终止）], [是（用当前估计 $V$ 替代未来）],
    [目标是否有偏], [无采样偏差；收敛前含初值 $V_0$ 的自举截断误差（按 $gamma^k$ 衰减）], [无偏（首次访问协议下）], [有偏（源于自举估计与有限样本）],
    [方差来源], [无随机采样方差], [整幕轨迹随机性，随幕长增长], [单步转移随机性，方差显著更低],
    [与贝尔曼方程的关系], [基于显式展开式迭代求解不动点], [不经一步递推，直接依价值定义采样], [基于条件期望递推式做随机近似],
  )),
) <tab-three-routes>

=== 基于压缩映射的不动点迭代理论（已知分布下的精确期望）
<sec-fixed-point-theory-detail>
当环境转移模型 $p(s', r divides s, a)$ 与策略 $pi(a divides s)$ 完全已知时，贝尔曼方程右端的条件期望可按#link(<sec-bellman-exp-explicit>)[第 4 章]与#link(<sec-opt-explicit>)[第 5.3 节]的显式展开式精确求值。此时求解价值函数等价于在完备赋范线性空间（Banach 空间）中求解算子不动点方程 $x = cal(T) x$。

除了#link(<thm-5.9>)[定理 5.9] 定义的状态价值算子 $cal(T)^pi_V, cal(T)^star_V : bb(R)^(|cal(S)|) arrow.r bb(R)^(|cal(S)|)$ 外，在动作价值空间 $(bb(R)^(|cal(S)| times |cal(A)|), norm(dot.op)_oo)$（其中 $norm(Q)_oo eq.dot max_(s, a) |Q(s, a)|$）上可同样定义#strong[动作价值贝尔曼期望算子 $cal(T)^pi_Q$] 与#strong[动作价值贝尔曼最优算子 $cal(T)^star_Q$]：
$
  (cal(T)^pi_Q Q)(s, a) & eq.dot sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($Q(s', a')$)], \
  (cal(T)^star_Q Q)(s, a) & eq.dot sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhl($max_(a' in cal(A))$) #mhlg($Q(s', a')$)] .
$ <eq-q-bellman-operators>

#strong[命题 6.1（四类贝尔曼算子的统一 $gamma$-压缩性与不动点迭代误差界）] <prop-6.1> 当 $gamma in [0, 1)$ 时，$cal(T)^pi_V, cal(T)^star_V, cal(T)^pi_Q, cal(T)^star_Q$ 在最大模范数 $norm(dot.op)_oo$ 下均为 $gamma$-压缩映射。设 $cal(T)$ 为其中任一算子，$x^star$ 为其唯一不动点（即 $v_pi, v_star, q_pi$ 或 $q_star$），对任意初值 $x_0$ 生成的不动点迭代序列 $x_(k + 1) = cal(T) x_k$，满足如下先验与后验截断误差界：
$
  #eqbox([$ norm(x_k - x^star)_oo lt.eq #mhl($frac(gamma^k, 1 - gamma)$) norm(x_1 - x_0)_oo quad & upright("（先验界）") \ norm(x_k - x^star)_oo lt.eq #mhl($frac(gamma, 1 - gamma)$) norm(x_k - x_(k - 1))_oo quad & upright("（后验界）") $])
$ <eq-fixed-point-error-bound>

#strong[证明]：$cal(T)^pi_Q$ 与 $cal(T)^star_Q$ 的 $gamma$-压缩性证明与#link(<thm-5.9>)[定理 5.9] 完全同构：利用 $|max_(a') Q_1(s', a') - max_(a') Q_2(s', a')| lt.eq max_(a') |Q_1(s', a') - Q_2(s', a')| lt.eq norm(Q_1 - Q_2)_oo$ 及 $sum_(s', r) p(s', r divides s, a) = 1$ 即得 $norm(cal(T)^star_Q Q_1 - cal(T)^star_Q Q_2)_oo lt.eq gamma norm(Q_1 - Q_2)_oo$。进而由三角不等式与压缩性质：
$
  norm(x_k - x^star)_oo & = norm(cal(T) x_(k - 1) - cal(T) x^star)_oo lt.eq gamma norm(x_(k - 1) - x^star)_oo \
  & lt.eq gamma [norm(x_(k - 1) - x_k)_oo + norm(x_k - x^star)_oo] .
$
移项整理 $(1 - gamma) norm(x_k - x^star)_oo lt.eq gamma norm(x_k - x_(k - 1))_oo$ 即得后验误差界；再由递推 $norm(x_k - x_(k - 1))_oo lt.eq gamma^(k - 1) norm(x_1 - x_0)_oo$ 代入即得先验误差界。$square.filled.medium$

#strong[算法意义]：@eq-fixed-point-error-bound 的后验误差界为动态规划给出可计算的停止准则：若要求最终价值估计误差不超过 $epsilon$，只需在相邻两次迭代的最大残差（Bellman Residual）满足 $norm(x_k - x_(k - 1))_oo lt.eq frac(1 - gamma, gamma) epsilon$ 时终止迭代即可。

=== 基于大数定律的蒙特卡洛期望估计（样本均值与增量式更新）
<sec-mc-expectation-theory>
当环境概率分布未知、但可对随机变量 $X$（如从状态 $s$ 出发的完整轨迹折扣回报 $G_t$）进行独立同分布（i.i.d.）采样获得样本序列 ${x_1, x_2, dots.h, x_N}$ 时，欲估计总体数学期望 $mu eq.dot bb(E) [X]$（设方差 $upright("Var")(X) = sigma^2 < oo$），最直接的统计估计量是#strong[经验样本均值]（Empirical Mean）：
$
  hat(mu)_N eq.dot #mhl($frac(1, N) sum_(i = 1)^N x_i$) .
$ <eq-mc-sample-mean>

#strong[命题 6.2（蒙特卡洛样本均值的统计性质与增量递推公式）] <prop-6.2> 设 ${X_i}_(i = 1)^N$ 独立同分布且 $bb(E) [X_i] = mu, upright("Var")(X_i) = sigma^2 < oo$，则样本均值估计量 $hat(mu)_N$ 满足：
1. #strong[无偏性与方差衰减]：对任意样本量 $N gt.eq 1$，$hat(mu)_N$ 是 $mu$ 的无偏估计，且均方误差（方差）以 $O(1 \/ N)$ 速率衰减：
   $
     bb(E) [hat(mu)_N] = mu, #h(2.5em) upright("MSE")(hat(mu)_N) = upright("Var")(hat(mu)_N) = #mhlb($frac(sigma^2, N)$) arrow.r_(N arrow.r oo) 0 .
   $ <eq-mc-unbiased-var>
2. #strong[强大数定律保证的一致收敛性]：由 Kolmogorov 强大数定律，当采样次数 $N arrow.r oo$ 时，$hat(mu)_N$ 以概率 $1$（几乎处处，almost surely）收敛于真实期望 $mu$，即 $Pr(lim_(N arrow.r oo) hat(mu)_N = mu) = 1$。
3. #strong[增量式更新恒等式（Incremental Mean Update）]：无需在内存中存储全部历史样本 ${x_1, dots.h, x_N}$，$hat(mu)_N$ 可由上一时刻估计值 $hat(mu)_(N - 1)$ 与新样本 $x_N$ 仅以 $O(1)$ 时间与空间开销递推更新：
   $
     #eqbox([$ hat(mu)_N = hat(mu)_(N - 1) + #mhl($frac(1, N)$) (#mhlg($x_N$) - hat(mu)_(N - 1)) $])
   $ <eq-incremental-mean>

#strong[证明（增量式更新公式）]：将 @eq-mc-sample-mean 的前 $N - 1$ 项分离并代入 $sum_(i = 1)^(N - 1) x_i = (N - 1) hat(mu)_(N - 1)$：
$
  hat(mu)_N & = frac(1, N) (sum_(i = 1)^(N - 1) x_i + x_N) = frac(1, N) [(N - 1) hat(mu)_(N - 1) + x_N] \
  & = frac(N hat(mu)_(N - 1) - hat(mu)_(N - 1) + x_N, N) = hat(mu)_(N - 1) + #mhl($frac(1, N)$) (#mhlg($x_N$) - hat(mu)_(N - 1)) . #h(2em) square.filled.medium
$

#strong[非平稳环境或策略演进下的常步长指数移动平均（EMA）]：在强化学习的控制过程中，策略 $pi$ 会随价值估计的更新而不断改进，导致回报分布随时间发生漂移（非平稳，Non-stationary）。此时若仍采用衰减步长 $alpha_N = 1 \/ N$，早期过时策略产生的样本将与最新样本享有相同权重 $1 \/ N$。工程上常将 $1 \/ N$ 替换为常数步长 $alpha in (0, 1]$，展开递推式可得：
$
  hat(mu)_N = hat(mu)_(N - 1) + alpha (x_N - hat(mu)_(N - 1)) = #mhlb($(1 - alpha)^N$) hat(mu)_0 + sum_(i = 1)^N #mhl($alpha (1 - alpha)^(N - i)$) x_i .
$ <eq-ema-expansion>
由于权重满足 $(1 - alpha)^N + sum_(i = 1)^N alpha (1 - alpha)^(N - i) = 1$，且越早的样本 $x_i$ 其权重 $(1 - alpha)^(N - i)$ 呈指数衰减，常步长更新能够快速遗忘旧策略的历史样本、追踪最新分布的期望值。

=== 基于 Robbins-Monro 理论的随机近似估计（带噪求根与在线步长准则）
<sec-robbins-monro-theory>
更一般地，许多期望估计与算子不动点问题均可统一表述为#strong[含噪函数的求根问题]（Stochastic Root-Finding Problem）。设目标是求解关于参数 $w$ 的确定性方程：
$
  g(w) eq.dot bb(E)_Y [#mhlb($w - Y$)] = w - bb(E) [Y] = 0 quad arrow.l.r.double quad w^star = bb(E) [Y] .
$ <eq-rm-root-problem>
在无模型设定下，由于随机变量 $Y$ 的分布未知，无法直接计算函数值 $g(w)$，但在每次交互步 $k$ 可以获得 $Y$ 的一个带噪观测样本 $y_k = bb(E) [Y] + eta_k$（其中 $eta_k$ 为零均值随机噪声，$bb(E) [eta_k divides cal(F)_(k - 1)] = 0$），从而构造出 $g(w_k)$ 的无偏随机观测：
$
  tilde(g)(w_k, eta_k) eq.dot w_k - y_k = g(w_k) - eta_k .
$ <eq-rm-noisy-obs>

#strong[定理 6.1（Robbins-Monro 随机近似收敛定理，1951）] <thm-6.1> 针对求根问题 $g(w) = 0$，构造如下随机近似迭代序列：
$
  #eqbox([$ w_(k + 1) = w_k - #mhl($alpha_k$) tilde(g)(w_k, eta_k) = w_k + #mhl($alpha_k$) (#mhlg($y_k$) - w_k) $])
$ <eq-robbins-monro-update>
若满足以下三条核心条件：
1. #strong[单调强恢复性质]：$g(w)$ 连续且在唯一根 $w^star$ 处满足 $(w - w^star) g(w) > 0$（对任意 $w eq.not w^star$），并在全局满足线性增长界；
2. #strong[鞅差分有界方差噪声]：条件期望噪声满足 $bb(E) [eta_k divides cal(F)_(k - 1)] = 0$ 且条件方差有界 $bb(E) [eta_k^2 divides cal(F)_(k - 1)] lt.eq sigma^2 < oo$（其中 $cal(F)_(k - 1)$ 为至第 $k - 1$ 步的历史 $sigma$-代数）；
3. #strong[Robbins-Monro 步长条件]：正步长序列 ${alpha_k}_(k = 1)^oo$ 满足：
   $
     #eqbox([$ sum_(k = 1)^oo #mhl($alpha_k$) = oo, #h(3em) sum_(k = 1)^oo #mhl($alpha_k^2$) < oo $])
   $ <eq-rm-step-conditions>
则迭代序列 ${w_k}$ 以概率 $1$ 收敛于真实期望根 $w^star = bb(E) [Y]$（即 $Pr(lim_(k arrow.r oo) w_k = w^star) = 1$）。

#strong[收敛机理与直觉剖析]：记第 $k$ 步的估计误差为 $e_k eq.dot w_k - w^star$，对于期望估计问题 $g(w_k) = w_k - w^star = e_k$，将 @eq-robbins-monro-update 两边减去 $w^star$ 并对两边平方取条件期望（利用 $bb(E) [eta_k divides cal(F)_(k - 1)] = 0$ 消去交叉项）：
$
  e_(k + 1) & = w_k - w^star + alpha_k (w^star + eta_k - w_k) = #mhlb($(1 - alpha_k) e_k$) + #mhlg($alpha_k eta_k$), \
  bb(E) [e_(k + 1)^2 divides cal(F)_(k - 1)] & = #mhlb($(1 - alpha_k)^2 e_k^2$) + #mhlg($alpha_k^2 bb(E) [eta_k^2 divides cal(F)_(k - 1)]$) lt.eq (1 - alpha_k)^2 e_k^2 + alpha_k^2 sigma^2 .
$ <eq-rm-error-recursion>
@eq-rm-error-recursion 给出两个步长条件的含义：
- #strong[第一条件 $sum_(k = 1)^oo alpha_k = oo$（步长不能衰减过快）]：对最终满足 $0 < alpha_k < 1$ 的步长，确定性收缩因子满足 $product_(k = 1)^N (1 - alpha_k) lt.eq exp(- sum_(k = 1)^N alpha_k)$，故 $sum alpha_k = oo$ 足以保证 $product (1 - alpha_k) arrow.r 0$，即无论初始估计 $w_0$ 距离真值 $w^star$ 多远，算法都有足够的累积步幅完全消除初始偏差 $e_0$。
- #strong[第二条件 $sum_(k = 1)^oo alpha_k^2 < oo$（步长必须最终趋于零以抑制采样噪声）]：每一步注入的随机噪声方差项为 $alpha_k^2 sigma^2$，只有当平方和 $sum alpha_k^2 < oo$ 时，无穷步累计的噪声方差总和才有界，且 $alpha_k arrow.r 0$ 使得迭代在逼近真值 $w^star$ 后不再受单次采样噪声 $eta_k$ 干扰而发生永恒震荡。
- #strong[特例验证]：调和级数步长 $alpha_k = frac(1, k)$ 同时满足 $sum_(k = 1)^oo frac(1, k) = oo$ 与 $sum_(k = 1)^oo frac(1, k^2) = frac(pi^2, 6) < oo$。将 $alpha_k = frac(1, k)$ 代入 @eq-robbins-monro-update，即为#link(<prop-6.2>)[命题 6.2] 的蒙特卡洛增量均值公式（@eq-incremental-mean）。更一般的步长形式为 $alpha_k = frac(c, (k + k_0)^p)$（其中 $p in (0.5, 1]$）。

#divider()

== 路线一 · 基于不动点理论的动态规划估计（模型已知：精确期望 + 自举）
<sec-dp-fixed-point>
当环境模型 $p(s', r divides s, a)$ 完全已知时，无需求助于轨迹采样，可直接利用#link(<sec-fixed-point-theory-detail>)[第 6.1 节]的压缩映射不动点理论，对#link(<sec-bellman-exp-explicit>)[第 4 章]与#link(<sec-opt-explicit>)[第 5.3 节]的#strong[显式展开形式贝尔曼方程]构造确定性不动点迭代算法。下面分别列出针对#strong[状态价值（$v_pi, v_star$）]与#strong[动作价值（$q_pi, q_star$）]的不动点估计算法。这是三条路线中唯一能给出#strong[确定性误差界]的一条（@eq-fixed-point-error-bound），代价是必须完整知道 $p(s', r divides s, a)$：一旦模型未知，右端的加权求和 $sum_(s', r) p(s', r divides s, a) [dot.op]$ 就无从计算，只能转向路线二与路线三。

=== 状态价值的不动点迭代估计（$v_pi$ 迭代评估与 $v_star$ 值迭代算法）
<sec-dp-state-value>
1. #strong[迭代策略评估（Iterative Policy Evaluation，估计固定策略状态价值 $v_pi$）]：
   依据#link(<thm-4.3>)[定理 4.3] 的 $v_pi arrow.r v_pi$ 贝尔曼期望展开方程（@eq-exp-explicit-vv），将状态价值贝尔曼期望算子 $cal(T)^pi_V$ 直接转化为不动点迭代公式。从任意初始向量 $V_0 in bb(R)^(|cal(S)|)$ 出发，第 $k + 1$ 轮对所有 $s in cal(S)$ 执行全宽回溯（Full-Width Backup）：
   $
     #eqbox([$ V_(k + 1) (s) arrow.l (cal(T)^pi_V V_k)(s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhlg($V_k (s')$)] $])
   $ <eq-dp-policy-eval-v>
   由#link(<prop-6.1>)[命题 6.1]，当 $k arrow.r oo$ 时，$V_k$ 以线性速率 $O(gamma^k)$ 几何收敛于唯一不动点 $v_pi$。在实际计算中，既可使用双数组做#strong[同步更新]（Synchronous Update），也可在单数组上直接覆盖做#strong[就地异步更新]（In-place / Gauss-Seidel Update，$V(s) arrow.l sum_a pi(a divides s) sum_(s', r) p(s', r divides s, a) [r + gamma V(s')]$），后者同样保收敛且通常收敛更快。

2. #strong[策略迭代算法（Policy Iteration，交替评估 $v_pi$ 与贪心改进逼近 $v_star$）]：
   在获得当前策略 $pi_k$ 的精确状态价值 $v_(pi_k)$ 后，利用#link(<thm-4.2>)[定理 4.2] 的 $q_pi arrow.r v_pi$ 桥接方程计算动作价值 $q_(pi_k) (s, a) = sum_(s', r) p(s', r divides s, a) [r + gamma v_(pi_k) (s')]$，进而构造贪心改进策略：
   $
     pi_(k + 1) (s) in #mhl($arg max_(a in cal(A))$) q_(pi_k) (s, a) = #mhl($arg max_(a in cal(A))$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhlg($v_(pi_k) (s')$)] .
   $ <eq-policy-improvement>
   #strong[策略改进定理（Policy Improvement Theorem）]保证：因对任意 $s$ 有 $q_(pi_k) (s, pi_(k + 1)(s)) = max_a q_(pi_k) (s, a) gt.eq sum_a pi_k (a divides s) q_(pi_k) (s, a) = v_(pi_k) (s)$，即 $(cal(T)^(pi_(k + 1))_V v_(pi_k))(s) gt.eq v_(pi_k) (s)$，由于 $cal(T)^(pi_(k + 1))_V$ 的权重 $pi_(k + 1)(a divides s) p(s', r divides s, a)$ 非负，该算子保序（$V lt.eq V'$ 蕴含 $cal(T)^(pi_(k + 1))_V V lt.eq cal(T)^(pi_(k + 1))_V V'$），反复迭代可得 $v_(pi_(k + 1)) = lim_(m arrow.r oo) (cal(T)^(pi_(k + 1))_V)^m v_(pi_k) gt.eq v_(pi_k)$。由于有限 MDP 的确定性平稳策略总数 $|cal(A)|^(|cal(S)|)$ 有限，交替执行“策略评估（@eq-dp-policy-eval-v）$arrow.r$ 策略改进（@eq-policy-improvement）”必在有限步内收敛于满足贝尔曼最优方程的最优价值 $v_star$ 与最优策略 $pi_star$。

3. #strong[值迭代算法（Value Iteration，基于贝尔曼最优算子 $cal(T)^star_V$ 直接估计 $v_star$）]：
   策略迭代在每一外层循环中都需要等待内层策略评估（@eq-dp-policy-eval-v）无穷步迭代收敛到精确 $v_(pi_k)$，计算开销较大。若将策略评估过程#strong[截断为仅执行一步更新]，并立即与策略改进（@eq-policy-improvement）的 $max_a$ 算子合并，则等价于直接对#link(<thm-5.7>)[定理 5.7] 的 $v_star arrow.r v_star$ 贝尔曼最优展开方程（@eq-opt-explicit-vv）应用 Banach 不动点迭代，更新律为：
   $
     #eqbox([$ V_(k + 1) (s) arrow.l (cal(T)^star_V V_k)(s) = #mhl($max_(a in cal(A))$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhlg($V_k (s')$)], quad forall s in cal(S) $])
   $ <eq-value-iteration>
   当迭代满足后验停止准则 $max_(s in cal(S)) |V_(k + 1) (s) - V_k (s)| < frac(1 - gamma, gamma) epsilon$ 时，由 @eq-fixed-point-error-bound 有 $norm(V_(k + 1) - v_star)_oo < epsilon$。随后以 $V_(k + 1)$ 代替 $v_star$ 代入 $q_star arrow.r v_star$ 展开式（#link(<thm-5.6>)[定理 5.6]）提取贪心策略：
   $
     pi(s) in #mhl($arg max_(a in cal(A))$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhlg($V_(k + 1) (s')$)] .
   $ <eq-vi-extract-policy>
   该策略满足 $norm(v_pi - v_star)_oo lt.eq frac(2 gamma epsilon, 1 - gamma)$（Singh & Yee, 1994）；由于有限 MDP 中各次优确定性策略与 $v_star$ 的差距有正下界，$epsilon$ 足够小时 $pi$ 即为最优策略。

=== 动作价值的不动点迭代估计（$q_pi$ 迭代评估与 $Q$-值迭代算法）
<sec-dp-action-value>
与状态价值完全对称，若直接在状态-动作空间 $cal(S) times cal(A)$ 上应用算子 $cal(T)^pi_Q$ 与 $cal(T)^star_Q$（@eq-q-bellman-operators），则可得到动作价值的两类不动点估计算法：

1. #strong[动作价值迭代策略评估（$Q$-Policy Evaluation，估计固定策略动作价值 $q_pi$）]：
   依据#link(<thm-4.4>)[定理 4.4] 的 $q_pi arrow.r q_pi$ 展开方程（@eq-exp-explicit-qq），对所有 $(s, a) in cal(S) times cal(A)$ 迭代更新：
   $
     #eqbox([$ Q_(k + 1) (s, a) arrow.l (cal(T)^pi_Q Q_k)(s, a) = sum_(s', r) p(s', r divides s, a) [r + gamma sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($Q_k (s', a')$)] $])
   $ <eq-dp-policy-eval-q>

2. #strong[动作价值迭代算法（$Q$-Value Iteration，基于 $q_star arrow.r q_star$ 直接估计 $q_star$）]：
   依据#link(<thm-5.8>)[定理 5.8] 的 $q_star arrow.r q_star$ 贝尔曼最优展开方程（@eq-opt-explicit-qq），直接应用压缩算子 $cal(T)^star_Q$ 迭代：
   $
     #eqbox([$ Q_(k + 1) (s, a) arrow.l (cal(T)^star_Q Q_k)(s, a) = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) [r + gamma #mhl($max_(a' in cal(A))$) #mhlg($Q_k (s', a')$)] $])
   $ <eq-q-value-iteration>
   一旦 $Q_k$ 收敛于唯一不动点 $q_star$，提取最优策略无需再查询环境模型 $p(s', r divides s, a)$，只需直接做点态最大化 $pi_star (s) in arg max_(a in cal(A)) q_star (s, a)$。#link(<sec-td-action-value>)[第 6.6 节]的 Q-Learning 是 @eq-q-value-iteration 在模型未知时的随机近似版本。

#divider()

== 路线二 · 基于蒙特卡洛（Monte Carlo）方法的价值估计（模型未知：采样 + 不自举）
<sec-mc-estimation>
当环境模型 $p(s', r divides s, a)$ 未知时，无法执行#link(<sec-dp-fixed-point>)[第 6.2 节]中的显式概率求和 $sum_(s', r) p(s', r divides s, a) [dot.op]$，即无法沿马尔可夫决策树对一步分支精确加权。#strong[蒙特卡洛（Monte Carlo, MC）方法]绕开一步贝尔曼递推方程，直接回到#link(<sec-value-functions>)[第 1.3 节]中价值函数的#strong[原始期望定义]（#link(<def-1.2>)[定义 1.2] 与#link(<def-1.3>)[定义 1.3]），依据#link(<sec-mc-expectation-theory>)[第 6.1 节]的大数定律，用智能体与环境交互采集到的#strong[真实折扣回报样本均值]近似理论条件期望。

从“期望值如何近似”这一视角看，所有蒙特卡洛估计算法共享同一个数学骨架——对命中特定条件事件 $C$ 的回报样本求平均；不同算法之间的演进，完全取决于在#strong[估计对象（条件事件 $C$）]、#strong[平均与更新方式]、以及#strong[样本复用、探索覆盖与分布修正]三个维度上的不同选择。本节首先建立统一估计模板与基准算法 MC Basic，随后对比状态价值与动作价值的估计机理及平均更新规则，进而按“提高样本利用率 $arrow.r$ 保证样本覆盖 $arrow.r$ 修正样本分布偏差”的递进脉络展开各核心算法。

=== 总览：期望的样本近似与蒙特卡洛算法谱系
<sec-mc-overview>
状态价值函数 $v_pi (s)$ 与动作价值函数 $q_pi (s, a)$ 的定义仅在#strong[条件事件]（Conditioning Event）的粒度上不同：状态价值以“时刻 $t$ 处于状态 $s$”为条件，动作价值以“时刻 $t$ 处于状态 $s$ 且执行动作 $a$”为条件，被估对象均为同一折扣回报随机变量 $G_t$ 在对应条件事件下的数学期望：
$
  #mhlb($C_V (s)$) eq.dot {S_t = s}, quad & v_pi (s) = bb(E)_pi [#mhlg($G_t$) divides #mhlb($C_V (s)$)], \
  #mhlb($C_Q (s, a)$) eq.dot {S_t = s, thin A_t = a}, quad & q_pi (s, a) = bb(E)_pi [#mhlg($G_t$) divides #mhlb($C_Q (s, a)$)] .
$ <eq-mc-condition-events>
将条件事件统一记为 $C$（取 $C_V (s)$ 或 $C_Q (s, a)$），待估真实期望记为 $z(C) eq.dot bb(E)_pi [G_t divides C]$。设截至当前交互共采集到 $N(C)$ 个命中事件 $C$ 的完整回报样本，第 $i$ 个命中样本的观测回报记为 $G_C^((i))$（$i = 1, 2, dots.h, N(C)$），则状态价值与动作价值的蒙特卡洛估计共用同一个经验样本均值模板（每获得一个新命中回报 $G_t$ 时，先令计数器 $N(C) arrow.l N(C) + 1$，再执行增量更新）：
$
  #eqbox([$ hat(z)(C) eq.dot frac(1, N(C)) sum_(i = 1)^(N(C)) #mhlg($G_C^((i))$), quad arrow.r "等价增量形式" quad hat(z)(C) arrow.l hat(z)(C) + #mhl($frac(1, N(C))$) (#mhlg($G_t$) - hat(z)(C)) $])
$ <eq-mc-generic-estimator>

上述两条价值定义正是#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-opt>)[5 章]全部贝尔曼方程的共同起点。与动态规划或时序差分方法相比，蒙特卡洛方法省去了“利用一步贝尔曼递推关系将未来回报期望以当前估计值自举替换”的步骤。这一机制在统计性质上带来两方面影响：一方面，更新目标 $G_t$ 是真实回报的无偏样本，完全不受自举初值偏差的影响，且对环境状态的马尔可夫性假设不敏感；另一方面，算法必须等待整幕轨迹终止后才能执行更新，且由于累加了整段轨迹的多步随机性，估计方差随幕长显著增长。

#strong[分幕式前提与回报的逆向递推计算]：根据#link(<def-1.1>)[定义 1.1]，时刻 $t$ 的折扣回报 $G_t = R_(t + 1) + gamma R_(t + 2) + dots.h.c + gamma^(T - t - 1) R_T$ 依赖于从时刻 $t + 1$ 直至交互终止时刻 $T$ 的全部未来奖励。因此，标准蒙特卡洛方法#strong[仅适用于分幕式任务]（Episodic Tasks，即每一幕交互必在有限步 $T < oo$ 内到达终止状态 $S_T$）：智能体必须先遵循策略与环境交互完一整幕，生成完整轨迹 $tau = (S_0, A_0, R_1, S_1, A_1, R_2, dots.h, S_(T - 1), A_(T - 1), R_T, S_T)$，才能观测到真实回报。在计算一整幕各时刻的回报时，若对每个时刻 $t$ 分别从头累加未来奖励，时间复杂度将达 $O(T^2)$；工程实现直接利用#link(<prop-1.1>)[命题 1.1] 的一步递推恒等式，从轨迹末端 $t = T - 1$ 向起点 $t = 0$ #strong[逆向递推]（初值 $G_T = 0$）：
$
  G_t = R_(t + 1) + gamma G_(t + 1), quad t = T - 1, thin T - 2, thin dots.h, thin 0 ,
$
仅需单次反向遍历即可在 $O(T)$ 时间内精确算出该幕所有时刻的真实回报 $G_t$。

#strong[命题 6.3（蒙特卡洛价值估计的一般形式与统计性质）] <prop-6.3> 设策略 $pi$ 与环境交互产生若干幕相互独立的完整轨迹，$z(C) eq.dot bb(E)_pi [G_t divides C]$ 为条件事件 $C$（取 $C_V (s)$ 或 $C_Q (s, a)$）对应的被估价值，$N(C)$ 为截至当前命中 $C$ 的样本总数（首次访问协议下每幕至多计入第一次命中的时刻，每次访问协议下计入每幕内的全部命中时刻），$hat(z)(C)$ 为 @eq-mc-generic-estimator 的估计量。则：
1. #strong[首次访问协议下的条件无偏性与方差衰减]：在首次访问协议下，每个命中样本分别来自不同幕的独立轨迹；给定 $N(C) = n$（$n gt.eq 1$），样本序列 ${G_C^((i))}_(i = 1)^n$ 条件独立同分布，由#link(<prop-6.2>)[命题 6.2]：
   $
     bb(E) [hat(z)(C) divides N(C) = n] = z(C), #h(2em) upright("Var")(hat(z)(C) divides N(C) = n) = frac(upright("Var")(G_t divides C), n) .
   $ <eq-mc-conditional-unbiased>
   （注：每次访问协议下同一幕内可产生多个命中样本，因幕内重复访问次数与同幕回报相互耦合，有限样本下有偏，不适用 @eq-mc-conditional-unbiased。）
2. #strong[两类协议共有的一致收敛性]：无论采用首次访问还是每次访问协议，只要条件事件 $C$ 在交互过程中以概率 $1$ 被无限次命中（即 $N(C) arrow.r oo$），则由强大数定律，$hat(z)(C) arrow.r z(C)$ 以概率 $1$ 成立。

#strong[注记（随机样本量与固定样本量的陈述边界）]：在按固定幕数采样的协议下，命中次数 $N(C)$ 本身是随机变量且与轨迹回报同源，故首次访问协议的无偏性须按 @eq-mc-conditional-unbiased 写为给定 $N(C) = n$ 的条件期望；若采样协议改为“持续采样直到事件 $C$ 恰好被首次访问 $n$ 次”，则样本量 $n$ 为确定性常数，无条件地有 $bb(E)[hat(z)(C)] = z(C)$ 与 $upright("Var")(hat(z)(C)) = upright("Var")(G_t divides C) \/ n$。

围绕通用估计模板 @eq-mc-generic-estimator，蒙特卡洛方法族通过改变其中的三个核心要素衍生出不同算法，其设计维度与本节后续各小节的对应关系见 @tab-mc-roadmap。

#figure(
  caption: [蒙特卡洛均值近似的三个可变维度与本节演进路线],
  text(size: 8.6pt, table(
    columns: (28mm, 42mm, 1fr, 28mm),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([可变维度], [具体可选项], [对应的近似效果与衍生算法], [对应小节]),
    table.hline(),
    [#strong[① 估什么] \ （条件事件 $C$）],
    [$C_V (s) = {S_t = s}$ \ $C_Q (s, a) = {S_t = s, A_t = a}$],
    [• 状态价值 MC 评估（仅用于评估 $v_pi$） \ • 动作价值 MC 估计（支撑无模型控制 $arg max_a Q$）],
    [#link(<sec-mc-basic>)[MC Basic 基线] \ #link(<sec-mc-vq-comparison>)[状态值与动作值对比]],
    [#strong[② 怎么算平均] \ （平均与加权方式）],
    [• 批量平均 $frac(1, N) sum G^((i))$ \ • 增量平均（步长 $1 \/ N$） \ • 常步长指数平均（步长 $alpha$） \ • 重要性采样加权（OIS / WIS）],
    [• 离线批量算术平均（MC Basic） \ • 在线等价样本均值（平稳评估） \ • 指数遗忘旧样本（非平稳控制） \ • 跨分布无偏 / 渐近无偏修正（离轨 MC）],
    [#link(<sec-mc-averaging>)[平均与更新方式] \ #link(<sec-mc-off-policy>)[离轨与重要性采样]],
    [#strong[③ 哪些样本进平均 \ 与怎么采样本] \ （利用率与覆盖）],
    [• 仅起点 vs. 全后缀复用 \ • 首次访问 vs. 每次访问 \ • 批量改进 vs. 逐幕更新 \ • 试探性出发 / $epsilon$-软 / GLIE],
    [• 从单条轨迹提取沿途全部状态-动作样本 \ • 权衡有限样本无偏性与样本利用率 \ • 衍生出 MCES、同轨 $epsilon$-贪心 MC 控制],
    [#link(<sec-mc-sample-efficiency>)[优化一：样本利用率] \ #link(<sec-mc-action-value>)[优化二：样本覆盖]],
  )),
) <tab-mc-roadmap>

=== 基线：MC Basic（最朴素的轨迹均值近似）
<sec-mc-basic>
在引入各类样本复用与在线更新技巧之前，先考察最直观、最朴素的无模型控制算法——#strong[MC Basic 算法]（赵世钰《强化学习的数学原理》第 5.1 节）。其设计思路是直接将#link(<sec-dp-state-value>)[第 6.2 节]的#strong[策略迭代（Policy Iteration）]改造为无模型版本：既然没有环境模型 $p(s', r divides s, a)$ 来精确计算动作价值 $q_(pi_k) (s, a)$，就对每一个状态-动作对 $(s, a)$ 独立采样多条轨迹，用回报的算术平均直接替换精确期望。

具体而言，给定第 $k$ 轮策略 $pi_k$，MC Basic 的每一轮迭代按以下两步交替执行：
1. #strong[策略评估（逐个状态-动作对独立批量采样）]：遍历状态-动作空间中的每一个状态-动作对 $(s, a) in cal(S) times cal(A)$，强制将每一幕的初始状态和初始动作指定为 $(S_0 = s, A_0 = a)$，从 $t = 1$ 起遵循当前策略 $pi_k$ 与环境交互直至终止，独立重复采集 $n$ 条完整轨迹，获得 $n$ 个起点回报样本 ${G_(s, a)^((1)), G_(s, a)^((2)), dots.h, G_(s, a)^((n))}$。由 @eq-mc-generic-estimator 直接求批量算术平均作为动作价值估计：
   $
     hat(Q)_(pi_k) (s, a) eq.dot frac(1, n) sum_(i = 1)^n #mhlg($G_(s, a)^((i))$), quad forall (s, a) in cal(S) times cal(A) .
   $ <eq-mc-basic-eval>
2. #strong[策略改进（逐状态贪心最大化）]：待所有 $(s, a)$ 的批量平均计算完毕后，无需环境模型，直接对每个状态 $s in cal(S)$ 选取估值最大的动作构造下一轮确定性贪心策略：
   $
     pi_(k + 1) (s) in #mhl($arg max_(a in cal(A))$) hat(Q)_(pi_k) (s, a), quad forall s in cal(S) .
   $ <eq-mc-basic-improve>

#strong[MC Basic 的基线意义与三大局限]：当每个 $(s, a)$ 的采样幕数 $n arrow.r oo$ 时，由大数定律有 $hat(Q)_(pi_k) (s, a) arrow.r q_(pi_k) (s, a)$，MC Basic 在极限下严格退化为动态规划的精确策略迭代，这清晰揭示了“蒙特卡洛控制本质上是用样本均值替代策略迭代中的模型期望”。然而，作为一种朴素基线，MC Basic 暴露出三个亟待解决的问题，构成了本节后续全部演进的出发点：
- #strong[问题一（估计对象的选择）]：动态规划的策略迭代评估的是状态价值 $v_(pi_k) (s)$，为何 MC Basic 必须改为估计动作价值 $q_(pi_k) (s, a)$？若只评估状态价值会产生什么差异？（见#link(<sec-mc-vq-comparison>)[下一小节：状态价值与动作价值的对比]）
- #strong[问题二（平均与更新的时机）]：@eq-mc-basic-eval 必须先将 $n$ 个样本全部存入内存、等整批采完才能求平均，能否每采完一条样本就以 $O(1)$ 内存实时更新均值？（见#link(<sec-mc-averaging>)[平均方式：批量、增量与常步长]）
- #strong[问题三（样本利用率极低与起点假设严苛）]：一条长度为 $T$ 的轨迹明明依次经过了 $T$ 个状态-动作对，MC Basic 却只用整条轨迹的总回报 $G_0$ 更新唯一起点 $(S_0, A_0)$，将中间时刻 $t = 1, dots.h, T - 1$ 的信息全部丢弃；同时它还要求每个 $(s, a)$ 都能被人为指定为初始起点并等 $n$ 幕全部采完才改进一次策略。如何充分利用轨迹中间样本、实时改进策略并去掉严苛的起点假设？（见#link(<sec-mc-sample-efficiency>)[优化一]至#link(<sec-mc-off-policy>)[优化三]）

=== 估计对象：状态价值与动作价值（统一描述与核心差异）
<sec-mc-vq-comparison>
按 @eq-mc-condition-events 与#link(<prop-6.3>)[命题 6.3] 的统一模板，状态价值 $v_pi (s)$ 与动作价值 $q_pi (s, a)$ 的蒙特卡洛估计在数学结构上完全同构：两者都对完整轨迹的折扣回报 $G_t$ 求样本均值，收敛性定理与 $O(1 \/ n)$ 的方差衰减形式完全一致。然而，仅仅因为条件事件从 $C_V (s) = {S_t = s}$ 细化为 $C_Q (s, a) = {S_t = s, thin A_t = a}$（多固定了一个动作变量 $A_t = a$），两者在#strong[底层统计机理]与#strong[上层算法后果]上产生了系统性差异，汇总见 @tab-mc-vq-comparison。

==== 一、底层统计机理差异（样本获取、计数关系与方差分解）

1. #strong[样本获取条件与计数切分关系]：
   估计 $v_pi (s)$ 的样本只需轨迹在时刻 $t$ 到达状态 $s$ 即可获得；而估计 $q_pi (s, a)$ 的样本只有在智能体到达状态 $s$ 且#strong[实际执行了动作 $a$] 时才能观测到，未被执行的动作 $a' eq.not A_t$ 始终没有样本。
   在#strong[每次访问计数]协议下，由于状态 $s$ 的每一次访问都唯一对应当时执行的一个动作 $a in cal(A)$，状态访问次数 $N(s)$ 恰好等于该状态下各动作访问次数 $N(s, a)$ 的边缘和：
   $
     N(s) = sum_(a in cal(A)) N(s, a), #h(2.5em) N(s) gt.eq N(s, a) quad #[（对任意 $a in cal(A)$）] .
   $ <eq-mc-visit-count>
   上式右端不等式取等号当且仅当在状态 $s$ 处所有访问均执行了同一个动作。（注：在#strong[首次访问计数]协议下，$N(s)$ 与 $N(s, a)$ 均按幕计数，同一幕内可能先后访问 $(s, a_1)$ 与 $(s, a_2)$，此时总有 $N(s) gt.eq N(s, a)$，但各动作计数之和满足 $sum_(a in cal(A)) N(s, a) gt.eq N(s)$，不再严格相等。）@eq-mc-visit-count 表明：同一条轨迹算出的回报 $G_t$ 可同时为 $V(S_t)$ 与 $Q(S_t, A_t)$ 提供样本，估计动作价值#strong[不增加环境交互成本]，但会将状态 $s$ 处的总样本量按各动作被选中的频率切分为 $|cal(A)|$ 份。

2. #strong[单样本方差的降低与估计量方差的放大]：
   由#link(<def-1.2>)[定义 1.2] 与#link(<def-1.3>)[定义 1.3]，$v_pi (s)$ 的回报样本包含第一步动作选择 $A_t tilde.op pi(dot.op divides s)$ 的随机性，而 $q_pi (s, a)$ 的样本已将该动作固定为 $a$。对给定 $S_t = s$ 的回报应用概率论中的#strong[全方差公式]（$upright("Var")(X) = bb(E)[upright("Var")(X divides Y)] + upright("Var")(bb(E)[X divides Y])$），并代入 $bb(E)[G_t divides S_t = s, A_t] = q_pi (s, A_t)$，可将第一步动作的随机性显式分离：
   $
     upright("Var")(G_t divides S_t = s) = bb(E)_(A_t) [upright("Var")(G_t divides S_t = s, A_t) divides S_t = s] + #mhlg($upright("Var")_(A_t) (q_pi (s, A_t) divides S_t = s)$) .
   $ <eq-mc-total-variance>
   右端第一项是“固定动作后后续环境转移与策略随机性”带来的平均条件方差，第二项是“同一状态下不同动作本身价值不同”带来的方差。按动作条件化消去了第二项非负方差，因此在策略加权平均意义下，动作价值单样本回报的条件方差不大于状态价值单样本的方差：
   $
     bb(E)_(A_t) [upright("Var")(G_t divides s, A_t)] = upright("Var")(G_t divides s) - upright("Var")_(A_t)(q_pi (s, A_t)) lt.eq upright("Var")(G_t divides s) .
   $ <eq-mc-var-conditioning>
   然而，在实际估计中，动作价值估计量 $hat(Q)_pi (s, a)$ 的方差#strong[通常反而高于]状态价值估计量 $hat(V)_pi (s)$，原因在于分母上的有效样本量被大幅稀释。在同轨采样下，状态 $s$ 处动作 $a$ 被选中的概率为 $pi(a divides s)$，故 $N(s, a)$ 的期望约为 $pi(a divides s) N(s)$；代入 @eq-mc-conditional-unbiased 的方差公式可得：
   $
     upright("Var")(hat(Q)_pi (s, a)) approx frac(upright("Var")(G_t divides s, a), #mhl($pi(a divides s)$) N(s)), #h(3em) upright("Var")(hat(V)_pi (s)) = frac(upright("Var")(G_t divides s), N(s)) .
   $ <eq-mc-variance-comparison>
   当某个动作被执行的概率 $pi(a divides s)$ 很小时，其估计方差会被因子 $frac(1, pi(a divides s))$ 成倍放大。这就是“探索不足时非贪心动作的 $Q$ 值估计极不可靠”的统计学根源。

==== 二、算法与工程后果（控制能力、访问覆盖、离轨修正与存储）

1. #strong[能否支撑无模型策略控制（聚合方向的不对称性）]：
   两类价值函数之间满足确定的单向聚合关系：
   $
     v_pi (s) = sum_(a in cal(A)) pi(a divides s) q_pi (s, a) quad #[（#link(<thm-3.1>)[定理 3.1]）], #h(3.5em) v_star (s) = max_(a in cal(A)) q_star (s, a) quad #[（#link(<thm-5.1>)[定理 5.1]）] .
   $ <eq-mc-vq-aggregation>
   由动作价值 $Q$ 聚合出状态价值 $V$（或直接选出最优动作 $arg max_a Q(s, a)$）只需在已知的动作集合上做策略加权或求最大值，#strong[完全不需要环境模型]。反之，若只估出了状态价值 $V(s) approx v_pi (s)$，想要改进策略就必须执行 @eq-policy-improvement 的单步向前看（One-step Lookahead）：
   $
     pi'(s) in arg max_(a in cal(A)) sum_(s' in cal(S), thin r in cal(R)) #mhlb($p(s', r divides s, a)$) [r + gamma V(s')] ,
   $
   这要求显式已知环境转移概率 $p(s', r divides s, a)$。因此得出无模型强化学习的一条核心准则：#strong[无模型策略控制必须估计动作价值 $Q(s, a)$；状态价值的蒙特卡洛估计仅适用于策略评估（Prediction）]。

2. #strong[充分探索与访问覆盖要求（Continual Exploration）]：
   #link(<prop-6.3>)[命题 6.3] 要求被估条件事件被无限次命中。若仅评估状态价值 $v_pi (s)$，即使被评估策略 $pi$ 是完全确定性的，只要状态 $s$ 在该策略诱导的马尔可夫链中常返，就能不断获得样本；但若要估计动作价值 $q_pi (s, a)$ 并用于控制，则要求#strong[每一个状态-动作对 $(s, a)$ 都被持续访问]。在确定性策略下，每个状态只有一个动作被执行，其余 $|cal(A)| - 1$ 个动作的样本数恒为 $0$，从而迫使动作价值控制算法必须额外引入探索机制（见#link(<sec-mc-action-value>)[优化二]）。

3. #strong[离轨学习时重要性采样比的起点差异]：
   当使用行为策略 $b$ 采集轨迹来估计目标策略 $pi$ 的价值时（详见#link(<sec-mc-off-policy>)[优化三]），条件事件是否固定当前动作 $A_t$，直接决定了重要性采样比连乘的起始时刻：
   $
     rho_(t : T - 1) = product_(k = t)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k)) quad #[（用于 $v_pi (s)$）], #h(2.5em) rho_(t + 1 : T - 1) = product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k)) quad #[（用于 $q_pi (s, a)$）] .
   $ <eq-mc-is-start-comparison>
   估计 $q_pi (s, a)$ 时，时刻 $t$ 的动作 $A_t = a$ 已作为条件给定，无需修正时刻 $t$ 的选动作概率，故连乘从下一步 $k = t + 1$ 开始；估计 $v_pi (s)$ 时，时刻 $t$ 的动作 $A_t$ 仍由行为策略 $b$ 随机采样，必须补上 $k = t$ 的概率比因子 $frac(pi(A_t divides S_t), b(A_t divides S_t))$。需要注意的是，若轨迹来自其他策略 $b eq.not pi$，无论估计 $v_pi$ 还是 $q_pi$ 都必须进行重要性采样修正；若直接对 $b$ 采样的回报求平均，得到的只能是行为策略自身的价值 $v_b (s)$ 或 $q_b (s, a)$。

4. #strong[存储空间开销]：
   表格型状态价值估计只需维护 $|cal(S)|$ 个表项，而动作价值估计需要维护 $|cal(S)| times |cal(A)|$ 个表项，内存与遍历开销随动作空间大小线性增长。

#figure(
  caption: [状态价值与动作价值的蒙特卡洛估计全方位对比],
  text(size: 8.6pt, table(
    columns: (26mm, 1fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon),
    table.header([对比维度], [状态价值 MC 估计（$v_pi (s)$）], [动作价值 MC 估计（$q_pi (s, a)$）]),
    table.hline(),
    [条件事件 $C$], [$C_V (s) = {S_t = s}$], [$C_Q (s, a) = {S_t = s, thin A_t = a}$],
    [样本获取前提], [轨迹访问状态 $s$ 即可], [轨迹访问状态 $s$ #strong[且实际执行动作 $a$]],
    [样本计数关系], [$N(s)$], [$N(s, a)$；每次访问计数下 $N(s) = sum_a N(s, a)$，首次访问下 $N(s) gt.eq N(s, a)$],
    [单样本条件方差], [$upright("Var")(G_t divides s)$，含当前步选动作随机性], [$upright("Var")(G_t divides s, a)$，已消去当前步选动作随机性],
    [估计量方差], [$frac(upright("Var")(G_t divides s), N(s))$], [$approx frac(upright("Var")(G_t divides s, a), pi(a divides s) N(s))$，低概率动作方差被 $1 \/ pi(a divides s)$ 放大],
    [访问覆盖要求], [状态 $s$ 被无限次访问], [每个状态-动作对 $(s, a)$ 均被无限次访问（需探索机制）],
    [离轨重要性采样比], [$rho_(t : T - 1) = product_(k = t)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$], [$rho_(t + 1 : T - 1) = product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$],
    [无模型策略控制], [不支持（需环境模型 $p$ 做一步向前看）], [直接支持（逐状态取 $arg max_a Q(s, a)$）],
    [表格存储开销], [$O(|cal(S)|)$], [$O(|cal(S)| times |cal(A)|)$],
  )),
) <tab-mc-vq-comparison>

=== 平均方式：批量平均、增量更新与常步长指数加权
<sec-mc-averaging>
确定了估计对象 $C$ 后，第二个核心问题是：当回报样本 $G_C^((1)), G_C^((2)), dots.h, G_C^((N))$ 陆续到达时，应当如何计算并更新均值估计量 $hat(z)_N$？根据计算时机与步长选取的不同，共有三种平均方式（对比见 @tab-mc-averaging-methods）：

1. #strong[批量算术平均（Batch Mean，直接批量更新）]：
   将截至当前采集到的全部 $N$ 个回报样本存储在列表 $"Returns"(C)$ 中，待需要读取估值时一次性求和除以 $N$：
   $
     hat(z)_N (C) = frac(1, N) sum_(i = 1)^N G_C^((i)) .
   $
   MC Basic（@eq-mc-basic-eval）采用的正是这种批量方式。其缺点在于内存占用随采样次数 $O(N)$ 线性增长，且在批量集齐前无法实时改善价值估计。

2. #strong[增量式样本平均（Incremental Mean，衰减步长 $alpha_N = 1 \/ N$）]：
   由#link(<prop-6.2>)[命题 6.2] 的增量恒等式（@eq-incremental-mean），第 $N$ 个样本到达后的算术平均值 $hat(z)_N$ 可以直接由上一次的均值 $hat(z)_(N - 1)$ 与新样本 $G_C^((N))$ 递推算出：
   $
     hat(z)_N (C) = hat(z)_(N - 1) (C) + #mhl($frac(1, N)$) [#mhlg($G_C^((N))$) - hat(z)_(N - 1) (C)] .
   $ <eq-mc-incremental-1n>
   理解 @eq-mc-incremental-1n 的关键在于：#strong[取步长 $alpha_N = 1 \/ N$ 的增量更新并非近似，它在代数上与存储全部历史样本的批量算术平均完全等价]，但将每个状态（或状态-动作对）的空间复杂度降为 $O(1)$（仅需维护当前估值 $hat(z)$ 与计数器 $N$）。
   从#link(<sec-robbins-monro-theory>)[第 6.1 节]的 Robbins–Monro 随机近似定理（#link(<thm-6.1>)[定理 6.1]）来看，括号内的误差项 $G_C^((N)) - hat(z)_(N - 1) (C)$ 是“目标回报减当前估计”的更新方向，而调和步长序列 $alpha_N = 1 \/ N$ 同时满足 $sum_(N = 1)^oo frac(1, N) = oo$（累积步幅无穷大，足以完全消除任意初值偏差 $hat(z)_0$）与 $sum_(N = 1)^oo frac(1, N^2) = frac(pi^2, 6) < oo$（步长平方和收敛，足以在后期完全抑制单次采样噪声），因此在策略固定（平稳分布）时保证以概率 $1$ 收敛于真实价值。

3. #strong[常步长指数移动平均（Constant-Step-Size EMA，固定步长 $alpha in (0, 1]$）]：
   在边评估边改进策略的蒙特卡洛控制过程中，策略 $pi$ 随每一幕不断演进，导致回报 $G_t$ 的真实概率分布随时间持续漂移（即#strong[非平稳环境，Non-stationary Problem]）。此时若继续使用 $alpha_N = 1 \/ N$，几千幕前由劣质初始策略产生的过时回报仍与最新回报享有完全相等的权重 $1 \/ N$，导致估值响应迟钝。工程上因此常将 $1 \/ N$ 替换为固定常数步长 $alpha in (0, 1]$：
   $
     #eqbox([$ hat(z)_N (C) = hat(z)_(N - 1) (C) + #mhl($alpha$) [#mhlg($G_C^((N))$) - hat(z)_(N - 1) (C)] = #mhlb($(1 - alpha)^N$) hat(z)_0 (C) + sum_(i = 1)^N #mhl($alpha (1 - alpha)^(N - i)$) G_C^((i)) $])
   $ <eq-mc-constant-alpha>
   如右端展开式所示，常步长更新不再等价于等权算术平均，而是#strong[指数加权移动平均]：距离当前越久远的历史样本 $G_C^((i))$，其权重 $alpha (1 - alpha)^(N - i)$ 呈指数级衰减，从而能够快速遗忘过时策略的旧样本、实时追踪当前最新策略的价值。其代价是常数步长满足 $sum_(N = 1)^oo alpha = oo$ 却#strong[不满足 Robbins–Monro 第二条件 $sum_(N = 1)^oo alpha^2 < oo$]，因此估值不会严格收敛到某个固定点，而是在真值附近保持幅度与 $alpha$ 成正比的小幅随机波动。

#figure(
  caption: [蒙特卡洛期望估计的三种平均与更新方式对比],
  text(size: 8.6pt, table(
    columns: (28mm, 44mm, 18mm, 24mm, 26mm, 1fr),
    align: (left + horizon, left + horizon, center + horizon, center + horizon, left + horizon, left + horizon),
    table.header([平均方式], [更新公式], [单表项空间], [等价于算术平均], [RM 收敛条件], [适用场景]),
    table.hline(),
    [#strong[批量算术平均] \ （Batch Mean）],
    [$hat(z)_N = frac(1, N) sum_(i = 1)^N G^((i))$],
    [$O(N)$],
    [是（定义本身）],
    [大数定律保证 \ $N arrow.r oo$ 收敛],
    [小样本离线统计、MC Basic 教学基线],
    [#strong[增量样本平均] \ （步长 $1 \/ N$）],
    [$hat(z)_N = hat(z)_(N - 1) + frac(1, N)(G^((N)) - hat(z)_(N - 1))$],
    [$O(1)$],
    [#strong[严格代数等价] \ （权重均为 $1 \/ N$）],
    [$sum 1 \/ N = oo$ ✓ \ $sum 1 \/ N^2 < oo$ ✓],
    [固定策略评估（平稳分布）、GLIE 理论收敛证明],
    [#strong[常步长更新] \ （步长 $alpha in (0, 1]$）],
    [$hat(z)_N = hat(z)_(N - 1) + alpha (G^((N)) - hat(z)_(N - 1))$],
    [$O(1)$],
    [否（指数移动平均，近大远小）],
    [$sum alpha = oo$ ✓ \ $sum alpha^2 = oo$ ✗],
    [策略不断变化的控制过程、非平稳环境追踪],
  )),
) <tab-mc-averaging-methods>

增量更新（@eq-mc-incremental-1n 与 @eq-mc-constant-alpha）无需等待批量样本集齐，每观测到一个回报即可原地更新估值，这为下一小节的“逐幕在线更新”以及离轨学习中的“加权重要性采样增量算法”奠定了基础。

=== 优化一：提高样本利用率（全后缀复用、每次访问与逐幕更新）
<sec-mc-sample-efficiency>
对比#link(<sec-mc-basic>)[MC Basic 基线]每次只用一条轨迹更新起点 $(S_0, A_0)$ 且等 $n$ 幕采完才改进策略的低效做法，现代蒙特卡洛算法从四个递进层面挖掘轨迹数据，显著提升了样本利用率（汇总见 @tab-mc-sample-reuse）：

1. #strong[轨迹全后缀复用（All-Suffix Trajectory Reuse）]：
   由马尔可夫性，一条完整轨迹 $tau = (S_0, A_0, R_1, S_1, A_1, R_2, dots.h, S_(T - 1), A_(T - 1), R_T, S_T)$ 中从任意中间时刻 $t$（$0 lt.eq t lt.eq T - 1$）截取的后缀子轨迹 $tau_(t : T) = (S_t, A_t, R_(t + 1), dots.h, S_T)$，都可以直接看作一条从状态 $S_t$（或状态-动作对 $(S_t, A_t)$）出发的合法轨迹样本。配合 $O(T)$ 的逆向递推 $G_t = R_(t + 1) + gamma G_(t + 1)$，#strong[采样一幕长度为 $T$ 的轨迹即可同时产出 $T$ 个时刻的回报样本]，一次性更新沿途经过的全部状态或状态-动作对，无需像 MC Basic 那样为每个 $(s, a)$ 单独重启采样。

2. #strong[同幕内重复访问样本的复用：首次访问（First-Visit）vs. 每次访问（Every-Visit）]：
   在启用全后缀复用后，同一幕轨迹可能在多个不同时间步 $t_1 < t_2 < dots.h$ 重复经过同一个状态 $s$（或同一个 $(s, a)$）。以状态价值评估为例，根据是否复用同一幕内的后续重复访问样本，分为两类经典协议（对比见 @tab-mc-fv-vs-ev）：
   - #strong[首次访问型蒙特卡洛（First-Visit MC）]：在每一幕轨迹中，仅采纳状态 $s$ #strong[第一次出现]的时刻 $t_1 (s) = min {t gt.eq 0 : S_t = s}$ 对应的回报 $G_(t_1 (s))$，忽略该幕内后续对 $s$ 的重复访问。设共有 $N(s)$ 幕访问过 $s$，第 $i$ 幕的首次访问回报为 $G_s^((i))$，其批量与增量更新式为（每当新一幕首次访问 $s$ 时，先令 $N(s) arrow.l N(s) + 1$）：
     $
       #eqbox([$ hat(V)_pi^upright("FV") (s) eq.dot #mhl($frac(1, N(s)) sum_(i = 1)^(N(s))$) #mhlg($G_s^((i))$), #h(2em) upright("增量更新：") quad V(s) arrow.l V(s) + #mhl($frac(1, N(s))$) [#mhlg($G_(t_1 (s))$) - V(s)] $])
     $ <eq-mc-first-visit-v>
     由于每幕至多贡献一个样本，不同样本严格来自不同幕的独立轨迹，满足#link(<prop-6.3>)[命题 6.3] 第 1 条的条件独立同分布前提，#strong[在有限样本下条件无偏]。
   - #strong[每次访问型蒙特卡洛（Every-Visit MC）]：将每一幕中访问状态 $s$ 的#strong[全部时间步]的回报都纳入平均（逆向遍历轨迹时无需检查 $S_t$ 在本幕前序时刻是否出现过，每遇到一次 $S_t$ 即令 $N(S_t) arrow.l N(S_t) + 1$ 并执行增量更新）。
     #strong[为什么每次访问型在有限样本下有偏却渐近一致？] 虽然单看任意一次命中时刻都有 $bb(E)[G_t divides S_t = s] = v_pi (s)$，但在同一幕内，状态 $s$ 被重复访问的次数本身是随机变量，且与该幕的轨迹长度及累计奖励相互耦合（例如在每步奖励为负的迷宫中，反复绕圈多次经过 $s$ 的那一幕往往总回报更差，却在分子和分母中占据了更多权重），同时同一幕内先后两次访问的回报共享其后的轨迹奖励而彼此相关。这导致分母含随机总访问次数的比率估计量在有限幕下有偏（$bb(E)[hat(V)_pi^upright("EV") (s)] eq.not v_pi (s)$）。然而，由于不同幕之间依然相互独立，当采样幕数趋于无穷（$N(s) arrow.r oo$）时，跨幕大数定律使该偏差以 $O(1 \/ N(s))$ 速率衰减至 $0$，估计量同样以概率 $1$ 收敛于 $v_pi (s)$。Singh & Sutton (1996) 进一步证明，在样本幕数较少时，每次访问型因利用了更多样本，其均方误差（MSE）往往低于首次访问型，且算法实现更简洁（免去了幕内去重判断）。

#figure(
  caption: [首次访问型 MC（First-Visit）与每次访问型 MC（Every-Visit）的对比],
  text(size: 8.6pt, table(
    columns: (26mm, 1fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon),
    table.header([对比维度], [首次访问型 MC（First-Visit MC）], [每次访问型 MC（Every-Visit MC）]),
    table.hline(),
    [样本采纳规则], [每幕轨迹中每个 $s$（或 $(s, a)$）#strong[仅计入第一次出现]的时刻 $t_1$], [每幕轨迹中每个 $s$（或 $(s, a)$）#strong[出现的所有时刻]全部计入],
    [样本独立性], [各样本来自不同幕，给定样本数下严格条件独立同分布], [跨幕独立，但同一幕内的多次命中样本共享后续奖励、彼此相关],
    [有限样本偏差], [#strong[条件无偏]：$bb(E)[hat(z)^upright("FV")(C) divides N(C) = n] = z(C)$], [#strong[有偏]（幕内随机访问次数与回报耦合），偏差随幕数以 $O(1 \/ N)$ 衰减],
    [渐近一致性], [$N(C) arrow.r oo$ 时以概率 $1$ 收敛于真值 $z(C)$], [$N(C) arrow.r oo$ 时以概率 $1$ 收敛于真值 $z(C)$（渐近无偏）],
    [实现与适用性], [需在逆向遍历时额外检查 $S_t$ 是否仍在前缀 $S_(0 : t - 1)$ 中], [无需去重判断，代码极简，小样本下均方误差常更低，自然对接函数近似与资格迹],
  )),
) <tab-mc-fv-vs-ev>

3. #strong[逐幕在线更新与广义策略迭代（Episode-by-Episode GPI）]：
   在 MC Basic 中，策略评估必须等待每个 $(s, a)$ 采满 $n$ 幕轨迹后才执行一次策略改进。结合#link(<sec-mc-averaging>)[上一小节]的增量更新公式（@eq-mc-incremental-1n 或 @eq-mc-constant-alpha），可将评估步截断为#strong[仅采样一幕轨迹]：每当一幕交互结束，立即逆向递推算出各步回报 $G_t$，对本幕经历的每个 $(S_t, A_t)$ 按增量公式更新动作价值估计（步长 $alpha$ 取 $1 \/ N(S_t, A_t)$ 或常数）：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [#mhlg($G_t$) - Q(S_t, A_t)] $])
   $ <eq-mc-q-update>
   并紧接着对本幕访问过的状态 $S_t$ 立即执行策略改进（如更新为关于最新 $Q(S_t, dot.op)$ 的贪心或软贪心策略）。这种“每采完一幕即交替执行一次增量评估与一次策略改进”的架构，正是#strong[蒙特卡洛广义策略迭代（MC Control via GPI）]的标准范式：下一幕采样立即受益于上一幕改进后的新策略，大幅加速了向最优策略推进的过程。

4. #strong[$V$ 与 $Q$ 协同更新及跨策略历史样本复用]：
   同一幕轨迹算出的回报序列 ${G_t}$ 可以零额外采样成本地同时更新状态价值表 $V(S_t)$ 与动作价值表 $Q(S_t, A_t)$；在已知策略分布 $pi(a divides s)$ 且各动作估值较准时，利用全期望关系 $V(s) = sum_a pi(a divides s) Q(s, a)$ 由 $Q$ 直接合成 $V$，还可消除单步动作采样的随机方差。更进一步，若将其他策略或历史日志生成的轨迹通过重要性采样（见#link(<sec-mc-off-policy>)[优化三]）加以修正，甚至可以跨策略复用离线历史数据。

#figure(
  caption: [蒙特卡洛方法提高样本利用率的五种递进手段（以 MC Basic 为参照基线）],
  text(size: 8.6pt, table(
    columns: (28mm, 44mm, 1fr, 34mm),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([优化手段], [相比基线额外复用的信息], [核心收益与付出的统计/工程代价], [代表算法]),
    table.hline(),
    [#strong[① 全后缀复用]],
    [单条轨迹中全部中间时刻 $t = 0, dots.h, T - 1$ 的后缀子轨迹],
    [采一幕得 $T$ 个样本，免去按每个 $(s, a)$ 单独重启；代价是需保证轨迹能覆盖所有 $(s, a)$],
    [所有现代 MC 评估与控制算法],
    [#strong[② 每次访问协议] \ （Every-Visit）],
    [同一幕内对同一 $s$ 或 $(s, a)$ 的第 $2, 3, dots.h$ 次重复访问],
    [样本量更大、免去幕内去重判断、小样本 MSE 常更低；代价是同幕样本相关且有限幕下有偏],
    [每次访问型 MC 评估与控制],
    [#strong[③ 逐幕增量更新] \ （Episode-by-Episode）],
    [无需等 $n$ 幕集齐，每幕结束立刻更新 $Q$ 并改进策略 $pi$],
    [新策略立刻用于下一幕采样，学习速率显著提升；代价是回报分布随策略漂移（非平稳）],
    [MCES、同轨 $epsilon$-贪心 MC 控制],
    [#strong[④ $V$ 与 $Q$ 互推]],
    [同一批轨迹同时更新 $V, Q$，或用 $sum_a pi(a divides s) Q(s, a)$ 算 $V$],
    [消除当前步动作采样方差；代价是需要动作价值 $Q(s, a)$ 的充分探索覆盖],
    [优势函数估计、Expected SARSA 思想前身],
    [#strong[⑤ 跨策略数据复用]],
    [行为策略 $b$ 或历史离线日志采集的轨迹],
    [可复用历史数据并解耦探索与优化；代价是需乘重要性采样比 $rho$，长幕下方差易膨胀],
    [离轨 OIS / WIS 蒙特卡洛],
  )),
) <tab-mc-sample-reuse>

=== 优化二：保证样本覆盖（探索机制：MCES、$epsilon$-贪心与 GLIE）
<sec-mc-action-value>
将 MC Basic 升级为“全后缀复用 + 逐幕增量更新（@eq-mc-q-update）”后，虽然数据效率大幅提升，但立即触发了#link(<sec-mc-vq-comparison>)[状态值与动作值对比小节]指出的#strong[探索性困境（Exploration Dilemma）]：在逐幕更新循环中，若策略 $pi$ 直接取确定性贪心策略 $pi(s) in arg max_a Q(s, a)$，则在状态 $s$ 下智能体只会不断执行当前估值最高的单一动作 $a = pi(s)$，其余动作 $a' eq.not pi(s)$ 永远没有机会被尝试，其访问计数 $N(s, a')$ 恒为 $0$、估值永久停滞在初值，导致算法极易陷入次优策略。

为保证所有状态-动作对 $(s, a) in cal(S) times cal(A)$ 均能被持续采样（满足充分探索要求），同轨学习（On-Policy Learning，即生成轨迹与被评估、改进的为同一策略）发展出三种递进的探索机制（对比见 @tab-mc-exploration-comparison）：

1. #strong[试探性出发蒙特卡洛（MC with Exploring Starts, MCES，又称探索性出发）]：
   MCES 是将 MC Basic 加上“全后缀复用 + 逐幕更新”后的直接产物。为了防止漏掉某些状态-动作对，MCES 人为规定一条#strong[试探性出发假设]：每一幕交互的初始状态-动作对 $(S_0, A_0)$ 在全部 $cal(S) times cal(A)$ 上以严格大于 $0$ 的概率随机抽取；从第二步 $t = 1$ 起，智能体完全遵循当前的确定性贪心策略 $pi(s) in arg max_a Q(s, a)$ 直至本幕终止。每幕结束后，逆向遍历 $t = T - 1, dots.h, 0$ 按 @eq-mc-q-update 更新沿途的 $Q(S_t, A_t)$，并更新访问状态的贪心策略 $pi(S_t)$。
   - #strong[局限性]：试探性出发在拥有可任意重置状态的仿真器（如棋类推演、电子游戏）中易于实现，但在真实物理环境（如机器人控制、自动驾驶，起点固定或由物理规律决定）中根本无法人为强制指定任意初始状态；此外，在一般随机环境下 MCES 能否保证收敛于 $q_star$ 迄今尚无完整数学证明（Sutton & Barto 第 2 版第 5.3 节将其列为开放问题）。

2. #strong[同轨策略 $epsilon$-贪心蒙特卡洛控制（On-Policy $epsilon$-Greedy MC Control）]：
   为了彻底取消不切实际的“试探性出发”假设，只能让策略 $pi$ 在交互全过程中自身保持随机探索能力——采用 #strong[$epsilon$-软策略（$epsilon$-Soft Policy）]，即要求对任意 $s in cal(S), a in cal(A)$ 均有 $pi(a divides s) gt.eq frac(epsilon, |cal(A)|) > 0$（其中探索率 $epsilon in (0, 1]$）。
   在给定当前动作价值估计 $Q(s, dot.op)$ 时，将全部探索概率预算 $epsilon$ 均匀分配给所有 $|cal(A)|$ 个动作，并将剩余的 $1 - epsilon$ 概率赋予当前贪心动作 $a^star in arg max_(a' in cal(A)) Q(s, a')$（若有多个动作并列最大，则按固定规则选定其一），即得到 #strong[$epsilon$-贪心策略（$epsilon$-Greedy Policy）]：
   $
     pi(a divides s) = cases(
       1 - epsilon + frac(epsilon, |cal(A)|) \, & upright("若 ") a = a^star \,,
       frac(epsilon, |cal(A)|) \, & upright("若 ") a eq.not a^star .
     )
   $ <eq-epsilon-greedy-policy>
   - #strong[单调改进保证与常数 $epsilon$ 的收敛边界]：对于任意 $epsilon$-软策略 $pi$，按 @eq-epsilon-greedy-policy 关于 $q_pi$ 构造出的新 $epsilon$-贪心策略 $pi'$ 满足：
     $
       q_pi (s, pi'(s)) = sum_(a in cal(A)) pi'(a divides s) q_pi (s, a) = frac(epsilon, |cal(A)|) sum_(a in cal(A)) q_pi (s, a) + (1 - epsilon) max_(a in cal(A)) q_pi (s, a) gt.eq v_pi (s) ,
     $
     由策略改进定理在 $epsilon$-软策略类中的推广（Sutton & Barto 第 2 版第 5.4 节），依然严格保证单调改进 $v_(pi') (s) gt.eq v_pi (s)$。只要环境状态互通，由于每个动作都有至少 $epsilon \/ |cal(A)|$ 的正概率被选中，无需试探性出发即可保证所有可从起点到达的 $(s, a)$ 被无限次访问。然而，当探索率 $epsilon$ 固定为常数时，策略在任何时候都必须以 $epsilon$ 的概率盲目随机动作，因此其收敛极限只是#strong[$epsilon$-软策略类中的最优策略]，而非全局最优确定性策略 $pi_star$。

3. #strong[无限探索且渐近贪心（GLIE 条件）与渐近最优收敛]：
   若要在不依赖试探性出发的前提下最终收敛到全局最优确定性策略 $pi_star$ 与最优动作价值 $q_star$，必须在初期保持充分探索，同时让探索率随幕数 $k$ 的增加缓慢衰减至 $0$。这一思想被严格表述为 #strong[GLIE 条件（Greedy in the Limit with Infinite Exploration）]：
   - #strong[无限探索（Infinite Exploration）]：所有状态-动作对 $(s, a)$ 在交互过程中被无限次访问，即 $lim_(k arrow.r oo) N_k (s, a) = oo$；
   - #strong[渐近贪心（Greedy in the Limit）]：当幕数 $k arrow.r oo$ 时，策略以概率 $1$ 收敛于关于动作价值的确定性贪心策略，即 $lim_(k arrow.r oo) pi_k (a divides s) = bb(1)[a = a_k^star]$。
   典型实现是令第 $k$ 幕的 $epsilon$-贪心探索率取调和衰减序列 $epsilon_k = frac(1, k)$（或 $frac(c, k)$）。由于 $sum_(k = 1)^oo frac(1, k) = oo$，根据 Borel–Cantelli 引理的推广可保证无限次探索所有动作；同时 $lim_(k arrow.r oo) epsilon_k = 0$ 保证策略渐近变为纯贪心策略。在有限 MDP 中，若同轨 MC 控制满足 GLIE 条件，且按各 $(s, a)$ 访问次数定义的更新步长 $alpha_k (s, a)$ 满足 Robbins–Monro 条件（@eq-rm-step-conditions，如 $alpha_k (s, a) = 1 \/ N_k (s, a)$），则 $Q_k$ 以概率 $1$ 收敛于全局最优动作价值 $q_star$，策略收敛于最优策略 $pi_star$（Singh et al., 2000）。

#figure(
  caption: [同轨蒙特卡洛控制的三种探索覆盖机制对比],
  text(size: 8.6pt, table(
    columns: (32mm, 38mm, 34mm, 36mm, 1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([探索机制], [覆盖率来源], [对环境/交互的要求], [理论收敛极限], [工程适用性与局限]),
    table.hline(),
    [#strong[试探性出发] \ （MCES）],
    [每幕起点 $(S_0, A_0)$ 均匀或正概率随机指定；后续步纯贪心],
    [极强：要求环境支持从任意 $(s, a)$ 重置出发],
    [目标是 $q_star, pi_star$（一般情形下尚无完整收敛证明）],
    [仅适用于拥有状态重置接口的仿真器；物理实机不可行],
    [#strong[固定 $epsilon$-贪心] \ （常数 $epsilon > 0$）],
    [策略自身每步以 $epsilon$ 概率均匀随机选动作],
    [弱：仅需正常从初始状态交互，无需重置起点],
    [#strong[$epsilon$-软策略类中的最优策略]（次优，非 $pi_star$）],
    [实现极简，配合常步长 $alpha$ 可持续适应非平稳环境；但永远保留 $epsilon$ 探索损耗],
    [#strong[GLIE 衰减 $epsilon_k$-贪心] \ （如 $epsilon_k = 1 \/ k$）],
    [探索率缓慢衰减，满足 $sum epsilon_k = oo$ 且 $epsilon_k arrow.r 0$],
    [弱：无需试探性出发，但需极长训练幕数],
    [#strong[全局最优 $q_star$ 与确定性最优策略 $pi_star$]（配合 RM 步长）],
    [具备完备的渐近最优理论保证；但工程中衰减过快易早熟收敛，过慢则训练耗时极长],
  )),
) <tab-mc-exploration-comparison>

=== 优化三：样本分布修正（离轨策略蒙特卡洛与重要性采样）
<sec-mc-off-policy>
同轨学习（On-Policy）之所以必须在“持续探索”与“追求确定性最优”之间左右权衡，根源在于它把#strong[探索环境的任务]与#strong[择优决策的任务]强行绑定在同一个策略上。为了彻底解开这一矛盾，或者为了直接利用历史日志、人类专家示范或其他控制器采集好的轨迹数据来评估与优化当前策略，#strong[离轨策略学习（Off-Policy Learning）]将策略一分为二：
- #strong[行为策略（Behavior Policy，$b(a divides s)$）]：实际与环境交互、负责生成采样轨迹的策略，通常设为具有充分探索性的随机策略（如常数 $epsilon$-贪心策略或均匀随机策略）；
- #strong[目标策略（Target Policy，$pi(a divides s)$）]：真正被评估或被优化学习的策略，在控制任务中可直接设为完全不带探索噪声的#strong[确定性贪心策略] $pi(s) in arg max_a Q(s, a)$。

要使行为策略 $b$ 采出的样本能够涵盖目标策略 $pi$ 可能走到的所有分支，两者必须满足#strong[覆盖假设（Coverage Assumption）]：
$
  forall s in cal(S), thin a in cal(A), quad pi(a divides s) > 0 arrow.r.double b(a divides s) > 0 .
$ <eq-coverage-assumption>

==== 一、重要性采样原理与未知环境模型的完美约消

由于轨迹样本是由行为策略 $b$ 生成的，若直接对观测到的回报 $G_t$ 求算术平均，由大数定律得到的是行为策略的价值 $bb(E)_b [G_t divides C]$（即 $v_b$ 或 $q_b$），而非目标策略的价值 $bb(E)_pi [G_t divides C]$。从均值近似的角度看，这是一个典型的#strong[采样分布 $P_b$ 与目标期望分布 $P_pi$ 不一致]的问题。

#strong[一般随机变量的重要性采样（Importance Sampling, IS）]：设随机变量 $tau$ 在目标分布 $P_pi$ 下取值为 $P_pi (tau)$，但样本是从另一个满足覆盖假设（$P_pi (tau) > 0 arrow.r.double P_b (tau) > 0$）的提议分布 $P_b$ 中抽取的。欲利用 $P_b$ 下的样本无偏估计目标期望 $bb(E)_pi [f(tau)] = sum_tau P_pi (tau) f(tau)$，只需在求和式中乘以并除以 $P_b (tau)$：
$
  bb(E)_pi [f(tau)] = sum_tau P_pi (tau) f(tau) = sum_tau P_b (tau) underbrace(#mhl($frac(P_pi (tau), P_b (tau))$), "重要性采样比 " rho(tau)) f(tau) = bb(E)_b [#mhl($rho(tau)$) f(tau)] .
$ <eq-general-importance-sampling>
@eq-general-importance-sampling 表明：将两个分布的概率之比定义为#strong[重要性采样比（Importance Sampling Ratio）] $rho(tau) eq.dot frac(P_pi (tau), P_b (tau))$，用 $rho(tau)$ 对观测值 $f(tau)$ 进行重加权后，修正样本 $rho(tau) f(tau)$ 在行为分布 $b$ 下的数学期望就严格等于原始变量在目标分布 $pi$ 下的数学期望。

#strong[MDP 子轨迹概率展开与环境转移概率约消]：将 @eq-general-importance-sampling 应用于动作价值 $q_pi (s, a) = bb(E)_pi [G_t divides S_t = s, A_t = a]$ 的估计。给定时刻 $t$ 处于状态 $S_t = s$ 且执行了动作 $A_t = a$，决定回报 $G_t$ 的后续子轨迹为 $tau_(t + 1 : T) = (R_(t + 1), S_(t + 1), A_(t + 1), dots.h, R_T, S_T)$。由马尔可夫性与条件概率乘法法则，该子轨迹在任意策略 $pi$ 下发生的条件概率为首步环境转移概率与后续各步“策略选动作 $times$ 环境转移”概率的连乘积：
$
  P_pi (tau_(t + 1 : T) divides S_t, A_t) = p(S_(t + 1), R_(t + 1) divides S_t, A_t) product_(k = t + 1)^(T - 1) pi(A_k divides S_k) p(S_(k + 1), R_(k + 1) divides S_k, A_k) .
$
当构造目标策略 $pi$ 与行为策略 $b$ 的子轨迹条件概率之比时，由于两条策略面对的是同一个环境，#strong[分子与分母中所有未知的环境转移概率 $p(S_(k + 1), R_(k + 1) divides S_k, A_k)$（含 $k = t$ 的首步环境转移）逐项完全约消]：
$
  rho_(t + 1 : T - 1) eq.dot frac(P_pi (tau_(t + 1 : T) divides S_t, A_t), P_b (tau_(t + 1 : T) divides S_t, A_t)) = frac(cancel(p(S_(t + 1), R_(t + 1) divides S_t, A_t)) product_(k = t + 1)^(T - 1) pi(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k)), cancel(p(S_(t + 1), R_(t + 1) divides S_t, A_t)) product_(k = t + 1)^(T - 1) b(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k))) = #mhl($product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$) .
$ <eq-importance-sampling-ratio>
（约定当 $t = T - 1$ 时空乘积 $rho_(T : T - 1) = 1$；若估计对象为状态价值 $v_pi (s)$，因条件事件仅固定 $S_t = s$ 而未固定 $A_t$，连乘须从 $k = t$ 开始，即 @eq-mc-is-start-comparison 中的 $rho_(t : T - 1)$。）@eq-importance-sampling-ratio 揭示了一个极具价值的性质：尽管整条轨迹的概率依赖于未知的环境动态，但#strong[重要性采样比 $rho_(t + 1 : T - 1)$ 完全不依赖环境模型 $p$]，仅由智能体自己已知的两个策略分布 $pi$ 与 $b$ 决定！由 @eq-general-importance-sampling，修正后的回报样本严格满足无偏关系：
$
  bb(E)_b [#mhl($rho_(t + 1 : T - 1)$) #mhlg($G_t$) divides S_t = s, A_t = a] = q_pi (s, a) .
$ <eq-is-unbiased-identity>

==== 二、普通重要性采样（OIS）与加权重要性采样（WIS）

设截至当前状态-动作对 $(s, a)$ 共被访问 $N(s, a)$ 次，第 $i$ 次命中样本对应的采样比与观测回报分别记为 $rho_(s, a)^((i))$ 与 $G_(s, a)^((i))$。根据对加权样本做简单算术平均还是做归一化加权平均，可构造两类离轨动作价值估计量（对比见 @tab-mc-ois-vs-wis）：
$
  #eqbox([$ hat(Q)_pi^upright("OIS") (s, a) eq.dot frac(1, N(s, a)) sum_(i = 1)^(N(s, a)) #mhl($rho_(s, a)^((i))$) #mhlg($G_(s, a)^((i))$), #h(2.5em) hat(Q)_pi^upright("WIS") (s, a) eq.dot frac(sum_(i = 1)^(N(s, a)) #mhl($rho_(s, a)^((i))$) #mhlg($G_(s, a)^((i))$), sum_(i = 1)^(N(s, a)) #mhl($rho_(s, a)^((i))$)) $])
$ <eq-mc-ois-wis>

- #strong[普通重要性采样（Ordinary Importance Sampling, OIS）]：左式直接以 $1 \/ N(s, a)$ 对修正样本 $rho_(s, a)^((i)) G_(s, a)^((i))$ 求算术平均。由 @eq-is-unbiased-identity，OIS 在首次访问协议下#strong[严格无偏]；但因为 $rho_(t + 1 : T - 1)$ 是 $T - t - 1$ 步概率比的连乘积，只要部分步骤上比值 $pi(A_k divides S_k) \/ b(A_k divides S_k) > 1$（例如行为策略以 $0.1$ 的小概率碰巧选到了目标策略概率为 $1$ 的贪心动作，单步比值即为 $10$，连续 $k$ 步即为 $10^k$），采样比就会随轨迹长度呈指数级暴涨，导致 OIS 估计量的方差极大，在包含环路的分幕任务中方差甚至可能发散至无穷大。
- #strong[加权重要性采样（Weighted Importance Sampling, WIS）]：右式将分母从样本个数 $N(s, a)$ 替换为采样比的累加和 $sum_(i = 1)^(N(s, a)) rho_(s, a)^((i))$（约定分母为 $0$ 时保持初值不变），即把每个样本 $G_(s, a)^((i))$ 的相对权重归一化为 $w_i = frac(rho_(s, a)^((i)), sum_j rho_(s, a)^((j))) in [0, 1]$。例如当仅采到 $N = 1$ 个非零权重样本时，无论 $rho^((1))$ 高达 $1000$ 还是低至 $0.01$，OIS 会将回报放大 $1000$ 倍或缩小为 $1%$，而 WIS 中分子分母的 $rho^((1))$ 直接约消，给出完全合理的单样本估计 $hat(Q)^upright("WIS") = G^((1))$！由于分子与分母同含随机变量 $rho$，WIS 作为比率估计量在有限样本下有偏（单样本时偏差即为 $q_b - q_pi$），但随着 $N(s, a) arrow.r oo$，分子除以 $N$ 与分母除以 $N$ 分别由大数定律收敛于 $q_pi (s, a)$ 与 $1$，故偏差渐近趋于 $0$（一致收敛）；同时因所有归一化权重均在 $[0, 1]$ 之间，只要单幕回报有界 $|G_t| lt.eq G_max$，WIS 的估值就恒被严格限制在 $[-G_max, G_max]$ 内，#strong[方差恒有界且远低于 OIS]。因此在实际工程与离轨控制中，几乎总是采用加权重要性采样（WIS）。

#figure(
  caption: [普通重要性采样（OIS）与加权重要性采样（WIS）的统计特性对比],
  text(size: 8.6pt, table(
    columns: (28mm, 1fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon),
    table.header([对比维度], [普通重要性采样（OIS）], [加权重要性采样（WIS）]),
    table.hline(),
    [估计量定义], [算术平均：$frac(1, N) sum_(i = 1)^N rho^((i)) G^((i))$], [归一化加权平均：$frac(sum_(i = 1)^N rho^((i)) G^((i)), sum_(i = 1)^N rho^((i)))$],
    [单样本（$N = 1$）表现], [$hat(Q) = rho^((1)) G^((1))$（受极端采样比剧烈扭曲）], [$hat(Q) = G^((1))$（分子分母 $rho^((1))$ 约消，等于真实观测回报）],
    [有限样本偏差], [#strong[无偏]（首次访问协议下）], [#strong[有偏]，但偏差以 $O(1 \/ N)$ 衰减，满足渐近无偏与一致收敛],
    [方差特性], [极高，长幕或存在环路时方差可能#strong[无界（$oo$）]], [权重归一化至 $[0, 1]$，回报有界时#strong[方差恒有界]且显著更小],
    [工程采用建议], [主要用于理论分析或极短幕任务，工程实践中极少直接采用], [#strong[离轨蒙特卡洛评估与控制的标准首选方案]],
  )),
) <tab-mc-ois-vs-wis>

==== 三、WIS 的增量更新公式与离轨蒙特卡洛控制流程

1. #strong[WIS 的 $O(1)$ 增量更新递推式]：
   将#link(<sec-mc-averaging>)[平均方式小节]的增量思想推广到加权平均：对每个状态-动作对 $(s, a)$，维护当前动作价值估计 $Q(s, a)$ 与截至当前的累积重要性权重和 $C(s, a) eq.dot sum_(i = 1)^n W_i$（初值 $C(s, a) = 0$）。每当一幕轨迹在时刻 $t$ 为 $(S_t, A_t)$ 产生新的回报样本 $G_t$ 与重要性采样比 $W eq.dot rho_(t + 1 : T - 1)$（若 $W = 0$ 则该样本对加权和无贡献，可直接跳过）时，先累加权重和 $C(S_t, A_t) arrow.l C(S_t, A_t) + W$，再执行增量更新：
   $
     #eqbox([$ C(S_t, A_t) arrow.l C(S_t, A_t) + #mhl($W$), #h(2.5em) Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($frac(W, C(S_t, A_t))$) [#mhlg($G_t$) - Q(S_t, A_t)] $])
   $ <eq-wis-incremental-update>
   对 @eq-wis-incremental-update 展开归纳即可验证，它在代数上与 @eq-mc-ois-wis 右端的批量 WIS 公式完全等价，且仅需 $O(1)$ 存储开销。

2. #strong[离轨蒙特卡洛控制（Off-Policy MC Control）与非贪心动作回溯截断]：
   在离轨 MC 控制中，目标策略 $pi$ 直接设为关于当前 $Q$ 的确定性贪心策略 $pi(s) in arg max_a Q(s, a)$（并列最大时按固定一致规则打破平局），而行为策略 $b$ 设为任意满足覆盖假设的软策略（如 $epsilon$-贪心策略）。每一幕控制循环按以下步骤执行：
   - #strong[步骤 1（行为策略采样）]：遵循行为策略 $b$ 与环境交互生成完整一幕轨迹 $(S_0, A_0, R_1, dots.h, S_(T - 1), A_(T - 1), R_T)$，初始化回报 $G arrow.l 0$ 与重要性采样权重 $W arrow.l 1$。
   - #strong[步骤 2（逆向递推与 WIS 更新）]：对时刻 $t = T - 1, T - 2, dots.h, 0$ 依次逆向回溯：先更新回报 $G arrow.l R_(t + 1) + gamma G$，再以当前权重 $W$ 按 @eq-wis-incremental-update 更新 $C(S_t, A_t)$ 与 $Q(S_t, A_t)$，并随即将状态 $S_t$ 的目标策略更新为最新贪心动作 $pi(S_t) arrow.l arg max_a Q(S_t, a)$。
   - #strong[步骤 3（回溯截断或权重累乘）]：检查时刻 $t$ 行为策略实际执行的动作 $A_t$ 是否与刚刚更新后的目标贪心动作 $pi(S_t)$ 一致：
     - 若 $A_t eq.not pi(S_t)$：由于确定性目标策略满足 $pi(A_t divides S_t) = 0$，从时刻 $t - 1$ 往前的所有时刻 $t' < t$ 其重要性采样比 $rho_(t' + 1 : T - 1)$ 中都必然包含因子 $pi(A_t divides S_t) = 0$，导致前序所有权重恒为 $0$。因此#strong[立即跳出本幕回溯循环，开始下一幕采样]；
     - 若 $A_t = pi(S_t)$：此时 $pi(A_t divides S_t) = 1$，将重要性权重更新为 $W arrow.l W dot.op frac(1, b(A_t divides S_t))$，继续向 $t - 1$ 回溯。
   这一“遇到非贪心动作即截断回溯”的机制直观地说明：离轨蒙特卡洛控制只能利用每一幕轨迹末端#strong[恰巧与目标贪心策略全部吻合的那一段后缀]来更新价值；当轨迹很长且行为策略探索较多时，有效回溯深度往往较短，这正是下一节引入单步时序差分控制（如 Q-Learning，无需长轨迹连乘重要性采样即可离轨学习）的核心动因。

=== 方法总览、选型决策与常见误区辨析
<sec-mc-summary>
将本节讨论的全部蒙特卡洛价值估计与控制方法按“估计对象、样本复用协议、平均更新方式、探索覆盖机制、数据来源与分布修正”五个维度进行横向汇总，可得 @tab-mc-methods-summary。

#figure(
  caption: [蒙特卡洛价值估计与控制算法谱系总览（方法 $times$ 均值近似选择维度）],
  text(size: 8.4pt, table(
    columns: (28mm, 14mm, 24mm, 24mm, 26mm, 26mm, 1fr),
    align: (left + horizon, center + horizon, left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([算法名称], [对象], [样本利用方式], [平均/更新方式], [探索覆盖机制], [数据来源与修正], [核心定位与收敛结论]),
    table.hline(),
    [#strong[MC Basic] \ （教学基线）],
    [$q_pi$],
    [仅用轨迹起点 $(S_0, A_0)$ 的总回报 $G_0$],
    [批量算术平均 \ $frac(1, n) sum G^((i))$],
    [人为遍历指定每个 $(s, a)$ 为起点],
    [同轨（$b = pi$），无分布偏差],
    [无模型策略迭代的最朴素基线；样本效率最低],
    [#strong[首次访问 MC] \ （First-Visit）],
    [$v_pi$ \ 或 $q_pi$],
    [全后缀复用，每幕仅计入首次访问时刻],
    [批量平均或等价增量 $1 \/ N$],
    [评估 $v_pi$ 无需探索动作；估 $q_pi$ 需软策略],
    [同轨（$b = pi$），无分布偏差],
    [标准策略评估：有限样本#strong[条件无偏]，$N arrow.r oo$ 时以概率 $1$ 收敛],
    [#strong[每次访问 MC] \ （Every-Visit）],
    [$v_pi$ \ 或 $q_pi$],
    [全后缀复用，同幕内全部访问时刻均计入],
    [增量更新 $1 \/ N$ 或常步长 $alpha$],
    [同上],
    [同轨（$b = pi$），无分布偏差],
    [标准策略评估：有限样本有偏但#strong[渐近无偏]，免去重判断，小样本 MSE 常更低],
    [#strong[试探性出发 MC] \ （MCES）],
    [$q_pi arrow.r q_star$],
    [全后缀复用 + 逐幕在线 GPI 更新],
    [增量更新 $1 \/ N$ 或常步长 $alpha$],
    [随机起点 $(S_0, A_0)$ + 后续确定性贪心],
    [同轨（$b = pi$），无分布偏差],
    [仅适用于可任意指定起点的仿真器；一般收敛性尚无完整证明],
    [#strong[同轨 $epsilon$-贪心 MC] \ （On-Policy）],
    [$q_pi arrow.r q_star$],
    [全后缀复用 + 逐幕在线 GPI 更新],
    [增量更新 $1 \/ N$ 或常步长 $alpha$],
    [$epsilon$-软策略；或按 GLIE 条件衰减 $epsilon_k arrow.r 0$],
    [同轨（$b = pi$），无分布偏差],
    [固定 $epsilon$ 收敛于 $epsilon$-软策略最优；#strong[GLIE + RM 步长]收敛于全局最优 $q_star$],
    [#strong[离轨重要性采样 MC] \ （Off-Policy IS）],
    [$v_pi, q_pi$ \ 或 $q_star$],
    [全后缀复用（控制时遇非贪心动作截断回溯）],
    [OIS 算术平均；#strong[WIS 增量加权更新]],
    [由行为策略 $b$（如 $epsilon$-软）保证覆盖假设],
    [离轨（$b eq.not pi$），乘重要性采样比 $rho$],
    [解耦探索与优化，可直接学确定性贪心策略 $pi_star$；WIS 渐近无偏且方差有界],
  )),
) <tab-mc-methods-summary>

==== 一、实际任务中的蒙特卡洛算法选型指南

面对具体的强化学习问题，可按以下三个递进问题快速确定最合适的蒙特卡洛方案：
1. #strong[任务目标是“仅评估给定策略”还是“寻找最优控制策略”？]
   - 若仅需评估给定策略的表现（Policy Evaluation），优先选择估计#strong[状态价值 $V(s)$]（每次访问型或首次访问型增量 MC），其表项规模仅为 $|cal(S)|$，且不要求策略遍历所有动作、估计方差更低。
   - 若需要在未知环境模型下改进策略（Model-Free Control），则#strong[必须估计动作价值 $Q(s, a)$]，以便直接通过 $arg max_a Q(s, a)$ 选出贪心动作。
2. #strong[轨迹样本是否由当前被评估/优化的同一个策略实时生成？]
   - 若智能体自采自用（On-Policy），且物理环境无法任意指定初始状态，应选用#strong[同轨 $epsilon$-贪心 MC 控制]（追求理论渐近最优则按 GLIE 衰减 $epsilon_k$，追求持续适应能力则保留小常数 $epsilon$）。
   - 若希望在保持充分探索的同时直接学习确定性最优策略 $pi_star$，或需要复用历史离线日志、他策示范数据（Off-Policy），应选用#strong[基于加权重要性采样（WIS）的离轨 MC 算法]（@eq-wis-incremental-update）。
3. #strong[被估价值的回报分布是否平稳？]
   - 在固定策略评估中，回报分布平稳，选用衰减步长 $alpha_N = 1 \/ N$ 可获得与批量样本均值严格等价的无偏/渐近无偏估计。
   - 在边评估边改进策略的控制过程中，策略持续变化导致回报分布非平稳，工程上优先选用#strong[常步长 $alpha in (0, 1]$] 以指数加权遗忘早期旧策略产生的过时样本。

==== 二、本科生学习中的四个常见误区辨析

1. #strong[误区一：“既然每次访问时刻都有 $bb(E)[G_t divides S_t = s] = v_pi (s)$，那么每次访问型 MC 在有限样本下也是无偏估计。”]
   - #strong[辨析]：期望的线性性只在样本个数固定时保证算术平均无偏。在每次访问型 MC 中，同一幕内状态 $s$ 被重复访问的次数本身是随机变量，且与该幕的轨迹长度及回报高低存在统计耦合，同时同一幕内多次访问的回报共享后续奖励而彼此相关，导致比率估计量 $hat(V)_pi^upright("EV") (s)$ 在有限幕下有偏；只有当采样幕数趋于无穷时，跨幕独立性才使偏差以 $O(1 \/ N(s))$ 衰减至零（渐近无偏）。
2. #strong[误区二：“状态价值 MC 评估不需要探索所有动作，因此可以直接拿任意行为策略 $b$ 采出的轨迹求算术平均来估计 $v_pi (s)$。”]
   - #strong[辨析]：这是把“访问覆盖要求”与“采样分布一致性”混为一谈。状态价值评估确实不需要在每个状态试遍所有动作，但轨迹中每一步选什么动作直接决定了状态转移走向与后续奖励分布。若不乘重要性采样比 $rho_(t : T - 1)$ 而直接对行为策略 $b$ 的轨迹回报求平均，大数定律保证其收敛到的是行为策略自身的价值 $v_b (s)$，而非目标策略的 $v_pi (s)$。只要 $b eq.not pi$，无论估 $V$ 还是估 $Q$ 都必须做重要性采样修正。
3. #strong[误区三：“状态访问计数恒等于各动作访问计数之和 $N(s) = sum_(a in cal(A)) N(s, a)$ 在所有 MC 协议下都成立。”]
   - #strong[辨析]：该恒等式#strong[仅在每次访问（Every-Visit）计数协议下成立]。在首次访问（First-Visit）协议下，$N(s)$ 统计的是“访问过状态 $s$ 的幕数”，而 $N(s, a)$ 统计的是“访问过状态-动作对 $(s, a)$ 的幕数”；同一幕轨迹完全可以先经过 $(s, a_1)$、稍后再次回到 $s$ 并执行 $(s, a_2)$，此时该幕对 $N(s)$ 仅贡献 $1$ 次计数，却对 $sum_a N(s, a)$ 贡献了 $2$ 次计数，故首次访问协议下一般有 $sum_(a in cal(A)) N(s, a) gt.eq N(s) gt.eq N(s, a)$。
4. #strong[误区四：“常步长更新 $hat(z) arrow.l hat(z) + alpha (G - hat(z))$ 只是把 $1 \/ N$ 换成了常数，随着样本无穷多也能以概率 $1$ 收敛到真值。”]
   - #strong[辨析]：由#link(<thm-6.1>)[定理 6.1]（Robbins–Monro 定理）及误差递推式 @eq-rm-error-recursion，每一步采样噪声向估计误差注入的方差项为 $alpha_k^2 sigma^2$。常步长 $alpha > 0$ 不满足第二条件 $sum_(k = 1)^oo alpha_k^2 < oo$，最新到达的样本永远保有固定权重 $alpha$，单次采样的随机涨落永远不会被完全抹平，因此估值只能在真值邻域内持续振荡，是用“放弃严格渐近收敛”换取“对非平稳分布的持续追踪能力”。

#divider()

== 核心扩展一 · 离轨策略评估与重要性采样（分布错配修正）
<sec-importance-sampling>
前述两类路线均默认轨迹样本由待评估的目标策略 $pi$ 生成（同轨学习）。然而在实际控制算法中，为了兼顾探索与利用，常需采用富于探索性的策略采集交互数据，同时评估或优化另一个更为贪心的目标策略——这构成了所有离轨（Off-Policy）方法的基本范式。此时，样本服从行为策略诱导的轨迹分布而非目标策略分布，存在着#strong[采样分布错配（Distribution Mismatch）]。本节系统阐述离轨策略评估的理论前提、似然比修正机制、方差特性，以及#strong[无需引入重要性采样的判定准则]。

1. #strong[问题症结与覆盖性假设]：
   设交互轨迹样本由#strong[行为策略（Behavior Policy）] $b(a divides s)$ 生成，而待估计的目标量为#strong[目标策略（Target Policy）] $pi(a divides s)$ 下的动作价值 $q_pi (s, a)$（或状态价值 $v_pi (s)$）。若直接对行为策略 $b$ 采样的回报求经验平均，估计量将收敛于 $q_b (s, a) eq.dot bb(E)_b [G_t divides S_t = s, A_t = a]$，与目标价值 $q_pi (s, a)$ 存在系统性偏差。
   消除该分布偏差的充要前提是满足#strong[覆盖性假设（Coverage Assumption）]（亦称绝对连续性条件）：
   $
     pi(a divides s) > 0 ⟹ b(a divides s) > 0, #h(1.5em) forall s in cal(S), a in cal(A) .
   $ <eq-is-coverage>
   即凡是目标策略 $pi$ 赋予正概率的动作，行为策略 $b$ 亦必须以正概率探索。若在某状态-动作对上 $pi(a divides s) > 0$ 而 $b(a divides s) = 0$，则该分支的样本在采样分布下的支撑集缺失，任何重加权手段均无法恢复其期望信息。

2. #strong[修正机制：轨迹似然比与环境转移概率的代数约消]：
   注意行为策略 $b$ 与目标策略 $pi$ 的差异仅体现在#strong[策略层的动作采样概率]上，而底层的#strong[环境状态转移规律 $p(s', r divides s, a)$ 完全相同]。给定 $(S_t = s, A_t = a)$ 后，将后续子轨迹 $tau_(t + 1 : T) = (S_(t + 1), A_(t + 1), dots.h, S_T)$ 在目标策略 $pi$ 与行为策略 $b$ 下的条件概率相除，按乘法链式法则展开后，#strong[未知的环境转移概率 $p(S_(k + 1), R_(k + 1) divides S_k, A_k)$ 在分子与分母中完全约消]，所得相对似然比仅由已知的策略概率之比构成：
   $
     rho_(t + 1 : T - 1) eq.dot frac(product_(k = t + 1)^(T - 1) pi(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k)), product_(k = t + 1)^(T - 1) b(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k))) = #mhl($product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$) .
   $ <eq-importance-sampling-ratio>
   该比值称为#strong[重要性采样比（Importance Sampling Ratio）]，由于不依赖于未知的环境动力学模型 $p$，可直接用于无模型离轨评估。对动作价值 $q_pi (s, a)$，因时刻 $t$ 的动作 $A_t = a$ 已由条件固定，似然比从 $k = t + 1$ 开始累乘，满足无偏测度变换恒等式 $bb(E)_b [rho_(t + 1 : T - 1) G_t divides S_t = s, A_t = a] = bb(E)_pi [G_t divides S_t = s, A_t = a] = q_pi (s, a)$。
   #strong[注（状态价值 $v_pi (s)$ 与动作价值 $q_pi (s, a)$ 的似然比下标区分）]：若待评估的对象是#strong[状态价值 $v_pi (s)$]，由于在条件 ${S_t = s}$ 下当前时刻动作 $A_t$ 并未固定、亦由策略采样产生，故重要性采样比必须从时刻 $t$ 开始累乘，记为 $rho_(t : T - 1) eq.dot product_(k = t)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$，此时有 $bb(E)_b [rho_(t : T - 1) G_t divides S_t = s] = v_pi (s)$。

3. #strong[估计量构造：普通重要性采样（OIS）与加权重要性采样（WIS）]：
   设在状态-动作对 $(s, a)$ 上共采集到 $N(s, a)$ 个轨迹回报样本 ${G_((i))}$ 及对应的似然比 ${rho_((i))}$，可构造两类离轨估计量：
   $
     hat(Q)_pi^upright("OIS") (s, a) = frac(1, N(s, a)) sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), #h(2.5em) hat(Q)_pi^upright("WIS") (s, a) = frac(sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$)) .
   $ <eq-mc-ois-wis>
   - #strong[普通重要性采样（Ordinary IS, OIS）]：$hat(Q)_pi^upright("OIS") (s, a)$ 对任意样本量均满足 $bb(E)_b [hat(Q)_pi^upright("OIS") (s, a)] = q_pi (s, a)$，是严格#strong[无偏估计量]；但由于分母为确定性样本数 $N(s, a)$，当连乘权重 $rho_((i))$ 出现极端值时，估计量方差可能急剧膨胀甚至无界。
   - #strong[加权重要性采样（Weighted IS, WIS）]：$hat(Q)_pi^upright("WIS") (s, a)$ 以随机权重之和 $sum_i rho_((i))$ 作为归一化分母，构成各样本回报的凸组合（当回报有界时，估计值严格落在 $[min_i G_((i)), max_i G_((i))]$ 区间内），方差显著更低且恒有界。由于分母是随机变量，WIS 在有限样本下存在 $O(1 \/ N)$ 量级的偏差，但随 $N arrow.r oo$ 偏差渐近趋于零（渐近无偏，Consistent）。工程实践中通常优先采用 WIS。
   WIS 亦可写为增量递推形式：令累积权重 $W_(n + 1) = W_n + rho_(n + 1)$，则有
   $
     Q_(n + 1) = Q_n + frac(rho_(n + 1), W_(n + 1)) [G_(n + 1) - Q_n] .
   $ <eq-mc-wis-incremental>
   对照 @eq-ch6-update-shell 可见，上式依然遵循通用增量更新形式 $x arrow.l x + alpha_k (y_k - x)$，其等效步长 $alpha_k = rho_k \/ W_k$ 是由样本似然比自适应决定的归一化权重（当同轨 $rho_k equiv 1$ 时即退化为 @eq-incremental-mean 中的等权步长 $1 \/ N$）。

4. #strong[方差的链式累积机理与逐决策重要性采样（Per-Decision IS）]：
   重要性采样比 $rho_(t + 1 : T - 1)$ 是沿时间步的连乘积，这是导致离轨多步估计方差随步数指数级增长的根本原因。将完整回报 $G_t = sum_(k = t + 1)^T gamma^(k - t - 1) R_k$ 展开后，对第 $k$ 步的即时奖励 $R_k$ 而言，由#strong[时序因果性]与#link(<lem-2>)[引理 2] 的条件期望塔性质，发生在时刻 $k$ 之后的似然比因子 $frac(pi(A_(k') divides S_(k')), b(A_(k') divides S_(k')))$（$k' gt.eq k$）在给定历史轨迹 $(S_t, A_t, dots.h, S_k, R_k)$ 下的条件期望恒等于 $1$（因 $sum_a b(a divides S_(k')) frac(pi(a divides S_(k')), b(a divides S_(k')) ) = sum_a pi(a divides S_(k')) = 1$）。因此，后置似然比因子可从期望中精确消去，仅需保留时刻 $k$ 之前的前缀乘积 $rho_(t + 1 : k - 1)$：
   $
     bb(E)_b [rho_(t + 1 : T - 1) G_t divides S_t, A_t] = bb(E)_b [sum_(k = t + 1)^T gamma^(k - t - 1) #mhl($rho_(t + 1 : k - 1)$) R_k divides S_t, A_t] .
   $ <eq-per-decision-is>
   上式称为#strong[逐决策重要性采样（Per-Decision IS）]。它表明：时间步越靠后的奖励项 $R_k$，所乘的前缀似然比因子个数越多，引入的方差贡献也越大。综上所述，离轨估计的高方差主要源于两个因素：一是目标策略 $pi$ 与行为策略 $b$ 的分布偏离程度，二是连乘所跨越的有效时间步长。针对多步连乘方差失控的截断修正方案将在#link(<sec-offpolicy-multistep>)[第 6.7 节]详细讨论。

5. #strong[无需重要性采样的结构判据]：
   并非所有离轨算法均需引入重要性采样比。似然比 $rho$ 的作用是修正#strong[策略层关于动作分布的期望]。若算法所构造的自举目标值 $y_k$ 本身不包含关于目标策略分布的采样期望，则无需乘以似然比。最具代表性的情形是基于#strong[贝尔曼最优方程]的单步自举目标（如 Q-Learning，见#link(<sec-td-action-value>)[第 6.6 节]）：
   $
     y_k = R_(k + 1) + gamma max_(a' in cal(A)) Q(S_(k + 1), a') .
   $ <eq-max-target-no-is>
   在给定当前状态-动作对 $(S_k = s, A_k = a)$ 的条件下，单步转移 $(R_(k + 1), S_(k + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 仅由环境动力学决定，与行为策略 $b$ 无关；而后继价值项 $max_(a') Q(S_(k + 1), a')$ 直接对动作空间取确定性最大值（同理，Expected SARSA 直接按已知分布 $sum_(a') pi(a' divides S_(k + 1)) Q(S_(k + 1), a')$ 显式求和），并未依赖从策略中采样出的后继动作 $A_(k + 1)$。在此情形下，行为策略 $b$ 仅需满足持续探索条件以确保所有 $(s, a)$ 被充分访问，无需重要性采样校正。反之，#strong[凡是更新目标中包含需通过轨迹动作采样来近似的策略期望（如离轨 SARSA 或多步离轨回报），且采样策略 $b$ 异于目标策略 $pi$ 时，均必须引入重要性采样加权。]

6. #strong[与贝尔曼方程的理论关系]：
   重要性采样机制#strong[并未改变底层的贝尔曼期望方程本身]。无论是状态价值方程 $v_pi (s) = bb(E)_pi [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$（@eq-bellman-exp-vv，全轨迹展开对应乘以 $rho_(t : T - 1)$）还是动作价值方程 $q_pi (s, a) = bb(E)_pi [R_(t + 1) + gamma q_pi (S_(t + 1), A_(t + 1)) divides S_t = s, A_t = a]$（@eq-bellman-exp-qq，对应乘以 $rho_(t + 1 : T - 1)$），算子的不动点始终严格保持为 $v_pi$ 与 $q_pi$；重要性采样仅在统计估计层面对样本赋予似然比权重，以完成从行为分布 $b$ 到目标分布 $pi$ 的测度变换。

#divider()

== 路线三 · 基于随机近似的时序差分（TD）估计（模型未知：采样 + 自举）
<sec-td-estimation>

同轨蒙特卡洛的完整回报在首次访问协议下无偏，但存在两项固有缺陷：（1）必须等待整幕交互终止（$t = T$）后才能更新，无法应用于无终止状态的持续性任务（Continuing Tasks，$T = oo$）；（2）整幕回报 $G_t = R_(t + 1) + gamma R_(t + 2) + dots.h.c + gamma^(T - t - 1) R_T$ 累加了多达 $T - t$ 步的环境与策略随机性，方差随幕长增长；在离轨设定下，重要性采样比连乘（@eq-importance-sampling-ratio）还可使普通 IS 估计量方差无界。

#strong[时序差分学习（Temporal-Difference Learning, TD）]将#link(<sec-bellman-exp-cond>)[第 3 章]与#link(<sec-bellman-opt>)[第 5 章]的条件期望形式贝尔曼方程（自举思想）与#link(<sec-robbins-monro-theory>)[第 6.1 节]的 Robbins-Monro 随机近似理论（采样求根）结合：以单步转移样本替代条件期望，并用当前估计自举后继价值，从而在模型未知时逐步在线更新价值估计。

=== 状态价值的时序差分估计（TD(0)、$n$-步 TD 与 TD($lambda$)）
<sec-td-state-value>
1. #strong[从 Robbins-Monro 随机近似导出 TD(0) 状态价值估计算法]：
   根据#link(<thm-3.3>)[定理 3.3] 的状态价值贝尔曼期望方程（条件期望形式 @eq-bellman-exp-vv），真实状态价值 $v_pi (s)$ 满足：
   $
     v_pi (s) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_pi (S_(t + 1))$) divides S_t = s] .
   $
   将其改写为#link(<sec-robbins-monro-theory>)[第 6.1 节]的 Robbins-Monro 求根方程（@eq-rm-root-problem）：
   $
     g(v_pi (s)) eq.dot v_pi (s) - bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s] = 0 .
   $ <eq-td-rm-root>
   在交互时刻 $t$，智能体从状态 $S_t = s$ 采样一步转移获得观测样本 $(R_(t + 1), S_(t + 1))$。由于真值 $v_pi (S_(t + 1))$ 未知，用当前维护的价值估计表 $V(S_(t + 1))$ #strong[自举（Bootstrap）]替代 $v_pi (S_(t + 1))$，构造出单步采样目标（#strong[TD Target]）与带噪残差观测（其负值定义为#strong[时序差分误差，TD Error $delta_t$]）：
   $
     y_t^upright("TD") eq.dot #mhl($R_(t + 1) + gamma #mhlg($V(S_(t + 1))$)$), #h(2.5em) delta_t eq.dot y_t^upright("TD") - V(S_t) = #mhl($R_(t + 1) + gamma #mhlg($V(S_(t + 1))$) - V(S_t)$) .
   $ <eq-td-target-error>
   将带噪观测 $tilde(g)_t = - delta_t$ 代入 Robbins-Monro 随机近似迭代式（@eq-robbins-monro-update），得到 #strong[TD(0) 状态价值估计算法]：
   $
     #eqbox([$ V(S_t) arrow.l V(S_t) + #mhl($alpha_t$) delta_t = V(S_t) + #mhl($alpha_t$) [R_(t + 1) + gamma #mhlg($V(S_(t + 1))$) - V(S_t)] $])
   $ <eq-td0-v-update>
   #strong[收敛性定理]：在有限表格型 MDP 中，若每个状态被无限次访问且步长序列满足 Robbins-Monro 条件 $sum_t alpha_t (s) = oo, sum_t alpha_t^2 (s) < oo$，则由随机近似与随机不动点压缩理论（Jaakkola et al., 1994; Tsitsiklis, 1994），TD(0) 迭代序列 $V_t$ 以概率 $1$ 收敛于真实状态价值 $v_pi$。

2. #strong[$n$-步时序差分（$n$-Step TD）与 TD($lambda$)：连接 MC 与 TD(0) 的连续谱]：
   TD(0) 仅向前采样 $1$ 步即用 $V(S_(t + 1))$ 自举，而蒙特卡洛（MC）向前采样直到终止（$oo$ 步）。将回报一步递推式（@eq-return-recursion）连续展开 $n$ 步并用 $V(S_(t + n))$ 截断自举，即得到 #strong[$n$-步时序差分回报（$n$-Step Return）]及其更新公式：
   $
     G_(t : t + n) eq.dot #mhl($sum_(k = 1)^n gamma^(k - 1) R_(t + k)$) + gamma^n #mhlg($V(S_(t + n))$), #h(2em) V(S_t) arrow.l V(S_t) + alpha [G_(t : t + n) - V(S_t)] .
   $ <eq-n-step-td>
   进一步对所有 $n in {1, 2, dots.h}$ 的 $n$-步回报以几何权重 $(1 - lambda) lambda^(n - 1)$（其中 $lambda in [0, 1]$）做指数加权平均，即构成 #strong[TD($lambda$) 的 $lambda$-回报]：
   $
     G_t^lambda eq.dot #mhl($(1 - lambda) sum_(n = 1)^oo lambda^(n - 1)$) #mhlg($G_(t : t + n)$) .
   $ <eq-td-lambda-return>
   当 $lambda = 0$ 时，$G_t^0 = G_(t : t + 1) = R_(t + 1) + gamma V(S_(t + 1))$，完全退化为单步 TD(0)（低方差、有初始自举偏差）；当 $lambda = 1$ 时，$G_t^1 = G_t$，完全退化为无偏的蒙特卡洛估计（无偏、高方差）。因此 $lambda in [0, 1]$ 提供了在#strong[随机近似自举]与#strong[蒙特卡洛采样]之间平滑调节偏差-方差权衡（Bias-Variance Trade-off）的参数。在分幕任务中，约定 $t + n gt.eq T$ 时 $G_(t : t + n) = G_t$，上式等价于 $G_t^lambda = (1 - lambda) sum_(n = 1)^(T - t - 1) lambda^(n - 1) G_(t : t + n) + lambda^(T - t - 1) G_t$。

   $lambda$-回报需要等待未来 $n$ 步数据（前向视角）。在线实现采用资格迹（Eligibility Trace）的后向视角：对每个状态维护 $z_t (s) = gamma lambda z_(t - 1) (s) + bb(1)[S_t = s]$（$z_(-1) = 0$），每步以同一个 $delta_t$ 更新所有状态：
   $
     #eqbox([$ V(s) arrow.l V(s) + #mhl($alpha$) delta_t #mhlb($z_t (s)$), quad forall s in cal(S) $])
   $ <eq-td-lambda-trace>
   在分幕、恒定步长、采用上述累积资格迹且一幕内保持价值表 $V$ 不变的离线实现中，所有更新推迟到幕末执行，后向视角的累计更新量与基于同一冻结 $V$ 计算的前向 $lambda$-回报累计更新量相等（Sutton & Barto 第 2 版第 12.4 节）；若一幕内价值表随时间变化，二者一般只近似相等。

#divider()

== 核心扩展二 · 动作价值估计与无模型控制算法族（从期望评估到贪心最大化）
<sec-td-action-value>
#link(<sec-td-estimation>)[第 6.5 节]所讨论的自举目标均围绕固定策略下状态价值的期望展开。如#link(<sec-mc-vq-comparison>)[第 6.3 节「状态价值与动作价值」小节]所述，在环境动力学模型未知的设定下，仅凭状态价值估计 $V(s)$ 无法直接导出贪心控制策略。本节系统阐述从动作价值评估走向无模型最优控制的算法谱系：通过将自举目标中的策略层期望算子替换为#strong[最大化算子 $max$]，智能体无需借助环境模型即可直接从动作价值估计 $Q(s, a)$ 中求解最优策略。

从期望算子到最大化算子的演进涉及三个层面的理论权衡：其一，自举目标是否消除策略层的动作采样方差（SARSA 与 Expected SARSA）；其二，将策略层算子替换为 $max$ 后，更新目标不再依赖实际执行的后继动作，从而天然支持无重要性采样的离轨控制（Q-Learning），但因 $max$ 算子的凸性会引入系统性最大化偏差（Double Q-Learning）；其三，当引入参数化函数近似时，自举、离轨与函数近似的结合可能破坏算子不动点迭代的收敛性（DQN 与致命三元组）。以下依次给出这五类代表性算法的数学构造与理论性质：

1. #strong[SARSA 算法（同轨策略 On-Policy TD 控制，对应 $q_pi arrow.r q_pi$ 全采样随机近似）]：
   由#link(<thm-3.4>)[定理 3.4] 的动作价值贝尔曼期望方程（条件期望形式 @eq-bellman-exp-qq）：
   $
     q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1), A_(t + 1)) [R_(t + 1) + gamma #mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] .
   $
   智能体从 $(S_t, A_t)$ 出发，与环境交互获得 $(R_(t + 1), S_(t + 1))$，并继续按当前策略 $pi$（如 $epsilon$-贪心策略）采样出下一时刻的实际执行动作 $A_(t + 1) tilde.op pi(dot.op divides S_(t + 1))$，组成五元组 $(S_t, A_t, R_(t + 1), S_(t + 1), A_(t + 1))$（SARSA 之名由此而来）。以单样本 $R_(t + 1) + gamma Q(S_(t + 1), A_(t + 1))$ 近似上述三变量联合条件期望，做 Robbins-Monro 更新：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma #mhlg($Q(S_(t + 1), A_(t + 1))$) - Q(S_t, A_t)] $])
   $ <eq-sarsa-update>
   SARSA 评估的是当前正在执行的策略 $pi$；将其与 $epsilon$-贪心策略改进交替执行即构成同轨 TD 控制。表格型 SARSA 以概率 $1$ 收敛于 $q_star$ 的充分条件为：所有 $(s, a)$ 被无限次访问、各 $(s, a)$ 的步长满足 Robbins-Monro 条件（@eq-rm-step-conditions），且行为策略序列满足 GLIE 条件（Singh et al., 2000）。
   - #strong[方法动机与核心机制]：@eq-bellman-exp-qq 右端的条件期望同时包含环境转移 $(R_(t + 1), S_(t + 1))$ 与后继动作 $A_(t + 1)$ 两层随机性；SARSA 对这两层随机性均采用单样本采样近似。
   - #strong[理论性质与所依方程]：严格对应动作价值贝尔曼期望方程 @eq-bellman-exp-qq；由于更新目标直接依赖实际采样执行的后继动作 $A_(t + 1) tilde.op pi$，属于同轨（On-Policy）算法，且目标中包含后继动作采样带来的策略层方差。

2. #strong[期望 SARSA 算法（Expected SARSA，对应 $q_pi arrow.r q_pi$ 环境层采样 + 策略层精确期望）]：
   回顾#link(<sec-cond-qq>)[第 3.4 节]对 @eq-bellman-exp-qq 的嵌套期望分解：$q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma bb(E)_(A_(t + 1) tilde.op pi) [q_pi (S_(t + 1), A_(t + 1))] divides S_t = s, A_t = a]$。虽然环境转移分布 $p(s', r divides s, a)$ 未知（必须通过采样 $(R_(t + 1), S_(t + 1))$ 做随机近似），但#strong[智能体自身的策略分布 $pi(a' divides S_(t + 1))$ 完全已知]。因此，无需对下一动作 $A_(t + 1)$ 进行随机采样，而可直接对后继动作求精确期望：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma sum_(a' in cal(A)) #mhl($pi(a' divides S_(t + 1))$) #mhlg($Q(S_(t + 1), a')$) - Q(S_t, A_t)] $])
   $ <eq-expected-sarsa-update>
   #strong[理论优势]：Expected SARSA 完全消除了因随机采样 $A_(t + 1)$ 引入的策略层采样方差，在相同步长下比标准 SARSA 具有更低的估计方差与更高的数值稳定性；同时，它既可用于同轨评估与控制，也可自然用于离轨评估（由行为策略 $b$ 生成转移样本，而在求和项中代入目标策略 $pi$ 的概率）。
   - #strong[方法动机与核心机制]：针对 SARSA 因采样 $A_(t + 1)$ 引入额外方差的局限，利用策略分布 $pi(a' divides S_(t + 1))$ 已知这一性质，将策略层由单次采样改为显式加权求和，仅在环境层保留采样近似。
   - #strong[理论性质与所依方程]：对应贝尔曼期望方程 @eq-bellman-exp-qq；以每步增加 $O(|cal(A)|)$ 次动作求和运算为代价，消除策略层采样方差，并在无需重要性采样比的条件下支持单步离轨策略评估。

3. #strong[Q-Learning 算法（离轨策略 Off-Policy TD 控制，对应贝尔曼最优方程 $q_star arrow.r q_star$ 随机近似）]：
   Watkins (1989) 提出的 Q-Learning 不再经过“先评估 $q_pi$、再改进 $pi$”的交替过程，而是直接对#link(<thm-5.4>)[定理 5.4] 的#strong[动作价值贝尔曼最优方程]（条件期望形式 @eq-opt-cond-qq）：
   $
     q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a]
   $
   应用 Robbins-Monro 随机近似：智能体按行为策略 $b$（如 $epsilon$-贪心）采样四元组 $(S_t, A_t, R_(t + 1), S_(t + 1))$，直接将后继状态的最大动作价值 $max_(a') Q(S_(t + 1), a')$ 作为自举目标（注：亦可从 Expected SARSA 的角度理解——当目标策略 $pi$ 取为关于当前 $Q$ 的确定性贪心策略时，@eq-expected-sarsa-update 即退化为 Q-Learning）：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($Q(S_(t + 1), a')$) - Q(S_t, A_t)] $])
   $ <eq-td-control>
   #strong[$max$ 与 $bb(E)$ 的内外顺序及离轨性]：对比状态价值与动作价值贝尔曼最优方程（#link(<thm-5.3>)[定理 5.3]，@eq-opt-cond-vv；#link(<thm-5.4>)[定理 5.4]，@eq-opt-cond-qq）中最大化算子与条件期望算子的位置：
   $
     v_star (s) & = #mhl($max_(a in cal(A))$) #mhlb($bb(E)_(R_(t + 1), S_(t + 1))$) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a], \
     q_star (s, a) & = #mhlb($bb(E)_(R_(t + 1), S_(t + 1))$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a] .
   $ <eq-max-expectation-order>
   - 在 $v_star$ 的方程中 $max_a$ 位于条件期望之外。若直接对单次采样回报取最大，将把期望算子与最大化算子非法交换，引入严重的正向偏差；此外，即使已知 $v_star$，从 $v_star$ 提取贪心动作仍需已知一步环境转移模型。因此，无模型最优控制必须以动作价值 $q_star$ 为估计对象。
   - 在 $q_star$ 的方程中条件期望位于最外层，对给定的采样后继状态 $S_(t + 1) = s'$，$max_(a') Q(s', a')$ 仅需在动作空间上做确定性最大化。给定 $(S_t = s, A_t = a)$ 后，$(R_(t + 1), S_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 仅由环境转移律决定，与生成轨迹的行为策略 $b$ 无关，后继动作亦无需按目标策略采样，因此 Q-Learning 无需重要性采样即可直接进行离轨控制（见#link(<sec-importance-sampling>)[第 6.4 节]第 5 项）。
   在有限 MDP、奖励有界、行为策略 $b$ 使所有 $(s, a)$ 被无限次访问，且按各 $(s, a)$ 访问次数定义的步长满足 Robbins-Monro 条件时，表格型 $Q(s, a)$ 以概率 $1$ 收敛于最优动作价值 $q_star (s, a)$（Watkins & Dayan, 1992），对行为策略 $b$ 无 GLIE 要求。
   - #strong[方法动机与核心机制]：同轨 SARSA 的更新目标依赖含探索噪声的实际执行动作 $A_(t + 1)$，所评估的是带探索的软策略而非最优策略；Q-Learning 将策略层算子替换为贪心最大化 $max_(a')$，使更新目标直接逼近贝尔曼最优算子。
   - #strong[理论性质与所依方程]：直接对应动作价值贝尔曼最优方程 @eq-opt-cond-qq；实现了探索策略 $b$ 与目标最优策略 $pi_star$ 的解耦（天然离轨且无需重要性采样），但因对含噪估计取最大值而引入系统性高估偏差。

4. #strong[最大化偏差（Maximization Bias）与 Double Q-Learning]：
   在 Q-Learning（@eq-td-control）中，目标项使用带有随机估计误差的同一个价值表 $Q$ 同时完成#strong[选出最大动作]（$a^star = arg max_(a') Q(S_(t + 1), a')$）与#strong[评估该动作的价值]（$Q(S_(t + 1), a^star) = max_(a') Q(S_(t + 1), a')$）。由于 $max$ 是凸函数，即便每个动作的价值估计 $hat(Q)(s', a')$ 都是真值 $q_star (s', a')$ 的无偏估计（$bb(E)[hat(Q)(s', a')] = q_star (s', a')$），由 #strong[Jensen 不等式]必有：
   $
     #mhl($bb(E) [max_(a' in cal(A)) hat(Q)(s', a')]$) gt.eq #mhlb($max_(a' in cal(A)) bb(E) [hat(Q)(s', a')]$) = max_(a' in cal(A)) q_star (s', a') ,
   $ <eq-maximization-bias>
   即“#strong[最大值的期望不小于期望的最大值]”，导致 Q-Learning 系统性地高估（Overestimate）动作价值。#strong[Double Q-Learning]（Hasselt, 2010）通过维护两份相互独立的价值估计器 $Q_1, Q_2$ 来解耦“动作选择”与“价值评估”（每步以 $0.5$ 概率随机选择其一进行更新，如用 $Q_1$ 选出贪心动作 $a^star = arg max_(a') Q_1(S_(t + 1), a')$，再用另一份估计器 $Q_2$ 评估该动作的价值）：
   $
     Q_1 (S_t, A_t) arrow.l Q_1 (S_t, A_t) + alpha [R_(t + 1) + gamma #mhlg($Q_2 (S_(t + 1), #mhl($arg max_(a') Q_1 (S_(t + 1), a')$))$) - Q_1 (S_t, A_t)] ,
   $ <eq-double-q-learning>
   另一半步骤则对称地交换 $Q_1, Q_2$ 的角色。若 $Q_2$ 无偏且其评估误差与 $Q_1$ 的选择误差条件独立，则 $bb(E)[Q_2 (s', a^star)] = q_star (s', a^star) lt.eq max_(a') q_star (s', a')$，从而消除正向最大化偏差（可能表现为轻微低估）。深度强化学习中的 Double DQN 与 TD3 的截断双评论家（Clipped Double-Q）均沿用了这一去偏机制。
   - #strong[方法动机与核心机制]：克服 @eq-td-control 因复用同一带噪估计器同时执行动作最大化选择与价值评估所导致的 Jensen 不等式正向偏差（@eq-maximization-bias），通过双估计器交叉评估实现统计解耦。
   - #strong[理论性质与所依方程]：底层不动点方程仍为贝尔曼最优方程 @eq-opt-cond-qq（属纯统计估计器层面的去偏修正，不改变算子不动点）；以双倍存储开销为代价消除了最大化高估偏差。

5. #strong[从表格型随机近似到参数化函数近似（DQN 与半梯度更新）]：
   当状态空间 $cal(S)$ 为高维或连续空间时，表格型存储不再可行，需采用参数化函数 $hat(v)(s; bold(theta))$ 或 $hat(q)(s, a; bold(theta))$（如深度神经网络）逼近价值函数。此时将目标网络参数 $bold(theta)^-$ 视为固定常数（即对自举目标不反传梯度的#strong[半梯度法]，Semi-gradient Method），对均方 TD 误差 $cal(L)(bold(theta)) = 1 / 2 [y_t^upright("TD") - hat(q)(S_t, A_t; bold(theta))]^2$ 执行随机梯度下降，即得到 #strong[DQN（Deep Q-Network）] 的参数更新律：
   $
     bold(theta)_(t + 1) = bold(theta)_t + #mhl($alpha$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($hat(q)(S_(t + 1), a'; bold(theta)^-)$) - hat(q)(S_t, A_t; bold(theta)_t)] #mhlb($nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)_t)$) .
   $ <eq-dqn-update>
   当取表格型独热特征表示（One-Hot Feature）时，$nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)) = bold(e)_((S_t, A_t))$，@eq-dqn-update 精确退化为表格型 Q-Learning（@eq-td-control）。DQN 同时引入经验回放（Experience Replay）以打破轨迹样本的时序相关性，并通过周期性同步目标网络参数 $bold(theta)^- arrow.l bold(theta)$ 减缓自举目标的非平稳漂移。

   #strong[函数近似下的收敛性边界与致命三元组]：前述 TD(0)、SARSA 与 Q-Learning 以概率 $1$ 收敛的理论保证均建立在有限表格型表示之上。引入参数化函数近似后，贝尔曼算子作用后的结果一般不再落入函数近似子空间内，且半梯度更新并非任何固定目标函数的真实梯度下降。经典理论表明：在同轨采样下，线性函数近似 TD(0) 仍收敛于投影贝尔曼方程的唯一不动点，其渐近误差不超过最优线性逼近误差的 $1 \/ (1 - gamma)$ 倍（Tsitsiklis & Van Roy, 1997）；然而，当#strong[函数近似（Function Approximation）]、#strong[自举（Bootstrapping）]与#strong[离轨训练（Off-Policy Training）]三者同时存在——即构成所谓的#strong[致命三元组（Deadly Triad）]时，复合算子不再保证具有压缩映射性质，即便在线性函数近似下迭代参数亦可能发散至无穷（Baird, 1995）。因此，DQN 等非线性离轨自举方法在理论上缺乏全局收敛保证，其训练稳定性高度依赖目标网络与经验回放等稳定化机制。
   - #strong[方法动机与核心机制]：突破表格型方法在大规模或连续状态空间中的维数灾难，以参数化近似器 $hat(q)(s, a; bold(theta))$ 替代查找表，并沿半梯度方向更新参数（@eq-dqn-update）。
   - #strong[理论性质与所依方程]：目标结构仍基于贝尔曼最优方程 @eq-opt-cond-qq；具备跨状态泛化能力，但因同时触发“致命三元组”而丧失 Banach 压缩不动点收敛保证。

#divider()

== 核心扩展三 · 离轨多步估计的方差控制（截断重要性采样与回溯修正）
<sec-offpolicy-multistep>
#link(<sec-importance-sampling>)[第 6.4 节]表明，在离轨设定下乘以重要性采样比 $rho$ 可恢复多步回报期望的无偏性，但连乘结构（@eq-importance-sampling-ratio、@eq-per-decision-is）会导致估计方差随步数呈指数级增长；另一方面，#link(<sec-td-estimation>)[第 6.5 节]指出，引入多步自举回报（$n$-步 TD 与 TD($lambda$)）能够有效加快信用分配并降低单步自举偏差。当试图将“离轨数据复用”与“多步自举回报”相结合时，便面临乘性似然比带来的严重方差失控问题。

为在离轨多步估计中兼顾数值稳定性与收敛性能，核心思路是对重要性采样比率引入#strong[逐项截断（Truncation）]。根据截断位置是直接作用于无自举回报、仅作用于多步资格迹回溯系数，还是同时作用于单步 TD 误差本身，可严格区分出以下三类具有不同不动点性质的机制：

1. #strong[朴素截断重要性采样（无自举校正时的渐近偏差）]：
   若直接在多步连乘似然比 $rho_(t + 1 : t + n) = product_(k = t + 1)^(t + n) frac(pi(A_k divides S_k), b(A_k divides S_k))$ 中将每一项截断于上界常数 $bar(c) > 0$：
   $
     bar(rho)_(t + 1 : t + n) eq.dot product_(k = t + 1)^(t + n) min (bar(c), frac(pi(A_k divides S_k), b(A_k divides S_k))) ,
   $ <eq-truncated-is>
   则每一因子均以概率 $1$ 有界，连乘积的方差随之受到严格控制。然而，若直接将 @eq-truncated-is 用于对完整回报 $G_t$ 加权而不做自举误差修正，则由于 $min(bar(c), dot.op)$ 严格压低了大权重样本的期望贡献，估计量将产生无法随样本量增大而消除的渐近偏差。

2. #strong[Retrace($lambda$) 算法（截断多步回溯系数，严格保持不动点 $q_pi$ 不变）]：
   为在截断似然比以控制方差的同时消除渐近偏差，Munos et al. (2016) 提出了基于动作价值的离轨多步估计算法 #strong[Retrace($lambda$)]。其核心思想是将多步更新写成沿轨迹对#strong[动作价值在目标策略期望下的单步 TD 误差]的加权累加：
   $
     Q^upright("Retrace") (S_t, A_t) eq.dot Q(S_t, A_t) + sum_(k = t)^(T - 1) gamma^(k - t) (#mhl($product_(j = t + 1)^k bar(c)_j$)) #mhlg($delta_k^Q$), #h(1.5em) bar(c)_j = lambda min(bar(c), frac(pi(A_j divides S_j), b(A_j divides S_j))) ,
   $ <eq-retrace>
   （注：文献中常取 $bar(c) = 1$ 并把 $lambda$ 并入迹系数或写为 $lambda^((k - t)) product_(j = t + 1)^k min(bar(c), frac(pi(A_j divides S_j), b(A_j divides S_j)))$，二者仅差记号写法。）其中#strong[动作价值的单步期望 TD 误差 $delta_k^Q$] 定义为（对比状态价值的一步 TD 误差 @eq-td-target-error）：
   $
     delta_k^Q eq.dot R_(k + 1) + gamma #mhlb($bb(E)_(A' tilde.op pi(dot.op divides S_(k + 1))) [Q(S_(k + 1), A')]$) - Q(S_k, A_k) = R_(k + 1) + gamma sum_(a' in cal(A)) pi(a' divides S_(k + 1)) Q(S_(k + 1), a') - Q(S_k, A_k) .
   $ <eq-retrace-td-error>
   #strong[不动点不变性定理（Munos et al., 2016, Theorem 1）]：与直接对回报截断不同，Retrace($lambda$) 算子的唯一不动点#strong[严格保持为目标策略的真实动作价值 $q_pi$，不因截断阈值 $bar(c)$ 而发生偏移]！其数学机理在于：当 $Q = q_pi$ 时，由动作价值贝尔曼期望方程（@eq-exp-explicit-qq），对轨迹上任意时刻的状态-动作对 $(S_k, A_k)$，单步期望 TD 误差的条件期望均精确为零：
   $
     bb(E)_b [delta_k^Q divides S_k, A_k] = bb(E)_p [R_(k + 1) + gamma sum_(a') pi(a' divides S_(k + 1)) q_pi (S_(k + 1), a') divides S_k, A_k] - q_pi (S_k, A_k) = 0 .
   $
   由于在时刻 $k$ 之前决定的非负截断迹系数 $product_(j = t + 1)^k bar(c)_j$ 关于给定 $(S_k, A_k)$ 后的环境一步转移 $(R_(k + 1), S_(k + 1))$ 是条件已知的常数，由全期望公式（#link(<lem-2>)[引理 2]）与条件已知量提取性质（P9），@eq-retrace 中求和号的每一项在 $Q = q_pi$ 处的期望均恒等于零，故 $bb(E)_b [Q^upright("Retrace")(s, a)] = q_pi (s, a)$。不仅如此，当取 $bar(c) lt.eq 1$ 时，对任意行为策略 $b$ 与目标策略 $pi$，Retrace 算子在最大模范数下恒为压缩映射（无发散风险）。在此机制下，截断系数 $bar(c)_j$ 仅起到#strong[自适应调节有效多步自举视野]的作用：当 $pi$ 与 $b$ 接近时保留长视野多步回溯以加速收敛；当 $pi$ 与 $b$ 偏离较大时自动衰减后续项权重、平滑退化向单步 Expected SARSA，从而在不改变不动点 $q_pi$ 的前提下实现方差有界。

3. #strong[V-trace 算法（同时截断单步 TD 误差权重与回溯迹系数，改变算子不动点）]：
   在估计#strong[状态价值 $V(s)$] 的分布式 Actor-Learner 架构（IMPALA, Espeholt et al., 2018）中，由于状态价值的单步 TD 误差 $delta_k^V eq.dot R_(k + 1) + gamma V(S_(k + 1)) - V(S_k)$ 依赖于在时刻 $k$ 按行为策略 $b$ 实际采样的动作 $A_k$（而非像 @eq-retrace-td-error 那样在给定 $A_k$ 后只剩环境转移），即使在 $V = v_pi$ 处仍有 $bb(E)_b [delta_k^V divides S_k] = (cal(T)^b_V v_pi)(S_k) - v_pi (S_k) eq.not 0$。因此，必须对时刻 $k$ 的单步 TD 误差本身也乘以重要性采样比进行修正。#strong[V-trace] 为此引入两个独立的截断阈值 $bar(rho) gt.eq bar(c)$，分别定义单步误差截断权重 $rho_k eq.dot min(bar(rho), frac(pi(A_k divides S_k), b(A_k divides S_k)))$ 与多步回溯迹系数 $c_j eq.dot min(bar(c), frac(pi(A_j divides S_j), b(A_j divides S_j)))$，构造 $n$-步状态价值目标：
   $
     v_t^upright("V-trace") eq.dot V(S_t) + sum_(k = t)^(t + n - 1) gamma^(k - t) (#mhl($product_(j = t)^(k - 1) c_j$)) #mhlb($rho_k$) #mhlg($delta_k^V$) .
   $ <eq-vtrace>
   #strong[两个截断阈值的角色分工与不动点偏移]：
   - 迹系数 $c_j$（受 $bar(c)$ 截断）与 Retrace 中的 $bar(c)_j$ 作用相同：它只影响多步误差向前回溯的衰减速度（收缩模长），#strong[不改变算子的不动点]；
   - 单步权重 $rho_k$（受 $bar(rho)$ 截断）直接决定了单步贝尔曼更新所逼近的目标策略：当取 $bar(rho) = oo$（不截断 $rho_k$）时，不动点仍精确为 $v_pi$；当为抑制单步极端权重方差而取有限阈值 $bar(rho) < oo$ 时，V-trace 算子的唯一不动点将#strong[偏移为介于行为策略 $b$ 与目标策略 $pi$ 之间的软截断混合策略价值 $v_(pi_(bar(rho)))$]，其中等效目标策略定义为：
     $
       pi_(bar(rho)) (a divides s) eq.dot frac(min(bar(rho) thin b(a divides s), thin pi(a divides s)), sum_(a' in cal(A)) min(bar(rho) thin b(a' divides s), thin pi(a' divides s))) .
     $ <eq-vtrace-fixed-point-policy>

4. #strong[与贝尔曼方程的关系辨析]：
   对比上述机制可以清晰地界定截断操作对贝尔曼不动点的不同影响：在动作价值估计中，Retrace($lambda$)（@eq-retrace）利用给定 $(S_k, A_k)$ 后单步期望 TD 误差为零的性质，仅截断多步传递系数 $bar(c)_j$，从而在保证方差有界的同时#strong[严格保留贝尔曼期望方程的不动点 $q_pi$ 不变]；而在状态价值估计中，V-trace（@eq-vtrace）由于必须在单步 TD 误差上乘以似然比 $rho_k$，当对 $rho_k$ 施加有限截断 $bar(rho) < oo$ 时，实质上#strong[改写了所求解的贝尔曼期望方程本身]，以容忍目标不动点从 $v_pi$ 微小偏移至 $v_(pi_(bar(rho)))$ 为代价，换取大规模异步离轨训练下的有界方差与收缩稳定性。

#divider()

== 三类估计方法的回溯结构对比与核心扩展总览
<sec-estimation-comparison>
综合#link(<sec-dp-fixed-point>)[第 6.2]--#link(<sec-offpolicy-multistep>)[6.7 节]，动态规划（DP）、蒙特卡洛（MC）与时序差分（TD）构成了强化学习价值估计的三类基本范式。三者在马尔可夫决策树上的回溯广度（Width）与深度（Depth）截然不同（见 @fig-dp-mc-td-backups），针对状态价值与动作价值的全部估计算法及统计特征汇总于 @tab-all-value-estimators。

#figure(
  grid(
    columns: (1fr, 1fr, 1fr),
    column-gutter: 4mm,
    row-gutter: 3mm,
    align: center + top,
    text(size: 8.5pt)[*动态规划（DP）* \ 全宽 · 单步 · 精确期望 \ 自举 · 需模型 $p$],
    text(size: 8.5pt)[*蒙特卡洛（MC）* \ 单轨 · 采样至终止 \ 不自举 · 免模型],
    text(size: 8.5pt)[*时序差分（TD）* \ 单轨 · 单步采样 \ 自举 · 免模型],
    diagram(
      spacing: (5mm, 9mm),
      node-stroke: 0.8pt + accent,
      edge-stroke: 0.8pt + accent,
      node((1.5, 0), [$V(S_t)$], radius: 15pt, fill: accent-soft),
      node((0.5, 1), text(fill: white, size: 7pt)[$a_1$], radius: 7.5pt, fill: accent),
      node((2.5, 1), text(fill: white, size: 7pt)[$a_2$], radius: 7.5pt, fill: accent),
      edge((1.5, 0), (0.5, 1), "->", text(size: 7pt)[$pi$], label-side: right),
      edge((1.5, 0), (2.5, 1), "->", text(size: 7pt)[$pi$], label-side: left),
      ..((0, 1, 0), (1, 1, 1), (2, 2, 0), (3, 2, 1)).map(((x, i, side)) => (
        node((x, 2), [$s'_#(x + 1)$], radius: 8.5pt, fill: hl-green-fill, stroke: 0.8pt + hl-green-stroke),
        edge((if i == 1 { 0.5 } else { 2.5 }, 1), (x, 2), "->", text(size: 7pt)[$p$], label-side: if side == 0 { right } else { left }),
      )).flatten(),
    ),
    diagram(
      spacing: (5mm, 8mm),
      node-stroke: 0.8pt + warn-stroke,
      edge-stroke: 1.2pt + warn-stroke,
      node((0, 0), [$V(S_t)$], radius: 15pt, fill: accent-soft, stroke: 0.8pt + accent),
      node((0, 1), text(fill: white, size: 7pt)[$A_t$], radius: 7.5pt, fill: warn-stroke),
      node((0, 2), text(size: 8pt)[$S_(t+1)$], radius: 11pt, fill: white),
      node((0, 3), [$S_T$], shape: rect, fill: warn-soft, inset: 4pt),
      edge((0, 0), (0, 1), "->", text(size: 7pt)[采样 $A_t$], label-side: left),
      edge((0, 1), (0, 2), "->", text(size: 7pt)[$R_(t+1), S_(t+1)$], label-side: left),
      edge((0, 2), (0, 3), "-->", text(size: 7pt)[直至终止，得 $G_t$], label-side: left),
    ),
    diagram(
      spacing: (5mm, 9mm),
      node-stroke: 0.8pt + hl-green-stroke,
      edge-stroke: 1.2pt + hl-green-stroke,
      node((0, 0), [$V(S_t)$], radius: 15pt, fill: accent-soft, stroke: 0.8pt + accent),
      node((0, 1), text(fill: white, size: 7pt)[$A_t$], radius: 7.5pt, fill: hl-green-stroke),
      node((0, 2), text(size: 8pt)[$V(S_(t+1))$], radius: 19pt, fill: hl-green-fill),
      edge((0, 0), (0, 1), "->", text(size: 7pt)[采样 $A_t$], label-side: left),
      edge((0, 1), (0, 2), "->", text(size: 7pt)[采样 $R_(t+1), S_(t+1)$], label-side: left),
    ),
  ),
  caption: [三类价值估计方法的回溯结构：动态规划对一步内全部动作与后继状态精确求期望；蒙特卡洛沿单条轨迹采样到终止；时序差分采样一步后以 $V(S_(t+1))$ 自举],
) <fig-dp-mc-td-backups>

#figure(
  caption: [状态价值（$v_pi, v_star$）与动作价值（$q_pi, q_star$）的估计算法、所依方程与更新公式汇总。表中 $bb(E)_p [f] eq.dot sum_(s', r) p(s', r divides s, a) f(s', r)$；“对象”列为每次更新所估计的价值函数，括注为外层 GPI 控制的极限],
  text(size: 8.6pt, table(
    columns: (24mm, 16mm, 29mm, 1fr),
    align: (center + horizon, center + horizon, left + horizon, left + horizon),
    table.header(
      [估计方法],
      [对象],
      [算法与所依方程],
      [迭代 / 增量更新公式],
    ),
    table.hline(),
    table.cell(rowspan: 4)[#strong[不动点迭代] \ （DP） \ #link(<prop-6.1>)[命题 6.1] \ 需模型 \ 自举],
    [$v_pi$], [迭代策略评估 \ @eq-exp-explicit-vv],
    [$V_(k+1)(s) arrow.l sum_a pi(a divides s) bb(E)_p [r + gamma V_k (s')]$],
    [$v_star$], [值迭代 \ @eq-opt-explicit-vv],
    [$V_(k+1)(s) arrow.l max_a bb(E)_p [r + gamma V_k (s')]$],
    [$q_pi$], [$Q$-策略评估 \ @eq-exp-explicit-qq],
    [$Q_(k+1)(s, a) arrow.l bb(E)_p [r + gamma sum_(a') pi(a' divides s') Q_k (s', a')]$],
    [$q_star$], [$Q$-值迭代 \ @eq-opt-explicit-qq],
    [$Q_(k+1)(s, a) arrow.l bb(E)_p [r + gamma max_(a') Q_k (s', a')]$],
    table.hline(stroke: 0.6pt + accent),
    table.cell(rowspan: 4)[#strong[蒙特卡洛] \ （MC） \ #link(<prop-6.2>)[命题 6.2] \ 免模型 \ 不自举],
    [$v_pi$], [首次 / 每次访问 MC \ @eq-v-def],
    [$V(S_t) arrow.l V(S_t) + frac(1, N(S_t)) [G_t - V(S_t)]$ \ 首次访问无偏；每次访问渐近无偏],
    [$q_pi$], [MCES \ @eq-q-def + GPI],
    [$Q(S_t, A_t) arrow.l Q(S_t, A_t) + alpha [G_t - Q(S_t, A_t)]$ \ 再令 $pi arrow.l$ greedy$(Q)$；一般收敛性尚无完整证明],
    [$q_pi$], [$epsilon$-软 MC \ @eq-q-def + GPI],
    [$Q(S_t, A_t) arrow.l Q(S_t, A_t) + alpha [G_t - Q(S_t, A_t)]$ \ 再令 $pi arrow.l epsilon$-greedy$(Q)$ \ GLIE + RM 步长 + GPI 时 $Q arrow.r q_star$],
    [$q_pi$], [离轨 MC（WIS） \ @eq-importance-sampling-ratio],
    [$W = rho_(t+1:T-1)$，$C arrow.l C + W$ \ $Q(S_t, A_t) arrow.l Q(S_t, A_t) + frac(W, C) [G_t - Q(S_t, A_t)]$ \ WIS 有偏、渐近无偏],
    table.hline(stroke: 0.6pt + accent),
    table.cell(rowspan: 5)[#strong[随机近似] \ （TD） \ #link(<thm-6.1>)[定理 6.1] \ 免模型 \ 自举 \ 目标有偏],
    [$v_pi$], [TD(0) \ @eq-bellman-exp-vv],
    [$V(S_t) arrow.l V(S_t) + alpha [R_(t+1) + gamma V(S_(t+1)) - V(S_t)]$],
    [$v_pi$], [$n$ 步 TD、TD($lambda$) \ @eq-n-step-td、@eq-td-lambda-trace],
    [$V(S_t) arrow.l V(S_t) + alpha [G_(t:t+n) - V(S_t)]$ \ $V(s) arrow.l V(s) + alpha delta_t z_t (s)$],
    [$q_pi$ \ GPI → $q_star$], [SARSA \ @eq-bellman-exp-qq],
    [$Q(S_t, A_t) arrow.l Q(S_t, A_t) + alpha [R_(t+1)$ \ $quad + gamma Q(S_(t+1), A_(t+1)) - Q(S_t, A_t)]$],
    [$q_pi$], [Expected SARSA \ @eq-bellman-exp-qq],
    [$Q(S_t, A_t) arrow.l Q(S_t, A_t) + alpha [R_(t+1)$ \ $quad + gamma sum_(a') pi(a' divides S_(t+1)) Q(S_(t+1), a') - Q(S_t, A_t)]$],
    [$q_star$], [Q-Learning \ @eq-opt-cond-qq],
    [$Q(S_t, A_t) arrow.l Q(S_t, A_t) + alpha [R_(t+1)$ \ $quad + gamma max_(a') Q(S_(t+1), a') - Q(S_t, A_t)]$],
  )),
) <tab-all-value-estimators>

在三条基本估计路线之上，为应对采样分布偏移、无模型最优控制与离轨多步高方差，本章建立了三项核心扩展机制。这些扩展机制在保持通用增量更新框架不变的前提下，通过对样本重加权或重塑目标值 $y_k$ 实现功能扩展；三项扩展机制的核心问题、修正方案、统计代价及所对应的底层方程汇总于 @tab-estimation-patches。

#figure(
  caption: [三类基本估计路线之上的三项核心扩展机制汇总：问题症结、核心修正机制、统计代价以及与贝尔曼不动点方程的对应关系],
  text(size: 8.4pt, table(
    columns: (1.15fr, 0.9fr, 1.7fr, 1.35fr, 1.15fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header(
      [核心问题],
      [扩展机制],
      [方法修正],
      [统计代价与理论性质],
      [对应方程与不动点],
      [代表算法],
    ),
    table.hline(),
    [样本分布与目标分布错配：样本由行为策略 $b$ 生成，直接求均值收敛于 $q_b$ 而非 $q_pi$（或 $v_b$ 而非 $v_pi$）],
    [扩展一 \ 重要性采样 \ #link(<sec-importance-sampling>)[6.4 节]],
    [乘以轨迹似然比（估 $q_pi$ 用 $rho_(t + 1:T - 1)$，估 $v_pi$ 用 $rho_(t:T - 1)$），环境转移概率相消；加权 IS 以权重和归一化],
    [OIS 无偏但方差随幕长指数增长；WIS 方差有界，有限样本有偏、渐近无偏],
    [贝尔曼期望方程 \ @eq-bellman-exp-vv / @eq-bellman-exp-qq \ （不动点保持 $v_pi, q_pi$）],
    [离轨 MC \ OIS / WIS \ 逐决策 IS],
    table.hline(stroke: 0.6pt + accent),
    [无模型下无法从 $V$ 提取策略；策略层期望算子无法直接求得最优价值，且对带噪估计取最大会产生正向偏差],
    [扩展二 \ 动作价值与贪心最大化 \ #link(<sec-td-action-value>)[6.6 节]],
    [直接估计 $Q$，将目标中策略层求和 $sum_(a') pi(a' divides s')$ 替换为 $max_(a')$（天然支持单步离轨）；双估计器解耦选与评],
    [单估计器产生最大化高估偏差；结合函数近似与离轨自举触发“致命三元组”可致发散],
    [贝尔曼最优方程 \ @eq-opt-cond-qq \ （不动点为 $q_star$）],
    [$Q$-Learning \ Double $Q$ \ DQN],
    table.hline(stroke: 0.6pt + accent),
    [离轨与多步回报叠加时，似然比沿轨迹连乘导致方差失控],
    [扩展三 \ 截断重要性采样与回溯 \ #link(<sec-offpolicy-multistep>)[6.7 节]],
    [Retrace($lambda$) 仅截断多步回溯迹系数 $bar(c)_j$；V-trace 同时以 $bar(c)$ 截断迹系数并以 $bar(rho)$ 截断单步 TD 误差权重 $rho_k$],
    [收缩有效多步视野以保证方差有界；当 V-trace 取 $bar(rho) < oo$ 时引入渐近目标偏差],
    [Retrace 保持不动点 $q_pi$（@eq-retrace）；V-trace（$bar(rho) < oo$）不动点偏移为 $v_(pi_(bar(rho)))$（@eq-vtrace）],
    [Retrace($lambda$) \ V-trace],
  )),
) <tab-estimation-patches>

#divider()

// ============================================================
//  第 7 章：策略梯度——直接对期望回报目标求导
// ============================================================
= 策略梯度：直接对期望回报目标求导
<sec-policy-gradient>

#link(<sec-value-estimation>)[第 6 章]的三条估计路线均建立在同一个前提之上：将贝尔曼方程作为#strong[求解对象]，先估计出价值函数 $v_pi$ 或 $q_star$，再通过贪心算子导出控制策略。本章阐述强化学习的另一条核心范式：将策略显式建模为关于参数 $bold(theta)$ 的可微函数 $pi_bold(theta) (a divides s)$，直接对#strong[期望回报目标函数] $J(bold(theta))$ 求梯度并执行梯度上升。这一范式不再以求解贝尔曼不动点方程为目标，但全面复用了第 6 章所建立的期望估计工具——其统计估计的对象由“状态/动作价值”转化为“策略目标的梯度”。本章依次论述：记号与问题设定的局部扩展（#link(<sec-pg-setup>)[第 7.1 节]）、基于价值的方法在三类场景下的理论局限（#link(<sec-pg-motivation>)[第 7.2 节]）、策略梯度定理的严密推导（#link(<sec-pg-theorem>)[第 7.3 节]）、蒙特卡洛策略梯度 REINFORCE（#link(<sec-reinforce>)[第 7.4 节]）、状态基线与优势函数（#link(<sec-pg-baseline>)[第 7.5 节]）、Actor-Critic 架构与兼容函数近似（#link(<sec-actor-critic>)[第 7.6 节]）、广义优势估计 GAE（#link(<sec-gae>)[第 7.7 节]）、策略梯度与贝尔曼方程的理论边界（#link(<sec-pg-vs-bellman>)[第 7.8 节]），以及针对三类核心优化难题的代表性算法变体（#link(<sec-pg-variants>)[第 7.9 节]）。
本章最后一节将信任域裁剪框架进一步延伸至大语言模型的可验证奖励强化学习（RLVR）算法谱系，从三个核心设计维度统一剖析 GRPO、DAPO、GSPO 与 DCPO 的演进逻辑（#link(<sec-rlvr-lineage>)[第 7.10 节]）。

#divider()

== 记号与设定的局部扩展
<sec-pg-setup>

第 1--6 章均假定动作空间 $cal(A)$ 为有限集、策略为离散概率分布 $pi(a divides s)$、期望运算写为有限求和。为涵盖#strong[连续动作空间]与#strong[参数化策略]，本章对记号作如下局部扩展（不改变前文约定）：

1. #strong[动作空间可含连续分量]：设 $cal(A) subset.eq bb(R)^m$，策略写为关于动作 $a$ 的#strong[条件概率密度] $pi(a divides s)$，即对任意可测集 $B subset.eq cal(A)$ 有 $Pr(A_t in B divides S_t = s) = integral_B pi(a divides s) dif a$。当 $cal(A)$ 为有限离散集时，只需将积分符号替换为求和符号 $sum_(a in cal(A))$（对应计数测度下的 Radon-Nikodym 导数），所有公式即退化为前文形式；本章统一采用积分记号。
2. #strong[策略参数化]：策略由参数向量 $bold(theta) in bb(R)^d$ 参数化，记为 $pi_bold(theta) (a divides s)$。例如离散动作空间常采用 Softmax 参数化 $pi_bold(theta) (a divides s) prop exp(bold(theta)^top bold(phi)(s, a))$，连续动作空间常采用均值与协方差由神经网络参数化的高斯策略。
3. #strong[正则性与可微性假设]：为保证对数策略梯度 $nabla_bold(theta) log pi_bold(theta) (a divides s)$ 良定义，假设在所考虑的支撑集上 $pi_bold(theta) (a divides s) > 0$ 且关于 $bold(theta)$ 连续可微。
4. #strong[期望回报性能目标]：定义策略优化的性能目标函数为初始状态分布 $d_0$ 下的期望折扣回报：
   $
     J(bold(theta)) eq.dot sum_(s in cal(S)) d_0 (s) v_(pi_bold(theta)) (s) = bb(E)_(S_0 tilde d_0) [v_(pi_bold(theta)) (S_0)] .
   $ <eq-pg-objective>
   本章讨论范围仍为折扣因子 $gamma in [0, 1)$ 的折扣 MDP（或有限视野分幕式 MDP）。
5. #strong[折扣状态访问测度]：定义策略 $pi$ 从初始分布 $d_0$ 出发的未归一化折扣状态访问测度 $mu^pi (s)$ 及其归一化折扣状态分布 $d^pi (s)$ 为：
   $
     mu^pi (s) eq.dot sum_(t = 0)^oo gamma^t Pr(S_t = s divides pi, d_0), quad d^pi (s) eq.dot (1 - gamma) mu^pi (s), quad sum_(s in cal(S)) d^pi (s) = 1 .
   $ <eq-pg-state-visitation>

#divider()

== 方法动机：基于价值的控制方法在三类场景下的理论局限
<sec-pg-motivation>

#link(<sec-value-estimation>)[第 6 章]的控制算法均遵循“先估计动作价值函数、再通过最大化算子提取策略”的间接范式。该范式在以下三类核心场景下面临根本性局限，而直接参数化策略的策略梯度方法则能够自然克服这些困难：

1. #strong[连续动作空间下贪心最大化 $max_a$ 的计算棘手性]：基于价值的方法在每一步决策与目标更新中均需计算 $arg max_(a in cal(A)) Q(s, a)$。当 $cal(A)$ 为有限小集合时，这仅需常数时间的枚举查表；但当 $cal(A) subset.eq bb(R)^m$ 为高维连续空间时，每次动作选取与贝尔曼目标计算均转化为复杂的非凸全局优化问题，计算开销高昂且难以保证求得全局最优。策略梯度方法直接将 $pi_bold(theta) (a divides s)$ 建模为易于采样的参数化分布，交互时直接从策略分布采样动作，训练时沿参数梯度更新，完全无需对动作空间执行最大化搜索。
2. #strong[随机最优策略的表征能力]：确定性贪心策略或固定探索率的 $epsilon$-贪心策略无法收敛于任意内部随机策略。然而在部分可观测马尔可夫决策过程（POMDP，存在感知混淆）或多智能体博弈（如石头剪刀布等零和博弈的纳什均衡）中，#strong[最优策略本身必须是随机混合策略]。参数化策略分布 $pi_bold(theta) (a divides s)$ 可自然表征并以任意精度逼近最优随机策略。
3. #strong[优化目标的一致性与策略变化平滑性]：基于价值的方法最小化的是价值函数的近似残差（如均方 TD 误差），而非直接最大化策略性能指标 $J(bold(theta))$。在函数近似下，极小的动作价值逼近误差可能导致贪心算子 $arg max_a hat(Q)(s, a)$ 发生不连续的跳变，诱发策略性能震荡；相反，策略梯度方法直接沿 $nabla_bold(theta) J(bold(theta))$ 方向连续更新策略参数，保证了策略分布随参数更新平滑演进，且优化目标与真实控制性能严格一致。

两类范式的核心分野见 @fig-pg-vs-value：二者虽同样出发自期望回报定义，但基于价值的方法致力于求解贝尔曼不动点方程，而策略梯度方法则致力于求解性能目标 $J(bold(theta))$ 的一阶平稳点。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (12mm, 8mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 5pt,
      node-corner-radius: 3pt,
      node((1, 0), text(size: 8pt)[*共同起点：折扣回报的数学期望* \ $J = bb(E)[G_0]$，$v_pi = bb(E)[G_t divides S_t = s]$], fill: accent-soft, width: 62mm),
      node((0, 1), text(size: 8pt)[*基于价值的方法（第 6 章）：求解不动点方程* \ 求解对象：贝尔曼期望 / 最优方程的不动点 \ 先估计 $v_pi$ 或 $q_star$，再由 $arg max_a$ 导出策略], fill: hl-blue-fill, stroke: 0.85pt + hl-blue-stroke, width: 62mm),
      node((2, 1), text(size: 8pt)[*策略梯度方法（第 7 章）：直接对性能目标求导* \ 求解对象：$max_bold(theta) J(bold(theta))$ 的一阶平稳点 \ 直接优化 $pi_bold(theta)$，价值仅作为梯度的加权因子], fill: hl-amber-fill, stroke: 0.85pt + hl-amber-stroke, width: 62mm),
      edge((1, 0), (0, 1), "->", text(size: 7pt)[估计价值函数], label-side: right),
      edge((1, 0), (2, 1), "->", text(size: 7pt)[估计目标梯度], label-side: left),
      node((0, 2), text(size: 7.4pt)[核心工具：压缩映射、大数定律、Robbins-Monro], stroke: none, width: 62mm),
      node((2, 2), text(size: 7.4pt)[核心工具：对数导数恒等式、状态基线、优势函数估计 \ （Critic 价值估计直接复用第 6 章工具）], stroke: none, width: 62mm),
    )
  },
  caption: [基于价值的方法与策略梯度方法的理论分野：二者均出发自期望回报；左支以贝尔曼不动点方程为求解对象，右支以期望目标函数的平稳点为求解对象，贝尔曼方程在右支中仅作为优势函数定义与 Critic 价值估计的辅助工具],
) <fig-pg-vs-value>

#divider()

== 策略梯度定理：将目标梯度表征为期望形式
<sec-pg-theorem>

欲沿梯度方向 $nabla_bold(theta) J(bold(theta))$ 优化策略参数，面临两项核心理论障碍：其一，目标函数 $J(bold(theta))$ 定义为轨迹回报的期望，在无模型设定下无法解析求值，因此必须将梯度 $nabla_bold(theta) J(bold(theta))$ 本身也表征为可通过轨迹采样估计的#strong[数学期望形式]；其二，状态价值 $v_(pi_bold(theta)) (s)$ 对参数 $bold(theta)$ 存在复合依赖——既依赖于单步#strong[动作选择分布] $pi_bold(theta) (a divides s)$，又依赖于由策略变化所诱导的#strong[多步状态访问分布] $mu^(pi_bold(theta)) (s)$，而状态访问分布对 $bold(theta)$ 的导数涉及未知的环境转移概率 $p(s' divides s, a)$。以下引理 7.1 与定理 7.1 分别解决了这两项难题。

#strong[引理 7.1（对数导数恒等式，Log-Derivative Trick / Score Function Identity）] <lem-7.1> 设策略密度 $pi_bold(theta) (a divides s) > 0$ 且关于 $bold(theta)$ 可微，则对任意与 $bold(theta)$ 无关的可积函数 $f(a)$（不要求 $f$ 关于 $a$ 可微），有恒等式：
$
  #eqbox([$ integral_(cal(A)) f(a) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) dif a = integral_(cal(A)) pi_bold(theta) (a divides s) f(a) #mhl($nabla_bold(theta) log pi_bold(theta) (a divides s)$) dif a = bb(E)_(A tilde.op pi_bold(theta) (dot.op divides s)) [f(A) #mhl($nabla_bold(theta) log pi_bold(theta) (A divides s)$)] $])
$ <eq-pg-log-derivative>
即“对概率密度求导后再积分”可等价转化为“在该概率密度下对对数导数 $nabla_bold(theta) log pi_bold(theta) (a divides s)$ 加权求期望”。特别地，取常数函数 $f(a) eq.triple 1$，可得得分函数的零均值性质：
$
  bb(E)_(A tilde.op pi_bold(theta) (dot.op divides s)) [nabla_bold(theta) log pi_bold(theta) (A divides s)] = integral_(cal(A)) pi_bold(theta) (a divides s) nabla_bold(theta) log pi_bold(theta) (a divides s) dif a = nabla_bold(theta) integral_(cal(A)) pi_bold(theta) (a divides s) dif a = nabla_bold(theta) 1 = bold(0) .
$ <eq-pg-score-zero>

#strong[证明]：由微积分对数求导法则 $nabla_bold(theta) log pi_bold(theta) (a divides s) = frac(nabla_bold(theta) pi_bold(theta) (a divides s), pi_bold(theta) (a divides s))$，两边同乘 $pi_bold(theta) (a divides s)$ 即得 $nabla_bold(theta) pi_bold(theta) (a divides s) = pi_bold(theta) (a divides s) nabla_bold(theta) log pi_bold(theta) (a divides s)$，代入左端积分立得 @eq-pg-log-derivative。取 $f(a) eq.triple 1$ 时，在满足控制收敛定理的正则条件下可交换微分与积分次序；由于概率密度归一化条件 $integral_(cal(A)) pi_bold(theta) (a divides s) dif a = 1$ 对任意 $bold(theta)$ 恒成立，故其关于 $bold(theta)$ 的梯度恒为零向量。$#h(2em) square.filled.medium$

对数导数恒等式（@eq-pg-log-derivative）是策略梯度理论的核心桥梁：它将概率测度的微分算子转化为该测度下的期望算子，从而使#link(<sec-value-estimation>)[第 6 章]的全部期望估计方法均可直接用于梯度估计。其中随机向量 $nabla_bold(theta) log pi_bold(theta) (A divides S)$ 在数理统计中称为#strong[得分函数]（Score Function）。

#strong[定理 7.1（策略梯度定理，Policy Gradient Theorem, Sutton et al., 2000）] <thm-7.1> 在#link(<sec-pg-setup>)[第 7.1 节]的设定下，性能目标 @eq-pg-objective 关于策略参数 $bold(theta)$ 的梯度满足：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = sum_(s in cal(S)) #mhlb($mu^(pi_bold(theta)) (s)$) integral_(cal(A)) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) thin #mhlg($q_(pi_bold(theta)) (s, a)$) dif a $])
$ <eq-pg-theorem-sum>
其中 $mu^(pi_bold(theta)) (s)$ 为 @eq-pg-state-visitation 定义的折扣状态访问测度。注意到展开式中不含状态分布关于 $bold(theta)$ 的导数项 $nabla_bold(theta) mu^(pi_bold(theta)) (s)$。进一步应用#link(<lem-7.1>)[引理 7.1] 并代入归一化分布 $d^(pi_bold(theta)) = (1 - gamma) mu^(pi_bold(theta))$，可将策略梯度等价表征为期望形式：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = frac(1, 1 - gamma) bb(E)_(S tilde d^(pi_bold(theta)), A tilde pi_bold(theta)) [#mhlg($q_(pi_bold(theta)) (S, A)$) #mhl($nabla_bold(theta) log pi_bold(theta) (A divides S)$)] $])
$ <eq-pg-theorem-expectation>

#strong[证明（基于贝尔曼桥接方程的递推展开法）]：

+ #strong[第一步：对状态价值 $v_(pi_bold(theta)) (s)$ 求导，分离策略层导数与后继价值导数。] 由#link(<thm-3.1>)[定理 3.1] 的 $v_pi arrow.r q_pi$ 贝尔曼桥接式 $v_(pi_bold(theta)) (s) = integral_(cal(A)) pi_bold(theta) (a divides s) q_(pi_bold(theta)) (s, a) dif a$，对两边关于 $bold(theta)$ 求梯度并应用乘积求导法则：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = underbrace(integral_(cal(A)) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) q_(pi_bold(theta)) (s, a) dif a, upright("记为局部梯度项 ") phi(s)) + integral_(cal(A)) pi_bold(theta) (a divides s) nabla_bold(theta) q_(pi_bold(theta)) (s, a) dif a .
  $ <eq-pg-proof-step1>
  记第一项为 $phi(s)$；第二项包含动作价值对参数的导数 $nabla_bold(theta) q_(pi_bold(theta)) (s, a)$，需借助环境层贝尔曼方程继续展开。

+ #strong[第二步：代入 $q_pi arrow.r v_pi$ 贝尔曼桥接式，利用环境模型与策略参数无关的性质化简。] 由#link(<thm-4.2>)[定理 4.2] 的桥接方程
  $ q_(pi_bold(theta)) (s, a) = sum_(s', r) p(s', r divides s, a) [r + gamma v_(pi_bold(theta)) (s')] $，
  由于环境转移与奖励分布 $p(s', r divides s, a)$ 是环境固有属性、#strong[不依赖于策略参数 $bold(theta)$]，对其关于 $bold(theta)$ 求导时即时奖励项导数为零，仅保留后继状态价值的导数项：
  $
    nabla_bold(theta) q_(pi_bold(theta)) (s, a) = gamma sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s') = gamma sum_(s' in cal(S)) p(s' divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s') .
  $ <eq-pg-proof-step2>
  将 @eq-pg-proof-step2 代回 @eq-pg-proof-step1 的第二项，并将关于 $a$ 的积分与关于 $s'$ 的求和合并为策略 $pi_bold(theta)$ 诱导的单步状态转移概率 $Pr(S_1 = s' divides S_0 = s, pi_bold(theta)) = integral_(cal(A)) pi_bold(theta) (a divides s) p(s' divides s, a) dif a$，可得状态价值梯度的自递推方程：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = phi(s) + gamma sum_(s' in cal(S)) Pr(S_1 = s' divides S_0 = s, pi_bold(theta)) nabla_bold(theta) v_(pi_bold(theta)) (s') .
  $ <eq-pg-proof-recursion>
  上式与#link(<sec-bellman-exp-cond>)[第 3 章]的状态价值贝尔曼期望方程具有完全相同的线性递推结构（未知向量为 $nabla_bold(theta) v_(pi_bold(theta)) (s)$，单步源项为 $phi(s)$）。

+ #strong[第三步：级数展开自递推关系并合并为折扣状态访问测度。] 对 @eq-pg-proof-recursion 沿时间步反复展开（由 $gamma in [0, 1)$ 及有界性条件保证级数绝对收敛，对应#link(<sec-math-comparison-contraction>)[第 5.4 节]的 Neumann 级数展开 $(I - gamma P_pi)^(-1) = sum_(t = 0)^oo (gamma P_pi)^t$）：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = sum_(t = 0)^oo gamma^t sum_(s' in cal(S)) Pr(S_t = s' divides S_0 = s, pi_bold(theta)) phi(s') .
  $ <eq-pg-proof-unrolled>
  将 @eq-pg-proof-unrolled 代入目标梯度 $nabla_bold(theta) J(bold(theta)) = sum_s d_0 (s) nabla_bold(theta) v_(pi_bold(theta)) (s)$（因初始分布 $d_0$ 与 $bold(theta)$ 无关），并交换求和次序：
  $
    nabla_bold(theta) J(bold(theta)) = sum_(s' in cal(S)) underbrace((sum_(t = 0)^oo gamma^t sum_(s in cal(S)) d_0 (s) Pr(S_t = s' divides S_0 = s, pi_bold(theta))), = thin mu^(pi_bold(theta)) (s') thin upright("（由式 ") #ref(<eq-pg-state-visitation>) upright("）")) phi(s') = sum_(s' in cal(S)) mu^(pi_bold(theta)) (s') phi(s') ,
  $
  此即 @eq-pg-theorem-sum；再对内层积分应用#link(<lem-7.1>)[引理 7.1] 并代入 $mu^(pi_bold(theta)) (s) = frac(1, 1 - gamma) d^(pi_bold(theta)) (s)$，即证得 @eq-pg-theorem-expectation。$#h(2em) square.filled.medium$

#strong[关于状态分布参数依赖项的化简机理]：在性能目标 $J(bold(theta)) = sum_s d_0 (s) v_(pi_bold(theta)) (s)$ 中，策略参数 $bold(theta)$ 改变不仅影响单步动作选择，还会改变未来各时刻访问各状态的概率分布。上述证明严格表明，这一状态分布对参数的变化率#strong[并未被忽略或近似丢弃]：在第二步（@eq-pg-proof-step2）中，借助贝尔曼桥接方程将未来状态分布对 $bold(theta)$ 的依赖转化为后继状态价值的导数 $gamma sum_(s') p(s' divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s')$，进而在第三步（@eq-pg-proof-unrolled）通过无穷级数展开，将所有时间步上的链式求导项精确加总并吸收进折扣状态访问测度 $mu^(pi_bold(theta)) (s)$ 之中。若从轨迹联合概率密度直接求导，亦可导出完全等价的结论（见#link(<sec-reinforce>)[第 7.4 节]）。

#strong[关于归一化常数因子 $1 \/ (1 - gamma)$]：@eq-pg-theorem-expectation 右端带有比例常数 $1 \/ (1 - gamma)$。在实际梯度上升算法中，该正常数通常直接并入学习率步长 $alpha_k$ 中，这与#link(<sec-robbins-monro-theory>)[第 6.1.3 节] Robbins-Monro 随机近似框架中步长吸收正比例因子的处理完全一致。

#divider()

== REINFORCE：策略空间中的蒙特卡洛梯度估计
<sec-reinforce>

#link(<thm-7.1>)[定理 7.1] 将策略梯度表示为关于折扣状态分布与策略分布的数学期望，接下来的核心任务便是从交互轨迹样本中估计该期望。最直接的无偏采样方案与#link(<sec-mc-estimation>)[第 6.3 节]的蒙特卡洛方法完全对应：沿当前策略采集完整轨迹，并以真实折扣回报 $G_t$ 作为动作价值 $q_(pi_bold(theta)) (S_t, A_t)$ 的无偏样本。

#strong[命题 7.1（REINFORCE 蒙特卡洛策略梯度估计量的无偏性，Williams, 1992）] <prop-7.1> 设轨迹 $tau = (S_0, A_0, R_1, S_1, A_1, R_2, dots.h)$ 由策略 $pi_bold(theta)$ 与环境交互生成（对于在有限步 $T$ 终止的分幕式任务，约定可将终止状态 $S_T$ 视为零奖励自环吸收态，从而有限和 $sum_(t = 0)^(T - 1)$ 与无穷级数 $sum_(t = 0)^oo$ 严格等价），则有：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = bb(E)_(tau tilde pi_bold(theta)) [sum_(t = 0)^(T - 1) #mhlb($gamma^t$) #mhlg($G_t$) #mhl($nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)$)] $])
$ <eq-pg-reinforce>
其中 $G_t = sum_(k = 0)^(T - t - 1) gamma^k R_(t + k + 1)$ 为#link(<def-1.1>)[定义 1.1] 给出的从时刻 $t$ 起算的折扣回报。

#strong[证明]：对轨迹时刻 $t$ 的通项，应用#link(<lem-2>)[引理 2] 的全期望公式（塔性质，取条件变量为 $(S_t, A_t)$）与已知量提取性质（P9），并代入动作价值定义 $bb(E)_(pi_bold(theta)) [G_t divides S_t, A_t] = q_(pi_bold(theta)) (S_t, A_t)$（@eq-q-def）：
$
  bb(E)_(tau tilde pi_bold(theta)) [gamma^t G_t nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] & = bb(E)_(S_t, A_t) [gamma^t #mhlb($bb(E)[G_t divides S_t, A_t]$) nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] quad #[（由#link(<lem-2>)[引理 2] 与性质 P9）] \
  & = bb(E)_(S_t, A_t) [gamma^t #mhlg($q_(pi_bold(theta)) (S_t, A_t)$) nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] \
  & = sum_(s in cal(S)) gamma^t Pr(S_t = s divides pi_bold(theta), d_0) integral_(cal(A)) pi_bold(theta) (a divides s) q_(pi_bold(theta)) (s, a) nabla_bold(theta) log pi_bold(theta) (a divides s) dif a .
$
对所有时间步 $t$ 求和（在分幕任务中 $t gt.eq T$ 时奖励与终止态得分贡献为零，故 $sum_(t = 0)^(T - 1)$ 与 $sum_(t = 0)^oo$ 一致），由线性性（P13）交换期望与求和，并代入折扣状态访问测度定义 $mu^(pi_bold(theta)) (s) = sum_(t = 0)^oo gamma^t Pr(S_t = s divides pi_bold(theta), d_0)$（@eq-pg-state-visitation）及对数导数恒等式（#link(<lem-7.1>)[引理 7.1]），即得 @eq-pg-theorem-sum。$#h(2em) square.filled.medium$

基于单条采样轨迹的 REINFORCE 随机梯度上升更新律为（当步长序列 $alpha_k$ 满足 @eq-rm-step-conditions 时，由 Robbins-Monro 随机近似理论保证收敛于 $J(bold(theta))$ 的平稳点）：
$
  #eqbox([$ bold(theta)_(k + 1) = bold(theta)_k + alpha_k sum_(t = 0)^(T - 1) gamma^t G_t nabla_bold(theta) log pi_(bold(theta)_k) (A_t divides S_t) $])
$ <eq-pg-reinforce-update>

#strong[理论性质评述]：

1. #strong[与蒙特卡洛价值估计的同构性]：@eq-pg-reinforce 以完整轨迹回报 $G_t$ 替代未知的真实动作价值 $q_(pi_bold(theta)) (S_t, A_t)$，在统计机制上与#link(<prop-6.2>)[命题 6.2] 的蒙特卡洛方法完全对应——具有#strong[严格无偏、无需自举、不依赖环境模型]的优点，但同样只能在整幕轨迹终止后执行离线更新。
2. #strong[折扣因子 $gamma^t$ 的理论必要性]：@eq-pg-reinforce 中的时间步权重 $gamma^t$ 直接源自折扣状态访问测度 $mu^(pi_bold(theta))$ 的定义，是保证梯度估计量对折扣目标 @eq-pg-objective 严格无偏的必要因子（部分工程实现常忽略 $gamma^t$，此时实际优化的是非折扣状态分布加权下的近似目标，存在理论偏差）。
3. #strong[高方差瓶颈]：由于完整回报 $G_t$ 累加了时刻 $t$ 之后整段轨迹的环境转移与动作采样随机性，将该高方差标量直接乘在得分函数 $nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)$ 上会导致梯度估计方差极大、收敛缓慢。为此，下一节引入状态基线技术以在不引入偏差的前提下显著降低梯度方差。

#divider()

== 状态基线与优势函数：无偏方差缩减机制
<sec-pg-baseline>

REINFORCE 梯度估计量高方差的根源在于：完整回报 $G_t$ 不仅包含“在状态 $S_t$ 选择特定动作 $A_t$ 的相对优劣”，还混入了由状态 $S_t$ 本身的基础价值水平所决定的基准偏移。通过从动作价值（或回报）中减去一个#strong[仅依赖于状态 $S_t$、不依赖于当前动作 $A_t$ 的基线函数（Baseline）$b(S_t)$]，可在严格保持梯度期望不变的前提下大幅缩减估计方差。

#strong[命题 7.2（状态相关基线的无偏性）] <prop-7.2> 设 $b : cal(S) arrow.r bb(R)$ 为任意仅依赖于状态 $s$ 而与动作 $a$ 无关的确定性函数，则对任意状态 $s in cal(S)$，基线项与得分函数乘积的条件期望恒为零向量：
$
  bb(E)_(A tilde.op pi_bold(theta) (dot.op divides s)) [b(s) nabla_bold(theta) log pi_bold(theta) (A divides s)] = b(s) integral_(cal(A)) pi_bold(theta) (a divides s) nabla_bold(theta) log pi_bold(theta) (a divides s) dif a = b(s) integral_(cal(A)) nabla_bold(theta) pi_bold(theta) (a divides s) dif a = bold(0) .
$ <eq-pg-baseline-zero>
因此，策略梯度（@eq-pg-theorem-expectation）可等价表征为带基线的形式：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = frac(1, 1 - gamma) bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [(q_(pi_bold(theta)) (S, A) - b(S)) nabla_bold(theta) log pi_bold(theta) (A divides S)] $])
$ <eq-pg-baseline-gradient>

#strong[证明]：在给定状态 $S = s$ 的条件下，$b(s)$ 关于动作随机变量 $A$ 为条件已知常数（性质 P9），可直接提取至积分（期望）号外；剩余积分项由#link(<lem-7.1>)[引理 7.1] 的零均值性质（@eq-pg-score-zero，源于概率密度恒归一化 $integral_(cal(A)) pi_bold(theta) (a divides s) dif a equiv 1$）精确等于零向量。将 @eq-pg-baseline-zero 代入 @eq-pg-theorem-expectation 即得 @eq-pg-baseline-gradient。$#h(2em) square.filled.medium$

理论与实践中最自然的基线选择是当前策略下的#strong[状态价值函数] $b(s) = v_(pi_bold(theta)) (s)$：$v_(pi_bold(theta)) (s)$ 表征智能体在状态 $s$ 下遵循策略 $pi_bold(theta)$ 所能获得的平均期望回报，而 $q_(pi_bold(theta)) (s, a)$ 表征在状态 $s$ 显式选定动作 $a$ 后再遵循策略 $pi_bold(theta)$ 所获得的期望回报。二者之差定义为#strong[优势函数]（Advantage Function）：
$
  #eqbox([$ A^(pi_bold(theta)) (s, a) eq.dot q_(pi_bold(theta)) (s, a) - v_(pi_bold(theta)) (s) $])
$ <eq-pg-advantage-def>
优势函数 $A^(pi_bold(theta)) (s, a)$ 精确刻画了在状态 $s$ 下选择动作 $a$ 相对于当前策略平均表现的超额收益，且由#link(<thm-3.1>)[定理 3.1] 易知其在策略分布下的条件期望恒为零：$bb(E)_(A tilde.op pi_bold(theta))[A^(pi_bold(theta)) (s, A)] = v_(pi_bold(theta)) (s) - v_(pi_bold(theta)) (s) = 0$。

#strong[最小方差最优基线]：若以最小化单步梯度估计量的方差（即协方差矩阵的迹 $bb(E)[norm((q_(pi_bold(theta)) - b(s)) nabla_bold(theta) log pi_bold(theta))^2]$）为准则对 $b(s)$ 求一阶极值条件，可得理论最小方差基线为：
$
  b^star (s) = frac(bb(E)_(A tilde.op pi_bold(theta)) [norm(nabla_bold(theta) log pi_bold(theta) (A divides s))^2 q_(pi_bold(theta)) (s, A)], bb(E)_(A tilde.op pi_bold(theta)) [norm(nabla_bold(theta) log pi_bold(theta) (A divides s))^2]) .
$ <eq-pg-optimal-baseline>
即以得分函数模长平方为权重的动作价值加权平均；状态价值 $v_(pi_bold(theta)) (s) = bb(E)_(A tilde.op pi_bold(theta))[q_(pi_bold(theta)) (s, A)]$ 正是 @eq-pg-optimal-baseline 略去范数权重后的无权近似，在实际算法中直接采用#link(<sec-value-estimation>)[第 6 章]的价值估计方法对 $v_(pi_bold(theta)) (s)$ 进行逼近即可获得优良的降方差效果。

#strong[优势函数与单步 TD 误差的期望等价性]：由#link(<thm-3.2>)[定理 3.2] 的 $q_pi arrow.r v_pi$ 贝尔曼期望方程（@eq-bellman-exp-qv），单步时序差分误差 $delta_t eq.dot R_(t + 1) + gamma v_(pi_bold(theta)) (S_(t + 1)) - v_(pi_bold(theta)) (S_t)$ 在给定 $(S_t = s, A_t = a)$ 下的条件期望恰等于优势函数：
$
  bb(E)_(R_(t + 1), S_(t + 1)) [underbrace(R_(t + 1) + gamma v_(pi_bold(theta)) (S_(t + 1)) - v_(pi_bold(theta)) (S_t), upright("真实状态价值下的 TD 误差 ") delta_t) divides S_t = s, A_t = a] = q_(pi_bold(theta)) (s, a) - v_(pi_bold(theta)) (s) = A^(pi_bold(theta)) (s, a) .
$ <eq-pg-advantage-td>
@eq-pg-advantage-td 揭示了一条关键性质：要构造优势函数 $A^(pi_bold(theta)) (s, a)$ 的无偏单步估计，无需同时维护 $Q$ 与 $V$ 两套估计器，仅需估计状态价值函数 $V(s)$ 并计算其单步 TD 误差 $delta_t$ 即可。这直接导出了下一节的 Actor-Critic 架构。

#divider()

== Actor-Critic 架构与兼容函数近似定理
<sec-actor-critic>

#strong[演员-评论家（Actor-Critic）]架构将策略梯度（#link(<sec-pg-theorem>)[第 7.3 节]）与基于自举的价值估计（#link(<sec-td-estimation>)[第 6.5 节]）有机结合：#strong[Actor（演员）]维护参数化策略 $pi_bold(theta) (a divides s)$ 并沿策略梯度方向更新参数 $bold(theta)$；#strong[Critic（评论家）]维护参数化价值函数 $hat(v)(s; bold(w))$（或 $hat(q)(s, a; bold(w))$），利用第 6 章的时序差分方法更新参数 $bold(w)$，为 Actor 提供低方差的优势函数（或动作价值）估计。

#strong[Actor（策略参数更新）]：以优势估计量 $hat(A)_t$ 替代 @eq-pg-reinforce-update 中的整幕回报 $G_t$，得到通用的 Actor 更新公式：
$
  #eqbox([$ bold(theta)_(k + 1) = bold(theta)_k + alpha_k #mhlg($hat(A)_t$) nabla_bold(theta) log pi_(bold(theta)_k) (A_t divides S_t) $])
$ <eq-pg-ac-update>
其中优势估计量 $hat(A)_t$ 的具体构造方式决定了 Actor-Critic 算法的具体类型（汇总见 @tab-pg-advantage-estimators）。

#strong[Critic（价值参数更新）]：以一步自举的#strong[优势 Actor-Critic（Advantage Actor-Critic, A2C）]为例，Critic 采用参数为 $bold(w)$ 的状态价值近似函数 $hat(v)(s; bold(w))$，其单步 TD 误差与半梯度更新律为：
$
  hat(delta)_t = R_(t + 1) + gamma hat(v)(S_(t + 1); bold(w)_k) - hat(v)(S_t; bold(w)_k), quad bold(w)_(k + 1) = bold(w)_k + beta_k hat(delta)_t nabla_bold(w) hat(v)(S_t; bold(w)_k) .
$ <eq-pg-critic-update>
在 Actor 更新（@eq-pg-ac-update）中取 $hat(A)_t = hat(delta)_t$ 即构成一步 Actor-Critic 算法；若将 Critic 的自举目标替换为 $n$-步 TD 回报或 TD($lambda$)，则得到对应的多步 Actor-Critic 算法。可见，Critic 的更新过程与#link(<sec-td-estimation>)[第 6.5 节]的时序差分价值估计完全一致。

#strong[偏差-方差权衡]：在 REINFORCE 中，完整回报 $G_t$ 的条件期望严格等于真实 $q_(pi_bold(theta)) (S_t, A_t)$，梯度估计无偏但方差极大；而在 Actor-Critic 中，由于自举优势估计 $hat(delta)_t = R_(t + 1) + gamma hat(v)(S_(t + 1); bold(w)) - hat(v)(S_t; bold(w))$ 使用了带有函数近似误差与自举误差的估计值 $hat(v)(dot.op; bold(w))$，当 $hat(v) eq.not v_(pi_bold(theta))$ 时，$bb(E)[hat(delta)_t divides S_t, A_t] eq.not A^(pi_bold(theta)) (S_t, A_t)$，从而在策略梯度估计中引入了#strong[自举与函数近似偏差]，以此换取在线单步更新能力与显著更低的估计方差。

#strong[定理 7.2（兼容函数近似定理，Compatible Function Approximation Theorem, Sutton et al., 2000; Kakade, 2001）] <thm-7.2> 在何种条件下，用参数化近似器替代真实价值函数不会给策略梯度引入任何渐近偏差？设优势函数（或搭配状态基线 $v(s)$ 后的动作价值）的参数化近似器 $hat(A)_bold(w) (s, a)$ 满足以下两条条件：
1. #strong[梯度兼容性条件（Compatibility Condition）]：近似器关于自身参数 $bold(w)$ 的梯度等于策略的对数梯度（得分函数）：
   $
     nabla_bold(w) hat(A)_bold(w) (s, a) = nabla_bold(theta) log pi_bold(theta) (a divides s) ,
   $ <eq-pg-compatibility-cond>
   即线性兼容参数化形式 $hat(A)_bold(w) (s, a) = bold(w)^top nabla_bold(theta) log pi_bold(theta) (a divides s)$（注：由 @eq-pg-score-zero 知得分函数关于动作的条件期望为零，故该线性组合天然满足优势函数的零均值性质 $bb(E)_(A tilde.op pi_bold(theta))[hat(A)_bold(w) (s, A)] = 0$；若要逼近动作价值 $q_(pi_bold(theta)) (s, a)$，则需写成 $hat(q)(s, a; bold(w), bold(v)) = hat(v)(s; bold(v)) + bold(w)^top nabla_bold(theta) log pi_bold(theta) (a divides s)$）。
2. #strong[最小均方误差正交性条件]：参数 $bold(w)$ 收敛于加权均方逼近误差 $cal(E)(bold(w)) eq.dot frac(1, 2) bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [(A^(pi_bold(theta)) (S, A) - hat(A)_bold(w) (S, A))^2]$ 的极小点，即满足一阶平稳条件：
   $
     nabla_bold(w) cal(E)(bold(w)) = bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [(hat(A)_bold(w) (S, A) - A^(pi_bold(theta)) (S, A)) #mhl($nabla_bold(w) hat(A)_bold(w) (S, A)$)] = bold(0) .
   $ <eq-pg-compatible-orthogonality>
则将 @eq-pg-compatibility-cond 代入 @eq-pg-compatible-orthogonality 并移项，立得用近似器 $hat(A)_bold(w)$ 替换真实优势函数后计算的策略梯度#strong[精确等于]真实策略梯度（零逼近偏差）：
$
  #eqbox([$ frac(1, 1 - gamma) bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [#mhlg($hat(A)_bold(w) (S, A)$) #mhl($nabla_bold(theta) log pi_bold(theta) (A divides S)$)] = frac(1, 1 - gamma) bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [A^(pi_bold(theta)) (S, A) nabla_bold(theta) log pi_bold(theta) (A divides S)] = nabla_bold(theta) J(bold(theta)) $])
$ <eq-pg-compatible-exact-grad>
此外，将 $hat(A)_bold(w) (S, A) = [nabla_bold(theta) log pi_bold(theta) (A divides S)]^top bold(w)$ 代入上式左端可得 $(1 - gamma)^(-1) bold(F)(bold(theta)) bold(w) = nabla_bold(theta) J(bold(theta))$，其中 $bold(F)(bold(theta)) eq.dot bb(E)_(d^(pi_bold(theta)), pi_bold(theta)) [nabla_bold(theta) log pi_bold(theta) (nabla_bold(theta) log pi_bold(theta))^top]$ 为策略分布的 #strong[Fisher 信息矩阵]，故最优兼容参数向量 $bold(w) = (1 - gamma) bold(F)(bold(theta))^(-1) nabla_bold(theta) J(bold(theta))$ 恰对应于 Amari 意义下的#strong[自然策略梯度（Natural Policy Gradient）]方向。

#figure(
  caption: [Actor-Critic 架构中四类优势函数估计器与第 6 章价值估计方法的对应关系。随着自举步数增加，自举偏差递减而采样方差递增；GAE 通过参数 $lambda in [0, 1]$ 在该谱系上实现连续插值],
  text(size: 8.6pt, table(
    columns: (1.05fr, 1.55fr, 1.05fr, 1.2fr, 1.1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([优势估计器], [数学构造], [对应的第 6 章方法], [偏差-方差特征], [代表性算法]),
    table.hline(),
    [蒙特卡洛优势], [$hat(A)_t = G_t - hat(v)(S_t)$], [第 6.3 节 MC + 状态基线], [无自举偏差、方差大], [REINFORCE with Baseline],
    table.hline(stroke: 0.6pt + accent),
    [一步 TD 优势], [$hat(A)_t = hat(delta)_t = R_(t+1) + gamma hat(v)(S_(t+1)) - hat(v)(S_t)$], [第 6.5 节 TD(0)], [含一步自举偏差、方差最小], [一步 Actor-Critic / A2C],
    table.hline(stroke: 0.6pt + accent),
    [$n$-步 TD 优势], [$hat(A)_t^((n)) = G_(t:t+n) - hat(v)(S_t)$], [第 6.5 节 $n$-步 TD], [偏差与方差折中], [多步 A2C / A3C],
    table.hline(stroke: 0.6pt + accent),
    [广义优势估计（GAE）], [$hat(A)_t^upright("GAE")(gamma, lambda)$，见 @eq-pg-gae], [第 6.5 节 TD($lambda$) 的优势对应], [由 $lambda in [0, 1]$ 连续权衡], [TRPO / PPO],
  )),
) <tab-pg-advantage-estimators>

#divider()

== 广义优势估计（GAE）：多步优势估计的指数加权平均
<sec-gae>

在 Actor-Critic 框架中，一步 TD 优势估计方差低但受 Critic 逼近误差导致的自举偏差影响较大，而蒙特卡洛优势估计虽无自举偏差但方差随轨迹长度急剧增长。与#link(<sec-td-estimation>)[第 6.5 节]利用 TD($lambda$) 统一一步 TD 与蒙特卡洛的价值估计完全平行，Schulman et al. (2016) 提出的#strong[广义优势估计]（Generalized Advantage Estimation, GAE）通过对所有步长 $n$ 的 $n$-步优势估计量做几何加权平均，引入连续插值参数 $lambda in [0, 1]$ 实现偏差与方差的平滑调节。

首先将 $n$-步优势估计量表示为单步 TD 误差的折扣累加和。记价值近似函数 $V$（即 $hat(v)(dot.op; bold(w))$）下的第 $t$ 步 TD 误差为 $delta_t^V eq.dot R_(t + 1) + gamma V(S_(t + 1)) - V(S_t)$，对 $n$-步优势估计量 $hat(A)_t^((n)) eq.dot G_(t : t + n) - V(S_t)$ 展开裂项相消（Telescoping Sum）：
$
  #eqbox([$ hat(A)_t^((n)) eq.dot sum_(k = 0)^(n - 1) gamma^k R_(t + k + 1) + gamma^n V(S_(t + n)) - V(S_t) = sum_(l = 0)^(n - 1) gamma^l delta_(t + l)^V $])
$ <eq-pg-nstep-advantage>
（展开右端可见，中间项 $+ gamma^l V(S_(t + l))$ 与后一时刻的 $- gamma^l V(S_(t + l))$ 逐项正负抵消，仅余首项 $-V(S_t)$ 与末项 $gamma^n V(S_(t + n))$。）

#strong[定义 7.1（广义优势估计，GAE）] <def-gae> 给定折扣因子 $gamma in [0, 1]$ 与权衡参数 $lambda in [0, 1]$，广义优势估计量 $hat(A)_t^upright("GAE") (gamma, lambda)$ 定义为各步 TD 误差以 $(gamma lambda)^l$ 为权重的无穷级数（在分幕任务中求和至终止步 $T - t - 1$）：
$
  #eqbox([$ hat(A)_t^upright("GAE") (gamma, lambda) eq.dot sum_(l = 0)^oo (gamma lambda)^l delta_(t + l)^V $])
$ <eq-pg-gae>

#strong[命题 7.3（GAE 与 $n$-步优势指数加权平均的等价性）] <prop-7.3> 对任意 $lambda in [0, 1)$，@eq-pg-gae 定义的 GAE 等于所有 $n$-步优势估计量 $hat(A)_t^((n))$ 在几何分布权重 $(1 - lambda) lambda^(n - 1)$ 下的加权平均：
$
  hat(A)_t^upright("GAE") (gamma, lambda) = (1 - lambda) sum_(n = 1)^oo lambda^(n - 1) hat(A)_t^((n)) .
$ <eq-pg-gae-average>
#strong[证明]：将 @eq-pg-nstep-advantage 代入上式右端，并利用级数绝对收敛性（P13）交换关于 $n$ 与 $l$ 的双重求和次序（满足 $0 lt.eq l < n < oo$，故外层 $l$ 从 $0$ 到 $oo$，内层 $n$ 从 $l + 1$ 到 $oo$）：
$
  (1 - lambda) sum_(n = 1)^oo lambda^(n - 1) sum_(l = 0)^(n - 1) gamma^l delta_(t + l)^V = sum_(l = 0)^oo gamma^l delta_(t + l)^V underbrace((1 - lambda) sum_(n = l + 1)^oo lambda^(n - 1), = thin (1 - lambda) frac(lambda^l, 1 - lambda) thin = thin lambda^l) = sum_(l = 0)^oo (gamma lambda)^l delta_(t + l)^V ,
$
与 @eq-pg-gae 严格一致。$#h(2em) square.filled.medium$

考察插值参数 $lambda$ 在两个端点处的退化情形：
- #strong[当 $lambda = 0$ 时]：@eq-pg-gae 仅保留 $l = 0$ 的首项，即 $hat(A)_t^upright("GAE") (gamma, 0) = delta_t^V = R_(t + 1) + gamma V(S_(t + 1)) - V(S_t)$，完全退化为一步 TD 优势估计（方差最小，受 $V$ 的逼近偏差影响最大）。
- #strong[当 $lambda = 1$ 时]：@eq-pg-gae 化为 $hat(A)_t^upright("GAE") (gamma, 1) = sum_(l = 0)^oo gamma^l delta_(t + l)^V = G_t - V(S_t)$（即 @eq-pg-nstep-advantage 在 $n arrow.r oo$ 时的极限），完全退化为带基线的蒙特卡洛优势估计（无论 $V$ 是否有偏，估计量在期望意义下均不引入自举偏差，但方差最大）。

综上所述，@tab-pg-advantage-estimators 中的各类优势估计器均可视为同一参数谱系下的特例，GAE 在优势函数空间中的角色与#link(<sec-td-estimation>)[第 6.5 节] TD($lambda$) 在状态价值空间中的角色严格对偶。需要强调的是，参数 $lambda$ 仅调节#strong[优势估计量 $hat(A)_t$ 的偏差-方差权衡]，并不改变底层策略梯度定理（@eq-pg-theorem-expectation）的目标形式。

#divider()

== 策略梯度与贝尔曼方程的理论边界辨析
<sec-pg-vs-bellman>

#link(<sec-mdp>)[第 1]--#link(<sec-value-estimation>)[6 章]的核心主线是#strong[求解贝尔曼方程]：将贝尔曼期望方程或贝尔曼最优方程视为价值空间上的算子不动点方程 $x = cal(T) x$，通过精确迭代或随机近似求解 $v_pi, q_pi, v_star, q_star$。本章的策略梯度方法则遵循另一条独立主线，为避免概念混淆，需严格厘清二者之间的理论边界：

#strong[核心分野]：策略梯度方法的直接优化变量是策略参数 $bold(theta)$，其求解目标是性能指标 $J(bold(theta))$ 的平稳点，#strong[贝尔曼方程不再作为最终的求解对象]。在纯蒙特卡洛策略梯度（REINFORCE）中，整个推导与算法执行仅依赖对数导数恒等式与完整轨迹采样，完全不涉及单步贝尔曼自举。

#strong[贝尔曼方程进入策略梯度体系的三种途径]：

1. #strong[理论推导与优势函数定义中的桥接关系]：在策略梯度定理（#link(<thm-7.1>)[定理 7.1]）的递归证明中，利用了 $v_pi arrow.r q_pi$ 与 $q_pi arrow.r v_pi$ 的一步贝尔曼期望方程将对状态分布的求导转化为折扣状态访问测度；同时，优势函数 $A^pi (s, a) = q_pi (s, a) - v_pi (s)$（@eq-pg-advantage-def）及其与单步 TD 误差的期望等价性（@eq-pg-advantage-td）直接建立在贝尔曼期望桥接关系之上。
2. #strong[Critic 模块中的辅助价值估计工具]：在 Actor-Critic 与 GAE（#link(<sec-actor-critic>)[第 7.6]--#link(<sec-gae>)[7.7 节]）中，Critic 模块复用#link(<sec-td-estimation>)[第 6.5 节]的时序差分方法（基于状态价值贝尔曼期望方程 @eq-bellman-exp-vv）逼近 $v_(pi_bold(theta))$。在此架构下，贝尔曼期望方程#strong[从“最终求解目标”降格为“构建低方差梯度估计量的辅助估计工具”]。
3. #strong[最大熵强化学习中的显式结合（软贝尔曼方程）]：在最大熵 Actor-Critic 算法（如 SAC，见#link(<sec-pg-variants>)[第 7.9.3 节]）中，目标函数显式引入了策略熵正则项，此时 Critic 需直接求解带有熵奖励修正的#strong[软贝尔曼期望方程]，而 Actor 则最小化策略分布与软动作价值玻尔兹曼分布之间的 KL 散度，构成价值不动点迭代与参数化策略优化的深度融合。

各代表性策略梯度算法族与贝尔曼方程的依赖关系汇总于 @tab-pg-bellman-boundary。

#figure(
  caption: [策略梯度算法谱系与贝尔曼方程的理论关系对比。在标准策略梯度与 Actor-Critic 中，贝尔曼方程仅作为优势函数定义或 Critic 价值估计的辅助工具；在大语言模型 RLVR 的无 Critic 算法族中，贝尔曼自举被组内相对回报基线完全替代；而 SAC 则是显式求解软贝尔曼不动点方程的代表],
  text(size: 8.6pt, table(
    columns: (0.85fr, 1.7fr, 1.1fr, 1.05fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([算法类别], [优势 / 价值信号来源], [所依赖的贝尔曼关系], [是否求解贝尔曼方程]),
    table.hline(),
    [REINFORCE], [完整轨迹回报 $G_t$（减去状态基线）], [仅证明与 $A = q - v$ 定义], [否（纯蒙特卡洛）],
    table.hline(stroke: 0.6pt + accent),
    [A2C / A3C], [Critic 的一步或 $n$-步 TD 误差], [@eq-bellman-exp-vv 用于 Critic 估计 $v_pi$], [仅 Critic 辅助估计],
    table.hline(stroke: 0.6pt + accent),
    [TRPO / PPO], [基于 Critic 的广义优势估计 GAE（@eq-pg-gae）], [同上，经由 TD($lambda$) 递推], [仅 Critic 辅助估计],
    table.hline(stroke: 0.6pt + accent),
    [GRPO 算法族（#link(<sec-rlvr-lineage>)[第 7.10 节]）], [同一提示下组内标准化回报，广播为序列内各 token 的优势], [无（以组内经验均值替代 $v_pi$，无需 Critic 网络）], [否（完全无需自举）],
    table.hline(stroke: 0.6pt + accent),
    [SAC], [由软贝尔曼方程估计的软动作价值 $q_upright("soft")^pi$ 与软状态价值 $v_upright("soft")^pi$], [软贝尔曼期望方程（@eq-pg-soft-bellman）], [是（Critic 求解软不动点）],
  )),
) <tab-pg-bellman-boundary>

#divider()

== 策略梯度的重要扩展变体：信任域约束、确定性策略与最大熵正则
<sec-pg-variants>

#link(<sec-pg-theorem>)[第 7.3]--#link(<sec-gae>)[7.7 节]建立了策略梯度与 Actor-Critic 的基础理论框架：@eq-pg-theorem-expectation 给出了无偏梯度表征，@eq-pg-baseline-gradient 通过状态基线降低了方差，@eq-pg-ac-update 实现了在线自举更新，@eq-pg-gae 提供了偏差-方差的连续权衡。然而，在复杂的非凸深度强化学习优化中，直接沿一阶梯度更新仍面临三类核心挑战：其一，参数空间步长过大导致策略分布剧烈偏移与性能塌缩；其二，高维连续动作空间中随机策略积分方差较大；其三，纯回报目标缺乏显式探索激励导致策略熵过早退化。以下三类代表性算法变体分别针对这三项核心问题构建了相应的数学修正机制。
其中，第一类变体所提出的裁剪代理目标（Clipped Surrogate Objective）在大语言模型的可验证奖励强化学习（RLVR）中被广泛沿用，并进一步演化出四代代表性算法（详见#link(<sec-rlvr-lineage>)[第 7.10 节]）。

=== 变体一：策略更新步长失控与信任域约束 —— TRPO 与 PPO

#strong[核心问题]：性能目标 $J(bold(theta))$ 关于深度神经网络参数 $bold(theta)$ 高度非凸，且欧氏参数空间的距离与策略概率分布空间的距离（如 KL 散度）之间不存在一致的比例关系。在标准梯度上升中，即使欧氏参数步长很小，也可能导致策略分布 $pi_bold(theta) (dot.op divides s)$ 发生剧烈跳变；而在强化学习中，一旦新策略劣化，后续交互将采集到低质量轨迹分布的数据，引发不可逆的#strong[性能塌缩（Performance Collapse）]。问题的本质在于一阶梯度仅在旧策略分布 $pi_(bold(theta)_upright("old"))$ 的局部邻域内有效。

#strong[核心机制]：对每次策略更新显式施加#strong[策略分布偏移约束]，确保新策略保持在旧策略的局部信任域（Trust Region）内。
1. #strong[信任域策略优化（TRPO，Schulman et al., 2015）]：利用#link(<sec-importance-sampling>)[第 6.4 节]的重要性采样技术，将新策略 $pi_bold(theta)$ 的局部替代目标写成旧策略 $pi_(bold(theta)_upright("old"))$ 采样分布下的期望（该替代目标在 $bold(theta) = bold(theta)_upright("old")$ 处的一阶梯度与 $J(bold(theta))$ 严格相等），并在状态平均 KL 散度有界的信任域约束下求解最大化问题：
   $
     #eqbox([$ max_bold(theta) quad bb(E)_(S tilde.op d^(pi_(bold(theta)_upright("old"))), A tilde.op pi_(bold(theta)_upright("old"))) [frac(pi_bold(theta) (A divides S), pi_(bold(theta)_upright("old")) (A divides S)) hat(A)_t] quad upright("s.t.") quad bb(E)_(S tilde.op d^(pi_(bold(theta)_upright("old")))) [D_upright("KL") (pi_(bold(theta)_upright("old")) (dot.op divides S) parallel pi_bold(theta) (dot.op divides S))] lt.eq delta $])
   $ <eq-pg-trpo>
2. #strong[近端策略优化（PPO-Clip，Schulman et al., 2017）]：为避免求解二阶约束优化问题，PPO 直接在一阶代理目标中对单步重要性采样比 $rho_t (bold(theta)) eq.dot frac(pi_bold(theta) (A_t divides S_t), pi_(bold(theta)_upright("old")) (A_t divides S_t))$ 施加区间裁剪，构造保守下界目标（Pessimistic Lower Bound）：
   $
     J^upright("CLIP") (bold(theta)) = bb(E)_t [min(rho_t (bold(theta)) hat(A)_t, thin upright("clip")(rho_t (bold(theta)), 1 - epsilon, 1 + epsilon) hat(A)_t)], #h(1.5em) rho_t (bold(theta)) = frac(pi_bold(theta) (A_t divides S_t), pi_(bold(theta)_upright("old")) (A_t divides S_t)) .
   $ <eq-pg-ppo-clip>
   裁剪算子的作用是截断超出信任域边界 $[1 - epsilon, 1 + epsilon]$ 的优化激励：当优势 $hat(A)_t > 0$ 且比值 $rho_t > 1 + epsilon$，或当优势 $hat(A)_t < 0$ 且比值 $rho_t < 1 - epsilon$ 时，目标函数关于 $bold(theta)$ 的梯度降为零，从而在无需显式计算二阶矩阵的前提下有效限制单步更新幅度。

#strong[统计代价与理论性质]：TRPO 需在每步更新中利用共轭梯度法近似求解 Fisher 信息矩阵线性方程组并执行回溯线搜索，计算开销较大；PPO 仅需一阶随机梯度更新，但硬裁剪操作在边界处截断了梯度，引入了一定的渐近偏差，且有效更新步幅对超参数 $epsilon$ 较为敏感。两类方法均保持了底层贝尔曼方程的角色不变——Critic 模块依然依据贝尔曼期望方程（经由 GAE，@eq-pg-gae）估计优势函数。

=== 变体二：连续动作空间下的解析最大化与确定性策略梯度 —— DDPG 与 TD3

#strong[核心问题]：如#link(<sec-pg-motivation>)[第 7.2 节]所述，在连续动作空间 $cal(A) subset.eq bb(R)^m$ 中，基于价值的 Q-Learning 无法直接解析求解 $max_(a in cal(A)) Q(s, a)$；而随机策略梯度（@eq-pg-theorem-expectation）则需同时在状态空间与连续动作空间上采样积分，在高维动作空间中方差较大、样本效率受限。

#strong[核心机制]：Silver et al. (2014) 提出的#strong[确定性策略梯度（Deterministic Policy Gradient, DPG）]将策略直接建模为从状态到连续动作的确定性可微映射 $a = mu_bold(theta) (s)$，并在连续可微的动作价值函数 $q^(mu_bold(theta)) (s, a)$ 下利用复合函数链式求导法则消去动作积分与最大化算子：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = bb(E)_(S tilde.op d^(mu_bold(theta))) [#mhl($nabla_bold(theta) mu_bold(theta) (S)^top$) #mhlg($nabla_a q^(mu_bold(theta)) (S, a) divides_(a = mu_bold(theta) (S))$)] $])
$ <eq-pg-dpg>
上式的几何意义十分直观：Critic 提供动作价值关于连续动作向量的上升方向 $nabla_a q(S, a)$，Actor 则通过链式法则调整策略参数 $bold(theta)$，使输出动作 $mu_bold(theta) (S)$ 沿动作价值增大的方向移动，从而以可微梯度上升替代了离散空间中的不可微算子 $arg max_a Q(s, a)$（Silver et al. 证明了当随机策略的方差趋于零时，随机策略梯度定理 @eq-pg-theorem-sum 精确收敛于确定性策略梯度定理 @eq-pg-dpg）。

#strong[统计代价与理论性质]：由于确定性策略 $mu_bold(theta) (s)$ 自身不具备随机探索能力，必须采用叠加外部噪声的行为策略（如 $b(s) = mu_bold(theta) (s) + cal(N)(0, sigma^2)$）进行离轨采样，并通过基于动作价值贝尔曼期望方程的离轨 Critic（如 #strong[DDPG]，Lillicrap et al., 2016）训练价值网络 $Q_bold(w) (s, a)$。然而，在函数近似下，Actor 持续沿 $nabla_a Q_bold(w)$ 方向寻优会迅速利用并放大 Critic 网络的局部高估误差（即#link(<sec-td-action-value>)[第 6.6 节]第 4 项最大化偏差的连续空间对应物）。为此，#strong[TD3]（Twin Delayed DDPG，Fujimoto et al., 2018）引入截断双 Critic 网络（取 $min_(i = 1, 2) Q_(bold(w)_i) (S_(t + 1), tilde(a))$ 作为贝尔曼自举目标）、目标策略平滑正则与延迟 Actor 更新三项机制以抑制高估发散。

=== 变体三：熵正则化与最大熵强化学习 —— SAC 与软贝尔曼方程

#strong[核心问题]：标准期望回报目标 @eq-pg-objective 仅最大化累积奖励，缺乏维持策略随机性的内生机制。在训练过程中，策略分布容易过早塌缩为近乎确定性的单峰分布，导致探索停滞并陷入局部次优解；此外，在存在多条等价最优路径（多峰最优）或外部扰动的环境中，保持适度的策略熵能够显著提升控制鲁棒性。

#strong[核心机制]：Haarnoja et al. (2018) 提出的#strong[软演员-评论家（Soft Actor-Critic, SAC）]将策略在每个访问状态下的信息熵 $cal(H)(pi(dot.op divides S_t)) eq.dot bb(E)_(A_t tilde.op pi(dot.op divides S_t)) [- log pi(A_t divides S_t)]$ 作为附加内在奖励并入优化目标，构建#strong[最大熵强化学习（Maximum Entropy RL）]目标函数：
$
  #eqbox([$ J_upright("soft") (bold(theta)) = bb(E)_(tau tilde.op pi_bold(theta)) [sum_(t = 0)^oo gamma^t (R_(t + 1) + #mhl($alpha cal(H) (pi_bold(theta) (dot.op divides S_t))$))] $])
$ <eq-pg-sac-objective>
其中温度系数 $alpha > 0$ 控制熵正则项与原始奖励之间的相对权重（当 $alpha arrow.r 0$ 时退化为标准强化学习）。由于目标函数中计入了未来各时刻的策略熵，状态价值与动作价值的定义相应推广为包含未来熵收益的#strong[软状态价值 $v_upright("soft")^pi (s)$] 与#strong[软动作价值 $q_upright("soft")^pi (s, a)$]（注意按定义，$q_upright("soft")^pi (s, a)$ 固定了当前时刻 $t$ 的动作 $A_t = a$，故仅包含从 $t + 1$ 时刻起的未来策略熵）。由此可导出修正后的#strong[软贝尔曼期望方程（Soft Bellman Expectation Equations）]：
$
  #eqbox([$ q_upright("soft")^pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_upright("soft")^pi (S_(t + 1))$) divides S_t = s, A_t = a] $]) \
  #eqbox([$ v_upright("soft")^pi (s) = bb(E)_(A_t tilde.op pi(dot.op divides s)) [#mhlg($q_upright("soft")^pi (s, A_t)$) - #mhl($alpha log pi (A_t divides s)$)] $])
$ <eq-pg-soft-bellman>
将 @eq-pg-soft-bellman 的第二式（$v_upright("soft")^pi arrow.r q_upright("soft")^pi$ 桥接式，其中已包含状态 $S_(t + 1)$ 处的熵项 $- alpha log pi(A_(t + 1) divides S_(t + 1))$）代入第一式（$q_upright("soft")^pi arrow.r v_upright("soft")^pi$ 桥接式），即得软动作价值的复合自递推方程：
$
  q_upright("soft")^pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1), A_(t + 1)) [R_(t + 1) + gamma (#mhlg($q_upright("soft")^pi (S_(t + 1), A_(t + 1))$) - #mhl($alpha log pi (A_(t + 1) divides S_(t + 1))$)) divides S_t = s, A_t = a] .
$ <eq-pg-soft-bellman-qq>
对比第 3 章的标准贝尔曼期望方程（@eq-bellman-exp-vq 至 @eq-bellman-exp-qq）可见，软贝尔曼方程完全保留了“单步即时奖励 + 折扣后继价值”的压缩映射结构，仅在策略层桥接与自递推中额外计入了策略熵修正项 $- alpha log pi$。因此，软贝尔曼算子同样满足 $gamma$-压缩性质，可直接应用#link(<sec-value-estimation>)[第 6 章]的离轨时序差分方法进行迭代求解——这正是 @tab-pg-bellman-boundary 将 SAC 列为显式求解贝尔曼方程代表的原因。在算法实现上，SAC 交替执行基于 @eq-pg-soft-bellman-qq 的双软 Q 网络离轨 TD 更新，以及基于重参数化技巧（Reparameterization Trick）的随机策略梯度上升。

#strong[统计代价与理论性质]：引入熵正则项改变了原 MDP 的最优不动点——SAC 收敛到的是最大熵目标 @eq-pg-sac-objective 下的软最优策略（玻尔兹曼分布形式），而非原始确定性最优策略 $pi_star$；同时，算法性能对温度系数 $alpha$ 的尺度较为敏感（现代实现通常设定目标熵下界并通过对偶梯度下降自动调节 $alpha$）。

#figure(
  caption: [策略梯度三类重要扩展变体的核心问题、改进方案与统计性质对比],
  text(size: 8.6pt, table(
    columns: (0.75fr, 1.5fr, 1.3fr, 1.25fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([算法变体], [核心问题], [核心机制与改进方案], [统计代价与理论性质]),
    table.hline(),
    [TRPO], [欧氏步长难以控制策略分布偏移，步长过大会引发性能塌缩], [施加平均 KL 散度信任域约束，最大化离轨重要性采样代理目标（@eq-pg-trpo）], [每步需用共轭梯度法与线搜索求解二阶约束优化，计算开销较大],
    table.hline(stroke: 0.6pt + accent),
    [PPO], [同上，旨在以纯一阶梯度方法近似信任域约束], [对单步似然比施加区间 $[1 - epsilon, 1 + epsilon]$ 裁剪，构造保守下界目标（@eq-pg-ppo-clip）], [裁剪边界处截断梯度引入偏差，有效步幅依赖于超参数 $epsilon$],
    table.hline(stroke: 0.6pt + accent),
    [DDPG / TD3], [连续动作空间下 $max_a Q$ 难以解析求解，随机策略积分方差大], [采用确定性策略 $mu_bold(theta)(s)$ 并由链式法则沿 $nabla_a Q$ 反传梯度（@eq-pg-dpg）], [需外加探索噪声；Actor 易放大 $Q$ 的高估误差（TD3 以双 Critic 抑制）],
    table.hline(stroke: 0.6pt + accent),
    [SAC], [纯回报目标缺乏探索激励，策略熵易过早退化并陷入局部极值], [最大化熵正则目标（@eq-pg-sac-objective），Critic 求解软贝尔曼方程（@eq-pg-soft-bellman）], [最优不动点改变为软最优策略；温度系数 $alpha$ 需自适应调节],
    table.hline(),
    [REINFORCE / A2C], [（基础同轨策略梯度基准）], [直接沿 @eq-pg-reinforce-update 或 @eq-pg-ac-update 做一阶梯度更新], [REINFORCE 方差高；A2C 含 Critic 自举逼近偏差且无步长信任域保护],
  )),
) <tab-pg-variants>

#divider()

== 信任域裁剪框架的延伸：大语言模型可验证奖励强化学习（RLVR）算法谱系
<sec-rlvr-lineage>

#link(<sec-pg-variants>)[第 7.9.1 节]所建立的 PPO 裁剪代理目标（@eq-pg-ppo-clip）不仅在连续控制领域成为标准基线，还在大语言模型（LLM）的后训练阶段得到了广泛继承与深入发展。在面向数学推理与代码生成等任务的可验证奖励强化学习（Reinforcement Learning from Verifiable Rewards, RLVR）中，研究者在 PPO 裁剪代理目标的统一框架下相继提出了 GRPO、DAPO、GSPO 与 DCPO 四代代表性算法。本节从问题设定出发，将这四代算法的演进统一归结为#strong[三个核心设计维度（优势函数估计、信任域比率与裁剪边界、目标函数归一化尺度）]上的系统性改进。

=== 任务建模：自回归词元（Token）序列生成与稀疏末端奖励

在将策略梯度应用于自回归大语言模型时，其马尔可夫决策过程建模与#link(<sec-pg-setup>)[第 7.1 节]的标准设定相比具有三项结构性特征：

1. #strong[自回归序列状态与有限词表动作空间]：给定输入提示（Prompt）$x$，语言模型策略自回归地生成长度为 $|y|$ 的词元序列（Response）$y = (y_1, y_2, dots, y_(|y|))$。在时刻 $t$，动作 $A_t = y_t$ 取自有限词表 $cal(V)$，状态 $S_t = (x, y_(<t))$ 由提示与已生成的前缀词元序列确定性地拼接而成（环境状态转移是完全确定性的）。
2. #strong[序列末端稀疏可验证奖励与无折扣设定]：中间生成步骤无即时奖励（$t < |y|$ 时 $R_t = 0$），仅在序列生成结束时由确定性规则校验器（如答案匹配或单元测试）给出整条序列的标量奖励 $R(x, y) in [0, 1]$，且折扣因子通常取 $gamma = 1$。
3. #strong[同提示成组采样（Group Sampling）]：在每次采样阶段，针对同一输入提示 $x$，从旧策略 $pi_(bold(theta)_upright("old")) (dot.op divides x)$ 中独立并行采样一组共 $G$ 条完整回复 ${y_1, y_2, dots, y_G}$，从而天然具备对同一状态起点下的多条轨迹回报进行组内统计比较的条件。

由链式法则，整条回复序列 $y$ 在策略 $pi_bold(theta)$ 下的条件生成概率等于各时间步词元条件概率的连乘积：
$
  pi_bold(theta) (y divides x) = product_(t = 1)^(|y|) pi_bold(theta) (y_t divides x, y_(<t)) .
$ <eq-rlvr-seq-prob>

在 $gamma = 1$ 且仅末端存在奖励 $R(x, y)$ 的设定下，任意时刻 $t$ 的真实动作价值仍良定义为从前缀状态 $(x, y_(<t))$ 选择词元 $y_t$ 后的条件期望回报 $q_(pi_bold(theta)) (S_t, A_t) = bb(E)_(y_(>t) tilde.op pi_bold(theta)) [R(x, y) divides x, y_(lt.eq t)]$。然而，由于词表空间庞大，#strong[每条生成轨迹中的长前缀状态 $(x, y_(<t))$ 在单次批次中几乎只被访问一次]：既无法直接对同一中间前缀状态做多次蒙特卡洛树采样求均值，而训练一个与生成模型同等参数规模的独立 Critic 价值网络不仅显存与计算开销高昂，其单样本拟合误差还会直接传递为策略梯度的偏差。这一结构性矛盾构成了 RLVR 算法演进的起点——即如何在#strong[移除独立 Critic 价值网络]的前提下，构造低方差、少偏差的优势估计与稳定的信任域约束。

=== 统一裁剪代理目标与三个核心设计维度

上述四代 RLVR 算法共享基于 @eq-pg-ppo-clip 的#strong[裁剪代理目标函数（Clipped Surrogate Objective）]骨架，其一般形式可统一写为对提示分布、组内 $G$ 条采样回复及序列内词元位置的嵌套加权期望：
$
  J_upright("RLVR") (bold(theta)) = bb(E)_(x tilde.op cal(D), thin {y_i}_(i=1)^G tilde.op pi_(bold(theta)_upright("old")) (dot.op divides x)) [ frac(1, G) sum_(i = 1)^G frac(1, |y_i|) sum_(t = 1)^(|y_i|) min(rho_(i,t) (bold(theta)) hat(A)_(i,t), thin upright("clip")(rho_(i,t) (bold(theta)), 1 - epsilon_upright("low"), 1 + epsilon_upright("high")) hat(A)_(i,t)) ] ,
$ <eq-rlvr-shell>
其中第 $i$ 条回复在第 $t$ 个词元位置上的单步重要性采样比定义为：
$
  rho_(i,t) (bold(theta)) eq.dot frac(pi_bold(theta) (y_(i,t) divides x, y_(i,<t)), pi_(bold(theta)_upright("old")) (y_(i,t) divides x, y_(i,<t))) .
$ <eq-rlvr-token-ratio>

与标准 PPO 目标（@eq-pg-ppo-clip）相比，@eq-rlvr-shell 将内层求和显式展开至词元粒度，外层引入了对同提示组内 $G$ 条回复的平均，并将裁剪上下界推广为允许非对称的参数 $(epsilon_upright("low"), epsilon_upright("high"))$。正如#link(<sec-expectation-estimation-theory>)[第 6.1 节]通过三个设计维度统一价值估计算法一样，四代 RLVR 算法之间的本质差异可完全归结为以下#strong[三个核心设计维度]：

1. #strong[设计维度一：优势函数估计量 $hat(A)_(i,t)$ 的构造方式]——决定了信用分配（Credit Assignment）的时间粒度以及是否依赖独立 Critic 网络：是采用基于 Critic 网络的逐词元 GAE（标准 PPO），还是采用同提示组内标准化相对回报（GRPO），抑或结合跨步历史统计的平滑优势估计（DCPO）。
2. #strong[设计维度二：信任域似然比的定义粒度与裁剪边界函数]——决定了策略分布偏移的度量单位与截断机制：是以单词元概率比 $rho_(i,t)$ 配合对称/非对称常数边界（GRPO / DAPO），还是以序列级几何平均似然比 $s_i$ 配合序列级常数边界（GSPO），抑或以单词元概率比配合依赖于旧策略概率 $q_(i,t)$ 的自适应边界函数（DCPO）。
3. #strong[设计维度三：目标函数关于序列长度的归一化尺度]——决定了不同长度回复在总梯度中的相对权重：是采用“先对每条回复内部按长度 $|y_i|$ 平均、再对组内 $G$ 条回复平均”的序列级归一化（GRPO），还是采用“对批次内所有词元等权平均”的词元级归一化（DAPO），抑或采用仅在单条回复内部平均的归一化方式（DCPO）。

除上述三个核心维度外，目标函数中还常包含一项关于参考策略 $pi_upright("ref")$ 的 KL 散度正则项 $beta D_upright("KL")(pi_bold(theta) parallel pi_upright("ref"))$。在基于人类反馈的强化学习（RLHF）中，该项用于防止策略过度迎合不完美的神经奖励模型（Reward Hacking）；而在 RLVR 中，由于奖励由精确的规则校验器给出，无需担心奖励模型失真，因此自 DAPO 起的后续算法常将该 KL 正则项系数置零以释放长链推理策略的探索空间。@fig-rlvr-lineage 展示了这四代算法沿三个核心维度的演进脉络。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (12mm, 6mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,
      node((0, 0), text(size: 7.8pt)[*共同基础：PPO 裁剪代理目标框架*（@eq-pg-ppo-clip、@eq-rlvr-shell） \ 逐词元或逐序列最大化 $min(rho_(i,t) hat(A)_(i,t), thin upright("clip")(rho_(i,t), 1 - epsilon_upright("low"), 1 + epsilon_upright("high")) hat(A)_(i,t))$ \ 以重要性采样比率裁剪近似 TRPO 的信任域约束], fill: accent-soft, width: 96mm),
      node((0, 1), text(size: 7.4pt)[*PPO（RLHF 基准）*：以独立 Critic 网络配合 GAE 逐词元估计优势，单提示单回复采样 \ 局限性：Critic 价值网络使显存与算力开销翻倍；长前缀仅单次采样，价值拟合偏差直接污染策略梯度], width: 96mm),
      node((0, 2), text(size: 7.4pt)[*GRPO*：维度一改进 —— 以同提示组内标准化回报作为序列内各词元的共享优势（@eq-rlvr-group-adv），移除 Critic \ 局限性：序列内词元级信用分配缺失；组内奖励全同导致零梯度；$1 / sigma$ 与 $1 / |y_i|$ 引入难度与长度权重偏差], width: 96mm),
      node((0, 3), text(size: 7.4pt)[*DAPO*：维度二、三改进 + 数据过滤 —— 非对称上界放宽（Clip-Higher）、批次词元等权归一化（@eq-rlvr-dapo-loss）、动态过滤全同组、超长奖励整形并移除 KL 正则 \ 局限性：丢弃全同组样本增加了额外采样开销], width: 96mm),
      node((0, 4), text(size: 7.4pt)[*GSPO*：维度二改进 —— 将重要性比率与裁剪单位由单词元提升为长度归一化序列似然比（@eq-rlvr-gspo-ratio），匹配序列级奖励 \ 局限性：几何平均似然比有偏；序列级裁剪将整条回复内的词元梯度一并截断], width: 96mm),
      node((0, 5), text(size: 7.4pt)[*DCPO*：维度一、二、三综合改进 —— 裁剪边界由旧概率 $q_(i,t)$ 自适应决定（@eq-rlvr-dcpo-bounds）、跨步平滑优势 SAS（@eq-rlvr-sas）、回复内归一化 \ 局限性：对旧概率数值精度敏感，低概率处需引入硬上限超参数截断], width: 96mm),
      edge((0, 0), (0, 1), "->"),
      edge((0, 1), (0, 2), "->", text(size: 6.6pt)[维度一], label-side: right),
      edge((0, 2), (0, 3), "->", text(size: 6.6pt)[维度二、三 + 采样层], label-side: right),
      edge((0, 3), (0, 4), "->", text(size: 6.6pt)[维度二], label-side: right),
      edge((0, 4), (0, 5), "->", text(size: 6.6pt)[维度一、二、三], label-side: right),
    )
  },
  caption: [大语言模型 RLVR 四代策略梯度算法在统一裁剪代理目标 @eq-rlvr-shell 下的演进谱系：各代算法围绕优势估计（维度一）、信任域比率与裁剪边界（维度二）及长度归一化尺度（维度三）针对性地解决前代算法的理论局限],
) <fig-rlvr-lineage>

=== 第一代：GRPO —— 以组内相对回报基线替代 Critic 价值网络

#strong[核心问题]：在标准 PPO 中，广义优势估计（GAE，@eq-pg-gae）依赖一个通常与策略网络同等参数规模的 Critic 价值网络，在大语言模型训练中带来近一倍的显存与计算负担；同时，由于 RLVR 仅在序列末尾提供稀疏奖励且每个长前缀状态仅被采样一次，Critic 对中间词元价值的拟合存在较大逼近误差，直接降低了策略梯度估计的准确性。

#strong[核心机制]：Shao et al. (2024) 提出的#strong[组相对策略优化（Group Relative Policy Optimization, GRPO）]完全移除了 Critic 网络，转而在维度一上利用同提示下 $G$ 条采样回复的末端奖励统计量构造基线：将组内标准化后的相对回报直接赋值给该回复序列中的所有词元作为共享优势估计：
$
  hat(A)_i = frac(R_i - mu_R, sigma_R), quad mu_R = frac(1, G) sum_(j = 1)^G R_j, quad sigma_R = sqrt(frac(1, G) sum_(j = 1)^G (R_j - mu_R)^2), quad hat(A)_(i,t) eq.dot hat(A)_i quad (forall t in {1, dots, |y_i|}) .
$ <eq-rlvr-group-adv>

从理论上看，@eq-rlvr-group-adv 是#link(<sec-pg-baseline>)[第 7.5 节]状态基线定理（#link(<prop-7.2>)[命题 7.2]）在序列级 MDP 上的经验近似：它将基线函数 $b(x) = v_(pi_bold(theta)) (x)$ 替换为同一提示状态 $x$ 下多条独立采样轨迹的平均回报 $mu_R$。严格而言，由于 $mu_R$ 包含了当前样本回报 $R_i$ 自身（对比严格无偏的留一法均值基线 $mu_(-i) = frac(1, G - 1) sum_(j eq.not i) R_j$，有 $R_i - mu_R = frac(G - 1, G)(R_i - mu_(-i))$，仅差常数因子 $frac(G - 1, G)$），且分母除以了依赖样本的经验标准差 $sigma_R$，@eq-rlvr-group-adv 会引入随组大小 $G$ 增大而衰减的微弱归一化偏差，但在 $G in [8, 64]$ 的常规设置下显著降低了策略梯度的方差并免去了 Critic 网络开销。

#block(breakable: false, above: 1em)[
#strong[统计代价与理论局限]：GRPO 的简化设计引入了三项新的理论局限，构成了后续三代算法的改进动因：

1. #strong[序列内词元级信用分配缺失]：同一回复 $y_i$ 内的所有词元共享完全相同的标量优势 $hat(A)_(i,t) equiv hat(A)_i$，无法区分长链推理过程中关键正确推导步骤与冗余或局部错误步骤的个体贡献。
2. #strong[组内全同奖励下的零梯度退化]：当同一提示下的 $G$ 条回复全部正确（$R_j equiv 1$）或全部错误（$R_j equiv 0$）时，组内方差为零、分子 $R_i - mu_R = 0$，导致整组样本的优势估计 $hat(A)_i equiv 0$，对该提示产生零梯度更新，降低了训练中后期的有效样本利用率。
3. #strong[长度与难度归一化偏差]：@eq-rlvr-shell 中的序列级归一化因子 $frac(1, |y_i|)$ 使较短回复中的单个词元获得更大的梯度权重（在负优势下倾向于惩罚短回复、诱发回复长度膨胀，在正优势下则稀释长推理链的奖励信号）；同时分母 $sigma_R$ 会放大组内方差极小样本的梯度步幅。
]

=== 第二代：DAPO —— 非对称裁剪、词元级归一化与动态采样过滤

#strong[核心问题]：在长思维链（Long-CoT）推理训练中，GRPO 的对称裁剪上界限制了低概率探索词元的概率提升（引发策略熵过早坍缩），全对或全错提示组导致有效梯度比例持续下降，序列级长度归一化 $frac(1, |y_i|)$ 扭曲了长短回复的权重，且超出最大上下文长度被强制截断的回复带来了虚假的负奖励噪声。

#strong[核心机制]：Yu et al. (2025) 提出的#strong[解耦裁剪与动态采样策略优化（DAPO）]在保持 @eq-rlvr-shell 核心结构不变的前提下，对维度二、维度三及数据采样层进行了针对性修正（同时移除了 KL 散度正则项）：

1. #strong[维度二改进：解耦非对称裁剪（Clip-Higher）]——将裁剪上下界解耦设置为 $epsilon_upright("low") = 0.2$ 与较大的 $epsilon_upright("high") = 0.28$。其机理在于：对于满足 $hat(A)_i > 0$ 的优势动作，若旧策略赋予某关键探索词元的概率 $q$ 很低（如 $q = 0.01$），对称上界 $1 + epsilon = 1.2$ 仅允许单步将其概率提升至 $0.012$，严重制约了低概率高价值推理分支的强化；适度放宽上界 $epsilon_upright("high")$ 可有效维持策略分布的多样性、防止熵坍缩，而保持较小的下界 $epsilon_upright("low")$ 则可避免负优势词元的概率被过快压缩至零。
2. #strong[维度三改进：批次词元级等权归一化（Token-Level Policy Gradient Objective）]——将代理目标函数（最大化目标）的外层归一化方式由“先按每条回复长度 $|y_i|$ 平均”修改为对同一提示组内所有词元的总数做等权平均：
   $
     J_upright("DAPO") (bold(theta)) = bb(E)_(x, thin {y_i}) [ frac(1, sum_(i = 1)^G |y_i|) sum_(i = 1)^G sum_(t = 1)^(|y_i|) min(rho_(i,t) (bold(theta)) hat(A)_(i,t), thin upright("clip")(rho_(i,t) (bold(theta)), 1 - epsilon_upright("low"), 1 + epsilon_upright("high")) hat(A)_(i,t)) ] .
   $ <eq-rlvr-dapo-loss>
   在此归一化尺度下，每个词元对目标梯度的贡献权重不再受其所属序列总长度 $|y_i|$ 的反比稀释，从而保证了长链正确推理轨迹中的有效信号强度，并抑制了错误回复为逃避惩罚而盲目增加长度的倾向。
3. #strong[数据采样层改进：动态采样（Dynamic Sampling）与超长奖励整形]——在每次收集训练批次时，在线过滤掉组内奖励全为 $1$ 或全为 $0$（即 $0 < sum_(i=1)^G R_i < G$ 不成立）的提示组并继续采样，确保进入梯度更新的每个提示组均具有非零优势方差；同时对接近或超出最大生成长度的截断样本施加平滑的区间线性惩罚或掩码屏蔽，消除截断伪影带来的奖励噪声。

#strong[统计代价与理论性质]：动态采样虽彻底消除了零梯度组对批次更新的稀释，但丢弃已完成自回归生成的全同组样本意味着需要消耗额外 $3$--$5$ 倍的推理生成算力以填满相同规模的有效训练批次；同时，放宽裁剪上界 $epsilon_upright("high")$ 增大了单步策略分布的最大允许偏移量。

=== 第三代：GSPO —— 从词元级似然比转向长度归一化序列似然比

#strong[核心问题]：在 @eq-rlvr-shell 中，奖励与优势 $hat(A)_i$ 是在#strong[整条序列级别]定义的，而重要性采样比 $rho_(i,t)$ 与裁剪算子却是在#strong[单个词元级别]独立作用的，二者在作用粒度上存在理论错配。这一粒度错配在长序列与混合专家（MoE）模型训练中引发三方面问题：
- 序列级真实重要性采样比为各词元比率的连乘积 $product_(t=1)^(|y_i|) rho_(i,t)$，单词元裁剪无法直接约束整条序列的对数似然累积漂移；
- 推理引擎与训练引擎在算子实现上的微小数值舍入误差，以及 MoE 模型在两次前向传播中专家路由（Expert Routing）的离散跳变，都会导致个别词元的比率 $rho_(i,t)$ 发生剧烈抖动，迫使词元级算法不得不依赖路由回放（Routing Replay）等工程措施维持稳定。

#strong[核心机制]：Zheng et al. (2025) 提出的#strong[组序列策略优化（Group Sequence Policy Optimization, GSPO）]在维度二上将重要性采样比率与信任域裁剪的基本单位统一提升至#strong[序列级别]。为避免纯序列似然比连乘随长度 $|y_i|$ 发生数值下溢或方差爆炸，GSPO 定义长度归一化的几何平均序列似然比 $s_i (bold(theta))$，并直接在序列级别执行裁剪以最大化如下代理目标：
$
  s_i (bold(theta)) eq.dot (frac(pi_bold(theta) (y_i divides x), pi_(bold(theta)_upright("old")) (y_i divides x)))^(frac(1, |y_i|)) = exp(frac(1, |y_i|) sum_(t = 1)^(|y_i|) log frac(pi_bold(theta) (y_(i,t) divides x, y_(i,<t)), pi_(bold(theta)_upright("old")) (y_(i,t) divides x, y_(i,<t)))) ,
$ <eq-rlvr-gspo-ratio>
$
  J_upright("GSPO") (bold(theta)) = bb(E)_(x, thin {y_i}) [ frac(1, G) sum_(i = 1)^G min(s_i (bold(theta)) hat(A)_i, thin upright("clip")(s_i (bold(theta)), 1 - epsilon, 1 + epsilon) hat(A)_i) ] ,
$ <eq-rlvr-gspo-objective>
其中序列优势 $hat(A)_i$ 仍取自组内标准化公式 @eq-rlvr-group-adv。

值得注意的是，由于 $s_i (bold(theta))$ 对全序列对数概率比进行了长度平均（即对数似然比的算术平均再取指数），其数值波动比单词元比率 $rho_(i,t)$ 小得多；因此，GSPO 的裁剪阈值 $epsilon$ 必须相应调整为与“每词元平均对数似然漂移”相匹配的量级（通常取 $3 times 10^(-4) tilde.op 4 times 10^(-4)$，若仍沿用词元级的 $0.2$ 则裁剪约束将几乎失效）。

#block(breakable: false, above: 1em)[
#strong[统计代价与理论性质]：

1. #strong[几何平均似然比的测度变换偏差]：长度归一化比率 $s_i = [pi_bold(theta)(y_i divides x) \/ pi_(bold(theta)_upright("old"))(y_i divides x)]^(1 \/ |y_i|)$ 并非严格的无偏重要性采样权重（真实序列权重为 $s_i^(|y_i|)$），它在梯度中自动引入了与序列长度成反比的缩放并改变了高阶矩，属于以有偏代理目标换取数值稳定性的折中。
2. #strong[序列级整体截断导致的样本信息损失]：当某条长回复的整体比率 $s_i$ 超出 $[1 - epsilon, 1 + epsilon]$ 时，整条回复中的所有词元同时失去梯度信号，无法保留序列内部未越界词元的学习信息。
3. #strong[局部极端漂移被序列平均掩盖]：由于 $log s_i$ 是全序列对数比率的均值，序列内极少数低概率词元的剧烈偏移可能被大量高置信度词元的零偏移所平均稀释，从而逃脱序列级阈值的约束。
]

=== 第四代：DCPO —— 概率自适应动态裁剪边界与跨步平滑优势估计

#strong[核心问题]：在前三代算法中，词元级裁剪边界 $[1 - epsilon_upright("low"), 1 + epsilon_upright("high")]$ 均为与旧策略概率 $q_(i,t) eq.dot pi_(bold(theta)_upright("old")) (y_(i,t) divides x, y_(i,<t))$ 无关的固定常数。然而，相同的比率偏移量在不同基础概率下对应的#strong[实际概率质量变化 $|p - q| = |rho - 1| q$] 相差悬殊：当 $q = 0.9$ 时，比率变动 $0.2$ 意味着概率质量大幅改变 $0.18$；而当 $q = 0.01$（对应高熵推理分支处的探索词元）时，比率变动 $0.28$ 仅允许概率质量微调 $0.0028$。固定常数比率边界因此对低概率探索词元施加了过分严苛的限制，而对高概率词元又相对宽松。

#strong[核心机制]：Yang et al. (2025) 提出的#strong[动态裁剪策略优化（Dynamic Clipping Policy Optimization, DCPO）]在保留 @eq-rlvr-shell 词元级代理目标骨架的基础上，同时对全部三个核心设计维度进行了修正：

1. #strong[维度二改进：基于旧策略概率的自适应动态裁剪边界（Dynamic Adaptive Clipping）]——不直接约束相对比率偏移 $|rho - 1| lt.eq epsilon$，而是约束由新策略概率 $p = rho q$ 加权的概率质量变动 $|(rho - 1) p| = |rho (rho - 1)| q lt.eq epsilon$。分别针对下界（$rho < 1$ 时要求 $(1 - rho) rho q lt.eq epsilon_upright("low")$）与上界（$rho > 1$ 时要求 $(rho - 1) rho q lt.eq epsilon_upright("high")$）求解关于比率 $rho$ 的一元二次不等式 $rho^2 - rho - epsilon_upright("high") \/ q lt.eq 0$ 与 $rho^2 - rho + epsilon_upright("low") \/ q gt.eq 0$，可得依赖于旧策略概率 $q$ 的闭式动态裁剪边界函数 $[b_upright("low") (q), b_upright("high") (q)]$：
   $
     #mhl($b_upright("low") (q) eq.dot frac(1, 2) + frac(1, 2) sqrt(max(1 - frac(4 epsilon_upright("low"), q), 0))$), #h(2em) #mhlb($b_upright("high") (q) eq.dot min(frac(1, 2) + frac(1, 2) sqrt(1 + frac(4 epsilon_upright("high"), q)), thin rho_max)$) .
   $ <eq-rlvr-dcpo-bounds>
   （其中为防止 $q arrow.r 0$ 时上界按 $O(1 \/ sqrt(q))$ 无界发散，工程上设置硬上限截断常数 $rho_max = 10$。）由 @eq-rlvr-dcpo-bounds 可见：当 $q$ 接近 $1$ 时，由一阶泰勒展开 $sqrt(1 plus.minus 4 epsilon \/ q) approx 1 plus.minus 2 epsilon$，动态边界自然退化为标准常数边界 $[1 - epsilon_upright("low"), 1 + epsilon_upright("high")]$；而当 $q arrow.r 0$ 时，上界 $b_upright("high") (q)$ 显著放宽，从而在不破坏整体信任域稳定性的前提下为低概率探索词元赋予充足的更新空间。
2. #strong[维度一改进：跨步平滑优势估计（Smooth Advantage Standardization, SAS）]——为在不丢弃全同奖励样本组（对比 DAPO 的动态采样）的前提下缓解零梯度与单步小样本统计抖动，DCPO 对同一提示 $x$ 在第 $k$ 个训练步的当前组内标准化优势 $hat(A)_upright("cur")$ 与跨历史训练步累积的全局标准化优势 $hat(A)_upright("tot")$ 构造两组互补的步数加权平均：
   $
     hat(S)_upright("cur") = frac(k - 1, k) hat(A)_upright("cur") + frac(1, k) hat(A)_upright("tot"), #h(2em) hat(S)_upright("tot") = frac(1, k) hat(A)_upright("cur") + frac(k - 1, k) hat(A)_upright("tot") ,
   $
   进而选取二者中绝对值较小者（保守最小幅值准则）作为最终传入代理目标的平滑优势估计量 $hat(A)_(i,t)^upright("SAS")$：
   $
     #eqbox([$ hat(A)_(i,t)^upright("SAS") eq.dot cases(
       hat(S)_upright("cur") \, & upright("若 ") |hat(S)_upright("cur")| lt.eq |hat(S)_upright("tot")| \,,
       hat(S)_upright("tot") \, & upright("若 ") |hat(S)_upright("cur")| > |hat(S)_upright("tot")| .
     ) $])
   $ <eq-rlvr-sas>
   通过引入跨步累积统计量 $hat(A)_upright("tot")$，即使当前步组内 $G$ 条回复偶然全部全对或全错（$hat(A)_upright("cur") = 0$），只要历史累积分布具有非零方差，样本仍能获得有效的非零优势信号，避免了 DAPO 丢弃整组样本所造成的采样算力浪费；同时取 $min(|hat(S)_upright("cur")|, |hat(S)_upright("tot")|)$ 有效抑制了异常单步统计值导致的梯度突变。
3. #strong[维度三改进：回复内平均与批次级汇总（Response-Specific Normalization）]——DCPO 将待最大化的裁剪代理目标函数定义为仅在每条回复内部按长度 $|y_i|$ 平均（外层对批次内总回复数归一化，不再按总词元数加权）：
   $
     J_upright("DCPO") (bold(theta)) = bb(E)_(x, thin {y_i}) [ frac(1, G) sum_(i = 1)^G frac(1, |y_i|) sum_(t = 1)^(|y_i|) min(rho_(i,t) (bold(theta)) hat(A)_(i,t)^upright("SAS"), thin upright("clip")(rho_(i,t) (bold(theta)), b_upright("low") (q_(i,t)), b_upright("high") (q_(i,t))) hat(A)_(i,t)^upright("SAS")) ] ,
   $ <eq-rlvr-dcpo-loss>
   其中 $b_upright("low") (q_(i,t)), b_upright("high") (q_(i,t))$ 由 @eq-rlvr-dcpo-bounds 给出。其设计依据在于：组内标准化优势 $hat(A)_i$ 已经完成了同一提示下各条回复之间的相对重要度标定，若采用 DAPO 的批次词元等权（相当于给每条回复额外乘以长度权重 $|y_i|$），反而会使优势绝对值较小但篇幅冗长的回复在总梯度中占据主导地位。

#block(breakable: false, above: 1em)[
#strong[统计代价与理论性质]：

1. #strong[对旧策略词元概率数值精度的强依赖]：动态边界 $b_upright("low") (q), b_upright("high") (q)$ 直接以旧策略的单词元概率 $q_(i,t)$ 为自变量，在 $q_(i,t) << 1$ 时对推理与训练引擎之间的数值不一致高度敏感（恰与 GSPO 追求序列级平滑的取向相反）。
2. #strong[奇异点截断超参数的引入]：由于 $1 \/ sqrt(q)$ 在 $q arrow.r 0$ 时发散，算法必须依赖人为设定的硬上限阈值 $rho_max$ 来维持有界性，增加了超参数耦合（$epsilon_upright("low"), epsilon_upright("high"), rho_max$）。
]

=== 四代 RLVR 算法的理论对比与方法论总结

@tab-rlvr-lineage 在统一的裁剪代理目标框架下横向对比了 PPO（RLHF 基准）与四代 RLVR 算法的核心问题、在三个核心设计维度上的具体改进以及各自的统计代价。

#figure(
  caption: [大语言模型四代 RLVR 策略梯度算法在统一裁剪代理目标框架（@eq-rlvr-shell）下的理论对比。各算法共享一阶似然比裁剪结构，核心差异体现在优势函数估计（维度一）、信任域比率粒度与裁剪边界函数（维度二）以及序列长度归一化尺度（维度三）],
  text(size: 8.4pt, table(
    columns: (0.6fr, 1.5fr, 1.65fr, 1.35fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([算法], [核心问题], [核心机制与改进方案（所属设计维度）], [统计代价与理论局限]),
    table.hline(),
    [PPO \ （基准）], [逐词元优势依赖独立 Critic 网络；显存与算力开销翻倍，且单次前缀采样下价值拟合偏差大], [（基准方案）以 Critic 网络配合 GAE 逐词元估计优势（@eq-pg-gae），单提示采样单条回复], [训练显存与计算量高昂；长序列前缀缺乏重复采样，Critic 逼近误差直接转化为梯度偏差],
    table.hline(stroke: 0.6pt + accent),
    [GRPO], [移除独立 Critic 后，如何在仅有末端奖励的条件下构造低方差基线], [维度一：同提示采样 $G$ 条回复，以组内标准化回报作为序列内各词元的共享优势（@eq-rlvr-group-adv）], [序列内词元级信用分配缺失；全同奖励组产生零梯度；$1 / sigma_R$ 与 $1 / |y_i|$ 引入权重偏差],
    table.hline(stroke: 0.6pt + accent),
    [DAPO], [固定对称上界抑制低概率词元探索（熵坍缩）；全同组稀释梯度；序列归一化扭曲长度权重], [维度二、三 + 采样层：非对称裁剪（上界放宽至 $0.28$）、批次词元等权目标（@eq-rlvr-dapo-loss）、动态过滤全同组、超长奖励整形；移除 KL 正则], [动态过滤丢弃已生成的全同组样本，相同有效更新步数需额外消耗数倍推理生成算力],
    table.hline(stroke: 0.6pt + accent),
    [GSPO], [序列级奖励与词元级似然比粒度错配；长序列方差累积且对 MoE 路由抖动敏感], [维度二：将重要性比率与裁剪单位提升为长度归一化几何平均序列似然比（@eq-rlvr-gspo-ratio、@eq-rlvr-gspo-objective），阈值降至 $10^(-4)$ 量级], [几何平均比率并非无偏测度变换；序列级整体裁剪会一并截断回复内的正常词元；局部极端漂移被平均掩盖],
    table.hline(stroke: 0.6pt + accent),
    [DCPO], [常数比率边界对低概率探索词元的实际概率质量更新限制过严；整条裁剪与丢组浪费样本], [维度一、二、三：由旧概率 $q_(i,t)$ 导出自适应动态边界（@eq-rlvr-dcpo-bounds）、跨步平滑优势 SAS（@eq-rlvr-sas）、回复内平均目标（@eq-rlvr-dcpo-loss）], [对低概率词元的数值精度敏感；$q arrow.r 0$ 处需引入硬上限 $rho_max$ 截断；多超参数耦合],
  )),
) <tab-rlvr-lineage>

综合上述演进脉络，可得出以下三点理论结论：

1. #strong[贝尔曼自举在序列末端稀疏奖励场景下的完全退场]：在 @tab-pg-bellman-boundary 所列的经典 Actor-Critic 算法中，贝尔曼期望方程仍作为 Critic 估计状态价值的辅助工具；而在以 GRPO 为代表的 RLVR 算法族中，通过利用同提示下多条完整轨迹的组内经验均值直接充当状态基线 $b(x) approx v_(pi_bold(theta)) (x)$，彻底省去了对中间状态价值的时序差分自举，使策略梯度回归到无需贝尔曼递推的组内蒙特卡洛基线范式。
2. #strong[信任域代理目标设计自由度的精细化扩展]：从经典 PPO 单一的对称裁剪常数 $epsilon$ 出发，RLVR 算法谱系在维度二上依次解耦出“上下界非对称度”（DAPO）、“比率定义的时间粒度（词元级 vs. 序列几何平均）”（GSPO）以及“依赖旧策略概率的自适应边界函数 $b(q)$”（DCPO），更精确地逼近了概率分布空间中的局部信任域约束。
3. #strong[设计维度上的内生权衡]：在重要性比率粒度（词元级局部精细裁剪 vs. 序列级全局平滑裁剪）、零梯度组处置（在线丢弃重采 vs. 跨步历史统计平滑）以及长度归一化尺度（词元等权 vs. 回复等权）这三组核心矛盾上，GSPO 与 DCPO 分别代表了面向不同工程瓶颈（MoE 路由数值稳定性 vs. 词元级探索效率）的互补设计取向。

#divider()

// ============================================================
//  第 8 章：方程结构定性、强化学习算法关联谱系与工程选型
// ============================================================
= 方程结构定性、强化学习算法关联谱系与工程选型
<sec-algo-selection>

== 四类递推算子的结构特征与计算复杂度
<sec-operator-complexity>
贝尔曼期望方程（#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-exp-explicit>)[4 章]）与贝尔曼最优方程（#link(<sec-bellman-opt>)[第 5 章]）共享相同的#strong[环境层转移结构]，二者的结构差异仅在于#strong[策略层算子]是用策略分布加权求和 $sum_a pi(a divides s)$ 还是取贪心最大值 $max_a$。四类递推关系在 MDP 交互图中的算子构成、存储开销与单轮全状态更新复杂度对比见 @tab-operator-complexity。

#figure(
  caption: [四类贝尔曼递推算子的结构特征、空间开销与单轮全量更新计算复杂度对比],
  table(
    columns: 6,
    table.header(
      [递推类型],
      [策略层算子 \ （期望 / 最优）],
      [环境层算子],
      [维护变量与 \ 空间复杂度],
      [单轮全量更新 \ 计算复杂度],
      [核心数学依据],
    ),
    table.hline(),
    [#strong[$v arrow.r q$]],
    [$sum_a pi(a divides s)$ ／ $max_a$],
    [无（同一时刻 $t$）],
    [$v$: $O(|cal(S)|)$ \ $q$: $O(|cal(S)| thin |cal(A)|)$],
    [$O(|cal(S)| thin |cal(A)|)$],
    [条件全期望公式（#link(<lem-2>)[引理 2]） \ ／ 贪心最大化（#link(<thm-5.1>)[定理 5.1]）],
    [#strong[$q arrow.r v$]],
    [无（动作 $a$ 已固定）],
    [$sum_(s', r) p(s', r divides s, a) [dot.op]$],
    [$v$: $O(|cal(S)|)$ \ $q$: $O(|cal(S)| thin |cal(A)|)$],
    [$O(|cal(S)|^2 thin |cal(A)| thin |cal(R)|)$],
    [回报一步递推（#link(<prop-1.1>)[命题 1.1]） \ + 马尔可夫性（#link(<lem-3>)[引理 3]）],
    [#strong[$v arrow.r v$]],
    [外层：$sum_a pi(a divides s)$ ／ $max_a$],
    [内层：$sum_(s', r) p(s', r divides s, a) [dot.op]$],
    [仅维护 $v$: \ $O(|cal(S)|)$],
    [$O(|cal(S)|^2 thin |cal(A)| thin |cal(R)|)$],
    [$(v arrow.r q) compose (q arrow.r v)$ \ 先策略层后环境层],
    [#strong[$q arrow.r q$]],
    [内层：$sum_(a') pi(a' divides s')$ ／ $max_(a')$],
    [外层：$sum_(s', r) p(s', r divides s, a) [dot.op]$],
    [仅维护 $q$: \ $O(|cal(S)| thin |cal(A)|)$],
    [$O(|cal(S)|^2 thin |cal(A)|^2 thin |cal(R)|)$],
    [$(q arrow.r v) compose (v arrow.r q)$ \ 先环境层后策略层],
  ),
) <tab-operator-complexity>

（注：若环境奖励函数确定或已按 @eq-variant-expected-reward 预先计算单步期望奖励 $r(s, a) = sum_(s', r) r thin p(s', r divides s, a)$ 与状态转移边缘概率 $p(s' divides s, a) = sum_r p(s', r divides s, a)$，则 @tab-operator-complexity 时间复杂度中的 $|cal(R)|$ 因子可消去。）

#divider()

== 贝尔曼方程结合期望估计算法导出强化学习算法的关联谱系
<sec-rl-genealogy>
将贝尔曼期望方程与贝尔曼最优方程、状态价值 $V$ 与动作价值 $Q$ 两类对象，以及#link(<sec-value-estimation>)[第 6 章]的三类期望估计方法（不动点迭代、蒙特卡洛样本均值、Robbins-Monro 随机近似）组合，再配合广义策略迭代（Generalized Policy Iteration, GPI）与参数化函数近似，可得到从表格型方法到深度强化学习（Deep RL）的主要算法。各估计方法结合贝尔曼期望 / 最优方程导出的状态价值与动作价值算法见 @fig-rl-genealogy，对应的更新公式见 @tab-all-value-estimators。图中最下一层是#link(<sec-policy-gradient>)[第 7 章]的策略梯度范式：它不再以贝尔曼不动点方程为最终求解对象，而是直接对期望回报性能目标求导，贝尔曼方程仅以“优势函数定义 + Critic 辅助价值估计”的形式进入梯度估计（唯一的显式结合特例是求解软贝尔曼期望方程的 SAC）。

#figure(
  {
    set par(justify: false)
    let L(body) = align(left, text(size: 7.6pt, body))
    diagram(
      spacing: (6mm, 6mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,

      // 列分组：只圈算法行，方程节点在框外
      node(enclose: ((0, 2), (0, 4)), stroke: (dash: "dashed", paint: hl-blue-stroke, thickness: 0.6pt), fill: none, inset: 2pt, snap: false),
      node(enclose: ((2, 2), (2, 4)), stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.6pt), fill: none, inset: 2pt, snap: false),

      // 第 0 层：根
      node((1, 0), text(size: 7.6pt)[*价值定义与回报递推*（第 1 章） \ $v_pi (s) = bb(E)[G_t divides S_t = s]$ \ $q_pi (s, a) = bb(E)[G_t divides S_t = s, A_t = a]$], fill: accent-soft, width: 46mm),

      // 第 1 层：两类贝尔曼方程
      node((0, 1), text(size: 7.6pt)[*贝尔曼期望方程*（第 3–4 章） \ $v_pi = cal(T)^pi_V v_pi, med q_pi = cal(T)^pi_Q q_pi$ \ 下方框内：预测 / 评估], fill: hl-blue-fill, stroke: 0.85pt + hl-blue-stroke, width: 52mm),
      node((2, 1), text(size: 7.6pt)[*贝尔曼最优方程*（第 5 章） \ $v_star = cal(T)^star_V v_star, med q_star = cal(T)^star_Q q_star$ \ 下方框内：控制], fill: hl-amber-fill, stroke: 0.85pt + hl-amber-stroke, width: 52mm),
      edge((1, 0), (0, 1), "->", text(size: 6.8pt)[固定 $pi$], label-side: right),
      edge((1, 0), (2, 1), "->", text(size: 6.8pt)[$max_pi arrow.r max_a$], label-side: left),
      edge((0, 1), (2, 1), "<->", stroke: (dash: "dashed", paint: muted, thickness: 0.6pt), text(size: 6.8pt)[$sum_a pi(a divides s) arrow.l.r max_a$], label-side: right),
      edge((0, 1), (0, 2), "->", stroke: 0.6pt + hl-blue-stroke),
      edge((2, 1), (2, 2), "->", stroke: 0.6pt + hl-amber-stroke),

      // 第 2 层：不动点迭代（显式展开式）
      node((1, 2), text(size: 7.6pt)[*方法一：不动点迭代*（6.2 节） \ $x_(k+1) = cal(T) x_k$ \ 模型已知 · 精确期望 · 自举], stroke: 0.9pt + accent, width: 40mm),
      node((0, 2), L[• *迭代策略评估* $V_(k+1) = cal(T)^pi_V V_k$ \ • *$Q$-策略评估* $Q_(k+1) = cal(T)^pi_Q Q_k$ \ • 交替贪心改进：*策略迭代*], stroke: 0.6pt + hl-blue-stroke, width: 52mm),
      node((2, 2), L[• *值迭代* $V_(k+1) = cal(T)^star_V V_k$ \ • *$Q$-值迭代* $Q_(k+1) = cal(T)^star_Q Q_k$ \ • 策略评估截断为一步即值迭代], stroke: 0.6pt + hl-amber-stroke, width: 52mm),
      edge((1, 2), (0, 2), "->", text(size: 6.5pt)[期望 \ 展开式], label-side: right),
      edge((1, 2), (2, 2), "->", text(size: 6.5pt)[最优 \ 展开式], label-side: left),

      // 第 3 层：蒙特卡洛（直接采样价值定义，不经贝尔曼方程）
      node((1, 3), text(size: 7.6pt)[*方法二：蒙特卡洛*（6.3 节） \ 样本均值 $hat(mu)_N$ · 完整回报 \ 直接采样价值定义 \ （不经贝尔曼方程，不自举）], stroke: 0.9pt + warn-stroke, width: 40mm),
      node((0, 3), L[• *首次 / 每次访问 MC*：$v_pi$、$q_pi$ \ • *离轨 MC*：OIS / WIS（$rho_(t+1:T-1) G_t$）], stroke: 0.6pt + hl-blue-stroke, width: 52mm),
      node((2, 3), L[• *MCES*：一般收敛性尚无完整证明 \ • *同轨 $epsilon$-软 MC 控制*：GLIE + RM \ #h(0.8em) 步长下 $Q arrow.r q_star$], stroke: 0.6pt + hl-amber-stroke, width: 52mm),
      edge((1, 3), (0, 3), "->", stroke: 0.7pt + warn-stroke, text(size: 6.5pt)[评估], label-side: right),
      edge((1, 3), (2, 3), "->", stroke: 0.7pt + warn-stroke, text(size: 6.5pt)[GPI \ 改进], label-side: left),

      // 第 4 层：随机近似 TD（条件期望式）
      node((1, 4), text(size: 7.6pt)[*方法三：随机近似*（6.5 节） \ $w arrow.l w + alpha_k (y_k - w)$ \ 模型未知 · 采样 + 自举], stroke: 0.9pt + hl-green-stroke, width: 40mm),
      node((0, 4), L[• *TD(0)、$n$ 步 TD、TD($lambda$)*：$v_pi$ \ • *SARSA*：评估 $q_pi$；GLIE + GPI 下 \ #h(0.8em) 同轨控制 $Q arrow.r q_star$ \ • *Expected SARSA*：对 $A_(t+1)$ 求期望], stroke: 0.6pt + hl-blue-stroke, width: 52mm),
      node((2, 4), L[• *Q-learning*：$Q$-值迭代的采样版 \ #h(0.8em) 离轨，所有 $(s, a)$ 无限次访问 \ • *Double Q-learning*：减小高估偏差], stroke: 0.6pt + hl-amber-stroke, width: 52mm),
      edge((1, 4), (0, 4), "->", stroke: 0.7pt + hl-green-stroke, text(size: 6.5pt)[期望 \ 条件式], label-side: right),
      edge((1, 4), (2, 4), "->", stroke: 0.7pt + hl-green-stroke, text(size: 6.5pt)[最优 \ 条件式], label-side: left),

      // 第 5 层：函数近似延伸
      node((0, 5), text(size: 7.6pt)[*函数近似 · Actor-Critic* \ Critic 以 TD / GAE 估计 $v_pi$ \ A2C / A3C / TRPO / PPO], fill: accent-soft, stroke: 0.6pt + accent, width: 52mm),
      node((1, 5), text(size: 6.8pt, fill: muted)[致命三元组：函数近似 \ + 自举 + 离轨训练 \ 可致发散（6.6 节）], stroke: none, width: 40mm),
      node((2, 5), text(size: 7.6pt)[*函数近似 · 价值式控制* \ DQN / Double / Dueling DQN：$q_star$ \ DDPG / TD3：$q_pi$ + Actor \ SAC：软 $q_pi$ + Actor], fill: accent-soft, stroke: 0.6pt + accent, width: 52mm),
      edge((0, 4), (0, 5), "->", stroke: (dash: "dashed", paint: accent, thickness: 0.7pt), text(size: 6.5pt)[参数化 + 半梯度], label-side: left),
      edge((2, 4), (2, 5), "->", stroke: (dash: "dashed", paint: accent, thickness: 0.7pt), text(size: 6.5pt)[参数化 + 半梯度], label-side: right),

      // 第 6 层：策略梯度范式（不解方程，直接对期望回报目标求导）
      node((1, 6), text(size: 7.6pt)[*策略梯度范式*（第 7 章）：*不解贝尔曼方程* \ 求解对象是 $max_bold(theta) J(bold(theta))$ 而非 $x = cal(T) x$ \ 贝尔曼方程仅作为优势定义与 Critic 的价值估计工具 \ 唯一显式结合特例：SAC 的软贝尔曼方程], fill: hl-amber-fill, stroke: 0.85pt + hl-amber-stroke, width: 66mm),
      edge((0, 5), (1, 6), "<->", stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.7pt), text(size: 6.5pt)[同一算法 \ 两种视角], label-side: left),
      edge((2, 5), (1, 6), "<->", stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.7pt), text(size: 6.5pt)[同一算法 \ 两种视角], label-side: right),
    )
  },
  caption: [强化学习算法关联谱系：左框为预测 / 评估类算法（对应贝尔曼期望方程），右框为控制类算法（对应贝尔曼最优方程或 GPI 外环）；中列三类期望估计方法分别作用于显式展开式（DP）、价值定义（MC，不经贝尔曼方程）与条件期望式（TD），最下行为函数近似延伸。右下节点按价值式控制谱系归类，DDPG / TD3 / SAC 的 Critic 求解的是（软）期望方程；最底行的策略梯度范式直接对期望回报目标求导，含 Actor 的算法（A2C / PPO / DDPG / TD3 / SAC）兼具两种视角],
) <fig-rl-genealogy>

策略梯度范式并未止步于 PPO：在大语言模型的可验证奖励强化学习（RLVR）训练中，该框架进一步演化出 GRPO、DAPO、GSPO 与 DCPO 四代代表性算法（#link(<sec-rlvr-lineage>)[第 7.10 节]）。这类算法完全移除了独立的 Critic 价值网络，以同提示组内相对回报充当状态基线，使贝尔曼自举方程不再进入梯度估计过程（见 @tab-pg-bellman-boundary 对应条目）。

图中未列出两类状态价值算法：纯 $V$ 的蒙特卡洛控制在无模型时无法选取贪心动作（见#link(<sec-mc-vq-comparison>)[第 6.3 节「状态价值与动作价值」小节]）；无模型最优控制通常不对 $v_star$ 做采样自举而直接估计 $q_star$，结构原因见 @eq-max-expectation-order 及其后说明。

#divider()

== 工程算法选型与非马尔可夫状态修复建议
<sec-engineering-guidelines>
在实际系统建模与强化学习工程实现中，应根据#strong[环境模型是否已知]、#strong[任务分幕特性与偏差-方差权衡]、#strong[状态-动作空间规模]及#strong[状态马尔可夫性假设是否成立]选择对应的方程形式与求解方案：

+ #strong[环境模型 $p(s', r divides s, a)$ 完全已知（规划与动态规划场景）]：
  - #strong[优先选用显式展开形式与 $v arrow.r v$ 不动点递推（#link(<thm-4.3>)[定理 4.3]、#link(<thm-5.7>)[定理 5.7]）]：当转移概率已知时，维护状态价值 $v(s)$ 仅需 $O(|cal(S)|)$ 存储空间，比维护 $q(s, a)$ 节省 $|cal(A)|$ 倍内存。在通过值迭代（@eq-value-iteration）或策略迭代求得最优状态价值 $v_star$ 后，仅需在在线决策时通过一次 $q_star arrow.r v_star$ 展开（#link(<thm-5.6>)[定理 5.6]）即可恢复最优贪心动作 $pi_star (s) in arg max_a [r(s, a) + gamma sum_(s') p(s' divides s, a) v_star (s')]$。
  - #strong[矩阵求逆解析解与不动点迭代的边界]：在固定策略评估中，当状态数 $|cal(S)| lt.tilde 10^3$ 时，可直接构造 @eq-matrix-bellman 的线性方程组 $(I - gamma P_pi) v_pi = r_pi$ 通过高斯消元或 LU 分解求精确解析解；当 $|cal(S)|$ 较大且转移矩阵 $P_pi$ 稀疏时，应采用基于贝尔曼期望算子 $cal(T)^pi_V$ 的迭代策略评估，将单轮开销降至与非零转移边数成正比。

+ #strong[环境模型未知、仅能通过交互采样获取轨迹（无模型强化学习场景）]：
  - #strong[蒙特卡洛（MC）与时序差分（TD）的权衡选型]：在无终止状态的持续性任务（$T = oo$）或幕长极长的任务中，必须采用基于自举的时序差分方法（TD / SARSA / Q-Learning）；在短幕长、奖励稀疏或状态表征存在轻微非马尔可夫性的分幕任务中，不依赖马尔可夫自举假设的蒙特卡洛回报（或高 $lambda$ 的 TD($lambda$) / GAE($lambda$)）能有效避免自举偏差的累积放大。
  - #strong[同轨控制与离轨控制的选用]：当允许使用经验回放池（Experience Replay）复用历史样本追求高样本效率时，可选用离轨价值式控制：Q-Learning / DQN 基于标准 $q_star arrow.r q_star$，DDPG / TD3 基于 $q_pi$ 的期望方程与确定性策略梯度，SAC 基于软贝尔曼期望方程与熵正则策略目标；当在线交互过程本身对探索期的安全性敏感（如机器人实机控制，需考虑 $epsilon$-贪心探索带来的真实风险）时，应选用忠实评估实际执行策略的同轨算法（SARSA / Expected SARSA / PPO）。
  - #strong[高维或连续空间的神经网络算子近似]：当 $|cal(S)|$ 或 $|cal(A)|$ 为高维或连续空间时，表格型存储与显式求和失效，需将 @eq-td-control 中的时序差分残差转化为均方误差损失函数（@eq-dqn-update，如 DQN），并在连续动作空间下配合参数化策略网络：DDPG / TD3 以确定性策略网络近似 $arg max_a Q(s, a)$，SAC 以随机策略最大化熵正则的软动作价值。

+ #strong[观测状态不满足马尔可夫性（非平稳或部分可观测场景）]：
  - #strong[排查并修复状态表示缺陷]：全文全部一步贝尔曼递推与 TD 自举均严格依赖#link(<lem-3>)[引理 3] 的条件独立化简 $p(g divides s', r, a, s) = p(g divides s')$（@eq-lem-3a）。若实际工程中的传感器观测 $O_t$ 丢失了关键历史信息（如仅输入单帧图像而无法判断运动速度，或奖励函数依赖历史累计状态），则 $G_(t + 1) cancel(perp) (S_t, A_t) divides S_(t + 1)$，直接套用一步贝尔曼方程会导致 TD 价值估计出现系统性偏差甚至震荡发散。此时必须在状态输入层拼接历史观测窗口（Frame Stacking）、引入循环/注意力状态编码器（RNN / Transformer）或显式增广历史统计量，使增广后的状态表征近似恢复马尔可夫性。
