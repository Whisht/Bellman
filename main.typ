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

在强化学习经典文献（如 Sutton & Barto《强化学习：导论》）中，贝尔曼方程通常以两种等价的数学形式出现：一是以条件期望表征的#strong[紧凑形式]（基于全期望公式与塔性质），二是以状态转移概率与策略分布显式求和表征的#strong[展开形式]（基于全概率公式与链式法则）。本笔记严格区分并打通这两条推导路径，按“先单步桥接（$v arrow.r q$、$q arrow.r v$）、后复合自递推（$v arrow.r v$、$q arrow.r q$）”的统一逻辑组织方程推导（#link(<sec-mdp>)[第 1]--#link(<sec-bellman-opt>)[5 章]），核心对照见 @tab-overview；进而从#strong[期望值与不动点估计理论]出发，系统阐述基于压缩映射不动点迭代的动态规划（含值迭代）、基于大数定律的蒙特卡洛估计以及基于 Robbins-Monro 随机近似理论的时序差分（TD）估计方法，给出状态价值与动作价值估计算法结合贝尔曼期望/最优方程导出强化学习算法体系的关联谱系（#link(<sec-value-estimation>)[第 6 章]）；再转向一条不以贝尔曼方程为求解对象的路线——把策略参数化，直接对期望回报目标求梯度，并说明这条路线在何处仍借道贝尔曼方程、何处是例外（#link(<sec-policy-gradient>)[第 7]--#link(<sec-algo-selection>)[8 章]）。

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
= 期望值估计：从方程到算法
<sec-value-estimation>

#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-opt>)[5 章]建立了状态价值（$v_pi, v_star$）与动作价值（$q_pi, q_star$）满足的八条贝尔曼方程，它们是全文的核心。八条方程形态各异，却可以写成同一个#strong[自指不动点方程]：方程右端的算子 $cal(T)$ 作用在未知函数上，而左端正是这个未知函数本身。求解贝尔曼方程，就是求算子 $cal(T)$ 的不动点：
$
  x = cal(T) x, #h(2em) x in {v_pi, q_pi, v_star, q_star}, #h(1em) cal(T) thin "为对应的贝尔曼算子" .
$ <eq-ch6-fixed-point-shell>

求解算法因此有一个统一的骨架：#strong[不动点迭代] $x_(k + 1) = cal(T) x_k$——用当前估计算出下一个估计，反复执行。从这个骨架出发，本章的全部算法都可以看作对同一个问题的三种回答：#strong[每一步的 $cal(T) x_k$ 究竟怎么算出来？] 把 $cal(T)$ 展开后，它的核心是一个条件数学期望 $bb(E) [dot.op divides dot.op]$：在价值函数的原始定义中它是 $bb(E) [G_t divides S_t = s]$，在单步递推的条件期望形式中它是 $bb(E) [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$。因此从理论方程走向可计算算法，取决于以下两个问题：
1. #strong[如何计算或估计条件期望 $bb(E) [X divides C]$]：当环境模型 $p(s', r divides s, a)$ 已知时，条件期望可通过显式概率加权求和精确计算；当环境模型未知（Model-Free）时，则必须从智能体与环境交互产生的随机轨迹样本中#strong[估计期望值]。
2. #strong[如何处理未来回报 $G_(t + 1)$ 的递推依赖]：是直接采样完整轨迹直到底层终止以观测真实回报 $G_t$（#strong[无自举]，No Bootstrapping），还是利用贝尔曼方程的一步递推关系，用当前对后继价值的估计量 $V(S_(t + 1))$ 或 $Q(S_(t + 1), dot.op)$ 替代真实未来回报期望（#strong[自举]，Bootstrapping）。

对这两个问题的不同回答，把本章分成三条路线。前两条路线的回答是"是"与"否"，第三条路线则是"既要采样、又要自举"。三条路线各自又会暴露新的问题，解决这些新问题的办法，就是本章后三节的三块#strong[补丁]。骨架决定方法与方法的相似，补丁决定方法与方法的差异——这条脉络见 @fig-estimation-routes。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (6mm, 7mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,
      node((1, 0), text(size: 7.8pt)[*统一骨架：不动点迭代* \ $x_(k+1) = cal(T) x_k$ \ 每一步都要算出 $cal(T) x_k$，而它内含条件期望 $bb(E)[dot.op divides dot.op]$], fill: accent-soft, width: 62mm),
      node((0, 1), text(size: 7.6pt)[*路线一：精确求期望* \ （6.2 节）目标 $= cal(T) x_k$ 直接算出 \ 需环境模型 $p(s', r divides s, a)$ \ 不动点迭代（DP）], stroke: 0.85pt + hl-blue-stroke, fill: hl-blue-fill, width: 44mm),
      node((1, 1), text(size: 7.6pt)[*路线二：采完整回报* \ （6.3 节）目标 $= G_t$，采样至终止 \ 绕开贝尔曼方程，回到价值定义 \ 蒙特卡洛（MC）], stroke: 0.85pt + warn-stroke, fill: warn-soft, width: 44mm),
      node((2, 1), text(size: 7.6pt)[*路线三：采样 + 自举* \ （6.5 节）目标 $= R_(t+1) + gamma V(S_(t+1))$ \ 免模型，用当前估计替代未来 \ 时序差分（TD）], stroke: 0.85pt + hl-green-stroke, fill: hl-green-fill, width: 44mm),
      node((1, 2), text(size: 7.4pt)[*三块补丁*：三条路线各自暴露的新问题 \ 6.4 重要性采样 · 6.6 动作价值与控制 · 6.7 离轨多步方差控制], stroke: (dash: "dashed", paint: muted, thickness: 0.6pt), width: 62mm),
      edge((1, 0), (0, 1), "->", text(size: 6.8pt)[模型已知], label-side: right),
      edge((1, 0), (1, 1), "->", text(size: 6.8pt)[模型未知 \ 不自举], label-side: right),
      edge((1, 0), (2, 1), "->", text(size: 6.8pt)[模型未知 \ 自举], label-side: left),
      edge((1, 1), (1, 2), "->", stroke: (dash: "dashed", paint: muted, thickness: 0.6pt)),
    )
  },
  caption: [本章的生成脉络：贝尔曼方程给出统一的不动点骨架，骨架每一步内含的条件期望在模型已知时精确可算（DP）、在模型未知时只能估计——采完整回报得到 MC（绕开贝尔曼方程），采样一步再自举得到 TD；三条路线各自暴露的新问题由后续三节补丁解决],
) <fig-estimation-routes>

本章先建立这一统一视角所依赖的三类数学工具（#link(<sec-expectation-estimation-theory>)[第 6.1 节]）；随后依次给出三条路线：模型已知的精确期望与不动点迭代（#link(<sec-dp-fixed-point>)[第 6.2 节]）、模型未知的完整回报采样（#link(<sec-mc-estimation>)[第 6.3 节]）、模型未知的采样加自举（#link(<sec-td-estimation>)[第 6.5 节]）；并逐一交代三处补丁：离轨评估与重要性采样（#link(<sec-importance-sampling>)[第 6.4 节]）、动作价值与控制算法族（#link(<sec-td-action-value>)[第 6.6 节]）、离轨多步的方差控制（#link(<sec-offpolicy-multistep>)[第 6.7 节]）；最后横向对比三者的统计特征与回溯结构（#link(<sec-estimation-comparison>)[第 6.8 节]）。

#divider()

== 期望值估计的统一视角与三类数学工具
<sec-expectation-estimation-theory>

@fig-estimation-routes 的三条路线共用同一个更新式。把它写出来，后面所有算法的差别就只剩三个位置上的取值不同——这与#link(<sec-robbins-monro-theory>)[第 6.1.3 节]的 Robbins-Monro 迭代式（@eq-robbins-monro-update）以及蒙特卡洛的增量均值公式（@eq-incremental-mean）是同一个式子：
$
  #eqbox([$ x arrow.l x + #mhl($alpha_k$) [#mhlg($y_k$) - x] $])
$ <eq-ch6-update-shell>
其中 $x$ 是待估的价值（估计），$y_k$ 是第 $k$ 次更新所用的#strong[目标值]（Target），$alpha_k$ 是步长。算法之间的全部差异，都落在三个坐标上：

1. #strong[目标值 $y_k$ 从哪里来]：是直接算出精确的条件期望（路线一），还是采样得到完整回报 $G_t$（路线二），还是采样一步再加当前估计自举（路线三）。这决定#strong[是否需要环境模型]以及#strong[目标是否有偏]。
2. #strong[目标策略与采样策略是否一致]：采样所用的行为策略 $b$ 与想评估的目标策略 $pi$ 相同时，样本可以直接用；不同时，样本来自错误的分布，需要#strong[重要性采样]重新加权——这是本章的第一块补丁（#link(<sec-importance-sampling>)[第 6.4 节]）。
3. #strong[用什么统计量把样本汇总成估计]：是精确求和（路线一），还是大数定律下的样本均值（路线二），还是 Robbins-Monro 随机近似下的递推平均（路线三）。三种统计量的性质不同，分别由下面三小节的数学工具给出保证。

