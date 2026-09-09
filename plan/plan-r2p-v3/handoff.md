# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phase 6, all six items, at the researcher's call)
**Prior sessions:** 2026-08-05, 2026-08-17, 2026-09-09 (2b), 2026-09-09 (3),
2026-09-09 (4+5)
**Last content commit:** `d195621` — **this handoff is committed on top of it**,
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
| 4 | `/cite-check` | **done** — decision **A** (**D7**) |
| 5 | `/pipeline-check` | **done** — decision **C** (**D8**) |
| 6 | Harden the tooling | **done 2026-09-09** — all six items (**D9**) |
| 7 | Docs, constitution, release | **the only phase left.** Unblocked |

**No researcher calls are outstanding.** Two were taken this session, both
before any code: scope (all six candidates, not the top five) and invariant 15's
tier (split by citing surface, with the runtime rows fixed now).

**⚠ The pilot repo is `~/research/cordoba`.** Sixth handoff carrying this. It is
a *mixed* v1/v2 install — it still has `check-evidence.sh` wired and firing, and
`.claude/conventions/data-access.md` on disk — which is why it is a good donor
for lint work and a bad one for "what a clean v2 project looks like".

**⚠ Do not carry a phase's new scope in this file again.** The last handoff
listed five Phase 6 candidates that were in no task list, and `phase-6.md`'s own
header says corrections and additions are patched *there*, because that is the
file a worker on the phase reads. Those five are now recorded in `phase-6.md` as
6e–6i. This handoff points; it does not own.

## What landed

| Commit | What |
|---|---|
| `6a0086d` | **6e** — lint reads the corpus once. 11.0s → 2.0s, output byte-identical |
| `411ec33` | **6f** — invariant 15, every `.claude/**` / `docs/**` pointer, + 6 files fixed |
| `fe96465` | **6g/h/i** — invariants 16, 17, 18 on the claims ledger |
| `89d6ba0` | invariants 4 and 5 each own one defect (11 false reports gone) |
| `41a68d9` | **6a** — linkcheck `--baseline` + collapse detector; a third live instance |
| `ddd74ae` | **6b** — merge prints its heading tree; stops truncating its report |
| `3e20032` | **6c** — migrate-source repathed to v2; smoke test redesigned |
| `d195621` | **6d** — `test/upgrade-integration.sh` + the orphaned-hook warning |

Plus this handoff, which also carries `log.md` D9, `phase-6.md`'s outcomes, and
`TODO.md`.

## Where the numbers are now

| | Session start | Now |
|---|---|---|
| lint checks | 14 | **18** |
| lint runtime, pilot (285 docs) | **11.0s** (recorded as ~9s) | **2.26s** |
| lint verdict, this repo | PASS | PASS, 1 warning |
| lint verdict, pilot | FAIL, 3 warnings | FAIL, 5 warnings |
| `--upgrade` test coverage | none | 21 assertions, `npm test` |

The pilot gained findings because the new checks found real defects there, not
because anything regressed. **Re-measure before diffing** — a baseline against a
live engagement decays in weeks. `phase-3.md` §5's baseline is now two
generations old; the numbers above supersede it.

## Phase 7 — everything it now owns

Its scope grew twice: once when decisions B and C went against their
recommendations, and once from what Phase 6 found.

1. **Delete the 14 `docs/*-mechanism.md` files (decision B) — and repoint or drop
   every citation in the same commit.** A phase that deletes 2,695 lines and
   leaves the citations is not done. **This is now checkable rather than
   hand-built:** invariant 15 reports exactly those pointers, so the sweep has a
   green condition.
2. **The 24 WARN-tier doc pointers.** Run `bash .claude/hooks/lint-research.sh`
   and read the list. Six live in `plan/` and are *correct* — a plan file quoting
   a dead convention while describing the defect. **They need no exemption:**
   when the plan completes it moves to `archive/`, which is exempt, so the noise
   is self-clearing.
3. **`docs/verification-architecture.md` gains principle 7's side-effect axis**
   (from decision C, `c7543f5`).
4. **Promote invariant 15's WARN tier to FAIL** once (1) and (2) land. Green
   becomes reachable at that point, which is the script's own stated condition
   for choosing FAIL.
