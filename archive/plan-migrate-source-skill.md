# /r2p-migrate-source Skill

Completed: 2026-05-20

## What was built

A new r2p skill at `.claude/skills/migrate-source/SKILL.md` that transplants one external
data source's full data layer — ref docs, companion files, wrapper functions, env-var
declarations, INDEX row, `data/README.md` entry, and CLAUDE.md mention — from a donor r2p
project to a target, adapting project-specific identifiers via LLM at migration time.
Gated behind a proposal-then-apply flow: the skill writes `MIGRATION_PROPOSAL.md` first;
nothing lands on disk until the user approves. The final SKILL.md is 603 lines (489 at
Phase 1, grown by fix-plan Phase-1 edits). Validated end-to-end against `~/cambodia-growth`
as donor for both Atlas (PostgreSQL, 6 helpers, no ref doc → stub bootstrapped per fix-plan
behavior) and IMF SDMX (3 ref docs + OpenAPI YAML + 1 wrapper, no env vars). Shipped
bundled with sibling plan `plan-migrate-source-skill-fixes` at commit `fee5051`.

## Key decisions

1. **LLM-at-migration-time discovery, not donor-side discipline.** No BEGIN/END markers,
   no per-source manifest files in the donor. The skill discovers the data layer at runtime
   using the INDEX helper-functions table, wrapper docstring back-links, source-prefixed
   filenames, and source-prefixed env-var names. Alternative was requiring donors to maintain
   migration manifests; rejected because it would silently rot and require retrofitting every
   existing donor project.

2. **Proposal-then-apply gate (MIGRATION_PROPOSAL.md → explicit user approval).** Nothing
   is written to the target until the user reviews the full plan, including conflicts, target
   context assumptions, and dependency analysis. Alternative was a `--dry-run` flag; rejected
   in favor of always producing the proposal because the gate is the safety invariant, not an
   option.

3. **Strip-and-prompt for headline anchors; never auto-derive.** Wrapper headline anchors
   from the donor are stripped and replaced with `TODO(migrate): verify against <target>`.
   Re-verification is the receiving project's responsibility. Auto-derivation would mask
   upstream API drift and require the migration tool to call credentialled APIs at migration
   time.

4. **Git-style merge markers on collision.** When a target file already contains content for
   the migrated source, the target file is rewritten with `<<<<<<<` / `=======` / `>>>>>>>`
   markers and the conflict is surfaced in MIGRATION_PROPOSAL.md. Conflict resolution is
   left to the researcher; the skill never silently overwrites.

5. **Refuse migration if target lacks the data-access convention.** Pre-flight check looks
   for `.claude/conventions/data-access.md` at the target; exits with "run `r2p init
   --upgrade` first." No auto-install. This protects the convention as the integration
   seam and avoids partial installs in the critical path.

6. **Bootstrap missing `<target>_utils.py` rather than refuse.** If the target has no
   utility module yet, the skill creates one from the data-access convention's worked
   example (load_dotenv block + constants placeholder) and appends the lifted wrappers.
   The bootstrap is surfaced in the proposal so the user sees the new file before apply.

7. **Lenient discovery with fallbacks (added by fix-plan after Phase-2 validation).**
   Phase 2 against cambodia-growth surfaced three places the original SKILL was too strict:
   donors without a ref doc for a source should warn-and-proceed (stub created) rather than
   refuse; helper functions that don't match `<slug>_*` naming should still be discoverable
   via section banners in the utility module; commented-out env-var declarations in
   `.env.example` must be read (not just uncommented ones). All three are addressed in the
   fix plan — see `plan-migrate-source-skill-fixes` archive entry for the specific edits.

## Methods landed

No `methods/<slug>/rule.md` files were created or modified by this plan.

## Files added or modified

**.claude/skills/**
- ✚ `migrate-source/SKILL.md` — the skill (603 lines); frontmatter + four-phase flow (Discovery → Proposal → Apply → Smoke-test) + inline MIGRATION_PROPOSAL.md and MIGRATION_TODO.md templates

**docs/**
- ✚ `migrate-source-mechanism.md` — design rationale: why LLM-at-migration over donor-side discipline; proposal-then-apply tradeoffs; what this does NOT do (no orchestration, no auto-verify); extension points

**.claude/conventions/**
- ✎ `data-access.md` — added one-line cross-reference in "Adding a new source" recipe pointing to `/r2p-migrate-source`
- ✎ `data-sources.md` — same one-line cross-reference in the "Adding a new source — recipe" section

**README.md**
- ✎ Added `/r2p-migrate-source` row to the skills table; added `migrate-source/` to the `.claude/skills/` internals tree; added `migrate-source-mechanism.md` to the `docs/` internals tree

**templates/**
- ✚ `.env.example` — committed env-var contract template (installed to target projects by `r2p init`; precondition for the skill's env-var discovery phase)
- ✚ `data/README.md` — on-disk inventory template for the `data/` directory (gitignored except this file; seeded by `r2p init`)

## Learnings

**Donor projects predate the conventions.** `~/cambodia-growth` was the first non-trivial
donor and was partly pre-convention at validation time: no `data-access.md`, no
`.env.example`, and an Atlas source with no ref doc. Running `r2p init --upgrade` on the
donor fixed the convention gap but also dropped `.framework-new` sidecars into cambodia-growth
that the researcher needs to diff and accept. The lesson: donors should be upgraded before
being used as migration sources; add a pre-flight upgrade reminder to the skill.

**Smoke-test needs project venv, not "python".** The original SKILL assumed `python` resolves
to the project's environment. In practice r2p projects use a project-local venv. The fix-plan
addressed this; the planning assumption was wrong from the start.

**`.env.example` in r2p uses commented-out declarations.** The upgrade installs a template
with `# ATLAS_DB_HOST=...`-style lines — a contract, not a dump of secrets. The original
SKILL only searched for uncommented declarations and missed all five Atlas env vars. This is
a data-format assumption that needed to be validated empirically, not assumed from convention
prose.

**Helper naming is not always source-prefixed.** cambodia-growth's Atlas helpers include
`get_country_year_data`, `get_product_data`, etc. — names that don't surface "atlas" in the
function name. The original SKILL's `<slug>_*` glob found only `atlas_query` (1 of 6).
Section-banner discovery (finding the `# === Atlas` header in the utility module and taking
everything until the next banner) is the correct fallback.

## Metrics

- Phases: 3 of 3 completed
- Sessions: 4 (2026-05-18 planning, 2026-05-18 impl phases 1+3, 2026-05-19 phase-2 partial,
  2026-05-20 re-validation after fix-plan)
- Final commit: `fee5051` (bundled with `plan-migrate-source-skill-fixes`)
