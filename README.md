# Research to Policy

A Claude Code harness for **applied research projects** — applied development economics and policy research.

The default Claude Code experience is built for software engineering. Research projects have different rhythms: long multi-session plans, evidence accumulation across phases, the need to remember what was *learned* (not just what was *built*), and a constant temptation to over-produce charts without distilling findings. This framework adds the lightweight conventions and hooks that make Claude Code work for that flow. The workflow is focused on:

- Planning calibrated for the iterative reality of research — deliberated up front, not over-specified
- Context management so that we avoid context rot and codebase re-exploration every time
- Multi-session orchestration so that we don't worry about referencing files or summaries any more
- Automated learning to take notes of relevant challenges or solutions
- Verification during analysis and before publishing — every artifact and deliverable gets a domain-aware sanity check, not a CI-style green-light test
- Reproducibility — analytical artifacts trace back to the script and inputs that made them, instead of disappearing into undocumented one-off runs
- Analytical structure that separates raw sources from analysis, and exploration from findings, so the project doesn't collapse into an undifferentiated dump of scripts and PNGs


## Quickstart

```bash
npm install -g github:andresfortunato/research-to-policy
cd /path/to/your/research-project
r2p init
```

`r2p init` is idempotent — safe to re-run. It seeds the project with `.claude/{conventions,hooks}/`, `.claude/settings.json`, scaffolding directories (`research/evidence/`, `research/wiki/`, `research/methods/`, `research/methods/`, `research/methods/`, `plan/archive/`, `deliverables/`, etc.), `CLAUDE.md`, and a framework block in `.gitignore`. Skills and agents are global — symlinked into `~/.claude/{skills,agents}/` so an upgrade lands everywhere automatically. Existing files are never overwritten — in particular, if `CLAUDE.md` already exists, `r2p init` leaves it untouched and drops the framework template at `CLAUDE_TEMPLATE.md` alongside it so you can diff and merge.

### Adopting r2p in an existing, disorganized project

If the project predates r2p — random scripts at the root, charts mixed with data, methodology buried in `README.md` and script docstrings, prior `CLAUDE.md` or `.cursorrules` content — run the adoption audit after `r2p init`. The audit walks the tree, classifies pre-existing files against framework slots (`research/wiki/raw/`, `output/`, `data/processed/`, `research/methods/`, `research/evidence/`, `.claude/conventions/project/`), reconciles any prior AI config, surfaces methodology calls hidden in unstructured locations as candidate `research/methods/` records, and flags orphan analysis. Output is `ADOPTION_PROPOSAL.md` at project root. **Nothing is moved automatically** — you review the proposal section by section, execute the moves by hand, and commit after each. Run once per project, at adoption; for ongoing maintenance use `/research-cleanup`.

The audit is shipped as a plain instruction document (`docs/r2p-adopt.md` in the framework), **not as an installed skill** — it's only useful once per project, so the framework keeps it out of Claude's context until you explicitly ask for it. To run it, paste a prompt like this in a Claude Code session at the project root:

```
Read the r2p adoption instructions at $(npm root -g)/research-to-policy/docs/r2p-adopt.md
and run the adoption audit on this project. Walk through preflight, the four audits,
and write the proposal to ADOPTION_PROPOSAL.md. Don't move, delete, or edit any file —
proposal only.
```

If you have a local clone of the framework, point Claude at `<your-clone>/docs/r2p-adopt.md` instead. The document is self-contained; Claude reads it, runs the audit, and writes `ADOPTION_PROPOSAL.md`. **Greenfield project?** Skip this entirely — `r2p init` lays down the framework structure clean, there's nothing to adopt.

Once installed, a typical first session:

```text
/brainstorming  What deflator should we use for cross-city wage comparisons?
   → discussion lands at plan/brainstorms/wage-deflator.md
   → settled call cited at research/methods/2026-05-08_deflator-choice.md
/planning       Build out the wage-gaps analysis from this brainstorm
   → produces plan/plan-wage-gaps/{plan.md, phases/phase-N.md, handoff.md}
/implementation Pick up plan-wage-gaps from the handoff
   → run scripts (with header), commit with Run:/Out: lines
   → write research/evidence/01_wage-gaps-by-city.md after the chart drops
   → handoff.md is rewritten at session end
```

