// ============================================================
//  强化学习笔记：贝尔曼期望方程与贝尔曼最优方程的完整推导
// ============================================================

// ---------- 配色与字体 ----------
#let accent = rgb("#1f4e79")
#let accent-soft = accent.lighten(92%)
#let muted = luma(120)

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

// 列表
#set list(marker: ([•], [‣], [–]), indent: 0.6em, body-indent: 0.6em, spacing: 0.9em)
#set enum(indent: 0.6em, body-indent: 0.6em, spacing: 0.9em)
#show list: set par(first-line-indent: 0pt)
#show enum: set par(first-line-indent: 0pt)

// 公式
#set math.equation(supplement: [式])
#show math.equation.where(block: true): set block(above: 1.1em, below: 1.1em)
#show math.equation: set text(font: ("New Computer Modern Math", "Source Han Serif SC", "Noto Serif CJK SC", "Songti SC"))
// 推导中重点结论的框
#let eqbox(body) = box(
  stroke: 0.9pt + accent,
  fill: accent-soft,
  inset: (x: 10pt, y: 7pt),
  radius: 3pt,
  body,
)

// ---------- 标题 ----------
#set heading(numbering: (..n) => if n.pos().len() <= 2 { numbering("1.1", ..n) })
#show heading: set text(font: sans-font, fill: accent.darken(25%), weight: "bold")
#show heading: set par(first-line-indent: 0pt, justify: false)

#show heading.where(level: 1): it => {
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
  block(above: 1.6em, below: 0.9em, sticky: true)[
    #if it.numbering != none {
      text(fill: accent)[#counter(heading).display(it.numbering)]
      h(0.6em)
    }
    #it.body
  ]
}
#show heading.where(level: 3): it => {
  set text(size: 11.5pt)
  block(above: 1.4em, below: 0.8em, sticky: true)[
    #box(width: 3pt, height: 0.9em, fill: accent, baseline: 0.1em)
    #h(0.4em)
    #it.body
  ]
}

// ---------- 表格 ----------
#set table(
  align: (x, y) => if y == 0 or x == 0 { center + horizon } else { left + horizon },
  inset: (x: 9pt, y: 7pt),
  stroke: (x, y) => (
    top: if y == 0 { 1.2pt + accent } else if y == 1 { 0.6pt + accent } else { none },
    bottom: 0.4pt + luma(210),
  ),
  fill: (_, y) => if y == 0 { accent-soft } else if calc.even(y) { luma(250) },
)
#show table.cell.where(y: 0): strong
#show table.cell.where(x: 0): set text(weight: "medium")
#show table.cell: set par(justify: false, first-line-indent: 0pt)
#show table.cell: set text(size: 9.5pt)
#show figure.where(kind: table): set block(breakable: true, above: 1.3em, below: 1.3em)
#show figure: set block(breakable: true)

// ---------- 代码块 / 示意图 ----------
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(248),
  stroke: 0.5pt + luma(220),
  inset: 10pt,
  radius: 4pt,
  breakable: false,
  align(center, text(font: mono-font, size: 6.6pt, it)),
)

// ---------- 分隔线 ----------
#let divider() = {
  v(0.3em)
  line(length: 100%, stroke: (paint: luma(190), thickness: 0.5pt, dash: "dotted"))
  v(0.3em)
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
#v(1em)

#show outline.entry.where(level: 1): it => {
  v(0.5em, weak: true)
  set text(font: sans-font, weight: "bold")
  it
}
#text(font: sans-font, size: 16pt, weight: "bold", fill: accent.darken(25%))[目录]
#v(0.3em)
#outline(title: none, depth: 2, indent: 1.5em)

#pagebreak()


本文档旨在从概率论基础与马尔可夫决策过程（MDP）的基本定义出发，系统、严密地推导强化学习中的核心方程体系------#strong[贝尔曼期望方程]（Bellman
Expectation Equation）与#strong[贝尔曼最优方程]（Bellman Optimality
Equation）。

在强化学习经典文献（如 Sutton &
Barto《强化学习：导论》）中，贝尔曼方程通常以两种等价的数学形式出现：一是以条件期望表征的#strong[紧凑形式]（常称贝尔曼期望方程），二是以状态转移概率与策略分布显式求和表征的#strong[展开形式]（常直接称贝尔曼方程）。本笔记严格区分并打通这两种形式，完整覆盖状态价值函数
$v$ 与动作价值函数 $q$
之间的四类递推关系（$v arrow.r v$、$q arrow.r v$、$v arrow.r q$、$q arrow.r q$），并给出自我完备的闭环证明。

