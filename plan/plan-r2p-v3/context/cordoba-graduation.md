# Graduating the Córdoba r2p fixes — study result

**Status:** study **done** 2026-08-17. Supersedes the 2026-08-05 scoping note of
the same name. **Still not a phase** — the items below are approved in principle
(researcher, 2026-08-17) but not yet placed in `plan.md`. See *Placement* last.

Method: read the diffs and **ran the gates**, per the scoping note's own warning.
Running them is what produced the two hardest findings; neither is visible in the
tree.

## The framework bug — highest priority, and not a graduation

`templates/migration/02_repath.py` **silently half-repaths code.** Its `RULES`
table matches path tokens **with a trailing slash** (`("evidence/",
"research/evidence/")`, `re.escape`d at `:78`). A `Path` join on a bare segment
never matches:

```python
EVID = REPO / "evidence"                # not matched — no slash
"""Inputs: research/evidence/*.md"""    # matched, rewritten
```

So a script's docstring is repathed while the line that opens the directory is
not. The report reads clean and complete.

**Measured on the pilot** (`~/cordoba-growth-narrative`, ran `02_repath.py`
2026-08-04, report at `plan/plan-r2p-v2-consolidation/mapping/repath_report.md`):
`evidence/ -> research/evidence/` **571 rewrites, 559 files, double-prefix guard
clean** — and **four dead v1 code paths survive**:

| Site | Holds | Consequence |
|---|---|---|
| `plan/plan-narrativa-final-memo/gate_coverage.py:34` | `REPO / "evidence"` | **crashes today** |
| `deliverables/decks/20260721_*/render/d1_es_biggest_obstacle.py:23` | `ROOT / "slides"` | `mkdir(parents=True)` at `:24` — **silently re-creates a v1 dir the migration deleted**, writes the chart there, exits 0 |
| `deliverables/decks/20260723_*/render/p4_s44_es_biggest_obstacle.py:30` | `ROOT / "slides"` | same, `mkdir` at `:31` |
| `cordoba_utils.py:916` | `_REPO / "data_sources"` | the project's shared util module, dead path |

Reproduce:

```sh
cd ~/cordoba-growth-narrative
git grep -nE '(/|join\(|Path\()\s*"(evidence|methods|sources|wiki|slides|decisions|learnings|data_sources|brainstorms|internal_docs|project_conventions)"' -- '*.py' '*.sh' '*.R'
for d in data_sources slides evidence; do [ -e "$d" ] || echo "$d GONE"; done
```

`analysis/water/2{0,1}_*.py` and `deliverables/memos/*/build_slides*.py` also
match the grep and are **fine** — the first two already carry v2 paths, the rest
are relative to `__file__` inside their own deliverable. `migration/audit.py` and
`05_methods_merge.py` read v1 paths **on purpose** and are `EXCLUDE_PREFIXES`d.
A detector must not flag those four classes.

**Fourth defect of the class `CLAUDE.md` names** — lives only in the
upgrade/migration path, invisible to an `init` test.

### The second bug that made the first one cryptic

`gate_coverage.py` builds `by_num` as a `defaultdict(list)`, then **reads** every
id in an earlier loop (`:73`), which auto-vivifies empty lists. The later
resolution test `if n not in by_num` (`:97`) therefore answers *"resolved"* for
ids that only ever existed as a side effect of being looked at. Instead of
failing with "0 evidence docs found", it dies 40 lines on with `IndexError: list
index out of range` at `:104`.

**A membership test against a `defaultdict` is not a membership test.** Generic,
cheap to state, and the reason a loud failure presented as a cryptic one.

## Approved graduations

Ranked. Researcher approved this order 2026-08-17. **G-numbers are this note's,
not task ids** — assign task ids at placement.

### G4 — `scope_authored:`, a truthfulness flag on the frontmatter block

**Pilot:** evidence docs carry
`scope_authored: true   # unit/period hand-checked against the doc; kind/confidence still heuristic`
(e.g. `research/evidence/150_*.md:14`).

