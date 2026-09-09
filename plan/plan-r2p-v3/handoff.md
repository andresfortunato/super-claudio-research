# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phase 4 + the invariant 13 call) · prior sessions
2026-08-05, 2026-08-17, 2026-09-09 (Phase 2b), 2026-09-09 (Phase 3)
**Last content commit:** `703821f` — **this handoff is committed on top of it**,
so `HEAD` is the handoff commit. (A handoff cannot name its own commit; the
convention forbids fabricating it. Verify with `git log --oneline -3`.)
**Branch:** `main` · **Working tree:** clean.

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** — 4 routes + 7 stamps, all 5 criteria verified |
| 2 | State the chain once | **done** — one shipped assumption corrected after the pilot review (**D2**) |
| 2b | Graduate the Córdoba fixes | **done** — all 5 items, all 6 criteria (**D5**) |
| 3 | Lint the chain | **done** — 9 tasks + invariant 1 recursive. 7 checks → 14 (**D6**) |
| 4 | `/cite-check` | **done 2026-09-09** — 3 tasks, 4 criteria. Decision **A** answered (**D7**) |
| 5 | `/pipeline-check` | **next — unblocked.** **needs decision C** |
| 6 | Harden the tooling | unblocked, independent of everything. **Grew by one** — see below |
| 7 | Docs, constitution, release | blocked on 5·6 · **needs decision B** |

**Answered this session:** **decision A** — `/cite-check` is its own skill; and
**invariant 13's tier** — promoted WARN → FAIL. Both as recommended, so nothing
downstream moved. **B** (Phase 7) and **C** (Phase 5) remain open, each with a
recommendation in `plan.md` and each reversible within its phase.

**⚠ The pilot repo is `~/research/cordoba`**, not `~/cordoba-growth-narrative`.
Fourth handoff carrying this. Still the thing that costs a session two failed
lookups.

**⚠ `phase-3.md`'s §5 lint baseline is the `⚠ CORRECTED 2026-09-09` block, not
the one above it.** A baseline measured against a live engagement decays in
weeks — re-measure before diffing, always.

## What landed

| Commit | What |
|---|---|
| `34b77af` | **invariant 13 → FAIL.** Its WARN rationale cited invariant 14's population; its own is zero |
| `703821f` | **Phase 4** — `.claude/skills/cite-check/SKILL.md`, refuse-early, and the `/verify` boundary |

Plus this handoff, the `log.md` **D7** entry, `phase-4.md`'s execution notes, and
a correction to `.scc/status/project.md` — which claimed **`plan/` is empty**
while this plan was five weeks into execution. It is the first thing a session
reads. **Update it when a phase lands, not when the plan does.**

## Carry into Phase 5 — read before writing `/pipeline-check`

**1. The scope-shrink that hit Phase 4 will hit Phase 5 too.** `phase-5.md` was
written when link 1 had no lint. It now has invariants 8, 9, 9b, 10, 11, 12, 13,
14. **Before implementing any check inside a skill, ask whether the lint already
answers it** — and if it does, run the lint and read its output instead. That
single question is what turned Phase 4 from a day into an afternoon.

**2. `context/cordoba-graduation.md`'s **G9** is Phase 5 input, not a task.**
Unchanged.

**3. Decision C** is *should `/pipeline-check` ever run a script, or only report
what is stale and hand over the command?* Recommendation on file:
report-and-hand-over, execute only on an explicit second confirmation.

**4. The regexes are settled and verified — reuse them, do not re-derive.**

| Thing | Form | Gotcha that cost a session |
|---|---|---|
| claim heading | `^#{2,3} C[0-9]+` | `^## C[0-9]+` matches **0** of the pilot's 48 claims |
| claim reference | `\[C[0-9]+\]` | rejects `[1]`, `[23]`, `[2024]`, `[c12]`, image alt-text |
| evidence reference | `#[0-9][0-9A-Fa-f]*`, then drop any token with a hex letter or >4 digits | `#5FA1C7` reads as id 5; `#266798` reads as id 266798 |
| `Rests on:` ids | ids **before the first `·`** only | the rest of the line is `**Supersedes the reading of:** #62` |
| `artifacts:` | YAML **block** list; optional; absent is normal | absent means "not stated", never "no charts exist" |
| renumber banner | `Renumbered <old> → <new>` and `(was #<old>)` | a `#nn` matching no file may still be live — check banners first |

## Surprises

