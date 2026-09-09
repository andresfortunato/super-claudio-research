# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phases 4 and 5, plus a constitution amendment)
**Prior sessions:** 2026-08-05, 2026-08-17, 2026-09-09 (2b), 2026-09-09 (3)
**Last content commit:** `2e4f404` — **this handoff is committed on top of it**,
so `HEAD` is the handoff commit. (A handoff cannot name its own commit; verify
with `git log --oneline -5`.)
**Branch:** `main` · **Working tree:** clean.

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** |
| 2 | State the chain once | **done** (**D2**) |
| 2b | Graduate the Córdoba fixes | **done** (**D5**) |
| 3 | Lint the chain | **done** — 7 checks → 14 (**D6**) |
| 4 | `/cite-check` | **done 2026-09-09** — decision **A** (**D7**) |
| 5 | `/pipeline-check` | **done 2026-09-09** — decision **C** (**D8**) |
| 6 | Harden the tooling | **next — unblocked, independent of everything.** The list has grown to six |
| 7 | Docs, constitution, release | blocked on 6 only. Decision **B** answered; **scope grew** |

**All four researcher decisions are now answered.** A and the invariant 13 tier
went as recommended; **B and C went against the recommendation**, and both
reversals moved work rather than removing it — read *What the reversals cost*.

**⚠ The pilot repo is `~/research/cordoba`.** Fifth handoff carrying this.

**⚠ `phase-3.md`'s §5 lint baseline is the `⚠ CORRECTED 2026-09-09` block.**
Re-measure before diffing; a baseline against a live engagement decays in weeks.

## What landed

| Commit | What |
|---|---|
| `34b77af` | invariant 13 WARN → **FAIL**. Its WARN rationale cited another check's population |
| `703821f` | **Phase 4** — `/cite-check`, refuse-early, the `/verify` boundary |
| `c7543f5` | **constitution** — principle 7 gains a side-effect axis and four bounds |
| `2e4f404` | **Phase 5** — `/pipeline-check`, executes directly, refuses on a dirty tree |

Plus `f85425a` (D7 + phase-4 notes) and this handoff. `.scc/status/project.md`
was corrected — it had claimed `plan/` was empty for five weeks.

## What the reversals cost — read before Phase 7

**Decision C (execute directly) forced a constitution amendment**, and correctly:
principle 7 graded verification by *token* cost and every shipped tier was
read-only. That posture was never a stated principle — just a coincidence of the
first three tiers all being *review* tools. Principle 7 now carries a
side-effect axis (read-only / derived / source) and four bounds. **A future
proposal that wants to write source files does not inherit this** and revises the
document again.

*Say this accurately:* the binding table already said "or invent a new one with
reason", so the amendment **extends** principle 7 rather than reversing it.
Overstating a decision as a constitutional violation is its own kind of drift.

**Decision B (delete the mechanism docs) transferred work into Phase 7.** The
recommendation to move them to `docs/v1/` existed because
`docs/v2-case-study-cordoba.md` cites them. Deleting makes those citations
dangle — the same defect class Phase 7 is cleaning up. **Phase 7 must audit and
repoint or drop every reference in the same commit as the deletion.** A phase
that deletes 2,695 lines and leaves the citations is not done.

## The pointer inventory — bigger than D5 said, and D5 was wrong about it

D5 recorded five dangling pointers and said **`decision-records` has no v2
successor**, which is what made the sweep a convention-design question needing a
researcher call. **That is wrong.** `methods.md` line 1: *"Methods — Protocol
(v2, absorbs decision-records and learning-capture)."* The v2 conventions carry
their merge history in their own titles. All seven are plain repaths:

| Dead pointer | v2 home | Cited from |
|---|---|---|
| `script-header.md` | `provenance.md` | `docs/verification-architecture.md:53`, `docs/r2p-adopt.md` ×4 |
| `analytical-commit-format.md` | `provenance.md` | `docs/verification-architecture.md:54`, `docs/r2p-adopt.md:516` |
| `data-sources.md` | `sources.md` | **`.claude/conventions/project-conventions.md:26`**, `docs/audience-and-philosophy.md:99` |
| `data-access.md` | `sources.md` | **`templates/.env.example:7`** — installs into every project |
| `handoff-format.md` | `plan-lifecycle.md` | **`.claude/hooks/precompact-handoff.sh:36`** |
| `learning-capture.md` | `methods.md` | **`.claude/hooks/precompact-handoff.sh:40`** |
| `decision-records.md` | `methods.md` | **`.claude/conventions/project-conventions.md:179`** |

