# Phase 5 — `/pipeline-check`

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phases 2, 3 · **Blocks:** nothing
**⚠ Gated on decision C** — may it execute project scripts at all?
Recommendation on file: report-and-hand-over by default, execute only on an
explicit second confirmation. Confirm before writing the execute path.
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
