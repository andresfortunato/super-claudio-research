# Phase 5 — `/pipeline-check`

**✅ DONE 2026-09-09.** All four tasks, all five verification criteria. Commit
`2e4f404`, preceded by the constitution amendment `c7543f5`.

**⚠ Decision C was answered AGAINST the recommendation in this file: it runs the
script directly**, no second confirmation (`log.md` **D8** §1). **Task 5.3 as
written below is superseded** — read *Execution notes* before trusting it. The
constitution was amended first, per CLAUDE.md.

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phases 2, 3 · **Blocks:** nothing
**Session scope:** one session · **Estimated context:** ~35%

## Intent

Principle 9 of the constitution demands **verifiable freshness anchors**: every
freshness timestamp paired with a concrete re-runnable value, so a date stamp
becomes a smoke test. v1 bound that to source docs and method diagnostic-counts.

Nobody noticed that **an evidence doc's `## Measured` block is already exactly
that** — a set of concrete numbers produced by a documented procedure. v2 even
made it verdict-free by lint, which is what makes it mechanically comparable in
the first place. This phase treats it as the anchor it is.

That is also why this mechanism is not `manifest.jsonl` returning: the manifest
captured *how a run happened*, which git plus a script header already covers. This
compares *what the run produced* against what was written down.

## Why this is a new cost tier, not a violation

`docs/verification-architecture.md` warns that a skill wanting a budget *between*
`/verify` (2k) and `/deliverable-review` (12k) is a yellow flag — there is
probably no real concern at that intermediate scale. This skill is cheap in tokens
and expensive in **wall-clock and compute**, which is a different axis, not an
intermediate point on the existing one. Phase 7 adds that axis to the architecture
doc explicitly. Do not let this land as a silent exception — the constitution's
own rule is that an intentional failure revises the document first.

## Tasks

**5.1 — `.claude/skills/pipeline-check/SKILL.md`** ✚
Three entry forms: an evidence id, a claim (checks everything it rests on), or
`--stale` (everything invariant 10 flagged). For each doc: resolve to its
producing script through the provenance trail — `artifacts:` path → `git log --`
→ the commit's `Run:` line → the script → its header's `Inputs:`/`Seed:`/`Env:`.
Report the diff between the numbers in `## Measured` and what a re-run produces.

**5.2 — The refusal path is the feature.** An evidence doc with no traceable
script must produce **"cannot trace"**, never a guess. §5.3's lesson generalizes
past frontmatter: a confidently wrong answer is worse than a blank one, because
it gets trusted and then manufactures a contradiction. Enumerate the untraceable
cases explicitly — no `artifacts:`, no `Run:` line in the commit, script deleted
since, header missing.

**5.3 — Default posture: report and hand over.** Name the scripts, print the
commands with their seeds, stop. Pending C, the execute path is a second
confirmation, never the default, and it never runs a script whose header it could
not read (no seed → no reproducible comparison → the diff is meaningless).

**5.4 — Say what it does not do.** It is not a correctness proof and not a
replacement for `/verify`: it answers *do the recorded numbers still hold?*, not
*are the numbers right?* A pipeline can reproduce a wrong number perfectly.

## Verification

- Fixture where a chart was re-rendered after its evidence doc's `date:` — the
  skill identifies the doc **without executing anything**.
- Fixture with a deleted producing script — reports "cannot trace", makes no guess.
- Fixture with no `Seed:` in the header — refuses the comparison and says why.
- Token cost stays low even where wall-clock is high; if the report grows with the
  number of docs checked, cap it **and print the dropped count** (no silent caps).
- New skill dir needs no installer edit — see `context/installer-map.md`.

## Do not touch

`lint-research.sh` (Phase 3), the conventions (Phase 2), Phase 6's file list.
Do not extend `/verify` — that boundary is Phase 4's to draw.

## Commit discipline

By pathspec, one command.

## Execution notes — 2026-09-09

### 5.3 is superseded; what replaced it

Specced as *report and hand over; execute only on a second confirmation*.
Answered: **execute directly.** Reporting staleness and printing a command makes
the researcher a copy-paste relay for a decision the check already made.

**This introduced a hazard the specced design did not have.** A re-run
overwrites the artifact in place, so the skill can now destroy work. The fix is
a **precondition, not a warning**:

> The working tree must be clean for every path the run will write, or the skill
> refuses and names the dirty paths. **Git is the undo**, and an uncommitted
> artifact has none.

Everything else in 5.3 survived and matters more now, not less: it never runs a
script whose header it cannot read, and **no `Seed:` means refuse the comparison**
— an unseeded diff is indistinguishable from sampling noise.

### The constitution was amended before the skill landed

`c7543f5`. Principle 7 graded verification by **token cost** and all three
shipped tiers were read-only — a posture that was never a stated principle, just
a coincidence of the first three tiers all being *review* tools. It now carries a
side-effect axis and four bounds. This section of the phase file predicted the
need ("do not let this land as a silent exception") and was right.

**Still owed to Phase 7:** `docs/verification-architecture.md` has not been
updated with the axis. This file assigns that to Phase 7 and it stays there.

### G9 held, and implied a case the tasks did not list

*The correct granularity is not the finest.* Compare numbers, never bytes and
never timestamps. Invariant 10 already embodies this — it compares **commit
timestamps, not mtimes**, which sidesteps G9's `git checkout` objection entirely,
so `--stale` is a pure reuse with nothing to reimplement.

**The unanticipated consequence: an image-only script is a `cannot compare`, not
a pass.** `## Measured` numbers are not recoverable from a PNG, and byte-diffing
an image reports every palette change as a finding — the exact noise G9 rejects.
Look upstream for a numeric intermediate; report `cannot compare` if there is
none. **Never report "unchanged" because a chart merely re-rendered.**

### Verification, criterion by criterion

| Criterion | Result |
|---|---|
| chart re-rendered after the doc's `date:` — identified **without executing anything** | invariant 10 flagged `#2` from git alone; then classified `cannot compare — image-only output` |
| deleted producing script → "cannot trace", no guess | `cannot trace — script deleted (analysis/03_gone.py)` |
| no `Seed:` → refuses the comparison and says why | `cannot compare — unseeded run` |
| token cost low where wall-clock is high; cap lists and print the dropped count | report is four fixed sections, every list capped with a stated drop count |
| no installer edit | verified — symlink appears from an unmodified `installGlobals()` run |

**Plus the happy path, which the criteria did not require and should have:** the
traceable seeded numeric fixture walked the full chain, re-ran in 35ms, and
caught the panel mean moving **4.2 → 5.05** and n **3 → 4** after `data/raw/` was
refreshed. A refusal-only test set proves the skill declines correctly and
nothing about whether it works.