**Why it beats what we shipped.** `evidence.md:120-131` makes `unit` + `geography`
+ `period` the mechanical contradiction test, and `:144` already records the
mis-inference that motivated the rule (v2's scope-key inference tagged a
24-province panel `metro | 1960–2026`). Our answer is binary — hand-author or
omit. Omitting destroys the triage value of the whole INDEX; the pilot's third
option **keeps the machine-guessed value and prices it**. This is principle
"never infer a field whose wrongness beats its absence" resolved, not obeyed.

**Destination:** `.claude/conventions/evidence.md`, frontmatter block at `:54-70`
and the rationale at `:120`. **Highest-value pure graduation.**

### G5 — id-collision *recovery* → `citation-discipline.md`

**Pilot:** ran the full cycle on three collisions. Disambiguate inline
(`#119`(sec) / `#119`(mig)) → renumber (`131→150`, `119→149`, `139→151`) → `> ⚠
Renumbered` banner on the doc → `(was #131)` appended to the headline.

**Which half worked, measured.** The banner and `(was #NN)` **held**. The inline
disambiguator **rots**: the tags are frozen against a numbering that then
changed, so `gate_coverage.py`'s `DISAMBIG` (`:38-45`) names three files that no
longer exist, and `output/mapa_1{a,c,d}.md` still write `#119`(sec).

**The rule is a negative one:** repair an ambiguous id by renumbering with a
banner, never by tagging the reference.

**Destination:** `.claude/conventions/citation-discipline.md` — greps clean for
`collision|collide|filename|ambiguous|disambig`, i.e. **zero coverage today**.
Headings at `:7 :34 :55 :74 :88 :110 :122 :132`. We have prevention (`.next-id`);
this is the missing recovery half. **Fifth appearance of the collision problem.**

### G1 — bare-directory-literal detector for the migration ✅ SHIPPED 2026-08-17

`templates/migration/02_repath.py` gains `bare_segment_hits()` — a guard, not a
rewriter. It reports and **fails the repath**; it never edits a path expression,
because rewriting `X / "evidence"` needs to know what `X` is and a wrong rewrite
of a path expression is worse than an unrewritten one.

Its watch list is **derived from `RULES`**, not restated, so the guard and the
rewriter cannot disagree about which directories moved — the discipline two of
the pilot's gates stated independently (*"the SAME source `assign_subphases.py`
uses"*, *"same ROUTES table `build_mapa_evidencia.py` uses"*). Deriving it also
buys the false-positive rule for free: `RULES` knows `methods/` →
`research/methods/`, so a line already reading `"research" / "methods"` is
legitimate while bare `"methods"` is not.

Two suppressions, both measured load-bearing:

- **`__file__` on the line** — `Path(__file__).parent / "slides"` inside a
  deliverable is that deliverable's own subfolder and did not move. Removing this
  rule adds **3 false positives** on the pilot.
- **the v2 parent already quoted earlier on the line** — `ROOT / "research" /
  "methods"` is correct v2. Fixture-verified (removing it costs nothing on the
  pilot only because the pilot has no such line).

**Measured on the pilot: 4 hits, 4 real, 0 false** — the exact four sites found
by hand. Zero false positives is why it exits non-zero rather than warning; a
one-shot migration whose miss is silent is how this bug survived. Reproduce
without touching the pilot (`--check` still overwrites its historical report):

```sh
cd ~/cordoba-growth-narrative && python3 -c "
import importlib.util
s=importlib.util.spec_from_file_location('rp','$R2P/templates/migration/02_repath.py')
rp=importlib.util.module_from_spec(s); s.loader.exec_module(rp)
print(*rp.bare_segment_hits(rp.tracked_text_files()), sep='\n')"
```

**Still owed, Phase 6a:** the duplicate-path-per-line detector on
`03_linkcheck.py`, and an `--upgrade` integration test. **Not** owed: repairing
the pilot's four sites — that is pilot work, not framework work.

### G3 — the lint needs a WARN tier; it has none

All 7 checks in `.claude/hooks/lint-research.sh` are ok-or-FAIL (`:26-104`,
`fail=1` throughout, `exit $fail` at `:106`).

**Pilot built the missing tier and stated the reason in the file.**
`gate_retracciones.py` check 4 (`:132-146`) **prints and never fails**: a
two-word-phrase language classifier misreported (`base exportadora`, `gradiente
plano`, `industrias urbanas` carry no accent and no function word, so a
stopword test called all three wrong), so it prints the rows and asks for an eye
rather than "ship a test that misreports". Measured 12 of 40 rows.

