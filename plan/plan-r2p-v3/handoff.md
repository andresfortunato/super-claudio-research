# Handoff — plan-r2p-v3

**Session:** 2026-09-09 (Phase 3 execution) · prior sessions 2026-08-05, 2026-08-17, 2026-09-09 (Phase 2b)
**Last content commit:** `f1a8947` — **this handoff is committed on top of it**, so
`HEAD` is the handoff commit, not `f1a8947`. (A handoff cannot name its own commit;
the convention forbids fabricating it. Verify with `git log --oneline -2`.)
**Branch:** `main` · **Working tree:** clean.

## Status

| # | Phase | Status |
|---|---|---|
| 1 | Drain the field notes | **done** — 4 routes + 7 stamps, all 5 criteria verified |
| 2 | State the chain once | **done** — one shipped assumption corrected after the pilot review (**D2**) |
| 2b | Graduate the Córdoba fixes | **done 2026-09-09** — all 5 items, all 6 criteria (**D5**) |
| 3 | Lint the chain | **done 2026-09-09** — 9 tasks + invariant 1 recursive. 7 checks → 14. Two specced invariants changed shape on measurement (**D6**) |
| 4 | `/cite-check` | **next — unblocked.** **needs decision A** |
| 5 | `/pipeline-check` | **unblocked.** **needs decision C** |
| 6 | Harden the tooling | unblocked, independent of everything. **6a shrank again** — see below |
| 7 | Docs, constitution, release | blocked on 4·5·6 · **needs decision B** |

**Decisions made in-session:** invariant 9 split into FAIL/WARN halves; invariant
10 made a conjunction; invariant 13 left WARN on an expired rationale; decision
**E** landed as *permit subfolders, check them* (`log.md` **D6**). Decisions
**A**, **B**, **C** remain open, plus **one new call** — invariant 13's tier.
**D** was recommended-and-unchallenged (no `#nn → [C<n>]` script in v3).

**⚠ The pilot repo is `~/research/cordoba`**, not `~/cordoba-growth-narrative`.
Still true, still the thing that costs a session two failed lookups.

**⚠ `phase-3.md`'s §5 lint baseline was five weeks stale and is now corrected in
place.** Every number moved: 173 → 285 evidence docs, 42 → 48 claims, 6 → 64
headline-cap failures, 15 → 106 missing-frontmatter docs. **A future baseline diff
must use the `⚠ CORRECTED 2026-09-09` block, not the one above it.** The lesson
generalises past this file: a baseline measured against a live engagement decays
in weeks, so re-measure before diffing, always.

## What landed

**Phase 3** — one commit per invariant, each carrying its own fixture story.

| Commit | What |
|---|---|
| `def96b6` | **3.0** the WARN tier — `warn()`, a counter, `PASS — 2 warning(s)`, exit 0 on warnings only |
| `6535549` | **invariant 1 recursive** — one `ev_docs()` walker replaces four non-recursive globs |
| `665d6b6` | **3.1 / invariant 8** — `Rests on:` resolves (FAIL) |
| `68ce58f` | **3.2 / invariants 9 + 9b** — artifact binding, split (FAIL + WARN); also `show()`, the no-silent-caps printer |
| `2f1344a` | **3.3 / invariant 10** — evidence staleness (WARN) |
| `566e57b` | **3.4 / invariants 11, 12** — `.next-id` ahead of the corpus; bound paths exist (both FAIL) |
| `1419586` | **3.4b / 3.4c / invariants 13, 14** — `[C<n>]` and bare `#nn` resolution (both WARN) |
| `50c246c` | **3.5** report shape — three legacy outputs capped; two invariants stop vanishing when inapplicable |
| `aa6b61a` | **3.6** `r2p evidence new <slug>` — O_EXCL-locked atomic allocation |
| `bf25bbe` | gitignore the allocator lock, both installers |

**Three out-of-phase fixes**, each forced by a verification criterion in
`phase-3.md`, none discretionary:

