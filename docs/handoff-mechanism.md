# Handoff mechanism — design rationale

## The problem this solves

Applied development research engagements span months. A typical Cambodia
diagnostic might run six months of Claude Code sessions, two researchers, a
half dozen analytical phases, and a dozen hand-offs between people and
between weeks. The expensive failure mode is never "the analysis was wrong" —
it's **cold start**: someone (often you, two weeks later) sits down in front
of a half-built repo and spends the first 45 minutes paging through commits,
re-reading notebooks, and reconstructing what was about to happen next.

Multiply that 45 minutes across every resumption point in a 6-month
engagement, and the cost of *not* leaving a good handoff is measured in
weeks of throughput.

The traditional fixes don't survive contact with research:

1. **"Just read the commit log."** Commit messages are written for code
   review, not session resumption. They tell you what changed, not what was
   in flight or what didn't work.
2. **"Keep a running journal."** Append-only journals grow stale at the top.
   The reader has to filter old state to find current truth, which is exactly
   the cold-start cost we're trying to avoid.
3. **"Tell Claude to summarize."** Without a structural target, Claude
   produces a generic summary of the session that is roughly as useful as
   the commit log.

## Why scc-style (vs Pedro / vs Hugo)

Three handoff styles were considered:

- **Pedro's `quality_reports/` style.** Append-only structured QA reports per
  task, indexed by date. Strong for code review, but research handoffs need
  *one current snapshot* not a paper trail of past snapshots, and the
  paper-trail mode duplicates what git history already provides.
- **Hugo's vault-manager style.** Multi-project dashboard with WIP limits.
  Useful at the org-of-projects level (and we may borrow it later for the
  shared-engagements view), but overkill for the single-engagement handoff.
- **scc's plan-local handoff.** One `handoff.md` per plan, rewritten each
  session, with a fixed structural skeleton (status, phase table, where-we-are,
  what's-next, surprises, what-didn't-work, verification log). This is what
  we adopt.

The scc style won because the structural skeleton itself is the value. The
fixed sections force the writer to address the questions a future reader will
actually ask — and surface the gaps when they can't be answered.

## Multi-time-scale framing

A research handoff has to serve three readers at once:

- **Within-session.** You step away for an hour. The handoff just needs to
  capture "where I am in the work" tersely. Verification log can be empty —
  nothing's been verified yet.
- **Researcher↔researcher.** Your branch lands on a teammate's machine. Add
  reading order, file footprints, and any surprises that won't be obvious
  from the diff. Assume they have the framework installed but not your head.
- **Project→follow-up-years-later.** You return to a closed-out engagement.
  Restate the goal in one sentence at the top. Explain *why* a decision was
  made, not just what it was — link to `decisions/YYYY-MM-DD_*.md`. The
  surprises section is now precious historical context.

The format doesn't change between scales — the *content density* does. The
fixed skeleton gives a 2028-you a place to put the year-later context next to
the original tactical state, without redesigning the file.

## What this does NOT do

- **It does not replace `evidence-logging`.** Handoff is tactical ("where am
  I, what's next"); evidence is substantive ("what did the data teach us").
  Cross-pointing is fine; merging would dilute both.
- **It does not replace git history.** Old session state is preserved in git.
  The handoff is the *current* snapshot, not the journal.
- **It does not auto-generate.** Claude can populate the structure, but the
  human in the loop is the one who knows what counts as a "surprise" or a
  meaningful "didn't work." Auto-generated handoffs collapse into commit-log
  paraphrase.
- **It is not enforced by a Stop hook.** Researchers commit when they commit;
  pressuring a handoff at every turn-end produces noise.

## Tradeoffs accepted

- **Rewriting the whole file each session has merge-conflict surface.** Two
  researchers committing handoff edits on parallel branches will conflict.
  Mitigated by the convention being one handoff per *plan* (so each
  researcher tends to own their plan); residual conflicts are resolvable by
  preferring the most recent committer's snapshot.
- **The verification log is on the honor system.** A researcher who fakes
  verification can mark a phase ✅ without evidence. The convention can't
  prevent this; the discipline rule "no ✅ without a verification entry"
  shifts the cost of dishonesty onto the reviewer who later catches it.
- **The file gets long for late-stage plans.** A plan with 8 phases produces
  a phase table that pushes the "Where we are" section below the fold. We
  accept this — the table is a high-information unit and shrinking it costs
  more than the scroll.

## Extension points

- **Project-level handoff.** For a project running multiple plans, add
  `handoff.md` at project root linking to each active plan's handoff. The
  format is the same; the phase table becomes a plan table.
- **Per-deliverable handoff.** When `deliverables/<name>/` work spans
  multiple sessions but is too small to warrant its own plan, drop a
  `handoff.md` inside the deliverable directory. Same format.
- **No hook integration.** Earlier drafts wired a PreCompact / SessionStart-on-compact
  pair to snapshot and surface the active plan's handoff across context loss.
  Removed: the conditional discipline didn't pay for the install footprint, and
  cold-resume from a freshly-rewritten `handoff.md` works without it. Cold-resume
  protocol now: open the relevant `plan/plan-<name>/handoff.md` directly at session
  start.
