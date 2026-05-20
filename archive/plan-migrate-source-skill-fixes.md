# /r2p-migrate-source Skill — Discovery & Smoke-test Gap Fixes

Completed: 2026-05-20

## What was built

A focused follow-up to `plan-migrate-source-skill` (see [parent plan archive](plan-migrate-source-skill.md)),
addressing 4 concrete gaps surfaced by a dry-run of the original SKILL against the first
non-trivial donor (`~/cambodia-growth`). All four edits landed in a single editing pass on
`.claude/skills/migrate-source/SKILL.md`, growing it from 489 to 603 lines. Atlas migration
(previously blocked) and IMF migration (previously passing, used as regression canary) both
validated end-to-end. The full bundle — parent plan's staged docs/wiring plus these SKILL
fixes — committed at `fee5051`.

## Key decisions

1. **Missing ref doc → warn-and-proceed + bootstrap a 5-line stub (not refuse-to-proceed).**
   When `Glob data_sources/<slug>*.md` finds nothing at the donor, the SKILL now records
   "no ref doc found," continues with other discovery anchors, emits a `## Warnings` block in
   the proposal, and writes a minimal stub at `<target>/data_sources/<slug>.md` on apply.
   MIGRATION_TODO gains a leading "write ref doc from scratch" step. Alternative considered:
   refuse and require the donor to add a ref doc first. Rejected because (a) donor cost of
   migration is not the receiving project's to impose, (b) the `Full guide: data_sources/<slug>.md`
   back-link in wrapper docstrings is load-bearing for the INDEX bridge — landing even a stub
   keeps the target convention-compliant so future wrapper edits can add the back-link without
   dangling, and (c) future donors will share this pre-convention shape.

2. **Banner-based discovery as a stable third anchor (not a compat shim).**
   Phase A step 3 now has three anchors: slug-prefix on `def` name (existing), `Full guide:`
   docstring back-link (existing), and **banner-substring** (new — captures all `def`s between
   a `# ── ` banner whose text contains the slug case-insensitively and the next `# ── `
   banner). This fires for convention-compliant donors too, making it a durable addition rather
   than a workaround for pre-convention donors. Cross-source banners (e.g.
   `# ── Atlas + IMF utilities ──`) raise an explicit user-resolution ambiguity note rather
   than a heuristic assignment; the brainstorm document suggested this, and the plan codified
   it as the safe default. De-dupe by function name when multiple anchors fire on the same def.

3. **Commented env-var declarations → match with `^#?\s*<SLUG>`, preserve `# ` prefix on apply.**
   The framework's `.env.example` template uses commented-out declarations (`# ATLAS_DB_HOST=`)
   as a contract, not a secrets dump. The original SKILL's `^<SLUG>` grep missed all five Atlas
   vars. The fix matches both forms; the `# ` prefix is preserved verbatim on apply so the
   target also ships the var in commented form. The proposal flags each matched line with
   `(commented in donor)`. No template format change — the SKILL adapts to the existing design.

4. **Smoke-test interpreter fallback chain + allowlisted error classifier.**
   Phase D step 8 now tries `<target>/.venv/bin/python` → `<target>/venv/bin/python` →
   `python3` (first-hit-wins) and reports which interpreter was used. `ModuleNotFoundError`
   on a small allowlist of framework deps (`dotenv`, `pandas`, `requests`, `psycopg2`,
   `pyyaml`, `numpy`, `pandasdmx`) is classified as **env-setup gap, not migration failure** —
   the migration files are in place; the venv isn't populated. Any other import error
   (wrapper name missing, syntax error in lifted code, `TODO_TARGET_*` hit at module scope)
   is a migration failure with verbatim error. The MIGRATION_TODO's env-setup step already
   covers population; the change is about correct labeling.

## Methods landed

No `methods/<slug>/rule.md` files were created or modified by this plan.

## Files added or modified

**.claude/skills/**
- ✎ `migrate-source/SKILL.md` — Phase A steps 1/3/4 (ref doc warn-proceed; banner anchor; commented env-var grep); Phase D steps 1/4/8 (stub bootstrap; commented-prefix preservation; interpreter fallback + error classifier); inline MIGRATION_PROPOSAL.md template (`## Warnings` section + `(commented in donor)` flag); inline MIGRATION_TODO.md template (leading step-0 for missing ref doc, conditional on stub bootstrap). 489 → 603 lines.

**plan/plan-migrate-source-skill-fixes/**
- ✚ `plan.md` (deleted with plan dir)
- ✚ `handoff.md` (deleted with plan dir)
- ✚ `log.md` (deleted with plan dir)

## Learnings

The four edits sat in non-overlapping sections of the SKILL exactly as `plan.md` predicted,
so batching all five sub-tasks in one editing pass was clean. No mid-edit design-call drift.

The ambiguity rule for cross-source banners (`# ── Atlas + IMF utilities ──`) is worth
flagging as a deferred refinement: the current rule errs toward explicit user resolution (the
whole block goes to the first-matching slug and the user is asked to sort it out). A
docstring-back-link heuristic could split the block automatically in a future pass, but the
explicit-ask path is the safe default until a real case motivates the heuristic.

The "deferred out of scope" list is also load-bearing context: adding a `--strict` flag to
restore refuse-on-missing behavior was explicitly rejected as a speculative knob that defers
rather than answers the design question; cleaning up cambodia-growth (adding `atlas_postgres.md`,
renaming helpers, uncommenting env vars) belongs to that project's plan, not this one.

## Metrics

- Phases: 4 completed (1: SKILL edits; 2: Atlas re-validation; 3: IMF re-regression; 4: commit)
- Sessions: 2 (2026-05-20 plan + Phase 1 edits; 2026-05-20 Phase 2–4 re-validation + commit)
- Final commit: `fee5051` (bundled with parent plan `plan-migrate-source-skill`)
