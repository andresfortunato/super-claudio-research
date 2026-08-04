# Audience and design philosophy

This document is for two readers:

1. **Researchers evaluating research-to-policy** for their own engagement — what's the framework actually opinionated about, and is it aligned with how you want to work?
2. **Contributors extending it** — every new convention, hook, skill, or template needs to fit the constitution below. If a proposed addition violates one of these principles, it is the wrong addition (or the principle needs to be re-debated explicitly, not silently bypassed).

The framework is small on purpose. Each piece earns its place. The principles below are how we keep it that way.

## Audience

The framework targets applied development-research teams: country-diagnostic, sectoral, and policy-research workstreams that produce mixes of memos, briefings, charts, datasets, and ad-hoc analyses for ministerial / executive / peer audiences.

It assumes:

- **Multi-session, multi-week plans** — not one-shot scripts. A typical engagement runs 3–9 months and crosses dozens of Claude sessions.
- **Mixed languages** — R and Python first-class; Stata and others tolerated. The framework is markdown-first and language-neutral in the core; language specifics live inside individual scripts (called out in the script-header `Env:` line).
- **Evidence accumulation matters more than feature velocity.** The deliverable is a defensible argument, not a shipped product. What was *learned* (and what's *unsettled*) needs to survive across sessions, researchers, and years.
- **Open-source-from-day-one.** No engagement-specific content lives in committed framework files. Pilot teams (Córdoba, Cambodia) are the first users, but the framework is published for anyone doing similar work.

It does *not* target: software engineering teams (Claude Code's defaults already serve them well), one-off data exercises (overkill), or fully-academic research with a LaTeX-Beamer pipeline (deferred to v1.1+).

## The nine design principles

### 1. Silent-by-default hooks

Every hook script must be silent unless the condition it checks for actually trips. A hook that fires on every Stop, every PostToolUse — even with friendly text — degrades into noise within days. Researchers stop reading it; Claude stops adapting to it.

Concretely: `check-archival.sh` returns nothing unless a plan is marked `.completed` and not yet archived. Earlier drafts had a PostToolUse manifest hook and PreCompact/SessionStart hooks; all were removed because the install footprint exceeded their value.

v2 removed a second hook for failing this test in the worst way. `check-evidence.sh` nudged when analysis artifacts were uncommitted without an evidence doc — but its "did you already write one?" check globbed the v1 path, so once v2 moved evidence under `research/`, the condition could never be satisfied and the nudge fired *unconditionally*. **A silent-by-default hook whose silence depends on a path is one refactor away from firing every turn.** Its invariants now live in `lint-research.sh`, run manually or from CI.

If you can't make a hook silent-by-default, it probably belongs as a user-invoked skill (`/verify`, `/wiki-lint`, `/scan-sources`, `/research-cleanup`) instead.

### 2. Conditional, not always-fire

Closely related to (1) but stronger: the *trigger* must reflect actual evidence that the convention applies, not a clock or a session boundary. Always-fire prompts pressure Claude into mechanical compliance — writing a trivial evidence doc to satisfy the rule, listing two-line "decisions" that don't deserve the ceremony.

Trigger discipline: tripwires read `git status`, the filesystem, file mtimes, or specific tool calls. They never fire just because a session ended or a context boundary approached. The Stop hook for evidence checks "are there uncommitted analytical artifacts AND no new evidence doc staged?" — both halves matter.

### 3. Composable, not monolithic

Every convention is one file in `.claude/conventions/` (the protocol) plus optionally one file in `.claude/hooks/` (the nudge) plus one file in `docs/` (the rationale). Skills are one directory under `.claude/skills/<name>/` with a single `SKILL.md`. Profiles are one directory under `templates/deliverables/<name>/` with `PROFILE.md` + `template.md`.

A project adopts pieces selectively. If the team doesn't write decision records, they don't install `decision-records.md` and the rest works fine. There is no orchestrator coordinating between conventions, and there is deliberately no cross-skill router (the Imbad mode-registry pattern is deferred until skill count exceeds ~8).

When proposing a new convention, ask: can this be one file in `.claude/conventions/`? If it requires touching three other conventions to integrate, the design is wrong.

### 4. Project-shared, not user-personal

Everything in `.claude/conventions/`, `.claude/hooks/`, `.claude/skills/`, `.claude/agents/`, and `.claude/settings.json` is committed to the research repo so every collaborator (human or AI, on any machine) gets the same scaffolding. User-personal customization stays in `.claude/settings.local.json` (gitignored).

This is the inverse of the Claude Code default, where most config lives in `~/.claude/`. The research repo is the unit of collaboration, so the harness moves with the repo. Same argument as for the script-header convention: future-you, your handoff partner, and the auditor years later all need to see the same thing.

### 5. Short CLAUDE.md, with pointers

CLAUDE.md is loaded into every session. Long-form rules in CLAUDE.md cost tokens forever and crowd out the project-specific framing that matters more (data sources, key frameworks, current focus). So CLAUDE.md stays around 80–120 lines: project overview, key frameworks, codebase structure, data sources, and one ~4-line pointer block per installed convention.

The pointer block names the convention, says when it applies, and points at `.claude/conventions/<name>.md` for the protocol. Claude reads the full protocol on demand when the situation matches the trigger. This pattern is the single biggest token-cost lever in the framework.

The ten pointer blocks shipped in v1: Evidence Logging, Wiki, Script Headers, Analytical Commit Format, Handoff Format, Plan Structure, Decision Records, Methods, Source Registry, Data Sources.

### 6. Markdown-first, language-neutral core

The framework's substrate is markdown — convention docs, wiki pages, evidence, handoffs, decision records, deliverable templates. Claude reads markdown natively, researchers can edit markdown in any tool (VS Code, Obsidian, plain text), and markdown survives format migrations.

Language-specific concerns (R vs. Python vs. Stata) live inside scripts and surface in the script-header `Env:` line. Every hook is pure bash + standard Unix tools — no external dependencies. Adding a new analytical language is mostly a script-header convention update; no framework rewrite needed.

LaTeX/Beamer add-ons are deferred to v1.1+ (Pedro / Hugo Sant'Anna patterns), and only as opt-in extensions — never as the default deliverable substrate.

### 7. Stakes-graded verification, no always-fire reviews

Verification is tiered by cost and by who triggers it:

- **Provenance substrate (zero install cost, researcher discipline).** `script-header` and `analytical-commit-format` conventions turn `git log` into the audit trail. No hook, no separate log; `git log -- output/<file>` resolves to a commit, the message names the script, the script's header documents the run.
- **`/verify` (≤2k tokens, user-invoked).** Per-artifact: one regression, one chart, one paragraph. Sign-of-coefficients, magnitudes, missingness, source citation, provenance. Run when you're about to publish or hand off.
- **`/deliverable-review` (≤12k tokens, user-invoked, forked parallel).** Seven lenses (data validity, identification/reasoning, robustness, framing, audience-fit, political-economy realism, peer-Lab plausibility), each in a separate sub-context. Run only on advanced deliverable drafts — last-mile, not exploratory.

There is deliberately no always-fire review. Always-fire reviews train Claude (and researchers) to discount review output as background noise. Reserve the heavy machinery for moments where it matters.

Why no automatic per-run audit log: an earlier draft shipped a `manifest.jsonl` PostToolUse hook with timestamp / script / inputs / outputs / output_sha256 / seed / env_hash / git_sha. Removed in favor of the conventions above because git + a script header gives ~80% of the value at zero install cost; the 20% delta (auto-discipline, env_hash without a lockfile, seedless-run surfacing) didn't pay for the JSONL substrate, the `jq` dependency, and the hook itself.

### 8. Open-source from day one

Every committed framework file is generic. Pilot-specific configuration (registry entries, deliverable text, brand assets) lives in the *target* project, not in this repo. The two pilots (Córdoba, Cambodia) are proving ground, not content sources.

This rules out: hardcoded country names in conventions, engagement-specific rules in skills, brand-styled chart templates in `templates/`. It admits: generic profiles that any country diagnostic could use, registry templates with commented examples, philosophy docs (this one) framed for outside readers.

### 9. Verifiable freshness anchors

Reference documentation about external systems — APIs, codebooks, project-internal methodology rules — accumulates stale claims silently. An endpoint still returns 200, but the response shape shifted. A cohort rule still runs, but the codes underlying it changed and the diagnostic counts no longer match. A `Status: verified 2025-06-12` line by itself rots: a future reader cannot tell whether the claim is still true.

The discipline is to pair every freshness timestamp with at least one **headline anchor** — a concrete value or count produced by the documented procedure. "As of 2026-05-04, the IMF DIP query for KHM 2009 inward FDI from China returns $1.113B." "Under v2 of the electronics-entrant rule, the narrow cohort has 49 entrants, with class breakdown sustainer 39 / faller 6 / plateauer 2 / pending 2." Anchors turn a date stamp into a re-runnable smoke test: future-Claude (or future-you) can re-fetch the value, and any drift surfaces immediately.

Where this binds in v1:

- **`data_sources/<source>_<thing>.md`** — every doc carries a `Status: verified <YYYY-MM-DD>` line plus at least one anchor (a country-year-indicator triple is ideal). See `.claude/conventions/data-sources.md`.
- **`methods/<method>/rule.md`** — the diagnostic-counts block IS the anchor; bumping a rule from vN to vN+1 requires re-running the implementing script and updating the counts. See `.claude/conventions/methods.md`.

Future ref-doc conventions whose claims age out should adopt the same pattern. The cost is a few minutes per verification; the payoff is an audit trail future readers can cheaply re-confirm. If a source genuinely has no point-in-time anchor (intraday market feeds, frequently-revised series), the escape hatch is a *structural* anchor — "the response object has these top-level keys"; "the codelist contains 20 codes" — weaker but better than a bare timestamp.

## How the principles bind future additions

Before proposing a new convention, hook, skill, or template, run it past the constitution:

| Principle | Question to ask |
|---|---|
| Silent-by-default | If this is a hook, does it fire only on real evidence? Or does it nag? |
| Conditional | Is the trigger an actual filesystem / git / tool-call check, or just a clock? |
| Composable | Can it be one file (or one dir) without touching others? |
| Project-shared | Is anything in here user-personal that should be in `settings.local.json`? |
| Short CLAUDE.md | Does the pointer block stay ≤4 lines? Does the protocol stay ≤120 lines? |
| Markdown-first | Does it work without a specific language toolchain? |
| Stakes-graded | Does it fit the cost tier (zero / ≤2k / ≤12k tokens)? Or invent a new one with reason? |
| Open-source | Is anything here engagement-specific? |
| Verifiable freshness | If this convention adds a ref doc whose claims age out, does it carry a `Status` date paired with a re-runnable headline anchor? |

If a proposal fails one of these and the failure is intentional, the constitution gets revised first — explicitly, in this document — before the addition lands. That's the only way the framework stays small over time.

## What this framework is *not*

A few things deliberately omitted in v1, with the reasoning:

- **No multi-deliverable orchestration.** Coordination patterns between memo / briefing / dashboard will emerge from real pilot use; designing them up front would over-fit.
- **No project-management dashboard.** WIP-limits, multi-engagement views, and Hugo-style vault managers are deferred — useful for researchers juggling 3+ countries, premature for the pilot.
- **No agent-of-agents.** Forked parallel review (`/deliverable-review`) spawns subagents in fixed shape; there is no general-purpose agent orchestrator. The framework is composable building blocks, not a workflow engine.
- **No always-on quality gates.** No CI for "did you run `/verify`?" or "did you update the wiki?" — those would invite mechanical compliance. The discipline lives in the user-invoked skills and the silent-conditional hooks.
- **No LLM-managed source-of-truth code.** `wiki/` is LLM-owned but `wiki/raw/` is immutable; the source-registry is YAML edited by humans (Claude only updates `last_scraped`). Script headers are written by humans (or by Claude, but always inspectable in the script). Trust boundaries are explicit.

## Cross-references

- The protocol files: `.claude/conventions/*.md`
- The mechanism docs (per-convention rationale): `docs/*-mechanism.md`, `docs/wiki-architecture.md`, `docs/verification-architecture.md`
- The extension guide (concrete steps to add a convention): `docs/extending.md`
- The build plan that produced v1: `plan/plan-v1-framework/plan.md` (in the framework repo; gitignored in target projects)
