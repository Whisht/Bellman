---
name: 强化学习笔记 · 贝尔曼方程推导
description: 中文数学推导笔记的单文档视觉系统，以墨青学术蓝为主调、三色语义高亮标记推导角色
colors:
  primary: "#1f4e79"
  primary-deep: "#173b5b"
  primary-strong: "#1a4267"
  primary-soft: "#edf1f4"
  primary-mid: "#c7d3de"
  muted: "#6e6e6e"
  ink-near-black: "#1e1e1e"
  rule-faint: "#bebebe"
  rule-header: "#c8c8c8"
  table-row-line: "#d2d2d2"
  table-zebra: "#fafafa"
  hl-amber-fill: "#fff4d6"
  hl-amber-stroke: "#b56a17"
  hl-blue-fill: "#e6f0fa"
  hl-blue-stroke: "#2b6cb0"
  hl-green-fill: "#e6f6ec"
  hl-green-stroke: "#2f855a"
  warn-fill: "#fff4e5"
  warn-stroke: "#b25000"
  optimality-node-fill: "#fdf1dc"
  optimality-node-stroke: "#b7791f"
typography:
  cover-display:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "26pt"
    fontWeight: 700
    lineHeight: 1.15
  cover-subtitle:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "15pt"
    fontWeight: 400
    lineHeight: 1.2
  headline:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "16pt"
    fontWeight: 700
    lineHeight: 1.25
  title:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "13pt"
    fontWeight: 700
    lineHeight: 1.3
  section:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "11.5pt"
    fontWeight: 700
    lineHeight: 1.35
  body:
    fontFamily: "New Computer Modern, Source Han Serif SC, Noto Serif CJK SC, Songti SC"
    fontSize: "10.5pt"
    fontWeight: 400
    lineHeight: 1.85
  emphasis:
    fontFamily: "New Computer Modern, Kaiti SC, Noto Serif CJK SC"
    fontSize: "10.5pt"
    fontWeight: 400
  math:
    fontFamily: "New Computer Modern Math, Source Han Serif SC, Noto Serif CJK SC, Songti SC"
    fontSize: "10.5pt"
    fontWeight: 400
  caption:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "9pt"
    fontWeight: 400
    lineHeight: 1.4
  table-data:
    fontFamily: "New Computer Modern, Source Han Serif SC, Noto Serif CJK SC, Songti SC"
    fontSize: "9.2pt"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Helvetica Neue, Liberation Sans, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    fontSize: "9pt"
    fontWeight: 400
    lineHeight: 1.3
  diagram-label:
    fontFamily: "New Computer Modern Math, Source Han Serif SC, Noto Serif CJK SC"
    fontSize: "7.5pt"
    fontWeight: 400
  diagram-node:
    fontFamily: "New Computer Modern, Source Han Serif SC, Noto Serif CJK SC"
    fontSize: "7.6pt"
    fontWeight: 400
  mono:
    fontFamily: "Menlo, DejaVu Sans Mono, Source Han Sans SC, Noto Sans CJK SC, PingFang SC"
    # 已定义，当前文档无代码块，故未使用；保留给未来的伪代码或算法清单
rounded:
  math-highlight: "2pt"
  conclusion-box: "3pt"
  diagram-panel: "4pt"
  diagram-enclosure: "6pt"
  diagram-node-small: "7.5pt"
  diagram-node-large: "15pt"
spacing:
  unit: "0.05em"
  paragraph: "1em"
  block-equation: "1.05em"
  figure: "1.2em"
  heading-h1-above: "1.6em"
  heading-h1-below: "1em"
  heading-h2-above: "1.5em"
  heading-h2-below: "0.85em"
  heading-h3-above: "1.3em"
  heading-h3-below: "0.75em"
  list-spacing: "0.9em"
  caption-block: "0.5em"
components:
  conclusion-box:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.ink-near-black}"
    rounded: "{rounded.conclusion-box}"
    padding: "7pt 10pt"
  heading-number-badge:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    typography: "{typography.title}"
    rounded: "{rounded.conclusion-box}"
    padding: "4pt 7pt"
  math-highlight-amber:
    backgroundColor: "{colors.hl-amber-fill}"
    rounded: "{rounded.math-highlight}"
    padding: "0.22em 0.12em"
  math-highlight-blue:
    backgroundColor: "{colors.hl-blue-fill}"
    rounded: "{rounded.math-highlight}"
    padding: "0.22em 0.12em"
  math-highlight-green:
    backgroundColor: "{colors.hl-green-fill}"
    rounded: "{rounded.math-highlight}"
    padding: "0.22em 0.12em"
  table-header-cell:
    backgroundColor: "{colors.primary-soft}"
    typography: "{typography.table-data}"
    padding: "6.5pt 8.5pt"
  diagram-node-expectation:
    backgroundColor: "{colors.primary-soft}"
    rounded: "{rounded.diagram-panel}"
    padding: "7pt"
  diagram-node-optimality:
    backgroundColor: "{colors.optimality-node-fill}"
    rounded: "{rounded.diagram-panel}"
    padding: "7pt"
