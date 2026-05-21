# r2p-adopt — bring an existing project under research-to-policy

One-shot audit-and-propose instructions for migrating a pre-framework research
project (random scripts at the root, charts mixed with data, methodology
buried in READMEs and script docstrings, prior `CLAUDE.md` or `.cursorrules`
content) onto the framework structure.

**This is a plain instruction document, not a skill.** It used to be a
user-invocable skill, but it's only useful once per project — installing it
globally polluted Claude's context across every session of every project. To
use it now, paste a short prompt at Claude pointing to this file. Then once
the adoption is done, you're done — nothing to uninstall.

## How to use this doc

In a Claude Code session at the root of the project you're adopting, run a
prompt like:

```
Read the r2p adoption instructions at <PATH> and run the adoption audit on
this project. Walk through preflight, the four audits, and write the
proposal to ADOPTION_PROPOSAL.md. Don't move, delete, or edit any file —
proposal only.
```

To find `<PATH>`:

- **If r2p is installed via npm globally**:
  `$(npm root -g)/research-to-policy/docs/r2p-adopt.md`
- **If you have a local clone of the framework**:
  `<your-clone-path>/docs/r2p-adopt.md`

When Claude finishes, you'll have `ADOPTION_PROPOSAL.md` at the project root.
Review section by section, execute the moves by hand, and commit after each.
Nothing happens automatically — that's by design.

## When to use this

- **Right after `r2p init`** on an existing, disorganized project where you
  have analytical content predating the framework.
- **Once per project.** Adoption is a transition, not a recurring task. After
  you've executed the proposal, use `/research-cleanup` for ongoing
  maintenance — that's the periodic equivalent.

## When NOT to use this

- **Greenfield projects.** `r2p init` lays everything down clean; nothing to
  audit.
- **Projects already r2p-native.** Use `/research-cleanup` for ongoing
  maintenance.
- **Mid-plan or mid-analysis.** The proposal is long and the moves shouldn't
  compete with active work. Wait for a quiet moment.
- **As a recurring task.** This is a one-shot. Re-running adds no value over
  `/research-cleanup`.

## Preconditions

- `r2p init` has been run. Look for `.claude/conventions/` and the
  scaffolding directories (`evidence/`, `decisions/`, `archive/`, etc.). If
  missing, write a one-line proposal that says "Run `r2p init` first" and
  stop.
- Run from project root.
- Note in the preflight section if the working tree is dirty — the researcher
  should commit or stash before executing the proposed moves so the migration
  is bisectable.

## Workflow

1. **Verify the framework is installed.** Check for `.claude/conventions/`
   and the standard scaffolding dirs. If absent → write a one-section
   proposal recommending `r2p init` and stop.
2. **Walk the tree.** Glob the project for scripts, data, charts, markdown,
   and existing AI config. Skip the directories listed under "Directories to
   skip" below.
3. **Run the four audits.** Each populates one section of the proposal.
4. **Write `ADOPTION_PROPOSAL.md`** at project root. Overwrite if it exists —
   a previous proposal is presumed acted on or discarded.
5. **Report to the user** in one paragraph: counts per audit, where the
   proposal lives, the reminder that nothing has been moved.

## Audits

### 1. File classification

For each non-framework file, propose a target slot under the framework.
Apply heuristics in priority order (filename pattern, then path signal,
then content peek for ambiguous cases). See the pattern → slot table below.

Findings split into four buckets:

- **Likely raw data** — moves to `wiki/raw/<source>/`. Filename has `raw_*`,
  `_orig`, or sits in a directory called `wiki/raw/` already.
- **Likely processed/intermediate** — moves to `data/processed/`. `_v2.csv`,
  `_clean`, `panel_*`, sits in `data/` but not `data/raw/`.
- **Likely chart/output** — moves to `output/`. `.png`/`.pdf`/`.svg` outside
  `output/`. Suggest a numeric prefix (`output/NN_<slug>`) for sortability if
  the project has more than ~5 charts.
- **Unclear provenance — researcher decides.** Top-level `.csv` or
  `.parquet` with no obvious raw-or-processed marker, files whose name doesn't
  match any pattern. List these explicitly under a "researcher decides"
  subheader rather than guessing wrong.

