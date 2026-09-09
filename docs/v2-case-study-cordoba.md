# Case study — what six months of intensive research did to a research framework

**Subject:** the Córdoba growth-narrative engagement (Harvard Growth Lab),
running on `research-to-policy` v1 from 2026-01 to 2026-08.
**Occasion:** the researcher reported that Claude was getting lost synthesizing
the project's own evidence, and that some findings appeared to contradict each
other for reasons that looked like writing rather than measurement.
**Outcome:** r2p v2 — 13 conventions to 7, 26 root directories to 8, and one new
mechanism.

---

## 1. The framework worked. That was the problem.

Nothing in this case study is a story about a framework being ignored. The
opposite: r2p v1 was followed closely enough, for long enough, that its
mechanisms filled up and then broke **at the seams where it had guessed at
scale**.

| Mechanism | What v1 assumed | What six months produced | Result |
|---|---|---|---|
| `evidence/` | no size stated | 151 docs, 1.73 MB, **INDEX.md = 330 KB** | index unreadable; synthesis unreliable |
| `decisions/` | "5–15; >30 is over-recording" | 43 | boundary with `methods/` collapsed |
| `learnings/` | a YAML frontmatter schema | 70 files, **7 compliant** | the real format was undocumented |
| `methods/` | ">10 means refocus the engagement" | 4 real entries | starved; its content went to `decisions/` |
| `data_sources/` | "flat, ~5–15 scans in seconds" | 60 docs | flat index stopped scanning |
| `wiki/` + registry | core scaffolding | 0 pages, 0 scrapes | pure context tax |
| root | unspecified | 26 dirs + 22 loose files | no orientation |

Four of those rows are the same failure: **a stated size range that reality
exceeded by 3–10×.** One is a format that lost 90% of the time. One is a whole
subsystem that never activated.

The generalisable lesson arrived from inside the migration itself. The first rule
for deciding which evidence docs deserved a full rewrite was "cited ≥3× by a
deliverable". On a corpus where citation counts run 80–180, it selected **145 of
151**. Replacing it with a rank cut (top 40 ∪ the 21 carrying retraction banners)
gave 57.

> **Size-dependent rules must be expressed as ranks or shares, never absolute
> counts.** A threshold that is well-calibrated at 20 documents is
> all-or-nothing at 150.

---

## 2. Why the evidence looked self-contradictory

The researcher's diagnosis — *over-interpretation in how the docs were written* —
was right, and it decomposed into four structural causes. All four are countable.

### 2.1 Verdicts were fused to measurements

v1 asked for `**claim** — number — implication` in one bullet. Authors complied
by writing verdicts. Across the corpus: **338 verdict words** (`confirms`,
`REFUTED`, `REJECTED`, `VERDICT`, `DOWNGRADED`) in **93 of 151 docs**.

**Measurements do not contradict each other; verdicts do.** Two docs can measure
compatible things and still read as a collision, because each shipped its own
adjudication and nothing ever reconciled the adjudications with each other.

v2 splits `## Measured` (numbers, cells, comparisons — no verdict words, enforced
by lint) from `## Reading` (2–5 sentences, explicitly the author's
interpretation). A synthesizing session reads `Measured` across docs and writes
the reading **once**, at narrative level.

### 2.2 Scope lived in prose

Unit, geography, period and weighting were buried in paragraphs. So a
province-level number and a metro-level number on the same question read as a
disagreement rather than as two measurements of two different objects.

This project had already paid for that twice, in the form of two hard-won
standing rules: *cities are the unit for labour claims — province and metro can
flip sign*, and *never use modelled population where a census exists*. Both are
scar tissue from one missing field.

v2 puts `unit / geography / period` in frontmatter, which converts the question
into a mechanical test: **two findings can only contradict each other if their
unit and period overlap.**

### 2.3 Status was a prose banner

Twenty-five docs carried `⚠ … RETIRED 2026-07-31 …` text, prepended to their
*index title*. Nothing was filterable, so retired legs kept being cited from doc
bodies while the warning sat in the index.

The sharpest artifact in the entire audit is a line the project wrote about
itself, in `retracciones.md`:

