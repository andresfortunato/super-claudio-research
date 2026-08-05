# Evidence — Protocol (v2)

**Trigger**: after any data-analysis session, phase, or implementation step
that produces evidence (charts, panels, comparisons, regressions,
decompositions).

**What changed in v2 and why**: v1 asked for `**claim** — number — implication`
in one bullet. Authors complied by writing *verdicts* ("H3 confirmed",
"REFUTED"), and 338 verdict words accumulated across 93 of 151 docs on the
pilot engagement. **Measurements do not contradict each other; verdicts do.**
v2 separates the two, moves scope into machine-readable frontmatter, and caps
the index row. Read `claims.md` next — evidence alone does not scale past ~40
docs.

## Where evidence lives

- `research/evidence/NN_<short_slug>.md`.
- `NN` comes from `research/evidence/.next-id`, a single-line counter. **The
  lead session allocates; parallel workers request a block up front and the
  lead bumps the counter once.** Do not derive the next id from `ls` — that is
  how the pilot produced three colliding ids across parallel worktrees.
- Index: `research/evidence/INDEX.md`, one row per doc, **capped** (below).
- Never overwrite or delete an evidence doc. Revise by appending a new one and
  setting `status` on both. The corpus is append-only; `claims.md` is the
  editable layer.

### Before declaring a gap, search wider than `research/evidence/`

**"No evidence doc exists" ≠ "no evidence exists."** Findings live in four
places: evidence docs, `data/processed/` tables (often ahead of any write-up),
the wiki plus `reference/literature/`, and **branches not checked out anywhere**.
An agent scoped to `research/evidence/` in the current worktree can be seeing a
quarter of the corpus. On the pilot, two claims were declared gaps needing new
analysis when one was already answered by a `data/processed/` CSV that had no
doc, and the other by two evidence docs on a branch no worktree had checked out.

Before writing "gap / needs new analysis" for any claim:

1. `grep -ril "<topic>" data/processed/` — and scan the directory listing; a
   table whose name answers the claim often exists with no write-up.
2. Check the wiki and `reference/literature/`.
3. `git branch -a`, not just `git worktree list` — the latter shows only
   checked-out branches. Read a non-checked-out branch with
   `git show <branch>:<path>`: all worktrees share one object store, so this
   needs no checkout and is safe against locks. A `.~lock.<name>#` file means
   the file is **open**, not empty.

Once you pull a number off another branch, **cite it by branch + path**, never
by bare `#NN` — ids collide across branches.

## Required shape

```markdown
---
id: 148
status: live                 # live | revised | retired
supersedes: [122]            # ids whose reading this replaces
superseded_by: []
date: 2026-08-03
unit: metro                  # nation | province | dpto | metro | fua | sector | firm
geography: Gran Córdoba (EPH aglomerado 13)
period: 2014–2025
kind: measurement            # measurement | comparison | decomposition | scenario | null-result
confidence: high             # high | medium | low
data: [eph_microdata, cep_sipa]     # research/sources/ stems
methods: [real-wage-measurement]    # research/methods/ slugs this rests on
artifacts:                          # OPTIONAL. Charts/tables this doc explains.
  - output/labour/emp_rate.png      # Hand-authored or absent — never inferred.
---

# <Headline measurement — ≤120 chars, no verdict>

## Measured
| Quantity | Value | Comparison | Cell |
|---|---|---|---|
| formal employment rate, GC | 41.2% (2025) | nation 45.0% | `output/…/emp_rate.csv:L14` |

## Reading
<2–5 sentences. The author's interpretation, and the ONLY place a verdict may
appear. If it depends on a methodology call, link the research/methods/ doc.>

## Scope
<What this does NOT establish. Unit and period limits. Known confounds. Why a
differently-scoped number elsewhere is not a contradiction.>

## Provenance
<Script · inputs · chart paths · seed.>
```

### The `Measured` / `Reading` split is the load-bearing rule

- **`## Measured` holds numbers and nothing else.** No "confirms", "refutes",
  "proves", "verdict", "rejected". A row is a quantity, its value, what it is
  being compared against, and the cell it came from. Every row must be
  re-derivable from `## Provenance`.
- **`## Reading` holds the interpretation, clearly owned by its author.** It may
  be wrong without making `## Measured` wrong. When a later doc disagrees, it
  disagrees with the reading — say so in that doc's `supersedes:`.
- A synthesizing session reads `## Measured` across docs and writes the reading
  **once**, at narrative level. That is the whole point: it stops inheriting
  151 pre-baked verdicts that were never reconciled with each other.
- **The fixed headers are also what keeps the corpus machine-readable.** Any
  digester that scrapes findings by `line.startswith("**")` under a
  `## Findings`-style header keeps only the **first physical line** of a
  hard-wrapped paragraph — headline retained, every number dropped — and a doc
  with no `###` children comes back **empty**. On the pilot, measured per-doc
  digest retention ranged **22–96%** around a 42% mean, and the low end was
  concentrated in the docs carrying the most numbers. A `## Measured` table row
  is immune because it is one line.

