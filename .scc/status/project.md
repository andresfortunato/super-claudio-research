# research-to-policy

A Claude Code harness for applied empirical, data-analytical, and policy research — adapts scc's planning/handoff/verification discipline to the realities of policy research and applied development economics.

**Current focus:** v2 shipped and merged to `main` (2026-08-04) — conventions 13 → 7 mandatory + 2 optional, layout 15 → 8 scaffolded dirs, wiki gated behind `r2p init --with-wiki`. Promoted from the six-month Córdoba pilot audit; see `docs/v2-case-study-cordoba.md` and `docs/v1-to-v2-migration.md`.

**Next session picks up on the Córdoba docs.** Scope not yet fixed — the two candidates are the framework's own write-ups (`docs/v2-case-study-cordoba.md`, `docs/lessons-ai-assisted-research.md`) and the pilot-repo follow-ups listed in that case study's §7 "What remains" (57 tier-1 evidence docs needing the `## Measured` / `## Reading` rewrite, 28 topic files wanting a synthesised lead, three claims with no evidence doc, 45 source docs with filename-derived triggers, and the flags/retractions still sitting in `plan-narrativa-final-memo/context/`). Start by settling which.

**Also queued (v2.1, see `TODO.md`):** prune the `docs/*-mechanism.md` set (still describes the v1 conventions — deliberate as historical record, stale for a release), repath `.claude/skills/migrate-source/SKILL.md` to the v2 `sources.md` convention and `research/sources/` layout, add a duplicate-path-per-line detector to `03_linkcheck.py`, and integration-test `--upgrade` rather than only `init`.

**No active plans.** `plan/` is empty. The two migrate-source plans were archived as superseded on 2026-08-04 — the skill they built still ships but refuses on any v2 project. See `archive/plan-migrate-source-skill.md`.

**Version note:** `package.json` is still `0.2.0`, but 2026-08-04 removed a hook (`check-evidence.sh`), added one (`check-archival.sh`), and materially changed the `--upgrade` path. Bump before any release.
