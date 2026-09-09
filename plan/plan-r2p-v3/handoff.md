# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phase 2b execution) · prior sessions 2026-08-05, 2026-08-17
**Last content commit:** `2d21597` — **this handoff is committed on top of it**, so
`HEAD` is the handoff commit, not `2d21597`. (A handoff cannot name its own commit;
the convention forbids fabricating it. Verify with `git log --oneline -2`.)
**Branch:** `main` · **Working tree:** clean.

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** — 4 routes + 7 stamps, all 5 criteria verified |
| 2 | State the chain once | **done** — all 4 tasks + template pointer, all 4 criteria verified. **One shipped assumption corrected after the pilot review — see D2** |
| 2b | Graduate the Córdoba fixes | **done 2026-09-09** — all 5 items, all 6 criteria verified by command, constraints held. See **D5** |
| 3 | Lint the chain | **next — unblocked.** **Task 3.0 (WARN tier) is new and comes first**; 3.4c is new. See *Carry into Phase 3* below |
| 4 | `/cite-check` | blocked on 3 · **needs decision A** |
| 5 | `/pipeline-check` | blocked on 3 · **needs decision C** |
| 6 | Harden the tooling | unblocked, independent of everything |
| 7 | Docs, constitution, release | blocked on all · **needs decision B** |

**Decisions made in-session:** principle 5's line budgets dropped (`log.md` **D1**);
pilot-repo review corrected the claim-heading anchor and fed phases 3 and 6
(`log.md` **D2**); Phase 2b executed and a stale-pointer class surfaced (**D5**).
Decisions **A**, **B**, **C**, **D**, **E** remain open. **N6 is closed —
rejected 2026-08-17.**

**⚠ 2026-09-09 — the pilot repo moved.** `~/cordoba-growth-narrative` is gone; it
is now **`~/research/cordoba`**. **Already repathed** in `phase-3.md`, `phase-6.md`
and `context/cordoba-graduation.md` — including the runnable `cd` commands — because
a phase file is what a parallel agent obeys (`agent-teams/SKILL.md:87`). `log.md`
keeps the old path where it records a past review; that is a log doing its job.

**✚ 2026-08-17 (`log.md` D4):** the Córdoba graduation study ran. It added
**Phase 2b**, reordered Phase 3, landed one fix ahead of the phases, and closed
three researcher calls — placement, the repath timing, and **N6** (rejected: r2p
stays engagement-neutral). It also rejected the two-language finding outright:
**r2p stays language-agnostic**, researcher call, do not re-propose.

## Pilot-repo review (2026-08-05) — what it changed

Reviewed the pilot (then `~/cordoba-growth-narrative`, now `~/research/cordoba`): v2 layout, 173 evidence docs, 42 claims, 10
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

### Folder grouping inside `research/` (`log.md` **D3**)

**The v2 layout held.** `methods/` is 37 flat `<topic-slug>.md` + `_adjuncts/`,
exactly per `methods.md:35,46`; `sources/` is flat files + per-source companion
dirs. Six months of contact, no drift. That is the result worth knowing.

**One divergence, broken three ways silently** —
`research/evidence/access_to_finance/` (tracked): ids **20/21/22 collide** with
root-level docs, all three are **absent from `INDEX.md`**, and
`lint-research.sh` **cannot see them** (`:49` and `:80` glob `"$EV"/[0-9]*_*.md`,
non-recursive → confident PASS over an unopened directory). Fourth recurrence of
the evidence-id collision, via a vector `.next-id` cannot defend: a second
numbering namespace, not parallel allocation. → **decision E**; Phase 3 must make
invariant 1 recursive regardless of how E lands.

**The v1 methods path is live in eight files** an agent acts on
(`planning/SKILL.md` ×3, `implementation/SKILL.md:37` contradicting its own `:64`
and `:148`, `templates/plan/plan.md:23`, …). It instructs an agent to *create*
`research/methods/<slug>/rule.md`, which succeeds and produces a layout the
convention, the lint and the INDEX all disagree with. → **task 7.3b**.

**Pilot lint baseline recorded** in `phase-3.md` per case-study §5.2 — 6 headline
caps, 1 root duplicate id (162), 15 docs missing frontmatter keys, all predating
v3. Diff against it; do not read a v3 run cold.

## What landed

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

**Phase 2b** (`9058c41`, `7c63510`, `70e1153`, `ceff9bd`, `d2bcde8` — one pathspec
commit per item) + `2d21597`, an out-of-phase blocker fix.