> *"Retired formulations survive **inside** evidence docs that the memo cites,
> and two of them are collisions **within a single file** — #124 retired +3.6 pp
> in Finding 2b and kept asserting it in Finding 4."*

A document that contradicts itself is what prose retractions produce at scale.
v2 uses `status: live | revised | retired`, one banner in the doc, and nothing in
the index.

### 2.4 Nothing curated — and the project had already noticed

Evidence is append-only *by design*, and that is correct: an audit trail has to
survive being wrong. The consequence v1 did not anticipate is that the corpus is
**monotonic**. It only grows. Nothing in it distills. At 151 docs, with 122 of
them cited directly from memos and decks, every synthesis session rebuilt a
distillation from scratch — from a 330 KB index whose median title was 1,554
characters and whose longest was 10,410.

**And a researcher had already built the missing layer by hand.** Inside
`plan/plan-narrativa-final-memo/context/` sat three files:

- `mapa_evidencia.md` — 1,568 lines, one row per claim, section by section
- `retracciones.md` — 40 live retractions with the exact retired wording
- `flags_narrativa_vs_evidencia.md` — 128 flags

`mapa_evidencia.md`'s own header states the reason:

> *"Este archivo existe para que ninguna sesión de redacción tenga que volver a
> abrir `evidence/INDEX.md` (317 KB de abstracts completos). Las 148 fuentes se
> leyeron enteras una vez; esto es el resultado."*

Someone hit the wall and built exactly the right fix. But the framework had no
slot for it, so it was **plan-scoped**, stamped *"GENERADO. No editar a mano"*,
and produced by a build script. It solved one memo and died with that plan; the
next plan would have to build it again.

> **When users invent a mechanism and hide it in the wrong directory, that is the
> strongest signal a framework has a gap.** Not complaints — workarounds.

---

## 3. Why decisions, methods and learnings collapsed into each other

v1 split methodology across three directories **by genre**:

| Directory | Genre | Question |
|---|---|---|
| `decisions/` | peer-reviewable choice | *why this and not that?* |
| `methods/<slug>/rule.md` | operational rule | *what do we compute?* |
| `learnings/` | tacit trap | *what will bite me?* |

Research does not arrive by genre. It arrives **by topic**, and a single topic
routinely needs all three:

> *The FUA is the city unit* → a **rule** (apportion BEA counties into FUA
> polygons by tract-centroid population share), a **justification** (vs CBSA,
> rejected because sprawl-correlated measurement error would load onto the
> coefficient of interest), and a **trap** (an FUA is not an EPH aglomerado —
> never pool Gran Córdoba with Río Cuarto).

On this project those were three files in three directories held together by
hand-written cross-links. `2026-07-17_tradable-nontradable-classification.md`
opens with three `learnings/` back-references in its header — the framework
working exactly as designed, which is why it is the evidence against the design.

**And the boundary was not actually held.** `decisions/` reached 43 against a
spec that called >30 over-recording, while `methods/` starved at 4 — because two
of the largest "decisions" (`municipal-universe-and-key`,
`tradable-nontradable-classification`) were plainly operational rules. Only 7 of
71 learnings used the documented format.

> **A boundary that fails 90% of the time is not being violated. It is not
> real.**

v2 keeps one directory, `research/methods/<topic>.md`, split by topic, with
sections for Rule / Why-not-the-alternatives / Traps / Diagnostic counts / Scope
and limits / Changelog. **113 files became 28.**

### 3.1 A directory can hide several genres at once

Routing all 70 learnings by hand surfaced something nobody had noticed: they were
**five different kinds of document** filed as one.

| Kind | n | Correct home |
|---|--:|---|
| source-operational trap (expiring token, silent HTTP 200) | 24 | the source's own doc |
| method/analysis trap (a pooling rule, a vintage break) | 20 | the method's own doc |
| cross-cutting numerical craft (`isclose` breaking a log mean) | 12 | one shared `_craft.md` |
| chart/deck style | 7 | project conventions |
| **bugs in r2p itself** | **7** | **the framework repo** |

