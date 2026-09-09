---
name: agent-teams
description: (r2p) Orchestrate agent teams for independent work in a research project. Use when the user wants to parallelize analysis, robustness checks, methodology comparisons, multi-source ingest, or any research task that decomposes into 2+ independent units. Triggers on "run in parallel," "agent team," "parallelize," "do these simultaneously," or when you detect independent work units that would benefit from parallel execution. Also triggered by the implementation skill when it detects independent phases or tasks during plan execution. Don't trigger for sequential work with tight dependencies, or trivial tasks where coordination overhead exceeds benefit.
---

# Agent Teams

## When to Use

Work decomposes into 2+ independent units that can run in parallel without conflicting on the same files or depending on each other's outputs mid-execution.

Work decomposes into 2+ CONFLICTING units that the researcher and/or the lead want to evaluate against each other (deflator A vs B, identification spec X vs Y, sample-frame option 1 vs 2). Each session works on a separate worktree. The winning approach gets merged into main.

**Use agent teams when:**
- Multiple independent tasks touch different scripts or methods rules
- Methodology comparisons: 2+ valid approaches to weigh against each other
- Robustness sweeps: re-run a regression spec across 3+ alternative samples / weights / fixed-effects structures
- Multi-source ingest: 4+ raw documents to distill into `research/wiki/` pages in parallel
- Plan execution: independent phases or tasks (delegated by implementation skill)

**Don't use when:**
- Work is tightly sequential — each step depends on the previous (harmonize panel → run regression → make chart)
- A single subagent would suffice (a quick lookup, a single-artifact `/verify`, a focused review)

### Agent teams vs subagents

Agent teams are independent Claude instances, each with their own full context window and the ability to message each other. Use them for sustained parallel work where each unit needs room to think and produces significant output.

Subagents are lightweight child processes that return a summary to the parent. Use them for quick focused tasks (a `/verify` pass on one regression, a code review, a file search) where the parent consumes the result, not the user directly.

Default to **agent teams** for analysis, ingestion, and methodology comparisons. Default to **subagents** for support tasks within a session.

## Before Launching: Orchestration Step

Don't launch teammates blindly. Pause and make the decisions that determine success or failure.

### 1. Ask the user instrumental questions

Stop and ask only the questions that materially affect orchestration. Not implementation details — the structural decisions:

- **What are the independent units of work?** The user may already have a decomposition (one teammate per country, one per identification spec), or may need help identifying where the natural splits are.
- **Do any units need file isolation?** Worktrees are needed when teammates would modify overlapping files (experimental branches comparing alternative specs in the same regression script). Otherwise, shared repo with non-overlapping file ownership.
- **What does "done" look like for each unit?** A regression that converges with sign-of-coefficients holding, a chart in `output/` that re-renders byte-identical, a row count that reconciles to the methodology rule, a `research/wiki/` page with provenance citations. Each teammate needs a clear finish line.
- **For comparisons: what criteria pick the winner?** Coefficient magnitude? Sign stability across robustness checks? Sample-size preserved? Without this, you can't compare results meaningfully.
- **Are there ordering constraints?** Some units may need to finish before others can start (partial parallelism — harmonize the panel first, then split into per-country analyses).

Don't ask about how teammates should implement their work — they figure that out. Focus on scope, isolation, success criteria, and constraints.

### 2. Present an orchestration plan for approval

Share a brief plan before launching. Follow the same philosophy as the planning skill — intent and constraints, not micromanagement:

```
## Orchestration Plan

**Goal**: [One sentence — what the parallel work achieves]

**Units of work:**
1. [Teammate A]: [scope] — done when [criteria]
2. [Teammate B]: [scope] — done when [criteria]
3. [Teammate C]: [scope] — done when [criteria]

**Isolation**: [shared repo / worktrees — and why]
**Output location**: [where each teammate writes results]
**Constraints**: [what teammates should NOT do — files they shouldn't touch, approaches to avoid]
**Dependencies**: [none / which units must finish before others start]
```

Wait for user approval. Don't launch until they confirm.

### 3. Launch teammates

