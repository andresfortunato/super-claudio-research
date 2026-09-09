# Log — plan-r2p-v3

Direction changes and dead ends. Appended, never rewritten. `plan.md` stays
stable unless the researcher approves a change; each entry below records one that
they did.

---

## D1 — 2026-08-05 · Principle 5's line budgets are dropped

**Raised during:** Phase 1, on discovering that all four of its routes landed in
files the phase's own constraint said were near a ≤120-line ceiling.

**What was found.** Phase 1's constraint quoted destination sizes in **KB** but
stated the limit in **lines**, so the headroom it assumed did not exist. Measured
in lines, **5 of 8 conventions already breached the limit before this plan ran**
(`evidence.md` 146, `methods.md` 144, `plan-lifecycle.md` 214,
`project-conventions.md` 185, `source-registry.md` 184). Three further facts
decided it:

1. **The cap was never in principle 5's body.** The body prescribed 80–120 lines
   for *CLAUDE.md*, because CLAUDE.md is loaded every session. The ≤120-line
   *protocol* cap existed only in the checkable-questions table, which applied the
   CLAUDE.md number to a different object.
2. **Nothing enforced it.** The only mechanical `120`s in the repo are unrelated —
   `lint-research.sh`'s 120-**character** INDEX headline cap and
   `retrieve-learnings.sh`'s own `MAX_LINES`.
3. **The mechanism the principle protects was never at risk.** Conventions are
   read *on demand*; the always-loaded budget is CLAUDE.md, which is 38 lines in
   this repo and 107 in `templates/CLAUDE.md.template`.

By the framework's own codification test — *a prescribed format with 10%
compliance is wrong, not disobeyed* (case study §6.6) — a rule at 37% compliance
in r2p's own repo is wrong rather than disobeyed.

**Researcher's decision.** Drop the rule, and **leave the length of CLAUDE.md to
the user.** Broader than the four options offered: not only is the protocol cap
removed, the framework stops prescribing CLAUDE.md's length at all. It is the
researcher's file.

**What changed, and why it landed out of phase.** The constitution's own rule is
that a revision is explicit and lands *before* the addition that depends on it.
Phase 2 creates `citation-discipline.md` and its spec said "≤120 lines", so the
edit could not wait for Phase 7.

| File | Change |
|---|---|
| `docs/audience-and-philosophy.md` | principle 5 body: line budgets removed, dated revision note explaining why; questions-table row now tests *shape* (is the rule in the convention file, with only a pointer in CLAUDE.md?) with no numbers |
| `docs/extending.md` | "Length target: 50–120 lines" → split-on-the-trigger test, no number |
| `phases/phase-1.md` | constraint marked `⚠ CORRECTED`, kept visible as the wrong version |
| `phases/phase-2.md` | both `≤120 lines` criteria marked `⚠ CORRECTED` and voided |
| `plan.md` | File Manifest line for `citation-discipline.md` |

**Deliberately not done.** The 5 over-length conventions are left exactly as they
are — under the new principle their length is not a defect, so "fixing" them would
be work created by a rule that no longer exists. `evidence.md` (187) and
`provenance.md` (135) keep Phase 1's additions.

**Still open, for Phase 7.** `docs/project-conventions-mechanism.md:49–50` cites
"Principle 5 (Short CLAUDE.md)" as a token-cost argument. That file is one of the
stale v1 mechanism docs already pending **decision B**; the citation is now one
step more stale. Fold it into whatever B decides rather than patching it twice.

---

## D2 — 2026-08-05 · Pilot-repo review corrects a shipped Phase 2 assumption

**Raised by:** a review of `~/cordoba-growth-narrative` (v2 layout, 173 evidence
docs, 42 claims, 10 worktrees) asking what the pilot does that the framework
doesn't follow.

**The correction.** `claims.md` specified the claim heading as `## C<n>` **and**
said to group claims under `##`-level narrative sections. Both cannot hold. The
pilot resolved it by demoting claims to `###` — its 42 claims all sit at
`### C<n>` under six `## §N` sections. Phase 2 shipped `citation-discipline.md`
assuming `## C<n>`, so **a checker built to that spec would report zero claims on
a full 42-claim ledger**: a false all-clear, which is strictly worse than a false
alarm. Fixed in both conventions — resolution now matches `^#{2,3} C[0-9]+`.

This is §6.6 (*the emergent format is the specification*) catching a defect one
release after the case study named the lesson.

**What else the review measured, and where each landed:**

| Finding | Landed |
|---|---|
| 573 bare `#nn` refs, 0 claim refs across 3 memo drafts, against 42 existing claims | `citation-discipline.md` § *Adopting this on a project that already cites evidence directly*; new **Decision D** |
| invariant 13 as FAIL would be unusable mid-adoption | `phase-3.md` ⚠ ADDED — write it WARN, print counts, no silent caps |
| claims at `###` breaks any `^## C` anchor | `phase-3.md` ⚠ ADDED — match `^#{2,3} C` |
| invariant 11 already passes on the pilot (id 173, `.next-id` 174) | `phase-3.md` ⚠ ADDED — will not self-demonstrate there |
| pilot still runs `check-evidence.sh`, wired in `settings.json`; no `check-archival.sh` | `phase-6.md` 6d ⚠ ADDED — upgrade gains an orphaned-hook warning + test asserts it |
| `--upgrade` warns about obsolete `skills/` and stale EXCLUDEs but **never** about orphaned hooks | same |
| pilot `CLAUDE.md` still lists `.claude/skills/` and "a Stop hook" | `phase-6.md` 6d ⚠ ADDED — noted, out of scope, warning is the cheap fix |

