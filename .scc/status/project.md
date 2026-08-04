# research-to-policy

A Claude Code harness for applied empirical, data-analytical, and policy research — adapts scc's planning/handoff/verification discipline to the realities of policy research and applied development economics.

**Current focus:** v2 shipped and merged to `main` (2026-08-04) — conventions 13 → 7 mandatory + 2 optional, layout 15 → 8 scaffolded dirs, wiki gated behind `r2p init --with-wiki`. Promoted from the six-month Córdoba pilot audit; see `docs/v2-case-study-cordoba.md` and `docs/v1-to-v2-migration.md`.

**Next:** prune the `docs/*-mechanism.md` set (still describes the v1 conventions — deliberate as historical record, stale for a release), and re-scope `plan/plan-migrate-source-skill*`.

**Paused plans:** `plan-migrate-source-skill` and `plan-migrate-source-skill-fixes`. Phases 1/3/4 shipped (`fee5051`, `00d4d53`); Phase 2 never closed. Both are written against the v1 `data-access` convention and `data_sources/` layout that v2 replaced — they need re-scoping to v2, not resumption. See each `handoff.md`.
