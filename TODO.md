# TODO — research-to-policy

Project-development backlog for the framework itself. Researchers *using* the framework do not need this file. **v2 is the current release** (merged to `main` 2026-08-04) — a consolidation promoted from the six-month Córdoba pilot audit, not a feature release. See `docs/v1-to-v2-migration.md` for the change table and `docs/v2-case-study-cordoba.md` for the audit behind it.

## Shipped

- **v2** — consolidation (conventions 13 → 7 mandatory + 2 optional; layout 15 → 8 scaffolded dirs; `research/claims.md` as the curated layer above append-only evidence; `Measured`/`Reading` split + frontmatter scope keys + machine-readable status in evidence; methods merged by topic rather than genre; wiki gated behind `r2p init --with-wiki`; `lint-research.sh` with seven invariants; `docs/field-notes/` for framework bugs found in project repos; `templates/migration/` scripts). See `archive/plan-r2p-v2-consolidation.md`.
- **v1.1** — cordoba-lessons (six small wins, theme-parallel opt-in, `brainstorming` skill, `learning-capture` skill + retrieve-learnings hook, plan archival via `archivist` agent + Stop hook tripwire, README rewrite for researcher audience). See `archive/plan-cordoba-lessons.md`.
- **v1.2** — skill-independence (vendored `planning`, `implementation`, `agent-teams` skills from super-claudio-code; added `r2p plan init <slug>` CLI subcommand; rationale at `docs/skill-independence-mechanism.md`). See `archive/plan-skill-independence.md` after archival.

## v2.1 — carried over from the v2 ship

**Three of the four below landed in v3 Phase 6 on 2026-09-09** and are struck
through rather than deleted, because each one's entry records *why* it existed:

- ~~**Repath `.claude/skills/migrate-source/SKILL.md` to v2.**~~ → `3e20032`. Its
  smoke test was redesigned rather than fixed; see `plan/plan-r2p-v3/log.md` D9.5.
- ~~**Integration-test `--upgrade`, not just `init`.**~~ → `d195621`.
  `test/upgrade-integration.sh`, wired to `npm test`.
- ~~**A duplicate-path-per-line detector for migrations.**~~ → `41a68d9`. Found a
  third live instance in `README.md` that the two-instance history did not know
  about.

Still open, and now Phase 7's:

- **Prune the `docs/*-mechanism.md` set.** ⚠ Decision **B** (2026-09-09) chose
  **delete**, against the recommendation to shelve under `docs/v1/`. Phase 7 must
  audit and repoint or drop every reference **in the same commit as the
  deletion** — `lint-research.sh` invariant 15 now reports those pointers, so
  the sweep is checkable rather than a hand-built list. v2 kept them on v1 paths deliberately — they describe v1 accurately — but the live docs set now documents merged conventions. Present duplicates: `data-access-mechanism.md` + `data-sources-mechanism.md` (both → `sources.md`); `brainstorm-mechanism.md` + `handoff-mechanism.md` + `plan-structure-mechanism.md` (all → `plan-lifecycle.md`); `learning-capture-mechanism-v1.md` + `methods-mechanism-v1.md` (both → `methods.md`). Decide per file: fold into a v2 mechanism doc, move under a `docs/v1/` shelf, or delete. Flagged in `docs/v2-case-study-cordoba.md` §7.
- **Repath `.claude/skills/migrate-source/SKILL.md` to v2.** It hard-refuses unless `.claude/conventions/data-access.md` and `<donor>/data_sources/INDEX.md` exist, neither of which a v2 project has, and its Globs target the old paths throughout. Port to `sources.md` + `research/sources/`, then re-run validation with a venv at the test target (the old blocker: the post-apply smoke test never literally passed). Both plans were archived as superseded on 2026-08-04 — see `archive/plan-migrate-source-skill.md` for the decisions and the five discovery findings, so they don't get re-derived.
- **Integration-test `--upgrade`, not just `init`.** v2's own lesson was that scaffolding changes get verified by running `r2p init` into a temp repo — but `--upgrade` is a second installer with its own path logic, and three v2 defects lived only there (stale `EXCLUDE`, unmapped `templates/plan_dir`+`claude_conventions_project`, ungated wiki). All three were invisible to an `init` test. Worth a script: init a temp project, dirty the append-only files, upgrade, and assert on sidecar count and root-dir list.
- **A duplicate-path-per-line detector for migrations.** `02_repath.py`'s `EXCLUDE_PREFIXES` guard cannot catch a many-to-one collapse — when three v1 dirs map to one v2 dir, an enumerating sentence becomes the same *valid* path three times, so linkcheck passes. Two instances shipped in v2 and were fixed by hand. The check is three lines: flag any line where a path pattern matches 2+ times with fewer distinct values than matches. Belongs in `03_linkcheck.py`.