**Checked and found already correct — no action:** the `_inbox/` staging rule was
already promoted into `templates/CLAUDE.md.template`; the pilot is fully on the v2
layout; all its CLAUDE.md convention pointers resolve; project-local
`.claude/skills/` is correctly absent (skills live in `~/.claude/skills/`, which
symlinks to this repo, so framework skill edits reach installed projects
immediately).

**Deliberately not done.** The pilot's own remediation — converting 573 references,
filing the three missing evidence docs — remains out of scope per *Open Items
Deferred*. This entry changes the framework, not the pilot.

---

## D3 — 2026-08-05 · `research/` folder grouping: what the pilot proves

**Raised by:** a follow-up review of how `~/cordoba-growth-narrative` groups
folders inside `research/`.

**Mostly the convention is being followed, and that is the finding.** `methods/`
is 37 flat `<topic-slug>.md` files plus `_adjuncts/<topic>/` — exactly
`methods.md:35` and `:46`. `sources/` is flat files plus per-source companion
dirs. `claims.md`, `wiki/` as specified. The v2 layout survived six months of
contact without drifting.

**The one divergence is `research/evidence/access_to_finance/`** — a tracked
thematic subfolder holding three evidence docs, a `charts/` dir and a memo.

⚠ **CORRECTED 2026-08-05, same day.** This entry first called it "broken in three
ways." That was wrong, and written before reading the folder's own README. The
subfolder is **deliberate and documented**: the docs came from another branch
whose ids 20/21/22 were already taken here, and renumbering them would have
broken the byte-identical diff against their source. The ids are namespaced on
purpose.

What survives the correction is one real defect: `lint-research.sh` **cannot see
them** — its uniqueness check globs `"$EV"/[0-9]*_*.md` (`:49`, same shape `:80`),
which is non-recursive, so it returns a confident PASS over a directory it never
opened. The three docs are also absent from `INDEX.md`.

`evidence.md:17` gives the flat path but never forbids subdirectories, and at 173
docs the pressure to group is real — so this recurs unless it is decided. **New
decision E** in `plan.md`: *recommend forbidding subfolders and making invariant 1
recursive*, because `NN` is the project-wide key `claims.md`, every deliverable and
`.next-id` all resolve against, and a subfolder hands a doc a second numbering
namespace. Thematic grouping is what frontmatter scope keys and `claims.md`
sections already provide. **This is the evidence-id collision recurring a fourth
time**, via a vector `.next-id` cannot defend against.

**Second finding: the v1 methods path is still live in eight files** that an agent
acts on — `planning/SKILL.md` ×3, `planning/references/multi-session.md` ×2,
`implementation/SKILL.md:37` (which contradicts its own `:64` and `:148`),
`implementation/references/escalation-reference.md`, `templates/plan/plan.md:23`,
`templates/plan_dir/archive/README.md:21`. Worse than a dangling reference: it
instructs an agent to *create* `research/methods/<slug>/rule.md`, which succeeds
and silently produces a layout the convention, the lint and the INDEX all
disagree with. → **new task 7.3b**.

**Third: a measured lint baseline for the pilot** is now recorded in `phase-3.md`
(§5 of the ⚠ ADDED block), per case-study §5.2. Today it FAILs on headline caps
(6 rows), one root-level duplicate id (162), and 15 docs missing frontmatter keys.
Any v3 lint run must be diffed against that, not read cold.

---

## D4 — 2026-08-17 · The Córdoba graduation study: 7 approved, 6 rejected, 1 framework bug

**Raised by:** executing the queued deep-dive in `context/cordoba-graduation.md`.
Full account there — that file is now the study **result** and supersedes its own
scoping note. This entry records only what changes direction.

**Method mattered.** The scoping note said read the diffs, not the tree. The
sharper rule is **run the code**: the two hardest findings are invisible in a
diff and only appear when the pilot's gates are executed.

**A shipped framework bug with a live victim.**
`templates/migration/02_repath.py` matches path tokens only with a trailing
slash, so `Path` joins on bare segments (`REPO / "evidence"`) are never
rewritten. Docstrings get repathed, the code that opens the directory does not,
and the report reads clean — 571 rewrites, 559 files, guard clean. **Four dead
v1 paths survive on the pilot**, two of them worse than a crash: the deck render
scripts `mkdir(parents=True)` their v1 `slides/` target, so running one chart
script **re-creates a directory the "26 dirs → 8" migration deleted** and exits
0. This is the **fourth** defect of the class `CLAUDE.md` names — visible only on
the migration/upgrade path, never to an `init` test. → **G1, Phase 6a**, plus a
field note.

**The pilot's best invention is dead and nobody noticed.** `gate_coverage.py` —
the coverage gate that found a load-bearing memo exhibit with no evidence doc —
crashes today, killed by that repath miss two days after the migration. The
generalizable half is the *second* bug: reading a `defaultdict(list)` key
auto-vivifies it, so the later `if n not in by_num` test answers "resolved" for
ids that only ever existed because they were looked at. **A membership test
against a `defaultdict` is not a membership test**, and it converted a loud
failure into a cryptic one. **Direction consequence: rules graduate, gate code
does not** (N1) — a plan-local gate has no owner once the plan closes.

**Seven approved, in rank order:** G4 `scope_authored:` (a truthfulness flag on
the frontmatter block — resolves the hand-author-or-omit binary at
`evidence.md:144` into a third option), G5 collision **recovery** into
`citation-discipline.md` (which today greps clean for the whole topic; the
renumber-plus-banner held, the inline disambiguator **rots**), G1, G3 the lint's
missing **WARN tier**, G2 `#nn` resolution, G7 a counting script's header states
its unit, G8 an unranked fan-out output is the defect.