| Commit | Found by | What |
|---|---|---|
| `a93d49d` | "green **and silent** on a fresh scaffold" | `templates/research/sources/EXAMPLE_world_bank_api.md` had no frontmatter at all → a fresh `r2p init` warned on a file it had just written |
| `91ac89d` | building 3.6, which creates docs *from the template* | a doc copied from `EXAMPLE_01_slug.md` failed invariants 5 and 12 on creation |
| `d0829ba` | 3.4b's stated condition | `citation-discipline.md` still called invariant 13 "proposed"; `evidence.md` still described invariant 9 as one check |

Plus `95e5ee8` (phase record + manifest) and `f1a8947` (`log.md` **D6**).

## Carry into Phases 4 and 5 — read before writing either skill

**1. The cheap halves all exist now, so both skills' scope shrank.** `/cite-check`
(Phase 4) and `/pipeline-check` (Phase 5) were specced when link 1 had no lint at
all. It now has two. **Do not re-implement resolution in a skill** — invariants 13
and 14 already answer *does this reference resolve*. What is left for
`/cite-check` is the row the lint explicitly cannot do:

> **a headline number with no `[C<n>]` at all.** There is nothing to resolve, so
> no grep can see it. Finding every number in a document and asking whether it is
> *yours* is the judgement walk. `citation-discipline.md` § *A number that cites
> nothing* is the rule it enforces, including the "illustrative context is exempt"
> boundary.

**2. Run the lint first and read its output.** Both skills should start by running
`lint-research.sh` rather than re-deriving what it knows. Invariant 9's FAIL list
is 14 named artifacts on the pilot; that is `/cite-check`'s worklist, already
enumerated.

**3. The regexes are settled and verified — reuse them, do not re-derive.**

| Thing | Form | Gotcha that cost a session |
|---|---|---|
| claim heading | `^#{2,3} C[0-9]+` | `^## C[0-9]+` matches **0** of the pilot's 48 claims |
| claim reference | `\[C[0-9]+\]` | rejects `[1]`, `[23]`, `[2024]`, `[c12]`, image alt-text |
| evidence reference | `#[0-9][0-9A-Fa-f]*`, then drop any token with a hex letter or >4 digits | `#5FA1C7` reads as id 5; `#266798` reads as id 266798 |
| `Rests on:` ids | ids **before the first `·`** only | the rest of the line is `**Supersedes the reading of:** #62` |
| `artifacts:` | YAML **block** list; optional; absent is normal | absent means "not stated", never "no charts exist" |
| renumber banner | `Renumbered <old> → <new>` and `(was #<old>)` | a `#nn` matching no file may still be live — check banners first |

**4. Invariant 14's ceiling is the strongest argument `/cite-check` has.**
Evidence ids are contiguous — **285 docs over 1..285, zero gaps** on the pilot —
so a transposed `#71` → `#17` resolves to the wrong doc and no version of the
check will ever catch it. Claim ids are sparse and hand-curated, so `[C99]` is
caught immediately. That is now written into `citation-discipline.md` § *Gaps* and
into the script. **Convert-on-touch buys checkability, not tidiness** — say that
in `/cite-check`, because it is the reason a researcher would bother.

**5. Phase 5 input, unchanged.** `context/cordoba-graduation.md`'s **G9** is
`/pipeline-check` input, not a task.

## Surprises

**1. The verification criteria found more defects than the tasks did.** Three
shipped defects surfaced, none by reading a diff:

- *"green **and silent** on a fresh scaffold"* → a scaffolded source doc with no
  frontmatter, which is also the worked example a researcher copies first.
