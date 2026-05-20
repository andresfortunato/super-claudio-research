# /r2p-migrate-source Skill — Brainstorming Summary

## Problem

Mature r2p projects (e.g. `~/cambodia-growth`) develop a clean data
layer — per-source ref docs, wrapper functions in `<project>_utils.py`,
env-var prefixes, INDEX rows, `data/README.md` entries, CLAUDE.md
mentions. Newer projects (e.g. `~/cordoba`) starting fresh have to
re-derive the same pieces source-by-source, even when the upstream
APIs are identical (IMF SDMX, BIS, Atlas Postgres). The framework
needs a way to **transplant** one source's full data layer from a
donor project to a target, with project-specific bits (country lists,
verification anchors, utility-module names) adapted to the target.

## Decisions Made

- **Migration unit = full data layer for one source (transplant).**
  Atomic unit is "everything for IMF" or "everything for Atlas" —
  ref doc + companion files (OpenAPI, etc.) + wrapper functions +
  env-var declarations + INDEX row + `data/README.md` section +
  CLAUDE.md mention if applicable. Per-wrapper rejected (too
  granular; shared deps split awkwardly). Whole-pipeline-at-once
  rejected (user wants to cherry-pick which sources to bring).

- **Adaptation = LLM at migration time, zero donor-side prep.**
  Rejected: verbatim-copy-plus-sed (Cambodia cruft leaks — country-id
  maps, headline anchors, peer-country lists). Rejected: donor-side
  discipline (BEGIN/END markers in utility module + per-source
  Migration sections in ref docs) — too much permanent maintenance
  tax on every donor project forever, markers drift silently. The
  data-access convention already gives the LLM enough scaffolding
  to do discovery at runtime: INDEX Helper-functions table, wrapper
  docstring back-links, source-prefixed file names, source-prefixed
  env vars.

- **Verification state handling = strip-and-prompt, not auto-derive.**
  On migration, the `Status: verified <date>` line is removed and the
  Cambodia-specific headline anchor is replaced with `TODO(migrate):
  verify against <target context>`. The new project's next session
  re-runs the anchor query and restores Status only if the value is
  reproduced. No auto-derivation (would silently mask upstream API
  drift; would require the migration tool to actually hit
  credentialled APIs the target may not yet have access to).

- **Conflict handling = git-style merge markers in target files.**
  If `data_sources/imf_sdmx_api.md` already exists at target, the
  tool writes a conflict-marker'd version (`<<<<<<<` / `=======` /
  `>>>>>>>`) and defers to the user. Leverages existing mental model;
  no bespoke merge UI to invent.

- **Form-factor = skill (`/r2p-migrate-source`), not CLI command.**
  The spine is conversational — discovery, dependency analysis,
  target-context gathering, and adaptation all need LLM reasoning at
  runtime. Mechanical bits (file copy, sed rename, env-var append)
  can be invoked via Bash from inside the skill, but the skill
  drives.

- **Apply gate = proposal-then-apply.** Tool writes
  `MIGRATION_PROPOSAL.md` first, listing every file to create/append,
  every conflict, every TODO. Nothing lands on disk until the user
  approves. Then files are applied and `MIGRATION_TODO.md` is written
  at target root listing post-migration re-verification steps.

## Research Findings

- **cambodia-growth's data layer maps cleanly to the model.** Prior
  Explore-agent audit confirmed that the project has (per source) one
  wrapper function (sometimes a small set), source-prefixed env vars,
  a ref doc, and an INDEX entry. No source uses constructs that
  defeat the model (e.g. wrappers dynamically generated from config).

- **data-access convention provides the runtime anchors.** Just
  shipped in this session. The INDEX Helper-functions table is the
  single highest-leverage anchor — it's the entry point from "user
  says `imf`" to "here are the wrapper + ref doc to lift."

## Open Questions

- **Single-source vs multi-source per invocation.** Does
  `/r2p-migrate-source --from <donor> --source imf,atlas,bis` work,
  or one source per invocation? Lean: support both; default is one
  source per call (the proposal-then-apply gate is per-source).

- **Target-context gathering shape.** Tool needs target country ISO,
  peer-country list, and the target utility module's name. Options:
  one batched `AskUserQuestion` early; or guess from target's
  existing CLAUDE.md / dirname and confirm. Lean: guess + confirm.

- **Target may lack `<target>_utils.py` entirely.** If cordoba has no
  utility module yet, does the tool create one? Lean: yes — bootstrap
  it with the lifted wrapper plus the `load_dotenv()` boot block from
  the data-access convention's worked example.

- **Pre-flight: target may lack data-access convention.** If the
  target hasn't run `r2p init` (no
  `.claude/conventions/data-access.md`), refuse? auto-install? Lean:
  refuse with a one-line "run `r2p init --upgrade` first" message.

- **Smoke-test step.** Post-apply, the tool should run something to
  confirm the transplant works. Options: (a) confirm `python -c
  "from <target>_utils import <wrapper>"` succeeds, (b) actually
  call the wrapper with target params and check response shape, (c)
  defer to user. Lean: (a) for now (cheap, catches import errors);
  (b) is a v1.x extension that requires `.env` to be populated.

- **Relationship to `/r2p-adopt`.** `/r2p-adopt` is for adopting a
  legacy non-r2p project. Migration is r2p→r2p. They share the
  "proposal-then-apply" pattern but operate on different inputs.
  Lean: keep separate; cross-link in docs.

## Constraints Identified

- **Tokens per migration: ~30–50k.** Acceptable because migrations
  are rare (handful per project lifecycle).

- **Non-determinism.** Two runs may surface slightly different dep
  lists; mitigated by the proposal-then-apply gate.

- **LLM may miss obscure shared dependencies.** Mitigated by the
  smoke test + headline-anchor re-verification post-migration.

- **Conflict resolution requires git-aware user.** Acceptable: r2p
  users are already git-fluent.

- **Donor must have data-access convention installed.** Implicit for
  any r2p project that has run `r2p init` after this session's
  v1.2 ships.

## Decision records to file

- None — framework-design decisions live in
  `docs/<name>-mechanism.md` files. The mechanism doc for this skill
  (`docs/migrate-source-mechanism.md`) will capture the rationale and
  tradeoffs. No `decisions/YYYY-MM-DD_<slug>.md` needed at framework
  scope.