That last row is the finding. Seven entries were never about Córdoba: evidence-id
collisions across parallel worktrees, two agents sharing one git index, parallel
fan-out hygiene, digest retention varying with heading style. They had been
sitting in a project repo where **no future project could ever see them**.

The evidence-id collision was filed **twice**, months apart, by different
sessions. It recurred because the first filing had nowhere to go that would
change the framework. The audit surfaced both at once, and v2 fixed it with a
central `.next-id` counter — three duplicate ids (#119, #131, #139) had already
accumulated, all from same-day fan-outs.

> **A framework needs a place for lessons about itself, in the framework repo.
> Otherwise its own bug reports are filed where they cannot be acted on.**

---

## 4. What was actually built

### Córdoba

| Before | After |
|---|---|
| `evidence/INDEX.md` 330 KB, median title 1,554 chars | 33 KB, hard 120-char cap **(10×)** |
| synthesis surface: 330 KB of index | `claims.md` (24 KB) + index (34 KB) = **57 KB** |
| 0 machine-readable scope fields | 151 docs with `unit / period / status / confidence` |
| 3 duplicate evidence ids, `ls`-based allocation | ids unique; central `.next-id` |
| 25 prose retraction banners in index titles | `status: revised`, banner in the doc |
| 113 files across `decisions/` + `learnings/` + `methods/` | 28 topic files + `_craft.md` |
| 26 root directories, 22 loose files | **8 directories**, 8 config files |
| `CLAUDE.md` 14 sections, 8.8 KB | 7 sections, 6.1 KB |
| no lint | 7 enforced invariants, PASS |

`research/claims.md` holds 40 claims in narrative order, each with unit, period,
one number, the evidence it rests on, and what contests it. Three are `open`;
four carry a live `Contested by:`.

**The ledger's most valuable output was not the claims — it was three holes.**
Compressing 151 docs into 40 claims made visible that three of the memo's
load-bearing numbers have **no evidence doc at all**: the 408-cell industry
immunity screen and the RIGI tabulation, the three-lens × three-period growth-gap
exhibit that carries §1 (it lives in a plan handoff and a render script), and the
consolidated agro verdict (an arithmetic sum across five docs, with no doc of its
own). Those were invisible while the index was 330 KB.

### The framework

7 mandatory conventions + 2 optional; `research/{claims.md,evidence,methods,sources}`;
`r2p init --with-wiki` (default off); rewired retrieval hook; new
`lint-research.sh`; `docs/field-notes/`; `templates/migration/` with the six
scripts; `docs/v1-to-v2-migration.md`. On branch `v2-consolidation`, version 0.2.0.

---

## 5. Lessons from running the migration

These cost real time and are the ones most likely to recur.

**1. A mechanical repath rewrites the documentation *about* the repath.**
`02_repath.py` faithfully turned `methods/<slug>/rule.md` into
`research/methods/<slug>/rule.md` **inside the v1-vs-v2 comparison table whose
entire job was to preserve the old path** — and later, porting to the framework
repo, turned the script's own rule table into `("research/sources/",
"research/sources/")` and collapsed three distinct README entries into
duplicates. The one place old paths must survive is the migration's own
documentation. `EXCLUDE_PREFIXES` now guards it. Caught by reading the diff; no
test would have.

**2. Measure a baseline before claiming you broke nothing.** The link checker
reported 238 dangling references after the migration. Alarming — until the same
checker, run against a `git worktree` of the pre-migration commit, reported
**405**. Most dangling links predated any migration, and the repath fixed more
references than it touched. Without the baseline there was no way to separate my
breakage from the repo's.

**3. Never infer a field whose wrongness is worse than its absence.** Scope
heuristics tagged a 24-province panel as `unit: metro, period: 1960–2026` (the
year regex swept every number in the first 6 KB). A blank field makes a reader
open the doc. A confidently wrong `metro | 1960–2026` makes them trust it and
then "discover" a contradiction with a genuinely-metro finding — **industrialising
the exact bug the field exists to prevent.** `unit` and `period` are hand-authored
for all 151; the fallback is `unknown`, and 34 docs legitimately carry it.

**4. Migration scripts must be idempotent by rebuild, not by skip.** The
frontmatter script initially *skipped* docs that already had frontmatter, which
silently froze the bad heuristic run in place. The same class of bug hit the
installer: `mkdir research/evidence/` before mirroring made the mirror skip it as
"exists" and shipped an empty `research/` tree to every new project. Both were
found by running the thing end-to-end and looking at the output — the installer
one only by `r2p init`-ing into a throwaway repo.

**5. Structural merge beats re-prosing.** The 43 decision records were
well-written and carried exact numbers and careful caveats. Re-writing them into
28 topic files by hand would have lost precision. Instead the merge moves prose
**verbatim** under the v2 headings, labelled with its origin file, and adds only
what consolidation actually provides: one file per topic, uniform sections, traps
folded in, frontmatter triggers. Preservation was verified by probing a
distinctive mid-document line from all 117 legacy docs against the new tree —
0 missing.

**6. Two merge defects worth naming.** An over-escaped regex (`r'^#\\s+.+$'`)
left every H1 in place, and inner `##` headings from merged learnings silently
re-opened top-level sections, collapsing the topic files' structure. Both were
invisible in the summary counts and obvious in the heading tree. **After any
document merge, print the heading tree.**