**G3 reorders Phase 3.** `lint-research.sh` is ok-or-FAIL throughout; invariant
13 was already decided to be WARN (D2) and **has nowhere to live**. G3 must
precede 3.4b. The pilot reached the same conclusion independently and wrote the
reason in the file — *rather than ship a test that misreports*.

**G6 rejected on a constitutional call (researcher, 2026-08-17): r2p stays
language-agnostic.** The two-language finding was real and measured, but encoding
it would put a language assumption in the core. It costs nothing: G6's only
language-independent part — a short-token heuristic classifier misreports, so
print and ask rather than fail — is exactly what **G3** ships.

**The meta-finding is the cheapest item here.** `project-conventions.md` says how
to write a project convention and where it lives, but **never when a plan's
by-product becomes one**. Measured: 3 of the pilot's 9 reusable rules reached
`.claude/conventions/project/`; 6 are still in a closed plan's directory. That is
case-study §6.8 recurring one layer below where Phase 1 just fixed it. → one rule
in `plan-lifecycle.md` Stage 4, checked by the **archivist**, which already runs
there.

**Not decided here:** placement in `plan.md` (recommendation tabled at the end of
`context/cordoba-graduation.md` — a new **Phase 2b** for the rule-shaped items,
because *2 blocks 3*), and **N6**, whether `chart_slide_export.md` ships as a
second example project convention.

> **Both closed since.** N6 was **rejected the same day** by the researcher
> (`context/cordoba-graduation.md:253`, `:285`) — this paragraph was left stale.
> Placement was adopted as written; Phase 2b shipped 2026-09-09 (**D5**).

---

## D5 — Phase 2b executed; one out-of-phase fix; a stale-pointer class surfaced (2026-09-09)

All five graduated items landed as specced, all six criteria verified by command,
all constraints held. Commits `9058c41` `7c63510` `70e1153` `ceff9bd` `d2bcde8`,
one per item, by pathspec. **Not a direction change** — logged because three
things below alter what a later session should believe.

**1. The pilot repo moved: `~/cordoba-growth-narrative` → `~/research/cordoba`.**
Every pilot-facing path in `handoff.md`, `phase-3.md` (lint baseline) and
`context/cordoba-graduation.md` is dead as written. Phase 3's whole validation
story runs against that repo, so this would have cost a session otherwise.

**2. Criterion 6 earned its place, and should be copied.** Writing T2's banner
spec *from the shipped artifact* and then checking the artifact against the spec
caught three things a from-memory spec would have shipped wrong — `(was #NN)`
lives on the frontmatter `headline:` key rather than the H1; the pilot set
`status: revised` on docs that retracted nothing, so T2 rules `status` unchanged
and flags the pilot's choice in a parenthetical rather than in the spec (which
keeps criterion 6 resolvable); and T1's field is already in production on
149/150/151, comment and all. **The pattern generalizes: when a phase graduates a
pilot artifact, make the artifact the spec's test, not its inspiration.**

Corollary, learned the hard way in the same task: a first draft of T2 enumerated
the five collision appearances from memory and got the breakdown wrong — the
study asserts "fifth appearance" and never enumerates. Shipped text states the
count plus the **three documented vectors**. A "still correct a year later" claim
about a five-week-old repair was cut in the same pass.

**3. One out-of-phase commit, `2d21597`, and it was not optional.**
`project-conventions.md` still put project conventions at `project_conventions/`
**at the project root** — v1, 9 occurrences, in the one file that tells an author
how to write one, while `templates/migration/01_layout.sh:80-86` moves that
directory to `.claude/conventions/project/` and `rmdir`s it. T5 sends the
archivist to the v2 path; an agent following T5 would read this file's recipe and
**re-create a directory the migration deletes** — `02_repath.py`'s bug, the one
G1 had just fixed, re-manufactured by our own new rule. Path only; the rest of
that file's v1 residue was left alone deliberately.

**New, needs a researcher call — a stale-pointer class wider than 7.3b.** Five
`.claude/conventions/*.md` pointers repo-wide resolve to nothing:
`data-access`, `data-sources`, `decision-records`, `handoff-format`,
`learning-capture`. v2 consolidated 13 conventions into 7 + 2 and the inbound
pointers were not all repathed — same class as **7.3b** (v1 methods path in eight
files), which suggests 7.3b is one instance of a sweep rather than a one-off.
`project-conventions.md:176` compounds it: it still says
**"super-claudio-research"** and routes methodology calls to
`decisions/YYYY-MM-DD_<slug>.md` via `decision-records.md` — a directory and a
protocol that both no longer exist.

Not fixed here because it is not a repath. Three of the five plausibly map onto
renamed survivors, but **`decision-records` has no v2 successor**, and deciding
where a decision record lives in v2 is a convention question. Reproduce with the
one-liner in `phases/phase-2b.md` § *Found, not fixed*.

---

## D6 — Phase 3 executed; two specced invariants changed shape on measurement (2026-09-09)

**Phase 3 is done.** Nine tasks plus the recursive fix to invariant 1, one commit
per invariant, every one seen red against a built fixture first. `lint-research.sh`
goes from 7 checks to 14, and `.next-id` acquires the first tool that reads it.

Full record in `phases/phase-3.md` § *Execution notes*. This entry holds only the
decisions, because they change what a later phase may assume.

### 1. Invariant 9 ships as two checks. **Decided; reversible in one commit.**

Specced as one FAIL — an artifact used in `deliverables/` that no evidence doc
lists under `artifacts:`. Measured against the pilot, that is **67 of 67**, and
the reason is structural rather than a data-quality problem: **zero** evidence
docs carry an `artifacts:` key, because the key shipped in Phase 2 of *this plan*.
On every project that predates v3, every reference is unbound by construction.

