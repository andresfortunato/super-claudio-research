---
name: migrate-source
description: (r2p) Transplant one external data source's full data layer (reference doc + companion files + wrapper function(s) + env vars + INDEX row + data/README.md entry + CLAUDE.md mention) from a donor r2p project to a target. Use when the user says "/r2p-migrate-source", "migrate the IMF pipeline from cambodia-growth", "pull this source over from another project", or otherwise asks to import an r2p source's data layer rather than re-derive it. Writes MIGRATION_PROPOSAL.md first; nothing lands on disk until the user approves.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# migrate-source

Transplant one external data source's *full data layer* from a donor
r2p project to a target r2p project. The unit is atomic: one source =
ref doc + companion files (OpenAPI spec, codelists) + wrapper
function(s) + env-var declarations + INDEX row + `data/README.md`
entry + CLAUDE.md mention if the donor had one.

The skill is **proposal-then-apply**. It writes
`MIGRATION_PROPOSAL.md` at the target root, the user reviews and
says "apply," and only then do files land. Adaptation
(country-specific constants, utility-module rename, headline-anchor
strip) happens at migration time via the LLM — no donor-side prep is
required beyond the `sources` convention.

This is the r2p-→-r2p transplant counterpart to `/r2p-adopt`
(legacy-→-r2p). They share the proposal-then-apply pattern but
operate on different inputs.

## When to invoke

The user types one of:

- `/r2p-migrate-source --from <donor-path> --source <slug>`
- `/r2p-migrate-source --from ~/cambodia-growth --source imf,atlas`
- "Migrate the IMF SDMX pipeline from cambodia-growth into this project."
- "Pull the Atlas Postgres setup over from `~/cambodia-growth`."
- "Bring in the BIS wrapper from the other project."

## When NOT to invoke

- The user wants to *adopt* a non-r2p legacy project — that's
  `/r2p-adopt`. This skill assumes both donor and target follow the
  `sources` convention.
- The user wants to refresh an *already-migrated* source against a
  newer donor version. Not in v1; for now, re-run the skill and
  accept the conflict markers.
- The source doesn't exist in the donor's `research/sources/INDEX.md`.
  Document it in the donor first, then migrate.
- The target is the donor. No-op.

## Preconditions

Run these as a single pre-flight block. Stop with a one-line message
on any failure.

1. **Donor exists and is a directory.** `--from <donor-path>` resolves.
2. **Donor has the sources convention.**
   `<donor>/.claude/conventions/sources.md` exists. (v2 merged the v1
   `data-access` and `data-sources` conventions into this one file; a
   donor still carrying the v1 pair needs `r2p init --upgrade` first.)
3. **Donor has an INDEX with a Helper-functions table.**
   `<donor>/research/sources/INDEX.md` exists and contains a section
   matching `^#+ +Helper functions` (case-insensitive).
4. **Donor has the named source.** For each slug in `--source`, at
   least one of: a row in the Helper-functions table whose Source
   column mentions the slug, OR a file matching
   `<donor>/research/sources/<slug>*`.
5. **Target has the sources convention.**
   `<target>/.claude/conventions/sources.md` exists. If absent:
   stop with `"Target lacks the sources convention; run 'r2p init
   --upgrade' first."` Do **not** auto-install.
6. **Target is a git repo.** `git -C <target> rev-parse --git-dir`
   succeeds. The user will review proposals via diff; we don't want
   to write into an untracked directory.

`<target>` defaults to the current working directory if `--to` is
omitted.

## Inputs

```
/r2p-migrate-source --from <donor-path> [--source <slug>[,<slug>...]] [--to <target-path>]
```

- `--from <donor-path>` — required. Absolute or `~`-prefixed path.
- `--source <slug>` — required. One slug, or a comma-list. Slug is
  the source family prefix used in filenames and env vars
  (`imf`, `atlas`, `bis`, `world_bank`). On a comma-list, the skill
  iterates one source at a time, each with its own proposal-then-apply
  gate. Multi-source is convenience, not parallelism.
- `--to <target-path>` — optional. Defaults to cwd.

If `--source` is omitted, list the donor's available sources (read
the Helper-functions table) and ask the user to pick.

## The four-phase flow

For each source slug (sequentially):