| Item | Landed in |
|---|---|
| T1 `scope_authored:` | `evidence.md` frontmatter block + a `####` rationale; one pointer line in `templates/CLAUDE.md.template` |
| T2 collision recovery | `citation-discipline.md` § *Repairing an ambiguous evidence id* — the negative rule, the banner's 4 required elements, `status:` unchanged |
| T3 unit-of-count | `provenance.md` Half 1, one paragraph before `Supersedes:` |
| T4 unranked = defect | `agent-teams/SKILL.md` § *Output Collection* — report-block section, the rule, consolidation step 2 |
| T5 promotion trigger | `plan-lifecycle.md` Stage 4 + **`archivist.md` step 4**, ordered before the delete step |

**T5 needed the archivist edit to be real.** Stage 4 assigns the check to the
archivist; an archivist that has never heard of it is the same defect T5 exists to
fix. Its steps were renumbered (a pre-existing duplicate `7.` fixed in passing).

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
in `deliverables/` resolves to a `#{2,3} C<n>` heading in `research/claims.md`
(**not** `## C<n>` — see the pilot review above) — and
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

**5. `CLAUDE.md` is untracked on `main`.** ⚠ **RESOLVED — verified tracked
2026-08-17** (`git ls-files --error-unmatch CLAUDE.md`); committed by `3182db8`.
A fresh clone now gets the repo's rules. No call needed; kept in place so the
stale version stays visible.

**6. The 5 over-length conventions were deliberately left alone.** Under D1 their
length is not a defect, so normalizing them would be work created by a rule that
no longer exists. `evidence.md` is now 215 lines and `provenance.md` 143.

**7. The pilot repo moved to `~/research/cordoba`** — see the warning at the top.
Cost: two failed lookups before `find ~ -maxdepth 3 -type d -name '*cordoba*'`
found it. Phase 3 depends on this repo more than any phase so far.

**8. Five convention pointers repo-wide resolve to nothing** — `data-access`,
`data-sources`, `decision-records`, `handoff-format`, `learning-capture`. v2 went
from 13 conventions to 7 + 2 and the inbound pointers were not all repathed.
**This makes task 7.3b look like one instance of a sweep, not a one-off.**
`project-conventions.md:176` is the worst single line: old framework name
(`super-claudio-research`) plus a route to `decisions/YYYY-MM-DD_<slug>.md` via
`decision-records.md` — directory and protocol both gone. **Needs a researcher
call**, because `decision-records` has no v2 successor and where a decision record
lives in v2 is a convention question, not a repath. Reproduce: `phase-2b.md`
§ *Found, not fixed*.

**9. `project-conventions.md` was a v1 file and T5 could not ship over it.** It put
project conventions at `project_conventions/` at the project root — the directory
`templates/migration/01_layout.sh:80-86` moves and `rmdir`s. T5 sends the archivist
to `.claude/conventions/project/`; a reader following T5 would take this file's
recipe and re-create a deleted directory, which is `02_repath.py`'s bug re-made by
our own new rule. Repathed in `2d21597`, path only. **The general lesson: a phase
that adds a pointer into a file inherits that file's staleness.**

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
- **Phase 2b, T2:** a first draft enumerated the five collision appearances from
  memory. The study asserts "fifth appearance" and never enumerates, so the
  breakdown was invented. Shipped text states the count plus the **three
  documented vectors** (parallel worktrees · parallel agent teams · a second
  numbering namespace). A "still correct a year later" claim about a five-week-old
  repair went in the same pass. **Both were caught by re-reading against the
  source, not by review** — when a phase file gives you a number without its
  derivation, ship the number, not a reconstruction of it.

## Queued, ahead of the remaining phases

**Deep-dive the Córdoba r2p fixes — ✅ DONE 2026-08-17.**
`context/cordoba-graduation.md` is now the **study result**, not a scoping note.
Decision record in `log.md` **D4**. Read the result file before touching Phases 3,
5 or 6; it reorders one of them.

Three things it changes:

1. **A shipped framework bug.** `templates/migration/02_repath.py` matches path
   tokens only with a trailing slash, so `Path` joins on bare segments
   (`REPO / "evidence"`) are never rewritten — docstrings get repathed, the code
   that opens the directory does not, and the report reads clean. Four dead v1
   paths survive on the pilot; two deck scripts `mkdir` their v1 target and so
   **re-create a directory the migration deleted**. Fourth defect of the
   migration-path-only class. → **G1 into Phase 6a**, plus a field note.
