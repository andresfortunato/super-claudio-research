# Handoff — plan-r2p-v3

**Session:** 2026-08-05 (first execution session) · **Last commit:** `1b8a85d`
**Branch:** `main` · **Working tree:** clean except untracked `CLAUDE.md` and `plan/`
(both untracked *before* this session — see Surprises).

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** — 4 routes + 7 stamps, all 5 verification criteria pass, 4 commits |
| 2 | State the chain once | not started — unblocked |
| 3 | Lint the chain | not started — blocked on 2 |
| 4 | `/cite-check` | not started — blocked on 3, **needs decision A** |
| 5 | `/pipeline-check` | not started — blocked on 3, **needs decision C** |
| 6 | Harden the tooling | not started — **unblocked, independent of everything** |
| 7 | Docs, constitution, release | not started — blocked on all, **needs decision B** |

## Phase 1 — what landed

Four commits, each by pathspec (`520c66c`, `8f3daab`, `06eadb6`, `1b8a85d`):

| Route | Destination | Commit |
|---|---|---|
| shared-index / `git add` race | `provenance.md` § Half 2 → *Commit by pathspec, never stage-then-commit* | `520c66c` |
| fan-out hygiene (all 5 modes) | `agent-teams/SKILL.md` — 4 new `####` subsections + the `report.md` rule | `8f3daab` |
| gap-check | `evidence.md` § Where evidence lives → *Before declaring a gap…* | `06eadb6` |
| digest retention | `evidence.md` § the `Measured`/`Reading` split — as *why* the headers are fixed | `06eadb6` |
| 3 stamp-only notes | — | `1b8a85d` |

Verification run and passing: remedy phrases left the notes (`pathspec` now resolves
in `.claude/`, all four fan-out phrases in `agent-teams`); all 7 stamps name a path
**and** a heading that exist; the two collision notes converge; `lint-research.sh`
PASS; the edited conventions still read as protocols.

## Surprises

**1. The ≤120-line convention limit is already broken repo-wide, and Phase 1 made
two files worse.** The phase file quoted destination sizes in **KB** but stated the
limit in **lines**, so the headroom it assumed did not exist. Measured before this
session:

```
ok    90 claims.md     OVER 146 evidence.md   OVER 144 methods.md
ok   113 provenance.md OVER 214 plan-lifecycle.md
ok   113 sources.md    OVER 185 project-conventions.md  OVER 184 source-registry.md
```

**5 of 8 conventions already exceeded it.** `docs/audience-and-philosophy.md:112`
makes "Does the protocol stay ≤120 lines?" a checkable question in the table every
proposal must pass — so this is a live constitutional failure, not a style nit.
After Phase 1: `provenance.md` 113 → **135**, `evidence.md` 146 → **187**.

Per the phase's own instruction ("if a route would push one past the limit, the
destination is wrong — say so in the handoff rather than trimming something else to
fit") the rules were written at their tightest and the breach is reported here
rather than absorbed. **This needs a researcher call, and it belongs in Phase 7**
(constitution edits), alongside decision B. Three options:

- (a) Raise/qualify the limit in the constitution — e.g. ≤120 lines for the
  *pointer block's* protocol summary, no hard cap on the convention file. Cheapest,
  and arguably what the principle always meant (its heading is "Short CLAUDE.md").
- (b) Keep 120 and split the 5 over-length conventions. Largest change; risks the
  "no layout change" constraint by multiplying convention files.
- (c) Keep 120 as an aspiration and drop it from the checkable-questions table.
  Worst of the three — it converts a mechanical check into advice, which is the
  `learnings/index.yaml` failure mode the plan explicitly forbids (§6.6).

*Recommend (a).* Nothing in the Córdoba audit says a 146-line protocol failed; the
evidence for the principle is all about **CLAUDE.md** being loaded every session,
which a convention file is not.

**2. `agent-teams/SKILL.md` contained a live contradiction, now fixed.** Its *Lead
consolidation* step 1 said "Read each teammate's output file" while the harness
blocks teammates from writing report files. Any lead following it would look for a
file that cannot exist. Fixed in `8f3daab`; flagged because the same
write-vs-return assumption may sit in other skills — worth a grep in Phase 7.

**3. `evidence-number-collisions-parallel-teams.md` had no H1** — it opened on
`## Problem`. Added one. If `docs/field-notes/README.md` or any tooling derives
titles from H1, that note was invisible to it.

**4. Two routes shared one destination, so Phase 1 shipped 4 commits, not the 5 the
phase suggested.** Splitting `evidence.md`'s two routes across two pathspec commits
would require staging partial hunks — which the pathspec rule committed one step
earlier explicitly says not to do with that form. Noted rather than worked around.

**5. `CLAUDE.md` and `plan/` are untracked on `main`.** Pre-existing, not caused
here. The repo's own project-instruction file is uncommitted, which means a fresh
clone gets none of the rules in it. Outside Phase 1's ownership; someone should
decide deliberately whether it is committed.

## What didn't work

Nothing abandoned. One check was authored wrong and corrected in place: comparing
the two collision stamps byte-for-byte reports a false divergence, because each
correctly backlinks the *other* note. The convergence test must strip the
` Duplicate of …` clause first:

```sh
grep -h "^\*\*Encoded in:\*\*" docs/field-notes/evidence-number-collision*.md \
  | sed 's/ Duplicate of.*//' | sort -u | wc -l   # must be 1
```

Worth keeping — this is the tripwire against the duplicate filing recurring a third
time, and Phase 3 could make it invariant-shaped.

## Next

**Phase 6 or Phase 2.** Both unblocked; 6 is the safer next session because it is
independent of everything and its split point (6c, `migrate-source`) is named in
advance. Phase 2 is the critical path (blocks 3, which blocks 4 and 5).

Before Phase 4/5/7, the researcher owes decisions **A**, **C** and **B**
respectively — plus the ≤120-line call in Surprises 1, which folds into B's phase.

Read `context/installer-map.md` before touching anything under `src/`; per `plan.md`
it already corrects one thing the File Manifest gets wrong (a new skill needs no
installer edit).