### Phase A — Discovery

Walk the donor and locate every artifact tied to this source. Use
filename prefixes, INDEX rows, wrapper docstring back-links, and
env-var prefixes as anchors.

1. **Reference doc(s)** — `Glob` `<donor>/research/sources/<slug>*.md`.
   Excludes `INDEX.md`, `README.md`, `EXAMPLE_*`. There may be more
   than one (`imf_sdmx_api.md`, `imf_weo_api.md`,
   `imf_dataflow_inventory.md`). Capture each. If the glob returns
   nothing, record "no ref doc found at donor" in the manifest and
   continue — the proposal will warn and Phase D will bootstrap a
   stub. The wrapper docstring back-link (`Full guide:
   research/sources/<slug>.md`) is load-bearing for the INDEX bridge, so
   even a pre-convention donor's bundle lands in convention-compliant
   shape at the target.
2. **Companion files** — `Glob` `<donor>/research/sources/<slug>*` for
   non-`.md` extensions: `.yaml` / `.yml` (OpenAPI specs), `.csv` /
   `.xlsx` (codelists like `pwt110_data.csv`), etc.
3. **Wrapper function(s)** — find the donor utility module:
   `Glob` `<donor>/*_utils.py` (exclude `setup_utils.py`, etc. —
   should be exactly one match; if more, ask). Read it. Locate every
   `def` that matches **any** of these three anchors:
   - **Name anchor.** `def` name begins with the slug
     (`atlas_query`, `atlas_get_country_year_data`).
   - **Docstring anchor.** Docstring contains `Full guide:
     research/sources/<slug>`.
   - **Banner anchor.** `def` sits between a `# ── ` section banner
     whose text contains the slug (case-insensitive substring) and
     the next `# ── ` banner (or end of file). This catches
     pre-convention donors whose helpers don't carry the slug in
     their name (`get_country_year_data` under
     `# ── Common Atlas queries ──`).

   De-dupe by function name when multiple anchors fire on the same
   `def`. Capture each wrapper's full text (the `def` through its
   return statement) plus its preceding `# ── …` section banner.

   **Banner disambiguation.** If a single banner matches multiple
   slugs in a comma-list invocation (e.g. `# ── Atlas + IMF
   utilities ──` matched by both `atlas` and `imf`), include the
   defs with the **first** slug in the comma-list and raise an
   explicit ambiguity note in the proposal: `⚠ Banner '<text>'
   matched by multiple slugs (<list>). Defs in this block included
   with <first-slug>; tell me which slug owns them.` The user
   resolves before approving.
4. **Env vars** — `grep -E "^#?\s*<SLUG_PREFIX>"`
   `<donor>/.env.example` (case-insensitive on the slug; e.g.
   `^#?\s*ATLAS_DB_`). The optional `# ` prefix matches the framework
   `.env.example` template's commented-example form (commented
   declarations are still real declarations — the template is the
   contract). Capture every match verbatim, including the leading
   `# ` if present, so the target ships them in the same commented
   shape.
5. **INDEX row** — `grep` the Helper-functions table in
   `<donor>/research/sources/INDEX.md` for rows mentioning the slug.
   Capture the row text verbatim (will be re-emitted at target).
6. **`data/README.md` entry** — if `<donor>/data/README.md` exists,
   grep for the slug or any captured wrapper name. Capture the
   matching section (heading + body until next heading).
7. **CLAUDE.md mention** — `grep` `<donor>/CLAUDE.md` for the slug.
   If a paragraph mentions it, capture it.

Record everything in an internal manifest (in memory; written to the
proposal in Phase C). The **wrapper** is the only hard requirement —
if no `def` matches any of the three anchors, surface and stop. A
missing ref doc warns and proceeds (Phase D bootstraps a stub);
missing env vars is normal (public APIs); missing INDEX row, missing
`data/README.md` entry, and missing CLAUDE.md mention all warn and
proceed.

### Phase B — Dependency analysis + target-context gathering

**Dependency analysis.** Read each captured wrapper. Identify
out-of-block references:

- Module-level constants referenced by the wrapper but defined
  elsewhere in the donor utility module (e.g. `atlas_query`
  references `ATLAS_DB_CONFIG` — that's in-block; but
  `get_country_year_data` references `COUNTRY_IDS` and `ID_TO_ISO`
  — those are project-specific country constants defined at the top
  of `cambodia_utils.py`).
