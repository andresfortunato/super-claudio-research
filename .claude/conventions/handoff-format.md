# Handoff Format — Protocol

**Trigger**: End of any working session that touched a `plan/plan-<name>/`,
or any moment the cold-start cost of "what was I doing?" is about to be paid by
a future reader (you-tomorrow, a teammate, or you-in-2028 reopening the
engagement).

## Where the handoff lives

- One handoff per active plan: `plan/plan-<name>/handoff.md`.
- For projects with no formal plan, put it at `handoff.md` at project root.
- The handoff is **rewritten in place every session** — not append-only. A new
  reader should never have to scroll past stale state to find current state.
- History is preserved in git, not in the file. If a direction change matters,
  record it once in `plan/plan-<name>/log.md` (see `plan-structure`).

## Required structure

```markdown
# Handoff: <plan-name or project>

**Status:** <ACTIVE — Phase N complete | PAUSED — reason | CLOSED — date>
**Date:** YYYY-MM-DD
**Last commit on plan branch:** `<sha>` — "<commit subject>"

## Phase status

| Phase | Title | Status | Notes |
|---|---|---|---|
| 1 | <title> | ✅ done / 🔄 in progress / ⏭ next / ⛔ blocked | <one-line> |

## Where we are

<2-6 sentences. What landed this session. What state the repo is in.
Concrete enough that a reader can `git checkout` and orient in one minute.>

## What's next

<1-3 next moves, ordered. Reading order if non-obvious. Which files matter,
which to ignore. Parallelizable items called out.>

## Surprises

<Things you learned this session that the next reader should not have to
rediscover. Constraints that turned out to be load-bearing. Tools that don't
work the way the docs imply. Empty if truly nothing surprising — don't pad.>

## What didn't work

<Dead-ends, abandoned approaches, false starts. Save the next reader from
re-running the same experiment. Empty is acceptable.>

## Verification log

<One bullet per check actually run this session, with the command and the
expected outcome. This is the evidence that "done" is really done.>
```

## Time-scale discipline

A handoff has to serve three readers at once. Tune the content, not the format.

- **Within-session (Stop hook fires; you'll resume in 10 minutes).**
  Terse. "Phase 3 mid-flight, source-registry skill drafted, smoke-test pending."
  The verification log can be empty if nothing's been verified yet.
- **Researcher↔researcher (your branch lands on a teammate's machine).**
  Add the reading order, the file footprint, and any surprises. Assume
  they have the framework but not your head.
- **Project→follow-up-years-later (you reopen Cambodia in 2028).**
  Context-rich. Restate the goal in one sentence. Explain *why* the last
  decision was made, not just what it was. Link to the relevant
  `decisions/YYYY-MM-DD_*.md` files.

## Discipline rules

- **Rewrite, don't append.** Every session, the handoff is replaced in place.
  The reader's eye should land on current truth without filtering.
- **Commit the handoff with the work it describes.** A commit that ships
  Phase N's code without updating `handoff.md` is incomplete — the next reader
  will think Phase N-1 is still active.
- **Never mark a phase ✅ without a verification-log entry.** "Done" without
  evidence is a guess. The verification log is the audit trail.
- **One handoff per plan, not per session.** Sessions are ephemeral; the
  handoff persists across them. Old session state is in git history.
- **No fabricated commit hashes.** If you haven't committed yet, write `(uncommitted)`
  in `last commit on plan branch` and resolve the field at commit time.
- **Distinct from evidence.** Handoff is tactical ("where am I, what's next");
  evidence (`.claude/conventions/evidence-logging.md`) are substantive
  ("what did the data teach us"). Don't merge them.

## Closing out

When a plan finishes, set Status to `CLOSED — YYYY-MM-DD`, leave the file in
place, and reference it from any successor plan's `plan.md`. A closed handoff
is the cheapest cold-start aid for a future return.