**1. A tier decision rested on another check's count.** Invariant 13 shipped WARN
because "573 references would drown a real project". Those 573 are bare `#nn` —
invariant **14**'s population — and 14 did not exist when the call was made.
Invariant 13's own population on the pilot is **zero**. Now FAIL, and the
tier-selection header in the script carries the lesson: *a tier chosen on a
measured count is only as good as the count; re-measure before citing one back,
including one you took yourself last session.*

**2. The first fixture was red for two unrelated reasons.** Missing
`headline:`/`confidence:` and a missing `.next-id` — nothing to do with invariant
13. "The lint went red" would have read as confirmation while proving nothing.
**A fixture is only a test once it is green-except-one.** Add this next to
"build the broken fixture, watch it go red" wherever that phrasing appears; on
its own it is not sufficient.

**3. The Phase 4 fixture refused itself.** `/cite-check`'s refuse-early rule had
inherited `/deliverable-review`'s ≥800-word floor, so a *finished* 127-word memo
was turned away. That floor exists because a seven-lens fan-out is too expensive
for a stub; a ≤2k check has no such excuse, and short is exactly the shape of a
ministerial briefing note. **The general form is worth naming: copying a
neighbour skill's precondition without copying its reason.** Refuse on draft
markers, never on length.

**4. Two independent paths reached the same rule.** Phase 3's 3.5 made
inapplicable invariants print rather than vanish, because silence reads as a
pass. Phase 4 independently needed a *Not flagged* section, because without one a
reader cannot tell an exemption from a miss. Same rule from opposite directions —
some evidence it is real and not a local fix. It should probably be written down
somewhere shared before a third phase rediscovers it.

**5. The status file drifted for five weeks and nothing caught it.** `.scc/status/project.md`
said "No active plans. `plan/` is empty." CLAUDE.md designates that file as the
owner of volatile state precisely so this does not happen. **Nothing checks it** —
worth a thought in Phase 6, though it is not currently in any task list.

## What didn't work

Nothing abandoned. Both errors this session were caught by running rather than
reading, and both are in *Surprises* above.

## Next

**Phase 5 (`/pipeline-check`) is the critical path and is unblocked**, needs
**decision C**, and its scope has almost certainly shrunk the way Phase 4's did —
read *Carry into Phase 5* §1 before opening `phase-5.md`.

**Phase 6 remains the independent alternative** if you would rather keep the
critical path for a fresh session.

### Needs a researcher call — two carried forward

- **Decision B** (Phase 7) — do the stale v1 `docs/*-mechanism.md` files move to
  `docs/v1/` or get deleted? *Recommend `docs/v1/` + a README.* **Note the part
  that is a bug either way:** `.claude/conventions/project-conventions.md`, a live
  v2 convention, references conventions that no longer exist — as do
  `docs/audience-and-philosophy.md` and `docs/verification-architecture.md`.
- **Decision C** (Phase 5) — see *Carry into Phase 5* §3.
- **The stale-pointer sweep** (`log.md` **D5**). Five dangling convention
  pointers — `data-access`, `data-sources`, `decision-records`, `handoff-format`,
  `learning-capture`. **`decision-records` has no v2 successor**, so where a
  decision record lives in v2 is a convention question, not a repath. Sizes 7.3b
  up from a one-off to a class. Reproduce: `phase-2b.md` § *Found, not fixed*.

### Phase 6 candidates — the list has grown again

Now four, none in any task list, each a legitimate Phase 6 addition:

- **`status: retired` under a cited claim is mechanical** and would make a clean
  **invariant 15**. It lives in `/cite-check` only because `phase-4.md` put it
  there, and a phase does not get to grow into `lint-research.sh`. **This is the
  strongest of the four** — it closes the one class in `/cite-check` that does not
  need judgement.
- **The lint's runtime** — ~9s on the pilot, ~8.9s of it predating Phase 3. The
  per-doc loop spawns ~6 subprocesses across 285 docs; one awk pass would fix it.
  A nine-second linter is an adoption risk by exactly the reasoning that produced
  the WARN tier.
- `claims.md` says *"a claim with no ids is an assertion — delete it."* Nothing
  checks it. One `grep`.
- A dangling `**Supersedes the reading of:** #62` is a broken link. Invariant 8
  reads only the ids before the first `·`, so it does not see it. One `grep`.

Plus the pre-existing 6a remainder: the duplicate-path-per-line detector and the
`--upgrade` integration test.
