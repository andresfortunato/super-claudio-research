# /r2p-migrate-source Skill — Implementation Plan

## Goal

Build a new r2p skill at `.claude/skills/migrate-source/SKILL.md` that
transplants one source's full data layer (ref docs + companion files +
wrapper functions + env vars + INDEX rows + `data/README.md` entries +
CLAUDE.md mentions) from a donor r2p project to a target, adapting
project-specific bits (utility-module name, country constants,
headline anchors) via LLM at migration time. Gated behind a
proposal-then-apply user review. No donor-side prep required beyond
what the `data-access` convention already prescribes.

## Constraints

- **No donor-side discipline beyond the existing `data-access`
  convention.** No BEGIN/END markers, no per-source Migration
  sections, no manifest files. Discovery happens at migration time
  via the LLM using the INDEX table, wrapper docstring back-links,
  source-prefixed filenames, and source-prefixed env vars.
- **Never apply files without explicit user approval.** The skill
  writes `MIGRATION_PROPOSAL.md` first; nothing lands on disk until
  the user says "apply."
- **Never auto-derive headline anchors.** Strip Cambodia-specific
  anchor lines, replace with `TODO(migrate): verify against
  <target>`. Re-verification is the receiving project's
  responsibility. (Would otherwise mask upstream API drift and
  require the migration tool to hit credentialled APIs.)
- **Never silently overwrite.** On collision, write target files
  with git-style merge conflict markers (`<<<<<<<` / `=======` /
  `>>>>>>>`) and surface the conflicts in `MIGRATION_PROPOSAL.md`.