#figure(
  align(center)[#table(
    columns: 4,
    table.header([方程类别], [条件期望形式], [显式展开形式], [适用对象与性质],),
    table.hline(),
    [贝尔曼期望方程], [$v_pi\(s\)= bb(E)_pi [R_(t + 1) + gamma v_pi \( S_(t + 1) \) divides S_t = s]$], [$v_pi\(s\)= sum_a pi\(a divides s\)sum_(s'\,r) p\(s'\,r divides s\,a\)[r + gamma v_pi \( s' \)]$], [任意固定策略
    $pi$；关于价值函数的#strong[线性]方程组],
    [贝尔曼最优方程], [$v_(*)\(s\)= max_a bb(E) [R_(t + 1) + gamma v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a]$], [$v_(*)\(s\)= max_a sum_(s'\,r) p\(s'\,r divides s\,a\)[r + gamma v_(*) \( s' \)]$], [最优策略
    $pi_(*)$；关于价值函数的#strong[非线性]方程组],
  )]
  , kind: table
  )

#divider()

= 马尔可夫决策过程与基本记号
<马尔可夫决策过程与基本记号>
== 有限马尔可夫决策过程
<有限马尔可夫决策过程>
强化学习将智能体（Agent）与环境（Environment）的交互建模为#strong[有限马尔可夫决策过程]（Finite
Markov Decision Process, Finite MDP），由五元组
$\(cal(S)\,cal(A)\,cal(R)\,p\,gamma\)$ 组成。基本记号约定如下表所示：

#figure(
  align(center)[#table(
    columns: 2,
    table.header([记号], [含义],),
    table.hline(),
    [$cal(S)\,cal(A)\,cal(R)$], [分别为有限的#strong[状态集合]、#strong[动作集合]与#strong[奖励集合]。下文常记当前状态为
    $s in cal(S)$，下一时刻状态为 $s' in cal(S)$，动作为
    $a in cal(A)$，即时奖励为 $r in cal(R)$。],
    [$S_t\,A_t\,R_(t + 1)$], [离散时间步 $t in { 0\,1\,2\,dots.h }$
    对应的状态、动作与奖励#strong[随机变量]；小写字母 $s\,a\,r$
    表示其对应的#strong[具体取值]。],
    [$p\(s'\,r divides s\,a\)$], [#strong[环境模型]（状态转移与奖励的联合条件概率）：$Pr\(S_(t + 1) = s'\,R_(t + 1) = r divides S_t = s\,A_t = a\)$，表示在状态
    $s$ 执行动作 $a$ 后，转移到状态 $s'$ 并获得奖励 $r$
    的概率。本文假设环境是#strong[平稳的]（Stationary），即该概率分布不随时间步
    $t$ 变化。],
    [$P\(s' divides s\,a\)$], [#strong[状态转移概率]（State-Transition
    Probability）：$P\(s' divides s\,a\)eq.dot sum_(r in cal(R)) p\(s'\,r divides s\,a\)$，即联合概率
    $p\(s'\,r divides s\,a\)$ 对奖励 $r$ 求和所得的边缘概率。],
    [$pi\(a divides s\)$], [#strong[策略]（Policy）：$pi\(a divides s\)eq.dot Pr\(A_t = a divides S_t = s\)$，表示智能体在状态
    $s$ 下选择动作 $a$ 的概率，满足
    $sum_(a in cal(A)) pi\(a divides s\)= 1$。本文默认讨论不随时间步 $t$
    变化的#strong[平稳策略]。],
    [$gamma in\[0\,1\]$], [#strong[折扣因子]（Discount
    Factor），用于权衡即时奖励与未来远期奖励的相对重要程度。],
    [$G_t$], [从时刻 $t$
    起算的#strong[回报]（Return，即累积折扣奖励）；其可能取值的集合记为
    $Gamma$，具体取值记为 $g in Gamma$。],
    [$v_pi\(s\)\,q_pi\(s\,a\)$], [策略 $pi$
    下的#strong[状态价值函数]（State-Value
    Function）与#strong[动作价值函数]（Action-Value Function）。],
  )]
  , kind: table
  )

#strong[记号约定]：$bb(E)_pi\[dot.op\]$ 表示智能体遵循策略 $pi$
时的数学期望；全文所有条件概率均在该前提下书写（在不引起歧义时，常将
$Pr_pi\(X = x divides Y = y\)$ 简记为 $p\(x divides y\)$）。

#strong[随机变量与具体取值的区分]：严谨推导贝尔曼方程的关键在于区分#strong[随机变量]（大写字母，如
$S_t\,A_t\,R_(t + 1)\,G_t$）与#strong[具体取值]（小写字母，如
$s\,a\,r\,g$）。由于回报 $G_t$
是未来奖励序列的线性组合，它本身也是一个随机变量。对于任意离散型随机变量
$X$ 与条件 ${ Y = y }$，其条件期望均可写为显式求和：

$ bb(E)\[X divides Y = y\]= sum_x x thin p\(x divides y\). $

第 4
节中所有展开形式的推导，本质上都是利用全概率公式与乘法法则，将条件概率
$p\(x divides y\)$ 分解为策略 $pi\(a divides s\)$ 与环境转移概率
$p\(s'\,r divides s\,a\)$ 的乘积组合。

#divider()

== 折扣回报 $G_t$ 的定义与递推性质
<折扣回报-g_t-的定义与递推性质>
#strong[定义 1.1（折扣回报）] 设交互终止时刻为 $T$。从时刻 $t$
开始的折扣回报定义为：

$ G_t #h(0em) eq.dot #h(0em) sum_(k = t + 1)^T gamma^(k - t - 1) R_k #h(0em) = #h(0em) R_(t + 1) + gamma R_(t + 2) + gamma^2 R_(t + 3) + dots.h.c $

#strong[收敛性条件]：在有限步的#strong[分幕式任务]（Episodic
Tasks，$T < oo$）中，可取
$gamma = 1$；在无限步的#strong[持续性任务]（Continuing
Tasks，$T = oo$）中，要求 $gamma in\[0\,1\)$（二者不能同时取 $T = oo$ 且
$gamma = 1$，否则无穷级数可能发散）。在有限 MDP 中，奖励集合 $cal(R)$
有限，必存在上界 $R_max < oo$ 使得 $\|R_k\|lt.eq R_max$。当
$gamma in\[0\,1\)$ 时，由等比级数求和公式可得：

$ \|G_t\|lt.eq sum_(k = 0)^oo gamma^k\|R_(t + k + 1)\|lt.eq sum_(k = 0)^oo gamma^k R_max = frac(R_max, 1 - gamma) < oo . $

级数绝对收敛保证了回报 $G_t$
的期望存在且有限，同时保证了期望算子与无穷级数求和可以合法交换顺序（详见第
2.4 节性质 P16）。

#strong[命题 1.1（回报的一步递推关系）] 对任意时刻
$t$，相邻两个时刻的回报满足如下递推恒等式：

$ #eqbox( [$ G_t = R_(t + 1) + gamma thin G_(t + 1) $]) $

#strong[证明]：将 $G_t$ 的定义式分离出首项
$R_(t + 1)$，并对后续项提取公因式 $gamma$：

$ G_t & = R_(t + 1) + gamma R_(t + 2) + gamma^2 R_(t + 3) + gamma^3 R_(t + 4) + dots.h.c\
 & = R_(t + 1) + gamma (R_(t + 2) + gamma R_(t + 3) + gamma^2 R_(t + 4) + dots.h.c)\
 & = R_(t + 1) + gamma G_(t + 1) . #h(2em) square.filled.medium $

#strong[说明]：$G_t$ 与 $G_(t + 1)$ 共享从 $R_(t + 2)$
开始的全部后续奖励项。这一递推关系是推导所有贝尔曼方程的起点。

#divider()

== 状态价值函数与动作价值函数
<状态价值函数与动作价值函数>
#strong[定义 1.2（状态价值函数）] 智能体从状态 $s in cal(S)$
出发，此后遵循策略 $pi$ 所获得的期望回报，称为状态价值函数：

$ v_pi\(s\)#h(0em) eq.dot #h(0em) bb(E)_pi [G_t divides S_t = s] . $

#strong[定义 1.3（动作价值函数）] 智能体在状态 $s in cal(S)$ 下执行动作
$a in cal(A)$，此后遵循策略 $pi$ 所获得的期望回报，称为动作价值函数：

$ q_pi\(s\,a\)#h(0em) eq.dot #h(0em) bb(E)_pi [G_t divides S_t = s \, thin A_t = a] . $

#strong[说明]：由于环境模型与策略均是平稳的（不随时间 $t$
变化），上述两个条件期望的值仅取决于状态 $s$（及动作 $a$），与具体时刻
$t$ 无关。两者的区别仅在于#strong[当前时刻动作 $A_t$
的随机性是否给定]：$v_pi\(s\)$ 中第一步动作 $A_t$ 仍需按策略
$pi\(dot.op divides s\)$ 采样，而 $q_pi\(s\,a\)$ 已将第一步动作固定为
$a$。

#divider()

= 数学预备知识：概率公理体系与三条核心引理
<数学预备知识概率公理体系与三条核心引理>
为使后续推导做到每一步有据可依，本节汇总所需的概率论基本性质（编号为
P1--P19），并证明三条在后续推导中反复调用的核心引理（引理 1--3）。在有限
MDP 下，状态、动作与奖励集合均为有限集，因此所有单步求和均为有限和。

== 离散型随机变量的概率分布（性质 P1--P6）
<离散型随机变量的概率分布性质-p1p6>
设 $X\,Y\,Z$ 为离散型随机变量，其具体取值分别记为 $x\,y\,z$，简记
$Pr\(X = x\)$ 为 $p\(x\)$。

- #strong[P1（联合分布与边缘分布）]：随机变量 $\(X\,Y\)$ 的联合分布
  $p\(x\,y\)$ 满足归一性
  $sum_x sum_y p\(x\,y\)= 1$。对联合分布关于其中一个变量求和，即可消去该变量，得到另一变量的#strong[边缘分布]（Marginal
  Distribution）：
  $ p\(x\)= sum_y p\(x\,y\)\,#h(2em) p\(y\)= sum_x p\(x\,y\). $
  对多元联合分布 $p\(x\,y\,z\)$，同样可通过对部分变量求和消去对应变量：
  $ p\(x\,z\)= sum_y p\(x\,y\,z\)\,#h(2em) p\(z\)= sum_x sum_y p\(x\,y\,z\). $
  反之，在推导中常需要将边缘分布逆向还原为更高维的联合分布之和（如将
  $p\(x\,z\)$ 展开为 $sum_y p\(x\,y\,z\)$），从而引入辅助变量 $Y$。

- #strong[P2（条件概率）]：当 $p\(y\)> 0$ 时，给定 ${ Y = y }$ 下 $X$
  的条件概率定义为：
  $ p\(x divides y\)#h(0em) eq.dot #h(0em) frac(p\(x\,y\), p\(y\)) . $
  由 P1
  易知条件分布同样满足归一性：$sum_x p\(x divides y\)= frac(sum_x p\(x\,y\), p\(y\)) = frac(p\(y\), p\(y\)) = 1$。

- #strong[P3（乘法法则）]：当 $p\(y\)> 0$（或 $p\(x\)> 0$）时，将 P2
  的定义式两边同乘分母可得：
  $ p\(x\,y\)= p\(x divides y\)thin p\(y\)= p\(y divides x\)thin p\(x\). $

- #strong[P4（链式法则及其条件形式）]：将多个变量的联合概率逐层分解为条件概率的乘积：

  + #strong[三变量与多变量无条件链式法则]：当 $p\(y\,z\)> 0$ 时，有：
    $ p\(x\,y\,z\)= p\(x divides y\,z\)thin p\(y divides z\)thin p\(z\). $
    #emph[证明]：将 $\(Y\,Z\)$
    视为一个复合随机变量，连续两次应用乘法法则（P3）：
    $ p\(x\,y\,z\) & = p #scale(x: 120%, y: 120%)[\(] x\,thin\(y\,z\)#scale(x: 120%, y: 120%)[\)]\
     & = p\(x divides y\,z\)thin p\(y\,z\)quad upright("（第一次应用 P3，将 ")\(y\,z\)upright(" 视为整体条件）")\
     & = p\(x divides y\,z\)thin p\(y divides z\)thin p\(z\). quad upright("（对 ") p\(y\,z\)upright(" 第二次应用 P3）") #h(2em) square.filled.medium $
    同理，对 $n$ 个随机变量 $X_1\,X_2\,dots.h\,X_n$ 递推应用
    P3，可得一般链式法则：
    $ p\(x_1\,x_2\,dots.h\,x_n\)= p\(x_1\)thin p\(x_2 divides x_1\)thin p\(x_3 divides x_1\,x_2\)dots.h.c p\(x_n divides x_1\,dots.h\,x_(n - 1)\). $
  + #strong[带公共条件的链式法则（条件链式法则）]：当所有项均带有公共条件
    ${ Z = z }$（满足 $p\(y\,z\)> 0$）时，有：
    $ p\(x\,y divides z\)= p\(x divides y\,z\)thin p\(y divides z\). $
    #emph[证明]：由条件概率定义（P2）将左端还原为无条件联合概率之比，再结合三变量链式法则化简：
    $ p\(x\,y divides z\) & eq.dot frac(p\(x\,y\,z\), p\(z\)) quad upright("（由 P2，将 ")\(x\,y\)upright(" 视为整体展开条件概率）")\
     & = frac(p\(x divides y\,z\)thin p\(y divides z\)thin p\(z\), p\(z\)) quad upright("（对分子 ") p\(x\,y\,z\)upright(" 代入上方已证的三变量无条件链式法则）")\
     & = p\(x divides y\,z\)thin p\(y divides z\). quad upright("（约去非零因子 ") p\(z\)upright("）") #h(2em) square.filled.medium $
  + #strong[多变量条件链式法则与 MDP 一步交互分解]：对公共条件
    ${ Z = z }$ 下的三个变量 $\(X\,Y\,W\)$，将 $\(Y\,W\)$
    视为整体，连续应用两次条件链式法则可得：
    $ p\(x\,y\,w divides z\) & = p #scale(x: 120%, y: 120%)[\(] x\,thin\(y\,w\)divides z #scale(x: 120%, y: 120%)[\)]\
     & = p\(x divides y\,w\,z\)thin p\(y\,w divides z\)quad upright("（第一次应用条件链式法则，将 ")\(y\,w\)upright(" 视为整体）")\
     & = p\(x divides y\,w\,z\)thin p\(y divides w\,z\)thin p\(w divides z\). quad upright("（对 ") p\(y\,w divides z\)upright(" 第二次应用条件链式法则）") #h(2em) square.filled.medium $
    #emph[MDP 中的两个直接特例]：
    - 在条件链式法则
      $p\(x\,y divides z\)= p\(x divides y\,z\)thin p\(y divides z\)$
      中，令公共条件为 $z = s$，取
      $x =\(s'\,r\)\,thin y = a$，代入策略定义
      $p\(a divides s\)eq.dot pi\(a divides s\)$，即得一步交互的联合概率分解：
      $ p\(s'\,r\,a divides s\)= p #scale(x: 120%, y: 120%)[\(]\(s'\,r\)\,thin a divides s #scale(x: 120%, y: 120%)[\)] = p\(s'\,r divides s\,a\)thin p\(a divides s\)= p\(s'\,r divides s\,a\)thin pi\(a divides s\). $
    - 在多变量条件链式法则中，令
      $z = s\,thin x = g\,thin y =\(s'\,r\)\,thin w = a$，即得四元组
      $\(g\,s'\,r\,a\)$ 在给定状态 $s$ 下的三层分解：
      $ p\(g\,s'\,r\,a divides s\) & = p\(g divides s'\,r\,a\,s\)thin p\(s'\,r\,a divides s\)\
       & = p\(g divides s'\,r\,a\,s\)thin p\(s'\,r divides s\,a\)thin pi\(a divides s\). $

- #strong[P5（全概率公式及其推广）]：结合边缘分布性质（P1）与链式法则（P4），可将目标概率分解为完备中间变量各取值下的条件概率加权和：

  + #strong[基本形式（无附加条件）]：
    $ p\(x\)= sum_y p\(y\)thin p\(x divides y\). $
    #emph[证明]：对边缘分布展开式（P1）中的每一项应用乘法法则（P3）：
    $ p\(x\) & = sum_y p\(x\,y\)quad upright("（由 P1，对二元联合分布关于 ") y upright(" 求和得边缘分布）")\
     & = sum_y p\(y\)thin p\(x divides y\). quad upright("（由 P3 乘法法则：") p\(x\,y\)= p\(y\)thin p\(x divides y\)upright("）") #h(2em) square.filled.medium $
  + #strong[推广一：条件全概率公式（带附加条件
    $Z = z$）]：当给定公共条件 ${ Z = z }$（满足
    $p\(z\)> 0$）时，引入中间变量 $Y$，有：
    $ p\(x divides z\)= sum_y p\(x\,y divides z\)= sum_y p\(y divides z\)thin p\(x divides y\,z\). $
    #emph[证明]：从条件概率定义（P2）出发，结合多元边缘分布性质（P1）与条件链式法则（P4）：
    $ p\(x divides z\) & eq.dot frac(p\(x\,z\), p\(z\)) quad upright("（由 P2 条件概率定义）")\
     & = frac(sum_y p\(x\,y\,z\), p\(z\)) quad upright("（由 P1，将分子 ") p\(x\,z\)upright(" 对 ") y upright(" 还原为三元联合分布之和）")\
     & = sum_y frac(p\(x\,y\,z\), p\(z\)) quad upright("（分母 ") p\(z\)upright(" 与求和变量 ") y upright(" 无关，由分配律移入求和号内）")\
     & = sum_y p\(x\,y divides z\)quad upright("（由 P2，识别 ") frac(p\(x\,y\,z\), p\(z\)) = p\(x\,y divides z\)upright("）")\
     & = sum_y p\(y divides z\)thin p\(x divides y\,z\). quad upright("（由 P4 条件链式法则：") p\(x\,y divides z\)= p\(y divides z\)thin p\(x divides y\,z\)upright("）") #h(2em) square.filled.medium $
    该式是证明条件全期望公式（引理 2）及第 5 节推导
    $p\(g divides s\)= sum_(s') p\(s' divides s\)thin p\(g divides s'\)$
    的直接依据。
  + #strong[推广二：多变量条件全概率公式（多层链式展开）]：当在公共条件
    ${ Z = z }$ 下同时引入两个中间变量 $\(Y\,W\)$ 时，有：
    $ p\(x divides z\)= sum_y sum_w p\(x\,y\,w divides z\)= sum_y p\(y divides z\)sum_w p\(w divides y\,z\)thin p\(x divides y\,w\,z\). $
    #emph[证明]：对 $p\(x divides z\)$ 先后关于变量 $Y$ 和变量 $W$
    连续应用两次推广一（条件全概率公式）：
    $ p\(x divides z\) & = sum_y p\(x\,y divides z\)= sum_y p\(y divides z\)thin p\(x divides y\,z\)quad upright("（对变量 ") y upright(" 应用推广一）")\
     & = sum_y p\(y divides z\)(sum_w p \( x \, w divides y \, z \)) quad upright("（将 ")\(y\,z\)upright(" 视为公共条件，对 ") p\(x divides y\,z\)upright(" 引入变量 ") w upright(" 应用推广一）")\
     & = sum_y p\(y divides z\)sum_w p\(w divides y\,z\)thin p\(x divides y\,w\,z\). quad upright("（由 P4 条件链式法则展开 ") p\(x\,w divides y\,z\)upright("）") #h(2em) square.filled.medium $
    （注：也可先对复合变量 $\(Y\,W\)$ 应用推广一得到
    $p\(x divides z\)= sum_(y\,w) p\(x\,y\,w divides z\)$，再直接代入 P4
    的多变量条件链式法则
    $p\(x\,y\,w divides z\)= p\(y divides z\)thin p\(w divides y\,z\)thin p\(x divides y\,w\,z\)$
    并提取与 $w$ 无关的公因式 $p\(y divides z\)$。） 在第 4.1
    节推导贝尔曼方程显式展开式时，令
    $z = s\,thin y = a\,thin w =\(s'\,r\)\,thin x = g$，代入上式即得未来回报分布
    $p\(g divides s\)$ 的完整展开式：
    $ p\(g divides s\)= sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)thin p\(g divides s'\,r\,a\,s\). $

- #strong[P6（贝叶斯公式）]：当 $p\(x\)> 0$
  时，$p\(y divides x\)= frac(p\(x divides y\)thin p\(y\), p\(x\))$。

#divider()

== 数学期望与条件期望（性质 P7--P13）
<数学期望与条件期望性质-p7p13>
- #strong[P7（数学期望的定义）]：当级数绝对收敛时，离散型随机变量 $X$
  的数学期望定义为：
  $ bb(E)\[X\]#h(0em) eq.dot #h(0em) sum_x x thin p\(x\). $

- #strong[P8（条件期望的定义与双重含义）]：给定 ${ Y = y }$ 时，$X$
  的条件期望定义为：
  $ bb(E)\[X divides Y = y\]#h(0em) eq.dot #h(0em) sum_x x thin p\(x divides y\). $
  #strong[理解条件期望的两个视角]：

  + 当 $y$ 是给定的具体取值时，$bb(E)\[X divides Y = y\]$
    是一个确定的#strong[实数]；若将 $y$ 视为自变量，则
    $g\(y\)eq.dot bb(E)\[X divides Y = y\]$ 是一个关于 $y$
    的确定性函数。
  + 若未指定 $Y$ 的具体取值，记号 $bb(E)\[X divides Y\]$ 表示将函数
    $g\(dot.op\)$ 作用于随机变量 $Y$ 上所得的复合随机变量 $g\(Y\)$：当
    $Y$ 取值为 $y$ 时，$bb(E)\[X divides Y\]$ 的取值即为
    $bb(E)\[X divides Y = y\]$。第 3 节与第 6
    节的推导均建立在这一视角之上。

- #strong[P9（条件期望的线性性）]：对任意常数 $a\,b in bb(R)$ 及随机变量
  $X\,Y\,Z$：
  $ bb(E)\[a X + b Y divides Z\]= a thin bb(E)\[X divides Z\]+ b thin bb(E)\[Y divides Z\]. $

- #strong[P10（条件期望的单调性）]：若随机变量满足
  $X lt.eq Y$（对所有可能取值均成立），则：
  $ bb(E)\[X divides Z\]lt.eq bb(E)\[Y divides Z\]. $ #emph[证明]：因
  $p\(x\,y divides z\)gt.eq 0$ 且 $y - x gt.eq 0$，故
  $bb(E)\[Y - X divides Z = z\]= sum_(x\,y)\(y - x\)p\(x\,y divides z\)gt.eq 0$。$square.filled.medium$

- #strong[P11（条件已知量的提取性质）]：若函数 $f\(Z\)$ 仅依赖于条件变量
  $Z$，则在以 $Z$ 为条件的期望中，$f\(Z\)$
  可视为已知常数直接提到期望号外：
  $ bb(E) [f \( Z \) thin X divides Z] = f\(Z\)thin bb(E)\[X divides Z\]\,#h(2em) upright("特别地，") #h(2em) bb(E) [f \( Z \) divides Z] = f\(Z\). $
  #emph[证明]：当给定 $Z = z$ 时，$f\(Z\)$ 取定值 $f\(z\)$，从而：
  $ bb(E)\[f\(Z\)X divides Z = z\]= sum_x f\(z\)thin x thin p\(x divides z\)= f\(z\)sum_x x thin p\(x divides z\)= f\(z\)thin bb(E)\[X divides Z = z\]. #h(2em) square.filled.medium $

- #strong[P12（多重条件下的期望定义）]：对任意联合条件事件 $C$（如
  ${ S_t = s\,A_t = a }$），有：
  $ bb(E)\[X divides C\]= sum_x x thin p\(x divides C\). $

- #strong[P13（条件独立性）]：若在给定 $Z$ 的条件下，$X$ 与 $Y$
  的条件分布满足：
  $ p\(x divides y\,z\)= p\(x divides z\)\,quad forall thin x\,y\,z\, $
  则称 $X$ 与 $Y$ 关于 $Z$ #strong[条件独立]，记为
  $X perp Y divides Z$。由 P8 与 P12 立得，此时条件期望中多余的条件 $Y$
  可以直接略去： $ bb(E)\[X divides Y\,Z\]= bb(E)\[X divides Z\]. $

#divider()

== 全期望公式与塔性质（性质 P14）
<全期望公式与塔性质性质-p14>
- #strong[P14（全期望公式 / 塔性质）]：若 $bb(E)\[\|X\|\]< oo$，则 $X$
  的期望等于其条件期望 $bb(E)\[X divides Y\]$ 的期望：
  $ bb(E)\[X\]= bb(E) [bb(E) \[ X divides Y \]] . $ #emph[证明]：由
  P8、P15 与 P5（全概率公式）：
  $ bb(E) [bb(E) \[ X divides Y \]] & = sum_y bb(E)\[X divides Y = y\]thin p\(y\)= sum_y (sum_x x thin p \( x divides y \)) p\(y\)\
   & = sum_x x sum_y p\(x divides y\)thin p\(y\)= sum_x x thin p\(x\)= bb(E)\[X\]. #h(2em) square.filled.medium $
  #emph[直观理解]："先按 $Y$ 的不同取值分组求平均，再按 $Y$
  的概率分布对各组均值做加权平均"等于"直接对 $X$ 求总体平均"。

- #strong[P14'（带附加条件的全期望公式）]：在保持外层条件 $Y$
  不变的前提下，向内层期望引入新的条件变量 $Z$，全期望公式依然成立：
  $ bb(E)\[X divides Y\]= bb(E) [bb(E) \[ X divides Y \, Z \] thin divides thin Y] . $
  该式是第 3 节推导的核心工具，其完整证明见第 2.6 节#strong[引理 2]。

- #strong[P14''（塔性质的多次嵌套）]：反复应用 P14'
  可逐层引入多个条件变量：
  $ bb(E)\[X divides Y\]= bb(E) [bb(E) [bb(E) \[ X divides Y \, Z \, W \] thin divides thin Y \, Z] divides thin Y] . $

#divider()

== 级数收敛与压缩映射定理（性质 P15--P18）
<级数收敛与压缩映射定理性质-p15p18>
- #strong[P15（有限求和的交换律）]：对有限指标集 $I\,J$ 与实数
  $a_(i j)$，求和顺序可无条件交换：
  $ sum_(i in I) sum_(j in J) a_(i j) = sum_(j in J) sum_(i in I) a_(i j) . $
  在有限 MDP 中，关于状态 $s'$、动作 $a$、奖励 $r$
  的求和均为有限和，因此可自由交换求和顺序。

- #strong[P16（无穷级数与期望的交换）]：对随机变量序列
  ${ X_k }_(k = 1)^oo$，若级数满足绝对收敛条件
  $sum_(k = 1)^oo bb(E) [\| X_k \|] < oo$，则期望与无穷求和可交换顺序：
  $ bb(E) [sum_(k = 1)^oo X_k] = sum_(k = 1)^oo bb(E)\[X_k\]. $
  #emph[用途]：当 $\|R_k\|lt.eq R_max$ 且 $gamma in\[0\,1\)$
  时，$sum_(k = 1)^oo gamma^(k - 1) bb(E)\[\|R_(t + k)\|\]lt.eq frac(R_max, 1 - gamma) < oo$。这保证了价值函数
  $v_pi\(s\)= bb(E)_pi\[G_t divides S_t = s\]$ 的存在性，且对
  $G_t = R_(t + 1) + gamma G_(t + 1)$
  两边取期望后拆分为两项之和是严格成立的。

- #strong[P17（控制收敛定理）]：若随机变量序列 ${ X_n }$ 满足
  $\|X_n\|lt.eq Y$（其中 $bb(E)\[Y\]< oo$）且逐点收敛
  $X_n arrow.r X$，则极限与期望可交换顺序：$lim_(n arrow.r oo) bb(E)\[X_n\]= bb(E)\[X\]$。

- #strong[P18（压缩映射定理 / Banach 不动点定理）]：在完备度量空间
  $\(cal(V)\,parallel dot.op parallel_oo\)$（对于有限
  MDP，$cal(V) = bb(R)^(\|cal(S)\|)$，最大模范数定义为
  $parallel V parallel_oo = max_(s in cal(S))\|V\(s\)\|$）上，若算子
  $T : cal(V) arrow.r cal(V)$ 满足
  $gamma$-压缩性质（$gamma in\[0\,1\)$）：
  $ parallel T V - T U parallel_oo lt.eq gamma parallel V - U parallel_oo\,quad forall thin V\,U in cal(V)\, $
  则 $T$ 存在#strong[唯一]的不动点 $V^(*)$（满足
  $T V^(*) = V^(*)$），且从任意初值 $V_0$ 出发的迭代序列
  $V_(k + 1) = T V_k$ 必收敛于
  $V^(*)$。该定理保证了贝尔曼期望方程与贝尔曼最优方程解的存在唯一性，以及价值迭代（Value
  Iteration）算法的收敛性。

#divider()

== 马尔可夫性（性质 P19）
<马尔可夫性性质-p19>
- #strong[P19（马尔可夫性，Markov Property）]：MDP
  的基本假设是"给定当前状态与动作后，未来与历史条件独立"，即下一时刻状态与奖励的分布仅取决于当前状态
  $S_t$ 和动作 $A_t$，而与更早的历史轨迹无关：
  $ Pr (S_(t + 1) = s' \, R_(t + 1) = r divides S_t \, A_t \, S_(t - 1) \, A_(t - 1) \, dots.h \, S_0 \, A_0) = Pr (S_(t + 1) = s' \, R_(t + 1) = r divides S_t \, A_t) . $
  由此可知，在固定平稳策略 $pi$ 下，一旦给定了下一时刻状态
  $S_(t + 1) = s'$，从时刻 $t + 1$ 开始的未来轨迹（包括未来回报
  $G_(t + 1)$）就只由 $s'$ 与策略 $pi$ 决定，与时刻 $t$ 的状态
  $S_t$、动作 $A_t$ 及即时奖励 $R_(t + 1)$ 条件独立，即：
  $ G_(t + 1) #h(0em) perp #h(0em)\(S_t\,A_t\,R_(t + 1)\)#h(0em) #scale(x: 120%, y: 120%)[\|] #h(0em) S_(t + 1) . $
  #strong[说明]：马尔可夫性是 MDP
  模型的定义性假设。若状态不具备马尔可夫性（如部分可观测马尔可夫决策过程
  POMDP），则一步贝尔曼递推不再成立。

#divider()

== 贝尔曼推导的三条核心引理（引理 1--3）
<贝尔曼推导的三条核心引理引理-13>
以下三条引理将上述概率与期望性质具体化为 MDP 价值递推的标准算子。

=== 引理 1（条件期望的线性性）
<引理-1条件期望的线性性>
对随机变量 $X\,Y$ 与条件变量 $Z$，有：

$ bb(E)\[X + Y divides Z\]= bb(E)\[X divides Z\]+ bb(E)\[Y divides Z\]. $

#strong[证明]：由条件期望的定义（P8）与边缘分布性质（P1）：

$ bb(E)\[X + Y divides Z = z\] & = sum_(x\,y)\(x + y\)thin p\(x\,y divides z\)\
 & = sum_(x\,y) x thin p\(x\,y divides z\)+ sum_(x\,y) y thin p\(x\,y divides z\)\
 & = sum_x x sum_y p\(x\,y divides z\)+ sum_y y sum_x p\(x\,y divides z\)\
 & = sum_x x thin p\(x divides z\)+ sum_y y thin p\(y divides z\)\
 & = bb(E)\[X divides Z = z\]+ bb(E)\[Y divides Z = z\]. #h(2em) square.filled.medium $

#divider()

=== 引理 2（全期望公式的条件加细形式）
<引理-2全期望公式的条件加细形式>
设 $X\,Y\,Z$ 为随机变量且期望存在，则：

$ bb(E)\[X divides Y\]= bb(E) [bb(E) \[ X divides Y \, Z \] thin divides thin Y] . $

#strong[注意]：在推导价值函数时，外层条件中已经包含当前状态
$Y = S_t$，因此不能直接套用无条件形式
$bb(E)\[X\]= bb(E)\[bb(E)\[X divides Z\]\]$，而必须使用上式，在保留外层条件
$Y$ 的同时，向内层期望中引入新的条件变量 $Z$（如 $A_t$ 或
$S_(t + 1)$）。

#strong[证明]：对任意给定的 $Y = y$，按条件期望定义（P8）展开外层期望：

$ bb(E) [bb(E) \[ X divides Y \, Z \] thin divides thin Y = y] & = sum_z bb(E)\[X divides Y = y\,Z = z\]#h(0em) p\(z divides y\)\
 & = sum_z (sum_x x thin p \( x divides y \, z \)) p\(z divides y\)\
 & = sum_x x sum_z p\(x divides y\,z\)thin p\(z divides y\)quad upright("（由 P15 交换有限求和顺序）")\
 & = sum_x x sum_z p\(x\,z divides y\)quad upright("（由 P4 链式法则：") p\(x divides y\,z\)p\(z divides y\)= p\(x\,z divides y\)upright("）")\
 & = sum_x x thin p\(x divides y\)quad upright("（由 P1、P5 条件全概率公式对 ") z upright(" 求和得边缘分布）")\
 & = bb(E)\[X divides Y = y\]. #h(2em) square.filled.medium $

#divider()

=== 引理 3（基于马尔可夫性的条件化简）
<引理-3基于马尔可夫性的条件化简>
在 MDP 中，设 $g in Gamma$ 为下一时刻回报 $G_(t + 1)$
的取值，则由马尔可夫性（P19）与条件独立性（P13）可得以下两条等价结论：

- #strong[结论 A（概率分布形式，用于第 4 节展开推导）]：
  $ p\(g divides s'\,r\,a\,s\)= p\(g divides s'\). $ 即：当已知下一状态
  $S_(t + 1) = s'$ 时，更早的 $\(s\,a\,r\)$ 对未来回报 $G_(t + 1)$
  的分布不再提供任何额外信息，可从条件中省去。

- #strong[结论 B（条件期望形式，用于第 3 节期望推导）]：
  $ bb(E)_pi [G_(t + 1) divides S_t = s \, A_t = a \, R_(t + 1) = r \, S_(t + 1) = s'] = bb(E)_pi [G_(t + 1) divides S_(t + 1) = s'] = v_pi\(s'\). $
  若不固定 $S_(t + 1)$ 的具体取值，写成关于随机变量 $S_(t + 1)$
  的形式即为：
  $ bb(E)_pi [G_(t + 1) divides S_t \, A_t \, S_(t + 1)] = bb(E)_pi [G_(t + 1) divides S_(t + 1)] = v_pi\(S_(t + 1)\). $

#divider()

= 贝尔曼期望方程（条件期望形式）
<贝尔曼期望方程条件期望形式>
本节从价值函数的定义出发，结合#strong[回报一步递推关系]（命题
1.1）、#strong[条件全期望公式]（引理 2）与#strong[马尔可夫性]（引理 3
结论 B），推导四条条件期望形式的贝尔曼期望方程：

#figure(
  align(center)[#table(
    columns: 2,
    table.header([递推关系], [贝尔曼期望方程（条件期望形式）],),
    table.hline(),
    [$v_pi arrow.r v_pi$], [$v_pi\(s\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s]$],
    [$q_pi arrow.r v_pi$], [$q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s \, A_t = a]$],
    [$v_pi arrow.r q_pi$], [$v_pi\(s\)= bb(E)_(A_t tilde.op pi\(dot.op divides s\)) [q_pi \( s \, A_t \)]$],
    [$q_pi arrow.r q_pi$], [$q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin bb(E)_(A_(t + 1) tilde.op pi\(dot.op divides S_(t + 1)\)) [q_pi \( S_(t + 1) \, A_(t + 1) \)] thin divides thin S_t = s \, A_t = a]$],
  )]
  , kind: table
  )

核心思路是将定义式中的未来回报期望
$bb(E)_pi\[G_(t + 1) divides dot.op\]$
通过引入下一时刻的条件变量，转化为后继状态价值 $v_pi\(S_(t + 1)\)$
或后继动作价值 $q_pi\(S_(t + 1)\,A_(t + 1)\)$。

#divider()

== 状态价值的自递推（$v_pi arrow.r v_pi$）
<状态价值的自递推v_pi-to-v_pi>
#strong[定理 3.1（状态价值的贝尔曼期望方程）] 对任意固定策略 $pi$ 与状态
$s in cal(S)$，状态价值函数满足：

$ #eqbox( [$ #h(0em) v_pi\(s\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s] #h(0em) $]) $

#strong[证明]： 1.
#strong[代入回报递推式并做线性拆分]：由状态价值函数的定义（定义
1.2）、回报一步递推式（命题 1.1）与条件期望线性性（引理 1）：
$ v_pi\(s\) & eq.dot bb(E)_pi [G_t divides S_t = s]\
 & = bb(E)_pi [R_(t + 1) + gamma G_(t + 1) divides S_t = s]\
 & = bb(E)_pi [R_(t + 1) divides S_t = s] + gamma thin bb(E)_pi [G_(t + 1) divides S_t = s] . $
\2. #strong[引入下一状态 $S_(t + 1)$ 加细条件]：考察第二项
$bb(E)_pi\[G_(t + 1) divides S_t = s\]$。由于 $G_(t + 1)$ 与 $S_t$
之间隔着一步动作与状态转移，应用引理 2（取
$X = G_(t + 1)\,Y = S_t\,Z = S_(t + 1)$），在内层条件中引入
$S_(t + 1)$：
$ bb(E)_pi [G_(t + 1) divides S_t = s] = bb(E)_pi [bb(E)_pi [G_(t + 1) divides S_t = s \, S_(t + 1)] thin divides thin S_t = s] . $
\3. #strong[利用马尔可夫性识别后继状态价值]：考察内层期望。当
$S_(t + 1)$ 取任意具体值 $s'$ 时，由马尔可夫性（引理 3 结论 B），已知
$S_(t + 1) = s'$ 后，上一时刻的状态 $S_t = s$ 可以省去，从而：
$ bb(E)_pi [G_(t + 1) divides S_t = s \, S_(t + 1) = s'] = bb(E)_pi [G_(t + 1) divides S_(t + 1) = s'] eq.dot v_pi\(s'\). $
根据性质 P8，这意味着内层条件期望作为随机变量 $S_(t + 1)$
的函数，恰好等于 $v_pi\(S_(t + 1)\)$：
$ bb(E)_pi [G_(t + 1) divides S_t = s \, S_(t + 1)] = v_pi\(S_(t + 1)\). $
\4. #strong[代回合并]：将上式代回第 2 步，并利用引理 1
将两项期望重新合并，即得：
$ v_pi\(s\) & = bb(E)_pi [R_(t + 1) divides S_t = s] + gamma thin bb(E)_pi [v_pi \( S_(t + 1) \) divides S_t = s]\
 & = bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s] . #h(2em) square.filled.medium $

#strong[含义]：状态 $s$ 的价值，等于从 $s$
出发执行一步交互所获得的#strong[即时奖励 $R_(t + 1)$
加上折扣后的下一状态价值 $gamma v_pi\(S_(t + 1)\)$ 的期望]。

#divider()

== 动作价值关于状态价值的表示（$q_pi arrow.r v_pi$）
<动作价值关于状态价值的表示q_pi-to-v_pi>
#strong[定理 3.2（$q_pi$ 关于 $v_pi$ 的贝尔曼期望方程）] 对任意固定策略
$pi$ 及状态-动作对 $\(s\,a\)in cal(S) times cal(A)$，有：

$ #eqbox( [$ #h(0em) q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s \, A_t = a] #h(0em) $]) $

#strong[证明]：推导步骤与定理 3.1 完全相同，只需将条件由 ${ S_t = s }$
替换为 ${ S_t = s\,A_t = a }$。 1. 由定义 1.3、命题 1.1 与引理 1：
$ q_pi\(s\,a\) & eq.dot bb(E)_pi [G_t divides S_t = s \, A_t = a]\
 & = bb(E)_pi [R_(t + 1) + gamma G_(t + 1) divides S_t = s \, A_t = a]\
 & = bb(E)_pi [R_(t + 1) divides S_t = s \, A_t = a] + gamma thin bb(E)_pi [G_(t + 1) divides S_t = s \, A_t = a] . $
\2. 对第二项用引理 2（取
$Y =\(S_t\,A_t\)\,Z = S_(t + 1)$）加细条件，再由引理 3 结论 B 省去已知
$S_(t + 1)$ 下多余的历史条件 $\(S_t = s\,A_t = a\)$：
$ bb(E)_pi [G_(t + 1) divides S_t = s \, A_t = a] & = bb(E)_pi [bb(E)_pi [G_(t + 1) divides S_t = s \, A_t = a \, S_(t + 1)] thin divides thin S_t = s \, A_t = a]\
 & = bb(E)_pi [bb(E)_pi [G_(t + 1) divides S_(t + 1)] thin divides thin S_t = s \, A_t = a]\
 & = bb(E)_pi [v_pi \( S_(t + 1) \) divides S_t = s \, A_t = a] . $ 3.
代回第 1 步并由引理 1 合并两项期望，即得定理结论。$square.filled.medium$

#strong[含义]：由于当前动作 $A_t = a$
已经给定，上式右端的一步随机性#strong[仅来自环境的状态转移与奖励]
$\(S_(t + 1)\,R_(t + 1)\)tilde.op p\(dot.op\,dot.op divides s\,a\)$，策略
$pi$ 的影响已全部包含在后继状态价值 $v_pi\(S_(t + 1)\)$ 内部。

#divider()

== 状态价值关于动作价值的表示（$v_pi arrow.r q_pi$）
<状态价值关于动作价值的表示v_pi-to-q_pi>
#strong[定理 3.3（$v_pi$ 关于 $q_pi$ 的贝尔曼期望方程）] 对任意固定策略
$pi$ 与状态 $s in cal(S)$，状态价值等于动作价值在策略分布
$pi\(dot.op divides s\)$ 下的期望：

$ #eqbox( [$ #h(0em) v_pi\(s\)= bb(E)_pi [q_pi \( S_t \, A_t \) divides S_t = s] = bb(E)_(A_t tilde.op pi\(dot.op divides s\)) [q_pi \( s \, A_t \)] #h(0em) $]) $

#strong[证明]：本式不涉及时间步的推进，只需在 $v_pi\(s\)$
的定义式中应用引理 2（取 $X = G_t\,Y = S_t\,Z = A_t$），引入当前动作
$A_t$ 作为内层条件：

$ v_pi\(s\) & eq.dot bb(E)_pi [G_t divides S_t = s]\
 & = bb(E)_pi [bb(E)_pi [G_t divides S_t = s \, A_t] thin divides thin S_t = s] quad upright("（由引理 2）")\
 & = bb(E)_pi [q_pi \( s \, A_t \) divides S_t = s] quad upright("（由 ") q_pi upright(" 的定义：") bb(E)_pi\[G_t divides S_t = s\,A_t = a\]= q_pi\(s\,a\)upright("）")\
 & = bb(E)_(A_t tilde.op pi\(dot.op divides s\)) [q_pi \( s \, A_t \)] . #h(2em) square.filled.medium $

#strong[含义]：状态价值等于在该状态下按策略 $pi\(dot.op divides s\)$
选择各动作时动作价值的加权平均。该式只涉及#strong[策略层]的动作采样，不涉及环境转移。

#divider()

== 动作价值的自递推（$q_pi arrow.r q_pi$）
<动作价值的自递推q_pi-to-q_pi>
#strong[定理 3.4（动作价值的贝尔曼期望方程）] 对任意固定策略 $pi$
及状态-动作对 $\(s\,a\)in cal(S) times cal(A)$，动作价值函数满足：

$ #eqbox( [$ #h(0em) q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin bb(E)_(A_(t + 1) tilde.op pi\(dot.op divides S_(t + 1)\)) [q_pi \( S_(t + 1) \, A_(t + 1) \)] thin divides thin S_t = s \, A_t = a] #h(0em) $]) $

#strong[证明]： 1. 由定理 3.2，已知：
$ q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s \, A_t = a] . $
\2. 对下一时刻的状态 $S_(t + 1)$ 应用定理 3.3（将时间下标由 $t$ 平移为
$t + 1$）：
$ v_pi\(S_(t + 1)\)= bb(E)_pi [q_pi \( S_(t + 1) \, A_(t + 1) \) divides S_(t + 1)] = bb(E)_(A_(t + 1) tilde.op pi\(dot.op divides S_(t + 1)\)) [q_pi \( S_(t + 1) \, A_(t + 1) \)] . $
\3. 将第 2 步代入第 1 步，即得定理 3.4。若再利用引理 2
将内外两层条件期望合并，也可简写为单层条件期望形式：
$ q_pi\(s\,a\)= bb(E)_pi [R_(t + 1) + gamma thin q_pi \( S_(t + 1) \, A_(t + 1) \) divides S_t = s \, A_t = a] . #h(2em) square.filled.medium $

#divider()

== 两层随机性分解与价值回溯结构
<两层随机性分解与价值回溯结构>
第 3.1 至 3.4 节的四条方程清晰地体现了智能体与环境交互的两层随机性：

- #strong[策略层转换（定理 3.3，$v_pi arrow.r q_pi$）]：智能体根据策略
  $pi\(dot.op divides S_t\)$ 选择动作 $A_t$；
- #strong[环境层转换（定理 3.2，$q_pi arrow.r v_pi$）]：环境根据
  $p\(dot.op\,dot.op divides S_t\,A_t\)$ 产生下一状态 $S_(t + 1)$ 与奖励
  $R_(t + 1)$。

```
          定理 3.3 (策略层期望: A_t ~ π)             定理 3.2 (环境层期望: S_{t+1}, R_{t+1} ~ p)
  ┌──────────┐ ──────────────────────────► ┌────────────┐ ──────────────────────────────────► ┌──────────────┐
  │  v_π(s)  │                             │  q_π(s,a)  │                                     │ v_π(S_{t+1}) │
  └──────────┘ ◄────────────────────────── └────────────┘ ◄────────────────────────────────── └──────────────┘
               定理 3.1 = 定理 3.3 ∘ 定理 3.2 (v_π → q_π → v_π：先策略层，再环境层)
               定理 3.4 = 定理 3.2 ∘ 定理 3.3 (q_π → v_π → q_π：先环境层，再策略层)
```

状态价值的递推（定理 3.1）与动作价值的递推（定理
3.4）正是上述两步转换的前后复合。条件期望形式的优点是结构紧凑，便于推导时序差分（TD）等基于采样估计的算法；若要利用已知的环境模型直接计算价值函数（如动态规划），则需要将条件期望展开为显式的概率求和形式。

#divider()

= 贝尔曼方程（显式展开形式）
<贝尔曼方程显式展开形式>
本节将第 3 节的四条条件期望方程展开为关于策略 $pi\(a divides s\)$
与环境转移概率 $p\(s'\,r divides s\,a\)$ 的#strong[显式求和形式]：

#figure(
  align(center)[#table(
    columns: 2,
    table.header([递推关系], [贝尔曼方程（显式展开形式）],),
    table.hline(),
    [$v_pi arrow.r v_pi$], [$v_pi\(s\)= sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)]$],
    [$q_pi arrow.r v_pi$], [$q_pi\(s\,a\)= sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)]$],
    [$v_pi arrow.r q_pi$], [$v_pi\(s\)= sum_(a in cal(A)) pi\(a divides s\)thin q_pi\(s\,a\)$],
    [$q_pi arrow.r q_pi$], [$q_pi\(s\,a\)= sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma sum_(a' in cal(A)) pi \( a' divides s' \) thin q_pi \( s' \, a' \)]$],
  )]
  , kind: table
  )

上述展开式均可从条件期望定义式
$bb(E)\[X divides Y = y\]= sum_x x thin p\(x divides y\)$
出发，结合#strong[全概率公式及其推广]（P5）与#strong[链式法则]（P4）直接导出。

#divider()

== 状态价值的展开递推（$v_pi arrow.r v_pi$）
<状态价值的展开递推v_pi-to-v_pi>
#strong[定理 4.1（状态价值贝尔曼方程的展开形式）] 对任意固定策略 $pi$
与状态 $s in cal(S)$，有：

$ #eqbox( [$ #h(0em) v_pi\(s\)= sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)] #h(0em) $]) $

#strong[证明]：由状态价值函数的定义与引理 1，将 $v_pi\(s\)$
拆分为即时奖励期望与未来回报期望两项：

$ v_pi\(s\)= bb(E)_pi [R_(t + 1) + gamma G_(t + 1) divides S_t = s] = underbrace(bb(E)_pi [R_(t + 1) divides S_t = s], upright("记为项 (A)")) + gamma thin underbrace(bb(E)_pi [G_(t + 1) divides S_t = s], upright("记为项 (B)")) . $

=== 第一部分：展开即时奖励期望项 (A)
<第一部分展开即时奖励期望项-a>
由条件期望定义（P8），项 (A) 可写为：

$ upright("(A)") = bb(E)_pi [R_(t + 1) divides S_t = s] = sum_(r in cal(R)) r thin p\(r divides s\). $

其中 $p\(r divides s\)$ 是关于动作 $A_t$ 和下一状态 $S_(t + 1)$
求和后的边缘分布。利用条件全概率公式（P5）将隐藏的中间变量 $\(a\,s'\)$
重新引入求和，再用链式法则（P4）将其拆分为策略 $pi$ 与环境转移概率 $p$
的乘积：

$ p\(r divides s\) & = sum_(a in cal(A)) sum_(s' in cal(S)) p\(s'\,r\,a divides s\)quad upright("（由 P1、P5 引入变量 ") a\,s' upright(" 展开边缘分布）")\
 & = sum_(a in cal(A)) sum_(s' in cal(S)) p\(s'\,r divides s\,a\)#h(0em) p\(a divides s\)quad upright("（由 P4、P5 条件全概率展开）")\
 & = sum_(a in cal(A)) sum_(s' in cal(S)) pi\(a divides s\)#h(0em) p\(s'\,r divides s\,a\). quad upright("（代入策略定义 ") pi\(a divides s\)eq.dot p\(a divides s\)upright("）") $

代回项 (A)，并由有限和交换律（P15）调整求和顺序：

$ upright("(A)") = sum_(r in cal(R)) r sum_(a in cal(A)) sum_(s' in cal(S)) pi\(a divides s\)thin p\(s'\,r divides s\,a\)= sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)thin r . $

=== 第二部分：展开未来回报期望项 (B)
<第二部分展开未来回报期望项-b>
记未来回报 $G_(t + 1)$ 的具体取值为
$g in Gamma$。由条件期望定义（P8），项 (B) 写为：

$ upright("(B)") = bb(E)_pi [G_(t + 1) divides S_t = s] = sum_(g in Gamma) g thin p\(g divides s\). $

对于条件概率 $p\(g divides s\)$，同样利用多变量条件全概率公式（P5
推广二）引入一步交互的中间变量
$\(a\,s'\,r\)$，并依次应用链式法则（P4）与马尔可夫性（引理 3 结论 A）：

$ p\(g divides s\) & = sum_(a in cal(A)) sum_(s' in cal(S)) sum_(r in cal(R)) p\(g\,s'\,r\,a divides s\)quad upright("（由 P1、P5 对 ") a\,s'\,r upright(" 全概率展开）")\
 & = sum_(a in cal(A)) sum_(s' in cal(S)) sum_(r in cal(R)) p\(g divides s'\,r\,a\,s\)#h(0em) p\(s'\,r\,a divides s\)quad upright("（由 P4、P5 条件全概率公式）")\
 & = sum_(a in cal(A)) sum_(s' in cal(S)) sum_(r in cal(R)) p\(g divides s'\,r\,a\,s\)#h(0em) p\(s'\,r divides s\,a\)#h(0em) pi\(a divides s\)quad upright("（由 P5 推广二拆分一步转移）")\
 & = sum_(a in cal(A)) sum_(s' in cal(S)) sum_(r in cal(R)) p\(g divides s'\)#h(0em) p\(s'\,r divides s\,a\)#h(0em) pi\(a divides s\). quad upright("（由引理 3 结论 A：马尔可夫性）") $

#quote(block: true)[
#strong[关键步骤说明]：上式最后一步利用马尔可夫性将
$p\(g divides s'\,r\,a\,s\)$ 化简为 $p\(g divides s'\)$。因为
$G_(t + 1)$ 是从时刻 $t + 1$ 开始计算的未来回报，一旦给定了下一状态
$s'$，过去的状态 $s$、动作 $a$ 与即时奖励 $r$ 就不再影响 $G_(t + 1)$
的分布。
]

将化简后的 $p\(g divides s\)$ 代回项 (B)，并将关于 $g$
的求和移至最内层：

$ upright("(B)") & = sum_(g in Gamma) g sum_(a in cal(A)) sum_(s' in cal(S)) sum_(r in cal(R)) p\(g divides s'\)thin p\(s'\,r divides s\,a\)thin pi\(a divides s\)\
 & = sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)underbrace(sum_(g in Gamma) g thin p\(g divides s'\), = thin bb(E)_pi\[G_(t + 1) divides S_(t + 1) = s'\]thin = thin v_pi\(s'\))\
 & = sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)thin v_pi\(s'\). $

（注：上式中 $v_pi\(s'\)$ 不含 $r$，保留 $sum_r$ 是为了与项 (A)
合并时统一求和记号；若单独对 $r$ 求和，则有
$sum_r p\(s'\,r divides s\,a\)= P\(s' divides s\,a\)$。）

=== 第三部分：合并项 (A) 与项 (B)
<第三部分合并项-a-与项-b>
将项 (A) 与 $gamma dot.op upright("(B)")$ 相加并提取公因式，即得：

$ v_pi\(s\) & = sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)thin r #h(0em) + #h(0em) gamma sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)thin v_pi\(s'\)\
 & = sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)] . #h(2em) square.filled.medium $

