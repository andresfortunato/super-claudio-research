# /r2p-migrate-source Skill

Archived: 2026-08-04 — **superseded, not completed.**

## Status at archival

Phases 1 and 3 shipped. Phase 2 (dry-run validation) never closed, and v2 then
removed the conventions the plan was written against. Archived rather than
resumed because its resumption recipe would validate the skill against a layout
that no longer ships.

| Phase | Outcome |
|---|---|
| 1. Implement the skill | ✅ shipped — `.claude/skills/migrate-source/SKILL.md`, 603 lines |
| 2. Dry-run validation | ⚠️ never closed — behavior validated, smoke test never passed |
| 3. Docs + framework wiring | ✅ shipped — `docs/migrate-source-mechanism.md`, README, cross-refs |

**The skill itself still exists and is not deleted by this archival.** What is
archived is the plan to build and validate it. Re-scoping the skill to v2 is
tracked in `TODO.md` under "v2.1".

## What was built

`/r2p-migrate-source`, a skill that transplants one external data source's full
data layer — reference doc, companion files, wrapper functions, env vars, INDEX
row, `data/README.md` entry, CLAUDE.md mention — from a donor r2p project to a
target, adapting project-specific bits (utility-module name, country constants,
headline anchors) at migration time. Gated behind a proposal-then-apply review:
the skill writes `MIGRATION_PROPOSAL.md` and nothing lands on disk until the user
approves.

## Key decisions

1. **No donor-side prep beyond the existing conventions.** No BEGIN/END markers,
   no per-source Migration sections, no manifest files. Discovery happens at
   migration time from the INDEX table, wrapper docstring back-links,
   source-prefixed filenames, and source-prefixed env vars. Alternative — require
   donors to annotate — was rejected because the donor does not benefit from the
   migration and will not maintain annotations for a project they are not on.

2. **Never auto-derive headline anchors.** Donor anchors are stripped and replaced
   with `TODO(migrate): verify against <target>`. Re-verification belongs to the
   receiving project. Carrying them over would mask upstream API drift and force
   the migration tool to hit credentialled APIs.

3. **Never silently overwrite.** On collision the skill writes git-style merge
   markers and surfaces the conflict in the proposal. Verified end-to-end.

4. **Lenient discovery, strict apply.** Phase 2 found the skill was strict in three
   places where the donor was merely pre-convention, so a follow-up plan added
   three fallback anchors (banner-substring discovery, commented env vars,
   warn-and-bootstrap on a missing ref doc). The lenience was deliberately scoped
   to *discovery* and smoke-test env detection — the five apply-gate invariants
   (no write before approval, no auto-derived anchors, no silent overwrite, no
   `.env` writes, no auto-install of conventions) were left untouched.

5. **Lift, don't refactor.** A helper with a non-slug-prefixed name
   (`get_country_year_data`) transplants verbatim with a rename proposed in
   MIGRATION_TODO. Renaming on the way in would cascade through donor notebooks.

## Why it was not completed

Phase 2's pass-criterion was that a post-apply smoke test
(`python -c "from <target>_utils import <wrapper>"`) **succeeds**. Across two
sessions it never did. Both Atlas and IMF migrations executed correctly — every
discovery, proposal and apply behavior matched the criteria — but the smoke test
hit `ModuleNotFoundError` (`psycopg2`, then `dotenv`) because the throwaway test
target had no virtualenv and the interpreter fallback chain landed on a bare
system `python3`.

The fix was understood and written down (bootstrap a venv at the test target;
pre-set dummy `ATLAS_DB_*` vars to dodge an eager `KeyError` at module load). It
was never executed, because v2 landed first.

**v2 removed both of the skill's preconditions.** `.claude/conventions/data-access.md`
was merged into `sources.md`, and `data_sources/` moved to `research/sources/`.
`SKILL.md` hard-refuses when either is absent and globs the old paths throughout,
so it now refuses on any v2 project. Closing Phase 2 as written would have
validated the skill against a dead layout.

## Files added or modified

**.claude/skills/**
- ✚ `migrate-source/SKILL.md` — 489 lines at Phase 1, 603 after the fix plan

**docs/**
- ✚ `migrate-source-mechanism.md`

**Root**
- ✎ `README.md`, convention cross-references

## Learnings

**"Classified correctly" is not "succeeded", and a plan should say which one it
means.** The smoke test failed; the skill's classifier correctly labelled the
failure as an env-setup gap rather than a migration failure. A session read that
as passing and shipped an archive commit (`aa32169`), which was reverted
(`2e3b9d8`) when the user caught it. The pass-criterion said `succeeds`. Where a
verification step can partially pass, write down which half counts.

**The first non-trivial donor will be pre-convention, and that is the normal
case.** The skill was designed assuming donors fully follow the data-access and
data-sources conventions. `cambodia-growth` was the first real donor and only
partly did — no Atlas ref doc, helpers named without a source prefix, env vars
present only in commented form. Three of the five Phase-2 findings were the skill
being strict where the world is messy. Future donors will be cleaner, but the
lenient path is what makes the skill usable on the ones that exist now.

**Project venvs are the norm; "default python" was a planning gap.** The plan
assumed a bare `python` would import the transplanted wrapper. Every real r2p
project has a virtualenv, and the throwaway test target did not — so the test
exercised an environment that resembles no actual user.

**A plan paused against a convention is a plan with an expiry date.** These two
plans sat for roughly ten weeks while v2 rewrote the conventions underneath them.
Nothing in the handoffs could express "this is now invalid" — they described a
resumption recipe in confident detail, and a future session would have followed
it. A paused plan should record what it depends on, so a convention change can
invalidate it loudly.

## Metrics

- Phases: 2 of 3 shipped; Phase 2 never closed
- Sessions: 3 (implementation, 2026-05-19 dry run, 2026-05-20 re-validation)
- Commits: `fee5051` (Phases 1+3, bundled with the fix plan), `00d4d53` (template
  cleanup). Premature archive `aa32169`, reverted at `2e3b9d8`.
- Sources exercised: 2 (Atlas, IMF), both against `~/cambodia-growth`
- Follow-up: `TODO.md` → v2.1, "Re-scope plan-migrate-source-skill"