A FAIL whose count equals "every chart the project ever drew" on upgrade day is
the failure mode this plan already legislated against twice — Decision 2's
grading, and D2's ruling that invariant 13 be WARN. `check-evidence.sh` died of it.

Splitting on *does any evidence doc mention this path at all* separates the two
populations cleanly, 14 / 53 on the pilot:

- **9 (FAIL), 14 hits** — the chart appears **nowhere** in `research/evidence/`.
  This is the audit's actual finding: a headline number with no evidence doc,
  invisible for six months. True regardless of adoption.
- **9b (WARN), 53 hits** — an evidence doc discusses the chart but has not listed
  it. An adoption meter that converges to zero under convert-on-touch.

The phase's intent survives: the three-missing-docs check is a `test -f` and it
FAILs. What is avoided is the cliff where the first person to adopt the key
inherits 66 failures.

### 2. Invariant 10 compares a conjunction. **Decided; not reversible cheaply.**

Specced as *newest commit touching an `artifacts:` path is newer than the doc's
`date:`*. That compares a commit timestamp against a hand-authored measurement
date, and the **green fixture — doc and chart in one commit — reported itself
stale.** Every project would have warned on every doc the day it adopted the key.

The obvious repair, comparing the doc's own last commit instead, has the mirror
flaw: a typo fix after a re-render masks the staleness. So it requires both — the
artifact moved after the doc last moved *and* after the date the doc claims. The
field-note case satisfies both; authoring-to-commit lag satisfies neither.

Commit-vs-commit compares `%ct` seconds, not `--date=short`. At day resolution a
chart re-rendered the same afternoon compares equal, and the fixture that should
have been red came back green. **Both halves were found by a fixture misbehaving,
not by reasoning** — which is the argument for the phase's see-it-red rule.

### 3. Invariant 13's recorded rationale has expired. **Left WARN. Needs a call.**

D2 made invariant 13 WARN because it had **573 targets**. Those 573 were bare
`#nn` — which is invariant **14's** population, and 14 did not exist on
2026-08-05; it was added 2026-08-17 (D4/G2). Measured today, invariant 13's
population on the pilot is **zero**.

So the tier no longer rests on the argument that produced it. An unresolvable
`[C<n>]` is as mechanical as invariant 8, which is FAIL, and unlike 14 it has no
legacy population to drown in.

**Left WARN**: it honours the recorded decision, and WARN → FAIL is a one-word
change while the reverse costs a release. **Flagged for the researcher** —
promoting it is the cheapest remaining hardening of link 1.

### 4. Decision E's live instance closed itself. Invariant 1 went recursive anyway.

`research/evidence/access_to_finance/` no longer holds evidence docs. Its README
records that the `access-to-finance` branch merged on **2026-08-21** and ids
20/21/22 were promoted to 208/209/210; what remains is a frozen provenance
snapshot of charts and a memo. The three invisible collisions are gone, and not
because anyone acted on E.

The recursive fix ships regardless, and E lands as *permit subfolders, check them*.
A check defends against a **vector**, not an instance, and T2 now names that vector
— a second numbering namespace — in a shipped convention. Until this commit the
rule and the check disagreed. Unique `NN` project-wide stays non-negotiable.

### 5. What the phase found that no one was looking for

**Three template/convention defects, each surfaced by a verification criterion
rather than by review.** A doc copied from the shipped evidence template failed
invariants 5 and 12 on creation — the `## Measured` guidance comment spells out
the verdict words the check greps for, and the `artifacts:` example shipped as
live YAML pointing at placeholder paths. A fresh `r2p init` warned on a source
example that had no frontmatter at all. And `upgrade.js`'s
`REQUIRED_GITIGNORE_LINES` still held the v1 paths `internal_docs/` and
`literature/`, so an upgraded project never starts ignoring
`reference/literature/` — it has been tracking third-party PDFs.

That last one is the two-installer trap CLAUDE.md names, found for the fourth
time, and again only in the `--upgrade` half.

**The generalisable lesson: the verification criteria found more than the tasks
did.** "Green *and silent* on a fresh scaffold" and "build the broken fixture,
watch it go red" each surfaced a shipped defect that no amount of reading the
diff would have. Keep both phrasings in future phases.

### 6. Measured, not fixed

`lint-research.sh` takes **~9s on the pilot, of which ~8.9s predates this phase** —
the per-doc loop spawns ~6 subprocesses across 285 docs. Not a regression and not
in the task list, so untouched. But a nine-second linter is an adoption risk by
exactly the reasoning that produced the WARN tier. **Phase 6 candidate.**

## D7 — Two researcher calls answered; Phase 4 done (2026-09-09)

Both calls the previous handoff carried forward were put to the researcher and
answered in one exchange. Both were taken as recommended, so nothing downstream
moves. **Decisions B and C remain open**, blocking Phases 7 and 5.

### 1. Invariant 13 is promoted to FAIL. **Answered: promote.**

Recorded in **D2** as WARN, on the grounds that a FAIL would drown a real
project in **573 references**. Those 573 are bare `#nn` — invariant **14**'s
population — and 14 did not exist when D2 was written. Invariant 13's own
population on the pilot is **zero**.

So the volume argument that keeps 14 at WARN permanently never applied to 13 at
all, and what is left is a check as mechanical as invariant 8, which is already
FAIL. Claim ids are sparse and hand-curated: an unresolvable `[C<n>]` is a typo
or a claim nobody wrote, never a conversion backlog.