- Imports the wrapper uses that aren't already in the target's
  utility module preamble.
- Helper functions the wrapper calls (e.g. `get_atlas_conn` is
  called by `atlas_query`; capture both).

For each out-of-block dependency, classify:

- **Generic** (move as-is): standard imports, source-prefixed
  constants like `ATLAS_DB_CONFIG`.
- **Project-specific** (needs target version): country-id maps
  (`COUNTRY_IDS`, `ID_TO_ISO`, `WB_COUNTRIES`), peer-country lists,
  output paths. Flag these for the proposal — they cannot be lifted
  verbatim.

**Target-context gathering** (guess-and-confirm). Read what's
already at the target to propose reasonable defaults:

- **Target slug for utility module**: from `<target>/CLAUDE.md`
  (look for `<X>_utils.py` mentions), from existing
  `<target>/*_utils.py` filename, or from the target directory's
  basename (`cordoba` → `cordoba_utils.py`).
- **Target country ISO and peer list**: from
  `<target>/CLAUDE.md` (country mentions), from existing
  `<target>/<X>_utils.py` constants if present, or unknown.
- **Existing target utility module**: if
  `<target>/<X>_utils.py` exists, capture its constants section and
  existing wrapper list so the proposal knows what to append vs
  bootstrap.

Surface every guess in the proposal under "Target context (confirm
or correct)" — the user sees them in writing before approving.

### Phase C — Proposal generation