---

# Design System: 强化学习笔记 · 贝尔曼方程推导

## Overview

**Creative North Star: "推导手稿 The Derivation Notebook"**

这是一份供人逐行核查推导的数学手稿，不是供人浏览的阅读产品。视觉系统的全部职责是让推导链可核查：公式与定理占据视觉重心，版式把「从哪一步到哪一步」说清楚，颜色只承担语义标注，不承担氛围。读者的工作方式是从某个结论回溯到它依赖的引理，因此交叉引用、编号与对照表是第一等的界面元素，装饰是第一等的干扰。

密度是这套系统的默认状态。正文页接近满排，留白只出现在需要停顿的地方：结论框、图表、章节起始。前置部分（封面、目录）刻意宽松，与正文的密排形成对比，使读者在进入推导之前完成一次呼吸。

**Key Characteristics:**
- 单一主色墨青学术蓝贯穿标题、结论框、表格顶线与交叉引用，形成统一的结构骨架。
- 三色公式高亮是标注工具而非装饰，每种色相固定对应推导中的一个角色，全文不得互换。
- 完全平面，无阴影、无渐变、无玻璃拟态；层级由色阶、线宽与实色块的面积对比承担。
- 字号阶梯粗疏而明确，26pt / 16pt / 13pt / 11.5pt / 10.5pt / 9pt 各有固定职责，不存在仅作微调的相邻字号。
- 无 eyebrow、kicker、引文大字与装饰性插图；标题自己承载重量。

## Colors

主色是一支墨青学术蓝的钢笔，其余颜色要么是它的深浅变体，要么是语义标注用的荧光笔。

### Primary
- **Ink-Blue 墨青学术蓝** (`#1f4e79`): 标题、结论框描边、表格顶线、章节编号实底块、链接与交叉引用。它是文档的骨架色，承担所有「这是结构」的信号。
- **Ink-Blue Deep** (`#173b5b`, `darken(25%)`): 各级标题与封面主标题专用。比主色更深，确保标题在视觉上压得住其下的密排正文。
- **Ink-Blue Strong** (`#1a4267`, `darken(15%)`): 粗体强调文字与图表题注。粗体本身已是强调，颜色只做轻微加深，避免双重强调喧宾夺主。
- **Ink-Blue Soft** (`#edf1f4`, `lighten(92%)`): 结论框底色、表格表头底色、期望类图节点底色。极浅，仅用于把一块内容从纸面上轻轻托起。
- **Ink-Blue Mid** (`#c7d3de`, `lighten(75%)`): 备份结构图中「已给定」节点（$S_t = s$、$S_{t+1} = s'$）的底色，配 1.3pt Ink-Blue 描边，与 Warning Ochre 的「未给定」节点形成对照。

### Secondary
- **Amber 琥珀** (`#fff4d6` 底 / `#b56a17` 描边): 公式内高亮，标记策略层算子或核心变换，如 $\pi(a \mid s)$ 与 $\max_a$。
- **Optimality Amber** (`#fdf1dc` 底 / `#b7791f` 描边): 仅用于封面八方程总览图中 $v_*, q_*$ 四个最优性节点及其边，把「最优」与「期望」两组方程在图内分开。与公式高亮的琥珀是不同色值，不得混用。

### Tertiary
- **Condition Blue 浅蓝** (`#e6f0fa` 底 / `#2b6cb0` 描边): 公式内高亮，标记新引入的条件变量或马尔可夫条件独立化简项。
- **Recursion Green 浅绿** (`#e6f6ec` 底 / `#2f855a` 描边): 公式内高亮，标记后继时刻的价值递推项。
- **Warning Ochre 警示赭** (`#fff4e5` 底 / `#b25000` 描边): 图内用于标记「尚未给定、需要遍历或取极值」的量——备份结构图中未给定的 $S_{t+1}$ 节点、$\max_a$ 边、终止状态 $S_T$；谱系图中标记蒙特卡洛方法节点及其边，把「不经贝尔曼方程、不自举」这一路与其他两路分开。

