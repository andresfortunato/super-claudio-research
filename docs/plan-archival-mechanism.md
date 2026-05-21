# Plan archival mechanism — rationale

Why a `.completed` marker triggers a Stop-hook-driven archivist agent
that synthesizes `archive/plan-<slug>.md` and deletes the plan
directory — instead of leaving completed plans in place, deleting
them outright, or running an always-on background sweeper.

## The problem

Multi-session research plans accumulate. By the time a project has
shipped a country diagnostic memo plus three follow-on briefings,
the working tree might hold 8–12 plan directories — five completed
months ago, three active, four somewhere in between. Three failure
modes follow:

1. **Plan-directory clutter erodes signal-to-noise.** When `ls plan/`
   prints a dozen entries, the active plan is hard to spot. The
   `handoff.md` files all start with "## Status"; you have to read
   five before finding the one that says ACTIVE.
2. **Decisions become uninherited.** A completed plan's decisions
   live in its `plan.md` "Decisions Made" section and its `log.md`
   direction-changes. If the directory is later deleted (cleanup
   pass), those decisions vanish unless they were promoted to
   `decisions/YYYY-MM-DD_<slug>.md`. Many aren't — the bar for a
   decision record is "would defend in peer review", and most
   plan-internal calls don't clear that bar but still matter.
3. **`git log` is not a synthesis.** Reconstructing what a finished
   plan accomplished from 30 commits and a deleted directory is
   possible but expensive. A future researcher (or future-self)
   wants 100 lines of "what was built, what was decided, what was
   learned" — not a 30-commit dig.

## The mechanism

A four-step lifecycle:

1. **Researcher confirms completion.** When every phase's verification
   has passed and the user signals "we're done", `handoff.md` is
   refreshed one last time and `touch plan/plan-<slug>/.completed`
   creates the marker. The marker is intentionally explicit
   (researcher-controlled), not auto-detected from a "✅ COMPLETE"
   line in `handoff.md` (which would mis-fire on intermediate
   phase-completion summaries).
2. **Stop hook detects the marker.** On the next Stop event, the
   `check-evidence.sh` hook (Tripwire 1, before the existing evidence
   tripwire) finds `plan/plan-*/.completed`, writes a
   `.archival-triggered` sentinel inside the plan directory, and
   emits a `decision: block` JSON to stdout with `reason` text
   instructing Claude to launch the archivist subagent.
3. **Archivist runs in a fresh subagent context.** Reads `plan.md`,
   `handoff.md`, `log.md`. Synthesizes `archive/plan-<slug>.md`
   (~60–150 lines) with: What was built, Key decisions (cross-linked
   to `decisions/`), Methods landed (cross-linked to `methods/`),
   Files added or modified, Learnings (extracted from
   `handoff.md`'s "Surprises" + "What didn't work"), Metrics.
   Appends a one-line entry to `archive/index.md`. Updates
   `CLAUDE.md` if the plan introduced new conventions / skills /
   hooks / agents / scaffolding directories. Deletes
   `plan/plan-<slug>/` entirely (markers go with it). Reports back.
4. **Re-block protection.** If the archivist invocation is interrupted
   (model crash, user Ctrl-C) before plan-dir cleanup, the
   `.archival-triggered` sentinel persists. On the next Stop the
   hook sees the sentinel and skips that plan. The user re-launches
   the archivist manually, or deletes the sentinel to retry.

## Why these specific shapes

### Why `.completed` (a file), not a `handoff.md` field?

Considered: detect "Status: ✅ COMPLETE" in `handoff.md` and trigger
on that. Rejected. Problems:
- Phase-completion handoffs often write `Phase N: ✅ done` lines for
  individual phases — string-match regex would mis-fire. A more
  precise pattern is fragile (handoff format evolves).
- The trigger is a *commitment*, not a *description*. The marker
  file is a researcher act ("yes, archive this"); a status line is
  prose. Acts beat prose for triggering automation.
- File presence is the simplest possible signal — one `[[ -f ... ]]`
  test, no parsing.

### Why `.archival-triggered` sentinel?

The hook emits `decision: block + exit 2`, which tells Claude Code
to halt the Stop, surface the reason, and let Claude continue. If
Claude completes the archivist invocation, the plan directory and
both markers are deleted. But if the invocation is interrupted, the
plan directory is still there with the `.completed` marker — without
the sentinel, the next Stop would block again, causing a loop. The
sentinel breaks the loop: subsequent Stops see the sentinel and skip.

The sentinel is written *before* the block, not after — atomicity.
If the hook is killed mid-execution, the worst case is the sentinel
landed but the block didn't emit; next Stop is silent (a researcher
can manually invoke the archivist). The opposite ordering would
risk a loop.