Write `<target>/MIGRATION_PROPOSAL.md` using the template below.
Cover every artifact, every conflict, every TODO. Stop and wait for
the user to say "apply" (or equivalent: "go ahead", "yes", "looks
good — apply"). On any other response, treat it as a request to
revise the proposal.

### Phase D — Apply + smoke-test

On explicit user approval:

1. **Bootstrap missing files if needed.**
   - If `<target>/<X>_utils.py` is absent, create it from the
     `sources` convention's runtime half: boot block
     (`from pathlib import Path`, `import os`, `from dotenv import
     load_dotenv`, `load_dotenv(Path(__file__).parent / '.env')`),
     a placeholder constants section (`# ── Country constants ──`
     with a `TODO(migrate)` line), then the lifted wrapper(s).
     Surface the bootstrap in the proposal so the user sees a new
     file is being created.
   - If `<target>/.env.example` is absent, create it with the
     captured env-var lines.
   - If `<target>/research/sources/INDEX.md` lacks a Helper-functions
     section, append one with the lifted row(s).
   - If `<target>/data/README.md` is absent and the donor had an
     entry, create it from the template seed and append the
     captured section.

2. **Write reference docs and companion files.** For each captured
   `research/sources/<slug>*` file:
   - If the target path doesn't exist: write the donor's content,
     adapted — set the frontmatter to `status: stale` (v2 carries
     freshness in the `status:` key, not a `Status:` prose line;
     a donor-verified date is not a target-verified date), clear
     `wrapper:` and `env:` only if the wrapper did not come across,
     replace headline-anchor values with
     `TODO(migrate): verify against <target-context>`, and keep every
     other section verbatim.
     A pre-convention donor doc may have no frontmatter at all; add
     the five keys (`source`, `status`, `triggers`, `wrapper`, `env`)
     rather than lifting a bare body. `triggers:` is load-bearing —
     `retrieve-learnings.sh` globs it, so a doc without one is
     invisible to retrieval at the target.
   - If the target path *does* exist: write a git-style merge file
     (`<<<<<<<` HEAD section / `=======` / `>>>>>>>` migrated
     section). Surface in the proposal's Conflicts list.

   **If discovery found no donor ref doc** (Phase A step 1 returned
   nothing), bootstrap a stub at `<target>/research/sources/<slug>.md`:

   ```markdown
   ---
   source: <slug>
   status: stale                    # never `verified` — nothing was verified
   triggers: "<slug> TODO-add-4-to-8-concrete-keywords"
   wrapper: <wrapper name, or none>
   env: [<captured env vars, or none>]
   ---

   # <Slug> — TODO(migrate): what it gives you

   This file was created by /r2p-migrate-source because the donor
   (`<donor-path>`) did not ship a ref doc for `<slug>`. Populate the
   five required sections per `.claude/conventions/sources.md`:
   `## What it gives you`, `## Access`, `## Headline anchor`,
   `## Gotchas`, `## Coverage limits`.
   ```

   The section names are the v2 five, not v1's Status / Headline
   anchor / Endpoints / Query shape / Parsing / Pitfalls. A stub that
   names the wrong sections is worse than no stub: it looks
   authoritative and fails the convention it cites.

   Leave the leading `MIGRATION_TODO.md` step "write
   `research/sources/<slug>.md` from scratch" to remind the receiving
   project.

3. **Append wrapper(s) to the target utility module.** Add
   wrappers (and their `# ── section banner ──`) at the end of the
   file. Rewrite project-specific dependency references to
   `TODO(migrate)`-prefixed placeholders if the target's equivalents
   are unknown (e.g. `country_ids = TODO_TARGET_COUNTRY_IDS`).
   Wrapper docstrings keep their `Full guide: research/sources/<slug>...`
   back-link.

4. **Append env vars** to `<target>/.env.example` (do not edit
   `.env`). Preserve grouping by source family. Add a header
   comment if introducing a new family. **Preserve the leading
   `# ` prefix verbatim** on any line that was commented in the
   donor — the framework template ships declarations commented as a
   "declare what we use, leave blank" form, and the target should
   mirror that.

5. **Append `data/README.md` entry** if the donor had one. Adapt
   any project-specific path references.

6. **Add INDEX row(s)** to the Helper-functions table in
   `<target>/research/sources/INDEX.md`. Use the same row format the
   table already uses.

7. **Add CLAUDE.md mention** if the donor had one *and* the
   target's CLAUDE.md has a Data Sources or Data Access section.
   Otherwise skip (don't introduce new sections — the user can
   promote later if the source is core).

8. **Smoke test, in two stages — and only the first one is a
   pass-criterion.** This split exists because the previous single-stage
   version never literally passed. Its criterion was `from <target>_utils
   import <wrapper>` *succeeding*, which needs the target's dependencies
   installed; across two validation sessions it always died on
   `psycopg2` or `dotenv` in a throwaway target with no virtualenv. The
   skill classified that correctly as an env gap, a session read
   "classified correctly" as "passed", and the archive commit had to be
   reverted. **Where a check can partially pass, say which half counts.**

   **Stage 1 — structural. Runs always, needs nothing installed, and
   this is the half that must pass.** Parse the target utility module
   without executing it:
   ```bash
   cd <target> && python3 - <<'EOF'
   import ast, sys
   src = open("<target>_utils.py").read()
   tree = ast.parse(src)                       # syntax
   top = {n.name for n in tree.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
   want = {"<wrapper_1>", "<wrapper_2>"}
   missing = want - top
   scope = [n for n in tree.body if not isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))]
   placeholders = sorted({x.id for n in scope for x in ast.walk(n)
                          if isinstance(x, ast.Name) and x.id.startswith("TODO_TARGET_")})
   print("missing wrappers:", sorted(missing) or "none")
   print("TODO_TARGET_ at module scope:", placeholders or "none")
   sys.exit(1 if (missing or placeholders) else 0)
   EOF
   ```
   It answers exactly the three questions a migration can break: does
   the lifted code parse, did every wrapper arrive as a module-level
   `def`, and is a `TODO_TARGET_*` placeholder sitting where import
   will hit it. All three are properties of the transplant, so all
   three are checkable with no venv, no `.env` and no network. A
   failure here is a **migration failure** — report the verbatim error
   and re-review the proposal.

   **Stage 2 — real import. Best-effort, informational, never a
   pass-criterion.** Pick the target's interpreter, first hit wins:
   1. `<target>/.venv/bin/python` if it exists and is executable
   2. `<target>/venv/bin/python` if it exists and is executable
   3. `python3` on `PATH`

   Run it with every captured env var set to a dummy value **in the
   subprocess environment only** — a module whose boot block does
   `os.environ['ATLAS_DB_HOST']` raises `KeyError` at import time, and
   that is an unset variable, not a bad migration. This never touches
   `.env`; the no-`.env`-writes rule is absolute.
   ```bash
   cd <target> && env <SLUG>_FOO=dummy <SLUG>_BAR=dummy \
     <interpreter> -c "from <target>_utils import <wrapper_1>, <wrapper_2>"
   ```

   Report one line naming the interpreter: `Stage 2 via:
   <target>/.venv/bin/python`, or `system python3 (no project venv
   found)`.

   **Classify a stage-2 failure, and never call it a migration
   failure on its own**:
   - `ModuleNotFoundError` for a dep in the allowlist (`dotenv`,
     `pandas`, `requests`, `psycopg2`, `pyyaml`, `numpy`,
     `pandasdmx`) — **env-setup gap**. The files are in place and the
     target's venv is not populated. Point at the project's own
     dependency-install path. Every real r2p project has a
     virtualenv; a target that does not resembles no actual user, and
     the skill must not create one — a venv in someone's project is a
     side effect nobody asked for.
   - Any other error — **worth re-reading**, but stage 1 has already
     told you whether the transplant is sound. Report it verbatim and
     say which stage it came from.

   Do **not** call any wrapper with arguments in either stage — that
   needs a populated `.env` and live credentials.

9. **Write `<target>/MIGRATION_TODO.md`** from the template below.
   This is the receiving project's checklist for getting the doc's
   frontmatter from `status: stale` to `status: verified <date>`
   (re-run the headline anchor, fill `.env`, smoke test, real fetch).

10. **Final report.** One block to the user:
    - Files created / appended / merge-conflicted
    - Smoke test result
    - Pointer to `MIGRATION_TODO.md`

## Discipline rules

- **Never write before the user approves.** The proposal lands on
  disk; everything else waits. "Apply" is the only go-signal.
- **Never auto-derive headline anchors.** Strip-and-prompt only.
  Re-verification is the receiving project's responsibility (and
  requires credentialled API access the migration tool should not
  assume).
