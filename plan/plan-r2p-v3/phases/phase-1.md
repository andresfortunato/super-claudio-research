# Phase 1 — Drain the field notes into the conventions

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** nothing · **Parallel with:** Phase 6
**Self-contained.** A worker on this phase needs no other file. If a correction
arrives after launch it is patched *here*, marked `⚠ CORRECTED <date>` — not into
`handoff.md`, which a parallel worker never reads.

## Intent

`docs/field-notes/` was created in v2 as the home for lessons about r2p itself,
after the pilot audit found seven framework bug reports filed as project
learnings — where no future project could see them, which is why the
evidence-id collision was filed **twice, months apart**, and fixed neither time.

v2 created the directory and encoded only some of its contents. The notes are
prose in a folder an agent reads only if it goes looking. **A lesson filed where
it cannot act is the exact failure the directory exists to end** — recurring one
level up, inside the framework that named it.

Route each of the seven to the convention or skill an agent actually reads *at
the moment the lesson applies*, then stamp the note. The prose is already
written and correct: move it close to verbatim (case study §5.5 — *structural
merge beats re-prosing*; the pilot's 43 decision records lost precision every
time someone re-phrased them).

## The seven, and where each goes

Verified by grep on 2026-08-04; the "current state" column is measured, not assumed.

| Note | Current state | Route to |
|---|---|---|
| `concurrent-sessions-same-worktree-steal-staged-files.md` | **the only place in the repo that says `pathspec`** — `provenance.md` §"Half 2 — the commit message" is silent | `provenance.md`, into the commit-message half |
| `parallel-phase-fanout-hygiene.md` | `plan-lifecycle.md` §"Parallel fan-out" already carries it well; `agent-teams/SKILL.md` has **zero** matches for `phase file`, `shared index`, `lost write`, `report.md` | `agent-teams/SKILL.md` — the file an agent reads *while* fanning out |
| `gap-check-data-layer-and-unchecked-branches.md` | encoded nowhere | `evidence.md` — a "before you declare a gap" rule |
| `digest-retention-varies-by-findings-header-style.md` | encoded nowhere | `evidence.md` — the `## Measured` / `## Reading` section schema, as *why the headers are fixed* |
| `evidence-number-collision-parallel-worktrees.md` | mechanism exists (`research/evidence/.next-id`), `evidence.md:18` names it | stamp → `.next-id`; the allocator is **Phase 3, not here** |
| `evidence-number-collisions-parallel-teams.md` | same mechanism — these two are the duplicate filing | stamp → same target as above |
| `porting-a-chart-forces-a-data-reread-and-the-data-moves.md` | **already encoded** at `provenance.md:103` | stamp only, change nothing |

Only four of the seven require an edit outside `docs/field-notes/`. Three are
stamp-and-move-on. Do not manufacture work for the other three.

## The stamp

Every note gains one line, directly under its H1:

```
**Encoded in:** `.claude/conventions/provenance.md` § Half 2 — the commit message
```

or, where the lesson genuinely stays advisory:

```
**Advisory — not encoded.** <one line: why no convention can carry it>
```

The two evidence-id notes point at the same target. If they end up pointing at
two different places, the duplicate filing that recurred once has recurred
again — stop and reconcile before continuing.

## Constraints

- **Move prose, don't re-write it.** Verbatim under the destination's headings,
  compressed only where the destination's format demands it. Conventions are
  prescriptive documents Claude acts on, not essays (`docs/extending.md`
  anti-patterns) — so a field note's narrative *evidence* stays in the note; the
  *rule* goes to the convention.
- **No new convention file.** All four routes land in files that already exist.
- **No new hook.** v2 removed `check-evidence.sh` for firing unconditionally
  after a path refactor; every check in v3 goes to `lint-research.sh` (Phase 3).
- **`.claude/conventions/*.md` stay ≤120 lines** (principle 5, short protocols).
  Current: `provenance.md` 4.0 KB, `evidence.md` 6.5 KB, `plan-lifecycle.md`
  7.6 KB. If a route would push one past the limit, the destination is wrong —
  say so in the handoff rather than trimming something else to fit.
- **Do not touch** `templates/migration/*`, `.claude/skills/migrate-source/`,
  `test/` — Phase 6 owns those, possibly concurrently.

## Verification

Domain-shaped, not "the file changed":

1. **Remedy phrase leaves the note.** `grep -rn pathspec .claude/` returns a
   hit in `provenance.md`. Same for the fan-out remedies in
   `agent-teams/SKILL.md`.
2. **Every stamp resolves.** Each `Encoded in:` names a path that exists *and* a
   heading that contains the rule — open it and read it, don't trust the path.
3. **The two collision notes converge** on one target.
4. **Nothing regressed.** `bash .claude/hooks/lint-research.sh` still passes
   from repo root.
5. **The four edited conventions still read as protocols** — a rule an agent can
   act on, not a story about Córdoba.

## Commit discipline

Commit **by pathspec**, in one command — never `git add` then `git commit`.
Phase 6 may be running in this same worktree, and the git index is
per-worktree, not per-session: staging and then committing hands your files to
whichever session commits first, under its message. This is the lesson this
very phase exists to encode.

```
git commit -m "<msg>" -- docs/field-notes/ .claude/conventions/provenance.md ...
```

Suggested split: one commit per route (4), plus one for the three stamp-only
notes. Message names the note and the destination.
