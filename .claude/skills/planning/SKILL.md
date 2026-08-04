---
name: planning
description: (r2p) Guide for writing implementation plans that give the executing session the right level of detail — intent and constraints, not code snippets and step-by-step instructions. Use when designing research-design plans, methodology calls, or multi-phase analyses, or when asked to plan, architect, or think through an approach. The key trigger is whether there are decisions that benefit from deliberation before execution — trade-offs to weigh, identification choices, multiple integration points, or ambiguous scope. Don't trigger for tasks with a single obvious implementation path (rename a variable, fix a typo, add a column to an existing pipeline) where reading the script makes the implementation obvious.
---

## Project identity
!`cat CLAUDE.md 2>/dev/null || echo "⚠ NO CLAUDE.md at project root — run r2p init to seed it from the framework template, or ask the user about the project first."`

**IMPORTANT: If the line above says "NO CLAUDE.md", stop and handle this before doing anything else.** Ask the user whether they want to seed it (`r2p init` does this), or to describe the project — what it studies, the current focus, what's next — so you can write `CLAUDE.md` from scratch (3-5 lines max: project name, what it studies, current focus, what's next).

# Planning

## When to Plan

Not every task needs a plan. The dividing line isn't task size — it's whether there are decisions that benefit from deliberation before execution.

**Plan when:**
- There are trade-offs with multiple valid approaches (deflators, identification strategies, sample-construction rules)
- New code connects to existing pipelines at multiple integration seams (data sources, methods, deliverables)
- The request is ambiguous and could mean very different things
- Going down the wrong path would waste significant context
- Implementation will span multiple sessions

**Skip planning when:**
- There's a single obvious implementation path
- The change follows an existing pattern mechanically (add another country to a country-loop)
- The task is a clear, scoped fix with an identified cause

A task can touch 10 files and not need a plan (mechanical transformation following a pattern). A task can touch 2 scripts and need a plan (if those scripts encode a methodology call).

## Core Principles

### Intent over Implementation

Don't include code snippets in plans — they're written against a snapshot that's stale by execution time, and the Edit tool requires reading the actual file anyway. A snippet creates two conflicting sources of truth that need reconciling, which is harder than working from intent alone.

Instead of pasting 30 lines of regression code, write: "Modify `scripts/03_regress.R` to swap the city fixed-effects spec for the matched-pairs spec defined in `research/methods/2026-05-08_identification.md`. Keep the existing diagnostic-counts block." The executing session reads `03_regress.R` and figures out the mechanical change. The snippet is at best redundant, at worst misleading.

### Constraints over Instructions

What NOT to do is as valuable as what to do. The executing session is good at figuring out implementation from intent, but it can't know about project-specific constraints without being told. "Don't break the harmonized panel produced by `02_clean.R` — downstream regressions consume it" prevents a class of mistakes that "add the new filter" doesn't.

Constraints are also more durable — they stay correct even as the codebase changes, while implementation instructions go stale.

### Decisions as Records

Things decided during brainstorming shouldn't be re-debated during execution. When a choice between approaches has been made, record it with enough context that the executing session understands why: "Use the WB GDP-deflator (not country-CPI) for cross-country wage panels — the brainstorm covered this; harmonization beats local accuracy here." This prevents re-derivation and keeps execution focused.

When a brainstorm decision graduates to a peer-reviewable methodology call, file it at `research/methods/<topic>.md` (see `.claude/conventions/methods.md`) and reference it from the plan rather than restating the contents.

### Tasks as Checkpoints

Tasks should be independently verifiable milestones, not sequential instructions. Each should have a clear done state — a script that runs end-to-end, a coefficient sign that holds, a chart that re-renders with the same seed, a row count that reconciles to a methodology rule.

**Bad** (micromanaging):
- Task 1.1: Open `scripts/01_clean.R`
- Task 1.2: Add filter for adults at line 42
- Task 1.3: Save to `data/processed/`

**Good** (checkpoints with intent):
- Task 1.1: Apply working-age filter (15–64) to the EPH harmonized panel; save to `data/processed/eph_working_age.csv`. Verify: row count matches `research/methods/working-age-filter/rule.md` diagnostic counts; no NA in the age column; commit message has Run/Out lines.

If a task can't be independently verified, it's too granular — merge it up. Good tasks create natural commit points and enable progress tracking across sessions.

## What Goes in a Plan

### Must Have
- **Constraints** — what NOT to do, project-specific boundaries ("preserve the harmonized panel schema", "don't change the deflator chain")
- **Decisions made** — choices from brainstorming with reasoning, not to be re-debated
- **File manifest** — paths + intent (what to create/modify/delete and why, not how)
- **Repo context summary** — how this plan fits in the codebase
- **Integration seams** — where new code connects to existing pipelines (data sources, methods, deliverables)
- **Verification gates per phase** — domain-shaped (sign-of-coefficients, magnitude sanity, source citation present, breakpoint alignment, row-count reconciliation), not unit tests. See `plan-structure.md` and `methods.md`'s diagnostic-counts pattern; per-artifact sanity is delegated to `/verify`.
- **Phase order + dependencies** — what depends on what

