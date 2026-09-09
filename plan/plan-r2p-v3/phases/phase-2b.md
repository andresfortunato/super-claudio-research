# Phase 2b — Graduate the Córdoba fixes

**✅ DONE 2026-09-09.** All five items landed, all six verification criteria
verified, all constraints held (no new file, no new directory, no hook or `src/`
edit). Commits `9058c41` (T1) · `7c63510` (T2) · `70e1153` (T3) · `ceff9bd` (T4)
· `d2bcde8` (T5), plus `2d21597` — one out-of-phase blocker fix, see the
*Execution notes* at the end of this file.

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phase 2 · **Blocks:** Phase 3
**Self-contained.** A worker on this phase needs no other file. The full study,
with every measurement and reproduction command, is
`context/cordoba-graduation.md`; read it only if a claim below is disputed.

## Intent

The pilot did not just use r2p — it **fixed r2p**, repeatedly, under deadline, in
its own repo, and the fixes stuck. The 2026-08-17 study (`log.md` **D4**) ranked
what survived contact. Four items are *rules*, and they land here.

They are a separate phase, not a reopened Phase 2, because Phase 2 is verified
`done`; reopening it costs the status table its meaning. Two items belong by
subject to closed phases (G8 edits Phase 1's `agent-teams/SKILL.md`), and are
here for the same reason.

**Why before Phase 3:** *"2 blocks 3 — a check for a rule not yet written is a
guess about what the rule would have said."* Phase 3's `#nn`-resolution invariant
checks the rule **T2** writes.

## The four, plus the meta-finding

Ranked as approved. Each states the pilot's evidence, because none of these is a
good idea in the abstract — each is a thing that was tried.

### T1 (G4) — `scope_authored:` on the evidence frontmatter block

**Pilot shipped:**

```yaml
scope_authored: true   # unit/period hand-checked against the doc; kind/confidence still heuristic
```

**What it fixes.** `evidence.md:120-131` makes `unit` + `geography` + `period` the
mechanical contradiction test, and `:144` already records the mis-inference that
motivated it — v2's scope-key inference tagged a 24-province panel as
`metro | 1960–2026`. Our answer is binary: hand-author the field, or omit it.
**Omitting destroys the triage value of the whole INDEX.** The pilot's third
option keeps the machine-guessed value and prices it.

Write it into the frontmatter block at `:54-70` and the rationale at `:120`.
Optional key; **absent means "nobody has checked", never "checked and wrong"** —
same absence semantics as `artifacts:` (handoff *Carry into Phase 3* §3).

The free-text comment is the point, not decoration: it names **which keys** were
hand-checked. A bare `true` would re-create the problem one level up.

### T2 (G5) — id-collision *recovery* into `citation-discipline.md`

`citation-discipline.md` greps clean for `collision|collide|filename|ambiguous|
disambig` — **zero coverage**. We ship prevention (`.next-id`); this is the
missing half. Headings at `:7 :34 :55 :74 :88 :110 :122 :132`.

**The pilot ran the whole cycle on three collisions, so we know which half
works.** Disambiguate inline (`#119`(sec) / `#119`(mig)) → renumber
(`131→150`, `119→149`, `139→151`) → `> ⚠ Renumbered` banner on the doc →
`(was #131)` appended to the headline.

| Half | Verdict |
|---|---|
| banner + `(was #NN)` in the headline | **held** |
| inline disambiguator tag | **rots** — the tags froze against a numbering that then changed. `gate_coverage.py`'s `DISAMBIG` names three files that no longer exist; three memo fragments still write `#119`(sec) |

**So the rule is negative:** repair an ambiguous id by renumbering with a banner,
never by tagging the reference. State the banner's required content — old id, new
id, date, and the "citations before this date may mean either doc" warning — so
T4's check has something to resolve against.

**Fifth appearance of the collision problem.** Say so in the text; a reader who
knows it has recurred five times will treat the rule differently.

### T3 (G7) — a counting script's header states its unit

`provenance.md:12-44` specifies `Inputs / Outputs / Seed / Env` — provenance for
**data**. Nothing covers provenance for a **judgement**.

**4 of 4 pilot gates did this unprompted**, each naming the miscount its rule
prevents: *"counting them is how the total drifted to 80"*; *"counting rows
instead of charts is what turns 76 into 79"*; *"a narrower pattern reported 12
false inert rows, four of which DID carry strings"*. That is the strongest
compliance signal in the whole study — unprompted, unanimous, and each instance
paid for itself by catching a real miscount.

One line in Half 1 (`:12`). Keep it to: **if the script counts something, the
header names the unit counted and the plausible wrong unit it rejects.**

### T4 (G8) — an unranked fan-out output is the defect

`agent-teams/SKILL.md`. **Pilot evidence:** `gate_chart_budget.py` re-framed what
a handoff had called a global budget failure ("79 rows against ≤32, fails by
2.5×"). Measured per section against the outline's own slot counts, it was not
global: **every sub-agent that ranked its rows came in at or near its allocation
and named its own drop candidates; the two that emitted unranked rows produced
all of the overflow.**

Case-study §6.5 (*ranks or shares, never absolute counts*) is the **consumer**
side of this. T4 is the **producer** side: a teammate that returns a list instead
of a ranking has not finished, and the lead should send it back rather than
trim it.

Ran the gate 2026-08-17: still red at 2.4×, with §1/§4/§9 all `ranked? NO`.
**Still-red is evidence the diagnostic keeps working**, not evidence it failed —
do not read it as a reason to soften the rule.

### T5 (meta-finding) — the promotion trigger in `plan-lifecycle.md`

**Measured:** of **9** reusable rules the pilot wrote during one plan, **3**
reached `.claude/conventions/project/` (all into `visualization.md`, commit
`1360b06`). **6 are still in a closed plan's directory**, where nothing reads
them.

`project-conventions.md` says how to *write* a project convention (`:81`, `:156`)
and where it lives. Grepped for `promot|when to|trigger|graduat|stage`: **it
never says when a plan's by-product becomes one.** So the default is "leave it in
the plan dir".

This is case-study §6.8 — *a mechanism invented and filed where it cannot act* —
recurring one layer below where **Phase 1 just fixed it**. Note that symmetry in
the text; it is the argument for the rule.

**Where:** `plan-lifecycle.md` Stage 4 (`:178-200`). A rule the plan wrote that
will outlive it moves to `.claude/conventions/project/` before archival. The
**archivist** already runs at step 3 (`:187`) and is the natural checker — add it
to what the archivist synthesizes, not as a separate hook.

## Constraints

- **No new always-fire hook, no layout change, no new directory.** Unchanged from
  `plan.md`.
- **T1's key is optional and never inferred.** Principle §5.3. A heuristic that
  populates `scope_authored` would be self-refuting.
- **No absolute-count thresholds** (case study §6.5). None of the five needs one.
- **Nothing engagement-specific.** The pilot's numbers are evidence and belong in
  this phase file; Córdoba, `gl_save()` and the Growth Lab bundle do not belong
  in a shipped convention. `CLAUDE.md`: proving ground, not content.
- **Both installers copy `.claude/conventions/` by directory walk**
  (`install-project.js:171`, `upgrade.js:258`), so **no installer edit is needed**
  — these are all edits to existing files. Same for the skill.
- **`templates/CLAUDE.md.template`** gets a pointer line only if a rule here
  changes what a project author must know at write time. T1 does; T2–T5 do not.
  §6.7: one line under *Where Things Go*, never a new section.

## Verification

1. `scope_authored` appears in `evidence.md`'s frontmatter block **and** its
   rationale section, and the text states that absence means "unchecked".
2. `citation-discipline.md` greps non-empty for `collision`, and the text names
   the inline disambiguator as the rejected option, not as an alternative.
3. `provenance.md` Half 1 carries the unit line; `grep -c` on absolute-count
   thresholds across all files touched is **0**.
4. `agent-teams/SKILL.md` states the ranking requirement in the fan-out output
   contract, where a lead reads it — not in a preamble.
5. `plan-lifecycle.md` Stage 4 names `.claude/conventions/project/` and assigns
   the check to the archivist.
6. **Against the pilot:** its `research/evidence/150_*.md` must satisfy T2's
   banner spec as written. If it does not, T2 is specced wrong — the pilot's
   banner is the thing that worked, and the spec is supposed to describe it.

## Commit discipline

**Commit by pathspec**, never `git add -A` (`provenance.md` § Half 2). Five items
across five files; T1–T3 and T5 are one file each, so five pathspec commits, one
per item. Do not batch — `log.md` D4 is the shared rationale and each commit
message should name its own item and its own pilot evidence.


---

## Execution notes (2026-09-09)

**All six criteria verified**, each by a command, not by reading:

| # | Result |
|---|---|
| 1 | `scope_authored` in the frontmatter block **and** its own `####` rationale; "Absent means 'nobody has checked', never 'checked and wrong.'" present |
| 2 | `citation-discipline.md` greps **7** hits for `collision`; disambiguator carries "rejected, not an alternative" and "do not use" |
| 3 | unit line inside Half 1 (`awk` between the two Half headings); **0** new absolute-count thresholds across the whole phase diff |
| 4 | all three T4 elements inside `## Output Collection` (`:133-211`) — report-block section, rule, consolidation step |
| 5 | Stage 4 names the destination and assigns the check; archivist step 4 exists and is **ordered before** the delete step (`:56` < `:60`) |
| 6 | pilot `150_*.md` satisfies **6/6** banner elements; `149_*` and `151_*` also 6/6 |

### The pilot repo has moved

`~/cordoba-growth-narrative` → **`~/research/cordoba`**. The handoff's path is
dead; every pilot-facing command in this plan needs the new one.

### Three things the artifact settled that the spec could not

Criterion 6's method — write the spec from the shipped banner, then check the
banner against it — paid for itself three times:

1. **`(was #NN)` lives on the frontmatter `headline:` key** on the pilot, not on
   the H1. `evidence.md`'s shape carries the headline *as* the H1, so the spec is
   written shape-agnostically ("the doc's headline"). The pilot's H1 still opens
   `# 119 — …` with the pre-renumber id; under our shape there is no id in the H1
   at all, so this does not propagate.
2. **The pilot set `status: revised` on all three renumbered docs**, which by
   `evidence.md`'s own definition means part of the doc is retired. Nothing was
   retired — the id moved. T2 therefore says `status:` does **not** change, and
   flags the pilot's choice in a parenthetical rather than folding it into the
   banner spec, so criterion 6 still resolves against what actually shipped.
3. **T1 is already live on the pilot**, comment and all
   (`scope_authored: true   # unit/period hand-checked …` on 149/150/151). The
   graduation is codifying a field that is in production, which is the strongest
   form of §6.6.

### The recurrence count was corrected before it shipped

A first draft enumerated the five collision appearances from memory and got the
breakdown wrong. The study says "fifth appearance" and does not enumerate. The
shipped text states the count and names the **three distinct vectors** that are
documented (parallel worktrees, parallel agent teams, a second numbering
namespace), which is what a reader needs and is verifiable. Same correction
applied to a "still correct a year later" claim about a repair made five weeks ago.

### One out-of-phase commit — `2d21597`, and why it was not optional

`project-conventions.md` still described project conventions as living in
`project_conventions/` **at the project root** — the v1 path, in 9 places, in the
single file that tells an author how to write one. v2 moved them to
`.claude/conventions/project/`, and `templates/migration/01_layout.sh:80-86`
actively moves the old directory there and `rmdir`s it.

T5 sends the archivist to `.claude/conventions/project/`. An agent following T5
would consult this file for the domain-file recipe, be told to create
`project_conventions/<domain>.md`, and **re-create a directory the migration
deletes** — the exact failure the graduation study found in `02_repath.py` (deck
scripts `mkdir`-ing their v1 target). Shipping T5 on top of it would have
manufactured the bug the study had just diagnosed.

Path only, 9 occurrences plus one "at the project root" phrase. Everything else
stale in that file was left alone and is reported below.

### Found, not fixed — for the Phase 7 stale-pointer sweep

**Five `.claude/conventions/*.md` pointers repo-wide resolve to nothing:**

```
.claude/conventions/data-access.md        .claude/conventions/handoff-format.md
.claude/conventions/data-sources.md       .claude/conventions/learning-capture.md
.claude/conventions/decision-records.md
```

Reproduce:

```sh
grep -rhoE '\.claude/conventions/[a-z-]+\.md' .claude/ templates/ \
  | sort -u | while read f; do [ -e "$f" ] || echo "MISSING: $f"; done
```

Same class as **task 7.3b** (the v1 methods path live in eight files): v2
consolidated 13 conventions into 7 + 2 and the inbound pointers were not all
repathed. `project-conventions.md:176` also still says **"super-claudio-research"**
and routes methodology calls to `decisions/YYYY-MM-DD_<slug>.md` via
`decision-records.md`, which is one of the five missing files — so that paragraph
sends a reader to a directory and a protocol that both no longer exist.

**This needs a researcher call**, which is why it was not fixed here: three of the
five names (`data-sources`, `handoff-format`, `learning-capture`) plausibly map onto
files that exist under new names, but `decision-records` has no v2 successor in
`.claude/conventions/`, and deciding where a decision record lives in v2 is a
convention question, not a repath.