# Evidence mechanism — design rationale

## The problem this solves

Research sessions produce a lot of artifacts — charts, panel CSVs, methods notes, derived tables. By default, Claude Code (and most AI coding agents) **report what they did** in their reply text and move on. The artifacts pile up; what was *learned* from them gets buried in the conversation, then lost when the session ends.

The traditional fix — "tell Claude to summarize at the end of every session" — has two failure modes:
1. **In CLAUDE.md**: a long protocol loads every turn (40+ lines), even on sessions that don't need it. Context bloat.
2. **As an always-fire reminder**: Claude is pressured to write something at every stop, so it writes trivial summaries to "comply" with the rule. Signal collapses.

The evidence mechanism is engineered to avoid both.

## Three pieces

### 1. The convention file (`.claude/conventions/evidence-logging.md`)

Defines what counts as an evidence-bearing finding, the file structure, the numbering protocol, and the discipline (one commit, never overwrite). Lives outside CLAUDE.md and is read **only when Claude is actually writing an evidence doc**. Cost: zero context tokens on sessions that don't trigger it.

### 2. The CLAUDE.md pointer (~4 lines)

Just enough to make Claude aware the convention exists and where to look:
```
## Evidence Logging
After any substantive data analysis: write evidence/NN_<slug>.md and update
evidence/INDEX.md. Full protocol: .claude/conventions/evidence-logging.md
(read on demand). A Stop hook nudges if artifacts were produced without an
evidence doc.
```

### 3. The Stop hook (`.claude/hooks/check-evidence.sh`)

The discipline-enforcer. Runs at every turn-end. **Silent by default.** Emits `additionalContext` only when both conditions hold:

```
Tripwire 1: Uncommitted analysis artifacts present
   git status -u | grep -E 'output/0[0-9][a-z]?_*.(png|csv|meta\.json)|methods/.*\.md'

AND

Tripwire 2: No new evidence/*.md in git status
   git status -u | grep -E 'evidence/[0-9]+_.*\.md'  ← must be empty
```

When both fire, the hook returns JSON with a one-shot reminder pointing at the convention file. When either fails, the hook exits 0 silently.

## Why these specific tripwires

- **Notebook-prefixed artifacts** (`output/0[0-9][a-z]?_*`) is the right granularity for "real analysis" because the project naming convention attaches a notebook number to every chart-registry artifact. PNGs without a number prefix (presentations, ad-hoc explorations) don't trigger.
- **`methods/*.md`** catches the case where a methodology note is written without a corresponding evidence doc.
- **Uncommitted state** (`git status` not git log) means the hook fires on the working session, not on past commits. Once analysis + evidence are committed together, the hook stays silent for unrelated future sessions.

## What this does NOT do

- **Doesn't enforce quality.** The hook can detect that an evidence doc is missing; it can't detect that the evidence is weak. Quality is still on the human + AI to maintain.
- **Doesn't auto-write the doc.** The hook nudges; Claude writes. This is intentional — auto-generated findings are exactly the trivial summaries we're trying to avoid.
- **Doesn't fire on research/exploration sessions.** If Claude reads files, runs ad-hoc queries, and produces nothing in `output/0*` or `methods/`, the hook stays silent.

## Tradeoffs accepted

- **Pattern coupling to naming convention.** The framework assumes notebook-prefixed `output/0[0-9][a-z]?_*` filenames. Projects with different conventions need to edit the regex in `check-evidence.sh`. This is the cost of detection precision.
- **Mid-analysis nudges.** The hook fires after every turn that satisfies the conditions, not only at "end of session." A multi-turn analysis session will see the nudge multiple times until evidence is written. Trade: some extra prompts in exchange for a real "did you do this?" check at every checkpoint.
- **No fallback when git is unavailable.** The hook silently exits in non-git directories. For non-git research projects, the hook is inert.

## Extension points

- **Tighten the trigger**: edit the analysis-hit regex in `check-evidence.sh` to match your project's artifact naming.
- **Add tripwires**: e.g. fire on new files in `regressions/` or `tables/` for projects that organize artifacts differently.
- **Loosen the snooze**: append `[ -f .evidence-skip ] && exit 0` near the top so users can `touch .evidence-skip` to silence the hook for a session.
- **Hard block** (not recommended for most cases): change the JSON output to include `"decision": "block"` to force continuation. Use sparingly — adds friction.

## Provenance

This mechanism originated in a Cambodia growth-diagnostics project where multi-phase analysis kept producing charts faster than findings were being distilled. After 7 phases, the team realized the most useful artifact across plans was a *project-level evidence index* — and the only way to keep it populated was to make "writing the evidence" a turn-stop concern, not a session-end concern. The folder was originally called `insights/` — renamed to `evidence/` to make the contrast with `learnings/` (operational gotchas) explicit.

---

## v2 addendum — why an append-only corpus needs a curated layer

v1 got the append-only rule right and stopped there. The rule is correct: an
evidence corpus is an audit trail and has to survive being wrong, so nothing in
it is edited or deleted. The consequence v1 did not anticipate is that the
corpus is therefore **monotonic** — it only grows, and nothing in it distills.

At 151 docs on the pilot engagement, with 122 of them cited directly from memos
and decks, that produced three failures at once:

1. **No triage surface.** `INDEX.md` grew to 330 KB because the "Title" column
   absorbed findings, caveats and retraction banners — median 1,554 chars,
   longest 10,410. It cost ~80k tokens to read and returned undifferentiated
   prose.
2. **No stable citation target.** Deliverables cited 122 evidence ids directly,
   so every evidence revision threatened every deliverable.
3. **A distillation rebuilt from scratch every session**, differently each time.

`research/claims.md` is that distillation, written down once, with the opposite
mutability rule from the layer beneath it: **evidence preserves, claims curate.**
Deleting a claim is cheap and correct; deleting an evidence doc destroys the
record. One indirection — deliverables → claims → evidence — means a retired
evidence leg updates one claim and its consumers keep working.

The threshold is **40 evidence docs**. Below that the capped index is still a
usable triage surface and the ledger is overhead.

See `docs/v1-to-v2-migration.md` for the four evidence defects v2 fixes and the
calibration table.