- **Never silently overwrite.** Existing files always get git-style
  merge markers; never blind-replace.
- **Never edit `.env`.** Only `.env.example`. Real secrets are the
  user's job.
- **Never auto-install the sources convention.** Refuse with the
  one-line message if missing; the user runs `r2p init --upgrade`.
- **One source per proposal-apply cycle.** Multi-source invocations
  iterate sequentially. Don't batch proposals; each source needs its
  own user-review gate.
- **Preserve donor wrapper docstrings.** The `Full guide:
  research/sources/<file>.md` back-link is load-bearing for the
  INDEX bridge — never strip it.

## Cost

A typical single-source migration runs 30–50k tokens: discovery
reads (donor INDEX + ref docs + utility module + `.env.example`),
proposal authoring, file writes. Migrations are rare (a handful per
project lifecycle), so the cost is acceptable. Atlas (5 wrappers,
shared constants) is the upper bound; IMF SDMX (one wrapper, no
auth) is the lower bound.

---

## Template: MIGRATION_PROPOSAL.md

Write this to `<target>/MIGRATION_PROPOSAL.md`. Fill every section;
leave `(none)` rather than omitting a heading. Exception: `## Warnings`
is omitted entirely when there are no warnings (an empty Warnings
heading is misleading).

```markdown
# Migration proposal: `<slug>` from `<donor-path>` → `<target-path>`

**Generated**: <ISO8601 UTC>
**Skill**: /r2p-migrate-source
**Status**: AWAITING USER APPROVAL — reply "apply" to land files.

## Warnings

Emit each that applies; omit the section if none:

- `⚠ Donor has no research/sources/<slug>*.md ref doc. Will bootstrap a
  stub at <target>/research/sources/<slug>.md — fill in before
  considering the source documented.`
- `⚠ Banner '<text>' matched by multiple slugs (<list>). Defs in
  this block included with <first-slug>; tell me which slug owns
  them before approving.`

## Source

- **Slug**: `<slug>`
- **Donor reference docs found**:
  - `research/sources/<slug>_<thing>.md` (<line count> lines)
  - `research/sources/<slug>_<other>.md` (...)
- **Donor companion files found**:
  - `research/sources/<slug>_openapi_X.yaml` (...) — OR `(none)`
- **Donor wrappers found** (in `<donor>/<X>_utils.py`):
  - `<wrapper_1>(...)`
  - `<wrapper_2>(...)`
- **Donor env vars found** (in `<donor>/.env.example`):
  - `<SLUG>_FOO` / `<SLUG>_BAR` — flag with ` (commented in donor)`
    on lines whose donor form had a leading `# `, e.g.
    `# ATLAS_DB_HOST= (commented in donor)`. The target will mirror
    that commented form. — OR `(none)`