### Neutral
- **Paper White** (`#ffffff`): 纸面。
- **Near-Black Ink** (`#1e1e1e`): 目录条目链接专用，避免目录页变成一片蓝色。
- **Muted Gray** (`#6e6e6e`): 页眉、页脚、英文副标题、图内虚线对应关系边。次级信息，不参与结构表达。
- **Rule Faint** (`#bebebe`): `divider()` 的点状分隔线。
- **Header Rule** (`#c8c8c8`): 页眉下方的 0.4pt 细线。
- **Table Row Line** (`#d2d2d2`): 表格行底线 0.4pt。
- **Table Zebra** (`#fafafa`): 表格偶数行底色，几乎不可察觉，只为长表的横向追踪提供辅助。

### Named Rules

**The Semantic Highlight Rule.** 三色公式高亮的语义是固定的：琥珀 = 策略算子/核心变换，浅蓝 = 条件加细/马尔可夫化简，浅绿 = 后继价值递推项。不得为「好看」而换色，不得在同一推导中用同一色相标记两种角色。高亮永远作用在公式的某一项上，而不是整个公式——整个公式需要被强调时使用结论框。

**The One Structural Voice Rule.** 墨青学术蓝及其变体只表达文档结构，不表达内容语义。内容语义交给三色高亮与警示赭。一个元素若同时使用主色与高亮色，说明职责划分出了问题。

**The Two-Ambers Rule.** 公式高亮琥珀 (`#b56a17`) 与最优性图节点琥珀 (`#b7791f`) 是两套色值。前者用于行内公式，后者仅用于封面总览图的 $v_*, q_*$ 节点。新增图中若需表达最优性，沿用后者。

## Typography

**Display Font:** Helvetica Neue / Liberation Sans（拉丁），Source Han Sans SC / Noto Sans CJK SC / PingFang SC（中文）
**Body Font:** New Computer Modern（拉丁，覆盖 `latin-in-cjk`），Source Han Serif SC / Noto Serif CJK SC / Songti SC（中文）
**Math Font:** New Computer Modern Math，中文回退同正文
**Label/Mono Font:** Menlo / DejaVu Sans Mono，中文回退到无衬线栈

**Character:** 无衬线负责结构与寻路，衬线负责推导本身。中文与拉丁分别指定族，用 `covers: "latin-in-cjk"` 把 CJK 文本中的拉丁字符交给数学友好的 New Computer Modern，保证正文里的 $v_\pi$ 与公式环境中的字形一致。族回退栈横跨 macOS 与 Linux，本机走 Source Han，CI 走 Noto CJK。

### Hierarchy
- **Cover Display** (bold, 26pt, 无衬线, Ink-Blue Deep): 仅封面主标题「强化学习笔记」。
- **Cover Subtitle** (regular, 15pt, 无衬线, Ink-Blue): 封面副标题，承载文档的实际主题。
- **Headline** (bold, 16pt, 无衬线, Ink-Blue Deep): 一级标题与「目录」标题。一级标题额外带 Ink-Blue 实底编号块（内文 white 14pt）与 1.2pt 通栏下划线。
- **Title** (bold, 13pt, 无衬线, Ink-Blue Deep): 二级标题，编号以 Ink-Blue 着色，与正文标题字色分开。
- **Section** (bold, 11.5pt, 无衬线, Ink-Blue Deep): 三级标题，前置 3pt 宽、0.9em 高的 Ink-Blue 实心竖条代替编号。
- **Body** (regular, 10.5pt, 衬线, 两端对齐, leading 0.85em, 段距 1em, 首行缩进 2em 但 `all: false`): 全部推导与论述。段落边界只用缩进与段距中的一种方式标记连续段落，`all: false` 使首段不缩进。
- **Emphasis** (regular, 10.5pt, Kaiti SC): 强调文字用楷体而非斜体，符合中文排版惯例。
- **Math** (regular, 10.5pt, New Computer Modern Math): 行间公式上下间距 1.05em，编号为章内序号 `(章.序)`。
- **Caption** (regular, 9pt, 无衬线, Ink-Blue Strong): 图表题注，编号部分加粗，置于表上方、图下方。
- **Table Data** (regular, 9.2pt): 表格单元，表头自动加粗，首列 medium。
- **Label** (regular, 9pt, 无衬线, Muted Gray): 页眉页脚。
- **Diagram Node** (regular, 7.6pt) / **Diagram Label** (regular, 7.5pt / 6.8pt / 6.5pt): fletcher 图内文字，按图的信息密度分三档。

### Named Rules

