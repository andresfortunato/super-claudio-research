# Before declaring an evidence gap, search the DATA LAYER, the WIKI, and non-checked-out BRANCHES — "no research/evidence/ doc exists" ≠ "no evidence exists" in this multi-worktree project

## What

Fact-checking the growth-diagnostics narrative, a parallel research fan-out declared two
claims (C7 "no new export products since 2011"; C17 "Córdoba produces quality cattle but
doesn't export") to be **gaps needing new/external analysis** — because each agent searched
only `research/evidence/*.md`. Both were wrong. The evidence existed:

- **C7** was fully answered by `data/processed/exports_opex/new_products_*_by_province.csv`
  (0 new RCA≥1 products 2011→2025) — a **data-layer table with no evidence doc**, plus a
  Fundar PDF in `reference/literature/`.
- **C17 beef** was fully answered by `research/evidence/28_..._beef_collapse.md` + `#30` and
  `beef_freight_arithmetic.csv` — but on branch **`plan-cordoba-export-diversification`**,
  which was **not checked out as a worktree**, so a path-based `ls research/evidence/` in the active
  worktrees never saw it.

The researcher had to redirect twice ("see the new_exports tables", "the beef work is on
plan-cordoba-export-diversification @ 85a0b3c"). Both redirects pointed at evidence that a
broader search would have found.

## Why it bites

This project runs ~13 branches across ~10 git worktrees (see `git worktree list`), PLUS
branches that exist on origin but aren't checked out anywhere. Findings live in four places,
not one: `research/evidence/` docs, `data/processed/` tables (often ahead of any write-up), `research/wiki/`
(distilled synthesis + `raw/literature/` PDFs), and **other branches**. An agent scoped to
`research/evidence/` in the current worktree sees maybe a quarter of the corpus.

## Prevention

Before writing "🔎 gap / needs new analysis" for any claim:
1. **Grep the data layer**, not just evidence docs: `grep -ril "<topic>" data/processed/`
   and scan `ls data/processed/<theme>/` for a table whose name answers the claim.
2. **Check the wiki**: `research/wiki/synthesis/`, `research/wiki/concepts/`, `research/wiki/entities/`,
   `reference/literature/`.
3. **Check branches not checked out.** `git worktree list` shows only checked-out branches;
   also do `git branch -a | grep <topic-ish>`. Read a non-checked-out branch **read-only**
   with `git show <branch>:<path>` (all worktrees share one object store — no checkout, no
   edit, safe against locks). Ask the researcher which branch owns a value chain if unsure —
   they know the worktree map.
4. A LibreOffice **lock file** (`.~lock.<name>#`) means the file is open, not empty — reading
   it read-only is fine; don't conclude "empty".

## The citation trap that follows

Once you pull a number off another branch, remember evidence numbers COLLIDE across branches
(`#28`/`#30` mean different things on `plan-cordoba-export-diversification`, this repo, and
`export-shiftshare-periods`). Cite by **branch + path/content**, never bare `#NN`. See
[[evidence-number-collision-parallel-worktrees]] and [[evidence-number-collisions-parallel-teams]].
