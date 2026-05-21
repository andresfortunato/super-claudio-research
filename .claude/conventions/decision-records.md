# Decision Records — Protocol

**Trigger**: Any methodology call you would want to defend in a peer review,
or that you would otherwise re-debate with yourself in three months.
File once; never re-derive.

This is the policy-research analog of pre-registration: lighter than a full
pre-analysis plan, heavier than a code comment. It is **not** an
Architectural Decision Record (ADR) — those describe software architecture.
A decision record here describes a *research* decision: a choice of
deflator, an identification strategy, a sample restriction, a model
specification, a data-source preference.

## Where decision records live

- One file per decision: `decisions/YYYY-MM-DD_<slug>.md`.
- `decisions/` lives at project root, sibling of `evidence/`, `wiki/`,
  `data/`. The directory is **committed** (researcher-shared, not local).
- Slug is short, decision-bearing: `2026-05-12_use-pwt-rgdpe-not-rgdpo.md`,
  not `2026-05-12_decision1.md`.
- Numbering is implicit (sortable by date). If two decisions land on the
  same day, order doesn't matter — slug carries the meaning.

## Required structure

```markdown
# <Decision — concrete claim, not "Choice of X">
**Date**: YYYY-MM-DD
**Plan**: <plan/plan-<slug>/ this decision feeds, or "project-level" if cross-plan>
**Status**: active | superseded by `YYYY-MM-DD_<other>.md` | invalidated YYYY-MM-DD

## Decision
<2-4 sentences. The choice made, in concrete terms. Reader should be able
to act on it without reading the rest.>

## Alternatives considered
- **<alt 1>** — <one-sentence description>
- **<alt 2>** — <one-sentence description>
- **<alt 3>** — <one-sentence description>

## Why rejected
<For each alternative, the specific reason. Be empirical: "PWT rgdpo
inflates oil-exporter productivity by ~40% in our sample" beats
"rgdpo is misleading."  Cite a number or a source.>

## Key assumptions
<What has to be true for this decision to be the right one. The places a
reviewer would push back. Examples: "data are MAR within country-year",
"the relevant counterfactual is the regional-mean trajectory."  Be honest
about what's load-bearing.>

## What would invalidate this decision
<Concrete tripwires. Examples: "PWT 11.0 release reconciles rgdpo and
rgdpe to within 5% in our sample", "Cambodia 2025 LFS reveals informal
share of manufacturing employment >2× our prior", "the IV first-stage
F-stat falls below 10 on the extended sample." This is the section that
makes the record auditable later — not a vague "if circumstances change."
```

## When to write one

Write a decision record when **any** of the following hold:

- A peer reviewer would ask "why did you choose X over Y?" and the diff
  alone wouldn't answer it.
- Re-doing the analysis without this decision would change the headline
  number by more than ~10%.
- You found yourself re-debating the same choice with yourself a second
  time. (The first re-debate is the trigger to file the record.)
- A pilot counterpart, donor, or publication referee will ask about it.

Do **not** write one for:

- Stylistic choices (chart palette, file naming).
- Decisions whose alternatives are obviously inferior (you don't need a
  record for "use the most recent World Bank vintage").
- Micro-implementation calls (loop vs vectorize, comprehension vs map).
  Code comments are sufficient.

## Lifecycle: invalidate vs supersede

- **Active.** The default state. Decision is in force.
- **Superseded.** The decision was replaced by a later one (e.g., new data
  arrived, methodology evolved). The original record is **not edited** —
  it stays in place with `Status: superseded by YYYY-MM-DD_<other>.md` so
  the genealogy is preserved. The new record references the old in its
  body, including which assumption broke.
- **Invalidated.** The decision turned out to be wrong on its own terms,
  not replaced by a successor. Mark with
  `Status: invalidated YYYY-MM-DD` and add a one-paragraph postmortem at
  the bottom: what was missed, what would have caught it sooner.

Never delete a decision record. Audit trails depend on the record
surviving even after the decision is wrong.

## Discipline rules

- **One commit ships the decision record with the analysis it governs.** A
  regression depending on a deflator choice is committed alongside the
  `decisions/YYYY-MM-DD_use-<deflator>.md`. Future `git blame` surfaces both.
- **Cross-link from `plan.md`.** A plan's `Decisions Made` section
  references the relevant `decisions/*.md` files by relative path.
- **Cross-link from evidence.** If `evidence/NN_*.md` rests on a methodology
  call, link the record from the insight's Source line so invalidation has
  a known impact surface.
- **The record is the artifact, not the discussion.** Brainstorms and
  threads may prefigure the decision; the record is what you cite.

## How many

A 6-month engagement typically produces 5–15 decision records. Fewer than 5
means decisions aren't being captured; more than 30 means micro-calls are
being over-recorded. Calibrate to "would a peer reviewer ask?"

## Distinct from neighboring conventions

- **`evidence-logging`** captures *findings* from the data; decisions
  capture *choices* about how to look at it.
- **`plan-structure`'s "Decisions Made"** is a pointer list; records live in `decisions/`.
- **`handoff-format`** is tactical session state; decisions are durable.