**What it blocks, deliberately:** writing `[C50]` in a draft before C50 exists in
the ledger now fails the run. That is the order `citation-discipline.md` § *A
number that cites nothing* already requires — the citation is what forces the
claim, which forces the evidence doc. Naming it in the script comment matters,
because the next person to hit it will read it as the check being wrong.

Verified in both directions on an isolated fixture. **The first fixture was red
for two unrelated reasons** — missing `headline:`/`confidence:` and a missing
`.next-id` — which would have read as confirmation while proving nothing. A
fixture is only a test once it is green-except-one. Commit `34b77af`.

*Generalisable, and now written into the script's tier-selection header: a tier
chosen on a measured count is only as good as the count. Re-measure before
citing one back, including a count you took yourself last session.*

### 2. Decision **A** — `/cite-check` is its own skill. **Answered: own skill.**

As recommended in `plan.md`. `/verify`'s contract is 3–5 judgement checks on one
artifact; the chain walk is mechanical and sweeps a whole document. Same ≤2k
tier, different shape. The boundary is now written into `/verify` itself (4.3) —
unstated, the two drift into overlapping and the one remembered second stops
being run.

### 3. Phase 4 shipped smaller than specced, and that was the plan working

`phase-4.md` was written when link 1 had no lint at all. Phase 3 shipped
invariants 13 and 14 in between, so `/cite-check` does **not** reimplement
resolution — it runs `lint-research.sh` first, reads its output, and spends its
budget on the three classes no grep can see. The handoff's *Carry into Phases 4
and 5* §1 is what made this cheap; it is worth writing that section again.

### 4. The fixture changed two things the diff could not show

Same pattern as D6 §5, third phase running. Commit `703821f`.

- **The refuse-early rule refused the fixture.** It had inherited
  `/deliverable-review`'s ≥800-word floor, and the fixture is a *finished*
  127-word memo. That floor exists because a seven-lens fan-out is too expensive
  to spend on a stub; a ≤2k check has no such excuse, and short is exactly the
  shape of a ministerial briefing note. **Refuse on draft markers, never on
  length.** Copying a neighbour skill's precondition without its reason is the
  general form of this bug.
- **Added a *Not flagged* section to the report.** Without it a reader cannot
  tell an exemption from a miss. This is 3.5's rule for inapplicable invariants —
  silence reads as a pass — arriving independently from the other side, which is
  some evidence it is a real rule and not a local fix.

**The fixture is also the argument for the skill.** `lint-research.sh` prints a
clean PASS on it — every `[C<n>]` resolves, every `#nn` resolves — while the memo
carries an uncited 11.4%, an 18% citing `#1` directly, and a `[C20]` resting on a
retired doc whose live replacement revises 6% to 2%. A green lint and three real
defects in the same document is the clearest statement of what link 1's expensive
half is for.

### 5. Noted, not built

**A claim resting on `status: retired` evidence is fully mechanical** and could be
invariant 15. It sits in `/cite-check` because `phase-4.md` put it there, and
Phase 4 does not get to grow into `lint-research.sh`. **Phase 6 candidate**,
alongside the two one-liners the previous handoff already lists.

## D8 — Decisions B and C answered; Phase 5 shipped; the constitution amended first (2026-09-09)

Both remaining open decisions were answered, **both against the recommendation
on file.** Neither reversal was cosmetic — C forced a constitution amendment
before any code landed, and B inverted which follow-up work Phase 7 owns.

### 1. Decision **C** — `/pipeline-check` runs the script directly

Recommended: report-and-hand-over, execute only on a second confirmation.
**Answered: run it directly.** The reasoning that makes it right is that
reporting staleness and printing a command makes the researcher a copy-paste
relay for a decision the check has already made — the only useful response to
"this chart is older than the data under it" is to re-render the chart.

**The constitution was amended before Phase 5 landed** (`c7543f5`), per
CLAUDE.md: a change that fails a principle revises the document explicitly,
first. Principle 7 graded verification by **token cost** (zero / ≤2k / ≤12k) and
all three shipped tiers were read-only. That read-only posture was never a
stated principle — it was a coincidence of the first three tiers all being
*review* tools. Principle 7 now carries a second axis (side-effect cost:
read-only / derived / source) and four bounds: re-runs existing inspectable code,
writes only script-declared `Outputs:`, stays user-invoked, reports what it ran.
A proposal wanting to write *source* files does not inherit this and revises the
document again.

*Note the constitution's binding table already anticipated this* — "does it fit
the cost tier, **or invent a new one with reason?**" The amendment is an
extension of principle 7, not a reversal of it, and saying so accurately matters:
overstating a decision as a constitutional violation is its own kind of drift.

### 2. Decision **B** — delete the 14 `docs/*-mechanism.md` files

Recommended: move to `docs/v1/` with a README. **Answered: delete.**

**This transfers work to Phase 7 rather than removing it.** The recommendation's
argument was that `docs/v2-case-study-cordoba.md` cites those files; deleting
them makes those citations dangle, which is the same defect class as the pointer
bugs below. **Phase 7 must audit and repoint or drop every reference in the same
commit as the deletion.** A phase that deletes 2,695 lines and leaves the
citations is not done.

### 3. The pointer inventory is larger than D5 recorded, and D5 was wrong about it

D5 listed **five** dangling convention pointers and said **`decision-records`
has no v2 successor**, which is what escalated the sweep from a repath to a
convention-design question needing a researcher call.

**That is wrong.** `methods.md` line 1 reads *"Methods — Protocol (v2, absorbs
decision-records and learning-capture)."* Every dead name has a known home; the
v2 conventions carry their own merge history in their titles. Measured:

