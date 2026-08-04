# Plan Lifecycle — Protocol (v2, merges brainstorm-format, plan-structure, handoff-format, plan-archival)

**Trigger**: any multi-session piece of work — a new analytical phase, a
deliverable build-out, a methodological migration.

v1 had four conventions for one lifecycle: brainstorm → plan → handoff →
archive. They were always read together and each restated the others'
boundaries. One file, four stages.

```
brainstorms/<topic>.md   →   plan/plan-<slug>/   →   handoff.md   →   plan/archive/plan-<slug>.md
   (settle it)                 (do it)              (hand it on)        (close it)
```

---

## Stage 1 — Brainstorm

Settles methodology calls *before* a plan can be written. The brainstorm is the
discussion; the plan is the work; `research/methods/<topic>.md` is the citable
artifact that comes out.

- `brainstorms/<topic>.md`, gitignored (researcher-local working state).
- Slug is decision-bearing: `productivity_deflator_choice.md`, not
  `brainstorm_2026_05_08.md`.

Five sections, which are the **handoff contract** to planning — whoever plans
next should walk straight into `plan.md` without re-debating settled choices:

```markdown
# <Topic> — Brainstorming Summary

## Problem
<2–3 sentences. A reader who agrees can skip the rest.>

## Decisions Made
- <Decision>: <what was chosen> — because <reasoning, with a number or source>.
  <Alternative> rejected because <why>.

## Research Findings
- <Finding>: <source> — <how it bears on the decision>.

## Open Questions
- <Unresolved items the plan must address.>

## Constraints Identified
- <Constraint>: <why it matters — data window, deadline, audience, audit need>.

## Methods to file
- <Calls that graduate to research/methods/<topic>.md.>
```

---

## Stage 2 — Plan

- One directory per plan: `plan/plan-<short-slug>/`. Slugs decision-bearing
  (`plan-cambodia-fdi-decomposition`, not `plan-january-work`).

```
plan/plan-<slug>/
├── plan.md          # the contract
├── handoff.md       # current session state (stage 3)
├── log.md           # direction changes only — required after the first one
├── phases/phase-N.md    # on demand, when a phase splits across sessions
└── output/          # parallel-agent scratch; cleaned at close
```

`plan.md` structure:

```markdown
# Plan: <slug>

## Goal
<2–5 sentences, researcher language. Link the brainstorm that fed it.>

## Constraints
- <hard rules — methodological, infrastructural, audience>
- <what is explicitly NOT changing>

## Decisions Made
<Settled. Do not re-debate during execution. Cross-link
research/methods/<topic>.md for anything a reviewer would question.>

## File Manifest
<Tree of files this plan adds (✚) / modifies (✎) / leaves alone (·). Concrete
enough that a parallel agent can pick a phase and know which files are theirs.>

## Phases
### Phase 1 — <title>
**Intent.** <2–4 sentences>
**Modifies/Adds.** <paths>
**Verification.** <domain-shaped — see below>

## Phase Order + Dependencies
<What blocks what. What can run in parallel.>

## Open Items Deferred
```

### Verification is domain-shaped, not code-shaped

- **Sign matches theory** — "FDI elasticity > 0; flips with the manufacturing
  dummy as expected".
- **Magnitude sanity** — "aggregate matches the published headline within
  rounding".
- **Breakpoint alignment** — "the structural break lands within ±1 year of the
  reform date".
- **Citation present** — "every memo claim references a `research/claims.md`
  entry".
- **Reproducibility** — "script header valid; commit carries `Run:`/`Out:`;
  rerun reproduces the artifact hash".

Linters and type-checks belong in pre-commit hooks, not in `plan.md`.

### Parallel fan-out

A parallel agent obeys **its phase file**, not the handoff. If a correction
lands between planning and launch, **patch the phase files as the last step
before the fan-out** — a fix stored only in `handoff.md` cannot reach a worker
whose phase file is deliberately self-contained. Mark patches visibly
(`⚠ CORRECTED <date>`) and inline measured values so nobody re-derives them.

Route every shared append-target (`research/evidence/INDEX.md`,
`research/claims.md`, the evidence id counter) **through the lead**. Two agents
in one worktree share one git index, so `git add` followed by `git commit` will
happily commit the other agent's staged files.

---

## Stage 3 — Handoff

- One handoff per active plan: `plan/plan-<slug>/handoff.md`.
- **Rewritten in place every session**, never appended. A reader's eye must
  land on current truth without filtering. History is in git; direction changes
  go in `log.md`.

```markdown
# Handoff: <plan-name>

**Status:** <ACTIVE — Phase N complete | PAUSED — reason | CLOSED — date>
**Date:** YYYY-MM-DD
**Last commit:** `<sha>` — "<subject>"   (or `(uncommitted)` — never fabricate)

## Phase status
| Phase | Title | Status | Notes |
|---|---|---|---|
| 1 | <title> | ✅ / 🔄 / ⏭ / ⛔ | <one line> |

## Where we are
<2–6 sentences. What landed. What state the repo is in.>

## What's next
<1–3 ordered moves. Reading order. What to ignore. Parallelizable items.>

## Surprises
<What the next reader should not have to rediscover. Empty beats padded.>

## What didn't work
<Dead ends, so nobody re-runs the experiment.>

## Verification log
<One bullet per check actually run, with the command and expected outcome.>
```

**Three readers, one format** — tune content, not shape:

- *Within-session* (resuming in 10 min): terse; verification log may be empty.
- *Researcher↔researcher*: add reading order and file footprint. They have the
  framework but not your head.
- *Years later*: restate the goal in one sentence and explain **why** the last
  decision was made. Link `research/methods/`.

Never mark a phase ✅ without a verification-log entry.

---

## Stage 4 — Archival

A plan is complete when every phase's verification passed and the researcher
confirms no work remains.

1. `touch plan/plan-<slug>/.completed` — explicit and researcher-controlled,
   never auto-detected from a "COMPLETE" line in prose.
2. The Stop hook finds the marker, writes `.archival-triggered`, and asks for
   the **archivist** subagent.
3. The archivist synthesizes `plan/archive/plan-<slug>.md` (decisions, methods
   landed, files touched, learnings, metrics), appends a line to
   `plan/archive/index.md`, updates CLAUDE.md if the structure changed, then
   deletes `plan/plan-<slug>/`.
4. The sentinel prevents re-blocking if the archivist was interrupted; it is
   removed with the plan directory.

`.completed` is local working state — don't commit it. The archive entry is the
permanent record, committed alongside the deletion.

**Boundary with `/research-cleanup`**: the archivist is per-plan and automated;
`/research-cleanup` is project-wide and user-invoked (orphan scripts, stale
intermediates, unreferenced charts). The archivist may recommend it; it never
scans beyond the plan directory.

---

## Discipline

- **Plans are written before execution**, not retrofitted. Planning during
  execution produces drift.
- **`log.md` records direction changes**, not edits. Renaming a phase is an
  edit; adding or killing one is a log entry.
- **One commit ships the plan and the brainstorm it consumed.**
- **`plan/*/output/` is scratch.** Never let it become a shadow
  `research/evidence/`.
- **Commit the handoff with the work it describes.** A commit shipping Phase N
  without a handoff update tells the next reader Phase N−1 is still live.