**Unblocks a decision already taken:** invariant 13 must be WARN not FAIL
(handoff *Pilot-repo review* §2) and **has nowhere to live today**.

**Destination:** `lint-research.sh` + the pattern in `docs/extending.md`.
**Do this before 3.4b, not after.**

### G2 — every `#nn` in a deliverable must resolve to a live evidence id

The pilot renumbered carefully and **never updated the citations**; nothing could
see it. Cheap mechanical sibling of proposed invariant 13 (which checks `[C<n>]`).
At the measured 573 bare `#nn` refs this is the one that actually fires.

**Destination:** `lint-research.sh`, Phase 3. Ships **WARN** (G3 first) for the
same crying-wolf reason as 13.

### G7 — a counting script's header states its unit and the unit it rejects

`provenance.md:12-44` specifies `Inputs / Outputs / Seed / Env` — provenance for
**data**. Nothing covers provenance for a **judgement**.

**4-of-4 gates did this unprompted**, each naming the miscount the rule prevents:
*"counting them is how the total drifted to 80"*, *"counting rows instead of
charts is what turns 76 into 79"*, *"a narrower pattern reported 12 false inert
rows, four of which DID carry strings"*. Strongest compliance signal in the study.

**Destination:** one line in `provenance.md` Half 1 (`:12`).

### G8 — an unranked fan-out output is the defect; overflow is its symptom

`gate_chart_budget.py` re-framed what a handoff called a global budget failure
("79 rows against ≤32, fails by 2.5×"). Measured per section against the
outline's own slot counts: **every sub-agent that ranked came in at or near its
allocation and named its own drop candidates; the two that emitted unranked rows
produced all the overflow.** The gate prints a `ranked?` column — that is the
diagnostic.

Case-study §6.5 (*ranks/shares, never absolute counts*) is the **consumer**-side
rule; this is the **producer**-side contract. Ran it 2026-08-17: still red at
2.4× overall, §1/§4/§9 all `ranked? NO`. **Still-red is evidence the diagnostic
keeps working**, not evidence it failed.

