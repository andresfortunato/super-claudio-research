# Plan Structure — Protocol

**Trigger**: Any multi-session piece of work — a new analytical phase, a
deliverable build-out, a methodological migration. Anything you'd want a
teammate or 2028-you to be able to resume from cold.

## Where plans live

- One directory per plan: `plan/plan-<short-slug>/` at project root.
- Slugs are short and decision-bearing: `plan-cambodia-fdi-decomposition`,
  not `plan-january-work`.
- The directory is gitignored in target projects (researcher-local) by
  default; commit it explicitly when collaboration requires it.

## Required files

```
plan/plan-<slug>/
├── plan.md          # the contract: goal, constraints, decisions, manifest, phases
├── handoff.md       # current session state (see handoff-format)
├── log.md           # direction changes, scope shifts, decision pivots
├── phases/          # optional: per-phase notes when a phase splits across sessions
│   └── phase-N.md
└── output/          # parallel-agent scratch; gitignored or cleaned at plan-close
```

`plan.md` and `handoff.md` are mandatory. `log.md` is mandatory once the
plan has had at least one direction change. `phases/` and `output/` are
created on demand.

## `plan.md` required structure

```markdown
# Plan: <slug>

## Goal
<2-5 sentences. The intended outcome, in researcher language. Reference
the brainstorm that fed into this plan if one exists.>

## Constraints
- <hard rules — methodological, infrastructural, audience>
- <things that are NOT being changed>

## Decisions Made
<Decisions consumed from brainstorm or earlier sessions. These are settled.
Do not re-debate during execution. Cross-link to decisions/YYYY-MM-DD_*.md
files for any methodology call worth defending in peer review.>

## File Manifest
<Tree of files this plan adds (✚) / modifies (✎) / leaves alone (·).
Concrete enough that a parallel agent can pick a phase and know exactly
which files are theirs.>

## Phases
### Phase 1 — <title>
**Intent.** <2-4 sentences>
**Modifies/Adds.** <bullet list of paths>
**Verification.** <domain-shaped checks — see below>

### Phase 2 — …

## Phase Order + Dependencies
<Which phases block which. Which can run in parallel.>

## Open Items Deferred
<Decisions explicitly pushed to a later plan.>
```

## Verification: domain-shaped, not code-shaped

scc's planning skill verifies phases with code-shaped checks ("the test
passes", "the type-check is green"). Research adapts this. Phase
verification in `plan.md` should be **domain-shaped**:

- **Sign of coefficients matches theory** ("FDI elasticity > 0 in
  diversification specs; flips sign with the manufacturing dummy as
  expected").
- **Magnitude sanity** ("aggregate matches the World Bank headline within
  rounding").
- **Breakpoint alignment** ("the structural break lands within ±1 year of
  the privatization reform date").
- **Source citation present** ("every claim in the memo references either
  an `evidence/NN_*.md` doc or a `wiki/` page").
- **Reproducibility** ("script has a valid header; commit message has
  `Run:`/`Out:` lines per the analytical-commit-format convention;
  rerunning produces the same artifact hash").

Code-style checks (linters, type-checkers) belong in pre-commit hooks, not
in `plan.md`'s verification section.

## Methodology decisions

For any methodology call you would want defended in a peer review — choice of
deflator, identification strategy, sample restriction, deflation base year —
file a `decisions/YYYY-MM-DD_<slug>.md` per the `decision-records`
convention and reference it from `plan.md`'s **Decisions Made** section.
Don't inline the rationale in `plan.md` — the decision file is auditable on
its own and survives plan close-out.

## Discipline rules

- **Plans are written before execution**, not retrofitted. Brainstorm →
  plan → execute is the cadence; planning during execution produces drift.
- **`log.md` records direction changes**, not minor edits. Tweaking a phase
  title is just an edit; adding/rejecting a phase is a log entry.
- **One commit ships the plan + the brainstorm it consumed.** Decision
  genealogy survives plan close-out.
- **`output/` is scratch.** Parallel agents may stage intermediate files
  there; gitignore or clean on plan close. Do not let it become a shadow
  `evidence/`.

## Completion and archival

A plan is "complete" when every phase's verification has passed and the
researcher has confirmed there is no remaining work. At that point:

1. **Create the marker.** `touch plan/plan-<slug>/.completed`. The marker
   is intentionally explicit — researcher-controlled, not auto-detected
   from a "✅ COMPLETE" line in `handoff.md` (which would mis-fire on
   intermediate phase-completion summaries).
2. **Stop hook fires.** On the next Stop event, the
   `check-evidence.sh` hook (Tripwire 1) finds the marker, writes a
   `.archival-triggered` sentinel, and emits a Stop-blocking instruction
   to launch the **archivist** subagent
   (`~/.claude/agents/archivist.md`).
3. **Archivist runs.** It reads `plan.md`, `handoff.md`, and `log.md`,
   synthesizes `archive/plan-<slug>.md` (key decisions, methods landed,
   files modified, learnings, metrics), appends a one-liner to
   `archive/index.md`, updates `CLAUDE.md` if architecture changed,
   then deletes `plan/plan-<slug>/` entirely.
4. **No re-block.** The `.archival-triggered` sentinel protects against
   re-blocking on subsequent Stop events if the archivist invocation
   was interrupted; the sentinel is removed with the plan directory
   when the archivist completes.

**Boundary with `/research-cleanup`.** The archivist is *per-plan and
automated* (synthesizes the archive entry, deletes the plan directory).
`/research-cleanup` is *project-wide and user-invoked* (audits orphan
scripts, stale intermediates, unreferenced charts). The two are
complementary, never overlapping. If a completed plan touched many
source files, the archivist recommends the user run `/research-cleanup`
afterward; the archivist itself does not scan beyond the plan
directory.

**Do not** rename `.completed` to anything else, edit it after creation,
or commit it (the marker is local working state). The archive entry —
`archive/plan-<slug>.md` — is the permanent record committed alongside
the deletion of `plan/plan-<slug>/`.

## Why scc-style at project root

`plan/plan-<slug>/` at project root is discoverable in one `ls` and matches
the planning skill's expectations. The nested `quality_reports/plans/`
alternative was rejected. See `docs/plan-structure-mechanism.md`.