## Added by v3 Phase 6 — small, diagnosed, not scheduled

- **`templates/research/sources/EXAMPLE_world_bank_api.md` fails the v2 required
  shape.** v2 frontmatter, v1 section headings (Endpoints / Query shape / Parsing
  / Pitfalls) where `sources.md` defines What it gives you / Access / Headline
  anchor / Gotchas / Coverage limits. The framework's own worked example does not
  follow its own convention. Reshaping it is editorial work about the World Bank
  API rather than a repath, which is why Phase 6 left it; `research/sources/INDEX.md`
  now warns readers to follow the list and not the example.
- **A shipped runtime surface must not point into `docs/`.** `r2p init` does not
  install `docs/`, so a template or convention citing `docs/<name>.md` dangles in
  every project while resolving fine in the framework repo. Five instances were
  fixed in `411ec33` by naming the framework repo, the way
  `install-project.js:302` already did. Not mechanised: the judgement is whether
  the reference is *qualified*, which a grep cannot decide.
- **`--upgrade` could warn about a stale project `CLAUDE.md`.** The pilot's still
  lists `.claude/skills/` (global since v2) and describes a Stop hook that no
  longer exists. `--upgrade` does not touch project `CLAUDE.md` and probably
  should not; a warning is the same cheap fix as the orphaned-hook one in
  `d195621`.
- **Nothing checks `.scc/status/project.md` for staleness.** It is the first
  thing a session reads, and it sat five weeks wrong at the top of every session.

## v1.3 and beyond

- **Plugin migration (dual CLI + plugin distribution)** — convert r2p from "npm CLI + global symlinks" to "npm CLI + Claude Code plugin" (the scc / Everything-Claude-Code pattern). Skills would get auto-rendered `(research-to-policy)` labels and namespaced commands (`/research-to-policy:planning`) — replaces the current hardcoded `(r2p) ` prefix in description fields. CLI shrinks to project-only scaffolding; plugin owns skills/hooks/agents. Layout: add `.claude-plugin/{plugin.json, marketplace.json}`, move `.claude/skills/` → `skills/`, `.claude/hooks/` → `hooks/` (+ `hooks/hooks.json` for auto-wiring), `.claude/agents/` → `agents/`, `.claude/conventions/` → `conventions/`. Delete `src/lib/install-globals.js` (plugin handles symlinks via `${CLAUDE_PLUGIN_ROOT}`). Drop hook entries from project `settings.json` (plugin auto-wires). `r2p init` writes `extraKnownMarketplaces` + `enabledPlugins` block to project's `.claude/settings.json` instead of symlinking. Once landed: revert the hardcoded `(r2p) ` description prefix on all 12 skills. Reference: `~/github/super-claudio-code/.claude-plugin/` and its README "Installation" section for the dual-channel pattern. Confirmed-real env var: `${CLAUDE_PLUGIN_ROOT}` (used by Superpowers in its `hooks/hooks.json`).
- **TDD-equivalent for research pipelines** — heavier whole-pipeline regression on every change (per-artifact `/verify` covers single-artifact sanity but not full-pipeline drift). Possible skill name: `pipeline-check`.
- **`evidence-ledger`** — a project-level table of formal claims, the chart/CSV that supports each, and whether the claim has been challenged.
- **`chart-registry`** — `save_fig(findings={...})` pattern so every chart ships with metadata Claude can read without re-opening the PNG.
- **`citation-discipline`** — every quantitative claim must reference a source (paper, dataset, internal doc).
- **LaTeX/Beamer add-on** — borrowed from Pedro/Hugo Sant'Anna's templates; useful when the deliverable register shifts toward academic outputs.
- **WIP-limited multi-project dashboard** (Hugo's vault-manager pattern) — for researchers juggling multiple country engagements.
- **Stata first-class support** — alongside R and Python.
- **Mode-registry / cross-skill advisor** (Imbad pattern) — once skill count exceeds ~8 and "which entry point?" becomes the bottleneck.
- **Globalize conventions** (without conflicting with Claude's defaults) — let researchers share one set of conventions across multiple project repos. Open question: how does this interact with project-shared `.claude/conventions/` (README principle 4 — "project-shared, not user-personal")? Collaborators cloning a project repo without `r2p` installed would see `@`-references in `CLAUDE.md` to paths that don't exist for them.

## Build pattern for new entries

Each addition follows the same pattern: one convention file in `.claude/conventions/`, optionally one hook script in `.claude/hooks/`, one section in `docs/`, optionally a skill in `.claude/skills/`. See `docs/extending.md`.
