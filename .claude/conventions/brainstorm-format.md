# Brainstorm Format — Protocol

**Trigger**: Any methodology call, identification choice, or analytical-design
question that needs to be settled *before* a plan can be written. The
brainstorm is the discussion; the plan is the work; the decision record (if
filed) is the citable artifact.

The brainstorming skill (`.claude/skills/brainstorming/SKILL.md`) drives the
conversation. This file documents the **shape of the output**, the
**handoff to the planning skill**, and the boundary with neighboring
conventions.

## Where brainstorms live

- One file per topic: `brainstorms/<topic>.md`.
- `brainstorms/` lives at project root, sibling of `plan/`, `evidence/`,
  `decisions/`. It is **gitignored** (researcher-local working state, not a
  shared artifact). Decisions that graduate to citable status get filed in
  `decisions/` instead.
- Slug is short, decision-bearing: `productivity_deflator_choice.md`,
  not `brainstorm_2026_05_08.md`.
- Theme-parallel projects (see `evidence-logging.md`) may use
  `brainstorms/<theme>/<topic>.md` for theme-bound discussions; flat is
  the default. Cross-cutting brainstorms always stay flat.

## Required structure

```markdown
# <Topic> — Brainstorming Summary

## Problem
<What we're trying to answer or measure — 2-3 sentences. The reader should
be able to skip the rest if this section already settles the question.>

## Decisions Made
- <Decision>: <what was chosen> — because <reasoning, with a number or
  source where possible>. <Alternative> was rejected because <why>.
- <Decision>: ...

## Research Findings
- <Finding>: <source — paper, dataset note, peer convention> — <how it
  applies to our decision>.

## Open Questions
- <Anything unresolved that the planning skill needs to address.>

## Constraints Identified
- <Constraint>: <why it matters — data window, deliverable deadline,
  counterpart audience, audit-trail need>.

## Decision records to file
- <Methodology calls a peer reviewer would push on. The researcher files
  these once at `decisions/YYYY-MM-DD_<slug>.md` after the brainstorm.>
```

The five sections (Problem / Decisions / Research / Open Questions /
Constraints) are the **handoff contract** to the planning skill. Whoever
runs `/planning` after the brainstorm should be able to walk straight from
this file into `plan/plan-<slug>/plan.md` without re-debating settled
choices. A "Decision records to file" section is optional but useful when
choices made in the brainstorm should graduate to `decisions/`.

## Handoff to the planning skill

The brainstorming skill triggers **the planning skill** by name — agnostic
about whose. r2p does not ship its own planning skill in v1.1; it relies
on the planning skill installed globally (typically from
`super-claudio-code`). When the brainstorm is complete and the researcher
says "go to planning", the brainstorming skill writes the summary file
and hands off — it does not write the plan itself.

## Discipline

- **The brainstorm captures decisions, not the plan.** Implementation
  steps, file lists, and verification gates belong in the plan, not in
  the brainstorm. If a brainstorm starts naming files to edit, stop —
  decisions are settled enough; trigger the planning skill.
- **Methodology calls graduate to `decisions/`.** Choices a peer reviewer
  would push on (deflator, identification, sample restriction) get filed
  once at `decisions/YYYY-MM-DD_<slug>.md`. The brainstorm records the
  conversation; the decision record is the citable artifact. Naming
  candidates in the "Decision records to file" section keeps the
  graduation explicit.
- **Brainstorms are append-only by convention, not by rule.** If a
  later session revisits a brainstorm, prefer dated `## Update: <date>`
  sections (mirroring the addendum pattern in
  `internal-research-memo`) over rewriting earlier text.
- **Brainstorms are not evidence.** Evidence is chart-backed findings
  with concrete numbers (`evidence/NN_*.md`); brainstorms are
  decisions-pre-execution. Don't conflate.

## Distinct from neighboring conventions

- **`plan-structure`** — plans capture *implementation steps*; brainstorms
  capture *the decisions a plan rests on*. A brainstorm typically
  precedes a plan; a plan should rarely re-debate brainstorm decisions.
- **`decision-records`** — decision records are the *citable, auditable*
  form of methodology calls (one file per decision; structured;
  committed). Brainstorms are the *conversation* that produced them
  (gitignored; free-form; transient working state).
- **`evidence-logging`** — evidence describes *what the data shows*;
  brainstorms describe *how we chose to look at it*.
- **`/verify`** — `/verify` sanity-checks a single existing artifact (a
  regression, a chart, a paragraph). Brainstorming happens *before* the
  artifact exists.
- **`handoff-format`** — handoffs are tactical session-state ("what's
  done, what's next"); brainstorms are durable-until-decided design
  artifacts.

## What this does NOT do

- **Doesn't enforce a length.** Five-line brainstorms ("we picked X
  because Y") are fine if the discussion was short. Longer brainstorms
  with three rounds of trade-off comparison are also fine. Match the
  shape to the question.
- **Doesn't auto-trigger the planning skill.** The brainstorming skill
  hands off explicitly when the researcher signals readiness ("let's
  write the plan"). Until then, the brainstorm stays in conversation.
- **Doesn't replace `decisions/`.** A brainstorm is not a decision
  record. The brainstorm names which decisions should graduate;
  the researcher files them.

## Provenance

This convention codifies a gap surfaced by an audit of an applied-research
project that ran without r2p conventions: a long methodology essay had
been written that *felt* like a plan but never produced one — implementation
sessions kept stalling because the methodology calls hadn't actually been
settled. The brainstorming skill closes that gap by making "settle the
decisions" a distinct, named step before "write the plan."

Rationale: `docs/brainstorm-mechanism.md`.
