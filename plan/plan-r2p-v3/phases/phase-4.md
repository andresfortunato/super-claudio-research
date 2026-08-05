# Phase 4 — `/cite-check`

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phases 2, 3 · **Blocks:** nothing
**⚠ Gated on decision A** — own skill, or a fourth check menu inside `/verify`?
Recommendation on file: own skill. Confirm before starting.
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