2. **G3 reorders Phase 3.** `lint-research.sh` is ok-or-FAIL throughout, so
   invariant 13 — already decided to be WARN in **D2** — has nowhere to live.
   **Add the WARN tier before 3.4b, not after.**
3. **Seven approved graduations**, ranked: G4 `scope_authored:`, G5 collision
   recovery, G1, G3, G2, G7, G8. **G9** is Phase 5 *input*, not a task. Six
   rejected with reasons — including **G6** on a researcher call that r2p stays
   language-agnostic, and **N1**: rules graduate, gate code does not.

**Both are now closed.** Placement: the tabled recommendation — a new **Phase 2b**
for the rule-shaped items, because *2 blocks 3* — was adopted, and Phase 2b is done
(2026-09-09, `log.md` **D5**). **N6 was rejected by the researcher on 2026-08-17**
(`context/cordoba-graduation.md:253`, `:285`) — `chart_slide_export.md` does **not**
ship as a second example project convention. ⚠ `log.md:220` and this section both
carried N6 as open for three weeks after it was decided; the study result is
authoritative.

Method note for any future pilot review: read the diffs **and run the code**.
Reading the tree is what made an earlier session call a deliberate, documented
evidence subfolder a defect; only *running* the pilot's gates showed that its
best invention has been dead since 2026-08-04.

## Next

**⚠ REVISED 2026-09-09.** **Phase 2b is done**; **Phase 3 is now the critical path
and is unblocked.**

**Read three things before writing an invariant**, in this order:

1. **The pilot repo is `~/research/cordoba`, not `~/cordoba-growth-narrative`.**
   `phase-3.md`'s lint baseline and every validation step in this plan point at
   the dead path. A "file not found" here means the path, not the finding.
2. ***Carry into Phase 3*** above — unchanged and still correct: the `#{2,3} C<n>`
   anchor, the verified `\[C[0-9]+\]` regex, `artifacts:` as a **block** list whose
   absence is legitimate, and the fact that a new invariant needs no installer edit.
3. **The order changed and the reason is mechanical.** **Task 3.0 (the WARN tier)
   comes first** — 3.3, 3.5 and invariant 13 are all written as though that tier
   exists and `lint-research.sh` is ok-or-FAIL throughout, so anything WARN-shaped
   has nowhere to live until 3.0 lands. **3.4c (invariant 14, `#nn` resolution)** is
   new and independent of 3.4b.

**Phase 2b changed what two Phase 3 invariants must check**, so do not spec them
from `phase-3.md` alone:

- **Invariant 14 (3.4c) now has a written rule to resolve against**, which was the
  whole reason 2b blocked 3. A bare `#nn` in a deliverable may point at a **renumbered**
  doc: T2 says the new doc carries `> ⚠ **Renumbered <old> → <new> on <date>.**`
  directly under its frontmatter and `(was #<old>)` on its headline. So a `#nn` that
  matches no file is not automatically broken — grep the renumber banners for
  `<old>` before reporting it. Three live examples in the pilot: 119→149, 131→150,
  139→151.
- **Invariant 1 must become recursive regardless of how decision E lands** — the
  `access_to_finance/` subdirectory (`:49`, `:80` glob non-recursively) is a
  confident PASS over an unopened directory, and T2 now names that same second-
  namespace vector in a shipped convention. The rule and the check disagree until
  this is fixed.
- **`scope_authored:` is a new optional frontmatter key.** Any invariant that
  validates the frontmatter block must not treat it as unknown — and must never
  populate it (T1: a heuristic that sets it is self-refuting).

**Still open on 3.4b (invariant 13).** Unchanged: add it per *Carry into Phase 3*
§1, or explicitly decide not to and downgrade `citation-discipline.md`'s *Gaps*
section from "proposed" to "advisory" so the file stops promising something that
isn't coming. **3.4c does not settle this** — it checks the `#nn` form, not `[C<n>]`.
The named split point is unchanged: **task 3.6**, the CLI (read
`context/installer-map.md` first).

### Needs a researcher call — carried forward

- **The stale-pointer sweep** (Surprises 8). Five dangling convention pointers, and
  `decision-records` has no v2 successor. Sizes 7.3b up from a one-off to a class.
- **Decision E** — the evidence subdirectory namespace. Phase 3 proceeds either
  way, but invariant 1 goes recursive regardless.

**Phase 6 remains available** as an independent alternative if you'd rather keep the
critical path for a fresh session. **6a shrank**: the bare-segment guard landed
2026-08-17; the duplicate-path detector and the `--upgrade` test remain.