- **Donor INDEX row**: `<verbatim row>`
- **Donor `data/README.md` section**: `<heading>` — OR `(none)`
- **Donor CLAUDE.md mention**: `<one-line quote>` — OR `(none)`

## Target context (confirm or correct)

- **Target utility module**: `<X>_utils.py`
  - Exists: yes / no (will bootstrap)
  - Existing wrappers: <list> — OR `(empty)`
- **Target ISO / country**: <guess from CLAUDE.md / dirname> — OR `unknown`
- **Target peer-country list**: <guess> — OR `unknown` (will leave as TODO)

If any of these are wrong, tell me before approving — the migration
will use them.

## Dependency analysis

Out-of-block references the wrappers make:

| Reference | Classification | Action |
|---|---|---|
| `ATLAS_DB_CONFIG` | generic (source-prefixed) | move as-is |
| `COUNTRY_IDS` | project-specific (country map) | placeholder `TODO_TARGET_COUNTRY_IDS` — fill before first use |
| `ID_TO_ISO` | project-specific | placeholder |
| `get_atlas_conn` | helper called by wrapper | move with the wrapper bundle |

## Files to write / append

| Path | Action | Notes |
|---|---|---|
| `<target>/research/sources/<slug>_thing.md` | create | Status line stripped; headline anchor → TODO |
| `<target>/research/sources/<slug>_other.md` | create | (...) |
| `<target>/research/sources/<slug>.md` | bootstrap stub | only when donor had no ref doc — 5-line stub, fill before use |
| `<target>/research/sources/<slug>_openapi.yaml` | create | copy as-is |
| `<target>/<X>_utils.py` | bootstrap + append | new file — see below |
| `<target>/.env.example` | append | adds `<SLUG>_*` block |
| `<target>/research/sources/INDEX.md` | edit | new Helper-functions row(s) |
| `<target>/data/README.md` | append | new section for `<slug>` |
| `<target>/CLAUDE.md` | edit | add one-line mention — OR `(skip)` |

## Conflicts (will be written with merge markers)

| Target path | Reason |
|---|---|
| `<target>/research/sources/<slug>_thing.md` | already exists at target |

OR: `(none)`

## TODOs that will land in `MIGRATION_TODO.md`

- Re-run headline anchor query for `<slug>`; set `status: verified <date>` in `<ref-doc>`'s frontmatter.
- Fill `<SLUG>_FOO`, `<SLUG>_BAR` in `.env` with target-environment values.
- Replace `TODO_TARGET_COUNTRY_IDS` in `<X>_utils.py` with the target's country-id map.
- Smoke-test: `python -c "from <X>_utils import <wrapper>"` should succeed (will be run automatically on apply).
- Real-fetch test: call `<wrapper>(...)` with target params and verify response shape.

## How to proceed

- **Reply "apply"** to write the files and run the import smoke test.
- **Reply with corrections** (e.g. "target country is COR, peer list is [...]") and the proposal will be regenerated.
- **Reply "cancel"** to stop without writing.
```

---

## Template: MIGRATION_TODO.md

Write this to `<target>/MIGRATION_TODO.md` *after* apply succeeds.

```markdown
# Migration TODO: `<slug>` (post-apply)

Migration of `<slug>` from `<donor-path>` landed at <ISO8601 UTC>.
The receiving project owns these re-verification steps.

## 0. Write `research/sources/<slug>.md` from scratch

**Include only if Phase D bootstrapped a stub (donor had no ref
doc).** Omit this section otherwise.

The migration created a frontmatter-only stub at
`research/sources/<slug>.md`. Populate the five required sections per
`.claude/conventions/sources.md`:

- `## What it gives you` (dimensions, coverage, frequency, units —
  enough to know whether it answers a question before fetching)