#divider()

== 动作价值到状态价值的展开（$q_pi arrow.r v_pi$）
<动作价值到状态价值的展开q_pi-to-v_pi>
#strong[定理 4.2（$q_pi$ 关于 $v_pi$ 的展开形式）] 对任意固定策略 $pi$
及状态-动作对 $\(s\,a\)in cal(S) times cal(A)$，有：

$ #eqbox( [$ #h(0em) q_pi\(s\,a\)= sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)] #h(0em) $]) $

#strong[证明]：由动作价值函数的定义与引理 1，有：

$ q_pi\(s\,a\)= underbrace(bb(E)_pi [R_(t + 1) divides S_t = s \, A_t = a], upright("项 (A)")) + gamma thin underbrace(bb(E)_pi [G_(t + 1) divides S_t = s \, A_t = a], upright("项 (B)")) . $

+ #strong[展开项 (A)]：条件中已给定 $\(s\,a\)$，无需对动作 $a$
  求和，只需引入下一状态 $s'$ 展开边缘分布 $p\(r divides s\,a\)$：
  $ upright("(A)") = sum_(r in cal(R)) r thin p\(r divides s\,a\)= sum_(s' in cal(S)\,thin r in cal(R)) r #h(0em) p\(s'\,r divides s\,a\). $
