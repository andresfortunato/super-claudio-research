# A parallel agent obeys its phase file, not the handoff — so patch the phase files as the LAST step before a fan-out, and route every shared append-target through the lead

**Discovered:** 2026-07-29, running Phases 2, 3 and 4 of `plan-agri-potential`
concurrently via `agent-teams`. Five distinct failure modes, four of them caught
before launch and one only mitigated afterwards. All three agents still produced a
complete evidence doc, which is the outcome these rules bought.

## 1. Corrections stored in a handoff cannot reach a parallel agent

`plan.md` deliberately made the phase files **self-contained**, and said so — that
self-containment is what makes a fan-out safe. The corollary is the trap:
**self-containment also means a correction stored anywhere else cannot land.**

Phase 0b had recorded three findings in `handoff.md` in prose. Three of them were
load-bearing and all three phase files still carried the stale version:

| Stale premise in the phase file | Reality | What it would have produced |
|---|---|---|
| Phases 2 and 3: "flag the agreement's not-yet-in-force status" | iTA provisionally applied **1 May 2026** | Two evidence docs conditioning a live legal schedule on a risk that had expired |
| Phase 2 block D.3: "use the monthly import data from Phase 0 source 12" | **Deferred; does not exist** | A session burned on endpoint discovery for a leg that already had a written fallback |
| Phase 3: "take the TRQ from the official agreement annex" | **Already extracted** | Re-parsing a 67 MB / 2,758-page PDF |

**Rule: patch the phase files as the last step before launching, never the handoff
alone.** Inline the measured values so nobody re-derives them, and mark corrections
visibly (`⚠ CORRECTED <date>`) so a reader can tell the patch from the original.

The general form, which is not specific to agents: **a plan written days ago can
carry a stale fact about the outside world**, and "not yet in force" is exactly the
kind of claim that flips with nothing in the repo changing. Any phase that conditions
a number on an external legal or policy state should be re-checked at the top of the
session that uses it.

## 2. Concurrent appends to a shared index are SILENT lost writes

`plan.md`'s hazard list anticipated evidence-**number** collision but not
evidence-**file** collision. Four files are append-targets that every agent in this
repo will want to touch:

- `research/evidence/INDEX.md`
- `research/sources/INDEX.md`
- `data/README.md`
- `cordoba_utils.py`

A number clash is at least visible afterwards. **A lost append is not** — the row
simply is not there, and nothing errors. **Rule: shared append-targets are
lead-only.** Teammates write `proposed_<thing>.md` (or a standalone function into
`proposed_wrapper.py`) inside their own output folder; the lead applies all of them
after the fan-out. This cost nothing and removed the entire failure class.

## 3. When one coordinator can see every writer, ASSIGN the numbers

`plan.md` said to claim evidence numbers from disk at write time, never in advance —
written for **sequential** sessions, where the only threat is a *parallel plan*
landing a number between two sessions. With three agents writing within the same
minute, "check then write" is **itself** the race it was meant to prevent.

**Rule: keep the claim-from-disk rule for sequential work; override it whenever a
lead can see all writers.** The lead assigned 135 / 136 / 137, told each agent to use
its number rather than derive one, and verified uniqueness before committing. Each
agent still reported how it had verified, so the check was not lost — just relocated
to where it could actually be conclusive.

## 4. Under stream instability, invert the work order: evidence doc first, charts last

All three agents died at least once to mid-stream API errors. **CSVs are durable;
interpretation is not** — it exists only in agent context. After the first stall
every agent was redirected to: **script → CSV → evidence doc → charts → report**,
with the instruction that a complete doc with three stated gaps beats a perfect one
never written. Also: prefer many small `Edit`s to one large `Write` (a stall
mid-`Write` loses a file that was already finished), and keep tool calls bounded —
the watchdog fires on **output silence**, not compute, so chaining many silent
operations into one long call is what trips it.

## 5. Script headers that explain WHY are what make a dead agent recoverable

Phase 4's agent died with its transcript **unrecoverable** — no context, no evidence
doc, no report. It was still fully recoverable, because its six scripts carried the
project's fixed-shape header *and* an extended comment explaining the reasoning (why
the maize baseline had to be tariff-inclusive, why the METS chart is log-log). A
fresh agent reconstructed the entire write-up from artifacts without re-running
anything.

**A header that records intent survives the agent that wrote it.** That is the
durability argument for the convention, stated more sharply than a style guide can.
Two caveats worth carrying:

- **Label the reconstruction.** A recovery agent inferring intent from artifacts can
  miss a judgment the original never wrote down, so #137 is explicitly flagged in
  `handoff.md` as one step further from the data than #135 and #136.
- **Recovery can find things the original missed.** The recovery agent noticed that
  `41_*.py` writes a CSV absent from disk and undeclared in its header, and that
  sibling mtimes differ — i.e. the outputs were **not** all from one run of the
  version on disk. A re-run would have silently destroyed the evidence of that.

## 6. Teammates cannot write `report.md`

The harness blocks it ("subagents should return findings as text, not write report
files"). All three returned their reports as a final message and **the lead
transcribed all three to disk**. Budget for this: a lead that does not persist them
loses the reports entirely, and they are the artifact the next session reads.

## Related

- `plan/plan-agri-potential/log.md` — Decisions 1, 4 and 5 (the fan-out call, the
  numbering override, the recovery-not-rerun call).
- `plan/plan-agri-potential/handoff.md` — "What didn't work".
- [[concurrent-sessions-same-worktree-steal-staged-files]] — the other concurrency
  hazard in this repo, and the reason teammates were barred from `git add/commit`.
- [[empty-result-can-mean-malformed-query-run-a-control]] — same shape as §2: a
  failure that returns a plausible-looking nothing instead of an error.