### Actively Harmful
- **Code snippets** — stale snapshot, the executing session reads the file anyway, creates conflicting sources of truth
- **Sub-step instructions** ("open file, add line, save") — duplicates the executing session's built-in capabilities
- **Predicted line numbers or file contents** — stale the moment anything changes
- **Standard operation instructions** ("run the script") — obvious, wastes context

### The Pointer Principle

A plan should be a pointer to the code, not a copy of it. "Modify `scripts/03_regress.R` to swap the city fixed-effects spec for the matched-pairs spec defined in `research/methods/2026-05-08_identification.md`" lets the executing session read `03_regress.R` with full context. Pasting 30 lines of regression code means the session reads both the plan AND the file, spending tokens reconciling them.

The test for every line: does this help the executing session do something it couldn't figure out from reading the code? If not, cut it.

## Context Budget

Context is the scarcest resource in a session. A plan that's too detailed wastes the implementer's context on redundant information (code snippets duplicating source files). A plan that's too vague wastes the implementer's context on exploration (reading scripts to figure out what the plan meant).

The sweet spot: decisions and constraints stated once clearly, file manifest pointing where to look, and clear verification gates. No duplicated information — the plan says "read X," not "here's what X contains."

For large plans, split into per-phase plan files rather than one giant document. Each phase file is independently readable. The master plan is just the phase list with dependencies and handoff points.

## Recommended Plan Structure

A well-structured plan covers these elements, adapted to the project's needs:

```
# [Title]

## Goal (1-2 sentences)
## Constraints (what NOT to do)
## Decisions Made (from brainstorming, don't re-debate)
## File Manifest (paths + intent, no code) -> saves exploration context
## Repo context summary (how this plan fits in the codebase) -> saves exploration context

## Phases
### Phase N: [Name]
- Intent: What this accomplishes
- Modifies/Adds: [files]
- Verification: [pass/fail gate — domain-shaped]
- Tasks: [checkpoints with intent]
```

Research plans naturally cross-link `research/methods/<date>_<slug>.md`, `research/methods/<slug>/rule.md`, and `research/sources/` — the structure above is a starting point, not a rigid template. Scale it to the task: a two-script change doesn't need phases; a complex methodology migration might need per-phase plan files.

## Plan Setup

Before writing, scaffold the plan directory by running `r2p plan init <slug>` (added in r2p v1.2). If that subcommand isn't available yet, scaffold the directory manually with `mkdir -p plan/plan-<slug>/{phases,context}` and create `plan.md`, `handoff.md`, `log.md`.

The scaffold creates `plan/plan-<slug>/` with `plan.md`, `handoff.md`, `log.md`, `phases/`, and `context/`.

Then write to:

- `plan.md` — the core plan document (goal, constraints, decisions, file manifest, repo context)
- `phases/phase-N.md` — per-phase files when the plan has multiple phases. Each is independently readable by its executing session.
- `context/*.md` — decision-enabling repo summaries (see below)

### Consuming brainstorming output

If a brainstorming session preceded planning, read `plan/brainstorms/<topic>.md` for decisions already made. Per `brainstorm-format.md`, every brainstorm carries a five-section handoff contract — **Problem**, **Decisions Made**, **Research Findings**, **Open Questions**, **Constraints Identified**. Lift the contents into `plan.md`:

- "Decisions Made" → `plan.md`'s `## Decisions Made` (don't re-debate)
- "Constraints Identified" → `plan.md`'s `## Constraints`
- "Open Questions" → resolve before sealing the plan, or surface as `## Open Items Deferred`
- "Research Findings" → repo-context summary or context files
- "Problem" → distilled into the goal

The brainstorming summary contains the reasoning; the plan records the conclusions.

## Context Files

When a phase touches complex systems that the implementer would otherwise spend significant context exploring, write decision-enabling context summaries in `context/`. These save 15-30% of execution context by replacing exploration with a 20-line summary.

A context file might describe how `research/sources/world_bank_api.md` interacts with the project's deflator chain, or how `research/methods/age-cohort-definition/rule.md` evolves vN-to-vN+1.

The test: would an implementer need to read 5+ files to understand this system well enough to make implementation decisions? If yes, write a context summary during planning.

Not every plan needs context files — only when the repo-context summary in `plan.md` isn't enough for a specific system.

## Multi-Session Plans

If the implementation will span multiple sessions — large file manifest, multiple integration seams, or any single phase estimated at >50% context usage — the plan needs session-aware design.

Signs a plan needs multi-session design:
- More than ~15 files to create or modify
- Multiple phases with dependencies between them
- Estimated context usage exceeding 50% for any phase
- Integration work touching more than 2-3 system boundaries

Read `references/multi-session.md` for session scoping, handoff protocols, and session boundary design before finalizing the plan structure. These concerns shape how phases are sized and ordered — they're planning decisions, not just execution details.