---

## 6. What generalises beyond r2p

1. **Append-only knowledge needs a curated layer above it.** The append-only rule
   is right — audit trails must survive being wrong. But past a few dozen
   entries, nobody can read the corpus, so something has to distill. Give the two
   layers **opposite mutability**: the record preserves, the view curates.
   Deleting a view entry is cheap and correct; deleting a record destroys the
   trail.
2. **Separate measurement from interpretation at the document level.** It is the
   cheapest possible defence against a corpus that appears to disagree with
   itself, and it makes real disagreement visible instead of burying it.
3. **Scope keys turn judgement calls into tests.** Unit and period in
   frontmatter mean "do these contradict each other?" has a mechanical answer.
4. **Organise by topic, not by genre.** Genre boundaries feel clean when writing
   the spec and fail at write time, because work arrives as a topic that needs
   several genres at once.
5. **Express size-dependent rules as ranks or shares.** Absolute counts invert
   when the corpus grows an order of magnitude.
6. **Codify what survives contact.** A prescribed format with 10% compliance is
   wrong, not disobeyed. The emergent format is the specification.
7. **A mechanism with zero artifacts should not have a section in the file that
   loads every session.** Ship it, gate it, give it one line.
8. **Read what your users built in the wrong place.** Every real gap in v1
   showed up first as a workaround: the claims layer hidden in a plan folder, the
   framework bug reports filed as project learnings, the method rules filed as
   decisions. Complaints are rare; workarounds are everywhere and they are
   precise.

---

## 7. What remains

- **57 tier-1 evidence docs still need the `## Measured` / `## Reading` rewrite
  by hand.** Frontmatter, status and the capped index cover all 151; the prose
  split is authored per doc. The tier list is
  `mapping/evidence_audit.csv` (`tier == 1-rewrite`).
- **The 28 topic files open with merged prose, not a synthesised lead.** Each
  carries every v1 record's content under uniform headings; the multi-source ones
  (`city-unit`, `agri-upside-accounting`, `pizza-chart`) would read better with a
  one-paragraph rule synthesis at the top.
- **Three claims have no evidence doc** (§4). Either file the docs or drop the
  numbers from the memo. This is the highest-value follow-up in the list.
- **45 source docs carry filename-derived `triggers:`** and `status: stale`.
  Refine when each source is next touched.
- **`plan-narrativa-final-memo/context/` still holds the long-form flags and
  retractions.** `claims.md` promotes their conclusions; the detail stays there
  until someone decides whether the 128 flags belong in the ledger or in the
  methods files.
- ~~**r2p is on `v2-consolidation`, unmerged.** `docs/*-mechanism.md` for the merged
  conventions still describe v1 — deliberately, as historical record, but the
  live docs set should be pruned before a release.~~ **Closed in v3** (decision B):
  the eight docs describing merged-away conventions are deleted; the six describing
  live conventions stay. See `docs/v2-to-v3.md`.