- **Refuse to migrate if target lacks the `data-access`
  convention.** Pre-flight check fails with a one-line "run `r2p
  init --upgrade` first" message. No auto-install.
- **Don't change the `data-access` or `data-sources` conventions to
  enable this skill.** Those conventions are fresh; the skill must
  work against them as-shipped, not require amendments.
- **Skill format follows existing r2p skills.** YAML frontmatter
  (`name`, `description`, `allowed-tools`); body is prescriptive
  for the executing session. Inline templates ok; split to
  `references/` only if a section exceeds ~40 lines.

## Decisions Made

From `brainstorms/migrate-source-skill.md` plus open-question
resolutions:

- **Migration unit** = full data layer for one source. Atomic.
- **Adaptation** = LLM at migration time. No donor-side prep.
- **Verification state** = strip-and-prompt (not auto-derive).
- **Conflict handling** = git-style merge markers in target files.
- **Form-factor** = skill (not CLI command). Conversational spine
  with Bash/sed for mechanical sub-tasks.
- **Apply gate** = proposal-then-apply.

Open questions resolved in this plan:

- **Single vs multi-source per invocation**: support both. Default
  one source per call (proposal-then-apply gate is per-source). When
  user supplies `--source imf,atlas,bis`, the skill iterates — one
  proposal per source, applied sequentially, each with its own
  user-approval gate. Multi-source is convenience, not parallelism.
- **Target-context gathering**: guess-and-confirm. The skill reads
  the target's existing `CLAUDE.md` / dirname / any country
  constants already in `<target>_utils.py` to propose target ISO,
  peer-country list, and utility-module name; surfaces them in
  `MIGRATION_PROPOSAL.md` under "Target context (confirm or
  correct)" for user review.
- **Target missing `<target>_utils.py`**: bootstrap it. The skill
  creates the file from the `data-access` convention's worked
  example (boot block with `load_dotenv()`, constants section
  placeholder), then appends the lifted wrapper. Notes this in the
  proposal so the user sees a new file is being created.
- **Target missing `data-access` convention**: refuse. Pre-flight
  check looks for `.claude/conventions/data-access.md` at target;
  exits with "Target lacks data-access convention; run `r2p init
  --upgrade` first."
- **Smoke-test step**: import check only (v1). After apply, the
  skill runs `python -c "from <target>_utils import <wrapper>"`
  via Bash and reports success/failure. A real fetch test (call
  the wrapper with target params, check response shape) requires
  `.env` populated and is a v1.x extension.
- **Relationship to `/r2p-adopt`**: keep separate. /r2p-adopt is
  legacy-→-r2p adoption (different inputs, different output:
  `ADOPTION_PROPOSAL.md`). This skill is r2p-→-r2p transplant.
  Cross-link in both directions in skill descriptions and the
  mechanism doc.

## File Manifest

**Create:**

| Path | Intent |
|---|---|
| `.claude/skills/migrate-source/SKILL.md` | The skill — frontmatter + body. Trigger conditions, preconditions, the four-phase flow (discovery → proposal → apply → smoke-test), inline templates for `MIGRATION_PROPOSAL.md` and `MIGRATION_TODO.md`. |
| `docs/migrate-source-mechanism.md` | Design rationale + tradeoffs. Why LLM-at-migration over donor-side discipline; why proposal-then-apply; why strip-and-prompt for anchors; what this does NOT do (no orchestration, no auto-verify); extension points (real-fetch smoke test, multi-project recipe library). |

**Modify:**

| Path | Intent |
|---|---|
| `README.md` | Add `migrate-source` to the skills tree under `.claude/skills/`; add `migrate-source-mechanism.md` to the docs tree; brief one-liner in the framework overview if appropriate. |
| `.claude/conventions/data-access.md` | "Adding a new source" recipe gains a one-line cross-reference: "To import a source from another r2p project, use `/r2p-migrate-source` instead of writing from scratch." |
| `.claude/conventions/data-sources.md` | Same one-line cross-reference in the "Adding a new source — recipe" section. |

**Skip:**

- `templates/CLAUDE.md.template` — no change. The existing Data
  Access pointer block is sufficient; the skill is discoverable via
  the conventions it references.
- `src/lib/install-project.js` — no change. Skills are mirrored
  globally to `~/.claude/skills/` by `install-globals.js`; the new
  skill folder picks up automatically on next `r2p init`.
- `src/lib/install-globals.js` — no change. Same reason.

## Repo context summary

- **Skill format**: existing r2p skills are single-file SKILL.md
  with YAML frontmatter (`name`, `description`, optional
  `allowed-tools`) and prescriptive body. Some have `references/`
  folders for long supporting docs (`planning/`). The convention is
  consistent — model on `verify/SKILL.md` and `scan-sources/SKILL.md`
  for tone and length.
- **Skill installation**: skills live in
  `.claude/skills/<name>/SKILL.md` in the framework repo and are
  symlinked into `~/.claude/skills/<name>/` globally by
  `r2p init` (Phase 3 of install). No per-project copies.
- **Data-access convention** (just shipped in this session) provides
  every anchor the skill needs to do discovery at runtime: INDEX
  Helper-functions table, wrapper docstring back-links
  (`Full guide: data_sources/<file>.md`), source-prefixed filenames
  (`imf_*.md`, `atlas_*.md`), source-prefixed env vars (`ATLAS_DB_*`,
  `IMF_*`).
- **Data-sources convention** holds the required sections in each
  ref doc (Status, Headline anchor, Endpoints, Query, Parsing,
  Pitfalls). The skill strips Status + headline anchor; preserves
  everything else.
- **Donor target for first validation**: `~/cambodia-growth`. Has
  6+ sources documented in `data_sources/INDEX.md`, wrappers in
  `cambodia_utils.py`, env vars in `.env` (with `.env.example` to
  be added on its next `r2p init --upgrade`). Atlas is the most
  complex (5 wrappers, Postgres auth via `ATLAS_DB_*`); IMF SDMX is
  the simplest (one wrapper, no auth, OpenAPI companion spec).
- **Target for first validation**: a throwaway test directory
  (`/tmp/migrate-source-test-target/`) with the data-access
  convention installed but no sources. Cleaner than risking
  pollution of `~/cordoba` during Phase 2 validation.

## Phases

### Phase 1: Implement the skill

- **Intent**: Write the SKILL.md that drives discovery, dependency
  analysis, target-context gathering, proposal generation, apply,
  and smoke-test. Inline the `MIGRATION_PROPOSAL.md` and
  `MIGRATION_TODO.md` templates.
- **Adds**: `.claude/skills/migrate-source/SKILL.md`.
- **Verification**: SKILL.md exists with valid YAML frontmatter
  (`name: migrate-source`, description starts with `(r2p)`,
  `allowed-tools` lists Read/Write/Edit/Bash/Glob/Grep at minimum);
  body covers all four flow phases; inline proposal/todo templates
  are concrete enough that a fresh session could execute them.
  Length target: ~250–400 lines (in line with existing r2p skills).
- **Tasks**:
  1. Draft frontmatter — name, (r2p)-prefixed description with
     trigger phrases ("/r2p-migrate-source", "migrate the IMF
     pipeline from cambodia-growth", "pull this source over from
     another project"), allowed-tools.
  2. Draft "When to invoke / When not to invoke" — borrowing the
     pattern from `verify/SKILL.md`.
  3. Draft "Preconditions" — donor has data-access convention,
     target has data-access convention, donor has source documented
     in `data_sources/INDEX.md`.
  4. Draft "Inputs" — `--from <donor-path>`, `--source <slug>` (or
     comma-list), `--to <target-path>` (defaults to cwd).
  5. Draft "Phase A: Discovery" — read donor's INDEX, locate
     source's ref doc + companions, locate wrapper(s) in
     `<donor>_utils.py`, locate env vars in `.env.example`, locate
     `data/README.md` section, locate CLAUDE.md mention.
  6. Draft "Phase B: Dependency analysis + target-context
     gathering" — identify out-of-block deps (constants referenced
     by the wrapper but defined elsewhere in the donor utility
     module); read target's CLAUDE.md / dirname / existing utility
     module to propose target context (ISO, peer list, utility
     module name).
  7. Draft "Phase C: Proposal generation" — write
     `MIGRATION_PROPOSAL.md` at target root with the full plan
     (files to create/append, conflicts, target-context
     assumptions, post-migration TODOs).
  8. Draft "Phase D: Apply + smoke-test" — on explicit user
     approval, write files (with merge markers on conflicts),
     append to existing files (utility module, `.env.example`,
     `data/README.md`, `INDEX.md`), bootstrap missing files if
     needed; run import smoke test; write `MIGRATION_TODO.md`.
  9. Draft inline `MIGRATION_PROPOSAL.md` template — the skill
     refers to this as the canonical proposal shape.
  10. Draft inline `MIGRATION_TODO.md` template — re-verification
      checklist (re-run headline anchor, fill `.env` values, smoke
      test, run a real fetch, restore Status line).

### Phase 2: Dry-run validation

- **Intent**: Validate the skill end-to-end against a real donor
  (`~/cambodia-growth`) and a controlled target (throwaway dir).
  Catch bugs in discovery/dep-analysis/adaptation before shipping.
  This is the "does the skill work?" gate — the skill is not done
  until at least IMF and Atlas migrate cleanly.
- **Adds/Modifies**: temporary test target at
  `/tmp/migrate-source-test-target/`; iterative edits to
  `.claude/skills/migrate-source/SKILL.md` based on test outcomes.
- **Verification** (domain-shaped, per source):
  - IMF migration: proposal lists `imf_sdmx_api.md`,
    `imf_sdmx_openapi_3_0.yaml`, the `imf_sdmx_fetch` wrapper, no
    env vars (IMF SDMX is public), an INDEX row, no
    `data/README.md` entry. After apply, target imports
    `imf_sdmx_fetch` successfully. `MIGRATION_TODO.md` lists
    re-verification of the headline anchor.
  - Atlas migration: proposal lists `atlas_postgres.md` (or
    whatever cambodia-growth's filename is), the `atlas_query`
    wrapper plus 4 higher-level helpers (`get_country_year_data`,
    etc.) as one bundle, the `ATLAS_DB_*` env vars (5 of them),
    an INDEX row, dependency analysis flagging the
    `COUNTRY_IDS`/`ID_TO_ISO`/`WB_COUNTRIES` constants as
    project-specific deps that need target-adapted versions.
    After apply, target imports `atlas_query` successfully.
  - Conflict test: pre-seed target with a partial
    `data_sources/imf_sdmx_api.md`; run migration; verify the
    target file ends up with git-style merge markers around the
    divergent sections.
- **Tasks**:
  1. Create `/tmp/migrate-source-test-target/` with the
     data-access convention installed (run `r2p init` against the
     throwaway dir).
  2. Run `/r2p-migrate-source --from ~/cambodia-growth --source
     imf` — review proposal, apply, run smoke test.
  3. Run again with `--source atlas` — review proposal carefully
     for the constants-dependency analysis. Apply. Smoke test.
  4. Pre-seed a conflict; re-run a migration; confirm merge markers.
  5. Edit SKILL.md to fix any gaps the test runs surfaced. Loop
     until clean.
  6. Tear down `/tmp/migrate-source-test-target/`.

### Phase 3: Docs + framework wiring

- **Intent**: Capture the design rationale before context fades,
  expose the skill in the README and from the convention recipes.
- **Adds**: `docs/migrate-source-mechanism.md`.
- **Modifies**: `README.md`, `.claude/conventions/data-access.md`,
  `.claude/conventions/data-sources.md`.
- **Verification**: mechanism doc covers the standard sections
  (problem, pieces, why not donor-discipline, why
  proposal-then-apply, what this does NOT do, tradeoffs accepted,
  extension points); README skill list + docs tree updated;
  convention recipes have the one-line cross-reference. Length
  target for mechanism: 100–150 lines per `docs/extending.md`.
- **Tasks**:
  1. Write `docs/migrate-source-mechanism.md`.
  2. Add skill row to README's `.claude/skills/` tree.
  3. Add mechanism doc to README's `docs/` tree.
  4. Add cross-references in both conventions' "Adding a new
     source" recipes.

## Out of scope (named for clarity, not built)

- A `data-access-lint` skill checking `.env.example` ↔ utility
  module parity (mentioned as an extension point in
  `docs/data-access-mechanism.md`).
- Real-fetch smoke test (call wrapper with target params, verify
  response shape). Requires populated `.env`; v1.x.
- Multi-project recipe library (donor manifests, source catalog).
  If this becomes a recurring need, ship in v1.x; for now, the
  conventions are the catalog.
- Auto-derivation of headline anchors at migration time (would
  mask drift; requires credentialled API access).

## Integration seams

- **Donor side**: reads `data_sources/INDEX.md` (Helper-functions
  table), `data_sources/<slug>*` files, `<donor>_utils.py` (locate
  wrappers + shared constants), `.env.example` (env-var
  declarations), `data/README.md` (source's section), `CLAUDE.md`
  (Data Sources / Data Access mentions).
- **Target side**: writes/appends to all of the above. Bootstraps
  `<target>_utils.py` if absent. Writes `MIGRATION_PROPOSAL.md`
  pre-apply and `MIGRATION_TODO.md` post-apply, both at target root.
- **Framework side**: no install-script changes (skills
  auto-mirror). README and convention cross-references are the
  only framework-visible changes.
