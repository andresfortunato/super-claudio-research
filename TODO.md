# TODO — research-to-policy

Project-development backlog for the framework itself. Researchers *using* the framework do not need this file. **v3 is the current release** — it makes the citation chain checkable end to end and adds no migration. See `docs/v2-to-v3.md` for the change table and the traps, `docs/v1-to-v2-migration.md` for the release before it, and `docs/v2-case-study-cordoba.md` for the pilot audit that drove both.

## Shipped

- **v3** — the checkable chain (`citation-discipline.md`; the `artifacts:` evidence key; `lint-research.sh` 7 → 18 checks and 11.0s → 2.3s; `r2p evidence new <slug>` as the first reader of `.next-id`; `/cite-check` and `/pipeline-check`; principle 7's side-effect axis and the new principle 10; `03_linkcheck.py --baseline` + duplicate-path detector; `05_methods_merge.py` prints its heading tree; `migrate-source` repathed to v2; `test/upgrade-integration.sh` wired to `npm test`; the eight design docs for merged-away conventions deleted). See `docs/v2-to-v3.md`; archive entry lands at plan archival.
- **v2** — consolidation (conventions 13 → 7 mandatory + 2 optional; layout 15 → 8 scaffolded dirs; `research/claims.md` as the curated layer above append-only evidence; `Measured`/`Reading` split + frontmatter scope keys + machine-readable status in evidence; methods merged by topic rather than genre; wiki gated behind `r2p init --with-wiki`; `lint-research.sh` with seven invariants; `docs/field-notes/` for framework bugs found in project repos; `templates/migration/` scripts). See `archive/plan-r2p-v2-consolidation.md`.
- **v1.1** — cordoba-lessons (six small wins, theme-parallel opt-in, `brainstorming` skill, `learning-capture` skill + retrieve-learnings hook, plan archival via `archivist` agent + Stop hook tripwire, README rewrite for researcher audience). See `archive/plan-cordoba-lessons.md`.
- **v1.2** — skill-independence (vendored `planning`, `implementation`, `agent-teams` skills from super-claudio-code; added `r2p plan init <slug>` CLI subcommand; rationale at `docs/skill-independence-mechanism.md`). See `archive/plan-skill-independence.md` after archival.

## v2.1 — carried over from the v2 ship

**All four landed in v3** and are struck through rather than deleted, because
each one's entry records *why* it existed. Three closed in Phase 6:

- ~~**Repath `.claude/skills/migrate-source/SKILL.md` to v2.**~~ → `3e20032`. Its
  smoke test was redesigned rather than fixed; see `plan/plan-r2p-v3/log.md` D9.5.
- ~~**Integration-test `--upgrade`, not just `init`.**~~ → `d195621`.
  `test/upgrade-integration.sh`, wired to `npm test`.
- ~~**A duplicate-path-per-line detector for migrations.**~~ → `41a68d9`. Found a
  third live instance in `README.md` that the two-instance history did not know
  about.

The fourth landed in v3 Phase 7:

- ~~**Prune the `docs/*-mechanism.md` set.**~~ → decision **B**, resolved
  2026-09-09. Eight of the fourteen described conventions v2 merged away and are
  deleted, with every citation repointed in the same commit; the six describing
  live conventions stay and were repathed. The scope split is the correction:
  decision B said "the 14", and `docs/extending.md` still prescribes
  `docs/<name>-mechanism.md` as the rationale slot for every convention, so
  deleting all fourteen would have retired the pattern in the act of using it.

**v2.1 is closed.**

## Open — small, diagnosed, not scheduled

- ~~**`templates/research/sources/EXAMPLE_world_bank_api.md` fails the v2
  required shape.**~~ → reshaped in v3 Phase 7. Kept as an entry because the
  defect class recurs: a worked example is the file a project copies, so it is
  the *last* place a convention change should be allowed to lag, and it was the
  last place this one reached.
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
- **The framework repo has no `.claude/settings.json` of its own**, so its hooks
  are unwired here — `lint-research.sh` and `check-archival.sh` only run because
  a session types them. It also had no `CLAUDE.md` until 2026-08-05. Both are the
  framework not running the framework. Worth deciding deliberately rather than
  fixing in a release commit: wiring `check-archival.sh` here would mean r2p's
  own plans get the archival tripwire, which is the behaviour it ships.
- **`lint-research.sh` has no CI job anywhere.** It is designed to run from CI
  and does not, in this repo or in the pilot. A GitHub Actions workflow is a
  dozen lines and would make the FAIL tier mean something.

## v4 — the plugin migration

Deferred out of v3 deliberately: it moves every file v3 touched and would have
collided throughout. It lands cleanly now that the convention surface has settled.

- **Plugin migration (dual CLI + plugin distribution)** — convert r2p from "npm CLI + global symlinks" to "npm CLI + Claude Code plugin" (the scc / Everything-Claude-Code pattern). Skills would get auto-rendered `(research-to-policy)` labels and namespaced commands (`/research-to-policy:planning`) — replaces the current hardcoded `(r2p) ` prefix in description fields. CLI shrinks to project-only scaffolding; plugin owns skills/hooks/agents. Layout: add `.claude-plugin/{plugin.json, marketplace.json}`, move `.claude/skills/` → `skills/`, `.claude/hooks/` → `hooks/` (+ `hooks/hooks.json` for auto-wiring), `.claude/agents/` → `agents/`, `.claude/conventions/` → `conventions/`. Delete `src/lib/install-globals.js` (plugin handles symlinks via `${CLAUDE_PLUGIN_ROOT}`). Drop hook entries from project `settings.json` (plugin auto-wires). `r2p init` writes `extraKnownMarketplaces` + `enabledPlugins` block to project's `.claude/settings.json` instead of symlinking. Once landed: revert the hardcoded `(r2p) ` description prefix on all 12 skills. Reference: `~/github/super-claudio-code/.claude-plugin/` and its README "Installation" section for the dual-channel pattern. Confirmed-real env var: `${CLAUDE_PLUGIN_ROOT}` (used by Superpowers in its `hooks/hooks.json`).

## Beyond v4

Four entries below this line shipped in v3 and are deleted rather than struck,
because a backlog that keeps its own graduates looks longer than it is. What each
became is recorded in `docs/v2-to-v3.md`, and the two that shipped in a *different
shape* than proposed have their rejected shapes recorded in
`docs/citation-chain-mechanism.md` — `chart-registry`'s `save_fig(findings={...})`
and `pipeline-check`'s whole-pipeline harness. Do not re-propose either without
reading why they were rejected. `evidence-ledger` is `research/claims.md`;
`citation-discipline` is a convention of that name.

- **LaTeX/Beamer add-on** — borrowed from Pedro/Hugo Sant'Anna's templates; useful when the deliverable register shifts toward academic outputs.
- **WIP-limited multi-project dashboard** (Hugo's vault-manager pattern) — for researchers juggling multiple country engagements.
- **Stata first-class support** — alongside R and Python.
- **Mode-registry / cross-skill advisor** (Imbad pattern) — for when "which entry point?" becomes the bottleneck. **The original trigger was "once skill count exceeds ~8"; r2p ships 15 and the bottleneck has not appeared**, which is the constitution's own point about absolute counts: the trigger is a *symptom* (a session reaching for the wrong skill, or asking which one applies), not a number. Re-state it that way before acting on it.
- **Globalize conventions** (without conflicting with Claude's defaults) — let researchers share one set of conventions across multiple project repos. Open question: how does this interact with project-shared `.claude/conventions/` (README principle 4 — "project-shared, not user-personal")? Collaborators cloning a project repo without `r2p` installed would see `@`-references in `CLAUDE.md` to paths that don't exist for them.

## Build pattern for new entries

Each addition follows the same pattern: one convention file in `.claude/conventions/`, optionally one hook script in `.claude/hooks/`, one section in `docs/`, optionally a skill in `.claude/skills/`. See `docs/extending.md`.