When the plan is verified end-to-end, `touch plan/plan-wage-gaps/.completed` triggers the archivist on the next Stop event.

## What the framework does

### Principles

- We shouldn't assign too much weight to plans, assuming almost automatic execution. Iteration makes planning better. Plans are the map, not the territory.
- Many plans tend to micromanage implementation, which is counterproductive because in reality plans change all the time. Micromanaged plans constrain the implementation agent's problem-solving capacity.
- Baking code snippets in plans is a waste of tokens. The implementation agent or session will re-read the codebase.
- We want to minimize the ratio of .md lines to code execution that is required to achieve high quality results.
- Verification belongs on the *substance* of the analysis, not on Python type signatures. The right checks are sign-of-coefficients, magnitude plausibility, missingness, and source citation — and they are stakes-graded: cheap per-artifact (`/verify`) for in-progress work, heavier multi-lens forked review (`/deliverable-review`) for last-mile drafts.
- Reproducibility is a contract, not an aspiration. Every analytical chart, table, and number must resolve via `git log` to the script, seed, and inputs that produced it. Script headers, `Run:`/`Out:` commit lines, and `.meta.json` sidecars are how that contract is enforced.
- Working state and settled findings live in different folders. Brainstorms and plans are gitignored exploration; decisions, evidence, and the archive are the project's persistent, citable memory. Conflating them makes the project unreadable to future-you and to peer reviewers.


### Workflow: brainstorming → planning → implementation → archival

Research is not a march from spec to ship. It's iteration with branches: a methodology call you couldn't predict before staring at the data, a robustness check that opens a new sub-question, a deliverable that needs a different framing for a different audience. The framework names four lifecycle moments and equips each:

1. **Brainstorming.** Before a plan, methodology calls deserve deliberation: which deflator, which identification strategy, which reference category, how to handle a survey-vintage break. `/brainstorming` runs a three-phase exchange (listen → challenge → propose alternatives), capturing the conversation in `plan/brainstorms/<topic>.md`. When the call is settled, the choices a peer reviewer would push on graduate to `research/methods/<topic>.md` (Rule / Why-not-the-alternatives / Traps / Diagnostic counts). The brainstorm is gitignored working state; the decision record is the citable artifact.

2. **Planning.** With methodology settled, `/planning` produces a multi-phase plan at `plan/plan-<slug>/{plan.md, phases/phase-N.md, handoff.md}`. Verification is **domain-shaped** — sign-of-coefficients, magnitude sanity, source-citation present, breakpoint alignment — not unit tests. Methodology cross-links to the relevant `research/methods/` records.

3. **Implementation.** `/implementation` reads `plan.md` + `handoff.md` and works through phases. Every analytical script gets a fixed-shape header (Inputs / Outputs / Seed / Env); every analytical commit carries `Run:` and `Out:` lines so `git log -- output/06_chart.png` resolves to the script that made it. After substantive analysis, write `research/evidence/NN_<slug>.md` (3–8 evidence-based findings with concrete numbers) and append a row to `research/evidence/INDEX.md`. The Stop hook nudges if uncommitted analysis exists without a fresh evidence doc. At session end, rewrite `handoff.md` — the bridge to the next session, the next collaborator, or future-you a year later.

4. **Archival.** When every phase verifies and the researcher confirms the plan is done, `touch plan/plan-<slug>/.completed`. The Stop hook's archival tripwire emits a blocking instruction; Claude launches the **archivist** subagent, which synthesizes `plan/archive/plan-<slug>.md` (What was built / Key decisions / Methods landed / Files modified / Learnings / Metrics), appends a one-liner to `plan/archive/index.md`, optionally updates `CLAUDE.md` if architecture changed, and deletes the plan directory. Per-plan; project-wide cleanup is the user-invoked `/research-cleanup`.

Two cross-cutting affordances run alongside the workflow. **Learnings** — gotchas and tacit findings worth remembering across plans — get filed at `research/methods/<slug>.md` with trigger keywords; the `retrieve-learnings.sh` hook surfaces matches when the user's prompt contains ≥2 keywords from a given learning. **Pre-compaction handoff** — the `precompact-handoff.sh` hook fires before auto-compaction and nudges a handoff refresh plus a sweep for session surprises worth preserving as learnings.

### Scaffolding and project structure

What `r2p init` lays down in your research project — **eight top-level
directories**, down from fifteen in v1:

