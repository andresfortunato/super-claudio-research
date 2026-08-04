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
