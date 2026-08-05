# Context — how a new framework artifact reaches a project

Read this instead of `install-project.js`, `upgrade.js`, `template-map.js`,
`install-globals.js` and `cli.js`. Written 2026-08-05 by reading all five.
Serves Phases 3, 4, 5, 6d and 7.

## The one-line answer per artifact type

v3 adds a convention, three skills, a CLI subcommand and lint checks. What each
requires of the installers:

| v3 adds | Installer change needed |
|---|---|
| `.claude/conventions/citation-discipline.md` | **none** — both installers walk the whole directory |
| `.claude/skills/{cite-check,pipeline-check}/` | **none** — global symlinks are enumerated at runtime |
| edits to `lint-research.sh` | **none** — `.claude/hooks/` is walked whole |
| `src/commands/evidence.js` | register in `src/cli.js` only |
| a *new hook script* | mirrored automatically, **but** it must be added to `.claude/settings.template.json`, and existing projects are only *told* to merge it — see the trap below |
| a *new template file or dir* | if it is project-appended state, add to `EXCLUDE`; if it should never install, add to `TEMPLATE_NOT_INSTALLED`; if its project name differs from its template name, add to `TEMPLATE_DIR_MAP` |

**So the v3 manifest's `src/lib/upgrade.js ✎` entry is probably unnecessary.**
Confirm by reading `upgrade.js:258–270` before editing it — the candidate list is
built by walking directories, not by enumerating files. Adding a convention and
two skills requires no edit. Delete that manifest line if it holds.

## The two installers, and the shared table

`src/commands/init.js` branches on `--upgrade`: `upgradeProject()` or
`installProject()`, then **both** call `installGlobals()`.

`src/lib/template-map.js` is the single source of truth for "where does this
`templates/` path land in a project", and it exists because of a shipped bug:
install carried an explicit MIRRORS table while upgrade just stripped the
`templates/` prefix, so `--upgrade` wrote `claude_conventions_project/`,
`plan_dir/` and `migration/` into project roots as **new top-level directories**
— on the release whose headline was getting a project down to eight legible root
dirs. Three exports:

- `TEMPLATE_DIR_MAP` — template dir → project dir, for names that differ or nest
  (`templates/plan_dir` → `plan`, `templates/claude_conventions_project` →
  `.claude/conventions/project`). **Longest prefix wins**, which is the only
  reason `templates/plan_dir/…` doesn't match `templates/plan/`.
- `TEMPLATE_NOT_INSTALLED` + `isNotInstalled()` — paths that never get a project
  copy: `templates/migration/` (read-and-adapt, not vendored), `templates/plan/`
  (scaffolded per-plan by `r2p plan init`), `CLAUDE.md.template`, `.env.example`,
  `handoff.md`.
- `toProjectRel()` — the mapping, returning `null` for no-copy.

**Add a template directory to this table, not to either installer.**

## `installProject()` — the init path

1. Mirrors `.claude/conventions/` and `.claude/hooks/`.
2. Copies `.claude/settings.template.json` → project `.claude/settings.json`
   **only if absent**; otherwise prints "merge new hook entries manually".
3. Mirrors every `TEMPLATE_DIR_MAP` source, **then** `mkdir`s whatever
   `SCAFFOLDING_DIRS` is still missing. **The order is load-bearing and
   commented as such**: `mirrorDir` → `copyIfAbsent` skips any path that already
   exists *including directories*, so `mkdir research/evidence/` first made the
   mirror skip `research/` wholesale and shipped an empty tree to every new
   project. This is case-study §5.4 — *idempotent by rebuild, not by skip*.
4. `SCAFFOLDING_DIRS` is the eight-root-dir list, expanded: `research{,/evidence,
   /methods,/methods/_adjuncts,/sources}`, `deliverables{,/memos,/decks}`,
   `reference{,/literature,/notes,/internal,/external}`, `plan{,/archive,
   /brainstorms}`, `data`, `analysis`, `output`.
5. Writes the gitignore block. Note `plan/`, `brainstorms/` and `.scc/` are
   **gitignored in target projects** — framework working state is local.
6. `withWiki` gates three things, not one: `skip: ['wiki']` when mirroring
   `templates/research`, the `WIKI_DIRS` mkdir, and the `seen.jsonl` seed.

## `upgradeProject()` — the path that gets forgotten

Candidate list (`upgrade.js:258–270`): walk `.claude/conventions`, walk
`.claude/hooks`, walk `templates` minus `EXCLUDE` minus `isNotInstalled()` minus
`templates/research/wiki/` unless `includeWiki`, plus the single file
`.claude/settings.template.json`.

- `EXCLUDE` is **project-appended state**, not framework content: `claims.md`,
  the three `INDEX.md`s, `.next-id`, the project-conventions INDEX, and the four
  wiki state files. Divergence there is the expected steady state.
- `staleExcludes()` (lines 104–114) guards the failure this file already shipped
  once: eight EXCLUDE paths went stale when v2 moved `templates/`, and **a
  non-matching EXCLUDE entry is silently inert**. Phase 6d asserts on this guard
  rather than re-implementing it.
- Divergent files become **sidecars** for the researcher to diff and delete; a
  project's own `settings.json` is never rewritten.
- `migrateLayout()` renames legacy wiki paths (`raw/` → `wiki/raw/`,
  `sources/registry.yaml` → `wiki/raw/registry.yaml`, …).
- A project without `research/wiki/` has **chosen** that (v2 gated it after six
  months of zero pages). Upgrade treats its absence as a decision, not a gap.

## Skills and agents are global, not per-project

`installGlobals()` `readdir`s the framework's `.claude/skills/` and
`.claude/agents/` and symlinks each entry into `~/.claude/`, pruning stale
framework-owned symlinks whose targets vanished. Consequences:

- **A new skill directory needs no installer edit.** Phases 4 and 5 add
  `cite-check/` and `pipeline-check/` and are done.
- Skills are **not** committed into target repos — which is why every skill
  description carries the hardcoded `(r2p) ` prefix (the plugin migration in v4
  replaces that with auto-rendered namespacing).
- A renamed or deleted skill self-cleans on the next `installGlobals()`.

## The trap Phase 6d must cover

**Hooks are mirrored but not wired.** A new hook script lands in the project's
`.claude/hooks/` on both paths, but it only *runs* if it is listed in that
project's `.claude/settings.json` — which `--upgrade` deliberately never
rewrites, and which init only writes when absent. So an existing project
upgrading to a release that adds a hook gets the script and not the wiring, with
one console line as the entire notification. v3 adds no hook, so this is not
blocking; it is the reason it adds none, and `docs/extending.md` step 2 should
say so.

**And this framework repo has no `.claude/settings.json` of its own** — only the
template. Its own hooks are therefore unwired here, which is consistent with it
having had no `CLAUDE.md` until 2026-08-05: the framework repo does not run the
framework. Worth a decision in Phase 7, not a silent fix.