```text
your-research-project/
├── .claude/                   ← framework conventions, hooks, settings (committed)
│   └── conventions/project/   ← project-bespoke style/process rules
├── CLAUDE.md                  ← short scaffold pointing at conventions (7 sections)
├── research/                  ← THE DURABLE RECORD
│   ├── claims.md              ← curated load-bearing claims; read this first
│   ├── evidence/              ← NN_<slug>.md + INDEX.md + .next-id (append-only)
│   ├── methods/               ← one <topic>.md per methodological object + _craft.md
│   ├── sources/               ← API/dataset reference docs (anchor-as-smoke-test)
│   └── wiki/                  ← OPTIONAL (r2p init --with-wiki)
├── analysis/<theme>/          ← analytical scripts
├── data/                      ← raw/<source>/ (immutable) · processed/<theme>/
├── output/<theme>/            ← charts, tables, .meta.json
├── plan/                      ← plan-<slug>/{plan,handoff,log}.md · archive/ · brainstorms/
├── deliverables/              ← memos/ (3 profiles) · decks/
└── reference/                 ← inputs we did not produce
    ├── literature/            ← papers, third-party reports (gitignored)
    ├── notes/                 ← transcripts, working notes (TRACKED — unrecoverable)
    ├── internal/              ← team-internal scoping (gitignored)
    └── external/              ← commissioned consultant reports (gitignored)
```

**Root holds these eight directories, config, and nothing else.** `_inbox/` is a
gitignored staging spot so loose files stop accumulating at the root.

Gitignored: `plan/`, `plan/brainstorms/`, `plan/_scratch/`, `reference/internal/`,
`reference/literature/`, `reference/external/`, `_inbox/`. Committed:
`research/**`, `plan/archive/`, `reference/notes/`, `deliverables/**`. `output/`
is your call (typically committed for small artifacts).

Projects carrying multiple parallel lines of inquiry may opt into a one-level
subfolder layout: `research/evidence/<theme>/NN_*.md` and `output/<theme>/NN_*`.
Flat is the default; hooks and skills accept both shapes.

#### The three research layers, and their opposite mutability rules

| Layer | What it is | Mutability |
|---|---|---|
| `research/claims.md` | the load-bearing claims a narrative rests on | **editable + deletable** — a curated view |
| `research/evidence/` | one doc per analysis, chart-backed | **append-only** — never edited or deleted |
| `research/methods/` | one file per methodological object | living, versioned in place via `## Changelog` |

Evidence preserves; claims curate. An append-only corpus is the audit trail and
has to survive being wrong — but at 150 docs it cannot be read, so the curated
layer on top is what deliverables actually cite. **`claims.md` is mandatory once
evidence passes 40 docs.** See `docs/v1-to-v2-migration.md` for the measurements
behind that number.

### Tools and skills

User-invoked skills (`/<name>` in Claude Code):

| Skill | When | What it does |
|---|---|---|
| `/brainstorming` | Before planning a methodology call | Three-phase exchange to settle a research-design decision; output → `plan/brainstorms/<topic>.md` |
| `/planning` | After brainstorm | Produces `plan/plan-<slug>/{plan.md, phases/phase-N.md}`; pairs with the `r2p plan init <slug>` CLI subcommand for scaffolding |
| `/implementation` | Executing a plan | Reads plan + handoff, works the phases, rewrites handoff at session end, drives `.completed`-driven archival |
| `/agent-teams` | Parallelizing 2+ independent units | Orchestrates teammate scope, isolation, output collection — methodology comparisons, robustness sweeps, multi-source ingest |
| `/learning-capture` | Captured a gotcha or insight | Files `research/methods/<slug>.md` + adds a row to `the `triggers:` frontmatter of the topic or source file` |
| `/verify` | Before publishing one artifact | 3–5 domain-shaped checks on a regression / chart / paragraph (≤2k tokens) |
| `/deliverable-review` | Last-mile draft of a deliverable | Forked parallel seven-lens review (≤12k tokens total) |
| `/wiki-ingest` | Adding a raw source to the wiki | Distills `research/wiki/raw/<path>` into one or more `research/wiki/` pages |
| `/wiki-lint` | After a batch of ingests | Flags orphans, contradictions, stale pages, page-budget violations |
| `/scan-sources` | Refreshing tracked sources | Re-scrapes `research/wiki/raw/registry.yaml` entries due for refetch (delegates to `web-scraping`) |
| `/r2p-migrate-source` | Importing a source from another r2p project | Transplants one source's full data layer (ref doc + wrapper + env vars + INDEX + cache entry) via `MIGRATION_PROPOSAL.md` → user approves → apply + import smoke test |
| `/research-cleanup` | Before a milestone or handoff | Project-wide orphan + intermediate proposal at `cleanup-proposal.md` (never deletes) |