+ #strong[展开项 (B)]：引入 $\(s'\,r\)$ 对 $p\(g divides s\,a\)$
  做全概率展开，再用链式法则（P4）与马尔可夫性（引理 3 结论 A）：
  $ upright("(B)") & = sum_(g in Gamma) g thin p\(g divides s\,a\)= sum_(g in Gamma) g sum_(s' in cal(S)\,thin r in cal(R)) p\(g\,s'\,r divides s\,a\)\
   & = sum_(g in Gamma) g sum_(s' in cal(S)\,thin r in cal(R)) p\(g divides s'\,r\,s\,a\)#h(0em) p\(s'\,r divides s\,a\)\
   & = sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)sum_(g in Gamma) g thin p\(g divides s'\)quad upright("（由引理 3 结论 A 及交换求和）")\
   & = sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)#h(0em) v_pi\(s'\). $
+ #strong[合并]：将项 (A) 与 $gamma dot.op upright("(B)")$
  合并，即得定理结论。$square.filled.medium$

#divider()

== 状态价值到动作价值的展开（$v_pi arrow.r q_pi$）
<状态价值到动作价值的展开v_pi-to-q_pi>
#strong[定理 4.3（$v_pi$ 关于 $q_pi$ 的展开形式）] 对任意固定策略 $pi$
与状态 $s in cal(S)$，有：

