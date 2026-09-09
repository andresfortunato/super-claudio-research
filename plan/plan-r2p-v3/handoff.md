# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phase 7 — the last one)
**Prior sessions:** 2026-08-05, 2026-08-17, 2026-09-09 (2b), 2026-09-09 (3),
2026-09-09 (4+5), 2026-09-09 (6)
**Last content commit:** `e396392` — **this handoff is committed on top of it**,
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
| 6 | Harden the tooling | **done** — all six items (**D9**) |
| 7 | Docs, constitution, release | **done 2026-09-09** — every task (**D10**) |

**All seven phases are verified. v3 has shipped: `package.json` is `0.3.0`.**
No researcher calls are outstanding. One was taken this session, before any
deletion — decision B's scope; see *What landed* and `log.md` **D10.1**.

**The only thing left in this plan is archival.** The next session should
confirm with the researcher, `touch plan/plan-r2p-v3/.completed`, and let the
Stop hook hand off to the **archivist**.

## What landed

| Commit | What |
|---|---|
| `1fad4b1` | **7.3b** — the v1 `methods/<slug>/rule.md` layout stops being an instruction, 9 files |
| `d351edf` | **7.3** — `r2p-adopt.md` fully repathed; it was v1 throughout, not five bad pointers |
| `978de28` | **7.3 + C** — `verification-architecture.md` rewritten: 5 tiers, the side-effect axis |
| `8d21a59` | **7.4** — constitution: principles 5, 7, 9 fixed; **principle 10 added** |
| `4a7e4fe` | **7.6** — 8 design docs deleted, 6 kept and repathed, every citation repointed |
| `2faea66` | **7.1** — `docs/v2-to-v3.md` |
| `28f6a19` | **7.2** — `docs/citation-chain-mechanism.md` |
| `a6af00b` | **7.5** — `extending.md`: step 2 becomes lint-invariant / skill / hook, in that order |
| `6ac46cb` | **item 5** — `EXAMPLE_world_bank_api.md` reshaped to the required five sections |
| `a964e42` | **7.7a** — README + TODO describe v3; TODO's three double-listed items resolved |
| `625b48e` | **item 4** — invariant 15's doc tier → FAIL, `plan/**` split off as permanent WARN |
| `7aedef8` | **not in any task list** — a fresh `r2p init` failed its own linter |
| `e396392` | **7.7** — release, `0.3.0` in two places |

Plus this handoff, which also carries `log.md` D10, `phase-7.md`'s outcomes, and
`.scc/status/project.md`.

## Where the numbers are now

| | Session start | Now |
|---|---|---|
| lint checks | 18 | 18 (two fixed, one made comment-aware) |
| invariant 15 findings, this repo | 25 (18 live) | **0 outside `plan/`** |
| lint verdict, this repo | PASS, 1 warning | PASS, 1 warning (`plan/` only, self-clearing) |
| lint verdict, a fresh `r2p init` | **FAIL, exit 1** | **PASS, exit 0** (also `--with-wiki`) |
| lint verdict, pilot | FAIL, 5 warnings | FAIL, 5 warnings — unchanged |
| `docs/*-mechanism.md` | 14 (2,695 lines) | 6 |
| `npm test` | 21 passed | 21 passed |
| version | `0.2.0` | **`0.3.0`** |

**Re-measure before diffing.** The pilot baseline decays in weeks, and its
FAIL is real defects rather than a regression.

## How to verify all of it in one go

```
bash .claude/hooks/lint-research.sh                            # PASS, 1 warning
npm test                                                       # 21 passed, 0 failed
python3 templates/migration/03_linkcheck.py --baseline HEAD    # 0 new breaks, 0 collapses
```

And the one that found the most this session — a throwaway scaffold, which is
now part of the stated procedure for any new invariant (`extending.md` 2a):

```
cd $(mktemp -d) && git init -q . && node <repo>/src/cli.js init
CLAUDE_PROJECT_DIR=$PWD bash <repo>/.claude/hooks/lint-research.sh   # PASS, exit 0
```

## Surprises