| Dead pointer | v2 home | Cited from |
|---|---|---|
| `script-header.md` | `provenance.md` | `docs/verification-architecture.md:53`, `docs/r2p-adopt.md` ×4 |
| `analytical-commit-format.md` | `provenance.md` | `docs/verification-architecture.md:54`, `docs/r2p-adopt.md:516` |
| `data-sources.md` | `sources.md` | **`.claude/conventions/project-conventions.md:26`**, `docs/audience-and-philosophy.md:99` |
| `data-access.md` | `sources.md` | **`templates/.env.example:7`** — ships into every project |
| `handoff-format.md` | `plan-lifecycle.md` | **`.claude/hooks/precompact-handoff.sh:36`** |
| `learning-capture.md` | `methods.md` | **`.claude/hooks/precompact-handoff.sh:40`** |
| `decision-records.md` | `methods.md` | **`.claude/conventions/project-conventions.md:179`** |

**Seven, not five, and three of the citing files are shipped runtime surfaces**
rather than docs: a live convention, a template that installs into every project,
and a hook. `precompact-handoff.sh` is the worst — it fires automatically when a
session's context fills and directs the session to read two convention files that
do not exist, in every installed project. It went unnoticed because **a pointer
to a missing file fails silently**: the session simply does not get the guidance
and nothing errors.

*Generalisable, and the second instance this plan has hit:* **a dangling pointer
is invisible by construction.** Invariant 8 exists because a dangling `Rests on:`
id has no symptom; this is the same failure one layer up, in the framework's own
files, and nothing checks it. **A convention-pointer resolver is a strong Phase 6
candidate** — it is one `grep` against `ls .claude/conventions/`.

### 4. Phase 5 shipped, and direct execution created a hazard the spec did not have

`phase-5.md` was written assuming report-and-hand-over. **A re-run overwrites the
artifact in place**, so the default posture change introduces a way to destroy
work that the specced design could not.

**The fix is a precondition, not a warning: the tree must be clean for every path
the run will write, or the skill refuses.** Git is the undo, and an uncommitted
artifact has none. Verified both ways — a hand-edited uncommitted output is
refused and survives intact; the same check permits the run once committed.

### 5. G9's ruling held, and implied something the phase file did not anticipate

G9: *the correct granularity is not the finest.* Date-only screams when
`git checkout` rewrites mtimes; date-plus-content was already proved noise
because bare years match anything. So the skill compares **numbers**, not bytes
and not timestamps — and invariant 10 already embodies this, comparing commit
timestamps rather than mtimes, which is why `--stale` is a pure reuse.

**The consequence: an image-only script is a `cannot compare`, not a pass.** The
numbers in `## Measured` are not recoverable from a PNG, and byte-diffing an
image reports every palette change as a finding. Look upstream for a numeric
intermediate; report `cannot compare` if there is none. **Never report
"unchanged" because a chart merely re-rendered** — that is a false green on
exactly the artifact class the pilot's real failure involved.

## D9 — Phase 6 executed at full scope; five checks found five live defects nobody had listed (2026-09-09)

**Researcher decisions taken this session, both at the top:**

1. **Scope: all six candidates**, not the ranked top five. The four original
   6a–6d items and the five new ones all landed.
2. **Invariant 15's tier: split by citing surface** — FAIL for a shipped runtime
   surface, WARN for documentation — and the runtime-surface rows fixed in the
   same commit rather than deferred to Phase 7, so FAIL is green immediately.

### 1. Execution order was changed on a measurement, before any code

The handoff ranked the runtime fix third. It was executed **first**, because the
other four new candidates add checks to `lint-research.sh` and the cost being
removed is per-document: `find` re-running on each of ten `ev_docs` calls,
`ev_id` spawning three processes per doc inside four loops, `ev_artifacts`
spawning an awk per doc from three invariants. Roughly 3,400 processes to build a
list of numbers that cannot change during a run. Adding four checks first would
have multiplied that into four more places.

**Re-measuring first also corrected the number.** The record said ~9s; it was
**11.0s**. Now 2.26s with 18 checks instead of 14.

**The performance commit was held to byte-identical output** on the pilot, on
this repo, and on a purpose-built fixture — and the fixture was necessary, not
belt-and-braces: the pilot has zero `artifacts:` keys, so invariants 9b, 10 and
12 are invisible to a pilot diff, and those are the three the commit changed most.
A green diff there would have proved nothing about them.

Two behaviour changes were deliberately **excluded** from that commit and made in
the next one, where the delta could be stated: invariants 4 and 5 each owning one
defect. Invariant 4 reported 11 findings on the pilot and all 11 were invariant
3's — a `break` exits the `for` over keys, not the `while` over docs, so a doc
with no `id:` key fell through to an id comparison that compared nothing to 252
and called it a mismatch. Invariant 5 was skipping all 45 pre-frontmatter docs
for a check that has nothing to do with frontmatter.

### 2. The point of a mechanical check is that the hand-built list is wrong

**D5 recorded five dangling pointers. The last handoff recorded seven. Resolving
every pointer found ten in this repo and seven in the pilot, and the two sets of
seven were not the same seven.** The hand-built inventory had missed
`insights-logging.md`, `brainstorm-format.md`, `evidence-logging.md` and
`plan-structure.md`. An inventory of invisible defects is itself incomplete —
which is the whole argument, stated twice now and finally acted on.

**Widening the target pattern was nearly free and found four more.** Scoping it
to `.claude/conventions/` was arbitrary; a `docs/<name>.md` pointer dangles just
as silently. And the generalisation is what makes Phase 7's deletion safe: the
moment a `docs/*.md` file is removed, every pointer at it becomes this defect.

**Widening the *citing* set was the opposite.** A first pass read everything and
reported 22 findings on the pilot, mostly the researcher's own prose. Those are
broken links in somebody's writing, a different population, and mixing them in is
how a WARN tier teaches people to ignore it. **A check's precision lives in which
files it reads, not in what it looks for.**

