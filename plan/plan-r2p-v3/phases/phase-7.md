# Phase 7 — Docs, constitution, release

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** all phases
**⚠ Gated on decision B** — do the stale v1 `docs/*-mechanism.md` files move to
`docs/v1/`, or get deleted? Recommendation on file: shelf them.
**Session scope:** one session · **Estimated context:** ~45%

## Intent

Not bookkeeping. Three distinct jobs, and the middle one is bug-fixing:

1. **Write the release down once** — the change table and the traps, in the shape
   of `docs/v1-to-v2-migration.md`, which is the best doc in this repo and the
   template to imitate.
2. **Fix live docs that reference files which no longer exist.** v2 merged
   thirteen conventions into seven and did not chase every reference.
3. **Revise the constitution where v3 changed it**, explicitly — the one rule
   `audience-and-philosophy.md` states about itself is that a proposal failing a
   principle revises the document *first*, never silently.

## The measured inventory

`grep -rln` for references to deleted v1 conventions (`script-header`,
`analytical-commit-format`, `data-sources`, `decision-records`, `evidence-logging`,
`handoff-format`, `plan-structure`, `learnings`) hits **eight files**, and they
are not all the same kind of problem:

| File | Kind |
|---|---|
| `.claude/conventions/project-conventions.md` | **live v2 convention** — a real bug; an agent reads this and follows a dead pointer |
| `docs/audience-and-philosophy.md` | **the constitution** — also lists v1's ten `CLAUDE.md` pointer blocks, now seven |
| `docs/verification-architecture.md` | live design doc — and it still presents the **removed** `check-evidence.sh` as "Layer 1" |
| `docs/r2p-adopt.md` | live adoption guide |
| `docs/{evidence-and-claims,migrate-source,data-sources}-mechanism.md` | the v1 shelf question (decision B) |
| `archive/plan-refdocs-conventions.md` | archived — **leave it**; an archive entry describing v1 paths is correct |

## Tasks

**7.1 — `docs/v2-to-v3.md`** ✚ Change table, why each change, and the traps.

**7.2 — `docs/citation-chain-mechanism.md`** ✚ Design rationale for the three
mechanisms, per `docs/extending.md` step 3. Must record the two redesigns and
their reasons — `chart-registry` → `artifacts:` key (principles 6 and 7), and
`pipeline-check` as principle 9 generalized. A future contributor who does not
know why `save_fig(findings={...})` was rejected will propose it again.

**7.3 — Fix the dangling references.** `project-conventions.md` first: it is live
and an agent acts on it. Then `r2p-adopt.md` and `verification-architecture.md`.

**7.4 — Revise the constitution.** Three edits: generalize principle 9 to cover
evidence `## Measured` blocks as anchors; add the compute-graded tier to the
stakes-graded table in principle 7 (and to `verification-architecture.md`); fix
principle 5's v1 pointer-block list. Add the new mechanisms to the
"How the principles bind future additions" table if any needs a new row.

**7.5 — `docs/extending.md`** ✎ Add the pattern v3 actually used —
*cheap lint invariant + user-invoked skill*, in place of the hook that used to be
step 2. And record the trap from `context/installer-map.md`: **a new hook is
mirrored but not wired**, because `--upgrade` never rewrites a project's
`settings.json`. That is the reason v3 adds no hook, and step 2 should say so.

**7.6 — Resolve decision B.** If shelving: `docs/v1/` plus a one-paragraph README
saying these describe v1 and are kept because the case study cites them.

**7.7 — Release.** `README.md` conventions list and version. `package.json` →
`0.3.0` — **after** Phase 6d's `--upgrade` test is green, never before.
`TODO.md`: close v2.1, **cancel** `evidence-ledger` as already shipped-as-`claims.md`
rather than leaving it looking pending, move the plugin migration to v4, and add
the two items this plan generated — the framework repo has no `.claude/settings.json`
of its own (its hooks are unwired here), and it had no `CLAUDE.md` until
2026-08-05. Both are the framework not running the framework; decide deliberately
rather than fixing them in a release commit.

## Verification

- **The Phase 6a link checker, pointed at this repo, reports zero dangling
  references from any live convention or doc.** This is the test; do not
  hand-audit what a tool built in this same release can check.
- `templates/CLAUDE.md.template` gains **zero new sections**. Three new
  mechanisms, one line under *Where Things Go*. §6.7: a mechanism with no
  artifacts does not get a section in the file that loads every session — the
  wiki held two for six months and produced nothing.
- `r2p init` into a throwaway repo: clean scaffold, `lint-research.sh` green and
  silent on the empty tree (all five new invariants must no-op on an empty
  corpus — a linter that fails a fresh install is worse than no linter).
- Then `--upgrade` over a v2 project, per Phase 6d.
- Version bumped exactly once, in the release commit.

## Commit discipline

By pathspec, one command. Keep 7.3 (bug fixes) in commits separate from 7.7
(release) — a reader tracing why a dead pointer was fixed should not land on a
version bump.