5. **`templates/research/sources/EXAMPLE_world_bank_api.md`** has v2 frontmatter
   and v1 section headings, so the framework's worked example fails its own
   required shape. Phase 6 left it deliberately: reshaping it is editorial work
   about the World Bank API rather than a repath. `research/sources/INDEX.md` now
   warns readers to follow the list and not the example.
6. **`package.json` is still `0.2.0`.** Decision 5 says v3 = `0.3.0`, with the
   release notes, not opportunistically. Since that decision was written, v3 has
   also added four lint checks, a CLI subcommand, two skills and a test.
7. **Write down "silence reads as a pass" somewhere shared.** Four phases have
   now reached it independently — 3.5 (inapplicable invariants print), Phase 4
   (*Not flagged*), Phase 5 (*Reproduced unchanged*), Phase 6 (`noted` in
   linkcheck, and `--` lines in the lint). Four times is a principle, not a
   coincidence.

## Surprises

**1. Every new mechanism found a live defect on its first run, except the one
that was made to fail first.** Invariant 15 found 5 runtime-surface pointers,
then 4 more once widened, then 2 whole classes invisible in this repo. The
duplicate-path detector found a **third** collapse instance in `README.md:24`,
live since v2, that the two-instance history did not know about. The heading-tree
audit found a defect shape its own two rules missed. **The `--upgrade` test found
nothing — and it is the only one whose green run means anything, because it was
shown red four separate ways first.** The other four had live defects to find, so
their red was free.

**2. A hand-built inventory of invisible defects is itself incomplete — twice
over.** D5 said five pointers; the last handoff said seven; resolving them all
found ten here and seven in the pilot, and the two sets of seven were not the
same seven. *This was already the stated thesis and it still took a third pass to
act on. When the argument for a check is "the defect is invisible", stop
enumerating and write the check.*

**3. Widening what a check looks for was nearly free; widening what it reads was
a mistake.** Broadening invariant 15's target pattern from `conventions/` to all
`.claude/**` + `docs/**` found 4 more real defects. Broadening its *citing* set
to the whole tree produced 22 pilot findings that were mostly the researcher's
own prose. **A check's precision lives in which files it reads, not in what it
looks for.**

**4. In three of four cases the dangling pointer was not the defect.** It was a
thread attached to a live v1 instruction underneath — `precompact-handoff.sh`
routing learnings to a directory `retrieve-learnings.sh` does not read, a skill
demanding an `index.yaml` its own heading says does not exist. **Repathing only
the pointer produces the half-repathed state `phase-6.md` calls worse than v1.**

**5. Two defect classes are invisible in this repo by construction.** A shipped
file pointing into `docs/` (never installed) or at `.claude/skills/` (global
since v2) resolves here and nowhere else. Both showed up only when the check ran
against the pilot. *A framework cannot check itself against itself.*

**6. Two phase-file specs could not be met as written.** 6a's "does not fire on a
legitimate repeat" contradicts the rule 6a states — measured, the tightest
legitimate gap (16 chars) is *closer* than the widest real one (18), so gap alone
cannot separate them. 6c inherited "bootstrap a venv at the test target" from the
archive; the criterion was the problem, not the environment. Both corrections are
in `phase-6.md`, marked.

**7. A performance commit needed a fixture the pilot could not provide.** The
pilot has zero `artifacts:` keys, so invariants 9b, 10 and 12 — the three the
refactor touched most — are invisible to a pilot diff. A byte-identical diff
there would have proved nothing about them.

**8. The order in a ranked list is not the order to execute it.** The runtime fix
was ranked third and went first, because the other four candidates add checks to
the script whose per-document cost was being removed.

## What didn't work

Nothing abandoned. Two things were attempted and rejected on measurement rather
than taste, both recorded above: a gap-only duplicate-path rule (6a), and
bootstrapping a venv to make the migrate-source smoke test pass (6c).

One item was **deliberately not finished** and is item 5 of Phase 7's list:
reshaping the World Bank example doc. It is editorial content work, not a repath,
and doing it badly would ship a worse example than the stale one.

## How to verify all of it in one go

```
bash .claude/hooks/lint-research.sh                     # PASS, 1 warning
npm test                                                # 21 passed, 0 failed
python3 templates/migration/03_linkcheck.py --baseline HEAD   # 0 new breaks, 0 collapses
```

The merge script (6b) needs mapping CSVs and a `research/_legacy/` tree, so it
has no in-repo invocation; `log.md` D9 records the fixture shape.
