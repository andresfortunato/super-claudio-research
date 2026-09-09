# research-to-policy

A Claude Code harness for applied empirical, data-analytical, and policy research — adapts scc's planning/handoff/verification discipline to the realities of policy research and applied development economics.

**Current focus: `plan/plan-r2p-v3` — checking the citation chain.** v3's thesis is that v2 established a `deliverable → claim → evidence → artifact → script → source` chain and checked almost none of it. **Phases 1, 2, 2b, 3, 4 and 5 are done, and all four researcher decisions are answered.** `lint-research.sh` has gone from 7 checks to 14, `.next-id` acquired the first tool that reads it (`r2p evidence new`), `/cite-check` walks the half of link 1 no grep can see, and `/pipeline-check` re-runs an evidence doc's producing script and diffs the numbers against `## Measured`.

**Next: Phase 6 (harden the tooling) — the only thing left before Phase 7.** Unblocked and independent. Phase 7 — docs, constitution, release — follows, and its scope grew when decisions B and C went against their recommendations. **Read `plan/plan-r2p-v3/handoff.md` first**; it carries the six Phase 6 candidates ranked, the seven-row dangling-pointer inventory, and the warning that the pilot repo is `~/research/cordoba`.

**⚠ The constitution changed on 2026-09-09.** `docs/audience-and-philosophy.md` principle 7 now grades additions on a **side-effect axis** (read-only / derived files / source files) as well as token cost, because `/pipeline-check` is the first r2p tier that writes anything. A proposal wanting to write source files does not inherit that amendment.

**⚠ This status file was five weeks stale until 2026-09-09** — it claimed `plan/` was empty while plan-r2p-v3 was mid-execution. It is the first thing a session reads. Update it when a phase lands, not when the plan does.

**v2 shipped and merged to `main` (2026-08-04)** — conventions 13 → 7 mandatory + 2 optional, layout 15 → 8 scaffolded dirs, wiki gated behind `r2p init --with-wiki`. Promoted from the six-month Córdoba pilot audit; see `docs/v2-case-study-cordoba.md` and `docs/v1-to-v2-migration.md`.

**Queued behind v3 (see `TODO.md`):** the `docs/*-mechanism.md` set still describes v1 conventions (Phase 7 / decision B owns this), `.claude/skills/migrate-source/SKILL.md` still points at the v1 `sources.md` convention and layout, a duplicate-path-per-line detector for `03_linkcheck.py`, and an `--upgrade` integration test rather than only `init`. The Córdoba pilot-repo follow-ups in the case study's §7 "What remains" are a separate track and belong in the pilot repo, not here.

**Version note:** `package.json` is still `0.2.0`, but 2026-08-04 removed a hook (`check-evidence.sh`) and added one (`check-archival.sh`), and v3 has since materially changed `lint-research.sh`, added `r2p evidence new`, and shipped a new skill. Bump before any release.
