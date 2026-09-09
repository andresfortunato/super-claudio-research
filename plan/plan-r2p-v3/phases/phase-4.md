# Phase 4 — `/cite-check`

**✅ DONE 2026-09-09.** All three tasks — 4.1 (`.claude/skills/cite-check/SKILL.md`),
4.2 (refuse early), 4.3 (the `/verify` boundary). All four verification criteria
met. Commit `703821f`. **Decision A answered: its own skill**, as recommended
(`log.md` **D7** §2).

**Scope shrank between spec and execution, deliberately.** This file was written
when link 1 had no lint at all; Phase 3 then shipped invariants 13 and 14, so the
skill does not reimplement resolution — it runs `lint-research.sh` first and
spends its budget on the three classes no grep can see. See *Execution notes*.

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phases 2, 3 · **Blocks:** nothing
**Session scope:** one session · **Estimated context:** ~30%

## Intent

The lint checks that links *resolve*. This checks that a specific deliverable
*uses* them — the publish-time question "is every number in this memo traceable
to a claim, and every claim to live evidence?"

Why it can't be a lint: the lint reads structure, and a memo's numbers live in
prose. Deciding which number a reader could challenge is judgement. Why it can't
be automatic: on a mid-composition draft every number is uncited, so a hook would
fire constantly and get discounted — that is exactly how a prescribed format ends
up at 7-of-71 compliance.

## Tasks

**4.1 — `.claude/skills/cite-check/SKILL.md`** ✚
User-invoked, ≤2k tokens, same tier as `/verify`. Takes a deliverable path.
Reports three defect classes:

| Class | Why it matters |
|---|---|
| **cites nothing** | §4's three load-bearing memo numbers with no evidence doc at all |
| **cites evidence directly** | the v1 pattern — 122 evidence ids cited from memos and decks, so every evidence revision threatened every deliverable. One indirection through a claim fixes it |
| **cites a claim whose evidence is `retired`** | 25 docs carried prose retraction banners; retired legs kept being cited from doc bodies. `status:` made this filterable in v2 and nothing yet filters on it |

**4.2 — Refuse early, like `/deliverable-review` does.** That skill refuses on
drafts with sections marked TBD or numbers marked `[CHECK]` and points at
`/verify`. Mirror it: on an outline, every number is uncited and the report is
noise. Say what the skill does *not* do.

**4.3 — Cross-reference** ✎ `.claude/skills/verify/SKILL.md`
`/verify`'s paragraph menu already includes a "source citation" check. Name the
boundary: `/verify` asks *does this one paragraph cite something?*, `/cite-check`
asks *does this whole deliverable's chain hold?* Without this line the two will
drift into overlapping and one will be dropped.

## Verification

- A fixture deliverable containing **one of each** defect class, plus at least one
  correctly-cited number and one prose number that is not a claim (a year, a
  count of interviews) — it must find the three and not flag the two.
- Stays inside 2k on a realistic memo. If it can't, the report is too verbose:
  cut the narrative, keep the table.
- **Never edits the deliverable.** It reports; the researcher resolves. Same
  posture as `/research-cleanup`, which writes a proposal and touches nothing.
- Per `context/installer-map.md`, a new skill directory needs **no** installer
  change — `installGlobals()` enumerates `.claude/skills/` at runtime. Verify the
  symlink appears; do not edit `install-project.js`.

## Do not touch

`lint-research.sh` (Phase 3 owns it and it should already be done — if it isn't,
this phase is not unblocked), the conventions (Phase 2), anything in Phase 6's
list.

## Commit discipline

By pathspec, one command. One commit; the fixture may be committed with it or
kept in the scratchpad, but if the fixture is committed it goes somewhere a
`research-cleanup` audit will not later flag as an orphan.

## Execution notes — 2026-09-09

### Verification, criterion by criterion

| Criterion | Result |
|---|---|
| fixture with one of each class, plus a correctly-cited number and a prose number that is not a claim | **found 3, exempted 5** — a cited `4.2pp [C12]`, a category count, an interview count, a year, and an external `2.1%` whose source is named in the same sentence |
| stays inside 2k on a realistic memo | **~510 tokens** on the fixture. The class-2 list is the only unbounded part and is capped with a stated drop count |
| never edits the deliverable | verified by md5 across a full run on a committed fixture: unchanged, working tree clean |
| new skill dir needs no installer change | verified — `installGlobals()` `readdir`s `.claude/skills/` at runtime; the symlink appeared from an unmodified installer run |

### The fixture is the argument for the skill

`lint-research.sh` prints a **clean PASS** on it. Every `[C<n>]` resolves, every
`#nn` resolves, `.next-id` is ahead, frontmatter is complete. And the memo still
carries all three defects: an uncited `11.4%`, an `18%` citing `#1` directly, and
a `[C20]` resting on a retired doc whose live replacement revises 6% to 2%.

**Build the fixture this way on purpose.** A fixture that fails the lint proves
nothing about a skill that runs after the lint.

### Two defects the fixture found, neither visible in a diff

1. **The refuse-early rule refused the fixture.** It had inherited
   `/deliverable-review`'s ≥800-word floor; the fixture is a *finished* 127-word
   memo. That floor exists because a seven-lens fan-out is too expensive for a
   stub — a ≤2k check has no such excuse, and short is the shape of a ministerial
   briefing note. Now: refuse on draft markers (`TBD`, `[CHECK]`, empty sections),
   never on length. **The general form: copying a neighbour skill's precondition
   without its reason.**
2. **A *Not flagged* section was missing**, so a reader could not tell an
   exemption from a miss. This is 3.5's inapplicable-invariant rule reached
   independently from the other side.

### Carried out of this phase

**A claim resting on `status: retired` evidence is mechanical** and would make a
clean invariant 15. It lives in the skill because this file put it there, and a
phase does not get to grow into `lint-research.sh`. **Phase 6 candidate.**