**Destination:** `.claude/skills/agent-teams/SKILL.md` — a teammate that returns
a list instead of a ranking has not finished. (Phase 1's file; Phase 1 is closed.)

### G9 — not a graduation: the design note for `pipeline-check` already exists

`gate_procedencia.py` **never ran** — `evaluar_deriva()` is `raise
NotImplementedError` (`:100`). Its diagnosis is real and confirmed: Anexo C.7
declared Enterprise Surveys as three waves verified 2026-05-13 while §9(a) and
Gráfico 23 ran **four** from a CSV refreshed 2026-07-23; three independent review
lenses raised it HIGH.

Its comment block (`:78-97`) enumerates three staleness designs and rules on them:
(A) date-only would have caught the real failure but `git checkout` rewrites
mtimes and the gate screams; (B) date-plus-margin buys quiet at the cost of a
blind window; (C) date-plus-content looks most rigorous and **is the one a prior
lesson already proved was noise** — bare years match anything. **The correct
granularity is not the finest.**

**Feed to Phase 5 as input.** The code is not a candidate; that paragraph is.

## The meta-finding — `project-conventions.md` has no promotion trigger

Of **9** reusable rules the pilot wrote during one plan, **3** reached
`.claude/conventions/project/` (double-paint, faceted-highlight, gl-design — all
into `visualization.md`, commit `1360b06`). **6 are still in
`plan/plan-r2p-v2-consolidation/for-project-conventions/`**, a closed plan's
directory, where nothing reads them.

`project-conventions.md` explains how to *write* one (`:81`, `:156` — the
triggering line) and where it *lives*. Grepped for `promot|when to|trigger|
graduat|stage`: **it never says when a plan's by-product becomes one.** Default
is therefore "leave it in the plan dir".

This is case-study §6.8 — *a mechanism invented and filed where it cannot act* —
recurring one layer below where Phase 1 just fixed it.

**Fix:** `plan-lifecycle.md` Stage 4 (`:178-200`) — a rule this plan wrote that
will outlive it moves to `.claude/conventions/project/` before archival. The
**archivist** already runs there (step 3, `:187`) and is the natural checker.

## Negative decisions — do not re-propose

| # | Rejected | Why |
|---|---|---|
| **G6** | the two-language project (deliverable language ≠ research-record language) | **Researcher call 2026-08-17: r2p stays language-agnostic.** Loses nothing — G6's only language-independent part (*a short-token heuristic classifier misreports; print and ask rather than fail*) is carried by **G3**. |
| **N1** | the gate scripts themselves | Rules graduate, code must not. 1 of 5 crashes, 1 was never implemented, both unnoticed — **a plan-local gate has no owner once the plan closes.** Checks worth keeping go in `lint-research.sh`, which we maintain and ship. |
| **N2** | `gate_procedencia.py` | Never executed. Nothing to promote but the design note — see **G9**. |
| **N3** | 6 of the 9 `for-project-conventions/` notes | Engagement-specific (GL design system, Córdoba periodization, IGN dpto shapefiles, one deck's annotation choice). `CLAUDE.md` forbids. Correct home is the pilot's own `.claude/conventions/project/` — which is what the meta-finding fixes. |
| **N4** | the pandoc→docx trap list (`deliverable_production__pandoc-docx-sectpr-toc-dpi-traps.md`) | Real and precise (empty `<w:sectPr/>` so image scaling is undeclared, ToC as an unpopulated Word field, 300-dpi silently clamped to 96). But tool-specific in exactly the way principle 6 keeps the core neutral. `docs/field-notes/` at most. |
| **N5** | `mapa_evidencia.md` | Carried forward from the scoping note. Re-confirmed and now **weaker**: its only durable part was the section-routing table, which already graduated by being imported into `gate_chart_budget.py`'s `ROUTE`. |

**N6 — REJECTED 2026-08-17 (researcher).** `chart_slide_export.md` (124 lines,
pilot). Its rule does generalize — *title, subtitle, source and notes travel as
editable text; never bake them into the image that leaves the repo, and never
overwrite the baked-in version, because evidence docs embed it* — and it was the
fastest of the 9 to be promoted inside the pilot. But the file is written around
`gl_save()` and the Growth Lab design bundle, so shipping it means rewriting it
generically first, and `CLAUDE.md` is explicit that Córdoba is proving ground,
not content. **The meta-finding already fixes the real problem**, which was never
that this rule is missing from the framework — it is that such rules never leave
the plan directory. Do not re-propose without new evidence.

## Verified fine, no action

- **`6a7da12` graduated well.** The pilot's machine-readable scope keys, the
  ≤120-char headline, INDEX-as-triage-table and the *contradict only if unit and
  period overlap* rule are all in `evidence.md` already. Only `scope_authored`
  (G4) was left behind.
- **`case-study.md` is byte-identical** to `docs/v2-case-study-cordoba.md`.
- **`02_repath.py` is byte-identical** to the pilot's copy — so the bug above is
  ours, in the shipped file, not a pilot-local edit.
- **`templates/claude_conventions_project/INDEX.md`** diffs against the pilot's
  by exactly the 4 rows the pilot added. The template's own "past ~5 files is a
  healthy pilot, past ~10 ask" meta-rule survived contact and is unchanged.

## Placement — DECIDED 2026-08-17 (researcher)

| Item | Where | Why |
|---|---|---|
| G4, G5, G7, G8, meta-finding | **new Phase 2b** | all are *rules*. `plan.md` *Phase Order*: **"2 blocks 3 — a check for a rule not yet written is a guess about what the rule would have said."** G2 checks G5's rule, so the rules land first. Phase 2 is `done` — reopening it would break the status table; the plan already uses letter suffixes (3.4b, 6d, 7.3b). G8 edits `agent-teams/SKILL.md`, Phase 1's file, and Phase 1 is closed, so it joins 2b rather than reopening 1. |
| G3, G2 | **Phase 3** | **G3 before 3.4b** — invariant 13 was decided WARN in D2 and has nowhere to live until the tier exists. |
| G1 + the repath fix | **done ahead of the phases** ✅ | shipped 2026-08-17. Phase 6 was already unblocked and independent, and this is a live defect in shipped code. Phase 6a keeps the duplicate-path detector and the `--upgrade` test. |
| G9 | **Phase 5** | context, not a task. |
| N6 | **rejected** | see above. |