**Never plan a reading strategy against a corpus-wide mean.** Before
digest-reading a set of docs, measure retention per doc and full-read everything
under ~50%; `grep -c '^### ' <doc>` is the cheap structural proxy, and zero
means the findings will be lost wholesale. Do **not** "fix" the digester
mid-phase — a parallel sub-phase reading the same corpus through a changed
digest produces fragments that are not comparable, and because
`research/evidence/` is append-only the docs cannot be reformatted to suit it
either. Measure and route instead.

### Frontmatter scope keys make contradictions checkable

`unit` + `geography` + `period` exist so that "these two docs disagree" becomes
a mechanical test: **two findings can only contradict each other if their unit
and period overlap.** A province number and a metro number on the same topic
are not in conflict; they measure different objects. On the pilot engagement,
two separate hard-won project rules — *cities are the unit for labour claims*,
*never use modelled population where a census exists* — were both scar tissue
from this one missing field.

`confidence` is `low` when the doc rests on a proxy, a modelled input, a single
thin cell, or a period the source does not cleanly cover. Say which in `Scope`.

### `artifacts:` — which finding a chart carries

Optional list of the chart and table paths **this doc is the written-up finding
for**. `git log` already records how an artifact was produced; what nothing
recorded was *which finding it carries*, so a chart could sit in a deliverable
with no evidence doc behind it and nothing could see the absence. On the pilot
that happened to a headline exhibit for six months. With the key, "chart exists
with no evidence doc" becomes a `test -f` rather than a judgement call.

- **Hand-authored or absent. No heuristic may ever populate it**, and no script
  may back-fill it by matching filenames, directories or mtimes. The reason is
  measured: v2's scope-key inference tagged a 24-province panel as
  `metro | 1960–2026` because a year regex swept every number in the first 6 KB
  of the doc. **A confidently wrong field manufactures the exact false
  contradiction the field exists to prevent.** A blank makes a reader open the
  doc; a wrong one makes them trust it.
- **Absent is a legitimate, common state** — a doc that measures something with
  no chart has nothing to bind. Absent means "not stated", never "none exist".
- Paths are repo-relative, exactly as they appear on disk. Lint checks both
  directions: a deliverable's chart with no doc listing it (invariant 9) and a
  listed path that does not exist (invariant 12).

See `.claude/conventions/citation-discipline.md` for the full chain this key is
one link of.

## The INDEX is a triage table, not a summary

```
| id | headline | unit | period | status | conf | file |
```

- **`headline` is hard-capped at 120 characters.** Lint enforces it.
- No caveats, no findings lists, no source strings, no retraction prose in the
  index. All of that lives in the doc.
- Rationale: the pilot's index reached **330 KB** with a median title of 1,554
  chars and a longest of 10,410 — larger than its five biggest evidence docs
  combined. Every synthesis session paid ~80k tokens to read it and got
  undifferentiated prose back. The capped shape is ~22 KB for 151 rows.

## Status and supersession

- **`live`** — in force.
- **`revised`** — part of the doc is retired. Put **one** banner at the top of
  the doc: `> ⚠ <leg> retired YYYY-MM-DD — <what replaced it>. Rest stands.`
  Set `superseded_by:` and set `supersedes:` on the replacing doc. **The banner
  never goes in the INDEX** — `status` carries it there.
- **`retired`** — the whole doc is superseded. It stays in place; the audit
  trail depends on it surviving.

A retraction that exists only as prose is invisible to a filter, which is how
the pilot ended up citing retired legs from doc bodies while the index
carried the warning.

## What counts

- A **specific number** a reader can cite, with its comparison and its cell.
- Something **non-obvious**: surprising, contradicts a prior, sharpens framing.
- 3–8 rows in `## Measured` per doc. Fewer means the analysis was thin; more
  means padding.

## What doesn't

- "We built a chart of X" (process, not finding).
- Stylized facts already in CLAUDE.md or a prior doc.
- Anything without a number, percentile, or named comparison.
- A verdict outside `## Reading`.

## Discipline

- One commit updates the doc **and** `INDEX.md`.
- Evidence is a project asset, not a plan artifact — it outlives the plan.
- **Past 40 docs, `research/claims.md` becomes mandatory.** Append-only
  evidence at scale needs a curated layer above it or every synthesis session
  rebuilds one from scratch, differently. See `claims.md`.

## Distinct from neighbours

- **`claims.md`** — the curated, editable ~40-entry view. Deliverables cite
  claims; claims cite evidence. Evidence stays append-only underneath.
- **`research/methods/`** — *how* we measured, and the traps in doing so.
  Evidence is *what came out*.
- **handoff** — tactical session state. Evidence is substantive.
