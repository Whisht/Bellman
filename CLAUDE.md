# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a single-document Typst project: a Chinese, mathematically rigorous derivation of the Bellman expectation and optimality equations from probability theory and finite MDPs. `main.typ` is the authoritative source; the Markdown notes are drafting/reference material, not build inputs.

## Build and preview

Typst 0.15 or newer is required. Package dependencies (`fletcher` and `mannot`) are downloaded through Typst's package registry.

```bash
typst compile main.typ bellman-notes.pdf
typst watch main.typ bellman-notes.pdf
```

There are no automated tests or lint commands. A successful compile is the basic verification for source changes; inspect the PDF as well when changing layout, diagrams, tables, fonts, or pagination. PDFs are ignored local artifacts.

## Document architecture

`main.typ` is deliberately self-contained rather than split into modules:

- The opening section defines colors, CJK/Latin font fallbacks, page headers and footers, heading styles, table and figure styling, and equation numbering. Equation numbers are chapter-based and reset at each level-1 heading.
- Reusable presentation helpers include `eqbox` for boxed conclusions and `mhl`, `mhlb`, and `mhlg` for amber, blue, and green math highlights. These colors have established semantic meanings documented in the introduction; preserve them when editing derivations.
- The cover diagram, contents, and introduction establish the eight-equation map connecting state/action values and expectation/optimality forms.
- Chapters 1–2 establish MDP notation, probability properties P1–P14, and lemmas 1–3. Chapters 3–4 derive Bellman expectation equations in conditional-expectation and explicitly expanded forms. Chapter 5 covers optimality equations, matrix solutions, and fixed points. Chapter 6 (`<sec-value-estimation>`) covers expectation estimation for state and action values: the three mathematical tools (contraction-mapping fixed points, Monte Carlo sample means, Robbins–Monro stochastic approximation), then dynamic-programming estimation (iterative policy evaluation, policy iteration, value iteration and Q-value iteration), Monte Carlo estimation (first-/every-visit, incremental updates, MCES, ε-soft control, ordinary/weighted importance sampling), and temporal-difference estimation (TD(0), n-step TD, TD(λ), SARSA, Expected SARSA, Q-learning, Double Q-learning), ending with a backup-structure comparison and the per-method update table. Chapter 7 compares operator structure and complexity, presents the RL algorithm genealogy (`<sec-rl-genealogy>`, the figure linking expectation/optimality equations × estimation method → derived algorithms, including function-approximation extensions), and gives engineering selection guidance.
- Chapter 6 states convergence results with their exact conditions (e.g. GLIE plus per-(s,a) Robbins–Monro step sizes for MC control, an open problem for MCES in general, tabular vs. function-approximation results and the deadly triad). Keep those qualifications when editing; the genealogy figure and the chapter 6 table must stay consistent with the prose.
- Fletcher diagrams, tables, displayed equations, and prose all live inline in `main.typ`. Figures suppress nested equation numbering; `eqbox` also suppresses numbering inside its body.

Cross-references use Typst labels such as `<eq-...>`, `<sec-...>`, `<fig-...>`, and `<tab-...>`. When moving, adding, or renumbering material, update both labels/references and any prose that states theorem, property, chapter, or equation numbers. Mathematical edits must preserve the document's derivation chain: definitions and probability lemmas support later Bellman proofs, so check downstream uses rather than treating each formula as isolated.

Keep the established distinction between random variables (uppercase) and their values (lowercase), and between conditional-expectation and explicitly expanded derivations. The notes assume finite, stationary MDPs and stationary policies unless a passage states otherwise.

## Writing conventions

The document is primarily Chinese, with English technical terms introduced where useful. Follow `Guidelines.md`: use objective, information-dense technical prose; explain mechanisms and consequences; avoid rhetorical suspense, slogans, conversational transitions, exaggerated claims, and formulaic “not X but Y” constructions.

Typography depends on New Computer Modern plus Source Han/Noto CJK fonts, with macOS and Linux fallbacks configured in `main.typ`. Font substitutions can change line breaks and page layout.

## CI and releases

`.github/workflows/typst.yml` compiles `main.typ` on Ubuntu after installing Noto CJK and other fonts, then uploads `bellman-notes.pdf` as the `bellman-notes` artifact. Pushes to `main` only trigger the workflow when `main.typ` or the workflow changes; pull requests and manual dispatches also build it. Tags matching `v*` publish the PDF to a GitHub Release with generated notes. Use GitHub Actions artifacts/releases as the distributable PDFs rather than committing local builds.