### Why an agent, not a skill?

scc's archivist is an agent; we adopt the same shape because the
work is multi-step, file-mutating, and partially destructive:
- Read 3+ files (`plan.md`, `handoff.md`, `log.md`).
- Synthesize ~100 lines of new prose.
- Write `archive/plan-<slug>.md`.
- Append to `archive/index.md` (Edit, not Write).
- Conditionally edit `CLAUDE.md`.
- Delete an entire directory.

A skill is a *protocol* (read-this-document-then-do-X). An agent is
a *bounded delegation* (here are tools, do the work, report back).
Multi-step file ops with conditional logic and a final destructive
step is agent-shaped: the model needs Bash + Read + Write + Edit, a
clean context, and a narrow brief.

### Why a separate `archive/` directory, not `plan/<slug>/ARCHIVED.md`?

Considered: leave the plan directory in place, add `ARCHIVED.md`
inside, optionally delete other files. Rejected. Two failure modes:
- The signal-to-noise problem persists (`ls plan/` still shows the
  completed plans).
- Researchers searching the working tree for "what's the active
  plan" still need to filter ARCHIVED markers. One more rule to
  remember.

A separate `archive/` directory makes the active vs. archived
distinction load-bearing in the directory tree itself: `plan/` is
"things in progress"; `archive/` is "things finished". `ls plan/`
shows only live work.

### Why does the archivist update CLAUDE.md, not the planning skill?

CLAUDE.md is the project's session-loaded memory. When a plan adds a
new convention or skill, the pointer block in CLAUDE.md needs to
land at some point — the planning skill *plans* the addition, the
implementation *makes* the addition, and the archivist *records*
that the addition is now permanent project architecture. Putting the
update at archival time (after the plan is verified complete and
the new file is committed) avoids the failure mode where a half-
shipped plan inserts a CLAUDE.md pointer to a file that doesn't
exist yet.

The archivist's update is conservative: only update if architecture
genuinely changed. A plan that edited an existing convention's prose
or shipped seed templates does not require a CLAUDE.md edit.

## Boundary with `/research-cleanup`

The two are complementary, never overlapping:

|                          | archivist                  | `/research-cleanup`                       |
|--------------------------|----------------------------|--------------------------------------------|
| **Trigger**              | Stop hook on `.completed`  | User runs `/research-cleanup`              |
| **Scope**                | One plan directory + archive entry | Project-wide                       |
| **What it touches**      | `plan/<slug>/`, `archive/`, optionally `CLAUDE.md` | Source files, intermediates, charts, notebooks |
| **What it does**         | Synthesize + delete        | Audit + propose (never delete)              |
| **Decision authority**   | Automatic                  | Researcher reviews proposal                |

The archivist is bounded — narrow, automated, plan-scoped. It never
touches scripts, notebooks, output charts, or data files. If a
plan's execution left orphan scripts or stale intermediates in the
working tree, the archivist *recommends* the user run
`/research-cleanup` afterward; it does not attempt to scan beyond
the plan directory.

`/research-cleanup` is the inverse: project-wide and never deletes.
It documents that per-plan archival is the archivist's job and does
not propose archiving plans itself. Each side defers to the other;
no logic is duplicated. The boundary paragraphs in
`.claude/agents/archivist.md` and
`.claude/skills/research-cleanup/SKILL.md` codify this — if either
file's boundary section ever drifts, the other is wrong.

## What this is not

- **Not a backup.** The archive is a synthesis, not a copy of the
  plan directory. Reconstructing the plan from the archive plus
  `git log` is possible but lossy by design — the synthesis is
  what's worth keeping.
- **Not a deletion sweep.** The archivist deletes one plan
  directory, the one that was just completed. It does not scan for
  stale plans, abandoned plans, or plans missing markers.
- **Not auto-triggered by handoff edits.** Only the explicit
  `.completed` marker fires the hook. A researcher who refreshes
  `handoff.md` to "✅ COMPLETE" without creating the marker does
  not trigger archival — by design.