- *"build the broken fixture, watch it go red"* → invariant 10's comparison was
  wrong in **two opposite directions**, and both were caught by a fixture
  misbehaving. The naive `date:` version reported the green fixture stale; the
  obvious repair (compare the doc's own last commit) silently missed a
  same-afternoon re-render because `--date=short` is day-resolution.
- building 3.6 *from* the evidence template → a doc copied from it fails
  invariants 5 and 12 on creation.

**Keep both phrasings in future phase files.** "Green" is not "silent", and an
invariant that has only ever been green is untested.

**2. The pilot fixed one of our open decisions while we were deciding it.**
`research/evidence/access_to_finance/` no longer holds evidence docs — the branch
merged 2026-08-21 and 20/21/22 became 208/209/210. Decision **E**'s live instance
is gone. The recursive fix shipped anyway: a check defends against a **vector**,
and T2 names that vector in a shipped convention. *Generalisable:* an open
decision about a live engagement can be resolved by the engagement. Re-check the
world before deciding about it.

**3. Invariant 13's tier was resting on another invariant's evidence.** D2 made it
WARN because "573 targets". Those are bare `#nn` — invariant 14's population — and
14 did not exist when D2 was written. Invariant 13's real population on the pilot
is **zero**. Left WARN; **needs a call**. *Generalisable:* when a decision cites a
number, re-check that the number still describes the thing being decided.

**4. `upgrade.js`'s `REQUIRED_GITIGNORE_LINES` still held v1 paths.**
`internal_docs/` and `literature/`, renamed by v2 to `reference/internal/` and
`reference/literature/`. `init` has been right all along. So an upgraded project
appends two directories that do not exist and never starts ignoring the two that
do — and the block's own comment says those are ignored because they are large and
often copyrighted. **A researcher who upgraded rather than re-initialised has been
committing third-party PDFs.** Fixed in `bf25bbe`, `reference/external/` added too.
Fourth sighting of the two-installer trap, fourth time only in the `--upgrade` half.

**5. Nothing had ever read `.next-id`.** Worth restating because the fix is
measured: 10 concurrent `r2p evidence new` calls produce 10 distinct ids; with the
lock disabled as a negative control, the same 10 produce **8 docs** — two ids
handed out twice, the losers saved only by the doc write also being `wx`.

**6. The lint takes ~9s on the pilot and ~8.9s of that predates Phase 3.** The
per-doc loop spawns ~6 subprocesses across 285 docs. Not a regression, not in the
task list, untouched. But a nine-second linter is an adoption risk by exactly the
reasoning that produced the WARN tier. **Phase 6 candidate**, and cheap: one awk
pass per doc instead of six.

## What didn't work

Nothing abandoned. Two authoring errors, both caught by running rather than reading:

- A `sed` "fix" to a message string introduced a **backtick inside a double-quoted
  bash string**, so `artifacts:` ran as a command. Visible only in a live run; the
  diff looked like a wording change.
- Invariant 9's first implementation ran one `grep -r` per referenced path — 67
  recursive greps over 285 docs, 9s on its own. Replaced with a single
  `grep -rhoFf` pass. **A check nobody waits for is a check nobody runs.**

## Next

**Phase 4 (`/cite-check`) is the critical path and is unblocked**, but it
**needs decision A** and its scope has changed — read *Carry into Phases 4 and 5*
§1 before opening `phase-4.md`, which was written when link 1 had no lint at all.

**Phase 6 remains the independent alternative** if you would rather keep the
critical path for a fresh session. **6a shrank again**: the bare-segment guard
landed 2026-08-17, and this session's `bf25bbe` fixed the stale-EXCLUDE-adjacent
gitignore defect. What remains there is the duplicate-path-per-line detector, the
`--upgrade` integration test, and now the lint's runtime.

### Needs a researcher call — carried forward, one new

- **✚ NEW — invariant 13's tier.** WARN on an expired rationale (see Surprises 3).
  Promoting it to FAIL is a one-word change and the cheapest remaining hardening
  of link 1. Population on the pilot is zero, so it cannot cry wolf.
- **The stale-pointer sweep** (`log.md` **D5**). Five dangling convention pointers
  — `data-access`, `data-sources`, `decision-records`, `handoff-format`,
  `learning-capture`. **`decision-records` has no v2 successor**, so where a
  decision record lives in v2 is a convention question, not a repath. Sizes 7.3b
  up from a one-off to a class. Reproduce: `phase-2b.md` § *Found, not fixed*.
- **Decision A** (Phase 4), **B** (Phase 7), **C** (Phase 5) — unchanged, each
  reversible within its phase, each with a recommendation in `plan.md`.

### Adjacent one-liners, deliberately not shipped

Both are inside link 2 and cost one `grep` each. Left out because they are not in
any phase's task list, and a phase that grows its own scope stops predicting
anything. **Either would be a legitimate Phase 6 addition.**

- `claims.md` says *"a claim with no ids is an assertion — delete it."* Nothing
  checks it.
- A dangling `**Supersedes the reading of:** #62` is a broken link. Invariant 8
  reads only the ids before the first `·`, so it does not see it.