Background hooks (silent unless their condition holds):

| Hook | Event | What it does |
|---|---|---|
| `check-evidence.sh` | Stop | T1: BLOCKING archival nudge when `plan/<slug>/.completed` exists. T2: silent nudge when uncommitted analysis exists without a fresh evidence doc |
| `retrieve-learnings.sh` | UserPromptSubmit | Surfaces ≤3 matched learnings as `additionalContext` when ≥2 trigger keywords appear in the prompt |
| `precompact-handoff.sh` | PreCompact | Nudges handoff refresh and prompts for session surprises worth saving as learnings |

Subagent (auto-launched):

| Agent | Trigger | What it does |
|---|---|---|
| `archivist` | Stop hook T1 emits the instruction on `.completed` | Synthesizes `plan/archive/plan-<slug>.md`, updates `plan/archive/index.md`, optionally edits `CLAUDE.md`, deletes the plan directory |

Conventions installed (long-form rules read on demand from `.claude/conventions/`):

| Convention | Purpose |
|---|---|
| `evidence` | `research/evidence/NN_<slug>.md`: frontmatter scope keys, `## Measured` vs `## Reading`, 120-char index cap, `status` supersession |
| `claims` | `research/claims.md`: the curated ledger above an append-only corpus. Mandatory past 40 evidence docs |
| `methods` | `research/methods/<topic>.md`: one file per methodological object — the rule, why-not-the-alternatives, the traps, diagnostic counts. Merges v1's `decisions` + `methods` + `learning-capture` |
| `sources` | `research/sources/<source>.md` + the runtime half (`<project>_utils.py`, `.env`/`.env.example`, `data/README.md`). Merges v1's `data-sources` + `data-access` |
| `plan-lifecycle` | brainstorm → plan → handoff → archive in one file. Merges v1's `brainstorm-format` + `plan-structure` + `handoff-format` + plan archival |
| `provenance` | Script header (Script / Inputs / Outputs / Seed / Env) + commit `Run:`/`Out:` lines. Merges v1's `script-header` + `analytical-commit-format` |
| `project-conventions` | `.claude/conventions/project/<domain>.md` flat folder + `INDEX.md` |

Optional, shipped but not promoted into `CLAUDE.md`:

| Convention | Purpose |
|---|---|
| `source-registry` | `research/wiki/raw/registry.yaml` watchlist + dedup via `seen.jsonl`. Needs `r2p init --with-wiki` |
| `research/wiki/SCHEMA.md` | Distilled-knowledge page types. Adopt only when the project's primary input is a *stream* (news, filings, bulletins), not datasets and papers |

Each convention file is the single source of truth for its rule. Pointer blocks in `templates/CLAUDE.md.template` and the README link to it; they don't duplicate prose.

Three deliverable profiles ship in `templates/deliverables/`: `country-diagnostic-memo` (4–7k words, technical-peer audience), `ministerial-briefing` (≤1.2k words / 2-page hard cap, executive audience), and `internal-research-memo` (5–12k words, working through a question). Each profile has a `PROFILE.md` (length target, register, success criteria, recommended `/deliverable-review` lens weights) and a `template.md` skeleton.

## What's in here

The framework's own internals — useful if you're proposing a new convention, hook, or skill, or auditing a behavior:

```text
.claude/
├── conventions/                       ← 13 convention files (long-form rules, on-demand reads)
├── hooks/
│   ├── check-evidence.sh              ← Stop hook: archival tripwire + evidence tripwire
│   ├── retrieve-learnings.sh          ← UserPromptSubmit: trigger-keyword learning retrieval
│   └── precompact-handoff.sh          ← PreCompact: handoff refresh nudge
├── agents/                            ← symlinked into ~/.claude/agents/ globally by `r2p init`
│   └── archivist.md                   ← per-plan archival on .completed
├── skills/                            ← symlinked into ~/.claude/skills/ globally by `r2p init`
│   ├── brainstorming/                 ← decisions-pre-planning conversation
│   ├── planning/                      ← multi-phase research plan authoring
│   ├── implementation/                ← phase-by-phase execution + handoff lifecycle
│   ├── agent-teams/                   ← parallel teammate orchestration
│   ├── learning-capture/              ← gotchas + tips, retrieval-keyed
│   ├── verify/                        ← per-artifact sanity check
│   ├── deliverable-review/            ← seven-lens forked review
│   ├── wiki-ingest/                   ← research/wiki/raw/ → research/wiki/{sources,concepts,...} distillation
│   ├── wiki-lint/                     ← orphans, contradictions, stale, budget
│   ├── research-cleanup/              ← orphan + intermediate proposal
│   ├── scan-sources/                  ← registry-driven targeted scraping
│   ├── migrate-source/                ← r2p→r2p source transplant (proposal-then-apply)
│   └── web-scraping/                  ← Playwright/httpx/BeautifulSoup toolkit (delegated to)
└── settings.template.json             ← copied to .claude/settings.json (project-shared)

docs/
├── audience-and-philosophy.md         ← design constitution (eight principles)
├── extending.md                       ← how to add new conventions/hooks
├── evidence-mechanism.md              ← rationale + tradeoffs (one per convention)
├── theme-parallel-mechanism.md
├── handoff-mechanism.md
├── plan-structure-mechanism.md
├── plan-archival-mechanism.md
├── brainstorm-mechanism.md
├── learning-capture-mechanism.md
├── wiki-architecture.md
├── verification-architecture.md
├── source-registry-mechanism.md
├── data-sources-mechanism.md
├── data-access-mechanism.md
├── migrate-source-mechanism.md
├── methods-mechanism.md
└── project-conventions-mechanism.md

templates/                              ← seeds installed by `r2p init`
├── CLAUDE.md.template                 ← short CLAUDE.md scaffold with v1.1 pointer blocks
├── research/evidence/INDEX.md                  ← empty INDEX seed
├── research/wiki/                              ← SCHEMA.md + README.md + index.md + log.md
├── research/wiki/raw/                          ← README.md + registry.yaml + seen.jsonl + scraped/
├── research/sources/                      ← INDEX.md + README.md + EXAMPLE_world_bank_api.md
├── data/README.md                     ← on-disk inventory template (data/ otherwise gitignored)
├── .env.example                       ← committed env-var contract (.env stays local)
├── research/methods/                           ← README.md + EXAMPLE_method/rule.md
├── .claude/conventions/project/               ← INDEX.md + README.md + EXAMPLE_visualization.md
├── handoff.md                         ← session-end handoff template
├── decision-record.md                 ← decision-record fillable template
├── plan/brainstorms/README.md              ← orientation for the gitignored plan/brainstorms/ directory
├── research/methods/                         ← README.md + index.yaml (empty seed)
├── plan/archive/                           ← README.md + index.md (empty rollup seed)
├── reference/internal/README.md            ← orientation for the gitignored reference/internal/ directory
├── literature/README.md               ← orientation for the gitignored literature/ directory
├── deliverables/decks/README.md                   ← orientation for the deliverables/decks/ directory
└── deliverables/                      ← three profiles, each PROFILE.md + template.md
```

Hooks are pure bash + standard Unix tools. The `r2p` CLI requires Node ≥18 (one runtime dep: `commander`); everything `r2p init` installs into a target project is plain markdown, JSON, YAML, or shell.

## Updates

Pull framework changes into an existing project:

```bash
cd /path/to/your/research-project
r2p init --upgrade
```

Scaffold a new plan directory:

```bash
r2p plan init <slug>      # creates plan/plan-<slug>/{plan.md, handoff.md, log.md, phases/, context/}
```

`r2p plan init` is idempotent — re-running on an existing slug skips files that already exist. The planning skill recommends running it before drafting `plan.md`.

For each framework convention or template seed, `--upgrade` either copies it in (if absent), silently skips it (if byte-identical), or writes a `<file>.framework-new` sidecar (if divergent — your version stays put). Review sidecars with your preferred diff tool and merge manually. `CLAUDE.md`, `research/evidence/INDEX.md`, `research/wiki/index.md`, `research/wiki/log.md`, `research/wiki/raw/registry.yaml`, `plan/archive/index.md`, and other user-curated seeds are left alone. New gitignored slots that ship with the framework (e.g. `reference/internal/`, `literature/`) are appended to your existing `.gitignore` framework block on upgrade.