For markdown files outside framework dirs (`README.md`, `NOTES.md`, etc.):
peek at content. If it reads as **methodology** → flag for audit 3
(archaeology). If it reads as **findings** (specific numbers, charts
referenced, "we find") → propose extracting into `evidence/NN_<slug>.md`.
If neither → leave in place and note its presence.

For scripts in `scripts/`, `src/`, `code/`, or `analysis/`: don't propose
renaming the directory — the framework doesn't mandate one. Just note its
existence and recommend the script-header convention
(`.claude/conventions/script-header.md`) gets adopted on next edit.

For notebooks (`.ipynb`): note their location only. Don't propose moves; do
recommend a separate `/research-cleanup` pass to flag scratch cells.

Each finding records: source path, proposed target path (or "<unclear —
researcher decides>"), one-sentence rationale, what was searched.

### 2. CLAUDE.md / .claude/ reconciliation

If the project predates r2p, it likely has prior AI config — `CLAUDE.md`,
`.claude/`, `.cursorrules`, `.windsurfrules`, `AGENTS.md`,
`.github/copilot-instructions.md`. The framework's `r2p init` is conservative
(never overwrites), so prior content sits alongside the new conventions.
This audit surfaces overlap and conflicts.

- **Existing `CLAUDE.md`.** Read it. For each section/rule, classify:
  - **Conflicts** with a framework convention — surface so the researcher
    decides which to keep.
  - **Duplicates** a framework rule now living in `.claude/conventions/` —
    propose deleting from `CLAUDE.md` so the convention file is the single
    source of truth.
  - **Project-specific** (research scope, dataset names, glossary, audience
    notes) — keep. This is exactly what `CLAUDE.md` is for.
  - **Operational project rule** (e.g. "always run pytest before commit") —
    propose moving to `project_conventions/<domain>.md`.
- **Pre-existing `.claude/` content.** List each file the framework didn't
  install. For each, ask the researcher: keep, delete, or merge with the
  matching framework artifact.
- **Other tools' AI config.** `.cursorrules`, `.windsurfrules`, `AGENTS.md`:
  propose extracting any project-bearing rules into `project_conventions/`
  so they're tool-agnostic, then leaving the original files in place
  (they're cheap and other tooling may still read them).

### 3. Methodology archaeology

The point: methodology calls deserve `decisions/` records. In a pre-framework
project they're scattered across READMEs, NOTES.md files, script docstrings,
and inline comments. This audit surfaces candidates.

For each candidate:

- Find the source location with grep. Trigger phrases live in the
  "Methodology archaeology — trigger phrases" section below ("we chose",
  "rejected because", "deflator", "specification", "exclusion", etc.).
- Record the file path and approximate line number.
- Quote the candidate sentence/paragraph.
- Propose a `decisions/YYYY-MM-DD_<slug>.md` filename. Date is best-guess
  from `git log -1 --format=%ad <file>`; today's date if no git history.
- Note: **researcher writes the full 5-section decision record** using the
  candidate paragraph as raw material. This doc surfaces; the researcher
  deliberates.

Don't auto-generate decision records. Methodology calls deserve the
researcher's deliberation — the value of `decisions/` comes from the
researcher having actually thought through "what would invalidate this".

### 4. Orphan analysis

This overlaps with `/research-cleanup`. Adoption is a natural moment to
confront accumulated cruft, so we run it once here. After adoption, defer
to `/research-cleanup`. Cross-link in the proposal so the researcher knows.

- **Charts without evidence.** For every image under `output/`, `figures/`,
  `charts/`, or any directory with >5 image files: grep its basename across
  all `.md` files in the project. Zero hits → orphan candidate. Propose
  either writing a retroactive `evidence/NN_<slug>.md` (if the chart is
  load-bearing — filename suggests it answers a question) or noting it for
  later cleanup.
- **Scripts without inbound references.** For every script outside framework
  dirs: grep its filename across the rest of the repo. Zero hits → potential
  orphan. Cross-check `git log --grep="Run: <script>"` for recent commits
  using the analytical-commit-format convention. Note in the proposal.
  Adoption isn't the time to delete, but the researcher should know.

## Proposal format

Write `ADOPTION_PROPOSAL.md` at project root. Schema:

```markdown
# Adoption proposal — YYYY-MM-DD

Generated by adoption audit. **Nothing here has been moved, deleted, or
rewritten.** This proposal walks you through bringing this project under
research-to-policy. Each section lists what was found, what's proposed,
and the manual step to take. Work top-to-bottom; commit after each
section so the migration is bisectable.

## Preflight
- Framework installed: yes (`.claude/conventions/` present)
- Git status: clean / **<n> uncommitted changes — commit or stash before
  proceeding**
- Existing AI config detected: CLAUDE.md, .cursorrules

## Suggested execution order

1. Commit any pending work (preflight).
2. **Section 2** (CLAUDE.md / .claude/ reconciliation) — small, low-risk
   diff first.
3. **Section 3** (decisions/ archaeology) — high-value; doing this early
   surfaces what the project has already settled.
4. **Section 1** (file moves) — biggest diff; do it in chunks (wiki/raw/
   first, then output/, then intermediates).
5. **Section 4** (orphan analysis) — defer to a separate session, or to
   `/research-cleanup` once you're r2p-native.

After each section, commit with a message like:
- `adopt: extract methodology calls to decisions/`
- `adopt: move raw inputs to wiki/raw/`
- `adopt: prune CLAUDE.md duplicates now covered by conventions/`

## 1. File classification

### Likely raw data → `wiki/raw/<source>/`
- `data/wb_indicators_2024.csv` (847 KB) → propose
  `wiki/raw/world-bank/wb_indicators_2024.csv`. **Rationale**: filename pattern;
  treated as source of truth in scripts (no upstream generator).

### Likely processed/intermediate → `data/processed/`
- `panel_v2.csv` at root (12 MB) → propose `data/processed/panel_v2.csv`.
  **Rationale**: `_v2` suffix; modified 2026-04-15; output of
  `scripts/build_panel.py`.

### Likely chart/output → `output/`
- `fdi_chart.png` at root → propose `output/01_fdi_chart.png` (numeric
  prefix for sortability).

### Unclear provenance — researcher decides
- `combined_data.csv` (3.2 MB) at root. Could be raw download or derived.
  **Action**: open and inspect, then move to `wiki/raw/` or `data/processed/`.

### Scripts directory
- `scripts/` exists (14 .py files). Framework doesn't rename. **Action**:
  adopt `.claude/conventions/script-header.md` on next edit of each script.

(If a bucket is empty: `(none)` under that header.)

## 2. CLAUDE.md / .claude/ reconciliation

### Existing CLAUDE.md
- Lines 12–30 ("Code style") duplicate
  `.claude/conventions/script-header.md`. **Propose**: delete from
  CLAUDE.md.
- Lines 31–60 ("Project context: Cambodia case study") project-specific.
  **Keep** — this is what CLAUDE.md is for.
- Lines 61–65 ("Always run pytest before commit") operational project rule.
  **Propose**: move to `project_conventions/testing.md`.

### Pre-existing .claude/
- `.claude/hooks/format-on-save.sh` — pre-existing, no overlap with
  framework hooks. **Keep**.

### Other AI config
- `.cursorrules` — extract project-bearing rules to `project_conventions/`,
  leave file in place for Cursor users.

(If none: `(none)` under each header.)

## 3. Methodology archaeology

For each candidate, **write a `decisions/YYYY-MM-DD_<slug>.md` record**
using the source paragraph as raw material. Then either delete the
originating sentence or leave a one-line pointer.

- `README.md:42–46` — "We use the World Bank deflator series rather than
  IMF WEO because WEO has gaps for Cambodia 2018–2019." → propose
  `decisions/2026-05-08_use-wb-deflator-not-weo.md`.
- `scripts/build_panel.py:1–15` (docstring) — sample exclusion: "drop
  countries with <5 years coverage". → propose
  `decisions/2026-05-08_min-five-years-coverage.md`.
- `notes.md:18` — "We exclude oil exporters from the headline sample;
  sensitivity in appendix." → propose
  `decisions/2026-05-08_exclude-oil-exporters.md`.

## 4. Orphan analysis

(Cross-link: `/research-cleanup` is the ongoing-maintenance equivalent.
This is a one-time sweep at adoption.)

### Charts without evidence
- `output/explore_07.png`, `output/old_fdi_v3.png` — neither referenced in
  any markdown. **Decide**: keep + write retroactive insight, or move to
  `_archive/`.

### Scripts without inbound references
- `scripts/munge_v1.py` — superseded by v3 per filename pattern; no
  inbound references; no recent `Run:` commits. **Likely safe to archive.**

## Audits skipped (preconditions not met)

(List any audits the skill couldn't run — e.g. "chart audit skipped: no
output/, figures/, or charts/ directories present.")
```

If every audit returned zero findings, still write the file with `(none)`
under each section. The researcher needs to confirm the audit ran.

## Rules

- **Never moves a file.** Not even into a staging dir.
- **Never edits CLAUDE.md or any pre-existing file.** Suggest edits, never
  apply them.
- **Never writes a decision record.** Only surfaces candidates.
- **Never commits.** The proposal is uncommitted markdown.
- **Hedge on classification.** "Researcher decides" beats a wrong slot.
  False positives in classification cost 30 seconds; false negatives lose
  work.
- **Cite line numbers.** Every methodology-archaeology finding has a
  `file:line` reference — the researcher must verify the quote by hand.
- **Skip the directories listed under "Directories to skip".** Tooling state
  (`.git/`, `node_modules/`, `__pycache__/`, etc.) and framework working
  dirs (`plan/`, `archive/` — these belong to active framework usage, not
  pre-framework legacy).
- **Don't recurse twice.** Glob once per filetype at the start of the
  workflow; cache and reuse across audits.

## Boundary with /research-cleanup

This audit runs **once**, when bringing an existing project under the
framework. Its scope: *mapping unfamiliar structure onto framework slots*
and *extracting buried methodology*. Orphan detection appears here only
because adoption is a natural moment to confront accumulated cruft.

`/research-cleanup` runs **periodically**, once the project is r2p-native.
Its scope: *catching newly-accumulated cruft against framework reference
points* (raw watermark, evidence cross-references, recent `Run:` commits in
the analytical-commit-format).

After adoption, do not re-run this doc. Use `/research-cleanup` for
ongoing audits.

---

# Appendix: audit checklist

Detailed heuristics for: which directories to skip, which filename patterns
map to which framework slots, which trigger phrases surface methodology
calls, and which pre-existing AI config files to detect. The body above
describes *what* to do; the appendix describes *how to recognize* what's in
front of you.

## Directories to skip

Never recurse into these — they are tooling state, dependencies, or
framework working state, not pre-framework legacy content the audit cares
about:

```
.git/
.svn/
.hg/
node_modules/
.venv/
venv/
env/
.env/
renv/library/
renv/staging/
__pycache__/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.tox/
.Rproj.user/
.DS_Store
.idea/
.vscode/
.scc/
dist/
build/
target/
.next/
.cache/
```

Also skip the framework's own working directories — these belong to
**active** framework usage, not pre-framework legacy:

```
plan/                  # active multi-session work; archivist's domain
archive/               # archived plan synthesis; archivist's domain
brainstorms/           # gitignored working state
.claude/conventions/   # framework-installed; check exists, don't audit content
.claude/hooks/         # framework-installed
.claude/skills/        # framework-installed
.claude/agents/        # framework-installed
.claude/settings.json  # framework-installed
```

The audit is about pre-framework cruft, not framework state.

## File-pattern → slot mapping

Apply in priority order. First matching rule wins. If nothing matches,
classify as "unclear — researcher decides".

### Raw data → `wiki/raw/<source>/`

Filename / path patterns:

```
raw_*                       # explicit raw prefix
*_raw.*                     # explicit raw suffix
*_orig.*                    # original/unmodified marker
*/raw/**                    # already in a wiki/raw/ subtree
data/raw/**
*_v1.*                      # often the first download
download_*
fetched_*
api_response_*
```

Strengthening signals (not required, but tip a borderline file):
- File is referenced as **input** by ≥2 scripts (suggests it's a source).
- File has no upstream generator script in the repo.
- Modified date is older than every script that references it.

Weakening signals (tip toward "processed" or "unclear"):
- Filename includes a date that aligns with a script's run timestamp.
- Found inside a `data/processed/` or `output/` directory already.

### Processed/intermediate data → `data/processed/`

```
clean_*                     # cleaning step output
processed_*
panel_*                     # constructed panel
merged_*
joined_*
*_v2.*                      # version-suffixed, suggests revision
*_v3.*
*_vN.*                      # any version > v1
*_clean.*
*_final.*
*_export.*
*_for_<analysis>.*          # analysis-specific derivative
```

Strengthening:
- Generated by a script in the repo (grep its filename in scripts/).
- Sits in a `data/` directory but **not** under `data/raw/`.

If a `data/` directory exists with no `wiki/raw/` subdir, treat all data files
as "unclear" rather than guessing — the researcher's organization isn't
the framework's, and the wrong slot is worse than no slot.

### Charts/output → `output/`

```
*.png
*.pdf
*.svg
*.jpg
*.jpeg
*.html                      # plotly, leaflet, sphinx exports
```

Path heuristics:
- Already in `output/`, `figures/`, `charts/`, `plots/`, `viz/` → keep
  (rename the directory only if the framework convention is significantly
  better; don't churn for cosmetics).
- At project root → propose moving to `output/`.
- Inside `notebooks/` next to the source notebook → keep (notebook-local
  artifact); flag for the researcher to decide if it should be promoted.

When proposing the target name: if the project has more than ~5 charts and
none use a numeric prefix, suggest `output/NN_<descriptive_slug>.<ext>`
for sortability. Don't fight a project that already uses semantic names
(`output/cambodia_fdi_ratio.png`); just confirm.

### Markdown content → varies by content type

Never auto-classify markdown by filename alone. Read the first ~50 lines
and decide:

- **Methodology document** (audit 3 trigger phrases below) → flag for
  archaeology. Propose extracting decision sentences into
  `decisions/YYYY-MM-DD_<slug>.md`.
- **Findings document** (specific numbers, charts referenced, "we find",
  "shows that", "result:") → propose extracting into
  `evidence/NN_<slug>.md`. Suggest the next free `NN` from
  `ls evidence/ | sort | tail -1`.
- **Project README** with mixed methodology + scope + setup → keep README
  in place; flag methodology sections for archaeology, suggest moving
  setup instructions to `project_conventions/` if operational.
- **TODO / log / scratch** → leave in place; if there are gotchas worth
  preserving, suggest `learnings/<slug>.md` per the learning-capture
  convention.
- **Wiki-style structured page** (already a knowledge artifact, not a
  decision or finding) → propose moving to `wiki/` per the wiki-ingest
  schema.

### Scripts

```
*.py *.R *.r *.do *.jl *.sh *.ipynb
*.sql *.dot
```

Don't propose renaming `scripts/`, `src/`, `code/`, `analysis/`, or any
existing scripts directory. The framework doesn't mandate one. Just:

- Note the directory's existence in the proposal.
- Recommend `.claude/conventions/script-header.md` adoption on next edit.
- Recommend `.claude/conventions/analytical-commit-format.md` for future
  commits that produce charts/tables.

For notebooks (`.ipynb`):
- Don't propose moving them; researchers organize notebooks by workflow,
  not by framework slot.
- Do recommend a follow-up `/research-cleanup` pass to flag scratch cells.

### Configuration / project metadata

Leave alone:
```
package.json package-lock.json yarn.lock
requirements.txt pyproject.toml setup.py setup.cfg poetry.lock
renv.lock DESCRIPTION NAMESPACE
Makefile justfile
.gitignore .gitattributes
.python-version .nvmrc .tool-versions
.editorconfig
LICENSE LICENCE COPYING
```

These aren't research artifacts; they live where the language/tooling
expects them.

## Existing AI config — files to detect

Surface each of these in audit 2 if they exist:

```
CLAUDE.md                              # Anthropic / Claude Code (framework's slot too)
CLAUDE.local.md                        # user-local Claude config
.claude/                               # any pre-existing .claude/ content not framework-installed
.cursorrules                           # Cursor
.cursor/rules/                         # newer Cursor rules dir
.windsurfrules                         # Windsurf
AGENTS.md                              # generic agent contract
.github/copilot-instructions.md        # GitHub Copilot
.aider.conf.yml                        # Aider
.continue/                             # Continue.dev
```

For each, the audit reports: file path, ~line count, and a recommendation:

- **`CLAUDE.md` / `CLAUDE.local.md`**: section-by-section reconciliation
  per the rules in the body above (conflicts, duplicates, project-specific,
  operational rule).
- **Other tools' configs**: extract any project-bearing rules into
  `project_conventions/`, leave the originals in place. They're cheap and
  the project may have non-Claude collaborators.
- **Pre-existing `.claude/`** (not framework-installed): list each file,
  ask researcher to keep / delete / merge.

## Methodology archaeology — trigger phrases

Greppable patterns that suggest a sentence is a methodology call. Run
case-insensitive, word-boundary matching where it makes sense.

### Choice/decision phrases

```
we (chose|decided|use|adopted|opted)
chose .* (because|since|over|rather than|instead of)
(rather than|instead of|over) [A-Z]
rejected (because|due to|since)
preferred .* (over|to)
not [A-Z].* (because|since|due to)        # "not WEO because..."
the alternative would be
in lieu of
```

### Methodology nouns

```
deflator
specification
identification (strategy|assumption)
(sample|sampling) (restriction|exclusion|frame)
(reference|baseline) (category|year|country|group)
(treatment|control) group
(weight|weighting) (scheme|approach)
(IV|instrument|instrumental variable)
(fixed|random) effect
clustering (at|on)
robust (standard error|SE)
deflation by
expressed in (real|nominal|constant)
denominat(ed|or) (in|by)
exclude(d|s)? .* (because|since|due to)
trim(med|s)? .* (at|to|the)
winsoriz(ed|es)? at
threshold of
cutoff at
```

### Source-choice phrases

```
(use|using|prefer) the .* (series|dataset|panel|API|vintage)
(version|vintage|release) (10|11|...) of
WEO|PWT|WDI|EORA|GTAP|ICP|MPDS|UN ?Comtrade
the (latest|most recent) (release|vintage) of
because .* (gap|coverage|missing|inconsistent)
```

### Section-header signals

When walking markdown files, also flag the section if its **header**
matches:

```
^#+ \s*(Methodology|Approach|Decisions|Choices|Notes on .*)$
^#+ \s*(Why|Rationale|Reasoning)$
^#+ \s*(Sample|Coverage|Sources|Variables|Specification)$
```

Headers don't auto-promote the whole section into a decision record — the
researcher decides what's load-bearing — but they're strong hints worth
quoting in the proposal.

## Decision-record slug heuristics

When proposing a `decisions/YYYY-MM-DD_<slug>.md` filename:

- **Date**: best-guess from `git log -1 --format=%ad --date=short <file>`
  for the source file. If no git history, today's date.
- **Slug**: short, decision-bearing kebab-case. Lift the verb-object from
  the source sentence:
  - "We use WB deflator rather than WEO" → `use-wb-deflator-not-weo`.
  - "Drop countries with <5 years coverage" → `min-five-years-coverage`.
  - "Exclude oil exporters from headline sample" →
    `exclude-oil-exporters`.
- Avoid generic slugs (`decision1`, `methodology-note`, `choice`) — the
  researcher should be able to read the slug and recall the call without
  opening the file.

## Preflight checks

Before running the four audits, gather:

1. **Framework installed?** `test -d .claude/conventions/` and at least
   3 of the scaffolding dirs (`evidence/`, `decisions/`, `archive/`,
   `wiki/`, etc.). If not → write a one-section proposal recommending
   `r2p init` and stop.
2. **Git status.** `git status --porcelain | head -20`. If non-empty,
   record the count for the preflight section. Don't refuse to run — the
   researcher may have the proposal staged.
3. **AI config detection.** Test for each file in the "Existing AI
   config" list above; record presence for audit 2.
4. **Watermark.** Note the most recent file mtime project-wide
   (excluding skip-list dirs) — useful as the "as-of" stamp on the
   proposal so a later re-read knows when the audit ran.

## Output discipline

- Single output file: `ADOPTION_PROPOSAL.md` at project root.
- Overwrite if it exists.
- Every finding has: source path, proposed action (with target path or
  filename if relevant), one-sentence rationale, what was searched.
- Hedge calibration: `Likely safe to <action>` ≠ `Probably safe; verify
  X` ≠ `Researcher decides`. Use the strongest hedge that's honest.
- Empty audits: write `(none)` under the section header. Don't omit
  the header.
