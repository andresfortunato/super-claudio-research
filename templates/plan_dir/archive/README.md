# plan/archive/

Permanent project memory. One markdown file per completed plan, plus
`index.md` as the rollup.

## What lives here

When a `plan/plan-<slug>/` directory is marked complete (the researcher
runs `touch plan/plan-<slug>/.completed`), the Stop hook fires the
**archivist** agent (`~/.claude/agents/archivist.md`). The archivist
reads `plan.md`, `handoff.md`, and `log.md`, synthesizes a 60–150-line
archive entry at `plan/archive/plan-<slug>.md`, appends a one-line summary
to `plan/archive/index.md`, updates `CLAUDE.md` if the plan changed
architecture, and deletes `plan/plan-<slug>/` entirely.

Each archive entry preserves:
- **What was built** — the intended outcome and what shipped.
- **Key decisions** — the calls future readers should inherit, with
  cross-links to `research/methods/<topic>.md` for peer-review-grade
  methodology calls.
- **Methods landed** — cross-links to any `research/methods/<topic-slug>.md`
  files the plan created or materially changed.
- **Files added or modified** — the actual file manifest, post-execution.
- **Learnings** — surprises, gotchas, dead ends extracted from the
  plan's `handoff.md` and `log.md` (separate from `research/methods/<slug>.md`,
  which captures *retrievable* tacit knowledge).
- **Metrics** — phases completed, sessions, final commit SHA.

## Why this exists, not just `git log`

Git captures the *changes*. The archive captures the *plan-shaped
synthesis* — what a future reader needs to know about a multi-session
piece of work in 100 lines instead of reconstructing from 30 commits
and a deleted plan directory. Without the archive, completed plans
would either pile up under `plan/` (signal-to-noise erodes as count
grows) or vanish entirely (decisions become uninherited). Full
rationale: `.claude/conventions/plan-lifecycle.md`, Stage 4.

## What does NOT live here

- **Active or in-progress plans.** Those live at `plan/plan-<slug>/`
  until completion.
- **Learnings.** Tacit gotchas live at `research/methods/<slug>.md` — separately
  retrievable, indexed by trigger keywords. The archivist may *mention*
  them in the Learnings section of an archive entry, but does not
  duplicate their content.
- **Decision records.** Methodology calls worth defending in peer
  review live at `research/methods/<topic>.md` — durable beyond any
  single plan. The archive entry cross-links to them.
- **Source code.** Scripts, notebooks, data, charts, evidence stay
  where they are; the archive entry references them but never copies
  them.

## Boundary with `/research-cleanup`

`/research-cleanup` audits *project-wide* cruft (orphan scripts, stale
intermediate CSVs, unreferenced charts, scratch notebook cells). The
archivist runs *per-plan* and stops at the plan boundary. After
archiving a plan that touched many source files, the archivist
recommends running `/research-cleanup` separately. No overlap.