**The Structure-In-Sans Rule.** 无衬线只出现在结构元素（标题、题注、页眉页脚、目录一级条目），衬线只出现在内容元素（正文、公式、表格数据、图内节点）。不要让推导正文变成无衬线，也不要让标题变成衬线。

**The No-Micro-Steps Rule.** 基础字号阶梯是 26 / 16 / 15 / 13 / 11.5 / 10.5 / 9.2 / 9 / 7.6 / 7.5。既有例外均有固定职责：一级标题编号块 14、封面英文副题 9.5、备份结构比较表 8.6、图内分组标签 8.5、公式关系注释 8.2，以及图内按节点与连线密度递减的 8 / 7 / 6.8 / 6.5。新增角色应复用基础阶梯或上述对应角色，不得只为制造细微层次插入与相邻值只差约 0.3pt 的新字号；每个例外都必须能说明其职责或空间约束。

**The Fallback-Is-Real Rule.** 族回退不是形式。本机与 CI 使用不同的实际字体，任何版式判断（尤其是目录最长条目、表格列宽、图内节点宽度）都必须考虑到字体替换会改变断行。

## Layout

固定 A4 单栏单页媒体，页边距 x 2.3cm、上 2.8cm、下 2.6cm。无断点、无响应式分支；「适配」这一维度由字体回退承担，而非容器。阅读路径是线性的：封面标题 → 八方程总览图 → 目录 → 导言 → 第 1–7 章。

前置部分与正文用硬分页分离。封面与图 1 构成标题单元，目录是独立的导航单元，二者不得共用一页——目录标题是寻路标签，必须位于其单元的顶部。正文各章依靠一级标题的 `sticky: true` 与上方 1.6em 间距形成章节起点，不强制每章另起一页。

间距以 em 为唯一单位，随字号缩放，不存在 px 级硬编码。节律来自刻意对比：标题上方宽松、下方紧凑（一级 1.6em/1em，二级 1.5em/0.85em，三级 1.3em/0.75em），目录一级条目上方 0.5em 弱间距而二级条目无额外间距。表格标题在表上方 0.5em，图标题在图下方。

页眉在非首页显示文档名与当前一级标题（通过 `query(heading.where(level: 1)).before(here())` 取最近者），下压 0.4pt 细线；页脚居中显示 `n / N`。这两个元素是长文档中唯一的持续定位装置。

表格整块不可分页（`breakable: false`），这是有意的取舍：宁可页底留白也不让一张对照表断在两页之间。

## Elevation & Depth

完全平面。全文没有任何阴影、渐变、背景模糊或透明度叠加。层级通过三种手段表达：色阶（Ink-Blue Soft 把一块内容从纸面托起）、线宽（0.4pt 行线 / 0.6pt 分隔 / 0.9pt 框线 / 1.2pt 表顶线与标题下划线 / 1.5pt 封面短横）、实色块面积（一级标题编号徽章是全文唯一的高饱和实色矩形，因此它天然是最强的定位信号）。

### Named Rules

**The Flat-Always Rule.** 不引入阴影，包括悬停与聚焦状态——本文档没有交互态。深度需求的正确解法是调整色阶或线宽，不是加投影。

**The Weight-Ladder Rule.** 线宽是层级语言。0.4pt 是可忽略的分隔，0.9pt 是「这是一个框」，1.2pt 是「这是一个主要边界」，1.5pt 只出现在封面。新增线条必须落在这架梯子上。

## Shapes

直角纸面 + 小圆角内容容器。圆角分三档语义：2pt 属于行内公式高亮（`mannot.markhl`，outset x 0.12em / y 0.22em，紧贴字形），3pt 属于结论框与编号徽章（文档级组件），4–6pt 属于 fletcher 图的节点与外框。更大的圆角（7.5–15pt）只出现在谱系图与 MDP 交互图的圆形/胶囊节点中，是图的内部几何，不构成页面形态语言。

唯一允许打破直角的页面级元素是结论框的 3pt 圆角。不使用彩色左边框式 callout，不使用硬偏移阴影，不使用几何遮罩。

## Components

每个组件都有可核查性职责，没有纯装饰组件。

### 结论框 eqbox
- **职责：** 标记推导终点。一个推导链的最终结论进框，中间步骤不进框。
- **形态：** 柔和圆角（3pt），Ink-Blue Soft 底，Ink-Blue 0.9pt 描边，内边距 7pt × 10pt。
- **行为：** 内部抑制公式编号（`numbering: none`），避免与外层编号重复。框内公式不另编号，引用指向框外的定理或公式标签。