#figure(
  caption: [三条路线在三个坐标上的取值对比。三者共用更新壳 @eq-ch6-update-shell，差别只在目标值 $y_k$ 的构造方式与所用的统计量],
  text(size: 8.6pt, table(
    columns: (26mm, 1fr, 1fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([坐标], [路线一：不动点迭代（DP）], [路线二：蒙特卡洛（MC）], [路线三：时序差分（TD）]),
    table.hline(),
    [环境模型], [必须已知], [不需要], [不需要],
    [目标值 $y_k$], [$cal(T) x_k$（精确期望）], [$G_t$（完整回报）], [$R_(t+1) + gamma V(S_(t+1))$（自举）],
    [统计量], [显式概率求和], [大数定律 · 样本均值], [Robbins-Monro 随机近似],
    [目标是否自举], [否（直接解方程）], [否（采样至终止）], [是（用当前估计替代未来）],
    [目标是否有偏], [无偏], [无偏], [有偏（源于自举）],
    [方差来源], [无采样方差], [整幕随机性，随幕长增长], [单步随机性，最低],
    [与贝尔曼方程的关系], [直接求解方程本身], [绕开方程，回到价值定义], [使用方程的单步递推形式],
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

== 路线二 · 基于蒙特卡洛（Monte Carlo）方法的价值估计（模型未知：完整轨迹采样）
<sec-mc-estimation>
当环境模型 $p(s', r divides s, a)$ 未知时，无法执行#link(<sec-dp-fixed-point>)[第 6.2 节]中的显式概率求和 $sum_(s', r) p(s', r divides s, a) [dot.op]$。路线二给出的是一个彻底而诚实的退让：#strong[蒙特卡洛（Monte Carlo, MC）方法]绕开一步贝尔曼递推方程，直接回到#link(<sec-value-functions>)[第 1.3 节]中价值函数的#strong[原始期望定义]（#link(<def-1.2>)[定义 1.2] 与#link(<def-1.3>)[定义 1.3]）：
$
  v_pi (s) eq.dot bb(E)_pi [#mhlg($G_t$) divides S_t = s], #h(3em) q_pi (s, a) eq.dot bb(E)_pi [#mhlg($G_t$) divides S_t = s, A_t = a] .
$
绕开贝尔曼方程，并不意味着 MC 与它无关：上面这两条价值定义正是#link(<sec-bellman-exp-cond>)[第 3]--#link(<sec-bellman-opt>)[5 章]全部贝尔曼方程的出发点。MC 省掉的只是"用递推关系把未来的期望自举回来"这一步。这一取舍的后果是双向的：目标值 $G_t$ 无偏，不受自举偏差影响，也不依赖马尔可夫性假设；但必须等到整幕终止才能更新，且方差随幕长增长。

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

3. #strong[离轨策略的样本错配]：以上估计量都假定样本由被评估的策略 $pi$ 自己产生。若样本来自另一个策略，则用它们求平均得到的是那个策略的动作价值，而不是 $q_pi (s, a)$。这是本章的第一块补丁，单独在#link(<sec-importance-sampling>)[第 6.4 节]展开。

#divider()

== 补丁一 · 离轨评估与重要性采样（采样分布与目标分布不一致）
<sec-importance-sampling>
前两条路线都默认了一件事：样本是由被评估的策略 $pi$ 自己产生的。但实际算法里，样本往往来自另一个策略——用带探索的策略采集数据、同时评估或改进一个更贪心的目标策略，是所有离轨（Off-Policy）方法的共同结构。此时估计量被算在了错误的分布上：这不是数值误差，而是#strong[分布错配]。本节把这块补丁讲清楚：它修的是什么、怎么修、代价是什么，以及#strong[什么情况下根本不需要它]。

1. #strong[病灶与覆盖假设]：
   设样本由#strong[行为策略（Behavior Policy）] $b(a divides s)$ 产生，而要估计的是#strong[目标策略（Target Policy）] $pi(a divides s)$ 的动作价值 $q_pi (s, a)$。直接对 $b$ 的样本求平均，收敛到的是 $q_b (s, a)$ 而不是 $q_pi (s, a)$——整个估计的目标错了。
   唯一可能修好的前提是#strong[覆盖假设（Coverage）]：
   $
     pi(a divides s) > 0 ⟹ b(a divides s) > 0, #h(1.5em) forall s in cal(S), a in cal(A) .
   $ <eq-is-coverage>
   即 $b$ 必须在 $pi$ 认为可能的每个动作上都留有正概率。若某处 $pi(a divides s) > 0$ 而 $b(a divides s) = 0$，则该处的样本永远不会出现，任何加权都无法弥补——这不是估计精度问题，而是信息缺失，不可修复。

2. #strong[手段：轨迹概率比，环境项相消]：
   关键观察是，$b$ 与 $pi$ 的差别只体现在#strong[动作的选取]上，环境的演化规律是同一个。把给定 $S_t, A_t$ 之后后续轨迹 $tau_(t + 1 : T) = (S_(t + 1), A_(t + 1), dots.h, S_T)$ 在两个策略下的条件概率相除，链式展开后#strong[未知的环境转移概率 $p(S_(k + 1), R_(k + 1) divides S_k, A_k)$ 在分子分母中完全约消]，只剩下动作概率的比值：
   $
     rho_(t + 1 : T - 1) eq.dot frac(product_(k = t + 1)^(T - 1) pi(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k)), product_(k = t + 1)^(T - 1) b(A_k divides S_k) cancel(p(S_(k + 1), R_(k + 1) divides S_k, A_k))) = #mhl($product_(k = t + 1)^(T - 1) frac(pi(A_k divides S_k), b(A_k divides S_k))$) .
   $ <eq-importance-sampling-ratio>
   这个#strong[重要性采样比（Importance Sampling Ratio）]完全不依赖环境模型，因此是模型无关的。加权后的回报样本满足 $bb(E)_b [rho_(t + 1 : T - 1) G_t divides S_t = s, A_t = a] = q_pi (s, a)$：它把"在 $b$ 下采样"还原成了"在 $pi$ 下求期望"。

3. #strong[估计量族：普通 IS 与加权 IS]：
   对同一个 $(s, a)$ 收集到的 $N(s, a)$ 个样本，有两种组合方式：
   $
     hat(Q)_pi^upright("OIS") (s, a) = frac(1, N(s, a)) sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), #h(2.5em) hat(Q)_pi^upright("WIS") (s, a) = frac(sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$) #mhlg($G_((i))$), sum_(i = 1)^(N(s, a)) #mhl($rho_((i))$)) .
   $ <eq-mc-ois-wis>
   - #strong[普通重要性采样（Ordinary IS, OIS）]：$hat(Q)_pi^upright("OIS") (s, a)$ 的期望严格等于 $q_pi (s, a)$，是无偏的；但它除以的是固定样本数 $N$，权重 $rho$ 可以任意大，方差可能无界。
   - #strong[加权重要性采样（Weighted IS, WIS）]：$hat(Q)_pi^upright("WIS") (s, a)$ 用权重之和 $sum_i rho_((i))$ 代替样本数 $N$ 作分母，相当于把 $rho$ 归一化。代价是引入了 $O(1 \/ N)$ 量级的偏差（因为分母是随机的），回报是当 $G$ 有界时估计量必落在 $[min_i G_((i)), max_i G_((i))]$ 内，方差有界。实践中常取 WIS。
   WIS 也可以写成增量式。设 $W_(n + 1) = W_n + rho_(n + 1)$，则
   $
     Q_(n + 1) = Q_n + frac(rho_(n + 1), W_(n + 1)) [G_(n + 1) - Q_n] .
   $ <eq-mc-wis-incremental>
   对照@eq-ch6-update-shell 可见，这仍然是同一个更新模板 $x arrow.l x + alpha_k (y_k - x)$，只是步长不再是预设的 $alpha_k$，而变成了#strong[由数据决定的随机步长] $alpha_k = rho_(k) \/ W_(k)$——与@eq-incremental-mean 中 $1 \/ N$ 自动产生是同一回事，只是这里每个样本的"份量"不同。

4. #strong[方差的来源与结构]：$rho$ 是连乘积，这是它麻烦的根源。可以证明一个重要的简化：把 $G_t$ 按奖励展开后，只有"乘在该奖励之前"的那些因子才真正影响期望，
   $
     bb(E)_b [rho_(t + 1 : T - 1) G_t divides S_t, A_t] = bb(E)_b [sum_(k = t + 1)^T gamma^(k - t - 1) rho_(t + 1 : k - 1) R_k divides S_t, A_t],
   $ <eq-per-decision-is>
   这就是#strong[逐决策重要性采样（Per-Decision IS）]。它说明：越靠后的奖励，乘在它前面的因子越多，方差贡献也越大。所以离轨估计的方差来源有两个：一是 $pi$ 与 $b$ 的差异程度（差异越大，单个因子越极端），二是#strong[幕的长度]（因子连乘的个数）。
   小结这块补丁的代价：它换来了"可以复用别人的数据"，付出的是方差——而且方差随幕长指数式增长。#link(<sec-offpolicy-multistep>)[第 6.7 节]会给出工程上通行的补救：把连乘截断。

5. #strong[什么时候不需要重要性采样]：这一点常被忽略。$rho$ 之所以出现，是因为目标值 $y_k$ 是#strong[在 $pi$ 下取期望]；如果目标值里根本没有这个期望，就不需要修正。典型情形是#strong[取最大值的自举目标]（值迭代、Q-Learning，见#link(<sec-td-action-value>)[第 6.6 节]）：
   $
     y_k = R_(k + 1) + gamma max_(a') Q(S_(k + 1), a') .
   $ <eq-max-target-no-is>
   这个 $max$ 是对 $Q$ 本身做的运算，与"动作 $A_k$ 是从哪个策略采出来的"无关；行为策略 $b$ 在这里只承担#strong[覆盖]职责——保证每个 $(s, a)$ 都被访问到，而不承担"分布要正确"的职责。反之，只要目标值是一个#strong[对动作的期望]（例如以 $pi$ 为目标的 Expected SARSA、或任何同轨平均），错配就立刻回来。判据可以一句话概括：#strong[目标值里但凡出现"对动作求期望"，而样本不是该期望对应的策略产生的，就必须加权。]

6. #strong[与贝尔曼方程的关系]：注意这块补丁#strong[没有改动贝尔曼方程本身]。@eq-bellman-exp-vv 依然写着 $v_pi (s) = bb(E)_pi [R + gamma v_pi (S') divides S = s]$，"在 $pi$ 下求期望"这一条一字未变。改的只是#strong[用来估计这个期望的样本权重]。
   这是本章补丁的共同形态，值得在进入其余补丁前点明：三条路线决定的是#strong[用什么去逼近期望]，补丁则在"样本与期望对不上"的地方做局部修正，而方程始终是那个不动点方程。#link(<sec-td-action-value>)[第 6.6 节]的补丁改的是目标的取法（$max$ 取代期望），#link(<sec-offpolicy-multistep>)[第 6.7 节]的补丁改的是回报的截断方式。

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

== 补丁二 · 动作价值与控制算法族（把"期望"换成"最大值"）
<sec-td-action-value>
#link(<sec-td-estimation>)[第 6.5 节]的自举目标始终是"对后继价值的某种加权平均"。本节收拢的是同一处改动的各个方向：把平均换成#strong[最大值]。这一处改动带来的是无模型最优控制的可能——一旦目标里出现 $max$，智能体不再需要"先评估策略、再改进策略"的两步循环，直接用一张 $Q$ 表就能读取贪心动作。

改动的代价沿几个方向显现：$max$ 是凸函数，会系统性高估；目标不再依赖采样动作，于是离轨成为可能（并因此不需要重要性采样，见#link(<sec-importance-sampling>)[第 6.4 节]第 5 项）；而一旦叠加函数近似，还会出现发散风险。以下五个算法共用一个目标结构，逐个说清三件事：#strong[病灶]（为解决问题而改动）、#strong[改动]（改了什么）、#strong[代价与对应方程]。

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
   - #strong[病灶]：@eq-bellman-exp-qq 右端的期望是对 $(R_(t + 1), S_(t + 1), A_(t + 1))$ 三者一起取的，其中 $A_(t + 1)$ 的随机性来自策略本身，模型未知时无法用求和消除；#strong[改动]：不对 $A_(t + 1)$ 求期望，改为采样一个实际执行的动作，用单样本代替三重期望；#strong[代价与方程]：目标里多一份策略层方差，且样本只能来自正在执行的策略（同轨）。对应贝尔曼期望方程 @eq-bellman-exp-qq。

2. #strong[期望 SARSA 算法（Expected SARSA，对应 $q_pi arrow.r q_pi$ 环境层采样 + 策略层精确期望）]：
   回顾#link(<sec-cond-qq>)[第 3.4 节]对 @eq-bellman-exp-qq 的嵌套期望分解：$q_pi (s, a) = bb(E)_(R_(t + 1), S_(t + 1)) [R_(t + 1) + gamma bb(E)_(A_(t + 1) tilde.op pi) [q_pi (S_(t + 1), A_(t + 1))] divides S_t = s, A_t = a]$。虽然环境转移分布 $p(s', r divides s, a)$ 未知（必须通过采样 $(R_(t + 1), S_(t + 1))$ 做随机近似），但#strong[智能体自身的策略分布 $pi(a' divides S_(t + 1))$ 已知]。因此，无需像 SARSA 那样对下一动作 $A_(t + 1)$ 进行随机采样，而是直接对后继动作求精确期望：
   $
     #eqbox([$ Q(S_t, A_t) arrow.l Q(S_t, A_t) + #mhl($alpha$) [R_(t + 1) + gamma sum_(a' in cal(A)) #mhl($pi(a' divides S_(t + 1))$) #mhlg($Q(S_(t + 1), a')$) - Q(S_t, A_t)] $])
   $ <eq-expected-sarsa-update>
   #strong[优势]：Expected SARSA 消除了因随机采样 $A_(t + 1)$ 引入的策略层方差，在相同步长下比标准 SARSA 具有更低的估计方差与更高的稳定性，且既可作同轨评估/控制，也可自然用作离轨评估（令 $b$ 生成样本，目标策略 $pi$ 代入求和）。
   - #strong[病灶]：SARSA 的目标里 $A_(t + 1)$ 是采样出来的，可策略分布 $pi(a' divides S_(t + 1))$ 是智能体自己的、完全已知的，这里白白承担了一次采样方差；#strong[改动]：策略层改回精确期望，环境层 $(R_(t + 1), S_(t + 1))$ 仍靠采样；#strong[代价与方程]：每步多一次对全部动作的求和（$|cal(A)|$ 倍计算量），换来更低的方差。对应贝尔曼期望方程 @eq-bellman-exp-qq。

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
   - #strong[病灶]：SARSA 的目标依赖下一个#strong[实际执行]的动作，于是"评估"与"探索"被绑在一起——为探索而执行的动作会拉低它自己的价值估计，学到的是带探索的策略；#strong[改动]：把 $A_(t + 1)$ 的期望换成对后继动作取 $max$，目标直接指向最优；#strong[代价与方程]：目标从"评估 $pi$"变成"评估 $pi_star$"，样本从此可来自任意策略（离轨）而不需要重要性采样（见#link(<sec-importance-sampling>)[第 6.4 节]第 5 项），代价是 $max$ 带来的系统性高估。对应的是#strong[贝尔曼最优方程] @eq-opt-cond-qq，而非期望方程。

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
   - #strong[病灶]：@eq-td-control 用同一份带噪估计既#strong[选]动作又#strong[评]价值，由 Jensen 不等式（@eq-maximization-bias）必有系统性高估；#strong[改动]：把"选"与"评"拆到两份独立估计器上，估计器层面解耦；#strong[代价与方程]：双倍存储与两次更新，偏差反转为轻微低估。方程仍是 @eq-opt-cond-qq，这是一处纯估计器层面的补丁，不动方程形态。

5. #strong[从表格型随机近似到参数化函数近似（DQN 与随机梯度下降）]：
   当状态空间 $cal(S)$ 为高维或连续空间时，用参数化函数 $hat(v)(s; bold(theta))$ 或 $hat(q)(s, a; bold(theta))$（如深度神经网络）近似价值函数。此时对均方 TD 误差 $cal(L)(bold(theta)) = 1 / 2 [y_t^upright("TD") - hat(q)(S_t, A_t; bold(theta))]^2$（将目标网络参数 $bold(theta)^-$ 视为固定常数，即半梯度 Semi-gradient）做随机梯度下降，即为 #strong[DQN（Deep Q-Network）] 的参数更新律：
   $
     bold(theta)_(t + 1) = bold(theta)_t + #mhl($alpha$) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($hat(q)(S_(t + 1), a'; bold(theta)^-)$) - hat(q)(S_t, A_t; bold(theta)_t)] #mhlb($nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)_t)$) .
   $ <eq-dqn-update>
   当取表格型独热特征表示（One-Hot Feature）时，$nabla_(bold(theta)) hat(q)(S_t, A_t; bold(theta)) = bold(e)_((S_t, A_t))$，@eq-dqn-update 精确退化为表格型 Q-Learning（@eq-td-control）。DQN 另以经验回放（Experience Replay）打破样本相关性，并周期性复制 $bold(theta)^- arrow.l bold(theta)$。

   #strong[函数近似下的收敛边界]：上述 TD(0)、SARSA、Q-Learning 的以概率 $1$ 收敛结论均限于表格型表示。参数化以后，半梯度更新不再是任何固定目标函数的梯度下降。已知结论为：同轨线性 TD(0) 收敛到 TD 不动点，其误差不超过最优线性逼近误差的 $1 \/ (1 - gamma)$ 倍（Tsitsiklis & Van Roy, 1997）；函数近似、自举与离轨训练三者同时出现（#strong[致命三元组]，Deadly Triad）时，即使线性特征也可能发散（Baird 反例，1995）。DQN 等深度方法因此没有一般性收敛保证，稳定性依赖目标网络、经验回放等工程措施。
   - #strong[病灶]：表格型只对有限状态空间成立，实际问题的 $cal(S)$ 高维或连续，存不下一张表；#strong[改动]：用参数化函数 $hat(q)(s, a; bold(theta))$ 代替表，更新改为沿半梯度下降（@eq-dqn-update）；#strong[代价与方程]：$max$ 目标本身没变，但"以概率 $1$ 收敛到不动点"这一结论不再成立——函数近似、自举、离轨三者同时出现即致命三元组，只能靠目标网络与经验回放压制发散。

#divider()

== 补丁三 · 离轨多步的方差控制（截断重要性采样）
<sec-offpolicy-multistep>
第一块补丁（#link(<sec-importance-sampling>)[第 6.4 节]）把"样本分布不对"修好了：乘上重要性采样比 $rho$，估计量就无偏。代价写在 @eq-per-decision-is 里——$rho$ 是连乘，方差随幕长增长，几幕之后普通 IS 的估计在数值上就不可用了。而#link(<sec-td-estimation>)[第 6.5 节]又说，多步回报能显著降低自举偏差。两者合在一起就撞上了这个矛盾：我们既想要离轨（复用旧数据、并行采集），又想要多步（减小偏差），而离轨多步的乘性权重让方差不可控。

本节的补丁只有一句话：把权重截断。

1. #strong[截断重要性采样（Truncated IS）]：
   把连乘权重 $rho_(t + 1 : t + n) = product_(k = t + 1)^(t + n) frac(pi(A_k divides S_k), b(A_k divides S_k))$ 逐项截断到 $bar(c)$ 以内：
   $
     bar(rho)_(t + 1 : t + n) eq.dot product_(k = t + 1)^(t + n) min (bar(c), frac(pi(A_k divides S_k), b(A_k divides S_k))) .
   $ <eq-truncated-is>
   每项都以概率 $1$ 有界，连乘也就有界，方差随之可控。代价直接来自 $min$：截断改变了权重的期望，估计量#strong[有偏]，且这个偏差不会随样本量消失。这与#link(<sec-importance-sampling>)[第 6.4 节]第 3 项 WIS 的性质同向：都是"用有界换无偏"。

2. #strong[Retrace($lambda$)]：
   Retrace 把截断放进 $lambda$-回报的递推里，产出一个#strong[递归的]、带截断权重的多步目标（Munos et al., 2016）：
   $
     Q^upright("Retrace") (S_t, A_t) eq.dot Q(S_t, A_t) + sum_(k = t)^(T - 1) gamma^(k - t) (product_(j = t + 1)^k bar(c)_j) delta_k, #h(1.5em) bar(c)_j = min(bar(c), frac(pi(A_j divides S_j), b(A_j divides S_j))) ,
   $ <eq-retrace>
   其中 $delta_k$ 是第 $k$ 步的 TD 误差（@eq-td-target-error）。当目标策略与行为策略接近时 $bar(c)_j approx 1$，@eq-retrace 退化为普通的 TD($lambda$) 式累加；两者差异很大时，截断把权重压回 $bar(c)$ 以内。Retrace 的一个重要性质是#strong[评估的安全性]：只要行为策略覆盖目标策略（@eq-is-coverage），即使 $pi$ 与 $b$ 差别很大，估计量的方差仍有界。

3. #strong[V-trace]：
   V-trace 是同一思路面向#strong[分布式 Actor-Learner 架构]的版本（Espeholt et al., 2018）：它用两个截断常数分别控制"目标不变性"与"方差"，并显式修正策略滞后带来的偏差。结论相同——截断换来有界方差，代价是目标价值出现依赖截断常数的偏移。

4. #strong[与贝尔曼方程的关系]：这里的方程形态第一次#strong[发生变化]。@eq-bellman-exp-vv 的右端是对后继状态的期望；@eq-retrace 的右端则是"沿轨迹累加带截断权重的 TD 误差"。形式上它仍是一个不动点方程，但#strong[不动点不再是 $v_pi$]，而是某个由 $bar(c)$ 决定的、介于 $v_b$ 与 $v_pi$ 之间的值。这是本章唯一一处"为了控制方差而接受目标改变"的地方，也是它与前三块补丁的根本区别：前三块都是让估计量去逼近同一个目标，这一块是#strong[换了一个更好算的目标]。

#divider()

== 三类估计方法的回溯结构对比与补丁总览
<sec-estimation-comparison>
综合#link(<sec-dp-fixed-point>)[第 6.2]--#link(<sec-offpolicy-multistep>)[6.7 节]，动态规划（DP）、蒙特卡洛（MC）与时序差分（TD）是强化学习价值估计的三类基本方法。三者在马尔可夫决策树上的回溯广度（Width）与深度（Depth）不同（见 @fig-dp-mc-td-backups），针对状态价值与动作价值的全部估计算法及统计特征汇总于 @tab-all-value-estimators。

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

三条路线各自暴露了自身无法解决的问题，本章用三块补丁分别处理。补丁不改变"采样代替求和"这一基本立场，只改动目标值 $y_k$ 的构造方式；三块补丁的病灶、做法、代价与被改动的方程汇总于 @tab-estimation-patches。

#figure(
  caption: [三类基本估计路线之上的三块补丁。前三列说明"为什么打补丁"与"补丁怎么打"，后三列说明"打补丁付出什么代价"以及被打补丁的是贝尔曼方程链条上的哪一环],
  text(size: 8.4pt, table(
    columns: (1.15fr, 0.9fr, 1.7fr, 1.35fr, 1.15fr, 1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header(
      [病灶],
      [补丁],
      [做法],
      [代价],
      [对应方程],
      [代表算法],
    ),
    table.hline(),
    [样本分布与目标分布不一致：样本来自 $b$，却要求 $pi$ 的期望，$bb(E)_b [G_t] eq.not q_pi (s, a)$],
    [补丁一 \ 重要性采样 \ #link(<sec-importance-sampling>)[6.4 节]],
    [乘轨迹概率比 $rho_(t + 1:T - 1)$，环境转移项相消，只剩策略比；加权 IS 再除以权重和 $W$ 归一化],
    [方差随幕长指数增长；WIS 有偏，仅渐近无偏],
    [贝尔曼期望方程 \ @eq-bellman-exp-vv \ （方程不变，只改样本权重）],
    [离轨 MC \ OIS / WIS],
    table.hline(stroke: 0.6pt + accent),
    [策略层算子是加权平均 $sum_a pi(a divides s)$，而控制目标要求取最大值；且 $max$ 是凸函数，对含噪估计取最大会系统性高估],
    [补丁二 \ 期望换最大值 \ #link(<sec-td-action-value>)[6.6 节]],
    [把目标中的 $sum_(a') pi(a' divides s')$ 换成 $max_(a')$；目标不再依赖采样动作，离轨由此成为可能],
    [最大化偏差；叠加函数近似后可能发散],
    [贝尔曼最优方程 \ @eq-opt-cond-qq],
    [$Q$-Learning \ Double $Q$-Learning \ DQN],
    table.hline(stroke: 0.6pt + accent),
    [离轨与多步叠加：$rho$ 沿轨迹连乘，方差不可控，且离轨多步目标同时受两处噪声影响],
    [补丁三 \ 截断重要性采样 \ #link(<sec-offpolicy-multistep>)[6.7 节]],
    [对比率逐项截断到 $bar(c)$，再以 $lambda$ 加权做树回溯平均；V-trace 在此之上再截断 TD 误差],
    [目标有偏；截断改写了不动点本身],
    [Retrace 方程 \ @eq-retrace \ （本章唯一改变不动点形态的补丁）],
    [Retrace($lambda$) \ V-trace],
  )),
) <tab-estimation-patches>

#divider()

// ============================================================
//  第 7 章：策略梯度——不解方程，直接对期望目标求导
// ============================================================
= 策略梯度：不解方程，直接对期望目标求导
<sec-policy-gradient>

#link(<sec-value-estimation>)[第 6 章]的三条路线有一个共同前提：把贝尔曼方程当作#strong[求解对象]，先估计出 $v_pi$ 或 $q_star$，再从价值函数中读出策略。本章给出另一条路线：把策略本身写成参数 $bold(theta)$ 的函数，直接对#strong[期望回报目标] $J(bold(theta))$ 求梯度并做梯度上升。这条路线不再以贝尔曼方程为求解对象，却仍然借用了第 6 章的全部期望估计工具——只是估计的对象从"价值"换成了"梯度"。本章依次给出：记号与设定的局部扩展（#link(<sec-pg-setup>)[第 7.1 节]）、值方法的三处失效（#link(<sec-pg-motivation>)[第 7.2 节]）、策略梯度定理的完整推导（#link(<sec-pg-theorem>)[第 7.3 节]）、REINFORCE（#link(<sec-reinforce>)[第 7.4 节]）、基线与优势函数（#link(<sec-pg-baseline>)[第 7.5 节]）、Actor-Critic（#link(<sec-actor-critic>)[第 7.6 节]）、广义优势估计 GAE（#link(<sec-gae>)[第 7.7 节]）、与贝尔曼方程的关系边界（#link(<sec-pg-vs-bellman>)[第 7.8 节]），最后是工程变体的动机与代价（#link(<sec-pg-variants>)[第 7.9 节]）。
这条线在本章最后一节延伸到本代大语言模型的 RLVR 算法族：同一裁剪外壳，三个坐标（#link(<sec-rlvr-lineage>)[第 7.10 节]）。

#divider()

== 记号与设定的局部扩展
<sec-pg-setup>

第 1--6 章一直假定动作空间 $cal(A)$ 有限、策略是概率分布 $pi(a divides s)$、期望写成求和。本章需要用到#strong[连续动作空间]与#strong[参数化策略]，因此只在本章局部放宽记号，不回改前文：

1. #strong[动作空间可含连续分量]：设 $cal(A) subset.eq bb(R)^m$，策略写为关于 $a$ 的#strong[概率密度] $pi(a divides s)$，即对任意可测集 $B subset.eq cal(A)$ 有 $Pr(A_t in B divides S_t = s) = integral_B pi(a divides s) dif a$。当 $cal(A)$ 有限时，把积分换回求和 $sum_(a in cal(A))$，所有公式即退化为前文的写法；本章统一使用积分记号，求和形式是它的特例。
2. #strong[策略参数化]：策略由参数 $bold(theta) in bb(R)^d$ 决定，记为 $pi_bold(theta) (a divides s)$。例如离散动作可取 softmax 策略 $pi_bold(theta) (a divides s) prop exp(bold(theta)^top bold(phi)(s, a))$，连续动作可取高斯策略，其均值与方差由 $bold(theta)$ 参数化。
3. #strong[正性假设]：为使用 $log pi_bold(theta)$ 及其梯度，要求对所考虑的状态与动作 $pi_bold(theta) (a divides s) > 0$，且 $pi_bold(theta)$ 关于 $bold(theta)$ 可微。
4. #strong[期望回报目标]：以初始状态分布 $d_0$ 下的期望价值为目标
   $
     J(bold(theta)) eq.dot sum_(s in cal(S)) d_0 (s) v_(pi_bold(theta)) (s) = bb(E)_(S_0 tilde d_0) [v_(pi_bold(theta)) (S_0)] .
   $ <eq-pg-objective>
   任务仍是折扣 MDP，折扣因子 $gamma in [0, 1)$；持续任务与平均奖励目标不在本章范围。
5. #strong[折扣状态访问测度]：记沿策略 $pi$ 运行时的折扣状态访问（未归一化）与归一化形式
   $
     mu^pi (s) eq.dot sum_(t = 0)^oo gamma^t Pr(S_t = s divides pi, d_0), quad d^pi (s) eq.dot (1 - gamma) mu^pi (s), quad sum_(s in cal(S)) d^pi (s) = 1 .
   $ <eq-pg-state-visitation>

#divider()

== 动机：值方法在三处失效
<sec-pg-motivation>

第 6 章的算法族都以"先有价值、后有策略"为骨架。这个骨架在三类问题面前失效，而策略梯度恰好绕过它们：

1. #strong[连续动作下 $max_a$ 本身成了优化问题]：值方法读取策略的每一步都要算 $arg max_a q(s, a)$。$cal(A)$ 有限时这是一次查表；$cal(A) subset.eq bb(R)^m$ 时它是每个状态上的非凸优化，既昂贵又无法保证全局最优。策略梯度把 $pi_bold(theta)$ 直接参数化为可采样的密度，动作由采样得到，不需要解 $arg max$。
2. #strong[最优策略可能必须是随机的]：贪心或 $epsilon$-贪心策略只能逼近确定性策略。在部分可观测或对抗环境中，最优策略本身可能是真正的随机分布（例如需要混合策略的博弈）。参数化随机策略能直接表示这类解，值方法的贪心外环则不能。
3. #strong[目标错位：价值误差小不等于策略好]：值方法最小化的是 $norm(V - v_pi)$ 或 TD 残差，而真正关心的是 $J(bold(theta))$。均方价值误差与策略性能之间没有单调关系：在某些状态上很小的价值误差，可能诱导出很差的贪心动作。策略梯度直接优化 $J(bold(theta))$，目标与实际目的对齐。

两条路线的分野见 @fig-pg-vs-value：它们共享同一个起点（回报的期望），但一个去解不动点方程，另一个去对目标求导。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (12mm, 8mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 5pt,
      node-corner-radius: 3pt,
      node((1, 0), text(size: 8pt)[*共同起点：回报的期望* \ $J = bb(E)[G_0]$，$v_pi = bb(E)[G_t divides S_t = s]$], fill: accent-soft, width: 62mm),
      node((0, 1), text(size: 8pt)[*值方法（第 6 章）：解方程* \ 求解对象：贝尔曼期望 / 最优方程的不动点 \ 先估计 $v_pi$ 或 $q_star$，再由 $arg max_a$ 读出策略], fill: hl-blue-fill, stroke: 0.85pt + hl-blue-stroke, width: 62mm),
      node((2, 1), text(size: 8pt)[*策略梯度（第 7 章）：对目标求导* \ 求解对象：$max_bold(theta) J(bold(theta))$ 的平稳点 \ 直接优化 $pi_bold(theta)$，价值只作为梯度的权重出现], fill: hl-amber-fill, stroke: 0.85pt + hl-amber-stroke, width: 62mm),
      edge((1, 0), (0, 1), "->", text(size: 7pt)[估计价值], label-side: right),
      edge((1, 0), (2, 1), "->", text(size: 7pt)[估计梯度], label-side: left),
      node((0, 2), text(size: 7.4pt)[工具：压缩映射、大数定律、Robbins-Monro], stroke: none, width: 62mm),
      node((2, 2), text(size: 7.4pt)[工具：对数导数技巧、基线、优势估计 \ （价值估计仅作为 Critic 复用第 6 章）], stroke: none, width: 62mm),
    )
  },
  caption: [值方法与策略梯度的分野：共同起点是回报的期望；左支以贝尔曼方程为求解对象，右支以期望目标的平稳点为求解对象，贝尔曼方程在右支中只通过优势函数与 Critic 进入],
) <fig-pg-vs-value>

#divider()

== 策略梯度定理：把梯度写成一个期望
<sec-pg-theorem>

要沿 $nabla_bold(theta) J(bold(theta))$ 做梯度上升，首先遇到两个障碍：$J$ 是期望，无法精确求值；$v_(pi_bold(theta))$ 对 $bold(theta)$ 的依赖既有#strong[动作分布]一条，又有#strong[环境状态分布随策略改变]一条，直接展开会没完没了。下面两件工具分别解决它们。

#strong[引理 7.1（对数导数技巧，Log-Derivative Trick）] <lem-7.1> 设 $pi_bold(theta) (a divides s) > 0$ 且关于 $bold(theta)$ 可微，则对任意函数 $f(a)$（不要求 $f$ 可微），有恒等式
$
  #eqbox([$ integral_(cal(A)) f(a) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) dif a = integral_(cal(A)) pi_bold(theta) (a divides s) f(a) #mhl($nabla_bold(theta) log pi_bold(theta) (a divides s)$) dif a $])
$ <eq-pg-log-derivative>
即"对密度求导"可改写为"在该密度下对 $nabla_bold(theta) log pi_bold(theta)$ 加权求期望"。特别地，取 $f eq.triple 1$ 得
$
  integral_(cal(A)) pi_bold(theta) (a divides s) nabla_bold(theta) log pi_bold(theta) (a divides s) dif a = nabla_bold(theta) integral_(cal(A)) pi_bold(theta) (a divides s) dif a = nabla_bold(theta) 1 = bold(0) .
$ <eq-pg-score-zero>

#strong[证明]：由 $nabla_bold(theta) log pi_bold(theta) = (nabla_bold(theta) pi_bold(theta)) \/ pi_bold(theta)$（对数求导法则），两边乘 $pi_bold(theta)$ 即得 $nabla_bold(theta) pi_bold(theta) = pi_bold(theta) nabla_bold(theta) log pi_bold(theta)$，代入左端积分即证。取 $f eq.triple 1$ 时积分与求导可交换（假设可微性与可积性条件满足），而 $pi_bold(theta)$ 归一化是#strong[恒等式]，对 $bold(theta)$ 求导恒为零。$#h(2em) square.filled.medium$

这一条引理是整章的支点：它把"求导"换成了"求期望"，于是第 6 章的采样工具可以照单全收。被采样的量 $nabla_bold(theta) log pi_bold(theta)$ 称为#strong[得分函数]（Score Function）。

#strong[定理 7.1（策略梯度定理，Sutton et al. 2000）] <thm-7.1> 在#link(<sec-pg-setup>)[第 7.1 节]的设定下，目标 @eq-pg-objective 的梯度可写成
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = sum_(s in cal(S)) #mhlb($mu^(pi_bold(theta)) (s)$) integral_(cal(A)) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) thin #mhlg($q_(pi_bold(theta)) (s, a)$) dif a $])
$ <eq-pg-theorem-sum>
其中 $mu^(pi_bold(theta))$ 是 @eq-pg-state-visitation 定义的折扣状态访问测度。等价地，用引理 7.1 与 $d^(pi_bold(theta)) = (1 - gamma) mu^(pi_bold(theta))$ 归一化后写成期望形式
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = frac(1, 1 - gamma) bb(E)_(S tilde d^(pi_bold(theta)), A tilde pi_bold(theta)) [#mhlg($q_(pi_bold(theta)) (S, A)$) #mhl($nabla_bold(theta) log pi_bold(theta) (A divides S)$)] $])
$ <eq-pg-theorem-expectation>

#strong[证明（三步：先对 $v$ 求导、借贝尔曼桥接换到 $q$、再展开自递推）]：

+ #strong[第一步：对 $v_(pi_bold(theta))$ 求导，策略层与环境层拆开。] 由#link(<thm-3.1>)[定理 3.1] 的 $v_pi arrow.r q_pi$ 桥接式 $v_(pi_bold(theta)) (s) = integral_(cal(A)) pi_bold(theta) (a divides s) q_(pi_bold(theta)) (s, a) dif a$，对 $bold(theta)$ 求导并用乘积法则：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = underbrace(integral_(cal(A)) #mhl($nabla_bold(theta) pi_bold(theta) (a divides s)$) q_(pi_bold(theta)) (s, a) dif a, upright("记为 ") phi(s)) + integral_(cal(A)) pi_bold(theta) (a divides s) nabla_bold(theta) q_(pi_bold(theta)) (s, a) dif a .
  $ <eq-pg-proof-step1>
  记第一项为 $phi(s)$，它就是定理右端"去掉状态求和"的局部形式；第二项仍需处理 $nabla_bold(theta) q_(pi_bold(theta))$。

+ #strong[第二步：对 $q$ 用贝尔曼桥接，环境模型项对 $bold(theta)$ 求导为零。] 由#link(<thm-4.2>)[定理 4.2] 的 $q_pi arrow.r v_pi$ 桥接式
  $ q_(pi_bold(theta)) (s, a) = sum_(s', r) p(s', r divides s, a) [r + gamma v_(pi_bold(theta)) (s')] $，
  其中环境模型 $p(s', r divides s, a)$ #strong[不依赖] $bold(theta)$（这是 MDP 与策略分离的关键），故
  $
    nabla_bold(theta) q_(pi_bold(theta)) (s, a) = gamma sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s') = gamma sum_(s' in cal(S)) p(s' divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s') .
  $ <eq-pg-proof-step2>
  代回 @eq-pg-proof-step1 的第二项，并把对 $a$ 的积分与对 $s'$ 的求和合并为"下一状态的分布" $Pr(S' = s' divides S = s, pi_bold(theta)) = integral_(cal(A)) pi_bold(theta) (a divides s) p(s' divides s, a) dif a$：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = phi(s) + gamma sum_(s' in cal(S)) Pr(S' = s' divides S = s, pi_bold(theta)) nabla_bold(theta) v_(pi_bold(theta)) (s') .
  $ <eq-pg-proof-recursion>
  这与#link(<sec-bellman-exp-cond>)[第 3 章]的贝尔曼自递推形式完全一致，只是未知量换成了 $nabla_bold(theta) v_(pi_bold(theta))$、自由项换成了 $phi$。

+ #strong[第三步：把自递推展开成沿轨迹的折扣和，$nabla_bold(theta) mu$ 被自动吸收。] 对 @eq-pg-proof-recursion 反复迭代（$gamma < 1$ 保证级数收敛，与#link(<thm-5.9>)[定理 5.9] 的压缩映射同一机制）：
  $
    nabla_bold(theta) v_(pi_bold(theta)) (s) = sum_(t = 0)^oo gamma^t sum_(s' in cal(S)) Pr(S_t = s' divides S_0 = s, pi_bold(theta)) phi(s') .
  $ <eq-pg-proof-unrolled>
  代回 $nabla_bold(theta) J(bold(theta)) = sum_s d_0 (s) nabla_bold(theta) v_(pi_bold(theta)) (s)$（$d_0$ 不依赖 $bold(theta)$），交换求和次序：
  $
    nabla_bold(theta) J(bold(theta)) = sum_(s' in cal(S)) underbrace(sum_(t = 0)^oo gamma^t sum_(s in cal(S)) d_0 (s) Pr(S_t = s' divides S_0 = s, pi_bold(theta)), = thin mu^(pi_bold(theta)) (s') thin upright("（@eq-pg-state-visitation）")) phi(s') = sum_(s' in cal(S)) mu^(pi_bold(theta)) (s') phi(s') ,
  $
  即 @eq-pg-theorem-sum；再对其用引理 7.1 并除以 $1 - gamma$ 得 @eq-pg-theorem-expectation。$#h(2em) square.filled.medium$

#strong[关于"梯度穿过状态分布"那一项的去向]：$J(bold(theta)) = sum_s d_0 (s) v_(pi_bold(theta)) (s)$ 中 $d_0$ 固定，问题全部来自 $v_(pi_bold(theta))$ 内部状态分布对 $bold(theta)$ 的依赖。证明显示这项#strong[并没有被丢弃]：它在 @eq-pg-proof-step2 借贝尔曼方程把 $nabla_bold(theta) q_(pi_bold(theta))$ 化为 $gamma sum_(s') p(s' divides s, a) nabla_bold(theta) v_(pi_bold(theta)) (s')$，再经 @eq-pg-proof-recursion 的自递推被展开成 $mu^(pi_bold(theta))$。换言之，贝尔曼方程使 $nabla_bold(theta)$ 与算子 $cal(T)^pi$ #strong[可交换]，把"对状态分布求导"的无穷级数一次性吸收进折扣访问测度。若不走这条递推、直接对有限 $T$ 的轨迹概率求导，也能得到同一结论（见 #link(<sec-reinforce>)[第 7.4 节]）。

#strong[关于常数因子 $1 \/ (1 - gamma)$]：@eq-pg-theorem-expectation 的期望形式带着 $1 \/ (1 - gamma)$。实际算法把它吸收进步长 $alpha$，写成 $bb(E)_(d^pi, pi)[q_pi nabla_bold(theta) log pi]$ 并按此采样；这与 #link(<sec-robbins-monro-theory>)[第 6.1 节] Robbins-Monro 更新中"目标值可差一个正常数倍、由步长补偿"的做法一致。

#divider()

== REINFORCE：策略空间中的蒙特卡洛估计
<sec-reinforce>

定理 7.1 把梯度写成期望，剩下的问题就是用样本去估计它。最直接的选择与#link(<sec-mc-estimation>)[第 6.3 节]一致：用完整回报 $G_t$ 代替 $q_(pi_bold(theta))$。

#strong[命题 7.1（REINFORCE 估计量的无偏性）] <prop-7.1> 设轨迹 $tau = (S_0, A_0, R_1, dots.h)$ 由 $pi_bold(theta)$ 生成，则
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = bb(E)_(tau tilde pi_bold(theta)) [sum_(t = 0)^(T - 1) #mhlb($gamma^t$) #mhlg($G_t$) #mhl($nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)$)] $])
$ <eq-pg-reinforce>
其中 $G_t = sum_(k = 0)^(T - t - 1) gamma^k R_(t + k + 1)$ 是 #link(<sec-mdp>)[第 1 章]定义的折扣回报。

#strong[证明]：把 @eq-pg-theorem-expectation 的期望写成沿轨迹的形式。注意 $G_t$ 只依赖 $t$ 时刻之后的奖励与状态，而在给定 $S_t = s, A_t = a$ 时，$bb(E)[G_t divides S_t = s, A_t = a] = q_(pi_bold(theta)) (s, a)$（动作价值定义 @eq-q-def）。于是对每一项用#link(<lem-1>)[引理 1] 的塔性质：
$
  bb(E)_(tau) [gamma^t G_t nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] = bb(E)_(S_t, A_t) [gamma^t bb(E)[G_t divides S_t, A_t] nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] = bb(E)_(S_t, A_t) [gamma^t q_(pi_bold(theta)) (S_t, A_t) nabla_bold(theta) log pi_bold(theta) (A_t divides S_t)] .
$
对 $t$ 求和，$sum_(t = 0)^oo gamma^t Pr(S_t = s)$ 恰好是 $mu^(pi_bold(theta)) (s)$，与 @eq-pg-proof-unrolled 一致，即得 @eq-pg-theorem-sum。$#h(2em) square.filled.medium$

对应的参数更新律为（随机梯度上升，步长 $alpha_k$ 满足 @eq-rm-step-conditions 时可套用 Robbins-Monro 框架）：
$
  #eqbox([$ bold(theta)_(k + 1) = bold(theta)_k + alpha_k sum_(t = 0)^(T - 1) gamma^t G_t nabla_bold(theta) log pi_bold(theta) (A_t divides S_t) $])
$ <eq-pg-reinforce-update>

#strong[三点说明]：

1. #strong[它就是策略空间的蒙特卡洛估计]：@eq-pg-reinforce 用完整回报 $G_t$ 代替 $q_(pi_bold(theta))$，与#link(<prop-6.2>)[命题 6.2] 的样本均值同一思路——无偏、不自举、必须等一幕结束。它估计的不是价值，而是梯度；但统计性质（无偏、方差大、需要整幕）与 MC 完全对应。
2. #strong[$gamma^t$ 因子是无偏性所要求的权重]：它来自折扣访问测度 $mu^(pi_bold(theta))$ 中第 $t$ 步的折扣 $gamma^t$。实际实现常省略它，代价是引入偏差（此时优化的不再是 @eq-pg-objective 的精确梯度）；保留它则与定理严格一致。
3. #strong[代价：方差]：$G_t$ 是整幕累积回报，随机性来自整段轨迹；得分函数 $nabla_bold(theta) log pi_bold(theta)$ 在每个时刻都要乘上一个高方差的标量。这正是下一节基线要解决的问题。

#divider()

== 基线与优势函数：减方差而不改梯度
<sec-pg-baseline>

REINFORCE 的病灶很清楚：得分函数 $nabla_bold(theta) log pi_bold(theta)$ 乘上的是整幕回报 $G_t$，而 $G_t$ 里含有大量与"在状态 $s$ 选动作 $a$ 有多好"无关的随机起伏。基线（Baseline）是这块补丁：从回报里减去一个#strong[不依赖当前动作]的量，方差下降而期望不变。

#strong[命题 7.2（状态基线不引入偏差）] <prop-7.2> 设 $b(s)$ 是任意只依赖状态 $s$、不依赖动作 $a$ 的函数，则对任意状态 $s$：
$
  bb(E)_(A tilde.op pi_bold(theta) (dot.op divides s)) [b(s) nabla_bold(theta) log pi_bold(theta) (A divides s)] = b(s) integral_(cal(A)) nabla_bold(theta) pi_bold(theta) (a divides s) dif a = bold(0) .
$ <eq-pg-baseline-zero>
因此 REINFORCE 的梯度可以等价写成
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = frac(1, 1 - gamma) bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta)) [(q_(pi_bold(theta)) (S, A) - b(S)) nabla_bold(theta) log pi_bold(theta) (A divides S)] $])
$ <eq-pg-baseline-gradient>

#strong[证明]：$b(s)$ 与 $A$ 无关，可提出期望；剩下的积分由 @eq-pg-score-zero 为零。关键是 $integral_(cal(A)) pi_bold(theta) (a divides s) dif a = 1$ 是#strong[恒等式]，对 $bold(theta)$ 求导恒为零——不是"近似为零"。把 $q_(pi_bold(theta))$ 换成 $q_(pi_bold(theta)) - b$ 因而不改变 @eq-pg-theorem-expectation。$#h(2em) square.filled.medium$

最自然的选择是 $b(s) = v_(pi_bold(theta)) (s)$：它代表"在状态 $s$ 按当前策略行事的平均水平"，而 $q_(pi_bold(theta)) (s, a)$ 是"在状态 $s$ 偏要执行动作 $a$、之后再按当前策略行事"的水平。二者之差就是#strong[优势函数]（Advantage Function）：
$
  #eqbox([$ A^(pi_bold(theta)) (s, a) eq.dot q_(pi_bold(theta)) (s, a) - v_(pi_bold(theta)) (s) $])
$ <eq-pg-advantage-def>
它回答"这个动作比平均水平好多少"，且在当前策略下均值为零：$bb(E)_(A tilde.op pi_bold(theta))[A^(pi_bold(theta)) (s, A)] = v_(pi_bold(theta)) (s) - v_(pi_bold(theta)) (s) = 0$。这正是 @eq-pg-baseline-gradient 的形式。

#strong[最优基线（可选读）]：若按梯度估计量的方差（协方差矩阵的迹）最小化来选 $b(s)$，对每个状态求解关于 $b$ 的二次优化，可得
$
  b^star (s) = frac(bb(E)_(A tilde.op pi_bold(theta)) [norm(nabla_bold(theta) log pi_bold(theta) (A divides s))^2 q_(pi_bold(theta)) (s, A)], bb(E)_(A tilde.op pi_bold(theta)) [norm(nabla_bold(theta) log pi_bold(theta) (A divides s))^2]) .
$ <eq-pg-optimal-baseline>
它是按得分函数范数加权的动作价值平均；$v_(pi_bold(theta))$ 是去掉权重后的常用近似。实际系统几乎不精确计算 @eq-pg-optimal-baseline，而是用第 6 章的方法估计 $v_(pi_bold(theta))$。

#strong[优势与 TD 误差的恒等关系]：基线补丁与#link(<sec-td-estimation>)[第 6.5 节]在此处合流。对单步转移，由贝尔曼期望方程 @eq-bellman-exp-vv 与动作价值定义：
$
  bb(E)[underbrace(R_(t + 1) + gamma v_(pi_bold(theta)) (S_(t + 1)) - v_(pi_bold(theta)) (S_t), upright("TD 误差 ") delta_t) divides S_t = s, A_t = a] = q_(pi_bold(theta)) (s, a) - v_(pi_bold(theta)) (s) = A^(pi_bold(theta)) (s, a) .
$ <eq-pg-advantage-td>
所以估计优势不必另维护一张 $Q$ 表：用一个 $V$ 的 TD 误差就够了。下一步就是把 $V$ 交给一个独立的估计器。

#divider()

== Actor-Critic：把第 6 章的价值估计器接进策略梯度
<sec-actor-critic>

#strong[Actor-Critic] 是基线补丁的自举版本：Actor 负责更新策略参数 $bold(theta)$，Critic 负责用第 6 章的方法估计 $v_(pi_bold(theta))$ 或优势。两者共用一条轨迹，但更新的是不同参数。

#strong[Actor（策略）]：用优势估计 $hat(A)_t$ 替换 @eq-pg-reinforce-update 中的 $G_t$，得到统一更新外壳
$
  #eqbox([$ bold(theta)_(k + 1) = bold(theta)_k + alpha_k #mhlg($hat(A)_t$) nabla_bold(theta) log pi_(bold(theta)_k) (A_t divides S_t) $])
$ <eq-pg-ac-update>
$hat(A)_t$ 的构造方式决定了这是哪一种 Actor-Critic，见 @tab-pg-advantage-estimators。

#strong[Critic（价值）]：以一步 TD 为例，维护参数 $bold(w)$ 的价值近似 $hat(v)(s; bold(w))$，TD 误差与 Critic 更新为
$
  hat(delta)_t = R_(t + 1) + gamma hat(v)(S_(t + 1); bold(w)_k) - hat(v)(S_t; bold(w)_k), quad bold(w)_(k + 1) = bold(w)_k + beta_k hat(delta)_t nabla_bold(w) hat(v)(S_t; bold(w)_k) .
$ <eq-pg-critic-update>
取 $hat(A)_t = hat(delta)_t$ 即得#strong[一步 Actor-Critic]；Critic 换成 $n$ 步 TD 或 TD($lambda$) 就得到相应的多步版本。这里的 Critic 更新与#link(<sec-td-estimation>)[第 6.5 节]的 TD(0) 完全同构，只是 $V$ 换成了参数化 $hat(v)$。

#strong[代价：从"无偏"退到"渐近无偏或有偏"]：REINFORCE 的 $G_t$ 在条件期望下等于真实 $q_(pi_bold(theta))$，而 $hat(delta)_t$ 含有尚未收敛的 $hat(v)$，因此 @eq-pg-ac-update 一般#strong[不是]真梯度的无偏估计。它换来的是在线更新、低方差与更短信用分配路径；偏差随 Critic 收敛而减小。

#strong[兼容函数近似（Compatible Function Approximation）]：何时 Critic 的近似不会破坏梯度方向？若取特征为得分函数
$
  hat(q)(s, a; bold(w)) = bold(w)^top nabla_bold(theta) log pi_bold(theta) (a divides s),
$ <eq-pg-compatible-features>
并令 $bold(w)$ 最小化加权均方误差 $bb(E)_(S tilde.op d^(pi_bold(theta)), A tilde.op pi_bold(theta))[(hat(q)(S, A; bold(w)) - q_(pi_bold(theta)) (S, A))^2]$（在通常的零均值归一化下），则所得 $bold(w)$ 与真梯度方向一致，只差一个由 $d^(pi_bold(theta))$ 归一化带来的正常数。这说明"价值近似"与"策略梯度"并非任意拼接：特征必须与得分函数兼容，才能保住方向。

#figure(
  caption: [Actor-Critic 中优势估计器与第 6 章估计方法的对应关系。估计器越靠下，自举越少、偏差越小而方差越大；GAE 用一个 $lambda$ 在这条谱上连续插值],
  text(size: 8.6pt, table(
    columns: (1.05fr, 1.55fr, 1.05fr, 1.2fr, 1.1fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([优势估计器], [构造], [借用的估计方法], [偏差 / 方差], [代表算法]),
    table.hline(),
    [MC 优势], [$hat(A)_t = G_t - hat(v)(S_t)$], [第 6.3 节 MC + 基线], [偏差小、方差大], [REINFORCE + 基线],
    table.hline(stroke: 0.6pt + accent),
    [一步 TD 优势], [$hat(A)_t = hat(delta)_t$], [第 6.5 节 TD(0)], [有自举偏差、方差小], [A2C / A3C],
    table.hline(stroke: 0.6pt + accent),
    [$n$ 步优势], [$hat(A)_t^((n)) = G_(t:t+n) - hat(v)(S_t)$], [第 6.5 节 $n$ 步 TD], [偏差-方差居中], [多步 Actor-Critic],
    table.hline(stroke: 0.6pt + accent),
    [GAE], [$hat(A)_t^upright("GAE")$，见 @eq-pg-gae], [第 6.5 节 TD($lambda$) 的优势版], [$lambda$ 连续调节], [PPO / TRPO],
  )),
) <tab-pg-advantage-estimators>

#divider()

== 广义优势估计：把 $n$ 步优势按几何权重平均
<sec-gae>

一步优势方差小但有自举偏差，MC 优势无偏但方差大。@tab-pg-advantage-estimators 的前三行是两个极端与一个折中，而#strong[广义优势估计]（Generalized Advantage Estimation, GAE）把 $n$ 步优势#strong[全部]按几何权重加权，用一个参数 $lambda$ 连续调节。

先把 $n$ 步优势写成 TD 误差之和。记 $delta_t = R_(t + 1) + gamma v_(pi_bold(theta)) (S_(t + 1)) - v_(pi_bold(theta)) (S_t)$，对 $n$ 步回报做望远镜式相消：
$
  #eqbox([$ hat(A)_t^((n)) = sum_(l = 0)^(n - 1) gamma^l delta_(t + l) = G_(t:t+n) - v_(pi_bold(theta)) (S_t) $])
$ <eq-pg-nstep-advantage>
推导只是把 $G_(t:t+n)$ 按每步展开后逐项配对：$gamma^l v_(pi_bold(theta)) (S_(t + l))$ 被前一项的 $gamma^l v_(pi_bold(theta)) (S_(t + l))$ 抵消，只剩首项 $-v_(pi_bold(theta)) (S_t)$ 与末项 $gamma^n v_(pi_bold(theta)) (S_(t + n))$。

#strong[定义 7.1（GAE）] <def-gae> 取 $lambda in [0, 1)$，定义
$
  #eqbox([$ hat(A)_t^upright("GAE") (gamma, lambda) eq.dot sum_(l = 0)^oo (gamma lambda)^l delta_(t + l) $])
$ <eq-pg-gae>

#strong[命题 7.3（GAE 是 $n$ 步优势的几何平均）] <prop-7.3> 对任意 $lambda in [0, 1)$，
$
  hat(A)_t^upright("GAE") (gamma, lambda) = (1 - lambda) sum_(n = 1)^oo lambda^(n - 1) hat(A)_t^((n)) .
$ <eq-pg-gae-average>
#strong[证明]：把 @eq-pg-nstep-advantage 代入右端，交换求和次序。右端中 $delta_(t + l)$ 的系数为
$
  (1 - lambda) sum_(n = l + 1)^oo lambda^(n - 1) gamma^l = (1 - lambda) frac(lambda^l, 1 - lambda) gamma^l = (gamma lambda)^l,
$
与 @eq-pg-gae 逐项相同。$#h(2em) square.filled.medium$

两端点验证了"连续旋钮"的说法：

- $lambda = 0$：@eq-pg-gae 只剩 $l = 0$ 项，$hat(A)_t^upright("GAE") = delta_t$，退化为一步 TD 优势——自举偏差最大、方差最小。
- $lambda = 1$：$hat(A)_t^upright("GAE") = sum_(l = 0)^oo gamma^l delta_(t + l) = G_t - v_(pi_bold(theta)) (S_t)$，退化为 MC 优势——无偏、方差最大。这一步正是 @eq-pg-nstep-advantage 在 $n -> oo$ 时的极限。

因此 GAE 与 @tab-pg-advantage-estimators 中"$n$ 步优势"是同一个旋钮的不同刻度，而不是另一种方法；它在#link(<sec-td-estimation>)[第 6.5 节]的 TD($lambda$) 中的位置完全对应：那里是$lambda$-回报对价值估计做几何加权，这里是同一权重对优势估计做几何加权。$lambda$ 只影响#strong[优势估计的偏差-方差]，不改变 @eq-pg-theorem-expectation 本身——策略梯度的目标与真梯度形式始终不变。

#divider()

== 策略梯度与贝尔曼方程：边界在哪里
<sec-pg-vs-bellman>

前面六章的中心任务是#strong[解方程]：把贝尔曼期望方程或贝尔曼最优方程当作自指的不动点方程，用迭代把 $v$、$q$ 解出来。本章的路线不同，必须把边界写清楚，否则会得出自相矛盾的结论。

#strong[边界（不变）]：策略梯度的求解对象是策略参数 $bold(theta)$，贝尔曼方程#strong[不再是求解对象]。REINFORCE 一路完全不出现自举，$v$、$q$ 也不需要被解出来——它只用到期望的可微性与对数导数技巧。这与第 6 章"解方程"是两条独立的路线。

#strong[但贝尔曼方程仍以三种方式进入]：

1. #strong[优势的定义]：$A^(pi) (s, a) = q_(pi) (s, a) - v_(pi) (s)$（@eq-pg-advantage-def）本身就是贝尔曼期望方程中 $v$ 与 $q$ 桥接关系 @eq-bellman-exp-vq 的差。没有这层关系，"优势"无从定义。
2. #strong[Critic 的价值估计]：Actor-Critic 与 GAE 用第 6 章的方法估计 $v_(pi_bold(theta))$——一步 TD 用贝尔曼期望方程 @eq-bellman-exp-vv，$n$ 步与 TD($lambda$) 是它的展开。此时贝尔曼方程#strong[被用来估计]一个量，而不是被求解为最终答案。
3. #strong[显式例外：软贝尔曼方程]：SAC（见#link(<sec-pg-variants>)[第 7.9 节]）在回报里加入策略熵，得到软贝尔曼方程。它确实又回到"解方程"的路子上，只不过方程右端多了一个熵项。

所以准确的表述是：策略梯度把贝尔曼方程从#strong[求解目标]降为#strong[估计工具]，而 SAC 是明确的反例，不能笼统说"策略梯度不解贝尔曼方程"。

#figure(
  caption: [策略梯度各族与贝尔曼方程的关系。前三行的贝尔曼方程只作为估计工具出现（优势定义与 Critic）；RLVR 族连 Critic 一并去掉，贝尔曼方程不再以任何形式进入梯度估计；最后一行是显式解方程的例外],
  text(size: 8.6pt, table(
    columns: (0.85fr, 1.7fr, 1.1fr, 1.05fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([算法], [优势 / 价值从哪来], [用到的贝尔曼关系], [是否解贝尔曼方程]),
    table.hline(),
    [REINFORCE], [完整回报 $G_t$ 减基线], [仅 $A = q - v$ 的定义], [否],
    table.hline(stroke: 0.6pt + accent),
    [A2C / A3C], [Critic 的一步或 $n$ 步 TD 误差], [@eq-bellman-exp-vv 用于估计 $v$], [否（估计，不解）],
    table.hline(stroke: 0.6pt + accent),
    [TRPO / PPO], [GAE（@eq-pg-gae）], [同上，经 TD($lambda$)], [否（估计，不解）],
    table.hline(stroke: 0.6pt + accent),
    [GRPO 族（#link(<sec-rlvr-lineage>)[第 7.10 节]）], [同一 prompt 内组内标准化的回报，广播为该回复各 token 的常数优势], [无（$A = q - v$ 的定义被组内基线替换，$v$ 不再被估计）], [否，且不估计 $v$],
    table.hline(stroke: 0.6pt + accent),
    [SAC], [软 $Q$ 与软 $V$，来自软贝尔曼方程], [软贝尔曼方程（含熵项）], [是，显式例外],
  )),
) <tab-pg-bellman-boundary>

#divider()

== 工程变体：各自修复一个具体病灶
<sec-pg-variants>

前面各节给的是"原理正确"的梯度估计：@eq-pg-theorem-expectation 无偏，@eq-pg-baseline-gradient 方差更低，@eq-pg-ac-update 能在线更新，@eq-pg-gae 给了偏差-方差旋钮。但直接把这些估计塞进梯度上升会遇到三类具体麻烦。下面三组变体各自只修其中一类，公式之外的改动一律不涉及。
变体一给出的裁剪外壳在 LLM 的 RLVR 训练中被原样继承，并在其上继续演化出四代算法（#link(<sec-rlvr-lineage>)[第 7.10 节]）——那是同一外壳上的三个坐标，不是第四组变体。

=== 变体一：步长太大就让策略崩坏 —— TRPO 与 PPO

#strong[病灶]：$J(bold(theta))$ 是非凸的，用估计梯度走一大步，参数可能落到一个策略分布与原来几乎无关的位置；轨迹分布随即改变，下一步的梯度估计建立在完全不同的数据上，于是崩坏不可逆。这不是"梯度错了"，而是"步子太大"。目标本身没有问题，问题在于我们只有一个局部线性近似。

#strong[改动]：给每一步加上"策略不能离得太远"的约束。TRPO 在#strong[信任域]内最大化一个用旧数据即可估计的替代目标——它利用重要性采样把新策略的期望回报写成旧策略样本上的加权和，并证明该替代目标的一阶近似等于 $J$ 的梯度，因此在旧策略附近最大化它等于在提升 $J$：
$
  #eqbox([$ max_bold(theta) quad bb(E)_(S tilde.op d^(pi_(bold(theta)_"old")), A tilde.op pi_(bold(theta)_"old")) [frac(pi_bold(theta) (A divides S), pi_(bold(theta)_"old") (A divides S)) hat(A)] quad "s.t." quad bb(E)_(S) [D_"KL" (pi_(bold(theta)_"old") (dot.op divides S) || pi_bold(theta) (dot.op divides S))] <= delta $])
$ <eq-pg-trpo>
这里的比值 $pi_bold(theta) / pi_(bold(theta)_"old")$ 与#link(<sec-importance-sampling>)[第 6.4 节]的离轨权重是同一个东西：用旧策略的样本来评估新策略。PPO 把硬约束换成软惩罚或裁剪，用更便宜的近似达到同样的"别走太远"：
$
  L^upright("CLIP") (bold(theta)) = bb(E) [min(rho_t (bold(theta)) hat(A)_t, "clip"(rho_t (bold(theta)), 1 - epsilon, 1 + epsilon) hat(A)_t)], quad rho_t (bold(theta)) = frac(pi_bold(theta) (A_t divides S_t), pi_(bold(theta)_"old") (A_t divides S_t)) .
$ <eq-pg-ppo-clip>
裁剪的作用是把"已经偏离太多的样本"从梯度里摘出去：一旦 $rho_t$ 越界，目标对该样本不再有梯度，超大步长的收益被截断。

#strong[代价]：TRPO 每步要解一个有约束的优化（实际用共轭梯度与线搜索近似），计算与实现都重；PPO 便宜，但裁剪引入偏差，且 $epsilon$ 的取值直接影响有效步长。两者都#strong[不改]贝尔曼方程的地位——Critic 仍按 @eq-pg-gae 估计优势，贝尔曼方程仍只是估计工具。

=== 变体二：连续动作下 $max$ 无从枚举 —— 确定性策略梯度（DDPG / TD3）

#strong[病灶]：#link(<sec-pg-motivation>)[第 7.2 节]列的第一条困难。在#link(<sec-pg-setup>)[第 7.1 节]的连续动作设定下，$max_a q(s, a)$ 是一个逐状态的优化问题，$arg max$ 没有闭式。随机策略梯度虽然可用，但要对动作积分，方差大。

#strong[改动]：把策略写成#strong[确定性]函数 $mu_bold(theta) (s)$，并用链式法则把动作从 $q$ 里"消掉"：
$
  #eqbox([$ nabla_bold(theta) J(bold(theta)) = bb(E)_(S tilde.op d^(mu_bold(theta))) [nabla_bold(theta) mu_bold(theta) (S)^top nabla_a q^(mu_bold(theta)) (S, a) |_(a = mu_bold(theta) (S))] $])
$ <eq-pg-dpg>
它读作：沿"$q$ 对动作的梯度"方向调整动作，再把这一调整反传到策略参数。动作不再是采样出来的，积分与 $max$ 都消失了。

#strong[代价]：确定性策略只能沿一个方向探索，必须在动作上外加探索噪声（DDPG 用噪声扰动的行为策略采数据，再用离轨数据训练确定性 Actor）——这又回到了#link(<sec-importance-sampling>)[第 6.4 节]的分布错配，只不过在确定性策略下由离轨 $Q$ 学习直接吸收。更深的问题是 $nabla_a q$ 本身是学出来的：$max$ 的高估偏差（#link(<sec-td-action-value>)[第 6.6 节]的 Double Q 所修的那个病灶）在这里变成" Actor 追着被高估的 $q$ 跑"，TD3 因此引入两个 Critic 取较小值并延迟更新 Actor。

=== 变体三：目标本身要"带探索" —— SAC 与软贝尔曼方程

#strong[病灶]：@eq-pg-objective 只奖励回报，不奖励探索。随机策略的熵在训练早期自然较大，但随着 $J$ 上升会迅速塌缩到一个接近确定性的策略，之后梯度信号变弱；更进一步，若最优策略需要保持随机性（如多峰最优、对抗环境），纯回报目标直接把它排除在外。

#strong[改动]：在每一步奖励里加上策略熵，得到一个#strong[最大熵]目标：
$
  #eqbox([$ J_"soft" (bold(theta)) = bb(E)_(pi_bold(theta)) [sum_(t = 0)^oo gamma^t (R_(t + 1) + alpha cal(H) (pi_bold(theta) (dot.op divides S_t)))] $])
$ <eq-pg-sac-objective>
$alpha > 0$ 是熵的温度。这个改动看起来只是加了一项，但它把对象的定义改了：现在要评估的不再是 $v_pi$，而是"软"价值。于是贝尔曼期望方程本身也要改，得到#strong[软贝尔曼方程]：
$
  #eqbox([$ q_"soft"^pi (s, a) = bb(E) [R_(t + 1) + gamma (v_"soft"^pi (S_(t + 1)) - alpha log pi (A_(t + 1) divides S_(t + 1))) divides S_t = s, A_t = a] $]) \
  #eqbox([$ v_"soft"^pi (s) = bb(E)_(A tilde.op pi) [q_"soft"^pi (s, a) - alpha log pi (a divides s)] $])
$ <eq-pg-soft-bellman>
注意它与 @eq-bellman-exp-vv 的差别精确在哪里：右端多了一个 $- alpha log pi$ 项，其余结构（单步奖励 + 折后的后继价值）一模一样。因此它仍是#strong[同一个求解框架]下的方程，可以照第 6 章的方法解——这正是 @tab-pg-bellman-boundary 最后一行说"是，显式例外"的理由。SAC 的实现就是交替：用软贝尔曼方程做 Critic 的一步 TD 更新，再用重参数化技巧对 @eq-pg-sac-objective 做梯度上升。

#strong[代价]：目标换了，最优策略也换了——SAC 求的不是 $pi_star$，而是熵正则下的最优策略；$alpha$ 的取值直接决定"探索换多少回报"，需要调节（实践中让 $alpha$ 随目标熵自动调整，但这已属实现细节，不在本章范围）。

#figure(
  caption: [三组工程变体各自修复的病灶与代价。三者都保留 @eq-pg-theorem-expectation 的梯度形式，改的是"怎么走这一步"或"目标是什么"],
  text(size: 8.6pt, table(
    columns: (0.75fr, 1.5fr, 1.3fr, 1.25fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([变体], [病灶], [改了什么], [代价]),
    table.hline(),
    [TRPO], [步长过大使策略崩坏], [信任域约束，用离轨比值构造替代目标（@eq-pg-trpo）], [每步解约束优化，实现重],
    table.hline(stroke: 0.6pt + accent),
    [PPO], [同上，但要便宜], [裁剪离轨比值（@eq-pg-ppo-clip）], [裁剪引入偏差，有效步长依赖 $epsilon$],
    table.hline(stroke: 0.6pt + accent),
    [DDPG / TD3], [连续动作下 $max$ 无闭式、动作积分方差大], [确定性策略 + 链式法则（@eq-pg-dpg）], [需外加探索噪声；$nabla_a q$ 偏差被 Actor 放大],
    table.hline(stroke: 0.6pt + accent),
    [SAC], [纯回报目标不奖励探索、熵会塌缩], [最大熵目标 + 软贝尔曼方程（@eq-pg-soft-bellman）], [最优策略改变；$alpha$ 需调节],
    table.hline(),
    [REINFORCE / A2C], [（基准，无额外补丁）], [@eq-pg-reinforce-update \/ @eq-pg-ac-update], [高方差；自举偏差],
  )),
) <tab-pg-variants>

#divider()

== 变体一的延伸：大语言模型强化学习中的策略梯度算法族
<sec-rlvr-lineage>

#link(<sec-pg-variants>)[第 7.9 节]的三组变体都在第 7.1 节的设定下修补策略梯度。变体一给出的裁剪外壳（@eq-pg-ppo-clip）没有停在控制任务里：大语言模型的可验证奖励强化学习（Reinforcement Learning from Verifiable Rewards, RLVR）把它原样继承下来，并在其上接连演化出 GRPO、DAPO、GSPO、DCPO 四代算法。本节沿用第 7.9 节的写法（病灶 / 改动 / 代价），同时把它们放进同一个框架：外壳不变，每次只动三个坐标中的某几个。

=== 场景：一条轨迹是一个 token 序列，奖励只在末尾给出

RLVR 的任务形式与第 7.1 节有三处不同，先写清楚，否则后面的公式会被误读：

1. #strong[轨迹是变长 token 序列]：给定 prompt $x$，策略生成回复 $y = (y_1, dots, y_(|y|))$；每个 token 是一个动作，动作空间是词表 $cal(V)$；第 $t$ 步的状态是已生成的前缀 $S_t = (x, y_(<t))$。
2. #strong[回报只在序列末尾给出]：$R(x, y) in [0, 1]$ 由规则校验（答案是否正确）给出，中间没有奖励，折扣因子取 $gamma = 1$。
3. #strong[同一 prompt 采一组回复]：一次生成 $G$ 条 $y_i tilde.op pi_(bold(theta)_"old") (dot.op divides x)$，组内比较几乎免费。

于是序列概率是逐 token 条件概率的乘积：
$
  pi_bold(theta) (y divides x) = product_(t = 1)^(|y|) pi_bold(theta) (y_t divides x, y_(<t)) .
$ <eq-rlvr-seq-prob>

在 $gamma = 1$、奖励只在末尾的设定下，$q_(pi_bold(theta)) (S_t, A_t) = bb(E) [R(x, y) divides S_t, A_t]$ 仍然良定义，但它随前缀变化，而#strong[每个前缀只被采样一次]：第 6.3 节的样本均值在这里没有同状态样本可平均，第 7.6 节的 Critic 也只能给出有偏估计。这条约束决定了后面全部设计——任何算法都必须在"学一个 Critic 逐 token 估计"与"放弃逐 token 差异、只保留序列级的相对好坏"之间选一边。

=== 统一外壳与三个坐标

四代算法共用的目标，是把 @eq-pg-ppo-clip 的裁剪逐 token 套到上面的 token MDP 上，再在外层对组与 token 做两重平均：
$
  J_"RLVR" (bold(theta)) = bb(E)_(x, thin y_i tilde.op pi_(bold(theta)_"old")) [ frac(1, G) sum_(i = 1)^G frac(1, |y_i|) sum_(t = 1)^(|y_i|) min(rho_(i,t) hat(A)_(i,t), "clip"(rho_(i,t), 1 - epsilon_"low", 1 + epsilon_"high") hat(A)_(i,t)) ]
$ <eq-rlvr-shell>
$
  rho_(i,t) (bold(theta)) = frac(pi_bold(theta) (y_(i,t) divides x, y_(i,<t)), pi_(bold(theta)_"old") (y_(i,t) divides x, y_(i,<t))) .
$ <eq-rlvr-token-ratio>

与 @eq-pg-ppo-clip 逐项对照，差别只有三处：内层按 token 展开（第 $t$ 步的动作是 $y_t$）；外层多了一重组与回复的平均；上下界允许不对称（GRPO 取 $epsilon_"low" = epsilon_"high" = epsilon$，DAPO 起拆成两个常数）。与第 6.1 节"三条路线共用同一个更新壳"的判断方式一样，四代算法之间的全部差异都落在三个坐标上：

1. #strong[坐标一：优势 $hat(A)_(i,t)$ 从哪里来]。决定信用分配到什么粒度、是否需要价值网络：Critic 与 GAE（第 7.6--7.7 节）、同一 prompt 的组内相对回报、跨步累积的平滑统计。
2. #strong[坐标二：信任域以什么为单位、边界取什么函数]。决定"多快允许策略移动"与"哪些 token 被裁掉"：单 token 概率比配常数界、整条序列的似然比配常数界、单 token 概率比配依赖旧概率的界。
3. #strong[坐标三：损失怎么归一化]。决定长回复与短回复的相对权重：先组内再回复内（$frac(1, G) sum_i frac(1, |y_i|) sum_t$）、批内 token 等权（$frac(1, sum_i |y_i|) sum_i sum_t$）、只在回复内平均（$sum_i frac(1, |y_i|) sum_t$）。

三个坐标之外还有一个外围开关：与参考策略的 KL 惩罚。它在 RLHF 里承担"不要偏离初始模型"的职责，服务于对齐；RLVR 的奖励来自规则校验，不存在奖励模型被攻破的问题，因此从 DAPO 起被关掉（四代里只有 GRPO 保留）。@fig-rlvr-lineage 把这条线与每次动到的坐标画在一起。

#figure(
  {
    set par(justify: false)
    diagram(
      spacing: (12mm, 6mm),
      node-stroke: 0.75pt + accent,
      edge-stroke: 0.7pt + accent,
      node-inset: 4.5pt,
      node-corner-radius: 3pt,
      node((0, 0), text(size: 7.8pt)[*不变量：PPO 裁剪外壳*（@eq-pg-ppo-clip） \ 逐 token 取 $min(rho_(i,t) hat(A)_(i,t), "clip"(rho_(i,t), 1 - epsilon_"low", 1 + epsilon_"high") hat(A)_(i,t))$ \ 信任域由 TRPO 的 KL 硬约束换成比值裁剪], fill: accent-soft, width: 96mm),
      node((0, 1), text(size: 7.4pt)[*PPO（RLHF）*：Critic + GAE 逐 token 估优势，每个 prompt 一条回复 \ 代价：价值网络与策略同规模；前缀只采样一次，拟合误差直接进入梯度], width: 96mm),
      node((0, 2), text(size: 7.4pt)[*GRPO*：坐标一 —— 组内标准化的回报广播为该回复各 token 的常数优势（@eq-rlvr-group-adv） \ 代价：序列内信用分配消失；同奖励组零梯度；$1 / sigma$ 与 $1 / |y_i|$ 引入的偏差], width: 96mm),
      node((0, 3), text(size: 7.4pt)[*DAPO*：坐标二、三 + 数据层 —— 非对称裁剪、批内 token 等权（@eq-rlvr-dapo-loss）、动态采样、超长奖励整形；关掉 KL \ 代价：整组样本被丢弃], width: 96mm),
      node((0, 4), text(size: 7.4pt)[*GSPO*：坐标二 —— 单位换成序列似然比（@eq-rlvr-gspo-ratio），序列级裁剪，$epsilon$ 降到 $10^(-4)$ 量级 \ 代价：比值有偏；整条回复一起被裁], width: 96mm),
      node((0, 5), text(size: 7.4pt)[*DCPO*：坐标一、二、三 —— 边界写成旧概率的函数（@eq-rlvr-dcpo-bounds），优势跨步平滑，损失只在回复内平均 \ 代价：依赖旧概率的可靠估计，边界须设上限兜底], width: 96mm),
      edge((0, 0), (0, 1), "->"),
      edge((0, 1), (0, 2), "->", text(size: 6.6pt)[坐标一], label-side: right),
      edge((0, 2), (0, 3), "->", text(size: 6.6pt)[坐标二、三 + 数据层], label-side: right),
      edge((0, 3), (0, 4), "->", text(size: 6.6pt)[坐标二], label-side: right),
      edge((0, 4), (0, 5), "->", text(size: 6.6pt)[坐标一、二、三], label-side: right),
    )
  },
  caption: [变体一的裁剪外壳在大语言模型 RLVR 中的四代延伸：外壳 @eq-rlvr-shell 不变，每次只动三个坐标中的某几个。边上的标注是该代算法动到的坐标，代价一栏是这次改动新引入的问题],
) <fig-rlvr-lineage>

=== 第一代：GRPO —— 把 Critic 换成组内基线

#strong[病灶]：@tab-pg-advantage-estimators 里偏差最小的一档是 GAE，而 GAE 需要一个通常与策略同规模的价值网络，在 LLM 上意味着显存与算力翻倍。更根本的是上面那条约束：$q_(pi_bold(theta)) (S_t, A_t)$ 随前缀变化，每个前缀却只出现一次，Critic 的拟合误差无法靠同状态的多样本平均消掉；第 7.6 节已指出，这个误差直接乘在 $nabla_bold(theta) log pi_bold(theta)$ 上，是梯度偏差，不是可以靠多跑几步摊平的噪声。

#strong[改动]：放弃逐 token 的优势，只保留序列级的相对好坏。对同一 prompt 的 $G$ 条回复，用组内标准化后的回报作为该回复内所有 token 的常数优势：
$
  hat(A)_i = frac(R_i - mu, sigma), quad mu = frac(1, G) sum_(j = 1)^G R_j, quad sigma = sqrt(frac(1, G) sum_(j = 1)^G (R_j - mu)^2), quad hat(A)_(i,t) eq.dot hat(A)_i .
$ <eq-rlvr-group-adv>

这不是新原理，而是#link(<sec-pg-baseline>)[第 7.5 节]基线补丁的极限形式：基线从 $b(s) = hat(v)(s)$ 换成"同一 prompt 其他回复的平均回报"。命题 7.2 保证只依赖状态、不依赖动作的基线不改变梯度期望。严格地说，$mu$ 含 $R_i$ 自身，与留一均值 $(1 / (G - 1)) sum_(j eq.not i) R_j$ 相比，@eq-rlvr-group-adv 只是整体乘了 $(G - 1) / G$；再除以随机的 $sigma$ 还会引入非线性的小偏差。$G$ 通常取 $8$--$64$，这两处偏差都小于提高采样数换来的方差收益。

#block(breakable: false, above: 1em)[
#strong[代价]：三条，后两代算法逐条对应。

1. #strong[序列内信用分配消失]：$hat(A)_(i,t)$ 在一条回复内是常数，"这一步算对了、那一步算错了"在梯度里没有区别。
2. #strong[零梯度]：组内回报全相等时 $sigma = 0$，所有 $hat(A)_i = 0$，这个 prompt 贡献零梯度。全对与全错都会落进这个状态，而全对的组在训练中越往后越多。
3. #strong[归一化偏差]：$1 / sigma$ 放大"同组内难题"（$sigma$ 小）的梯度，$1 / |y_i|$ 让短回复的每个 token 权重更大——两者都与"这个 token 有多重要"无关。
]

=== 第二代：DAPO —— 坐标二、坐标三各一处，外加两处数据层补丁

#strong[病灶]：GRPO 的三条代价在长链推理场景下同时放大；此外还有第四条——生成长度有上限，被截断的回复既拿不到正确的奖励，也不是策略真实的选择，它的回报是噪声。

#strong[改动]：@eq-rlvr-shell 的骨架一字未动，改的是坐标二、坐标三各一处，外加两处数据层补丁与一个开关。

1. #strong[坐标二：不对称裁剪（Clip-Higher）]。取 $epsilon_"low" = 0.2$、$epsilon_"high" = 0.28$。下界保持保守：放宽下界会把负优势 token 的概率继续压向 $0$，直接缩小采样空间。上界放宽：正优势的低概率 token 被 $1 + epsilon$ 卡住，而把低概率 token 抬起来正是探索的来源。原先固定对称的 $epsilon$ 造成的那种"分布越收越紧"，即熵坍缩，就此松开。
2. #strong[坐标三：token 级损失]。把外层平均换成批内 token 等权：
   $
     L_"DAPO" (bold(theta)) = frac(1, sum_(i = 1)^G |y_i|) sum_(i = 1)^G sum_(t = 1)^(|y_i|) min(rho_(i,t) hat(A)_i, "clip"(rho_(i,t), 1 - epsilon_"low", 1 + epsilon_"high") hat(A)_i) .
   $ <eq-rlvr-dapo-loss>
   GRPO 的 $1 / |y_i|$ 使短回复的每个 token 权重更大。在长链推理里，冗长而正确的回复与简短而错误的回复被同等看待时，前者的有效信号会被稀释；批内等权让权重与 token 数成正比。
3. #strong[数据层：动态采样]。把组内全对或全错的 prompt 整组丢弃，保证每个 micro-batch 里的组都有非零方差。治的是 GRPO 的第二条代价，方式是"不进梯度就不参与"。
4. #strong[数据层：超长奖励整形]。超过期望长度后按缓存区间线性扣分至 $-1$，并屏蔽被截断样本的损失项。
5. #strong[开关：关掉 KL 惩罚]。理由见第 7.10.2 节。

#strong[代价]：动态采样把已经生成的整组扔掉——同样的更新步数需要多采 3--5 倍回复，这是最直接的代价；上界放宽后单步允许的策略位移变大，需要靠 $sigma$ 归一化与下界继续约束。

=== 第三代：GSPO —— 信任域的单位从 token 换成序列

#strong[病灶]：@eq-rlvr-shell 的比值逐 token 定义，而这里被优化的目标是#strong[整条回复]的期望：$J(bold(theta)) = bb(E) [R(x, y)]$，重要性权重理应是序列似然比。用逐 token 的比值去裁剪，等于对一条回复施加 $|y_i|$ 个彼此独立的约束，它们的松紧由各 token 的局部漂移决定，互相不一致。这条错配在三个地方显形：

- 序列似然比的方差随 $|y_i|$ 累积（@eq-importance-sampling-ratio 的连乘结构），逐 token 的裁剪管不住整体漂移；
- 训练与推理引擎各自前向，逐 token 的数值差在长序列上累积；
- MoE 模型的路由在两次前向之间会变，同一 token 的比值因此抖动，GRPO 必须额外开 Routing Replay 才能收敛。

#strong[改动]：只换坐标二的单位。定义长度归一化的序列似然比（几何平均），并在序列级裁剪：
$
  s_i (bold(theta)) = (frac(pi_bold(theta) (y_i divides x), pi_(bold(theta)_"old") (y_i divides x)))^(1 / |y_i|) = exp(frac(1, |y_i|) sum_(t = 1)^(|y_i|) log frac(pi_bold(theta) (y_(i,t) divides x, y_(i,<t)), pi_(bold(theta)_"old") (y_(i,t) divides x, y_(i,<t)))) ,
$ <eq-rlvr-gspo-ratio>
$
  J_"GSPO" (bold(theta)) = bb(E) [ frac(1, G) sum_(i = 1)^G min(s_i hat(A)_i, "clip"(s_i, 1 - epsilon, 1 + epsilon) hat(A)_i) ] .
$ <eq-rlvr-gspo-objective>
优势不变，仍是 @eq-rlvr-group-adv，作为常数作用到整条回复的每个 token。

$epsilon$ 的量级也跟着变了，这一点容易被忽略：$s_i$ 是"平均对数比"的指数，合理的信任域尺度是"整条回复的平均对数似然漂移"，不是"单个 token 的比值"。实测取值在 $3 times 10^(-4)$ 到 $4 times 10^(-4)$ 量级；若沿用 $0.2$，在这个尺度上几乎不触发裁剪，等于没有信任域。

#block(breakable: false, above: 1em)[
#strong[代价]：

1. #strong[$s_i$ 是有偏代理]：几何平均不是似然比。真实比值是 $s_i^(|y_i|)$，两者随长度拉开，目标因此不再精确等于 $J(bold(theta))$。
2. #strong[裁剪以整条回复为单位]：$s_i$ 越界时，该回复的所有 token 一起失去这个方向的梯度，同一条回复里可用的信息 token 被一并丢掉。
3. #strong[平均抹掉局部极端]：序列级比值把各 token 的漂移平均，个别 token 的极端漂移不再被单独约束——这正是 DCPO 要拿回来的东西。
]

=== 第四代：DCPO —— 裁剪边界变成旧概率的函数

#strong[病灶]：坐标二的边界一直是常数，而同样的比值偏移在低概率 token 上对应的概率质量变化要小得多：$q = 0.9$ 与 $q = 0.01$ 处各允许比值变动 $0.28$，概率质量的变化差两个数量级。低概率（高熵）token 恰恰是推理分支的载体，把它们压在 $1 + epsilon$ 以内，等于把探索限制在高置信区。GSPO 换成序列单位后更没有解决这一点：它整条回复一起裁。

#strong[改动]：三个坐标各动一处，@eq-rlvr-shell 的骨架仍然没动。

1. #strong[坐标二：边界随旧概率变化]。把约束从"比值偏差"换成"概率质量加权的偏差"：$|(rho - 1) p| <= epsilon$，其中 $p = rho q$ 是新概率，$q = pi_(bold(theta)_"old") (y_t divides x, y_(<t))$ 是旧概率。代入后是关于 $rho$ 的两条二次不等式，解出
   $
     0.5 + 0.5 sqrt(max(1 - frac(4 epsilon_"low", q), 0)) <= rho <= 0.5 + 0.5 sqrt(1 + frac(4 epsilon_"high", q)) .
   $ <eq-rlvr-dcpo-bounds>
   $q arrow.r 0$ 时上界按 $0.5 + sqrt(epsilon_"high" / q)$ 增长、下界趋于 $0.5$；$q$ 大时上下界回到 $1 - epsilon$ 与 $1 + epsilon$ 的量级。低置信尾部的更新区间被放宽，高置信区基本不动——TRPO 的信赖域本来想约束的就是#strong[概率质量]的变化，而不是比值本身。另对上下界设硬上限 $10$，防止 $q arrow.r 0$ 时约束失效。
2. #strong[坐标一：跨步平滑的优势（SAS）]。组内标准化只用当前步的 $G$ 条回复，全对或全错时优势为零。取当前步标准化 $hat(A)_"cur"$ 与同一 prompt 历史累积标准化 $hat(A)_"tot"$ 的按步加权平均，再取绝对值较小者：
   $
     hat(S)_"cur" = frac(k - 1, k) hat(A)_"cur" + frac(1, k) hat(A)_"tot", quad hat(S)_"tot" = frac(1, k) hat(A)_"cur" + frac(k - 1, k) hat(A)_"tot" .
   $ <eq-rlvr-sas>
   其中 $k$ 是该 prompt 已经历的优化步数。训练前期信当前步，后期信累积分布；取绝对值较小者是保守选择，压制单步统计的抖动。组内回报全同时优势不再恒为零，信号由历史分布补上——这与 DAPO 的"丢组"是同一个病灶的两种处置。
3. #strong[坐标三：只在回复内平均]。
   $
     L_"DCPO" (bold(theta)) = sum_(i = 1)^G frac(1, |y_i|) sum_(t = 1)^(|y_i|) min(rho_(i,t) hat(A)_(i,t), "clip"(rho_(i,t), b_"low" (q_(i,t)), b_"high" (q_(i,t))) hat(A)_(i,t)) ,
   $ <eq-rlvr-dcpo-loss>
   其中 $b_"low"$、$b_"high"$ 取自 @eq-rlvr-dcpo-bounds。批内等权（DAPO）会让长回复在总损失里占更大份额，即使它的优势更小：一条优势 $1$、长度 $500$ 的回复与一条优势 $0.5$、长度 $1500$ 的回复，在批内等权下的贡献是 $0.25$ 对 $0.375$。标准化后的优势本身已经含了跨回复的相对关系，再乘一次长度权重就把它改掉了。

#block(breakable: false, above: 1em)[
#strong[代价]：

1. 边界依赖 $q$，旧策略的逐 token 概率必须可靠——这与 GSPO 想避免的数值敏感性正好相反。
2. $1 / sqrt(q)$ 在 $q arrow.r 0$ 时发散，必须靠上限 $10$ 兜底，上限本身是新的超参数。
3. 三处常数（下界、上界、硬上限）都要标定，而边界随训练进程移动（$q$ 的分布整体向高置信区移动），超参的可迁移性比常数边界差。
]

=== 同框架下的汇总与未收敛的分歧

@tab-rlvr-lineage 按第 7.9 节的格式把四代算法并排放置：改动一栏标出动到的坐标，代价一栏写这次改动新引入的问题。

#figure(
  caption: [四代 RLVR 算法在同一裁剪外壳上的改动与代价。四者共用 @eq-rlvr-shell 的骨架，差别落在优势来源（坐标一）、信任域的单位与边界（坐标二）、损失的归一化（坐标三）上；标注"数据层"的改动不在三个坐标内，它改的是进入 batch 的数据本身],
  text(size: 8.4pt, table(
    columns: (0.6fr, 1.5fr, 1.65fr, 1.35fr),
    align: (left + horizon, left + horizon, left + horizon, left + horizon),
    table.header([代], [病灶], [改了什么（动到的坐标）], [代价]),
    table.hline(),
    [PPO（RLHF）], [逐 token 优势依赖 Critic；价值网络通常与策略同规模，拟合误差直接进入梯度], [（基准）Critic + GAE 逐 token 估优势（@eq-pg-gae），每个 prompt 一条回复], [显存与算力翻倍；前缀只采样一次，价值误差无法靠同状态平均消掉],
    table.hline(stroke: 0.6pt + accent),
    [GRPO], [同上，且逐 token 的条件期望无样本可估], [坐标一：组内标准化的回报广播为该回复的常数优势（@eq-rlvr-group-adv）], [信用分配消失；同奖励组零梯度；$1 / sigma$ 与 $1 / |y_i|$ 引入难度与长度偏差],
    table.hline(stroke: 0.6pt + accent),
    [DAPO], [熵坍缩；零梯度组；长度偏差；截断样本的奖励噪声], [坐标二、三 + 数据层：非对称裁剪 $0.2$ 与 $0.28$、批内 token 等权（@eq-rlvr-dapo-loss）、动态采样、超长奖励整形；关掉 KL], [整组样本被丢弃，同更新步数需 3--5 倍生成量；单步允许的位移变大],
    table.hline(stroke: 0.6pt + accent),
    [GSPO], [序列级奖励配 token 级比值：方差随长度累积，MoE 路由抖动使比值不稳], [坐标二：单位换成序列似然比（@eq-rlvr-gspo-ratio），序列级裁剪，$epsilon$ 降到 $10^(-4)$ 量级], [比值有偏；整条回复一起被裁；局部极端漂移被平均掉],
    table.hline(stroke: 0.6pt + accent),
    [DCPO], [常数边界对低概率 token 过紧；整条裁剪浪费可用 token；零梯度仍未解], [坐标一、二、三：边界写成 $q$ 的函数（@eq-rlvr-dcpo-bounds）、优势跨步平滑（@eq-rlvr-sas）、损失只在回复内平均（@eq-rlvr-dcpo-loss）], [依赖旧概率的可靠估计；$1 / sqrt(q)$ 需上限兜底；边界随训练移动，超参难迁移],
  )),
) <tab-rlvr-lineage>

三点结论：

1. #strong[与贝尔曼方程的边界继续后退]。@tab-pg-bellman-boundary 里，策略梯度各族至少还把贝尔曼方程当作估计工具；RLVR 族把 Critic 一并去掉后，$A = q - v$ 的定义被组内基线替换，$v$ 不再被估计，贝尔曼方程连"估计工具"这层角色都不再出现。这是本章唯一一条贝尔曼方程完全不进入梯度估计的路线。
2. #strong[坐标二从一个常数变成两个自由度]。变体一只有 $epsilon$ 一个旋钮；这条线上先后拆出了单位（token 比与序列比）与边界函数（常数与依赖旧概率），DCPO 的边界还随训练进程变化。
3. #strong[分歧没有收敛]。比值粒度（token 级对序列级）、边界形态（常数对概率自适应）、零梯度处置（丢组对补统计量）三点上，GSPO 与 DCPO 恰好互为反例：前者认为 token 级比值是噪声源，后者认为序列级裁剪才是浪费。四代算法改变的是同一外壳上的三个坐标，而不是从一个新的目标函数一次导出——这一代仍处在"逐个修补"的阶段。

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
将贝尔曼期望方程与贝尔曼最优方程、状态价值 $V$ 与动作价值 $Q$ 两类对象，以及#link(<sec-value-estimation>)[第 6 章]的三类期望估计方法（不动点迭代、蒙特卡洛样本均值、Robbins-Monro 随机近似）组合，再配合广义策略迭代（Generalized Policy Iteration, GPI）与参数化函数近似，可得到从表格型方法到深度强化学习（Deep RL）的主要算法。各估计方法结合贝尔曼期望 / 最优方程导出的状态价值与动作价值算法见 @fig-rl-genealogy，对应的更新公式见 @tab-all-value-estimators。图中最下一层是#link(<sec-policy-gradient>)[第 7 章]的旁支：它不再解贝尔曼方程，而是直接对期望回报目标求导，贝尔曼方程只以"优势定义 + Critic 的价值估计"的形式留在梯度估计里（唯一的显式例外是 SAC 的软贝尔曼方程）。

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

      // 第 6 层：策略梯度旁支（不解方程，直接对期望回报目标求导）
      node((1, 6), text(size: 7.6pt)[*策略梯度旁支*（第 7 章）：*不解贝尔曼方程* \ 求解对象是 $max_bold(theta) J(bold(theta))$ 而非 $x = cal(T) x$ \ 贝尔曼方程只作为优势定义与 Critic 的价值估计工具 \ 唯一例外：SAC 的软贝尔曼方程], fill: hl-amber-fill, stroke: 0.85pt + hl-amber-stroke, width: 66mm),
      edge((0, 5), (1, 6), "<->", stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.7pt), text(size: 6.5pt)[同一算法 \ 两种视角], label-side: left),
      edge((2, 5), (1, 6), "<->", stroke: (dash: "dashed", paint: hl-amber-stroke, thickness: 0.7pt), text(size: 6.5pt)[同一算法 \ 两种视角], label-side: right),
    )
  },
  caption: [强化学习算法关联谱系：左框为预测 / 评估类算法（对应贝尔曼期望方程），右框为控制类算法（对应贝尔曼最优方程或 GPI 外环）；中列三类期望估计方法分别作用于显式展开式（DP）、价值定义（MC，不经贝尔曼方程）与条件期望式（TD），最下行为函数近似延伸。右下节点按价值式控制谱系归类，DDPG / TD3 / SAC 的 Critic 求解的是（软）期望方程；最底行的策略梯度旁支改为直接对期望回报目标求导，含 Actor 的算法（A2C / PPO / DDPG / TD3 / SAC）同时属于该支],
) <fig-rl-genealogy>

策略梯度旁支并没有停在 PPO：在大语言模型的 RLVR 训练中，它继续演化出 GRPO、DAPO、GSPO、DCPO 四代算法（#link(<sec-rlvr-lineage>)[第 7.10 节]）。它们把 Critic 一并去掉，贝尔曼方程不再以任何形式进入梯度估计——@tab-pg-bellman-boundary 为此单列了一行。

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
