# Handoff — plan-r2p-v3

**Session:** 2026-08-05 (first execution session)
**Last content commit:** `785113f` — **this handoff is committed on top of it**, so
`HEAD` is the handoff commit, not `785113f`. (A handoff cannot name its own commit;
the convention forbids fabricating it. Verify with `git log --oneline -2`.)
**Branch:** `main` · **Working tree:** clean except untracked `CLAUDE.md`
(untracked *before* this session — see Surprises 5).

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** — 4 routes + 7 stamps, all 5 criteria verified |
| 2 | State the chain once | **done** — all 4 tasks + template pointer, all 4 criteria verified. **One shipped assumption corrected after the pilot review — see D2** |
| 3 | Lint the chain | **next** — unblocked. See *Carry into Phase 3* below |
| 4 | `/cite-check` | blocked on 3 · **needs decision A** |
| 5 | `/pipeline-check` | blocked on 3 · **needs decision C** |
| 6 | Harden the tooling | unblocked, independent of everything |
| 7 | Docs, constitution, release | blocked on all · **needs decision B** |

**Decisions made in-session:** principle 5's line budgets dropped (`log.md` **D1**);
pilot-repo review corrected the claim-heading anchor and fed phases 3 and 6
(`log.md` **D2**). Decisions **A**, **B**, **C**, **D** remain open.

## Pilot-repo review (2026-08-05) — what it changed

Reviewed `~/cordoba-growth-narrative`: v2 layout, 173 evidence docs, 42 claims, 10
worktrees. Full account in `log.md` **D2**. The three that bind future phases:

1. **Claims sit at `### C<n>`, not `## C<n>`** — grouped under six `## §N`
   sections. Phase 2 had shipped the `##` assumption, so a checker built to spec
   would have reported **zero claims on a 42-claim ledger**. Both conventions now
   resolve on `^#{2,3} C[0-9]+`; verified 42 hits against the pilot.
2. **573 bare `#nn` refs, zero claim refs** across three drafts of one memo.
   `[C<n>]` has a real adoption gap → convert-on-touch rule added to
   `citation-discipline.md`, and **invariant 13 must be WARN, not FAIL** (a
   FAIL with 573 targets is the linter-crying-wolf death `check-evidence.sh` had).
3. **The pilot still runs `check-evidence.sh`, wired in its `settings.json`** —
   the hook v2 deleted for firing unconditionally. `--upgrade` never auto-deletes
   (correct) but prints **no warning** for an orphaned hook, though it does warn
   about obsolete `skills/` and stale EXCLUDEs. → Phase 6d gains the warning + an
   assertion.

**Verified fine, no action:** `_inbox/` already promoted to the template; pilot
fully on v2 layout; its CLAUDE.md convention pointers all resolve; project-local
`.claude/skills/` correctly absent — `~/.claude/skills/` **symlinks into this
repo**, so framework skill edits reach installed projects immediately.

## What landed — 9 commits

**Phase 1** (`520c66c`, `8f3daab`, `06eadb6`, `1b8a85d`)

| Route | Destination |
|---|---|
| shared-index / `git add` race | `provenance.md` § Half 2 → *Commit by pathspec* |
| fan-out hygiene (5 modes) | `agent-teams/SKILL.md` — 4 new `####` sections + the `report.md` rule |
| gap-check | `evidence.md` § *Before declaring a gap…* |
| digest retention | `evidence.md` § the `Measured`/`Reading` split — as *why* headers are fixed |
| 3 stamp-only notes | — |

**Constitution** (`912ea7a`) — D1, landed out of phase because Phase 2's spec
depended on it.

**Phase 2** (`ee44c32`, `3765ea1`, `5aba91e`, `785113f`) — `citation-discipline.md`
✚; `[C12]` syntax in both `citation-discipline.md` and `claims.md`; `artifacts:`
key in `evidence.md` + the example template; provenance ↔ artifacts cross-links;
one pointer line in `templates/CLAUDE.md.template`.

## Carry into Phase 3 — read this before writing invariants

**1. Invariant 13 does not exist and Phase 3's task list is one short.** Phase 3
specs invariants 8–12. Mapped against the chain:

| Link | Cheap check | Expensive check |
|---|---|---|
| deliverable → claim | **none** | `/cite-check` |
| claim → evidence | inv 8 | — |
| evidence → artifact | inv 9, 12 | — |

Decision 2 in `plan.md` says *"No mechanism ships only its expensive half."* As
specced, link 1 does exactly that. The missing check is one grep — every `[C<n>]`
in `deliverables/` resolves to a `## C<n>` heading in `research/claims.md` — and
`citation-discipline.md` already forward-references it as **invariant 13
(proposed)**, in a *Gaps* section, so shipping without it leaves a written promise
unkept. **Recommend adding it as task 3.4b.** Verified regex, tested below.