### 公式项高亮 mhl / mhlb / mhlg
- **职责：** 标记某一项在推导中扮演的角色，使读者能追踪同一项在相邻两行之间的变形。
- **形态：** 紧贴字形的圆角底块（2pt），0.5pt 同色描边，outset x 0.12em / y 0.22em。基于 `mannot.markhl`，按公式真实包围盒绘制，不依赖手工测量。
- **规则：** 见 The Semantic Highlight Rule。

### 三线表
- **职责：** 横向对照。记号表、方法对照表、更新规则表。
- **形态：** 表顶 1.2pt Ink-Blue，表头下 0.6pt Ink-Blue，行底 0.4pt Table Row Line；表头 Ink-Blue Soft 底加粗，偶数行 Table Zebra 底，首列 medium。
- **内边距：** 单元 6.5pt × 8.5pt，单元内文字 9.2pt，不两端对齐、不首行缩进。
- **行为：** 整块不可分页；表内行间公式上下间距压缩至 0.35em 并左对齐；题注在表上方。

### 章节标题块
- **一级：** Ink-Blue 实底编号徽章（白字 14pt，圆角 3pt，内边距 4pt × 7pt）+ 16pt 粗体标题 + 1.2pt 通栏下划线。上方 1.6em 弱间距，`sticky: true`，进入时重置公式编号计数器。
- **二级：** 13pt 粗体，编号以 Ink-Blue 着色，编号与标题间 0.6em。
- **三级：** 11.5pt 粗体，前置 3pt × 0.9em Ink-Blue 实心竖条，不编号。
- **编号规则：** 仅前两级编号（`n.pos().len() <= 2`），三级及以下不编号。

### 图表题注
- **形态：** 9pt 无衬线 Ink-Blue Strong，编号部分加粗，编号与正文间 0.5em。
- **位置：** 表上方、图下方。图内公式一律不编号。

### fletcher 结构图
- **职责：** 表达方程之间、算法之间的结构关系，不做示意图装饰。
- **形态：** 期望类节点 Ink-Blue Soft 底 + Ink-Blue 描边，最优类节点 Optimality Amber 底 + 同色描边，方法类节点按所属方法使用对应高亮描边。
- **边：** 推导方向为实线箭头，期望↔最优的对应关系为 Muted Gray 虚线双向箭头，函数近似延伸为 Ink-Blue 虚线。
- **文字：** 节点 7.6pt，边标签 7.5pt / 6.8pt / 6.5pt。

### 页眉与页脚
- **页眉：** 9pt 无衬线 Muted Gray，左侧「文档名 · 副标题」，右侧当前一级标题，下方 0.4pt Header Rule 细线。首页不显示。
- **页脚：** 9pt 无衬线 Muted Gray，居中 `n / N`。

### 分隔线 divider()
- **形态：** 0.5pt Rule Faint 点状线，上下各 0.25em。用于同一章内的主题切换，不用于章节之间。

## Do's and Don'ts

### Do:
- **Do** 用结论框框住推导终点，并抑制其内部的公式编号。
- **Do** 让三色高亮严格对应固定语义：琥珀 = 策略算子/核心变换，浅蓝 = 条件加细/马尔可夫化简，浅绿 = 后继价值递推项。
- **Do** 让标题上方间距大于下方（1.6em/1em、1.5em/0.85em、1.3em/0.75em），保持「标题属于其下内容」的分组。
- **Do** 用实色编号徽章与线宽阶梯表达层级，而不是阴影。
- **Do** 在新增表格时保持整块不可分页，接受因此产生的页底留白。
- **Do** 在改动版式后编译并检查 PDF，尤其当 CI 与本机使用不同中文字体时。
- **Do** 让目录独立成页，目录标题位于页面顶部。
- **Do** 保持随机变量大写、具体取值小写的排版约定，以及条件期望形式与显式展开形式的区分。

### Don't:
- **Don't** 在标题上方添加 eyebrow 或 kicker；标题自己承载重量。
- **Don't** 引入引文大字、装饰性信息图卡片或与推导无关的插图。
- **Don't** 为美观而交换高亮色相，或在同一推导中用同一色相标记两种角色。
- **Don't** 引入阴影、渐变文字、玻璃拟态或背景模糊。
- **Don't** 使用超过 1pt 的彩色左边框/右边框作为 callout 样式。
- **Don't** 在相邻角色之间插入只差 0.3pt 的新字号。
- **Don't** 让推导正文使用无衬线，或让标题使用衬线。
- **Don't** 混用公式高亮琥珀 (`#b56a17`) 与最优性图节点琥珀 (`#b7791f`)。
- **Don't** 让封面与目录共用一页。