$ #eqbox( [$ #h(0em) v_pi\(s\)= sum_(a in cal(A)) pi\(a divides s\)thin q_pi\(s\,a\)#h(0em) $]) $

#strong[证明]：直接将定理 3.3 的期望式
$bb(E)_(A_t tilde.op pi\(dot.op divides s\))\[q_pi\(s\,A_t\)\]$
按离散期望定义展开即可；若从回报分布 $p\(g divides s\)$
出发，则只需引入动作变量 $a$ 做全概率展开：

$ v_pi\(s\) & = sum_(g in Gamma) g thin p\(g divides s\)= sum_(g in Gamma) g sum_(a in cal(A)) p\(g\,a divides s\)\
 & = sum_(g in Gamma) g sum_(a in cal(A)) p\(g divides s\,a\)thin p\(a divides s\)quad upright("（由 P4 链式法则）")\
 & = sum_(a in cal(A)) pi\(a divides s\)sum_(g in Gamma) g thin p\(g divides s\,a\)quad upright("（交换求和并代入 ") pi\(a divides s\)= p\(a divides s\)upright("）")\
 & = sum_(a in cal(A)) pi\(a divides s\)thin q_pi\(s\,a\). #h(2em) square.filled.medium $

#divider()

== 动作价值的展开递推（$q_pi arrow.r q_pi$）
<动作价值的展开递推q_pi-to-q_pi>
#strong[定理 4.4（动作价值贝尔曼方程的展开形式）] 对任意固定策略 $pi$
及状态-动作对 $\(s\,a\)in cal(S) times cal(A)$，有：