**2. The claim-reference regex is `\[C[0-9]+\]` and is verified.** Fixture at
`…/scratchpad/fixture-memo.md` (scratchpad, not committed — `test/` is Phase 6's).
Extracts exactly 3 refs (`C12`, `C14`, `C15`); correctly rejects `[1]`, `[23]`,
`[2024]`, `[c12]`, `[#71]` and markdown image alt-text. Reproduce:

```sh
grep -oE '\[C[0-9]+\]' <memo>            # the refs
grep -oE '\[[^]]*\]' <memo> | grep -vE '^\[C[0-9]+\]$'   # everything it rejects
```

**3. `artifacts:` is a YAML block list, not inline.** Shipped shape:

```yaml
artifacts:
  - output/labour/emp_rate.png
```

Invariants 9 and 12 must parse the block form. The key is **optional**, and absent
is the common legitimate state — an invariant that treats absence as failure would
fire on every doc that measures something without a chart. Absence means "not
stated", never "no charts exist".

**4. No installer edit is needed for a new convention.** Both installers copy
`.claude/conventions/` by directory walk (`install-project.js:171`,
`upgrade.js:258`) — confirming what `plan.md` says the File Manifest gets wrong.
A new *hook invariant* is inside an existing file, so it also needs none. Phase
3.6's `r2p evidence new` **does** touch `src/cli.js` — read
`context/installer-map.md` first.

## Case-study compliance — audited, not assumed

Each lesson `plan.md` says binds this plan, checked against
`docs/v2-case-study-cordoba.md` itself:

| Lesson | Status |
|---|---|
| §6.5 size rules as ranks/shares, never absolute counts | **held** — grepped: zero absolute-count thresholds in `citation-discipline.md` |
| §6.7 zero-artifact mechanism gets one line, not a section | **held** — one line under *Where Things Go*, promotion explicitly gated on `deliverables/` carrying citations |
| §6.6 codify what survives contact | **held, and load-bearing** — it is the argument that killed the ≤120-line rule (D1) |
| §5.3 never infer a field whose wrongness beats its absence | **held** — `artifacts:` is hand-authored or absent, no-inference rule stated with the 24-province `metro \| 1960–2026` reason |
| §6.8 a mechanism filed where it cannot act | **held** — this is Phase 1's entire premise, and Phase 2 obeyed it too (a convention with no CLAUDE.md pointer would have repeated it) |
| §5.5 structural merge beats re-prosing | **partial — see below** |
| §5.2 measure a baseline · §5.6 print the heading tree | **not yet — Phase 6 owns both** |

**§5.5, honestly.** Phase 1 said "move prose, don't re-write it… verbatim, compressed
only where the destination's format demands it." The rules were **rewritten into the
prescriptive register**, not moved verbatim — conventions are documents an agent acts
on, field notes are narrative, and the two registers don't overlap. What §5.5 is
actually protecting was preserved: every precision-carrying element moved intact
(22–96% and the 42% mean, the ~50% full-read threshold, `grep -c '^### '`, the four
shared append-targets, the 135/136/137 block allocation, the exact safe/unsafe git
forms). What was dropped was engagement-specific narrative — the 2,758-page PDF, the
1 May 2026 legal date, `cordoba_utils.py` — which `CLAUDE.md` requires dropping.
**A future session re-checking §5.5 compliance should judge it on preserved numbers,
not preserved sentences.**

**Not started, and named here so it isn't lost:** `plan.md`'s closing note says
running v3's lint against the pilot repo is the cheapest validation that invariant 9
is real, because invariant 9 is precisely the check that finds the case study's
**three claims with no evidence doc** (§7's "highest-value follow-up"). That is a
Phase 3 verification step, not pilot-repo work.

## Surprises

**1. The ≤120-line protocol cap was never a real rule.** Resolved in-session as
D1 — full argument in `log.md`. Short form: it appeared only in the
checkable-questions table, applied CLAUDE.md's number to a different object, was
enforced by nothing, and sat at 3-of-8 compliance through a full release. The
researcher dropped it *and* the CLAUDE.md budget; length is now the researcher's
call. Phase 1's and Phase 2's stale criteria are marked `⚠ CORRECTED` in place
rather than deleted, so the wrong version stays visible.

**2. `agent-teams/SKILL.md` had a live contradiction, now fixed.** *Lead
consolidation* step 1 said "Read each teammate's output file" while the harness
blocks teammates from writing report files. Any lead following it would look for a
file that cannot exist. **The same write-vs-return assumption may sit in other
skills — worth one grep in Phase 7.**

**3. `evidence-number-collisions-parallel-teams.md` had no H1**, opening on
`## Problem`. Added. If anything derives titles from H1, that note was invisible.

**4. Two routes shared one destination**, so Phase 1 shipped 4 commits, not 5.
Splitting `evidence.md`'s two routes across two pathspec commits needs partial
staging — which the pathspec rule committed one step earlier says not to do.

**5. `CLAUDE.md` is untracked on `main`.** Pre-existing. The repo's own
project-instruction file is uncommitted, so a fresh clone gets none of its rules.
Outside any phase's ownership; needs a deliberate call.

**6. The 5 over-length conventions were deliberately left alone.** Under D1 their
length is not a defect, so normalizing them would be work created by a rule that
no longer exists. `evidence.md` is now 215 lines and `provenance.md` 143.

## What didn't work

Nothing abandoned. Two checks were authored wrong and corrected:

- Comparing the two collision stamps byte-for-byte reports a **false divergence**,
  because each correctly backlinks the *other* note. Strip the clause first:
  `… | sed 's/ Duplicate of.*//' | sort -u | wc -l` must be `1`. This is the
  tripwire against the duplicate filing recurring a third time — **Phase 3 could
  make it invariant-shaped.**
- The first fixture memo had 3 references across only 2 distinct claims, which
  passes Phase 2's wording loosely. Rewritten to 3 distinct claims so the
  criterion is met unambiguously.

## Next

**Phase 3** (lint the chain) is the critical path and is unblocked. Its named split
point is **task 3.6** (the CLI), after the five invariants — plan the session
boundary there. Add **3.4b (invariant 13)** per *Carry into Phase 3* §1, or
explicitly decide not to and downgrade `citation-discipline.md`'s *Gaps* section
from "proposed" to "advisory" so the file stops promising something that isn't
coming.

Phase 6 remains available as an independent alternative if you'd rather keep the
critical path for a fresh session.
