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

在强化学习经典文献（如 Sutton & Barto《强化学习：导论》）中，贝尔曼方程通常以两种等价的数学形式出现：一是以条件期望表征的#strong[紧凑形式]（基于全期望公式与塔性质），二是以状态转移概率与策略分布显式求和表征的#strong[展开形式]（基于全概率公式与链式法则）。本笔记严格区分并打通这两条推导路径，按“先单步桥接（$v arrow.r q$、$q arrow.r v$）、后复合自递推（$v arrow.r v$、$q arrow.r q$）”的统一逻辑组织全文，核心对照见 @tab-overview。

为突出公式中的核心结构，全文采用三色标记高亮关键数学项：$mhl(pi(a divides s) \/ max_a)$（琥珀色）标记#strong[策略层算子或核心变换]，$mhlb(S_(t+1) \/ p(g divides s'))$（浅蓝色）标记#strong[新引入的条件变量或马尔可夫条件独立化简项]，$mhlg(v_pi (S_(t+1)) \/ q_star (s', a'))$（浅绿色）标记#strong[后继时刻的价值递推项]。

#figure(
  caption: [贝尔曼期望方程与贝尔曼最优方程的总体对照（以状态价值自递推 $v arrow.r v$ 为例）],
  table(
    columns: (auto, auto, 1fr),
    table.header([方程类别与性质], [形式], [$v arrow.r v$ 方程]),
    table.hline(),
    table.cell(rowspan: 2)[#strong[贝尔曼期望方程] \ 任意固定策略 $pi$ \ 价值函数的#strong[线性]方程组],
    [条件期望形式],
    [$ v_pi (s) = bb(E)_pi [R_(t + 1) + gamma #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $],
    [显式展开形式],
    [$ v_pi (s) = sum_a #mhl($pi(a divides s)$) [sum_r p(r divides s, a) r + gamma sum_(s') p(s' divides s, a) #mhlg($v_pi (s')$)] $],
    table.cell(rowspan: 2)[#strong[贝尔曼最优方程] \ 最优策略 $pi_star$ \ 价值函数的#strong[非线性]方程组],
    [条件期望形式],
    [$ v_star (s) = #mhl($max_a$) bb(E) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
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

#strong[记号约定]：$bb(E)_pi [dot.op]$ 表示智能体遵循策略 $pi$ 时的数学期望；全文所有条件概率均在该前提下书写（在不引起歧义时，常将 $Pr_pi (X = x divides Y = y)$ 简记为 $p(x divides y)$）。

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

$ v_pi (s) eq.dot bb(E)_pi [#mhlg($G_t$) divides #mhlb($S_t = s$)] . $ <eq-v-def>

#strong[定义 1.3（动作价值函数）] <def-1.3> 智能体在状态 $s in cal(S)$ 下执行动作 $a in cal(A)$，此后遵循策略 $pi$ 所获得的期望回报，称为动作价值函数：

$ q_pi (s, a) eq.dot bb(E)_pi [#mhlg($G_t$) divides #mhlb($S_t = s, thin A_t = a$)] . $ <eq-q-def>

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
  #strong[用途]：当 $|R_k| lt.eq R_max$ 且 $gamma in [0, 1)$ 时，由 @eq-return-bound 知 $sum_(k = 1)^oo gamma^(k - 1) bb(E) [ abs(R_(t + k)) ] lt.eq frac(R_max, 1 - gamma) < oo$。这保证了价值函数 $v_pi (s) = bb(E)_pi [G_t divides S_t = s]$ 的良定义性，且对 $G_t = R_(t + 1) + gamma G_(t + 1)$ 两边取期望后拆分为两项之和是严格成立的。

#divider()

== 马尔可夫性与条件独立化简（性质 P14，引理 3）
<sec-markov-lemma3>
- #strong[P14（马尔可夫性，Markov Property）]：MDP 的定义性假设是“给定当前状态与动作后，未来与历史条件独立”，即下一时刻状态与奖励的分布仅取决于当前状态 $S_t$ 和动作 $A_t$，而与更早的历史轨迹无关：
  $
    Pr(S_(t + 1) = s', R_(t + 1) = r divides S_t, A_t, S_(t - 1), dots.h, S_0, A_0) = #mhlb($Pr(S_(t + 1) = s', R_(t + 1) = r divides S_t, A_t)$) .
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
    #eqbox([$ bb(E)_pi [G_(t + 1) divides #mhlb($S_t, A_t, S_(t + 1)$)] = bb(E)_pi [G_(t + 1) divides #mhlb($S_(t + 1)$)] = #mhlg($v_pi (S_(t + 1))$) $])
  $ <eq-lem-3b>

#divider()

// ============================================================
//  第 3 章：贝尔曼期望方程（条件期望形式）
// ============================================================
= 贝尔曼期望方程（条件期望形式）
<sec-bellman-exp-cond>
本章从价值函数的定义出发，结合#strong[回报一步递推关系]（#link(<prop-1.1>)[命题 1.1]）、#strong[条件全期望公式]（#link(<lem-2>)[引理 2]）与#strong[马尔可夫性]（#link(<lem-3>)[引理 3] 结论 B），推导四条条件期望形式的贝尔曼期望方程（汇总见 @tab-bellman-exp-cond）。

为体现两层随机性的内在生成逻辑，本章与后续章节统一按照#strong[“先单步桥接（$v_pi arrow.r q_pi$、$q_pi arrow.r v_pi$），后复合自递推（$v_pi arrow.r v_pi$、$q_pi arrow.r q_pi$）”]#strong[]的顺序展开。

#figure(
  caption: [贝尔曼期望方程（条件期望形式）的四类递推关系汇总（各式对所有 $s in cal(S)$ 或 $(s, a) in cal(S) times cal(A)$ 成立）],
  table(
    columns: (auto, 1fr),
    table.header([递推关系], [贝尔曼期望方程（条件期望形式）]),
    table.hline(),
    [$v_pi arrow.r q_pi$ \\ #text(size: 8.2pt, fill: muted)[策略层单步转换]],
    [$ v_pi (s) = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] $],
    [$q_pi arrow.r v_pi$ \\ #text(size: 8.2pt, fill: muted)[环境层单步转换]],
    [$ q_pi (s, a) = bb(E)_pi [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$v_pi arrow.r v_pi$ \\ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ v_pi (s) = bb(E)_pi [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $],
    [$q_pi arrow.r q_pi$ \\ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ q_pi (s, a) = bb(E)_pi [R_(t + 1) + gamma thin #mhl($bb(E)_(A_(t + 1) tilde.op pi(dot.op divides S_(t + 1)))$) [#mhlg($q_pi (S_(t + 1), A_(t + 1))$)] thin divides thin S_t = s, A_t = a] $],
  ),
) <tab-bellman-exp-cond>

#divider()

== 状态价值关于动作价值的表示（$v_pi arrow.r q_pi$）
<sec-cond-vq>
#strong[定理 3.1（$v_pi$ 关于 $q_pi$ 的贝尔曼期望方程）] <thm-3.1> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，状态价值等于动作价值在策略分布 $pi(dot.op divides s)$ 下的期望：

$
  #eqbox([$ v_pi (s) = bb(E)_pi [#mhlg($q_pi (S_t, A_t)$) divides S_t = s] = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] $])
$ <eq-bellman-exp-vq>

#strong[证明]：本式不涉及时间步推进，只需在 $v_pi (s)$ 的定义式（@eq-v-def）中应用#link(<lem-2>)[引理 2]（取 $X = G_t, Y = S_t, Z = A_t$），引入当前动作 $A_t$ 作为内层条件：

$
  v_pi (s) & eq.dot bb(E)_pi [G_t divides S_t = s] \
  & = bb(E)_pi [bb(E)_pi [G_t divides S_t = s, #mhlb($A_t$)] thin divides thin S_t = s] quad #[（由#link(<lem-2>)[引理 2] 引入动作条件 $A_t$）] \
  & = bb(E)_pi [#mhlg($q_pi (s, A_t)$) divides S_t = s] quad #[（由#link(<def-1.3>)[定义 1.3]：$bb(E)_pi [G_t divides S_t = s, A_t = a] = q_pi (s, a)$）] \
  & = #mhl($bb(E)_(A_t tilde.op pi(dot.op divides s))$) [#mhlg($q_pi (s, A_t)$)] . #h(2em) square.filled.medium
$

#strong[含义]：状态价值等于在该状态下按策略 $pi(dot.op divides s)$ 选择各动作时动作价值的加权平均。@eq-bellman-exp-vq 只涉及#strong[策略层]的动作采样，不涉及环境状态转移。

#divider()

== 动作价值关于状态价值的表示（$q_pi arrow.r v_pi$）
<sec-cond-qv>
#strong[定理 3.2（$q_pi$ 关于 $v_pi$ 的贝尔曼期望方程）] <thm-3.2> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，有：

$
  #eqbox([$ q_pi (s, a) = bb(E)_pi [#mhl($R_(t + 1)$) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] $])
$ <eq-bellman-exp-qv>

#strong[证明]：
+ #strong[代入回报递推式并做线性拆分]：由动作价值定义（@eq-q-def）、回报一步递推式（@eq-return-recursion）与#link(<lem-1>)[引理 1]：
  $
    q_pi (s, a) & eq.dot bb(E)_pi [G_t divides S_t = s, A_t = a] = bb(E)_pi [#mhl($R_(t + 1) + gamma G_(t + 1)$) divides S_t = s, A_t = a] \
    & = bb(E)_pi [R_(t + 1) divides S_t = s, A_t = a] + gamma thin bb(E)_pi [G_(t + 1) divides S_t = s, A_t = a] .
  $
+ #strong[引入后继状态 $S_(t + 1)$ 并应用马尔可夫性]：对第二项应用#link(<lem-2>)[引理 2]（取 $Y = (S_t, A_t), Z = S_(t + 1)$）加细条件，再由#link(<lem-3>)[引理 3] 结论 B（@eq-lem-3b）省去已知 $S_(t + 1)$ 下多余的历史条件 $(S_t = s, A_t = a)$：
  $
    bb(E)_pi [G_(t + 1) divides S_t = s, A_t = a] & = bb(E)_pi [bb(E)_pi [G_(t + 1) divides S_t = s, A_t = a, #mhlb($S_(t + 1)$)] thin divides thin S_t = s, A_t = a] \
    & = bb(E)_pi [#mhlb($bb(E)_pi [G_(t + 1) divides S_(t + 1)]$) thin divides thin S_t = s, A_t = a] = bb(E)_pi [#mhlg($v_pi (S_(t + 1))$) divides S_t = s, A_t = a] .
  $
+ #strong[代回合并]：将第 2 步代回第 1 步并由#link(<lem-1>)[引理 1] 合并两项期望，即得 @eq-bellman-exp-qv。$square.filled.medium$

#strong[含义]：由于当前动作 $A_t = a$ 已经给定，@eq-bellman-exp-qv 右端的一步随机性#strong[仅来自环境的状态转移与奖励] $(S_(t + 1), R_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$，策略 $pi$ 的影响已全部封装在后继状态价值 $v_pi (S_(t + 1))$ 内部。

#divider()

== 状态价值的自递推（$v_pi arrow.r v_pi$）
<sec-cond-vv>
#strong[定理 3.3（状态价值的贝尔曼期望方程）] <thm-3.3> 对任意固定策略 $pi$ 与状态 $s in cal(S)$，状态价值函数满足：

$ #eqbox([$ v_pi (s) = bb(E)_pi [#mhl($R_(t + 1)$) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] $]) $ <eq-bellman-exp-vv>

#strong[证明（方法一：由单步桥接定理复合导出）]：将#link(<thm-3.2>)[定理 3.2]（@eq-bellman-exp-qv）代入#link(<thm-3.1>)[定理 3.1]（@eq-bellman-exp-vq），再应用#link(<lem-2>)[引理 2] 消去内层条件 $A_t$：
$
  v_pi (s) & = bb(E)_pi [q_pi (S_t, A_t) divides S_t = s] = bb(E)_pi [bb(E)_pi [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s, #mhlb($A_t$)] thin divides thin S_t = s] \
  & = bb(E)_pi [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] . #h(2em) square.filled.medium
$

#strong[证明（方法二：直接引入 $S_(t + 1)$ 应用塔性质）]：亦可不经过 $q_pi$，直接从 $v_pi (s) eq.dot bb(E)_pi [G_t divides S_t = s]$ 出发，由#link(<prop-1.1>)[命题 1.1] 与#link(<lem-1>)[引理 1] 拆分为两项后，对第二项应用#link(<lem-2>)[引理 2]（取 $Z = S_(t + 1)$）与#link(<lem-3>)[引理 3] 结论 B：
$
  v_pi (s) & = bb(E)_pi [R_(t + 1) divides S_t = s] + gamma thin bb(E)_pi [bb(E)_pi [G_(t + 1) divides S_t = s, #mhlb($S_(t + 1)$)] thin divides thin S_t = s] \
  & = bb(E)_pi [R_(t + 1) divides S_t = s] + gamma thin bb(E)_pi [#mhlg($v_pi (S_(t + 1))$) divides S_t = s] = bb(E)_pi [R_(t + 1) + gamma thin #mhlg($v_pi (S_(t + 1))$) divides S_t = s] . #h(1.5em) square.filled.medium
$

#strong[含义]：状态 $s$ 的价值，等于从 $s$ 出发执行一步交互所获得的即时奖励 $R_(t + 1)$ 加上折扣后下一状态价值 $gamma v_pi (S_(t + 1))$ 的条件期望。

#divider()

== 动作价值的自递推（$q_pi arrow.r q_pi$）
<sec-cond-qq>
#strong[定理 3.4（动作价值的贝尔曼期望方程）] <thm-3.4> 对任意固定策略 $pi$ 及状态-动作对 $(s, a) in cal(S) times cal(A)$，动作价值函数满足：

$
  #eqbox([$ q_pi (s, a) = bb(E)_pi [R_(t + 1) + gamma thin #mhl($bb(E)_(A_(t + 1) tilde.op pi(dot.op divides S_(t + 1)))$) [#mhlg($q_pi (S_(t + 1), A_(t + 1))$)] thin divides thin S_t = s, A_t = a] $])
$ <eq-bellman-exp-qq>

#strong[证明]：对下一时刻状态 $S_(t + 1)$ 应用#link(<thm-3.1>)[定理 3.1]（将时间下标由 $t$ 平移为 $t + 1$），有：
$ v_pi (S_(t + 1)) = bb(E)_pi [q_pi (S_(t + 1), A_(t + 1)) divides S_(t + 1)] = #mhl($bb(E)_(A_(t + 1) tilde.op pi(dot.op divides S_(t + 1)))$) [#mhlg($q_pi (S_(t + 1), A_(t + 1))$)] . $
将其代入#link(<thm-3.2>)[定理 3.2]（@eq-bellman-exp-qv）右端的 $v_pi (S_(t + 1))$，即得 @eq-bellman-exp-qq。若再利用#link(<lem-2>)[引理 2] 将内外两层条件期望合并，也可简写为单层条件期望形式：
$
  q_pi (s, a) = bb(E)_pi [R_(t + 1) + gamma thin #mhlg($q_pi (S_(t + 1), A_(t + 1))$) divides S_t = s, A_t = a] . #h(2em) square.filled.medium
$ <eq-bellman-exp-qq-compact>

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

+ #strong[路径一（由第 3 章条件期望方程一步展开）]：在#link(<thm-3.3>)[定理 3.3] 的 $v_pi (s) = bb(E)_pi [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s]$ 中，期望内部仅依赖于一步随机变量 $(R_(t + 1), S_(t + 1))$。给定 $S_t = s$ 时，产生动作 $A_t = a$ 并转移到 $(S_(t + 1) = s', R_(t + 1) = r)$ 的联合条件概率为 $pi(a divides s) p(s', r divides s, a)$。直接按条件期望定义（P7）写出求和式并分解边缘概率，一步即可得到显式展开式：
  $
    v_pi (s) & = bb(E)_pi [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s] \
    & = sum_(a in cal(A)) #mhl($pi(a divides s)$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($v_pi (s')$)] .
  $ <eq-direct-one-step-expand>

+ #strong[路径二（不依赖塔性质，从回报分布 $p(g divides s)$ 底层展开）]：直接从价值函数原始定义 $v_pi (s) = bb(E)_pi [R_(t + 1) + gamma G_(t + 1) divides S_t = s]$ 出发，利用条件全概率公式（P5）对未来回报分布 $p(g divides s)$ 显式引入中间变量 $(a, s', r)$，再通过#link(<lem-3>)[引理 3] 结论 A（$p(g divides s', r, a, s) = p(g divides s')$）完成约简。这一底层路径直观展示了样本空间中每一步概率是如何拆解与重组的，下文 4.2 节将完整呈现该推导过程。

#figure(
  diagram(
    spacing: (14mm, 11mm),
    node-stroke: 0.8pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0.5, 0), [*价值函数定义与回报一步递推* \ $v_pi (s) = bb(E)_pi [R_(t+1) + gamma G_(t+1) divides S_t = s]$], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 68mm),
    node((0, 1), [*路径一：条件期望与塔性质（第 3 章）* \ 引入 $S_(t+1)$ 加细条件并由引理 3B 化简 \ $v_pi (s) = bb(E)_pi [R_(t+1) + gamma v_pi (S_(t+1)) divides S_t = s]$], fill: white, corner-radius: 4pt, inset: 6pt, width: 66mm),
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
  q_pi (s, a) = underbrace(bb(E)_pi [R_(t + 1) divides S_t = s, A_t = a], upright("记为项 (A)")) + gamma thin underbrace(bb(E)_pi [G_(t + 1) divides S_t = s, A_t = a], upright("记为项 (B)")) .
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

#strong[证明（方法二：从回报分布 $p(g divides s)$ 完整展开）]：若不借助 $q_pi (s, a)$，直接对 $v_pi (s) = bb(E)_pi [R_(t + 1) divides S_t = s] + gamma bb(E)_pi [G_(t + 1) divides S_t = s]$ 的两项分别用多变量条件全概率公式（@eq-p5-multi）与 @eq-mdp-joint-decomp 展开：
- #strong[即时奖励期望项]：引入 $(a, s')$ 展开边缘概率 $p(r divides s) = sum_(a in cal(A)) sum_(s' in cal(S)) pi(a divides s) p(s', r divides s, a)$，交换求和得：
  $
    bb(E)_pi [R_(t + 1) divides S_t = s] = sum_(r in cal(R)) r thin p(r divides s) = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(r in cal(R)) p(r divides s, a) r .
  $
- #strong[未来回报期望项]：将 @eq-mdp-joint-decomp 的 $p(g divides s) = sum_(a in cal(A)) pi(a divides s) sum_(s', r) p(s', r divides s, a) #mhlb($p(g divides s')$)$ 代入 $sum_(g in Gamma) g thin p(g divides s)$，并将关于 $g$ 的求和移至最内层：
  $
    bb(E)_pi [G_(t + 1) divides S_t = s] & = sum_(a in cal(A)) #mhl($pi(a divides s)$) sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) underbrace(sum_(g in Gamma) g thin #mhlb($p(g divides s')$), = thin bb(E)_pi [G_(t + 1) divides S_(t + 1) = s'] thin = thin v_pi (s')) \
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

+ #strong[期望奖励函数形式（动态规划与矩阵运算常用形式）]：预先定义状态-动作期望奖励函数 $r(s, a) eq.dot bb(E) [R_(t + 1) divides S_t = s, A_t = a] = sum_(r in cal(R)) p(r divides s, a) r = sum_(s' in cal(S), thin r in cal(R)) p(s', r divides s, a) r$（或定义依赖于后继状态的期望奖励 $r(s, a, s') eq.dot bb(E) [R_(t + 1) divides S_t = s, A_t = a, S_(t + 1) = s']$），从而消去对奖励集合 $cal(R)$ 的显式求和：
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
  diagram(
    spacing: (18mm, 13mm),
    node-stroke: 0.8pt + accent,
    edge-stroke: 0.8pt + accent,
    node((-0.95, 0), [*情形 1：已知 $S_(t+1) = s'$* \ （引理 3A 条件独立）], stroke: none, width: 35mm),
    node((0, 0), [$S_t = s$], corner-radius: 10pt, inset: 6pt, fill: white),
    edge((0, 0), (1, 0), "->", [$pi(a divides s)$], label-side: left),
    node((1, 0), [$A_t = a$], corner-radius: 10pt, inset: 6pt, fill: white),
    edge((1, 0), (2, 0), "->", [$p(s', r divides s, a)$], label-side: left),
    node((2, 0), [*$S_(t+1) = s'$* \ （已给定）], corner-radius: 4pt, fill: accent-mid, stroke: 1.3pt + accent, inset: 5pt),
    edge((2, 0), (3.1, 0), "->", [$p(g divides s')$], label-side: left),
    node((3.1, 0), [$G_(t+1) = g$], corner-radius: 10pt, inset: 6pt, fill: accent-soft),
    edge((0, 0), (3.1, 0), "-->", [路径被已给定的 $S_(t+1) = s'$ 阻断：$p(g divides s', r, a, s) = p(g divides s')$], bend: 28deg, label-side: left, stroke: (paint: luma(130), thickness: 0.7pt, dash: "dashed")),

    node((-0.95, 1.25), [*情形 2：未知 $S_(t+1)$* \ （$p(g divides s) eq.not p(g)$）], stroke: none, width: 35mm),
    node((0, 1.25), [*$S_t = s$* \ （已给定）], corner-radius: 4pt, fill: accent-mid, stroke: 1.3pt + accent, inset: 5pt),
    edge((0, 1.25), (1.5, 1.25), "->", [转移分布 $p(s' divides s)$], label-side: left),
    node((1.5, 1.25), [$S_(t+1)$ \ （未给定，遍历 $s'$）], corner-radius: 4pt, fill: warn-soft, stroke: 0.9pt + warn-stroke, inset: 5pt),
    edge((1.5, 1.25), (3.1, 1.25), "->", [后继分布 $p(g divides s')$], label-side: left),
    node((3.1, 1.25), [$G_(t+1) = g$], corner-radius: 10pt, inset: 6pt, fill: accent-soft),
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
    [$v_star arrow.r q_star$ \\ #text(size: 8.2pt, fill: muted)[策略层单步贪心]],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) #mhlg($q_star (s, a)$) $],
    [$q_star arrow.r v_star$ \\ #text(size: 8.2pt, fill: muted)[环境层单步转换]],
    [$ q_star (s, a) = bb(E) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$v_star arrow.r v_star$ \\ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ v_star (s) = #mhl($max_(a in cal(A))$) bb(E) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] $],
    [$q_star arrow.r q_star$ \\ #text(size: 8.2pt, fill: muted)[两层复合自递推]],
    [$ q_star (s, a) = bb(E) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) thin divides thin S_t = s, A_t = a] $],
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
  #eqbox([$ q_star (s, a) = bb(E) [#mhl($R_(t + 1)$) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] quad "for all " (s, a) in cal(S) times cal(A) $])
$ <eq-opt-cond-qv>

#strong[证明]：从定义 $q_star (s, a) eq.dot max_pi q_pi (s, a)$ 出发，代入#link(<thm-3.2>)[定理 3.2]（@eq-bellman-exp-qv）：
$
  q_star (s, a) & eq.dot max_pi q_pi (s, a) = max_pi bb(E)_pi [R_(t + 1) + gamma v_pi (S_(t + 1)) divides S_t = s, A_t = a] \
  & = bb(E) [R_(t + 1) + gamma #mhlb($max_pi v_pi (S_(t + 1))$) divides S_t = s, A_t = a] quad #[（由#link(<fact-f1>)[事实 F1]、#link(<fact-f2>)[F2] 将 $max_pi$ 移入期望内）] \
  & = bb(E) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] . #h(1.5em) square.filled.medium
$
（注：给定 $S_t = s, A_t = a$ 后，一步转移 $(S_(t + 1), R_(t + 1)) tilde.op p(dot.op, dot.op divides s, a)$ 仅由环境决定，故省去期望算子的下标 $pi$。）

=== 状态价值的自递推最优方程（$v_star arrow.r v_star$）
#strong[定理 5.3（状态价值的贝尔曼最优方程）] <thm-5.3> 对任意状态 $s in cal(S)$，最优状态价值函数满足：

$
  #eqbox([$ v_star (s) = #mhl($max_(a in cal(A))$) bb(E) [R_(t + 1) + gamma #mhlg($v_star (S_(t + 1))$) divides S_t = s, A_t = a] quad "for all " s in cal(S) $])
$ <eq-opt-cond-vv>

#strong[证明]：将#link(<thm-5.2>)[定理 5.2]（@eq-opt-cond-qv）代入#link(<thm-5.1>)[定理 5.1]（@eq-opt-cond-vq）右端的 $q_star (s, a)$，立得 @eq-opt-cond-vv。$square.filled.medium$

=== 动作价值的自递推最优方程（$q_star arrow.r q_star$）
#strong[定理 5.4（动作价值的贝尔曼最优方程）] <thm-5.4> 对任意状态-动作对 $(s, a) in cal(S) times cal(A)$，最优动作价值函数满足：

$
  #eqbox([$ q_star (s, a) = bb(E) [R_(t + 1) + gamma #mhl($max_(a' in cal(A))$) #mhlg($q_star (S_(t + 1), a')$) thin divides thin S_t = s, A_t = a] quad "for all " (s, a) in cal(S) times cal(A) $])
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

- #strong[定理 5.6（$q_star arrow.r v_star$ 的展开形式）] <thm-5.6>：由 $q_star (s, a) eq.dot max_pi q_pi (s, a)$ 与#link(<thm-4.2>)[定理 4.2]（@eq-exp-explicit-qv），因 $p(s' divides s, a) gt.eq 0$ 与策略无关，将 $max_pi$ 移入求和号内可得：
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
//  第 6 章：方程结构定性与强化学习算法选型
// ============================================================
= 方程结构定性与强化学习算法选型
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
    [$(v arrow.r q) compose (q arrow.r v)$： \ 先策略层后环境层],
    [#strong[$q arrow.r q$]],
    [内层：$sum_(a') pi(a' divides s')$ ／ $max_(a')$],
    [外层：$sum_(s', r) p(s', r divides s, a) [dot.op]$],
    [仅维护 $q$: \ $O(|cal(S)| thin |cal(A)|)$],
    [$O(|cal(S)|^2 thin |cal(A)|^2 thin |cal(R)|)$],
    [$(q arrow.r v) compose (v arrow.r q)$： \ 先环境层后策略层],
  ),
) <tab-operator-complexity>

（注：若环境奖励函数确定或已按 @eq-variant-expected-reward 预先计算单步期望奖励 $r(s, a) = sum_(s', r) r thin p(s', r divides s, a)$ 与状态转移边缘概率 $p(s' divides s, a) = sum_r p(s', r divides s, a)$，则 @tab-operator-complexity 时间复杂度中的 $|cal(R)|$ 因子可消去。）

#divider()

== 从贝尔曼方程到经典求解算法
<sec-classic-algorithms>
强化学习的经典算法体系本质上是对不同形式贝尔曼方程的迭代求解或随机近似求解，其演化脉络与对应关系见 @fig-gpi-algorithms：

#figure(
  diagram(
    spacing: (32mm, 10.5mm),
    node-stroke: 0.8pt + accent,
    edge-stroke: 0.8pt + accent,
    node((0, 0), [*贝尔曼期望方程* \ 线性不动点 $v_pi = cal(T)^pi v_pi$ \ （第 3–4 章）], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 48mm),
    node((1, 0), [*贝尔曼最优方程* \ 非线性不动点 $v_star = cal(T)^star v_star$ \ （第 5 章）], fill: accent-soft, corner-radius: 4pt, inset: 6pt, width: 48mm),
    edge((0, 0), (1, 0), "->", [单步贪心 $max_a$], label-side: left),
    node((0, 1), [*动态规划策略评估 / 策略迭代* \ 已知模型 $p(s', r divides s, a)$ \ 展开式迭代 $v_pi arrow.r v_pi$ + 贪心改进], fill: white, corner-radius: 4pt, inset: 6pt, width: 52mm),
    node((1, 1), [*动态规划价值迭代 (Value Iteration)* \ 已知模型 $p(s', r divides s, a)$ \ 展开式直接迭代 $v_star arrow.r v_star$], fill: white, corner-radius: 4pt, inset: 6pt, width: 52mm),
    node((0, 2), [*SARSA / 时序差分评估 (TD)* \ 模型未知，单步采样 $(s, a, r, s', a')$ \ 条件期望式 $q_pi arrow.r q_pi$], fill: white, corner-radius: 4pt, inset: 6pt, width: 52mm),
    node((1, 2), [*Q-Learning / DQN* \ 模型未知，单步采样 $(s, a, r, s')$ \ 条件期望式 $q_star arrow.r q_star$], fill: white, corner-radius: 4pt, inset: 6pt, width: 52mm),
    edge((0, 0), (0, 1), "->", [显式展开 ($v_pi$)], label-side: right),
    edge((1, 0), (1, 1), "->", [显式展开 ($v_star$)], label-side: left),
    edge((0, 1), (1, 1), "->", [单步评估截断], label-side: left),
    edge((0, 1), (0, 2), "-->", [采样替代期望 ($q_pi$)], label-side: right),
    edge((1, 1), (1, 2), "-->", [采样替代期望 ($q_star$)], label-side: left),
    edge((0, 2), (1, 2), "->", [后继动作取 $max_(a')$], label-side: left),
  ),
  caption: [贝尔曼方程体系与经典强化学习算法（动态规划与无模型时序差分）的演化对应关系],
) <fig-gpi-algorithms>

+ #strong[策略迭代（Policy Iteration，基于 $v_pi arrow.r v_pi$ 与 $q_pi arrow.r v_pi$ 显式展开）]：交替执行#strong[策略评估]（利用#link(<thm-4.3>)[定理 4.3] 迭代计算当前策略的 $V_(k + 1) = cal(T)^pi V_k$ 直至收敛于 $v_pi$）与#strong[策略改进]（利用#link(<thm-4.2>)[定理 4.2] 由 $v_pi$ 展开计算 $q_pi (s, a)$，再按 $pi'(s) in arg max_a q_pi (s, a)$ 更新贪心策略）。
+ #strong[价值迭代（Value Iteration，基于 $v_star arrow.r v_star$ 显式展开）]：将策略评估截断为单步更新，直接把#link(<thm-5.7>)[定理 5.7]（@eq-opt-explicit-vv）转化为不动点迭代公式：
  $
    V_(k + 1) (s) arrow.l #mhl($max_(a in cal(A))$) [sum_(r in cal(R)) p(r divides s, a) r + gamma sum_(s' in cal(S)) p(s' divides s, a) #mhlg($V_k (s')$)] .
  $ <eq-value-iteration>
+ #strong[SARSA 与 Q-Learning（基于 $q_pi arrow.r q_pi$ 与 $q_star arrow.r q_star$ 条件期望采样）]：在环境模型 $p(s', r divides s, a)$ 未知的无模型（Model-Free）设定下，用智能体与环境交互采样到的单步转移样本 $(s, a, r, s', a')$ 近似替代#link(<thm-3.4>)[定理 3.4]（@eq-bellman-exp-qq）与#link(<thm-5.4>)[定理 5.4]（@eq-opt-cond-qq）右端的条件期望，以步长 $alpha in (0, 1]$ 做随机近似更新：
  $
    upright("SARSA：") quad & Q(s, a) arrow.l Q(s, a) + alpha [#mhl($r + gamma #mhlg($Q(s', a')$)$) - Q(s, a)], \
    upright("Q-Learning：") quad & Q(s, a) arrow.l Q(s, a) + alpha [#mhl($r + gamma max_(a' in cal(A)) #mhlg($Q(s', a')$)$) - Q(s, a)] .
  $ <eq-td-control>

#divider()

== 工程算法选型与非马尔可夫状态修复建议
<sec-engineering-guidelines>
在实际系统建模与强化学习工程实现中，应根据#strong[环境模型是否已知]、#strong[状态-动作空间规模]及#strong[状态马尔可夫性假设是否成立]选择对应的方程形式与求解方案：

+ #strong[环境模型 $p(s', r divides s, a)$ 完全已知（规划与动态规划场景）]：
  - #strong[优先选用显式展开形式与 $v arrow.r v$ 递推（#link(<thm-4.3>)[定理 4.3]、#link(<thm-5.7>)[定理 5.7]）]：当转移概率已知时，维护状态价值 $v(s)$ 仅需 $O(|cal(S)|)$ 存储空间，比维护 $q(s, a)$ 节省 $|cal(A)|$ 倍内存。在求得最优状态价值 $v_star$ 后，仅需在在线决策时通过一次 $q_star arrow.r v_star$ 展开（#link(<thm-5.6>)[定理 5.6]）即可恢复最优贪心动作 $pi_star (s) in arg max_a [r(s, a) + gamma sum_(s') p(s' divides s, a) v_star (s')]$。
  - #strong[矩阵求逆解析解与不动点迭代的边界]：在固定策略评估中，当状态数 $|cal(S)| lt.tilde 10^3$ 时，可直接构造 @eq-matrix-bellman 的线性方程组 $(I - gamma P_pi) v_pi = r_pi$ 通过高斯消元或 LU 分解求精确解析解；当 $|cal(S)|$ 较大且转移矩阵 $P_pi$ 稀疏时，应采用基于贝尔曼期望算子 $cal(T)^pi$ 的迭代策略评估，将单轮开销降至与非零转移边数成正比。

+ #strong[环境模型未知、仅能通过交互采样获取轨迹（无模型强化学习场景）]：
  - #strong[必须选用条件期望形式与 $q arrow.r q$ 递推（#link(<thm-3.4>)[定理 3.4]、#link(<thm-5.4>)[定理 5.4]）]：在无模型设定下，智能体无法访问 $p(s', r divides s, a)$。若仅估计状态价值 $v(s)$，即使获得了准确的 $v_star$，也无法在不依赖 $p(s', r divides s, a)$ 的情况下计算 $arg max_a bb(E) [R_(t + 1) + gamma v_star (S_(t + 1)) divides s, a]$ 来选出动作。反之，$q arrow.r q$ 的条件期望形式将环境转移期望置于最外层，可直接用单步交互样本 $(s, a, r, s')$ 构造 @eq-td-control 的无偏时序差分目标，并通过 $arg max_a Q(s, a)$ 直接实现免模型控制。
  - #strong[高维或连续空间的神经网络算子近似]：当 $|cal(S)|$ 或 $|cal(A)|$ 为高维或连续空间时，表格型存储与显式求和失效，需将 @eq-td-control 中的时序差分残差转化为均方误差损失函数（如 DQN），并在连续动作空间下配合参数化策略网络近似 $max_a Q(s, a)$ 算子（如 DDPG、TD3、SAC 等 Actor-Critic 架构）。

+ #strong[观测状态不满足马尔可夫性（非平稳或部分可观测场景）]：
  - #strong[排查并修复状态表示缺陷]：全文全部贝尔曼递推均严格依赖#link(<lem-3>)[引理 3] 的条件独立化简 $p(g divides s', r, a, s) = p(g divides s')$（@eq-lem-3a）。若实际工程中的传感器观测 $O_t$ 丢失了关键历史信息（如仅输入单帧图像而无法判断运动速度，或奖励函数依赖历史累计状态），则 $G_(t + 1) cancel(perp) (S_t, A_t) divides S_(t + 1)$，直接套用一步贝尔曼方程会导致价值估计出现系统性偏差甚至震荡发散。此时必须在状态输入层拼接历史观测窗口（Frame Stacking）、引入循环/注意力状态编码器（RNN / Transformer）或显式增广历史统计量，使增广后的状态表征近似恢复马尔可夫性。