$ #eqbox( [$ #h(0em) q_pi\(s\,a\)= sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma sum_(a' in cal(A)) pi \( a' divides s' \) thin q_pi \( s' \, a' \)] #h(0em) $]) $

#strong[证明]：在定理 4.2 的展开式中，利用定理 4.3 将下一状态价值
$v_pi\(s'\)$ 展开为下一时刻动作 $a'$ 的加权平均：

$ v_pi\(s'\)= sum_(a' in cal(A)) pi\(a' divides s'\)thin q_pi\(s'\,a'\). $

将其代入定理 4.2 右端，即得定理 4.4。$square.filled.medium$

#divider()

== 两种形式的一致性与等价性验证
<两种形式的一致性与等价性验证>
+ #strong[由条件期望形式直接导出展开形式]： 在定理 3.1 的
  $v_pi\(s\)= bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s]$
  中，期望内部是关于随机变量 $\(R_(t + 1)\,S_(t + 1)\)$ 的函数。给定
  $S_t = s$ 时，产生动作 $A_t = a$ 并转移到
  $\(S_(t + 1) = s'\,R_(t + 1) = r\)$ 的联合条件概率为
  $pi\(a divides s\)thin p\(s'\,r divides s\,a\)$。因此，直接按条件期望的定义（P8）写出求和式，一步即可得到定理
  4.1：
  $ bb(E)_pi [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s] = sum_(a in cal(A)) pi\(a divides s\)sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_pi \( s' \)] . $

+ #strong[四条展开方程之间的相互推导]：

  - #strong[定理 4.1 = 定理 4.3 $compose$ 定理
    4.2]（$v_pi arrow.r q_pi arrow.r v_pi$）：将定理 4.2 的
    $q_pi\(s\,a\)$ 代入定理 4.3 的
    $v_pi\(s\)= sum_a pi\(a divides s\)q_pi\(s\,a\)$，即得定理 4.1；
  - #strong[定理 4.4 = 定理 4.2 $compose$ 定理
    4.3]（$q_pi arrow.r v_pi arrow.r q_pi$）：将定理 4.3 的
    $v_pi\(s'\)= sum_(a') pi\(a' divides s'\)q_pi\(s'\,a'\)$ 代入定理
    4.2，即得定理 4.4。

```
          定理 4.3: v_π(s) = Σ_a π(a|s) q_π(s,a)                [策略层加权平均]
  v_π ───────────────────────────────────────────────────────► q_π
      ◄───────────────────────────────────────────────────────
          定理 4.2: q_π(s,a) = Σ_{s',r} p(s',r|s,a)[r + γv_π(s')] [环境层转移期望]
```

#divider()

= 常见误区辨析：为何 $p\(g divides s\)eq.not p\(g\)$
<常见误区辨析为何-pg-mid-s-neq-pg>
在阅读第 4.1
节的推导时，初学者常会产生如下疑问：既然在推导中利用马尔可夫性声称"未来回报
$G_(t + 1)$（取值为 $g$）不依赖于时刻 $t$ 的状态 $s$"，从而将
$p\(g divides s'\,r\,a\,s\)$ 写为
$p\(g divides s'\)$，那么为何不能在一开始就直接认为
$p\(g divides s\)= p\(g\)$？

这一误区源于混淆了#strong[已知下一状态 $s'$] 与#strong[未知下一状态
$s'$] 两种不同的条件集合：

+ #strong[$p\(g divides s'\,r\,a\,s\)= p\(g divides s'\)$（已知下一状态
  $s'$）]： 在状态转移链
  $S_t arrow.r A_t arrow.r S_(t + 1) arrow.r G_(t + 1)$
  中，由于已经给定了下一时刻状态 $S_(t + 1) = s'$，从 $t + 1$
  时刻往后的未来回报 $G_(t + 1)$ 就只由 $s'$ 和策略 $pi$
  决定。此时，智能体究竟是从哪个旧状态 $s$、通过哪个动作 $a$ 到达 $s'$
  的，属于冗余的历史信息，因此可以省去 $\(s\,a\,r\)$。

+ #strong[$p\(g divides s\)eq.not p\(g\)$（未知下一状态 $s'$）]： 在
  $p\(g divides s\)$ 的条件中，并未给定下一状态 $s'$。此时，当前状态 $s$
  会直接决定智能体在下一时刻转移到各个状态 $s'$ 的概率分布
  $p\(s' divides s\)= sum_(a\,r) pi\(a divides s\)p\(s'\,r divides s\,a\)$，从而间接影响未来回报
  $g$ 的分布。

对 $p\(g divides s\)$ 与无条件分布 $p\(g\)$ 分别做全概率展开（设时刻 $t$
的状态分布为 $p\(s\)$）：

$ p\(g divides s\) & = sum_(s' in cal(S)) p\(g divides s'\)(sum_(a in cal(A)\,thin r in cal(R)) pi \( a divides s \) thin p \( s' \, r divides s \, a \)) = sum_(s' in cal(S)) p\(g divides s'\)thin p\(s' divides s\)\,\
p\(g\) & = sum_(tilde(s) in cal(S)) p\(tilde(s)\)thin p\(g divides tilde(s)\)= sum_(s' in cal(S)) p\(g divides s'\)(sum_(tilde(s) in cal(S)) p \( tilde(s) \) thin p \( s' divides tilde(s) \)) = sum_(s' in cal(S)) p\(g divides s'\)thin p\(s'\). $

对比可见，$p\(g divides s\)$ 是以#strong[从状态 $s$ 出发的转移概率
$p\(s' divides s\)$] 为权重对 $p\(g divides s'\)$ 加权求和，而 $p\(g\)$
是以#strong[对所有起点平均后的边缘状态分布 $p\(s'\)$]
为权重加权求和，二者对应的加权分布不同。

#divider()

= 贝尔曼最优方程：从策略空间最大化到单步贪心递推
<贝尔曼最优方程从策略空间最大化到单步贪心递推>
第 3 节与第 4 节针对#strong[任意固定策略] $pi$
推导了贝尔曼期望方程。强化学习的核心目标是寻找能获得最大回报的#strong[最优策略]
$pi_(*)$。本节推导最优价值函数 $v_(*)$ 与 $q_(*)$
满足的#strong[贝尔曼最优方程]。

从形式上看，贝尔曼最优方程只需将贝尔曼期望方程中"按策略分布求平均
$sum_a pi\(a divides s\)\(dot.op\)$"替换为"关于动作取最大值
$max_a\(dot.op\)$"。然而，#strong[将定义中"对所有策略空间取最大
$max_pi$"转化为递推式中"对单步动作取最大
$max_a$"，需要依赖贝尔曼最优性原理进行严格证明]。本节在有限 MDP 且
$gamma in\[0\,1\)$ 的设定下，利用双向夹逼法给出完整证明。

#divider()

== 最优策略与最优价值函数
<最优策略与最优价值函数>
#strong[定义 6.1（策略的偏序关系与最优价值函数）] 若策略 $pi$
在所有状态上的价值均不低于策略 $pi'$，即对任意 $s in cal(S)$ 均有
$v_pi\(s\)gt.eq v_(pi')\(s\)$，则称策略 $pi$ 优于或等价于 $pi'$（记为
$pi gt.eq pi'$）。在所有可能策略下达到的最大状态价值与最大动作价值，分别定义为#strong[最优状态价值函数]
$v_(*)$ 与#strong[最优动作价值函数] $q_(*)$：

$ v_(*)\(s\)#h(0em) eq.dot #h(0em) max_pi thin v_pi\(s\)\,quad forall thin s in cal(S)\;#h(2em) #h(2em) q_(*)\(s\,a\)#h(0em) eq.dot #h(0em) max_pi thin q_pi\(s\,a\)\,quad forall thin\(s\,a\)in cal(S) times cal(A) . $

在有限 MDP 且 $gamma in\[0\,1\)$
时，有以下两条基本事实成立（其存在性由第 6.5 节的压缩映射定理保证）：

- #strong[事实 F1]：对任意策略 $pi$ 及任意状态 $s in cal(S)$、动作
  $a in cal(A)$，由最大值定义必有：
  $ v_pi\(s\)lt.eq v_(*)\(s\)\,#h(2em) q_pi\(s\,a\)lt.eq q_(*)\(s\,a\). $
- #strong[事实
  F2（最优策略的存在性）]：至少存在一个优于或等价于所有其他策略的#strong[最优策略]
  $pi_(*)$，它在所有状态和动作上同时达到最优价值，即：
  $ v_(pi_(*))\(s\)= v_(*)\(s\)\,quad forall thin s in cal(S)\;#h(2em) #h(2em) q_(pi_(*))\(s\,a\)= q_(*)\(s\,a\)\,quad forall thin\(s\,a\)in cal(S) times cal(A) . $

#divider()

== 最优性原理：两条核心引理（引理 4--5）
<最优性原理两条核心引理引理-45>
贝尔曼#strong[最优性原理]（Principle of
Optimality）的核心思想是：最优策略的子策略（即从下一时刻状态继续交互的后续策略）也必然是最优的。该原理可形式化为以下两条核心引理，并可通过双向不等式夹逼证明。

=== 引理 4（$q_(*)$ 关于 $v_(*)$ 的递推关系：$q_(*) arrow.r v_(*)$）
<引理-4q_-关于-v_-的递推关系q_-to-v_>
对任意状态-动作对
$\(s\,a\)in cal(S) times cal(A)$，最优动作价值函数满足：

$ q_(*)\(s\,a\)= bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a] . $

（注：因条件中已固定 $S_t = s\,A_t = a$，右端期望仅对环境转移
$\(S_(t + 1)\,R_(t + 1)\)tilde.op p\(dot.op\,dot.op divides s\,a\)$
求平均，不再依赖具体策略，故省去期望的下标 $pi$。）

#strong[证明（双向夹逼法）]：记右端为
$W\(s\,a\)eq.dot bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a]$。

+ #strong[方向一（证明 $q_(*)\(s\,a\)lt.eq W\(s\,a\)$）]：
  对#strong[任意]策略 $pi$，由定理 3.2（对任意策略成立）及事实
  F1（$v_pi\(S_(t + 1)\)lt.eq v_(*)\(S_(t + 1)\)$），利用条件期望的单调性（性质
  P10）可得：
  $ q_pi\(s\,a\)= bb(E) [R_(t + 1) + gamma thin v_pi \( S_(t + 1) \) divides S_t = s \, A_t = a] #h(0em) lt.eq #h(0em) bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a] = W\(s\,a\). $
  由于上式对任意策略 $pi$ 均成立，对左端关于 $pi$ 取最大值，即得：
  $ q_(*)\(s\,a\)= max_pi q_pi\(s\,a\)#h(0em) lt.eq #h(0em) W\(s\,a\). $

+ #strong[方向二（证明 $q_(*)\(s\,a\)gt.eq W\(s\,a\)$）]： 取满足事实 F2
  的最优策略 $pi_(*)$（即
  $v_(pi_(*)) = v_(*)$）。根据动作价值的定义（在状态 $s$ 先执行动作
  $a$，从下一时刻起遵循 $pi_(*)$），应用定理 3.2 可得：
  $ q_(pi_(*))\(s\,a\)= bb(E) [R_(t + 1) + gamma thin v_(pi_(*)) \( S_(t + 1) \) divides S_t = s \, A_t = a] = bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a] = W\(s\,a\). $
  再由 $q_(*)\(s\,a\)= max_pi q_pi\(s\,a\)$ 的定义，必有：
  $ q_(*)\(s\,a\)#h(0em) gt.eq #h(0em) q_(pi_(*))\(s\,a\)= W\(s\,a\). $

综合两个方向的不等式，即证
$q_(*)\(s\,a\)= W\(s\,a\)$。$square.filled.medium$

#divider()

=== 引理 5（$v_(*)$ 关于 $q_(*)$ 的关系：$v_(*) arrow.r q_(*)$）
<引理-5v_-关于-q_-的关系v_-to-q_>
对任意状态 $s in cal(S)$，最优状态价值等于该状态下最优动作价值关于动作
$a in cal(A)$ 的最大值：

$ v_(*)\(s\)= max_(a in cal(A)) thin q_(*)\(s\,a\). $

#strong[证明（双向夹逼法）]：

+ #strong[方向一（证明
  $v_(*)\(s\)lt.eq max_(a in cal(A)) q_(*)\(s\,a\)$）]：
  对#strong[任意]策略 $pi$，由定理 4.3 与事实
  F1（$q_pi\(s\,a\)lt.eq q_(*)\(s\,a\)$），有：
  $ v_pi\(s\)= sum_(a in cal(A)) pi\(a divides s\)thin q_pi\(s\,a\)#h(0em) lt.eq #h(0em) sum_(a in cal(A)) pi\(a divides s\)thin q_(*)\(s\,a\). $
  由于 $pi\(dot.op divides s\)$ 是概率分布（满足
  $pi\(a divides s\)gt.eq 0$ 且
  $sum_a pi\(a divides s\)= 1$），加权平均的值不会超过被平均各数的最大值：
  $ sum_(a in cal(A)) pi\(a divides s\)thin q_(*)\(s\,a\)#h(0em) lt.eq #h(0em) sum_(a in cal(A)) pi\(a divides s\)(max_(a' in cal(A)) q_(*) \( s \, a' \)) = max_(a in cal(A)) thin q_(*)\(s\,a\). $
  对 $v_pi\(s\)lt.eq max_a q_(*)\(s\,a\)$ 左端关于 $pi$ 取最大值，即得
  $v_(*)\(s\)lt.eq max_(a in cal(A)) q_(*)\(s\,a\)$。

+ #strong[方向二（证明
  $v_(*)\(s\)gt.eq max_(a in cal(A)) q_(*)\(s\,a\)$）]： 记使
  $q_(*)\(s\,a\)$ 达到最大的动作为
  $a^(*) in arg max_(a in cal(A)) q_(*)\(s\,a\)$。构造策略 $pi'$：在状态
  $s$ 下以概率 $1$ 选择动作 $a^(*)$（即
  $pi'\(a^(*) divides s\)= 1$），并在后续时刻遵循最优策略
  $pi_(*)$。由定理 4.3 与引理 4 可得：
  $ v_(pi')\(s\)= q_(pi')\(s\,a^(*)\)= bb(E) [R_(t + 1) + gamma thin v_(pi_(*)) \( S_(t + 1) \) divides S_t = s \, A_t = a^(*)] = q_(*)\(s\,a^(*)\)= max_(a in cal(A)) thin q_(*)\(s\,a\). $
  再由 $v_(*)\(s\)$ 的定义知
  $v_(*)\(s\)gt.eq v_(pi')\(s\)= max_(a in cal(A)) q_(*)\(s\,a\)$。

综合两个方向的不等式，即证
$v_(*)\(s\)= max_(a in cal(A)) q_(*)\(s\,a\)$。$square.filled.medium$

#strong[说明]：对比定理 4.3 的
$v_pi\(s\)= sum_a pi\(a divides s\)q_pi\(s\,a\)$ 与引理 5 的
$v_(*)\(s\)= max_a q_(*)\(s\,a\)$ 可见，最优策略 $pi_(*)$ 本质上是关于
$q_(*)$ 的#strong[贪心策略]（Greedy Policy）------它将全部概率分配给使
$q_(*)\(s\,a\)$ 最大的动作 $a^(*)$，从而使策略层的加权求和退化为取最大值
$max_a$。

#divider()

== 贝尔曼最优方程：条件期望形式
<贝尔曼最优方程条件期望形式>
将引理 4 与引理 5
相互代入，即可得到全部四条条件期望形式的贝尔曼最优方程：

#figure(
  align(center)[#table(
    columns: 3,
    table.header([递推关系], [贝尔曼最优方程（条件期望形式）], [推导来源],),
    table.hline(),
    [$v_(*) arrow.r v_(*)$], [$v_(*)\(s\)= max_(a in cal(A)) thin bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a]$], [将引理
    4 代入引理 5],
    [$q_(*) arrow.r v_(*)$], [$q_(*)\(s\,a\)= bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a]$], [引理
    4（已证）],
    [$v_(*) arrow.r q_(*)$], [$v_(*)\(s\)= max_(a in cal(A)) thin q_(*)\(s\,a\)$], [引理
    5（已证）],
    [$q_(*) arrow.r q_(*)$], [$q_(*)\(s\,a\)= bb(E) [R_(t + 1) + gamma max_(a' in cal(A)) q_(*) \( S_(t + 1) \, a' \) thin divides thin S_t = s \, A_t = a]$], [将引理
    5 代入引理 4],
  )]
  , kind: table
  )

