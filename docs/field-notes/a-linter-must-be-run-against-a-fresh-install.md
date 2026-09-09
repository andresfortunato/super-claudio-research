# A linter that has never been run against `r2p init` fails on `r2p init`

**Encoded in:** `.claude/hooks/lint-research.sh` § invariant 15 exclusions 3 and
4 (global `~/` paths, and lines marked *framework repo*), `claims_live()` (HTML
comments are not live claims), and `templates/research/claims.md` (the shipped
`C1` is commented out). Plus `docs/extending.md` step 2a: **run a new invariant
against a fresh scaffold before you ship it.**

## Problem

`lint-research.sh` grew from 7 checks to 18 over v3, tested throughout against
two corpora: this repo and the Córdoba pilot. Both are mature. Neither is what
`r2p init` produces.

The first time the linter was pointed at a fresh `r2p init` — during Phase 7's
release verification, after eleven of the eighteen checks had already shipped —
it exited 1 with three findings on a scaffold containing no research at all:

| Finding | What it actually was |
|---|---|
| `C1 — no Rests on: ids` | the **shipped `claims.md` seed**, whose worked example is a placeholder claim |
| `check-archival.sh:55 -> .claude/agents/archivist.md (gone)` | a correct reference to `~/.claude/agents/archivist.md`, which is **installed globally** |
| `project-conventions.md:92 -> docs/audience-and-philosophy.md (gone)` | a correct, prose-qualified reference to a doc `r2p init` does not install |

**Two of the three were the check being wrong, and one was the seed.** All three
were invisible in the two corpora it had been tested against — the mature repos
have real claims, and this repo has `docs/` and no global-vs-project distinction
to get wrong.

## Why it matters more than a normal false positive

A linter that fails on the day it is installed is worse than no linter, and the
failure mode is not "someone fixes it". It is that the project learns, in its
first five minutes, that a red run is the normal state. Every subsequent real
finding arrives pre-discounted. This is the same dynamic that killed
`check-evidence.sh` — noise trains people to stop reading — arriving through a
different door.

It is also self-concealing in a specific way. The three findings each looked
plausible: a claim with no evidence *is* invariant 17's finding, and a
`.claude/**` path that does not resolve *is* invariant 15's. Nothing about the
output said "these are about the scaffold, not about your project."

## The rule

**Every new lint invariant runs against three corpora before it ships:** a
mature project (finds real defects), this repo (finds framework defects), and a
throwaway `r2p init` (proves it no-ops on an empty tree). The third is the one
that gets skipped, and it is the only one whose result is unambiguous — a fresh
scaffold has a known-correct answer, which the other two never do.

Two smaller rules fell out, both now in the script:

- **A `~/`-prefixed path is a global install, not a project-relative one.**
  Skills and agents live in `~/.claude/`; resolving them against the project
  root asks the wrong question. Mechanical, so it is in the pattern.
- **A shipped file may point into `docs/` if the line says "framework repo".**
  `TODO.md` had recorded this as un-mechanisable — "the judgement is whether the
  reference is *qualified*, which a grep cannot decide" — and that was true of
  qualification in general and false of an explicit marker. Honouring a stated
  marker is what invariant 14 already does with a renumber banner. It also
  converts *name the framework repo when you point into `docs/`* from advice
  into a rule with a consequence.

## The generalization

**A framework cannot check itself against itself, and it cannot check itself
against its users either.** Both are populated states. The empty state is a
third corpus, it is the one every project passes through, and it is the only one
with an answer known in advance.
