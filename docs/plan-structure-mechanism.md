# Plan structure mechanism — design rationale

## The problem this solves

Research projects fail in two opposite directions when planning is
mishandled:

1. **No plan → drift.** A project run as "do the next obvious thing" gets to
   month three with charts, half-finished memos, and no shared mental model
   of what the engagement is delivering. Course-corrections are expensive
   because everyone's mental model has diverged.
2. **Overheavy plan → ossification.** A plan that prescribes every analysis
   in advance is wrong by month two and gets quietly abandoned. Researchers
   stop reading it because it doesn't reflect reality, which is exactly when
   it would have been most useful.

The plan structure convention is the middle path: enough scaffolding to
keep direction shared, light enough to remain a living document.

## The scc adaptation

scc (the source of much of this framework's discipline) ships a `planning`
skill that produces `plan/plan-<slug>/{plan.md, handoff.md, log.md}`.
We adopt the directory layout and the file roles directly. What changes for
research:

- **Verification language.** scc verifies phases with code-shaped checks —
  the test passes, the build is green, the type-check is clean. Research
  doesn't have those primitives. Sign-of-coefficients, magnitude sanity,
  breakpoint alignment, and source-citation presence are the analogous
  checks. The convention spells these out so a researcher writing a phase
  doesn't fall back on "I'll know when it's done."
- **Decision capture.** Code projects can absorb most decisions into the
  diff (you can read the change to see what was decided). Research
  decisions — choice of deflator, identification strategy, sample
  restriction — are usually invisible from the diff and need a separate
  audit trail. We added the `decision-records` convention as a sibling and
  cross-link it from `plan.md`.
- **`brainstorms/` as plan input.** scc's planning skill assumes the user
  has done the thinking before invoking it. We make the brainstorm an
  explicit, committed artifact (`brainstorms/<slug>.md`) consumed by the
  plan. Decision genealogy survives the plan's close-out.
- **`output/` for parallel-agent scratch.** scc plans rarely run with
  parallel agents; ours do (deliverable review fan-out, ingestion runs).
  The `output/` subdir gives parallel agents a scratch space that doesn't
  pollute `evidence/` or `methods/`.

## Why project-root vs `quality_reports/plans/`

Two layouts were on the table for v1:

- **scc-style: `plan/plan-<slug>/`** at project root. Sibling of `data/`,
  `output/`, `notebooks/`. Discoverable in one `ls`. Matches the planning
  skill's expectations.
- **Pedro-style: `quality_reports/plans/<slug>/`**. Nested under a
  meta-quality directory. More structured, but adds a level of indirection
  every time someone wants to read a plan.

We picked scc-style. The argument was discoverability: in a 6-month
engagement with multiple researchers, the plan directory is read dozens of
times more often than it's written. Saving 1.5 seconds per read times
hundreds of reads beats the conceptual cleanliness of the nested layout.
The decision is recorded in the v1-framework brainstorm.

## Multi-session handoff via this layout

The plan layout co-evolves with `handoff-format`. `handoff.md` is *inside*
the plan directory, not at project root, because:

- A project may have multiple active plans (rare but allowed).
- Closing a plan keeps its handoff in place as a historical artifact.

The `phases/phase-N.md` split is reserved for phases that themselves span
multiple sessions and accumulate enough state that a single-line entry in
`plan.md`'s phase table is no longer sufficient. Most phases never need
this; when they do, the convention tells you where to put the file rather
than leaving it to ad-hoc placement.

## What this does NOT do

- **It does not replace evidence-logging.** Plans describe intent and
  scope; evidence describes what the data taught you. A plan whose
  verification log says "phase 3 done" is not a substitute for the
  `evidence/NN_*.md` doc that records the substantive findings.
- **It does not enforce a planning-before-execution norm at runtime.** A
  Stop hook could detect "edits in `notebooks/` without a plan" and nudge,
  but that would punish legitimate exploratory work. We rely on the
  researcher to know when a piece of work is plan-shaped.
- **It does not coordinate across plans.** Multi-plan projects rely on the
  researcher to decide ordering. A vault-manager-style WIP-limited
  dashboard (Hugo's pattern) is deferred to v1.1.

## Tradeoffs accepted

- **Slug naming is on the honor system.** `plan-january-work` will pass
  the convention but lose all decision-bearing value. We accept this
  because no automated check can tell a good slug from a bad one.
- **`log.md` discipline drifts.** Direction changes are easy to fold
  silently into `plan.md` instead of logging them. The cost is
  invisibility of the decision genealogy when someone returns to the
  plan a year later. The convention asks for the discipline; reviewer
  pressure is the only enforcement.
- **The directory is gitignored by default in target projects.** This
  preserves researcher-local working state (the framework repo's own
  `plan/` is committed because the *build* of the framework is itself
  a research-style project). Teams that want to share plans across a
  branch will need to remove the `plan/` line from `.gitignore`
  explicitly.

## Extension points

- **`phases/phase-N.md` split.** When a phase grows beyond a single
  paragraph in `plan.md`, give it its own file. Reference it from the
  phase table in `plan.md`.
- **Per-deliverable plans.** A complex deliverable (a 30-page country
  diagnostic) can be its own plan: `plan/plan-cambodia-diagnostic/`.
  No convention change needed.
- **Closure ritual.** When closing a plan, file a `decisions/YYYY-MM-DD_<slug>-close.md`
  capturing what the plan delivered vs what it intended, what was deferred,
  and what changed about your priors. Optional but high-leverage for
  long-running engagements.