#strong[具体代入过程]： \* #strong[$v_(*) arrow.r v_(*)$]：将引理 4 的
$q_(*)\(s\,a\)$ 表达式代入引理 5 的 $v_(*)\(s\)= max_a q_(*)\(s\,a\)$：
$ #eqbox( [$ #h(0em) v_(*)\(s\)= max_(a in cal(A)) thin bb(E) [R_(t + 1) + gamma thin v_(*) \( S_(t + 1) \) divides S_t = s \, A_t = a] #h(0em) $]) $
\* #strong[$q_(*) arrow.r q_(*)$]：在引理 4 的右端，将下一状态的最优价值
$v_(*)\(S_(t + 1)\)$ 按引理 5 替换为
$max_(a' in cal(A)) q_(*)\(S_(t + 1)\,a'\)$：
$ #eqbox( [$ #h(0em) q_(*)\(s\,a\)= bb(E) [R_(t + 1) + gamma max_(a' in cal(A)) q_(*) \( S_(t + 1) \, a' \) thin divides thin S_t = s \, A_t = a] #h(0em) $]) $

#divider()

== 贝尔曼最优方程：显式展开形式
<贝尔曼最优方程显式展开形式>
将第 6.3 节四条期望方程中的环境条件期望
$bb(E)\[dot.op divides S_t = s\,A_t = a\]$ 按第 4.2
节的方法对环境转移概率 $p\(s'\,r divides s\,a\)$
显式展开，即得到展开形式的贝尔曼最优方程：

$ upright("（") v_(*) arrow.r v_(*) upright("）") quad v_(*)\(s\) & = max_(a in cal(A)) sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_(*) \( s' \)]\,\
upright("（") q_(*) arrow.r v_(*) upright("）") quad q_(*)\(s\,a\) & = sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_(*) \( s' \)]\,\
upright("（") v_(*) arrow.r q_(*) upright("）") quad v_(*)\(s\) & = max_(a in cal(A)) thin q_(*)\(s\,a\)\,\
upright("（") q_(*) arrow.r q_(*) upright("）") quad q_(*)\(s\,a\) & = sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma max_(a' in cal(A)) q_(*) \( s' \, a' \)] . $

#strong[展开验证（以 $q_(*) arrow.r v_(*)$ 为例）]： 设 $pi_(*)$ 为满足
$v_(pi_(*)) = v_(*)$ 的最优策略，$g in Gamma$ 为从时刻 $t + 1$ 起遵循
$pi_(*)$ 所得回报 $G_(t + 1)$ 的取值。对引理 4 右端按线性性拆分，并对
$\(s'\,r\)$ 做全概率展开（与第 4.2 节完全相同）：

$ q_(*)\(s\,a\) & = bb(E)_(pi_(*)) [R_(t + 1) divides S_t = s \, A_t = a] + gamma thin bb(E)_(pi_(*)) [G_(t + 1) divides S_t = s \, A_t = a]\
 & = sum_(s' in cal(S)\,thin r in cal(R)) r thin p\(s'\,r divides s\,a\)+ gamma sum_(g in Gamma) g sum_(s' in cal(S)\,thin r in cal(R)) p_(pi_(*))\(g divides s'\,r\,s\,a\)thin p\(s'\,r divides s\,a\)\
 & = sum_(s' in cal(S)\,thin r in cal(R)) r thin p\(s'\,r divides s\,a\)+ gamma sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)underbrace(sum_(g in Gamma) g thin p_(pi_(*))\(g divides s'\), = thin v_(pi_(*))\(s'\)thin = thin v_(*)\(s'\))\
 & = sum_(s' in cal(S)\,thin r in cal(R)) p\(s'\,r divides s\,a\)[r + gamma thin v_(*) \( s' \)] . #h(2em) square.filled.medium $

将上式代入 $v_(*)\(s\)= max_a q_(*)\(s\,a\)$ 即得 $v_(*) arrow.r v_(*)$
的展开式；将 $v_(*)\(s'\)= max_(a') q_(*)\(s'\,a'\)$ 代入上式右端即得
$q_(*) arrow.r q_(*)$ 的展开式。

#divider()

== 与贝尔曼期望方程的对比及经典求解算法
<与贝尔曼期望方程的对比及经典求解算法>
+ #strong[线性方程组与非线性方程组的区别]：
  - #strong[贝尔曼期望方程是线性方程组]：对固定策略
    $pi$，记一步期望奖励向量为
    $r_pi\(s\)eq.dot sum_(a\,s'\,r) pi\(a divides s\)p\(s'\,r divides s\,a\)r$，策略
    $pi$ 下的状态转移矩阵为
    $\[P_pi\]_(s\,s')eq.dot sum_(a\,r) pi\(a divides s\)p\(s'\,r divides s\,a\)$，则定理
    4.1 可写成向量-矩阵形式：
    $ v_pi = r_pi + gamma P_pi v_pi quad arrow.l.r.double quad\(I - gamma P_pi\)v_pi = r_pi . $
    当 $gamma in\[0\,1\)$ 时，矩阵 $\(I - gamma P_pi\)$
    可逆，可直接通过矩阵求逆 $v_pi =\(I - gamma P_pi\)^(- 1)r_pi$
    解出解析解（时间复杂度
    $O\(\|cal(S)\|^3\)$），或在状态空间较大时通过不动点迭代法求解。
  - #strong[贝尔曼最优方程是非线性方程组]：由于含有最大化算子
    $max_a$，贝尔曼最优方程是非线性的，无法直接通过矩阵求逆求解，必须依赖迭代算法求解。
+ #strong[经典强化学习算法与贝尔曼方程的对应关系]：
  - #strong[策略迭代（Policy
    Iteration）]：交替执行#strong[策略评估]（Policy
    Evaluation，利用贝尔曼期望方程迭代计算当前策略的
    $v_pi$）与#strong[策略改进]（Policy Improvement，根据引理 5
    对动作价值取贪心策略 $pi'\(s\)= arg max_a q_pi\(s\,a\)$）；
  - #strong[价值迭代（Value Iteration）]：将贝尔曼最优方程
    $v_(*) arrow.r v_(*)$ 直接转化为迭代更新公式：
    $ V_(k + 1)\(s\)#h(0em) arrow.l #h(0em) max_(a in cal(A)) sum_(s'\,r) p\(s'\,r divides s\,a\)[r + gamma V_k \( s' \)] . $
    当 $gamma in\[0\,1\)$ 时，右端的贝尔曼最优算子是
    $gamma$-压缩映射，由压缩映射定理（性质 P18）保证 $V_k$
    必收敛于唯一解 $v_(*)$（这也同时保证了第 6.1 节事实 F2
    中最优策略的存在性）；
  - #strong[Q-Learning]：在不知道环境模型 $p\(s'\,r divides s\,a\)$
    的无模型（Model-Free）设定下，用智能体与环境交互采样到的单步经验
    $\(s\,a\,r\,s'\)$ 近似替代 $q_(*) arrow.r q_(*)$
    方程右端的期望，从而得到更新规则：
    $ Q\(s\,a\)#h(0em) arrow.l #h(0em) Q\(s\,a\)+ alpha [r + gamma max_(a' in cal(A)) Q \( s' \, a' \) - Q \( s \, a \)] . $

#divider()

= 方程结构定性与算法选型建议
<方程结构定性与算法选型建议>
== 四类递推算子的结构特征与计算复杂度
<四类递推算子的结构特征与计算复杂度>
贝尔曼期望方程（第 3--4 节）与贝尔曼最优方程（第 6
节）共享相同的#strong[环境层转移结构]，二者的结构差异仅在于#strong[策略层算子]是用策略分布加权求和
$sum_a pi\(a divides s\)$ 还是取贪心最大值 $max_a$。四类递推关系在 MDP
交互图中的算子构成、存储开销与单轮全状态更新复杂度对比如下：

#figure(
  align(center)[#table(
    columns: 6,
    table.header([递推类型], [策略层算子（期望 /
      最优）], [环境层算子], [维护变量与空间复杂度], [单轮全量更新计算复杂度], [核心数学依据],),
    table.hline(),
    [#strong[$v arrow.r q$]], [$sum_a pi\(a divides s\)$ ／
    $max_a$], [无（同一时刻 $t$）], [$v$:
    $O\(parallel cal(S) parallel\)$$q$:
    $O\(parallel cal(S) parallel parallel cal(A) parallel\)$], [$O\(parallel cal(S) parallel parallel cal(A) parallel\)$], [条件全期望公式（引理
    2）／ 最优性原理（引理 5）],
    [#strong[$q arrow.r v$]], [无（动作 $a$
    已固定）], [$sum_(s'\,r) p\(s'\,r divides s\,a\)\[dot.op\]$], [$v$:
    $O\(parallel cal(S) parallel\)$$q$:
    $O\(parallel cal(S) parallel parallel cal(A) parallel\)$], [$O\(parallel cal(S) parallel^2 parallel cal(A) parallel parallel cal(R) parallel\)$], [回报一步递推（命题
    1.1）+ 马尔可夫性（引理 3）],
    [#strong[$v arrow.r v$]], [外层：$sum_a pi\(a divides s\)$ ／
    $max_a$], [内层：$sum_(s'\,r) p\(s'\,r divides s\,a\)\[dot.op\]$], [仅维护
    $v$:
    $O\(parallel cal(S) parallel\)$], [$O\(parallel cal(S) parallel^2 parallel cal(A) parallel parallel cal(R) parallel\)$], [$\(v arrow.r q\)compose\(q arrow.r v\)$：先策略层后环境层],
    [#strong[$q arrow.r q$]], [内层：$sum_(a') pi\(a' divides s'\)$ ／
    $max_(a')$], [外层：$sum_(s'\,r) p\(s'\,r divides s\,a\)\[dot.op\]$], [仅维护
    $q$:
    $O\(parallel cal(S) parallel parallel cal(A) parallel\)$], [$O\(parallel cal(S) parallel^2 parallel cal(A) parallel^2 parallel cal(R) parallel\)$], [$\(q arrow.r v\)compose\(v arrow.r q\)$：先环境层后策略层],
  )]
  , kind: table
  )

（注：若环境奖励函数确定或已预先计算单步期望奖励
$r\(s\,a\)= sum_(s'\,r) r thin p\(s'\,r divides s\,a\)$
与状态转移边缘概率
$P\(s' divides s\,a\)= sum_r p\(s'\,r divides s\,a\)$，则上表时间复杂度中的
$\|cal(R)\|$ 因子可消去。）

#divider()

== 方程形式与工程算法选型建议
<方程形式与工程算法选型建议>
在实际系统建模与强化学习算法实现中，应根据#strong[环境模型是否已知]、#strong[状态-动作空间规模]及#strong[状态马尔可夫性假设是否成立]选择对应的贝尔曼方程形式：

+ #strong[环境模型 $p\(s'\,r divides s\,a\)$
  完全已知（规划与动态规划场景）]：
  - #strong[优先选用显式展开形式与 $v arrow.r v$ 递推（定理 4.1、第 6.4
    节）]：当转移概率已知时，维护状态价值 $v\(s\)$ 仅需
    $O\(\|cal(S)\|\)$ 存储空间，比维护 $q\(s\,a\)$ 节省 $\|cal(A)\|$
    倍内存。在求得最优状态价值 $v_(*)$ 后，仅需在决策时通过一次
    $q_(*) arrow.r v_(*)$ 展开（引理 4）即可恢复最优动作
    $pi_(*)\(s\)= arg max_a sum_(s'\,r) p\(s'\,r divides s\,a\)\[r + gamma v_(*)\(s'\)\]$。
  - #strong[线性求解与迭代求解的边界]：在固定策略评估中，当状态数
    $\|cal(S)\|lt.tilde 10^3$ 时，可直接构造线性方程组
    $\(I - gamma P_pi\)v_pi = r_pi$ 通过高斯消元或 LU
    分解求精确解析解；当 $\|cal(S)\|$ 较大且转移矩阵 $P_pi$
    稀疏时，应采用基于贝尔曼期望算子的迭代策略评估，将单步开销降至与非零转移边数成正比。
+ #strong[环境模型未知、仅能通过交互采样获取轨迹（无模型强化学习场景）]：
  - #strong[必须选用条件期望形式与 $q arrow.r q$ 递推（定理 3.4、第 6.3
    节）]：在无模型（Model-Free）设定下，智能体无法访问
    $p\(s'\,r divides s\,a\)$。若仅估计状态价值
    $v\(s\)$，即使获得了准确的 $v_(*)$，也无法在不依赖
    $p\(s'\,r divides s\,a\)$ 的情况下计算
    $arg max_a bb(E)\[R_(t + 1) + gamma v_(*)\(S_(t + 1)\)divides s\,a\]$
    来选出动作。反之，$q arrow.r q$
    的条件期望形式将环境转移期望置于最外层，可直接用单步交互样本
    $\(s\,a\,r\,s'\)$ 构造无偏或渐近无偏的时序差分目标（如 SARSA
    采样定理 3.4、Q-Learning 采样 $q_(*) arrow.r q_(*)$），并通过
    $arg max_a q\(s\,a\)$ 实现免模型控制。
  - #strong[高维连续空间的算子近似]：当 $\|cal(S)\|$ 或 $\|cal(A)\|$
    为高维或连续空间时，表格型存储与显式求和完全失效，需将条件期望形式的贝尔曼残差转化为均方误差损失函数（如
    DQN），并在连续动作空间下配合策略网络近似 $max_a q\(s\,a\)$ 算子（如
    DDPG、SAC 等 Actor-Critic 架构）。
+ #strong[观测状态不满足马尔可夫性（非平稳或部分可观测场景）]：
  - #strong[排查并修复状态表示缺陷]：本文全部贝尔曼递推均严格依赖引理 3
    的条件独立化简
    $p\(g divides s'\,r\,a\,s\)= p\(g divides s'\)$。若实际工程中的观测输入
    $O_t$
    丢失了关键历史信息（如仅输入单帧图像而无法判断运动速度，或奖励函数依赖历史累计状态），则
    $G_(t + 1) ⟂̸\(S_t\,A_t\)divides S_(t + 1)$，直接套用一步贝尔曼方程会导致价值估计出现系统性偏差甚至震荡发散。此时必须在状态输入层拼接历史窗口（Frame
    Stacking）、引入循环状态编码（RNN/Transformer）或显式增广历史统计量，使增广后的状态近似恢复马尔可夫性。