### 3. In three of four cases the dangling pointer was not the defect

It was a thread attached to a live v1 instruction underneath:

- **`precompact-handoff.sh`** named two conventions gone since v2 — and around
  them still told every session to write learnings to `learnings/<slug>.md` plus
  an `index.yaml` row. Neither exists in v2, and `retrieve-learnings.sh` *was*
  correctly migrated to glob `triggers:` across `research/methods/`. So the hook
  has been routing learnings to a directory the retrieval hook does not read, in
  every installed project, since v2.
- **`learning-capture/SKILL.md`** said "## index.yaml entry / Every learning MUST
  have a corresponding entry" eighty lines after its own heading "How it works
  (v2 — there is no `learnings/` directory)".
- **`project-conventions.md`**, installed into every project, described the v1
  layout in nine places and named the wrong required-section counts for both
  neighbours.

**Repathing only the pointers would have produced the half-repathed state
`phase-6.md` itself identifies as worse than v1** — passes a spot-check, fails
mid-task. Each file was read through and fixed whole.

**Two defect classes are invisible in this repo by construction** and appeared
only when the check ran against the pilot: five installed files pointing into
`docs/`, which `r2p init` never installs, and two conventions referencing skills
by `.claude/skills/<x>/SKILL.md`, which v2 made global. Both resolve here and
nowhere else. `install-project.js:302` already had the fix — it says "in the
framework repo".

### 4. Every new tier rests on a population measured this session

| Check | Population | Tier | Why |
|---|---|---|---|
| 16 retired | 0 | FAIL | mechanical; no adoption backlog |
| 16 revised | 21 | WARN | which leg was retired needs an eye |
| 17 no ids | 0 | FAIL | `claims.md` states it as an imperative |
| 18 other legs | 42 checked, 0 broken | FAIL | prospective, like invariant 11 |

That discipline is the direct correction of invariant 13, which shipped WARN
citing a count belonging to invariant 14.

**Invariant 18 also corrects a deliberate limitation, and the volume argument
against the old approach is stronger than the principled one.** Invariant 8 read
only the ids before the first `·`, and the comment was honest about why —
checking the later legs "reports the wrong field name". Tracking which field is
in force costs one variable. But the ledger's `Contested by:` values *wrap across
lines*, so a line scan sees **10 of the 34** ids in those legs. It was missing
70% of its own population.

### 5. Two specs could not be met as written, and both were corrected in the phase file

- **6a's "does not fire on a line that legitimately repeats a path"** contradicts
  the rule 6a states. "2+ matches with fewer distinct values" fires on 11 lines
  here and 8 are legitimate. Gap alone does not separate them — the tightest
  legitimate gap (16) is *closer* than the widest real one (18). Gap ≤20 **and**
  no sentence boundary between separates all fourteen.
- **6c's smoke test needed redesigning, not a venv.** The phase file inherited
  the archive's fix, "bootstrap a venv at the test target". A venv in someone's
  project is a side effect nobody asked for, and every real r2p project already
  has one — a target without a venv resembles no actual user, which was the
  original planning gap. **The criterion was the problem**: it required the
  target's dependencies installed, so it could never pass in a throwaway target.
  Stage 1 is now an `ast` parse needing nothing installed and it is the half that
  counts; stage 2 is the real import, informational. This is the archive's own
  learning — "'classified correctly' is not 'succeeded', and a plan should say
  which one it means" — applied to the check that produced it.

### 6. Five checks, five live defects that were on nobody's list

Every new mechanism found something on first run. That is the return on Phase 6
and it is worth stating as a number:

| Check | Found |
|---|---|
| invariant 15 | 5 runtime-surface pointers, + 4 more once widened, + 2 classes invisible here |
| duplicate-path detector | a **third** collapse instance, live in `README.md:24` since v2 |
| heading-tree audit | a defect shape (duplicated heading) that its own two rules missed |
| `--upgrade` test | nothing new — but shown red on four reverted fixes |
| invariants 16–18 | population zero today; the value is prospective |

**The `--upgrade` test finding nothing is the one worth reading twice.** It is
the only new mechanism here whose green run is meaningful, because it was made
to go red four separate ways first. The other four had live defects to find, so
their red was free.

### 7. Deliberately left for Phase 7, stated so it is not lost

- **`templates/research/sources/EXAMPLE_world_bank_api.md`** has v2 frontmatter
  and v1 section headings — the framework's worked example fails its own required
  shape. Reshaping it is editorial work about the World Bank API, not a repath.
  The INDEX recipe now says in one line to follow the list and not that file.
- **The 24 WARN-tier doc pointers** are Phase 7's sweep. Six of them live in
  `plan/` and are *correct* — a plan file quoting a dead convention while
  describing the defect. They need no exemption: when the plan completes it moves
  to `archive/`, which is already exempt. The noise is self-clearing.
- **A project's own `CLAUDE.md` goes stale** and `--upgrade` does not touch it.
  The pilot's still lists `.claude/skills/` and a Stop hook that no longer
  exists. A warning is the same cheap fix as the orphaned-hook one.
- **`.scc/status/project.md` staleness** still has nothing checking it.

---

## D10 — Phase 7 executed; v3 shipped; three things nobody had listed (2026-09-09)

Eleven commits, `d351edf` … `e396392`. Every Phase 7 task landed and
`package.json` is `0.3.0`. Outcomes table in `phases/phase-7.md`; this entry
records only the direction changes and the things that generalize.

### 1. A decision taken from a file list is a decision about the list

