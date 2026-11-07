// ============================================================
//  强化学习笔记：贝尔曼期望方程与贝尔曼最优方程的完整推导
// ============================================================
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/mannot:0.3.0": markhl

// ---------- 配色与字体 ----------
#let accent = rgb("#1f4e79")
#let accent-soft = accent.lighten(92%)
#let accent-mid = accent.lighten(75%)
#let muted = luma(120)

// 公式局部高亮配色
#let hl-amber-fill = rgb("#fff4d6")
#let hl-amber-stroke = rgb("#d9822b")
#let hl-blue-fill = rgb("#e6f0fa")
#let hl-blue-stroke = rgb("#2b6cb0")
#let hl-green-fill = rgb("#e6f6ec")
#let hl-green-stroke = rgb("#2f855a")
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
#text(font: sans-font, size: 16pt, weight: "bold", fill: accent.darken(25%))[目录]
#v(0.3em)
#outline(title: none, depth: 2, indent: 1.5em)

#pagebreak()

// ============================================================
//  导言
// ============================================================
本文档从概率论公理体系与有限马尔可夫决策过程（MDP）的基本定义出发，系统、严密地推导强化学习中的核心方程体系——#strong[贝尔曼期望方程]（Bellman Expectation Equation）与#strong[贝尔曼最优方程]（Bellman Optimality Equation）。

在强化学习经典文献（如 Sutton & Barto《强化学习：导论》）中，贝尔曼方程通常以两种等价的数学形式出现：一是以条件期望表征的#strong[紧凑形式]（基于全期望公式与塔性质），二是以状态转移概率与策略分布显式求和表征的#strong[展开形式]（基于全概率公式与链式法则）。本笔记严格区分并打通这两条推导路径，按“先单步桥接（$v arrow.r q$、$q arrow.r v$）、后复合自递推（$v arrow.r v$、$q arrow.r q$）”的统一逻辑组织方程推导（#link(<sec-mdp>)[第 1]--#link(<sec-bellman-opt>)[5 章]），核心对照见 @tab-overview；进而从#strong[期望值与不动点估计理论]出发，系统阐述基于压缩映射不动点迭代的动态规划（含值迭代）、基于大数定律的蒙特卡洛估计以及基于 Robbins-Monro 随机近似理论的时序差分（TD）估计方法，给出状态价值与动作价值估计算法结合贝尔曼期望/最优方程导出强化学习算法体系的关联谱系（#link(<sec-value-estimation>)[第 6]--#link(<sec-algo-selection>)[7 章]）。

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