- `## Access` (endpoint / package / query shape, the wrapper name and
  signature, auth and env vars, rate limits, a minimal call)
- `## Headline anchor` (a concrete re-fetchable value with its date)
- `## Gotchas` (numbered, symptom first, then fix)
- `## Coverage limits` (what the source does not have)

Then set `status: verified <today>` in the frontmatter and give
`triggers:` four to eight concrete keywords — without them the doc is
invisible to `retrieve-learnings.sh`. The wrapper's docstring
`Full guide: research/sources/<slug>.md` back-link will resolve once
the file is real.

## 1. Fill `.env` secrets

`.env.example` was updated with the new env-var block. Mirror them
into `.env` with real values:

```bash
# <SLUG>_FOO=<real value>
# <SLUG>_BAR=<real value>
```

If the source is a public API with no credentials, this section is
`(none)` — skip.

## 2. Re-run the headline anchor

Open `research/sources/<slug>_thing.md`. The `TODO(migrate): verify
against <target-context>` line replaces the donor's headline anchor.

1. Pick a target-context-appropriate concrete value (a country-year
   triple the documented procedure should produce).
2. Run the documented query (the wrapper, the worked-example URL,
   whatever the doc describes).
3. Paste the returned value into the `## Headline anchor` section.
4. Set `status: verified <today>` in the frontmatter.

This is the smoke test that proves the doc still describes reality.

## 3. Replace TODO placeholders in `<X>_utils.py`

If the dependency analysis flagged project-specific constants:

- `TODO_TARGET_COUNTRY_IDS` — populate with the target's
  country-id-to-iso map (e.g. for Atlas: `{31: 'KHM', 32: 'VNM', ...}`).
- Any other `TODO_TARGET_*` placeholders the migration introduced.

Until these are filled, wrappers that reference them will raise
`NameError` at call time.

## 4. Real-fetch smoke test

Run the wrapper(s) once with target parameters. Confirm the response
shape matches what `research/sources/<slug>_thing.md` describes:

```python
from <X>_utils import <wrapper>
df = <wrapper>(...)  # target-appropriate args
print(df.shape, df.columns.tolist(), df.head())
```

If this fails, the API has drifted since the donor's last
verification — update the wrapper and the ref doc together.

## 5. Promote to CLAUDE.md (if core)

If `<slug>` is core to this project (a Claude session would waste
time without knowing it exists), add a one-line mention in
`CLAUDE.md`'s Data Sources section. Otherwise leave it discoverable
via `research/sources/INDEX.md`.

## 6. Resolve any merge conflicts

If the proposal flagged conflicts, the affected files now contain
`<<<<<<<` / `=======` / `>>>>>>>` markers. Resolve them by hand and
commit.

## 7. Delete this file when done

Once all steps above are checked, `git rm MIGRATION_TODO.md` and
commit. The migration is complete.
```

---

## Cross-references

- `.claude/conventions/sources.md` — utility-module + env-var
  shape the skill writes against.
- `.claude/conventions/sources.md` — reference-doc sections the
  skill preserves on transplant.
- `docs/migrate-source-mechanism.md` — design rationale (why
  LLM-at-migration over donor-side discipline; why
  proposal-then-apply; tradeoffs).
- `docs/r2p-adopt.md` — sibling document for legacy-→-r2p adoption.
  Different inputs, different outputs (`ADOPTION_PROPOSAL.md`), same
  proposal-then-apply pattern.

## What this skill does NOT do

- **No orchestration.** One source per proposal cycle. Comma-list
  invocations iterate; they do not bundle.
- **No auto-anchor verification.** The donor's headline-anchor value
  is stripped; moving the doc's frontmatter from `status: stale` to
  `status: verified <date>` is the receiving project's job
  (`MIGRATION_TODO.md` step 2).
- **No `.env` writes.** Only `.env.example`. Real secrets stay
  local.
- **No silent overwrites.** Existing target files get merge markers.
- **No auto-install of conventions.** Refuses if target lacks
  `sources`; the user runs `r2p init --upgrade`.
- **No cross-project recipe library.** The conventions are the
  catalog; this skill walks a single donor at a time.
- **No real-fetch smoke test.** v1 runs only an import check. Real
  fetch lives in `MIGRATION_TODO.md` for the receiving project.