**Decision B — "delete the 14 `docs/*-mechanism.md` files" — was executed as
eight deletions and six repaths, on the researcher's call, escalated before any
deletion.**

Reading all fourteen: eight document conventions v2 merged away and are
therefore accurate about v1 and misleading about the framework. Six document
conventions that are still live. And `docs/extending.md` prescribes
`docs/<name>-mechanism.md` as the design-rationale slot for *every* convention —
the same slot task **7.2 creates `citation-chain-mechanism.md` in, in this same
phase**. Executing B literally would have retired the naming pattern in the act
of using it.

Measured before asking, which is what made the question answerable in one round:
the six keepers carry **0–3 stale path mentions each, eight in total**. So
"keep" cost eight line-fixes rather than a rewrite, and the choice was not
between deletion and debt.

One deviation from the approved list, stated in the commit:
`migrate-source-mechanism.md` was named in the delete column and was **kept**,
because the rule the researcher approved alongside the list — *delete docs for
conventions v2 merged away, keep docs for live ones* — puts it in the keep
bucket. The skill is live and 6c repathed it; only its cross-references were
stale.

**The lesson is not "escalate more".** D8 recorded decision B as answered and
unblocked, and it was — the *decision* was sound. What was wrong was its object:
a count of files matching a glob, standing in for a category nobody had checked
the glob against. *When a decision names a file set by pattern, enumerate the set
and read it before the decision is executed, not before it is taken.*

### 2. The verification criterion nobody had run found the largest defect

Phase 7's verification list included *"`r2p init` into a throwaway repo:
`lint-research.sh` green and silent on the empty tree — a linter that fails a
fresh install is worse than no linter."*

Run for the first time, after **eleven of the eighteen invariants had already
shipped**, it exited 1 with three findings on a tree containing no research at
all. Two of the three were the *check* being wrong:

- `check-archival.sh` correctly names `~/.claude/agents/archivist.md`, which is
  installed **globally**. Invariant 15 stripped the `~/` and resolved it against
  the project root — the wrong question.
- `project-conventions.md` correctly names `docs/audience-and-philosophy.md` and
  qualifies it in prose as *"in the framework repo (not installed here)"*.
  `TODO.md` had recorded this class as un-mechanisable, and that was true of
  qualification in general and false of an **explicit marker**: honouring a line
  that says *framework repo* is the same move invariant 14 makes with a renumber
  banner, and it converts a piece of advice into a rule with a consequence.

The third was the shipped `templates/research/claims.md` seed, whose worked `C1`
is a placeholder claim — an assertion by invariant 17's definition, correctly
flagged, on every fresh install. Fixed by commenting the block out **and** by
teaching the claims parser that an HTML-commented region is not live, which a
project needs anyway for a drafted or retired claim.

**Surprise 5 of the last handoff said a framework cannot check itself against
itself. This is the second half of that: it cannot check itself against its
users either.** Both are *populated* states, both have answers nobody knows in
advance. The empty state is a third corpus and the only one with a known-correct
answer. Encoded in `extending.md` step 2a (three corpora, in order) and
`docs/field-notes/a-linter-must-be-run-against-a-fresh-install.md`.

### 3. "Promote the WARN tier to FAIL" needed a third tier instead

The handoff's item 4 read as a one-line change. Executed literally it leaves the
repo red for as long as any plan is open: the last seven findings all live in
`plan/`, where quoting a dead convention **while describing the defect** is
correct, and no edit makes such a line both accurate and resolvable.

So `plan/**` became its own permanent WARN tier and the doc tier was promoted.
The split is what made the promotion reachable at all, and it is the script's own
rule doing the work — *FAIL only if a green run on a correct project is genuinely
reachable today* — applied to a population the rule had not been applied to
separately before.

Shown red three ways before being trusted green: a dangling `docs/` pointer exits
1, a dangling `.claude/` pointer exits 1, a dangling `plan/` pointer exits 0.

### 4. Two things were larger than their task line said, in the same direction

- **7.3's `r2p-adopt.md`** was listed as "live adoption guide" with five dangling
  pointers. It was an entirely v1 document — every slot it proposed was a v1
  slot — and it is the one file a project reads at the moment it has no other
  model of the framework. Three of the repaths were conceptual, not textual: raw
  data no longer goes to the wiki, archaeology proposes topics rather than dated
  decision records, and it had been **teaching the id-collision vector**
  (`ls evidence/ | sort | tail -1`) that produced five duplicate ids on the pilot.
- **7.7's README** was listed as "conventions list and version". Its `docs/` tree
  named nine files that no longer exist and none of the four that do; its
  `templates/` tree was v1 throughout, and listed `research/methods/` twice with
  different contents.

Both are the same shape as D9's surprise 2 — *a hand-built inventory of invisible
defects is itself incomplete* — one level up: **a task line written months before
execution is an inventory too**, and it decays the same way.

### 5. A generated report, once committed, becomes its own input

`linkcheck.md` was picked up by an over-broad `git add -A` mid-phase. On the next
run the duplicate-path detector read a *previous run's table rows* and reported a
phantom 3× `data/raw/` collapse whose source was its own output. Untracked,
gitignored, and `03_linkcheck.py` now excludes its `SELF_REPORT` from
`tracked_md()` so it cannot recur for anyone who commits it again.

Small, but it is the second time in two phases that a tool's own artifact
distorted the tool's own measurement, and both times the symptom looked like a
real finding.

### 6. Version numbers were in two places

`package.json` said `0.2.0` and so did a hardcoded `.version('0.2.0')` in
`src/cli.js`, so `r2p --version` had been reporting independently of the
manifest. Both bumped. Nothing checks that they agree; that is a candidate
invariant if it recurs.