**1. Decision B's object was wrong, though the decision was sound.** It said
"delete the 14 `docs/*-mechanism.md` files"; only eight are design docs for
conventions v2 merged away. Six document live conventions, and `extending.md`
still prescribes that filename as the rationale slot — the slot task **7.2
creates a new file in, in the same phase**. Executing it literally would have
retired the pattern in the act of using it. Escalated before any deletion;
answered *delete 8, repath 6*. Measuring first is what made it one round: the
six keepers carry 0–3 stale mentions each, eight in total, so "keep" cost eight
line-fixes. ***A decision that names a file set by pattern is a decision about
the pattern. Enumerate and read the set before executing it.***

**2. The verification criterion nobody had run found the largest defect.**
"`r2p init` into a throwaway repo, lint green and silent" was in Phase 7's list
from the start. Run for the first time — after **eleven of eighteen invariants
had shipped** — it exited 1 with three findings on a tree containing no research.
**Two of the three were the check, not the files:** a `~/`-prefixed path is a
global install and resolving it against the project root is the wrong question,
and a prose-qualified `docs/` pointer is deliberate. The third was the shipped
`claims.md` seed's placeholder claim. *Last handoff's surprise 5 said a framework
cannot check itself against itself; this is its other half — it cannot check
itself against its users either. Both are populated states. The empty state is
the only corpus whose correct answer is known in advance.*

**3. "Promote the WARN tier to FAIL" needed a third tier instead.** Done
literally it leaves the repo red for as long as any plan is open, because the
last seven findings live in `plan/`, where quoting a dead convention *while
describing the defect* is correct and unfixable-by-editing. `plan/**` is now a
permanent WARN tier; that split is what made the promotion reachable.

**4. Two task lines were much larger than they read, in the same direction.**
7.3's `r2p-adopt.md` was listed as five dangling pointers and was an entirely v1
document — the one file a project reads when it has no other model of the
framework, and it was **teaching the id-collision vector** (`ls evidence/ | sort
| tail -1`) that produced five duplicate ids on the pilot. 7.7's README was
listed as "conventions list and version"; its `docs/` tree named nine files that
no longer exist and none of the four that do. *Same shape as D9's surprise 2, one
level up: a task line written months before execution is an inventory, and it
decays the same way.*

**5. A generated report, once committed, becomes its own input.** `linkcheck.md`
was swept up by an over-broad `git add -A`; the next run read a previous run's
table rows and reported a phantom collapse. Untracked, gitignored, and the script
now excludes its own `SELF_REPORT`. Second time in two phases that a tool's own
artifact distorted its own measurement, and both times the symptom looked real.

**6. Almost nothing in this phase was bookkeeping.** The phase file opened by
saying so — *"Not bookkeeping. Three distinct jobs, and the middle one is
bug-fixing"* — and it undersold it. Of eleven commits, one is the version bump.

## What didn't work

Nothing abandoned. One deviation from an approved instruction, stated in its
commit rather than absorbed silently: `migrate-source-mechanism.md` was named in
the delete column of the list the researcher approved and was **kept**, because
the rule approved alongside that list — *delete docs for conventions v2 merged
away, keep docs for live ones* — puts it in the keep bucket. The skill is live
and 6c repathed it.

## Next session

1. **Confirm with the researcher, then `touch plan/plan-r2p-v3/.completed`.**
   The Stop hook writes `.archival-triggered` and asks for the **archivist**
   subagent, which synthesizes `archive/plan-r2p-v3.md`, appends to the archive
   index, and deletes this directory. Archiving also clears the last seven lint
   warnings, since `archive/` is exempt.
2. **Before archival, check the promotion rule** (`plan-lifecycle.md` Stage 4):
   any reusable rule this plan produced moves to a convention rather than being
   summarized in the archive entry. Most of v3's already did — that was the
   plan's whole thesis — but `log.md` D10's *three corpora* rule landed in
   `extending.md` and its field note, so verify rather than assume.
3. **`git push`.** Nothing in this plan has been pushed.

Beyond the plan, `TODO.md` is current: **v4 is the plugin migration**, and four
small diagnosed items are open, of which the two this plan generated are that
the framework repo has no `.claude/settings.json` of its own and that
`lint-research.sh` has no CI job in either repo.