**Three of the citing files are shipped runtime surfaces**, not docs.
`precompact-handoff.sh` is the worst: it fires automatically when context fills
and tells the session to read two conventions that do not exist, in every
installed project. **It went unnoticed because a pointer to a missing file fails
silently** — the session just does not get the guidance and nothing errors.

*Second instance this plan has hit of the same shape:* **a dangling pointer is
invisible by construction**, which is why invariant 8 exists. This is that
failure one layer up, in the framework's own files, and nothing checks it.

## Surprises

**1. A tier decision rested on another check's count.** Invariant 13 shipped WARN
on "573 references"; those are invariant **14**'s population, counted before 14
existed. Its own population is zero. Now FAIL. *Re-measure before citing a number
back at a decision, including one you took yourself last session.*

**2. The first fixture was red for two unrelated reasons.** "The lint went red"
would have read as confirmation while proving nothing. **A fixture is only a test
once it is green-except-one.** Pair this with "build the broken fixture, watch it
go red" — that phrasing alone is not sufficient.

**3. A skill's precondition refused its own fixture.** `/cite-check` had
inherited `/deliverable-review`'s ≥800-word floor and turned away a *finished*
127-word memo. That floor exists because a seven-lens fan-out is expensive; a
≤2k check has no such excuse, and short is the shape of a ministerial briefing
note. **General form: copying a neighbour's precondition without its reason.**

**4. Changing a default created a way to destroy work.** Report-and-hand-over
could not overwrite anything; executing directly overwrites the artifact in
place. Hence the clean-tree **refusal** — git is the undo, and an uncommitted
artifact has none. *When a decision flips a posture, re-ask what the old posture
was silently protecting.*

**5. G9's granularity ruling implied a case nobody listed.** Compare numbers, not
bytes — so **an image-only script is a `cannot compare`, not a pass.** `##
Measured` numbers are unrecoverable from a PNG, and byte-diffing reports every
palette change. **Never report "unchanged" because a chart merely re-rendered.**

**6. Two phases reached the same rule independently.** 3.5 made inapplicable
invariants print rather than vanish; Phase 4 needed a *Not flagged* section;
Phase 5 needed *Reproduced unchanged*. Three times now: **silence reads as a
pass.** It should be written down somewhere shared — Phase 7 or the constitution.

## What didn't work

Nothing abandoned. Every error this session was caught by running rather than
reading, and all are in *Surprises*.

## Next

**Phase 6 is the only thing between here and Phase 7**, is unblocked, and is
independent of everything. **Phase 7's scope grew** (see *What the reversals
cost*) — it now owns the deletion *and* its citation audit, the seven-row pointer
sweep, and `docs/verification-architecture.md`'s side-effect axis.

**No researcher calls are outstanding.**

### Phase 6 candidates — now six, none in any task list

Ranked. The first two are new this session and both are stronger than the
pre-existing 6a remainder.

1. **A convention-pointer resolver.** One `grep` of every
   `.claude/conventions/<name>.md` reference against `ls .claude/conventions/`.
   It would have caught all seven rows above, including the hook. **Cheapest
   real defect-finder left**, and it defends a vector that is invisible by
   construction.
2. **`status: retired` under a cited claim** → **invariant 15**. Fully mechanical;
   lives in `/cite-check` only because `phase-4.md` put it there. Closes the one
   class in that skill that does not need judgement.
3. **The lint's runtime** — ~9s on the pilot, ~8.9s of it predating Phase 3. Six
   subprocesses per doc across 285 docs; one awk pass fixes it. A nine-second
   linter is an adoption risk by the same reasoning that produced the WARN tier.
4. `claims.md` says *"a claim with no ids is an assertion — delete it."* Nothing
   checks it. One `grep`.
5. A dangling `**Supersedes the reading of:** #62` is a broken link. Invariant 8
   reads only ids before the first `·`, so it does not see it. One `grep`.
6. The pre-existing 6a remainder: the duplicate-path-per-line detector and the
   `--upgrade` integration test.

**Also noted, not sized:** nothing checks `.scc/status/project.md` for staleness,
which is how it sat five weeks wrong at the top of every session.
