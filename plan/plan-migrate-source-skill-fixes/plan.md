# /r2p-migrate-source — Phase-2 follow-up fixes

## Goal

Address the 4 actionable discovery / smoke-test gaps surfaced when the
SKILL was dry-run against `~/cambodia-growth` on 2026-05-19, so that
Atlas migration (currently blocked) and IMF migration (currently
passing) both succeed against the same donor. All edits land in
`.claude/skills/migrate-source/SKILL.md`. Parent plan
`plan/plan-migrate-source-skill/` stays as context for the why.

## Constraints

- **Donor side is read-only.** Do not require cambodia-growth to add
  an Atlas ref doc, rename helpers, or uncomment env vars. Cambodia is
  the first non-trivial donor; future donors will also be partly
  pre-convention, and the donor cost of migration is not paid by the
  receiving project.
- **Framework templates are the contract.** The shipped
  `.env.example` template uses commented-out examples. The SKILL
  adapts to that — the template format does not change to make this
  skill simpler.
- **Strict-mode behaviors stay strict where the breakage is silent.**
  Conflict-marker writes, no `.env` writes, no auto-install of
  conventions, no silent overwrites — all unchanged. The lenience
  added here is scoped to **discovery anchors** and **smoke-test env
  detection**, not to the apply-gate or write semantics.
- **No new SKILL flags.** The fixes are behavior changes, not opt-in
  knobs. A `--strict` mode would just defer the design question.
- **Lift, don't refactor.** When a helper has a non-slug-prefixed
  name (`get_country_year_data`), the SKILL transplants it verbatim
  and proposes a rename in MIGRATION_TODO; it does not rewrite the
  donor name on the way in.

## Decisions Made

From `brainstorms/migrate-source-skill-gaps.md` open questions, plus
the lenient-vs-strict call from the handoff:

### 1. Missing ref doc → warn-and-proceed, bootstrap a stub

When `Glob data_sources/<slug>*.md` returns nothing at the donor, the
SKILL no longer refuses. Instead:

- Discovery records "no ref doc found" and continues with the other
  anchors (wrappers, env vars, INDEX row).
- The proposal carries a top-level warning block:
  `⚠ Donor has no data_sources/<slug>*.md ref doc. Will bootstrap a
  stub at the target — fill in before considering the source
  documented.`
- On apply, the SKILL writes a minimal stub at
  `<target>/data_sources/<slug>.md` containing only:
  - `# <Slug>` heading
  - `Status: pending — migration stub, fill before use`
  - One paragraph: "This file was created by /r2p-migrate-source
    because the donor (`<donor-path>`) did not ship a ref doc for
    `<slug>`. Populate the standard sections (Headline anchor,
    Endpoint shape, Worked example, Gotchas) per
    `.claude/conventions/data-sources.md`."
- MIGRATION_TODO gains a leading step: "Write
  `data_sources/<slug>.md` from scratch — the migration created a
  stub."

**Why a stub instead of "no file at all":** wrapper docstrings carry
`Full guide: data_sources/<slug>.md` back-links that are documented as
load-bearing for the INDEX bridge. Even for pre-convention donors
where today's docstrings lack the back-link, the target should land
in convention-compliant shape so future wrapper edits at the target
can add the back-link without dangling. A 5-line stub costs nothing
and is honest about what is missing.

### 2. Banner-based discovery → third anchor with substring-on-slug

Add a third discovery rule to Phase A step 3, in addition to the
existing two (slug-prefix on `def` name; `Full guide: data_sources/<slug>`
in docstring):

> **Banner anchor.** Capture every `def` that sits between a `# ── `
> banner whose text contains the slug (case-insensitive substring) and
> the next `# ── ` banner (or end of file). The banner counts as the
> wrapper's section banner — lift it with the bundle.

Disambiguation rules:

- Substring match, case-insensitive: `# ── Common Atlas queries ──`
  matches slug `atlas`. `# ── Atlas DB connection ──` also matches.
  `# ── Common helpers ──` does not.
- Cross-source banners (e.g. `# ── Atlas + IMF utilities ──`) are
  unusual but possible. If two slugs in the same comma-list invocation
  both match the same banner, the proposal raises an explicit
  ambiguity note: `⚠ Banner '<text>' matched by multiple slugs
  (atlas, imf). Defs in this block included with the first slug; tell
  me which slug owns them.` User resolves before approving.
- A `def` already captured by one of the other two anchors is not
  duplicated. De-dupe by function name.

This rule fires for clean donors too — a fully-compliant project
still uses `# ── Atlas ──` banners — so it is not a "compat shim" but
a third stable anchor.

### 3. Commented env vars → match commented, preserve `# ` prefix

Phase A step 4's grep pattern changes from `^<SLUG>` to
`^#?\s*<SLUG>` (case-insensitive on slug, as today). Matches both
`ATLAS_DB_HOST=` and `# ATLAS_DB_HOST=`.

On Phase D step 4 (apply env vars to target's `.env.example`), the
leading `# ` (if present in the donor) is preserved verbatim. The
target ships them commented too, mirroring the framework template's
"declare what we use, leave blank" form. The proposal's "Donor env
vars found" list visually flags which lines were commented in the
donor: `# ATLAS_DB_HOST= (commented in donor)`.

### 4. Smoke-test python search → .venv → venv → python3, classify errors

Phase D step 8 changes the `python` invocation to a fallback chain:

1. `<target>/.venv/bin/python` if it exists and is executable
2. else `<target>/venv/bin/python` if it exists and is executable
3. else `python3` on PATH

The smoke-test report includes one line naming which interpreter was
used: `Smoke test via: <target>/.venv/bin/python` (or `system python3
(no project venv found)`).

Error classification on import failure:

- If the error is `ModuleNotFoundError: No module named '<dep>'` where
  `<dep>` is in a small allowlist of framework deps
  (`dotenv`, `pandas`, `requests`, `psycopg2`, `pyyaml`, `numpy`,
  `pandasdmx`) — report as **env-setup gap, not migration failure**.
  The migration files are in place; the target's venv isn't
  populated.
- Any other import error (the wrapper name itself missing, syntax
  error in the lifted code, TODO_TARGET_* placeholder hit at module
  scope) — report as **migration failure**, with the verbatim error.

The MIGRATION_TODO already covers env-setup; the change is purely
about how the SKILL labels the result to the user.

## Decisions explicitly deferred (out of scope here)

- **Cambodia-growth donor cleanup.** Adding `atlas_postgres.md`,
  renaming `get_country_year_data` to `atlas_get_country_year_data`,
  and uncommenting the Atlas env-var block are good hygiene for that
  project but belong in that project's plan, not this one.
- **Framework `.env.example` template format.** The commented-example
  form is the design. SKILL adapts.
- **Finding (b) — pre-convention ref docs without `Status:` /
  headline anchor.** Handoff confirmed the no-op `strip-and-prompt`
  path is correct behavior; no SKILL change. MIGRATION_TODO already
  prompts the receiving project to add the missing sections at
  re-verification.
- **`--strict` flag** for callers who want the old refuse-on-missing
  behavior. Not adding speculative knobs.

## File manifest

| Path | Action | Intent |
|---|---|---|
| `.claude/skills/migrate-source/SKILL.md` | edit | Phase A step 1 (ref doc: refuse → warn); Phase A step 3 (add banner anchor); Phase A step 4 (grep pattern + preserve `# `); Phase D step 1 (stub on missing ref doc); Phase D step 4 (preserve commented form); Phase D step 8 (interpreter search + error classifier); MIGRATION_PROPOSAL template (warning block + commented-flag in env list); MIGRATION_TODO template (leading "write ref doc" step when stub was bootstrapped); "What this skill does NOT do" updated where applicable. |
| `plan/plan-migrate-source-skill-fixes/handoff.md` | append per session | Session log + Atlas + IMF re-run results. |
| `plan/plan-migrate-source-skill-fixes/log.md` | append | Methodology notes if any design call shifts under contact. |

No new files outside this directory. No other framework code touched.
No conventions, README, or `docs/migrate-source-mechanism.md` change
(the design rationale doc is already accurate at the brainstorm/plan
level; the SKILL change is mechanism, not design).

## Repo context summary

- `.claude/skills/migrate-source/SKILL.md` is a 489-line skill with
  four phases (A: discovery, B: dependency analysis, C: proposal, D:
  apply + smoke test) and two inline templates
  (MIGRATION_PROPOSAL.md, MIGRATION_TODO.md). The edits cluster in
  Phase A steps 1/3/4, Phase D steps 1/4/8, and both templates.
- The previous plan `plan/plan-migrate-source-skill/` produced this
  SKILL; `handoff.md` there has the validation transcript and the
  per-finding recommended edits. Read it before editing.
- `brainstorms/migrate-source-skill-gaps.md` carries the
  repo-vs-skill axis discussion and the three open design questions
  resolved above.
- The test target was `/tmp/migrate-source-test-target/` last
  session; recreate per the handoff's "Re-running Atlas" section.
  cambodia-growth has had `r2p init --upgrade` applied (the framework
  sidecars landed unreviewed; the user owns that diff separately and
  it does not block this work).

## Phases

### Phase 1 — SKILL edits

- **Intent**: Land all four behavior changes plus template updates in
  a single editing pass. The four findings are independent at the
  edit-site level (different sections of the SKILL) but conceptually
  paired with the proposal/TODO template updates, so batching them
  avoids partial-state intermediate diffs.
- **Modifies**: `.claude/skills/migrate-source/SKILL.md` only.
- **Verification**:
  - Frontmatter still valid (`name`, `description`, `allowed-tools`
    intact).
  - All four findings have a concrete edit landed (no "TODO: add
    banner rule" left behind).
  - Discipline-rules section still lists the load-bearing
    invariants — never write before approval, never silently
    overwrite, never edit `.env`, never auto-install conventions.
    Lenient discovery does not weaken these.
  - Both inline templates still parseable as markdown (no broken
    fence blocks from edits).
- **Tasks**:
  - 1.1: Phase A step 1 + Phase D step 1 changes for missing ref doc
    (warn-and-proceed + stub bootstrap). Add proposal-warning block
    spec.
  - 1.2: Phase A step 3 banner-anchor rule with disambiguation note;
    de-dupe by function name.
  - 1.3: Phase A step 4 grep pattern + Phase D step 4 commented-form
    preservation; update proposal "Donor env vars found" rendering.
  - 1.4: Phase D step 8 interpreter fallback chain + error
    classifier + reporting line.
  - 1.5: MIGRATION_TODO template — add leading "write ref doc" step
    that fires only when stub was bootstrapped.

### Phase 2 — Atlas re-validation

- **Intent**: Confirm the four edits unblock Atlas migration end-to-end
  against the same donor that surfaced the gaps. This is the load-bearing
  test — Atlas was the case the parent plan could not finish.
- **Modifies**: nothing on disk in this repo; uses
  `/tmp/migrate-source-test-target/` (fresh) as scratch.
- **Verification** (pass-criteria restated from
  `plan-migrate-source-skill/handoff.md`):
  - Proposal includes warning about missing `data_sources/atlas*.md`
    ref doc.
  - Wrapper bundle lists all 6: `get_atlas_conn`, `atlas_query`,
    `get_country_year_data`, `get_product_data`, `get_pci_data`,
    `get_export_by_section`. Banner anchor must catch the 5
    non-prefixed names.
  - All 5 `ATLAS_DB_*` env vars listed in the proposal, each flagged
    "(commented in donor)". On apply, they land in
    `.env.example` with `# ` prefix preserved.
  - Dependency analysis flags `COUNTRY_IDS` and `ID_TO_ISO` as
    project-specific (→ `TODO_TARGET_*` placeholders). `psycopg2`
    flagged as module-level import to add to target's preamble.
  - On apply: stub `data_sources/atlas_postgres.md` (or
    `atlas.md` — slug-derived) lands with the spec'd headings only.
  - Smoke test: `python -c "from migrate_source_test_target_utils
    import atlas_query"` succeeds via `<target>/.venv/bin/python`.
    Report names the interpreter.
  - MIGRATION_TODO lists in order: write
    `data_sources/<slug>.md`, fill `ATLAS_DB_*` in `.env`, replace
    `TODO_TARGET_COUNTRY_IDS` / `TODO_TARGET_ID_TO_ISO`, real-fetch.
- **Tasks**:
  - 2.1: Recreate test target per handoff section "Re-running Atlas".
  - 2.2: Invoke `/r2p-migrate-source --from ~/cambodia-growth
    --source atlas --to /tmp/migrate-source-test-target`. Review
    proposal against the criteria above. If any pass-criterion
    fails, return to Phase 1.
  - 2.3: Reply "apply". Verify all post-apply criteria.

### Phase 3 — IMF re-regression

- **Intent**: Confirm the Phase-1 edits did not break the only path
  the parent plan validated. IMF was the working case and stays the
  canary for "did we accidentally make discovery too lenient or
  change apply semantics".
- **Modifies**: nothing on disk; reuses scratch target (or fresh).
- **Verification**: same proposal contents and smoke-test result as
  the parent plan's IMF session (see `plan-migrate-source-skill/
  handoff.md` step 3 — 4 ref docs + 1 OpenAPI yaml + 1 wrapper + 5
  INDEX rows; smoke test passes). Specifically: ref-doc discovery
  still finds the existing IMF ref docs (no false "missing ref doc"
  warning fires), no extra defs lifted by the banner rule, no env
  vars (`(none)`), `Status:` line stripping still works.
- **Tasks**:
  - 3.1: `/r2p-migrate-source --from ~/cambodia-growth --source imf
    --to /tmp/migrate-source-test-target` against a fresh target.
    Confirm parity with parent-plan IMF results.

### Phase 4 — Commit

- **Intent**: Ship Phase-1 edits + the parent plan's still-uncommitted
  Phase-1/3 changes (from working tree). Parent plan handoff notes
  "Commits: still none" — Atlas validation was the gate. Now it
  passes.
- **Modifies**: git index only.
- **Verification**: Single commit covering SKILL edits + parent plan's
  staged docs/wiring + this plan's `plan/` directory.
  `git status` clean after. CLAUDE.md (none here, framework repo) /
  README / docs untouched by this commit unless they were already
  staged in working tree from the parent plan.
- **Tasks**:
  - 4.1: `git status` + `git diff` review. Confirm only intended
    paths.
  - 4.2: Commit with message that references both plan dirs
    (parent + fixes).

## Open items deferred

- The cambodia-growth `.framework-new` sidecars from
  `r2p init --upgrade` last session — unreviewed, user owns. Not
  blocking; mentioned in parent-plan handoff. This plan does not
  touch them.

## Cross-references

- `plan/plan-migrate-source-skill/` — parent plan; phases 1 + 3 done,
  phase 2 partial (IMF passed, Atlas blocked → unblocked by this
  plan).
- `brainstorms/migrate-source-skill-gaps.md` — the five-finding
  table, repo-vs-skill axis, open design questions.
- `.claude/skills/migrate-source/SKILL.md` — the only file edited by
  Phase 1.
- `.claude/conventions/data-sources.md` — the schema the bootstrapped
  stub points at.
- `docs/migrate-source-mechanism.md` — design rationale; unchanged.