Each teammate receives in their launch prompt:
- Their specific scope (which scripts, which methods rule, which subsample)
- Done criteria (when they're finished)
- Constraints (what not to touch, what to avoid)
- Relevant context (`plan.md` if plan-based, or project context if standalone)
- Output location for their results
- Instructions to message the lead if they discover something that affects other teammates' work

Launch agent teams in **tmux mode** for visual monitoring of all teammates.

Teammates don't inherit the lead's conversation history — they start fresh. Give them everything they need upfront.

#### Patch the phase files as the LAST step before launching

**A parallel agent obeys its phase file, not the handoff.** Self-contained phase files are what make a fan-out safe, and the corollary is the trap: a correction stored anywhere else cannot land. On the pilot engagement, three load-bearing findings sat in `handoff.md` while all three phase files still carried the stale version — which would have produced two evidence docs conditioning a live legal schedule on an expired risk, and a session burned re-parsing a 2,758-page PDF that had already been extracted.

Before launching: inline the measured values into each phase file so nobody re-derives them, and mark corrections visibly (`⚠ CORRECTED <date>`) so a reader can tell the patch from the original. Any phase that conditions a number on an external legal or policy state gets re-checked at the top of the session that uses it — **a plan written days ago can carry a stale fact about the outside world** with nothing in the repo having changed.

#### Shared append-targets are lead-only

**Concurrent appends to a shared index are silent lost writes.** A number clash is at least visible afterwards; a lost append is not — the row simply is not there and nothing errors. The append-targets every teammate will want to touch are `research/evidence/INDEX.md`, `research/sources/INDEX.md`, `data/README.md`, and any shared utils module.

Teammates write `proposed_<thing>.md` (or a standalone function into `proposed_wrapper.py`) inside their own scratch folder; **the lead applies all of them after the fan-out.** This costs nothing and removes the entire failure class. Teammates are likewise barred from `git add`/`git commit` — see the shared-index hazard in `.claude/conventions/provenance.md`.

#### When one coordinator can see every writer, ASSIGN the evidence numbers

`evidence.md` says to claim ids from `.next-id` at write time. That rule is written for **sequential** sessions, where the only threat is a parallel plan landing a number between two sessions. With three agents writing inside the same minute, "check then write" *is* the race it was meant to prevent.

**Keep claim-at-write-time for sequential work; override it whenever a lead can see all writers.** The lead allocates a block up front (135 / 136 / 137), tells each teammate to use its number rather than derive one, and verifies uniqueness before committing. Each teammate still reports how it verified — the check is relocated to where it can be conclusive, not dropped.

#### Under stream instability, invert the work order

Teammates die to mid-stream API errors. **CSVs are durable; interpretation is not** — it exists only in agent context. Instruct teammates to work **script → CSV → evidence doc → charts → report**, on the principle that a complete doc with three stated gaps beats a perfect one never written. Two corollaries: prefer many small `Edit`s to one large `Write` (a stall mid-`Write` loses a file that was already finished), and keep tool calls bounded — the watchdog fires on **output silence**, not compute, so chaining many silent operations into one long call is what trips it.

A dead teammate is recoverable when its scripts carry the fixed-shape `provenance.md` header *plus* a comment explaining **why** (why the baseline had to be tariff-inclusive, why the chart is log-log). On the pilot engagement a fresh agent reconstructed an entire write-up from artifacts alone, without re-running anything. Two things to carry when you do that:

- **Label the reconstruction.** A recovery agent inferring intent from artifacts can miss a judgment the original never wrote down. Flag that doc in `handoff.md` as one step further from the data than its siblings.
- **Recovery can find what the original missed** — and re-running would destroy the evidence. The recovery agent noticed a script writing a CSV absent from disk and undeclared in its header, and sibling mtimes that differed, i.e. the outputs were **not** all from one run of the version on disk.

**Permissions**: Teammates need all permissions and MCP access required for their work. The lead can only grant permissions it already has. If teammates need permissions the lead lacks (specific MCP servers, tool approvals), ask the user to update `.claude/settings.json` or pre-approve before launching. Discovering missing permissions mid-execution wastes teammate context.

## How Teammates Work

### File ownership

Each teammate owns a specific set of files. No two teammates should modify the same script, methods rule, or insight in a shared repo — this causes overwrites. When scoping work, verify file sets don't overlap.

When overlap is unavoidable (methodology comparisons editing the same regression script with different specs), use worktrees. Each teammate gets an isolated copy of the repo.

### Communication

Teammates can message each other and the lead. This matters when:
- A teammate discovers something that affects another's work (a survey vintage break that invalidates the pre-2018Q3 sample for everyone, not just one teammate)
- A teammate needs a decision from the lead
- A teammate finishes and reports results

### Quality gates

Each teammate verifies their own work before reporting results: scripts run end-to-end with the same seed, diagnostic counts match the relevant `research/methods/<slug>/rule.md` rule, source citations are present, charts re-render byte-identical (or sign-and-magnitude-identical for stochastic content). The lead reviews results before consolidating.

## Output Collection

### Output location

**Plan-based execution** (launched by implementation skill):
Teammates write to `plan/plan-[name]/scratch/[task-name]/`. `scratch/`, not `output/`, because research projects use top-level `output/` for analytical artifacts (charts, tables) and a parallel-team output directory inside the plan must not collide with that. Scratch files are temporary — cleaned up when the plan is finalized and archived. The lead consolidates into the plan's `handoff.md` and updates task status.

**Standalone execution** (no plan):
Teammates write to a visible directory agreed upon in the orchestration plan. This should be somewhere the user can easily review — not hidden in `.claude/` or `scratch/`.

### Output format per teammate

**Teammates cannot write `report.md`.** The harness blocks it — subagents return findings as text, not written report files. Teammates return this block as their **final message**, and **the lead transcribes each one to disk**. Budget context for that transcription: a lead that skips it loses the reports entirely, and they are the artifact the next session reads. Data files a teammate produces (CSVs, charts, evidence docs) are written normally; it is the report that must come back as text.

```markdown
# [Teammate Name] — [Scope Summary]

## Status
[Done / Blocked / Partial]

## What was done
[Summary of completed work]

## Files modified
[List of files created or modified]

## Surprises
[Anything unexpected — omit section if none]

## What didn't work
[Approaches tried and abandoned — omit section if none]

## Ranked output
[Required when this teammate produced items competing for limited space —
findings, chart candidates, slide rows, recommendations. Ordered best-first,
with the teammate's own drop candidates named. Omit only if the output is not
a competing set.]
```

#### An unranked output is the defect, not the overflow

**When a teammate produces items that compete for limited space, it returns them
ranked and names its own drop candidates.** A teammate that returns a flat list
has not finished the work — it has moved the hardest part of the judgement to a
lead who has less context about those items than it does.

**Measured on the pilot.** A chart-budget gate reported the fan-out's output as a
global failure — "79 rows against the budget, fails by 2.5×" — and a handoff had
already written it up that way. Measured per section against the outline's own
slot counts, it was not global at all: **every sub-agent that ranked its rows came
in at or near its allocation and named its own drop candidates; the two that
emitted unranked rows produced all of the overflow.** The budget was never the
problem. Two teammates skipping the ranking step was.

**The lead sends unranked output back; it does not trim it.** Trimming looks
cheaper and is the wrong repair: the lead is choosing between items it did not
produce, so it drops on legibility rather than on merit, and the teammate's reason
for keeping a weak-looking item is lost with no record that it existed. Sending it
back costs one short round-trip and returns a ranking from the only agent that can
justify one.

This is the **producer** side of the size rule whose consumer side is *express a
size limit as a rank or a share, never an absolute count*. The two are one
mechanism: a ranked return is what makes a share expressible downstream, and an
absolute count applied to an unranked list can only ever be enforced by
truncation — which is the trimming this rule exists to prevent.

### Lead consolidation

After all teammates finish:
1. Transcribe each teammate's returned report to disk, then read them
2. **Check each competing-set output arrived ranked.** Unranked → send it back to
   that teammate. Do not trim it yourself, and do not read an aggregate overflow
   as a budget failure before checking which teammates ranked
3. Review for conflicts or contradictions between teammates
4. For comparisons: compare results against the criteria from the orchestration plan
5. Synthesize into a summary for the user
6. For plan-based work: update `plan/plan-[name]/handoff.md` with task statuses, surprises, and what didn't work — `handoff.md` is the source of truth, no sidecar status file

## Short vs Long Running Teams

### Short tasks (most cases)
Each teammate works on 1–2 focused tasks. Wait until they finish, review results. The lead decides: merge, redirect, or launch a next round. No mid-execution coordination needed — the tasks are short enough to complete and then assess.

### Long-running tasks
Teammates may work for extended periods (a per-country panel build, a multi-source ingest sweep). Teammates should message the lead when they discover something significant that might affect the broader plan.

### When a teammate discovers a plan-affecting issue

1. Teammate messages the lead describing the discovery
2. Lead assesses: does this affect other teammates' work?
3. If no: note it, let everyone continue
4. If yes: let current teammates finish their current task (don't interrupt mid-task), then stop and surface the issue to the user before launching more work

This follows the framework's iterative adaptation philosophy — when reality challenges the plan, stop, reflect, and readapt rather than pressing forward on stale assumptions.