- #strong[P8（条件期望的单调性）]：若随机变量满足 $X lt.eq Y$（对所有可能取值均成立），则因 $p(x, y divides z) gt.eq 0$ 且 $y - x gt.eq 0$，必有：
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
  & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] + gamma thin bb(E)_(S_(t + 1)) [bb(E)_(G_(t + 1)) [G_(t + 1) divides S_t = s, #mhlb($S_(t + 1)$)] thin divides thin S_t = s] \
  & = bb(E)_(R_(t + 1)) [R_(t + 1) divides S_t = s] + gamma thin bb(E)_(S_(t + 1)) [#mhlg($v_pi (S_(t + 1))$) divides S_t = s] \
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
  diagram(
    spacing: (19mm, 12mm),
    node-stroke: 0.9pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0, 0), [*状态价值* \ $v_pi (S_t)$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 25mm),
    node((1, 0), [*动作价值* \ $q_pi (S_t, A_t)$], fill: white, corner-radius: 4pt, inset: 6pt, width: 26mm),
    node((2, 0), [*后继状态价值* \ $v_pi (S_(t+1))$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 27mm),
    node((3, 0), [*后继动作价值* \ $q_pi (S_(t+1), A_(t+1))$], fill: white, corner-radius: 4pt, inset: 6pt, width: 31mm),
    edge((0, 0), (1, 0), "->", [定理 3.1 \ 策略层 $pi$], label-side: left),
    edge((1, 0), (2, 0), "->", [定理 3.2 \ 环境层 $p$], label-side: left),
    edge((2, 0), (3, 0), "->", [定理 3.1 \ 策略层 $pi$], label-side: left),
    edge((0, 0), (2, 0), "->", [定理 3.3（状态价值自递推 $v_pi arrow.r v_pi$：先策略层 $v_pi arrow.r q_pi$，再环境层 $q_pi arrow.r v_pi$）], bend: 32deg, label-side: left, stroke: (paint: accent, thickness: 0.8pt, dash: "dashed")),
    edge((1, 0), (3, 0), "->", [定理 3.4（动作价值自递推 $q_pi arrow.r q_pi$：先环境层 $q_pi arrow.r v_pi$，再策略层 $v_pi arrow.r q_pi$）], bend: -32deg, label-side: right, stroke: (paint: accent, thickness: 0.8pt, dash: "dashed")),
  ),
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
  #eqbox([$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) thin #mhlg($q_pi (s, a)$) quad "for all " s in cal(S) $])
$ <eq-exp-explicit-vq>

#strong[证明]：直接将#link(<thm-3.1>)[定理 3.1] 的期望式 $bb(E)_(A_t tilde.op pi(dot.op divides s)) [q_pi (s, A_t)]$ 按离散期望定义展开即得；若从回报分布 $p(g divides s)$ 出发，则只需引入动作变量 $a$ 应用条件全概率公式（@eq-p5-cond）：
$
  v_pi (s) & = sum_(g in Gamma) g thin p(g divides s) = sum_(g in Gamma) g sum_(a in cal(A)) #mhlb($p(g divides s, a) thin p(a divides s)$) \
  & = sum_(a in cal(A)) #mhl($pi(a divides s)$) underbrace(sum_(g in Gamma) g thin p(g divides s, a), = thin q_pi (s, a)) = sum_(a in cal(A)) #mhl($pi(a divides s)$) thin #mhlg($q_pi (s, a)$) . #h(2em) square.filled.medium
$

=== 动作价值到状态价值的展开（$q_pi arrow.r v_pi$）
#strong[定理 4.2（$q_pi$ 关于 $v_pi$ 的展开形式）] <thm-4.2> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，有：

$
  #eqbox([$ q_pi (s, a) = sum_(r in cal(R)) #mhl($p(r divides s, a) r$) + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$) quad "for all " (s, a) in cal(S) times cal(A) $])
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
  #eqbox([$ v_pi (s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$)] quad "for all " s in cal(S) $])
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
  #eqbox([$ q_pi (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) sum_(a' in cal(A)) #mhl($pi(a' divides s')$) #mhlg($q_pi (s', a')$) $])
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

$ #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) quad "for all " s in cal(S) $]) $ <eq-opt-cond-vq>

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
  #eqbox([$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [#mhl($R_(t + 1)$) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] quad "for all " (s, a) in cal(S) times cal(A) $])
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
  #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] quad "for all " s in cal(S) $])
$ <eq-opt-cond-vv>

#strong[证明]：将#link(<thm-5.2>)[定理 5.2]（@eq-opt-cond-qv）代入#link(<thm-5.1>)[定理 5.1]（@eq-opt-cond-vq）右端的 $q_star (s, a)$，立得 @eq-opt-cond-vv。$square.filled.medium$

=== 动作价值的自递推最优方程（$q_star arrow.r q_star$）
#strong[定理 5.4（动作价值的贝尔曼最优方程）] <thm-5.4> 对任意状态-动作对 $(s, a) in cal(S) times cal(A)$，最优动作价值函数满足：

$
  #eqbox([$ q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a] med "for all " (s, a) in cal(S) times cal(A) $])
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
  $ #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) quad "for all " s in cal(S) $]) $ <eq-opt-explicit-vq>

- #strong[定理 5.6（$q_star arrow.r v_star$ 的展开形式）] <thm-5.6>：由 $q_star (s, a) eq.dot max_pi q_pi (s, a)$ 与#link(<thm-4.2>)[定理 4.2]（@eq-exp-explicit-qv），因 $p(s' divides s, a) gt.eq 0$ 与策略无关，并借助#link(<fact-f2>)[事实 F2]（同一最优策略 $pi_star$ 在所有后继状态上同时最优），将 $max_pi$ 移入求和号内可得：
  $
    #eqbox([$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$) quad "for all " (s, a) in cal(S) times cal(A) $])
  $ <eq-opt-explicit-qv>

- #strong[定理 5.7（$v_star arrow.r v_star$ 的展开形式）] <thm-5.7>：将#link(<thm-5.6>)[定理 5.6]（@eq-opt-explicit-qv）代入#link(<thm-5.5>)[定理 5.5]（@eq-opt-explicit-vq），可得：
  $
    #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_star (s')$)] quad "for all " s in cal(S) $])
  $ <eq-opt-explicit-vv>

- #strong[定理 5.8（$q_star arrow.r q_star$ 的展开形式）] <thm-5.8>：在#link(<thm-5.6>)[定理 5.6] 右端代入 $v_star (s') = max_(a' in cal(A)) q_star (s', a')$，对任意 $(s, a) in cal(S) times cal(A)$ 可得：
  $
    #eqbox([$ q_star (s, a) = sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhl($max_(a' in cal(A))$) #mhlg($q_star (s', a')$) $])
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
  因 $P_pi$ 为行随机矩阵（谱半径 $rho(P_pi) = 1$），当 $gamma in [0, 1)$ 时，矩阵 $(I - gamma P_pi)$ 严格对角占优且满秩可逆，既可通过矩阵求逆直接解出解析解（时间复杂度 $O(|cal(S)|^3)$），也可通过不动点迭代求解。

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
= 期望值估计理论与状态/动作价值估计方法
<sec-value-estimation>

#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-opt>)[5 章]建立了状态价值（$v_pi, v_star$）与动作价值（$q_pi, q_star$）满足的八条贝尔曼方程。然而，无论在原始定义 $v_pi (s) = bb(E) [G_t divides S_t = s]$ 中，还是在单步递推的条件期望形式 $bb(E) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$ 中，核心运算均包含条件数学期望算子 $bb(E) [dot.op]$ 以及待求解的自指不动点结构。因此，从理论方程走向可计算的强化学习算法，取决于以下两个问题：
1. #strong[如何计算或估计条件期望 $bb(E) [X divides C]$]：当环境模型 $p(s', r divides s, a)$ 已知时，条件期望可通过显式概率加权求和精确计算；当环境模型未知（Model-Free）时，则必须从智能体与环境交互产生的随机轨迹样本中#strong[估计期望值]。
2. #strong[如何处理未来回报 $G_(t + 1)$ 的递推依赖]：是直接采样完整轨迹直到底层终止以观测真实回报 $G_t$（#strong[无自举]，No Bootstrapping），还是利用贝尔曼方程的一步递推关系，用当前对后继价值的估计量 $V(S_(t + 1))$ 或 $Q(S_(t + 1), dot.op)$ 替代真实未来回报期望（#strong[自举]，Bootstrapping）。

本章首先建立期望值与不动点估计的三类数学工具：压缩映射不动点迭代理论、大数定律与蒙特卡洛样本均值估计、Robbins-Monro 随机近似理论；随后列出这三类方法针对状态价值（$v_pi, v_star$）与动作价值（$q_pi, q_star$）的估计算法与推导。

#divider()

== 期望值估计与方程求解的三类数学工具
<sec-expectation-estimation-theory>

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

== 基于不动点理论的动态规划估计（模型已知：精确期望 + 自举）
<sec-dp-fixed-point>
当环境模型 $p(s', r divides s, a)$ 完全已知时，无需求助于轨迹采样，可直接利用#link(<sec-fixed-point-theory-detail>)[第 6.1 节]的压缩映射不动点理论，对#link(<sec-bellman-exp-explicit>)[第 4 章]与#link(<sec-opt-explicit>)[第 5.3 节]的#strong[显式展开形式贝尔曼方程]构造确定性不动点迭代算法。下面分别列出针对#strong[状态价值（$v_pi, v_star$）]与#strong[动作价值（$q_pi, q_star$）]的不动点估计算法。

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
   一旦 $Q_k$ 收敛于唯一不动点 $q_star$，提取最优策略无需再查询环境模型 $p(s', r divides s, a)$，只需直接做点态最大化 $pi_star (s) in arg max_(a in cal(A)) q_star (s, a)$。#link(<sec-td-action-value>)[第 6.4 节]的 Q-Learning 是 @eq-q-value-iteration 在模型未知时的随机近似版本。

#divider()

== 基于蒙特卡洛（Monte Carlo）方法的价值估计（模型未知：完整轨迹采样）
<sec-mc-estimation>
当环境模型 $p(s', r divides s, a)$ 未知时，无法执行#link(<sec-dp-fixed-point>)[第 6.2 节]中的显式概率求和 $sum_(s', r) p(s', r divides s, a) [dot.op]$。#strong[蒙特卡洛（Monte Carlo, MC）方法]绕开一步贝尔曼递推方程，直接回到#link(<sec-value-functions>)[第 1.3 节]中价值函数的#strong[原始期望定义]（#link(<def-1.2>)[定义 1.2] 与#link(<def-1.3>)[定义 1.3]）：
$
  v_pi (s) eq.dot bb(E)_pi [#mhlg($G_t$) divides S_t = s], #h(3em) q_pi (s, a) eq.dot bb(E)_pi [#mhlg($G_t$) divides S_t = s, A_t = a] .
$
在#strong[分幕式任务]（Episodic Tasks，每幕必在有限步 $T < oo$ 内到达终止状态）中，智能体遵循策略 $pi$ 与环境交互生成完整的一幕轨迹 $tau = (S_0, A_0, R_1, S_1, A_1, R_2, dots.h, S_(T - 1), A_(T - 1), R_T)$。从轨迹末端 $t = T - 1$ 向起点 $t = 0$ 逆向递推 $G_t = R_(t + 1) + gamma G_(t + 1)$（初值 $G_T = 0$），即可在 $O(T)$ 时间内精确算出该幕轨迹每个时刻 $t$ 的真实观测回报 $G_t$，再应用#link(<prop-6.2>)[命题 6.2] 的蒙特卡洛样本均值估计期望。

=== 状态价值的蒙特卡洛估计（首次访问型与每次访问型 MC 评估）
<sec-mc-state-value>
在同一幕轨迹 $tau$ 中，同一个状态 $s in cal(S)$ 可能在多个不同时间步被访问。根据对同一幕内重复访问样本的处理方式，状态价值的 MC 估计分为两类：

1. #strong[首次访问型蒙特卡洛估计（First-Visit MC Prediction）]：
   在每一幕轨迹中，仅记录状态 $s$ #strong[第一次出现]的时刻 $t_1 (s) = min {t gt.eq 0 : S_t = s}$ 所对应的折扣回报 $G_(t_1 (s))$，忽略该幕后续对 $s$ 的重复访问。以下按访问幕依次到达的流式协议理解：设在 $M$ 幕交互中共有 $N(s)$ 幕访问过状态 $s$，记第 $i$ 个访问 $s$ 的幕中的首次访问回报为 $G_s^((i))$，则状态价值估计量为：
   $
     #eqbox([$ hat(V)_pi^upright("FV") (s) eq.dot #mhl($frac(1, N(s)) sum_(i = 1)^(N(s))$) #mhlg($G_s^((i))$), #h(2em) upright("增量更新：") quad V(s) arrow.l V(s) + #mhl($frac(1, N(s))$) [#mhlg($G_(t_1 (s))$) - V(s)] $])
   $ <eq-mc-first-visit-v>
   #strong[理论性质]：不同幕的轨迹相互独立，且每个首次访问回报满足 $bb(E)[G_(t_1 (s)) divides S_(t_1 (s)) = s] = v_pi (s)$。由于 $N(s)$ 本身是随机变量，且与回报来自同一批轨迹，无偏性与方差须在给定样本量的条件下陈述：给定 $N(s) = n$ 后，这 $n$ 个回报条件独立同分布，由#link(<prop-6.2>)[命题 6.2] 得
   $
     bb(E)[hat(V)_pi^upright("FV") (s) divides N(s) = n] = v_pi (s), #h(2em) upright("Var")(hat(V)_pi^upright("FV") (s) divides N(s) = n) = upright("Var")(G_(t_1 (s)) divides N(s) = n) / n .
   $
   若采用“持续采样直到获得 $n$ 个访问 $s$ 的幕”的固定样本量协议，则无条件地有 $bb(E)[hat(V)_pi^upright("FV") (s)] = v_pi (s)$ 与方差 $upright("Var")(G_(t_1 (s))) \/ n$；若固定总幕数 $M$ 而令 $N(s)$ 随机，则只能使用上述条件结论。若 $s$ 以概率 $1$ 被无限次访问，则 $N(s) arrow.r oo$，估计量由强大数定律以概率 $1$ 收敛于 $v_pi (s)$。

2. #strong[每次访问型蒙特卡洛估计（Every-Visit MC Prediction）]：
   将所有幕中访问状态 $s$ 的#strong[全部时间步]对应的回报均纳入样本均值计算（每访问一次计数器 $N(s) arrow.l N(s) + 1$，并按 $V(S_t) arrow.l V(S_t) + frac(1, N(S_t)) [G_t - V(S_t)]$ 或常步长 $alpha$ 更新）。由于同一幕内先后两次访问 $s$ 的回报共享后续轨迹奖励，样本之间相关，每次访问估计量在有限样本下有偏；当 $N(s) arrow.r oo$ 时偏差趋于零，估计量同样以概率 $1$ 收敛于 $v_pi (s)$。Singh & Sutton (1996) 指出，样本较少时每次访问估计的均方误差常低于首次访问估计。

3. #strong[关键局限：为何无模型控制不能仅估计状态价值 $V(s)$？]
   在环境模型 $p(s', r divides s, a)$ 已知时，拥有状态价值 $v_pi (s)$ 即可通过 @eq-policy-improvement 的单步向前看（One-step Lookahead）选出贪心动作；但在#strong[无模型设定]下，因 $p(s', r divides s, a)$ 未知，即使精确估出 $V(s) = v_pi (s)$，智能体也无法计算 $arg max_a bb(E)[R_(t + 1) + gamma V(S_(t + 1)) divides S_t = s, A_t = a]$。因此，无模型策略控制#strong[必须直接估计动作价值 $Q(s, a)$]，从而免模型地通过 $arg max_a Q(s, a)$ 直接选取最优动作。

=== 动作价值的蒙特卡洛估计与策略控制（MCES、$epsilon$-贪心与重要性采样）
<sec-mc-action-value>
1. #strong[动作价值的蒙特卡洛增量估计（估计 $q_pi (s, a)$）]：
   将统计对象从状态 $s$ 细化为状态-动作对 $(s, a) in cal(S) times cal(A)$。当轨迹在时刻 $t$ 经历 $(S_t = s, A_t = a)$（首次访问或每次访问）并观测到完整回报 $G_t$ 时，计数器 $N(s, a) arrow.l N(s, a) + 1$，更新公式为（在策略控制中常取衰减步长 $alpha_k = 1 \/ N(s, a)$ 或常步长 $alpha$）：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [#mhlg($G_t$) - Q(S_t, A_t)] $])
   $ <eq-mc-q-update>

2. #strong[探索性困境与同轨策略蒙特卡洛控制（MCES 与 On-Policy $epsilon$-Greedy MC Control）]：
   若策略 $pi$ 是确定性策略，则在状态 $s$ 下智能体永远只会执行单一动作 $a = pi(s)$，其余动作 $a' eq.not pi(s)$ 永远无法被采样，$Q(s, a')$ 的估计将停滞在初值。为保证所有状态-动作对 $(s, a)$ 均被无限次访问（持续探索，Continual Exploration），有两类经典解法：
   - #strong[探索性出发蒙特卡洛（MC with Exploring Starts, MCES）]：假设每一幕的初始状态-动作对 $(S_0, A_0)$ 在 $cal(S) times cal(A)$ 上的每个取值均以正概率被选中，此后遵循确定性贪心策略 $pi(s) in arg max_a Q(s, a)$，每幕结束后按 @eq-mc-q-update 更新 $Q$ 并重新贪心化。MCES 收敛到 $q_star$ 在一般情形下尚无完整证明（Sutton & Barto 第 2 版第 5.3 节将其列为开放问题）。
   - #strong[同轨策略 $epsilon$-贪心蒙特卡洛控制（On-Policy $epsilon$-Greedy MC Control）]：取消不切实际的探索性出发假设，令策略 $pi$ 为软性（$epsilon$-soft）策略：以 $1 - epsilon$ 概率选择当前贪心动作 $a^star = arg max_(a') Q(s, a')$，以 $epsilon$ 概率在全部 $|cal(A)|$ 个动作中均匀随机探索：
     $
       pi(a divides s) = cases(
         1 - epsilon + frac(epsilon, |cal(A)|) \, & upright("若 ") a = arg max_(a' in cal(A)) Q(s, a') \,,
         frac(epsilon, |cal(A)|) \, & upright("若 ") a eq.not arg max_(a' in cal(A)) Q(s, a') .
       )
     $ <eq-epsilon-greedy-policy>
     对任意 $epsilon$-软策略 $pi$，关于 $q_pi$ 的 $epsilon$-贪心策略 $pi'$ 满足 $v_(pi') (s) gt.eq v_pi (s)$（策略改进定理在 $epsilon$-软策略类中的推广，Sutton & Barto 第 5.4 节），固定 $epsilon$ 时的极限是 $epsilon$-软策略类中的最优策略，而非 $pi_star$。若探索率按#strong[无限探索且渐近贪心（GLIE，Greedy in the Limit with Infinite Exploration，如 $epsilon_k = 1 \/ k$）]条件衰减，且所有 $(s, a)$ 被无限次访问、按各 $(s, a)$ 访问次数定义的步长 $alpha_k (s, a)$ 满足 Robbins-Monro 条件（@eq-rm-step-conditions），则同轨表格型 $epsilon$-软 MC 控制的 $Q$ 以概率 $1$ 收敛于 $q_star$；@eq-mc-q-update 取常步长 $alpha$ 时不满足 $sum alpha_k^2 < oo$，不在此结论之内。

3. #strong[离轨策略蒙特卡洛估计与重要性采样（Off-Policy MC via Importance Sampling）]：
   若用具有充分探索性的#strong[行为策略（Behavior Policy）] $b(a divides s)$ 与环境交互生成轨迹，同时希望评估或优化另一个#strong[目标策略（Target Policy）] $pi(a divides s)$（满足覆盖假设：凡 $pi(a divides s) > 0$ 必有 $b(a divides s) > 0$），则直接对 $b$ 采样的回报 $G_t$ 求平均会得到 $q_b (s, a)$ 而非 $q_pi (s, a)$。
   根据链式法则，给定 $S_t, A_t$ 后后续轨迹 $tau_(t + 1 : T) = (S_(t + 1), A_(t + 1), dots.h, S_T)$ 在目标策略 $pi$ 与行为策略 $b$ 下的条件概率之比中，#strong[未知的环境转移概率 $p(S_(k + 1), R_(k + 1) divides S_k, A_k)$ 在分子分母中完全约消]，从而得到完全不依赖环境模型的#strong[重要性采样比（Importance Sampling Ratio）]：
   $
     rho_(t + 1 : T - 1) eq.dot frac(product_(k = t + 1)^(T - 1) pi(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k)), product_(k = t + 1)^(T - 1) b(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k))) = #mhl($product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$) .
   $ <eq-importance-sampling-ratio>
   利用修正后的无偏回报样本 $rho_(t + 1 : T - 1) G_t$（满足 $bb(E)_b [rho_(t + 1 : T - 1) G_t divides S_t = s, A_t = a] = q_pi (s, a)$），可构造#strong[普通重要性采样（Ordinary IS，无偏但方差可能无界）]与#strong[加权重要性采样（Weighted IS，有偏但偏差随样本数增加趋于零；回报有界时方差有界）]两类动作价值估计量：
   $
     hat(Q)_pi^upright("OIS") (s, a) = frac(1, N(s, a)) sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), #h(2.5em) hat(Q)_pi^upright("WIS") (s, a) = frac(sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$)) .
   $ <eq-mc-ois-wis>

#divider()

== 基于随机近似的时序差分（TD）估计（模型未知：采样 + 自举）
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

=== 动作价值的时序差分估计与控制
<sec-td-action-value>
将 Robbins-Monro 随机近似应用于#link(<thm-3.4>)[定理 3.4]（$q_pi arrow.r q_pi$ 贝尔曼期望方程）与#link(<thm-5.4>)[定理 5.4]（$q_star arrow.r q_star$ 贝尔曼最优方程）的条件期望形式，可导出无模型动作价值估计与控制的主要算法：

1. #strong[SARSA 算法（同轨策略 On-Policy TD 控制，对应 $q_pi arrow.r q_pi$ 全采样随机近似）]：
   由#link(<thm-3.4>)[定理 3.4] 的动作价值贝尔曼期望方程（条件期望形式 @eq-bellman-exp-qq）：
   $
     q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1), A_(t + 1)) [R_(t + 1) + gamma #mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] .
   $
   智能体从 $(S_t, A_t)$ 出发，与环境交互获得 $(R_(t + 1), S_(t + 1))$，并继续按当前策略 $pi$（如 $epsilon$-贪心策略）采样出下一时刻的实际执行动作 $A_(t + 1) tilde.op pi(dot.op divides S_(t + 1))$，组成五元组 $(S_t, A_t, R_(t + 1), S_(t + 1), A_(t + 1))$（SARSA 之名由此而来）。以单样本 $R_(t + 1) + gamma Q(S_(t + 1), A_(t + 1))$ 近似上述三变量联合条件期望，做 Robbins-Monro 更新：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma #mhlg($Q(S_(t + 1), A_(t + 1))$) - Q(S_t, A_t)] $])
   $ <eq-sarsa-update>
   SARSA 评估的是正在执行的策略；将其与 $epsilon$-贪心改进交替执行即为同轨控制。表格型 SARSA 收敛于 $q_star$ 的条件为：所有 $(s, a)$ 被无限次访问、各 $(s, a)$ 的步长满足 @eq-rm-step-conditions，且策略满足 GLIE 条件（Singh et al., 2000）。

2. #strong[期望 SARSA 算法（Expected SARSA，对应 $q_pi arrow.r q_pi$ 环境层采样 + 策略层精确期望）]：
   回顾#link(<sec-cond-qq>)[第 3.4 节]对 @eq-bellman-exp-qq 的嵌套期望分解：$q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma bb(E)_(A_(t + 1) tilde.op pi) [q_pi (S_(t + 1), A_(t + 1))] divides S_t = s, A_t = a]$。虽然环境转移分布 $p(s', r divides s, a)$ 未知（必须通过采样 $(R_(t + 1), S_(t + 1))$ 做随机近似），但#strong[智能体自身的策略分布 $pi(a' divides S_(t + 1))$ 已知]。因此，无需像 SARSA 那样对下一动作 $A_(t + 1)$ 进行随机采样，而是直接对后继动作求精确期望：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma sum_(a' in cal(A)) #mhl($pi(a' divides S_(t + 1))$) #mhlg($Q(S_(t + 1), a')$) - Q(S_t, A_t)] $])
   $ <eq-expected-sarsa-update>
   #strong[优势]：Expected SARSA 消除了因随机采样 $A_(t + 1)$ 引入的策略层方差，在相同步长下比标准 SARSA 具有更低的估计方差与更高的稳定性，且既可作同轨评估/控制，也可自然用作离轨评估（令 $b$ 生成样本，目标策略 $pi$ 代入求和）。

3. #strong[Q-Learning 算法（离轨策略 Off-Policy TD 控制，对应贝尔曼最优方程 $q_star arrow.r q_star$ 随机近似）]：
   Watkins (1989) 提出的 Q-Learning 不再经过“评估 $q_pi$ 再改进 $pi$”的两步过程，而是直接对#link(<thm-5.4>)[定理 5.4] 的#strong[动作价值贝尔曼最优方程]（条件期望形式 @eq-opt-cond-qq）：
   $
     q_star (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a]
   $
   应用 Robbins-Monro 随机近似：智能体按行为策略 $b$（如 $epsilon$-贪心）采样四元组 $(S_t, A_t, R_(t + 1), S_(t + 1))$，直接将后继状态的最大动作价值 $max_(a') Q(S_(t + 1), a')$ 作为自举目标：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($Q(S_(t + 1), a')$) - Q(S_t, A_t)] $])
   $ <eq-td-control>
   #strong[$max$ 与 $bb(E)$ 的内外顺序及离轨性]：对比状态价值与动作价值贝尔曼最优方程（#link(<thm-5.3>)[定理 5.3]，@eq-opt-cond-vv；#link(<thm-5.4>)[定理 5.4]，@eq-opt-cond-qq）中最大化算子与条件期望算子的位置：
   $
     v_star (s) & = #mhl($max_(a in cal(A))$) #mhlb($bb(E)_(R_(t + 1), S_(t + 1))$) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a], \
     q_star (s, a) & = #mhlb($bb(E)_(R_(t + 1), S_(t + 1))$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) divides S_t = s, A_t = a] .
   $ <eq-max-expectation-order>
   - 在 $v_star$ 的方程中 $max_a$ 位于条件期望之外。朴素地复用同一条单步样本为各动作估值再取 $max_a$ 会引入最大化选择偏差，不能作为 $max_a bb(E)[dot.op]$ 的无偏插件；此外，即使已知 $v_star$，从 $v_star$ 选取贪心动作仍需一步模型或额外的环境信息。常规无模型最优控制因此直接估计 $q_star$。
   - 在 $q_star$ 的方程中条件期望位于最外层，对给定的采样后继状态 $S_(t + 1) = s'$，$max_(a') Q(s', a')$ 只是查表求最大值。给定 $(S_t = s, A_t = a)$ 后，$(R_(t + 1), S_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 只由环境转移律决定，与生成轨迹的行为策略 $b$ 无关，后继动作也无需按目标策略采样，因此 Q-Learning 无需重要性采样即可离轨学习。
   在有限 MDP、奖励有界、行为策略 $b$ 使所有 $(s, a)$ 被无限次访问，且按各 $(s, a)$ 访问次数定义的步长满足 Robbins-Monro 条件时，表格型 $Q(s, a)$ 以概率 $1$ 收敛于 $q_star (s, a)$（Watkins & Dayan, 1992），对行为策略 $b$ 无 GLIE 要求。

4. #strong[最大化偏差（Maximization Bias）与 Double Q-Learning]：
   在 Q-Learning（@eq-td-control）中，目标项使用带有随机估计误差的同一个价值表 $Q$ 同时完成#strong[选出最大动作]（$a^star = arg max_(a') Q(S_(t + 1), a')$）与#strong[评估该动作的价值]（$Q(S_(t + 1), a^star) = max_(a') Q(S_(t + 1), a')$）。由于 $max$ 是凸函数，即便每个动作的价值估计 $hat(Q)(s', a')$ 都是真值 $q_star (s', a')$ 的无偏估计（$bb(E)[hat(Q)(s', a')] = q_star (s', a')$），由 #strong[Jensen 不等式]必有：
   $
     #mhl($bb(E) [max_(a' in cal(A)) hat(Q)(s', a')]$) gt.eq #mhlb($max_(a' in cal(A)) bb(E) [hat(Q)(s', a')]$) = max_(a' in cal(A)) q_star (s', a') ,
   $ <eq-maximization-bias>
   即“#strong[最大值的期望大于期望的最大值]”，导致 Q-Learning 系统性地高估（Overestimate）动作价值。#strong[Double Q-Learning]（Hasselt, 2010）通过维护两份交替更新的估计器 $Q_1, Q_2$ 解耦动作选择与价值评估（每步以 $0.5$ 概率随机更新其中一个，如用 $Q_1$ 选出贪心动作 $a^star = arg max_(a') Q_1(S_(t + 1), a')$，再用另一份 $Q_2$ 评估其价值）：
   $
     Q_1 (S_t, A_t) arrow.l Q_1 (S_t, A_t) + alpha [R_(t + 1) + gamma #mhlg($Q_2 (S_(t + 1), #mhl($arg max_(a') Q_1 (S_(t + 1), a')$))$) - Q_1 (S_t, A_t)] ,
   $ <eq-double-q-learning>
   另一半步骤交换 $Q_1, Q_2$ 的角色。若 $Q_2$ 无偏且其评估误差与 $Q_1$ 的选择误差条件独立，则 $bb(E)[Q_2 (s', a^star)] = q_star (s', a^star) lt.eq max_(a') q_star (s', a')$，目标项不再系统性高估（可能出现轻微低估）。Double DQN 与 TD3 的 Clipped Double-Q 采用同一思路。

5. #strong[从表格型随机近似到参数化函数近似（DQN 与随机梯度下降）]：
   当状态空间 $cal(S)$ 为高维或连续空间时，用参数化函数 $hat(v)(s; bold(theta))$ 或 $hat(q)(s, a; bold(theta))$（如深度神经网络）近似价值函数。此时对均方 TD 误差 $cal(L)(bold(theta)) = 1 / 2 [y_t^upright("TD") - hat(q)(S_t, A_t; bold(theta))]^2$（将目标网络参数 $bold(theta)^-$ 视为固定常数，即半梯度 Semi-gradient）做随机梯度下降，即为 #strong[DQN（Deep Q-Network）] 的参数更新律：
   $
     bold(theta)_(t + 1) = bold(theta)_t + #mhl($alpha$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($hat(q)(S_(t + 1), a'; bold(theta)^-)$) - hat(q)(S_t, A_t; bold(theta)_t)] #mhlb($nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)_t)$) .
   $ <eq-dqn-update>
   当取表格型独热特征表示（One-Hot Feature）时，$nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)) = bold(e)_((S_t, A_t))$，@eq-dqn-update 精确退化为表格型 Q-Learning（@eq-td-control）。DQN 另以经验回放（Experience Replay）打破样本相关性，并周期性复制 $bold(theta)^- arrow.l bold(theta)$。

   #strong[函数近似下的收敛边界]：上述 TD(0)、SARSA、Q-Learning 的以概率 $1$ 收敛结论均限于表格型表示。参数化以后，半梯度更新不再是任何固定目标函数的梯度下降。已知结论为：同轨线性 TD(0) 收敛到 TD 不动点，其误差不超过最优线性逼近误差的 $1 \/ (1 - gamma)$ 倍（Tsitsiklis & Van Roy, 1997）；函数近似、自举与离轨训练三者同时出现（#strong[致命三元组]，Deadly Triad）时，即使线性特征也可能发散（Baird 反例，1995）。DQN 等深度方法因此没有一般性收敛保证，稳定性依赖目标网络、经验回放等工程措施。

#divider()

== 三类估计方法的回溯结构对比
<sec-estimation-comparison>
综合#link(<sec-dp-fixed-point>)[第 6.2]--#link(<sec-td-estimation>)[6.4 节]，动态规划（DP）、蒙特卡洛（MC）与时序差分（TD）是强化学习价值估计的三类基本方法。三者在马尔可夫决策树上的回溯广度（Width）与深度（Depth）不同（见 @fig-dp-mc-td-backups），针对状态价值与动作价值的全部估计算法及统计特征汇总于 @tab-all-value-estimators。

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

#divider()

// ============================================================
//  第 7 章：方程结构定性、强化学习算法关联谱系与工程选型
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
将贝尔曼期望方程与贝尔曼最优方程、状态价值 $V$ 与动作价值 $Q$ 两类对象，以及#link(<sec-value-estimation>)[第 6 章]的三类期望估计方法（不动点迭代、蒙特卡洛样本均值、Robbins-Monro 随机近似）组合，再配合广义策略迭代（Generalized Policy Iteration, GPI）与参数化函数近似，可得到从表格型方法到深度强化学习（Deep RL）的主要算法。各估计方法结合贝尔曼期望 / 最优方程导出的状态价值与动作价值算法见 @fig-rl-genealogy，对应的更新公式见 @tab-all-value-estimators。

#figure(
  {
    set par(justify: false)
    let L(body) = align(left, text(size: 7.6pt, body))
    diagram(
      spacing: (11mm, 6mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,

      // 列分组：只圈算法行，方程节点在框外
      node(enclose: ((0, 2), (0, 4)), stroke: (dash: "dashed", paint: hl-blue-stroke, thickness: 0.6pt), fill: none, inset: 4pt, snap: false),
      node(enclose: ((2, 2), (2, 4)), stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.6pt), fill: none, inset: 4pt, snap: false),

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
      node((1, 4), text(size: 7.6pt)[*方法三：随机近似*（6.4 节） \ $w arrow.l w + alpha_k (y_k - w)$ \ 模型未知 · 采样 + 自举], stroke: 0.9pt + hl-green-stroke, width: 40mm),
      node((0, 4), L[• *TD(0)、$n$ 步 TD、TD($lambda$)*：$v_pi$ \ • *SARSA*：评估 $q_pi$；GLIE + GPI 下 \ #h(0.8em) 同轨控制 $Q arrow.r q_star$ \ • *Expected SARSA*：对 $A_(t+1)$ 求期望], stroke: 0.6pt + hl-blue-stroke, width: 52mm),
      node((2, 4), L[• *Q-learning*：$Q$-值迭代的采样版 \ #h(0.8em) 离轨，所有 $(s, a)$ 无限次访问 \ • *Double Q-learning*：减小高估偏差], stroke: 0.6pt + hl-amber-stroke, width: 52mm),
      edge((1, 4), (0, 4), "->", stroke: 0.7pt + hl-green-stroke, text(size: 6.5pt)[期望 \ 条件式], label-side: right),
      edge((1, 4), (2, 4), "->", stroke: 0.7pt + hl-green-stroke, text(size: 6.5pt)[最优 \ 条件式], label-side: left),

      // 第 5 层：函数近似延伸
      node((0, 5), text(size: 7.6pt)[*函数近似 · Actor-Critic* \ Critic 以 TD / GAE 估计 $v_pi$ \ A2C / A3C / TRPO / PPO], fill: accent-soft, stroke: 0.6pt + accent, width: 52mm),
      node((1, 5), text(size: 6.8pt, fill: muted)[致命三元组：函数近似 \ + 自举 + 离轨训练 \ 可致发散（6.4 节）], stroke: none, width: 40mm),
      node((2, 5), text(size: 7.6pt)[*函数近似 · 价值式控制* \ DQN / Double / Dueling DQN：$q_star$ \ DDPG / TD3：$q_pi$ + Actor \ SAC：软 $q_pi$ + Actor], fill: accent-soft, stroke: 0.6pt + accent, width: 52mm),
      edge((0, 4), (0, 5), "->", stroke: (dash: "dashed", paint: accent, thickness: 0.7pt), text(size: 6.5pt)[参数化 + 半梯度], label-side: left),
      edge((2, 4), (2, 5), "->", stroke: (dash: "dashed", paint: accent, thickness: 0.7pt), text(size: 6.5pt)[参数化 + 半梯度], label-side: right),
    )
  },
  caption: [强化学习算法关联谱系：左框为预测 / 评估类算法（对应贝尔曼期望方程），右框为控制类算法（对应贝尔曼最优方程或 GPI 外环）；中列三类期望估计方法分别作用于显式展开式（DP）、价值定义（MC，不经贝尔曼方程）与条件期望式（TD），最下行为函数近似延伸。右下节点按价值式控制谱系归类，DDPG / TD3 / SAC 的 Critic 求解的是（软）期望方程],
) <fig-rl-genealogy>

图中未列出两类状态价值算法：纯 $V$ 的蒙特卡洛控制在无模型时无法选取贪心动作（#link(<sec-mc-state-value>)[第 6.3.1 节]第 3 项）；无模型最优控制通常不对 $v_star$ 做采样自举而直接估计 $q_star$，结构原因见 @eq-max-expectation-order 及其后说明。

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