### Updating `CLAUDE.md` from the template sidecar

`r2p init` and `r2p init --upgrade` both (re)write `CLAUDE_TEMPLATE.md` at your project root — a verbatim copy of the framework's current `templates/CLAUDE.md.template`. Your own `CLAUDE.md` is never overwritten. The sidecar is your **diff target**: when a framework upgrade ships new pointer sections (e.g. `## Data Access`, `## Internal Docs`, `## Literature`, `## Slides`), they show up in `CLAUDE_TEMPLATE.md` and you decide what to pull into `CLAUDE.md`.

**Workflow** — do this by hand, not by asking Claude to fetch from the framework repo:

1. **Open both files side-by-side** in your editor: `CLAUDE.md` (your live file) and `CLAUDE_TEMPLATE.md` (the framework's current shape).
2. **Compare the `##` section headers.** Anything in `CLAUDE_TEMPLATE.md` that's missing from your `CLAUDE.md` is a candidate to add. `grep -E "^## " CLAUDE.md CLAUDE_TEMPLATE.md` gives you the diff in seconds.
3. **Copy the relevant pointer blocks** verbatim from the template into your `CLAUDE.md`. Order in the template is a suggestion, not a constraint — append at the bottom or insert thematically as you prefer.
4. **Edit the copied sections to fit your project.** Drop slots you don't use, tighten language to your project's voice, swap framework examples for project-specific ones, add cross-references to your real research/methods/methods/data sources. The template is a *starting point*; `CLAUDE.md` is yours to curate.
5. **Commit.** The next `r2p init --upgrade` will refresh `CLAUDE_TEMPLATE.md` again without touching your edits, so you can repeat this loop whenever the framework ships new sections.

Asking Claude to "read the framework's `templates/CLAUDE.md.template` and update my file" round-trips through the source repo unnecessarily — the sidecar at `CLAUDE_TEMPLATE.md` is already the right diff target, local to your project.

To copy a working set of conventions from one project repo into another (without going through the framework):

```bash
cp -R /path/to/source-project/.claude/conventions/. /path/to/dest-project/.claude/conventions/
```

`cp -R` overwrites — review with `git diff` in the destination repo before committing.

Project-development backlog (v1.1+ items, open design questions) lives in `TODO.md` at the framework root.

If you also have super-claudio-code (scc) installed, both frameworks register their skills as symlinks under `~/.claude/skills/`. Last-installer-wins: running `r2p init` after `scc init` makes r2p's skills (planning, implementation, agent-teams) authoritative; vice versa makes scc's authoritative. Re-run whichever framework you want active. See `docs/skill-independence-mechanism.md` for the rationale behind vendoring rather than depending on scc.

## Design philosophy

These principles are load-bearing for anyone proposing a new convention, hook, or skill. Researchers using the framework can skip this section.

1. **Externalize conventions, hook the discipline.** Long-form rules live in `.claude/conventions/*.md` (read on demand) — not in `CLAUDE.md` (loaded every session). A small Stop hook checks state and *nudges* Claude when the discipline is being skipped. CLAUDE.md stays short.
2. **Conditional hooks, not always-fire prompts.** Every hook script must be **silent by default** and only emit `additionalContext` when the actual condition holds. Always-fire hooks pressure Claude to comply mechanically (writing trivial evidence to "satisfy the rule"), which destroys the signal.
3. **Composable, not monolithic.** Each convention is one file in `conventions/` and (optionally) one script in `hooks/`. Adopt only what your project needs.
4. **Project-shared, not user-personal.** Everything in `.claude/conventions/`, `.claude/hooks/`, and `.claude/settings.json` is committed to the research repo so collaborators (human or AI) get the same scaffolding. User-personal config stays in `.claude/settings.local.json` (gitignored).

The full eight-principle constitution (silent-by-default, conditional-not-always-fire, composable, project-shared, short CLAUDE.md, markdown-first, stakes-graded verification, open-source-from-day-one) is in `docs/audience-and-philosophy.md`. Read that before proposing a new convention or hook.
