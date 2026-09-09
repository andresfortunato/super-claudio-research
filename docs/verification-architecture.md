# Verification architecture — design rationale

## The problem this solves

Research deliverables fail in different ways at different stakes, and a
single verification mechanism can't catch all of them without becoming
either too noisy (false-positive fatigue) or too lax (silent misses on
high-stakes work). The framework's answer is **stakes-graded
verification**: a small set of tiers, each cheap-by-budget at its own
scale, each fired by a different trigger, each with a non-overlapping job.

The tiers, ordered by cost:

| Tier                     | Trigger          | Token cost  | Side effects        | Cadence                            |
|--------------------------|------------------|-------------|---------------------|------------------------------------|
| `lint-research.sh`       | Manual / CI      | ~0          | read-only           | Before a commit; in CI             |
| `/verify`                | User-invoked     | ≤2k         | read-only           | Per-artifact, before publishing    |
| `/cite-check`            | User-invoked     | ≤2k         | read-only           | Per finished deliverable           |
| `/pipeline-check`        | User-invoked     | ≤2k         | **writes derived files** | When the inputs under a number moved |
| `/deliverable-review`    | User-invoked     | ≤12k        | read-only           | Per advanced draft, before sending |

The first is a **bash script** — no model in the loop, so its cost is
wall-clock (2.3s over a 285-document corpus) rather than tokens. The rest
are **user-invoked**: verification at this cost is a deliberate act, not an
ambient one. Nothing here fires automatically, and that is a design
commitment, not an omission — see *Why nothing fires automatically* below.

**Two axes, not one.** Through v2 the tier list graded by token cost alone,
and every tier was read-only — which was a coincidence of the first three
all being *review* tools, never a stated property. v3's `/pipeline-check`
re-runs analytical scripts, so the list needed a second axis and the
constitution was amended to carry it (`docs/audience-and-philosophy.md`
principle 7, 2026-09-09):

| Axis | Question |
|---|---|
| **Token cost** | zero / ≤2k / ≤12k — how much context does invoking it spend? |
| **Side-effect cost** | read-only / writes derived files / writes source files — what does it change if it is wrong? |

Underneath all of them sits the **provenance substrate**: the script header
and the `Run:`/`Out:` commit lines, both in
`.claude/conventions/provenance.md`. These aren't verification tiers
themselves — they're the audit trail that `/verify` and `/pipeline-check`
read against. `git log -- output/<file>` resolves to a commit whose message
names the producing script; the script's header documents inputs, seed, and
env. No automatic log, no `jq` dependency.

## Why several tiers, not one

A single always-fire verification hook would face an impossible tradeoff:
broad enough to catch real defects (and produce noise on every turn),
or narrow enough to be quiet (and miss most real defects). Each tier takes
a different cut at the verification problem:

- **`lint-research.sh`** catches *mechanical breakage in the record*. A
  duplicate evidence id, frontmatter missing a required key, a claim resting
  on an id with no file, an `artifacts:` path that doesn't exist, a doc
  pointer that resolves to nothing. Everything here is decidable by grep,
  which is why it needs no model and can run in CI.
- **`/verify`** catches *artifact-level defects*. The regression's
  signs flipped, the chart's axis is wrong, the paragraph cites a
  number that doesn't exist.
- **`/cite-check`** catches *an unused chain*. The lint proves a reference
  resolves; this proves the deliverable actually made one — that every
  number in a finished memo traces to a claim, and every claim it leans on
  is still standing on live evidence.
- **`/pipeline-check`** catches *drift under a number that nobody re-read*.
  The evidence doc is fine, the chart renders, and the source published a
  new wave three weeks ago.
- **`/deliverable-review`** catches *deliverable-level defects*. The
  draft overclaims, the framing dismisses an alternative, the
  recommendations ignore implementation capacity, the audience is
  wrong.

Each is necessary; none subsumes another. Trying to fold any pair
together compromises both.

**The cheap half is mandatory; the expensive half is optional.** Each of the
three chain links v3 added ships as a lint invariant *and* a skill, and never
as a skill alone. Link resolution and staleness are grep — they belong in
bash, run for free, on every corpus. Walking a deliverable's numbers and
re-running a pipeline need a model and cost real budget, so they are
user-invoked. A mechanism that shipped only its expensive half would be
adopted by whoever remembered to type it.

## Provenance substrate (a convention, not a tier)

**Covered in `.claude/conventions/provenance.md`**, which merged v1's
separate `script-header` and `analytical-commit-format` conventions — they
were always read together and each restated the other's half of the same
audit trail.

Every analytical script starts with a fixed-shape header:

```
# Script:   scripts/06c_fdi_at_entry.R
# Inputs:   data/clean/wdi.csv
# Outputs:  output/06c_fdi_at_entry.png, output/06c_fdi_at_entry.csv
# Seed:     42
# Env:      R 4.3.1, tidyverse 2.0.0
```

Every commit that produces analytical artifacts includes `Run:` and
`Out:` lines:

```
Add FDI-at-entry chart for Phase 3 diagnostic

Run: scripts/06c_fdi_at_entry.R
Out: output/06c_fdi_at_entry.png, output/06c_fdi_at_entry.csv
```

Together these turn `git log` into the audit trail. Given a chart,
`git log -- <path>` finds the commit, the message names the script,
the script's header documents the run.

This replaces an earlier `manifest.jsonl` automatic-log mechanism. The
trade-off: the manifest captured per-run metadata automatically (no
researcher discipline needed) but cost a hook + a `jq` dependency + a
JSONL substrate. Conventions cost zero install and rely on git, which
the project already uses. The discipline is on the researcher; `/verify`
flags missing headers when it can't trace an artifact.

## Tier 1: `lint-research.sh`

**See `.claude/hooks/lint-research.sh`.**

Eighteen invariants over the research record, in pure bash. Every one of
them is a defect that actually happened on the Córdoba pilot — that is the
admission test, not a designer's guess at what could go wrong. Run it by
hand before a commit, or from CI. It reads the evidence corpus once into an
array and takes 2.3s over 285 documents.

Two verdict tiers inside it, and the split is deliberate:

- **FAIL** (exit 1) — a broken link or a duplicate id. Always mechanical,
  never a judgement call, and never so numerous that a mid-adoption project
  drowns in them.
- **WARN** (printed, counted, exit 0) — findings that need an eye before
  they mean anything, or whose true-positive count on a real project is
  large enough that failing the build would train everyone to ignore the
  linter. A check that can't decide is FAIL *only if a green run on a
  correct project is genuinely reachable today.*

**It is a script, not a hook, and that is the interesting part.** v1 shipped
this job as a Stop hook, `check-evidence.sh`, which nudged when analysis
artifacts were uncommitted with no evidence doc staged. Its "did you already
write one?" check globbed the v1 `evidence/` path, so once v2 moved the
corpus under `research/` the condition could never be satisfied and the
nudge fired *unconditionally*. v2 removed it.

The lesson generalised into principle 1 of the constitution: **a
silent-by-default hook whose silence depends on a path is one refactor away
from firing every turn.** The same invariants in a script that a person or a
CI job runs cannot degrade that way — if it breaks, it breaks visibly, in
one place, and nobody's session is nagged. Everything v3 added to the cheap
tier went here for that reason, and v3 adds no hook at all.

## Tier 2: `/verify`

**See `.claude/skills/verify/SKILL.md`.**

A user-invoked skill that runs three to five domain checks against a
single named artifact (regression result, chart, paragraph). Provenance
checks use `git log` + commit message + script header — inline, no
subagent.

Cost: ≤2k tokens per invocation.

The check menus (regression / chart / paragraph) are deliberately
narrow — sign of coefficients, magnitude plausibility, missingness,
source citation, provenance (git → commit → script → header). The skill
picks 3–5 checks per invocation, biased toward cheap checks, and emits
a structured markdown report.

Why user-invoked, not automatic:
1. The check menu requires judgment about which lens applies (no
   automatic hook can know whether a regression coefficient's sign
   is wrong without the user's prior).
2. Always-fire verification on every artifact would either spam
   the chat (always running) or stay silent in cases that mattered
   (running selectively without context).
3. Running cheaply is the design property — making it user-invoked
   means the cost is paid only when a researcher actually wants the
   check.

## Tier 3: `/cite-check`

**See `.claude/skills/cite-check/SKILL.md`.**

A user-invoked walk of one finished deliverable's citation chain:

```
deliverable ──[C12]──→ claim ──Rests on: #71──→ evidence ──artifacts:──→ artifact
```

Cost: ≤2k tokens per invocation — the same tier as `/verify`, deliberately.

**Why it is not a `/verify` check menu.** They share a budget and a trigger
moment, so folding them was the obvious move, and it was rejected on shape.
`/verify` runs three to five *judgement-shaped* checks on one artifact and
picks which ones apply. `/cite-check` is mechanical and exhaustive: it
enumerates every number in a document and asks the same question of each.
A menu that sometimes runs is the wrong container for a walk that must not
skip a row. The boundary is written into `verify/SKILL.md` as well, so a
session reaching for the wrong one is redirected.

**Why it is not the lint.** Invariants 13 and 14 already check that a
deliverable's `[C12]` and `#71` references *resolve*. Nothing in bash can
check the other half — whether the number in the sentence is the number in
the evidence doc, and whether a paragraph asserting something quantitative
cited anything at all. That is the Córdoba finding this exists for: three
load-bearing memo numbers with no evidence doc anywhere, invisible for six
months, and invisible to grep because there was nothing to grep for.

## Tier 4: `/pipeline-check`

**See `.claude/skills/pipeline-check/SKILL.md`.**

Traces an evidence doc to its producing script through the provenance
trail, re-runs that script, and diffs what comes back against the doc's
`## Measured` block.

Cost: ≤2k tokens — and minutes of wall-clock. **This is the tier that
introduced the second axis.** It is cheap in tokens and expensive in
compute, which is a different thing from the ≤2k/≤12k gradient, and it is
the only tier in the framework that writes anything.

`## Measured` is already a principle-9 freshness anchor and nobody had
noticed: concrete numbers produced by a documented procedure, kept
verdict-free by lint invariant 5, which is exactly what makes them
mechanically comparable to a re-run. The skill did not have to invent an
anchor format; it had to recognise one.

**The four bounds that permit a side-effecting tier** (constitution,
principle 7, amended 2026-09-09 *before* this shipped):

1. It re-runs existing, human-inspectable code — never writes or edits a
   script. The *No LLM-managed source-of-truth code* boundary is unchanged;
   only the trigger moved.
2. It writes only derived files the script declares in its header
   `Outputs:`. Never `data/raw/`, never source, never a deliverable. A
   derived file is reproducible by definition, which is what makes an
   unwanted re-run cheap.
3. It stays user-invoked. An always-fire tier that executes scripts is a
   build system, and this framework is explicitly not a workflow engine.
4. It reports what it ran. Execution without a record is the thing
   `provenance.md` exists to prevent.

A future proposal that wants to write *source* files does not inherit this.
It fails principle 7 as amended and revises the constitution again.

**Why it re-runs rather than reporting.** The recommendation on file was
report-and-hand-over: print the command, let the researcher run it. That was
overruled, and the reason is worth keeping. The finding is "this chart is
older than the data under it"; the only useful response to that finding is
to re-render the chart. Printing a command the researcher then pastes back
makes them a copy-paste relay for a decision the check already made.

## Tier 5: `/deliverable-review`

**See `.claude/skills/deliverable-review/SKILL.md`.**

A forked parallel review for advanced deliverable drafts. Spawns one
subagent per lens (data validity, identification/reasoning, robustness,
framing, audience-fit, political-economy realism, peer-Lab
plausibility) via the Task tool, in parallel, in the same turn. Each
lens runs in its own context and reports back a fixed-format
findings-and-questions block. The parent skill then synthesizes into
a single consolidated report.

Cost: ≤12k tokens total (≤1.5k per lens × 7 lenses + ≤1.5k synthesizer).

Why forked-parallel, not sequential:

Sequential seven-pass review (one context, seven readings) suffers from
contamination: pass three reads pass two's flags and biases toward
confirming them; pass seven sees so much accumulated context it
struggles to focus. Forked-parallel review trades the cost of seven
fresh contexts for genuine independence — when two lenses agree on a
finding, that agreement carries information; when they disagree,
the disagreement is itself the signal.

Why user-invoked:
1. 12k tokens is too expensive to spend on every save.
2. Many drafts are mid-composition; running parallel review on a
   half-written draft is wasted budget.
3. The deliverable's profile (length target, audience, recommended
   lenses) is the right cue — and the user sets the profile by
   choosing which deliverable template to start from.

Why advanced-drafts-only:
- Forked review is structural and substantive. It catches "this draft
  overclaims" / "this draft has the wrong frame" — issues that only
  exist once a draft has structure to evaluate. On an outline, every
  lens would correctly say "not enough here to evaluate."
- The skill refuses to run on drafts that look incomplete (no
  executive summary, sections marked TBD, numbers marked `[CHECK]`)
  and points the user at `/verify` for partial checks.

## How the tiers compose

Picture a researcher's day:

1. **Mid-analysis** — `Rscript scripts/06c.R` runs. The chart appears
   in `output/`. No automatic log; the researcher commits when done with
   the change, including `Run:` and `Out:` lines per `provenance.md`, and
   writes `research/evidence/03_fdi_entry_threshold.md` with an
   `artifacts:` key naming the chart. Both files in one commit.
2. **Before that commit** — `bash .claude/hooks/lint-research.sh`. 2.3s,
   no tokens. It catches that the new doc's id collides with one already on
   disk, because a parallel worktree allocated the same number an hour ago.
   Nothing else in the framework would have seen that.
3. **Before publishing the chart externally** — the researcher types
   `/verify output/06c_fdi_at_entry.png`. The skill picks four
   chart-menu checks (axis sanity, provenance, source citation,
   data freshness), runs `git log` to trace the chart to its script,
   reads the script's header, returns a report in ≤2k tokens. One flag:
   the chart's underlying CSV has a more recent commit than the chart
   itself.
4. **So they run `/pipeline-check #03`.** It traces the doc to
   `scripts/06c.R`, prints what it intends to run, re-runs it, and diffs
   the result against `## Measured`. Two of five numbers moved: the source
   published a new wave. The doc is updated with the new numbers and a
   fresh date; the chart is re-rendered as a declared output of the script.
5. **Before sending the deliverable** — `/cite-check
   deliverables/cordoba-diagnostic.md`. Every number in the memo traced to
   a claim, every claim to live evidence. Three numbers in the executive
   summary cite nothing at all; one claim rests on an evidence doc that was
   retracted last month.
6. **Then `/deliverable-review`** on the same file. The
   skill reads the country-diagnostic-memo profile, spawns 7 lenses
   in parallel, synthesizes. Total cost ≈10.8k tokens. Three cross-lens
   agreements, five single-lens findings, one researcher-decision
   point. Researcher addresses the agreements, considers the
   single-lens flags, makes a call on the decision point, then
   sends the deliverable.

Steps 2 and 5 are the v3 additions, and they sit at the two ends: the
cheapest tier, run most often, and the last mechanical check before a
document leaves the building. Nothing in the sequence fires on its own; each
step is a thing the researcher chose to do. The total cost across a day of
analysis is dominated by the (rare) deliverable-review invocations.

## Why nothing fires automatically

Every tier above is manual or user-invoked. That is not an accident of what
has been built so far — it is the same conclusion reached three times:

- **v1** shipped a `manifest.jsonl` PostToolUse hook and removed it: git plus
  a script header gave ~80% of the audit value at zero install cost.
- **v2** removed `check-evidence.sh`, the Stop hook, for firing
  unconditionally after a path refactor.
- **The pilot reached it independently.** Its `gate_retracciones.py:132-146`
  prints rows and asks for an eye rather than shipping a test that
  misreports, because a stopword check called 12 of 40 rows wrong.

Always-fire reviews train Claude *and* researchers to discount review output
as background noise, and mechanical compliance is the specific failure — a
trivial evidence doc written to satisfy a rule is worse than no evidence doc,
because it looks like coverage. v3 added five checks and two skills and no
hook. If the discipline needs a tripwire, the tripwire belongs in CI, where
it fails loudly in one place instead of quietly in everyone's session.

## Why these specific budgets

The cost budgets aren't arbitrary; they're sized to the cognitive job:

- **2k tokens** for `/verify` is "three-to-five focused checks plus a
  structured report" — anything more means the skill is sliding
  toward review territory and should be using `/deliverable-review`.
- **12k tokens** for `/deliverable-review` is "seven independent
  readings plus a synthesizer" — anything less compromises the
  independence (lenses get squeezed and contaminated); anything more
  means the synthesizer is over-elaborating.

If a future skill wants a budget between `/verify` and
`/deliverable-review` (say, 5k tokens), that's a yellow flag — there
probably isn't a real concern at that intermediate scale. Either it's
artifact-level (use `/verify`) or it's deliverable-level (use
`/deliverable-review`).

**The yellow flag is about the token axis only, and `/pipeline-check` is the
case that made that explicit.** It is not *between* the two budgets; it is
≤2k tokens and expensive on a different axis entirely. A proposal that
answers "what budget do you want?" with "a different kind of cost" is not
tripping this flag — it is describing an axis the list may not have yet. Two
proposals in one release wanting the same new axis is the signal to add it;
one is the signal to ask harder whether the tier is real.

## What this architecture does NOT do

- **No automatic deliverable review.** Forked-parallel on every save
  would cost ~12k tokens × dozens of saves per day = obvious
  budget collapse. Always user-invoked.
- **No automatic per-run audit log.** Earlier drafts shipped a
  `manifest.jsonl` PostToolUse hook. Removed: the bookkeeping value
  didn't pay for the install footprint when git + `provenance.md` cover the
  same audit needs at zero cost.
- **No writes to source.** `/pipeline-check` re-runs scripts and refreshes
  their declared outputs. Nothing in this architecture edits a script, a
  deliverable, or anything under `data/raw/`, and a proposal that wants to
  must revise principle 7 first.
- **No proof that a number is *right*.** `/pipeline-check` asks whether a
  number still reproduces. A pipeline reproduces a wrong number perfectly.
- **No correctness proof.** Verification surfaces flags; researchers
  resolve them. False negatives are possible at every layer.
- **No replacement for human review.** The peer-Lab-plausibility lens
  approximates a senior peer; it doesn't replace one. The political-
  economy-realism lens approximates a senior policy advisor; it
  doesn't replace one. These are first-pass filters.
- **No version control of verify reports.** Verification reads the
  current file; it doesn't track verification history across versions.
  If you want that, commit the verify report alongside the artifact.
- **No quality enforcement at write time.** The lint doesn't block a
  commit; skills don't refuse to run on weak analysis. (`/pipeline-check`
  refuses on a dirty working tree, which is a safety precondition on a tier
  that executes, not a quality gate.) The framework surfaces; the researcher
  decides.

## Tradeoffs accepted

- **User-invoked is opt-in.** A researcher who never types `/verify` and
  never runs the lint gets nothing. Trade: predictable cost vs opt-in
  coverage. Accepted because mandatory verification at high cost
  (always-fire `/deliverable-review`) is far worse — and mitigated at the
  cheap end, where `lint-research.sh` costs nothing to wire into CI and is
  the one tier a project can make non-optional without paying per turn.
- **The check menus in `/verify` are not exhaustive.** They catch
  the most common failure modes (sign, magnitude, missingness,
  citation, provenance). A subtle defect outside the menu won't be
  caught by `/verify` and will need `/deliverable-review` or human
  review.
- **Provenance depends on researcher discipline.** Without script
  headers and `Run:`/`Out:` commit lines, `/verify` can still run
  domain checks but its provenance check returns "no header" or "no
  Run: line in the producing commit" — surfacing the missing
  discipline rather than silently passing.
- **The seven lenses are policy-research-flavored.** A different
  research domain (e.g., clinical trials) would weight different
  lenses. The framework ships with the policy-research seven; the
  lens set is editable per project.
- **Forked-parallel costs 7×.** Worth it for the independence
  property; not worth it on a mid-composition draft (hence the
  advanced-drafts-only rule).

## Extension points

- **New artifact types in `/verify`.** Add a new check menu (D, E, F)
  to `verify/SKILL.md` for, e.g., synthetic-control results, structural
  estimation outputs, or qualitative interview transcripts.
- **New lenses in `/deliverable-review`.** Add an eighth lens (e.g.
  "ethics review" or "data-protection review") for engagements that
  need it. Update the per-deliverable profiles to include or exclude
  the new lens.
- **Project-specific check thresholds.** A project working with very
  short panels might tolerate higher missingness; a project working
  with very small effect sizes might tolerate weaker SEs. Edit the
  thresholds inline in the SKILL.md, or factor them into a separate
  project-config file referenced from the skill.
- **A new lint invariant.** The cheapest extension point in the framework,
  and the one v3 used five times. The admission test is that the defect
  actually happened on a real project and that a green run is reachable —
  see the FAIL/WARN split under Tier 1. `docs/extending.md` has the steps.
- **A script-header check in the lint.** The seam is there: flag a
  `scripts/*.{R,py,do}` with no header, or an `output/` file whose producing
  commit has no `Run:` line. Deliberately *not* a Stop hook — that shape was
  tried and removed twice. Add only if observed gaps in pilot use.

## Provenance

The tier structure adapts patterns from three sources:
- **Forked parallel review** — Pedro Cossio's seven-pass deliverable
  review, refitted to policy-research lenses (substituting
  political-economy-realism and peer-Lab-plausibility for code-shaped
  passes that don't apply to memos).
- **A conditional Stop hook** — v1's `evidence-logging` pattern. Kept here as
  the thing the cheap tier is *not*; see Tier 1.
- **The Córdoba pilot audit** (`docs/v2-case-study-cordoba.md`) — every lint
  invariant is a defect that happened there, and the three chain links v3
  checks are the three the audit found broken.

The provenance substrate (`provenance.md`) is native to this framework —
chosen over an automatic JSONL log because git already gives ~80% of the
audit value at zero install cost.

Adopted in this framework because policy-research deliverables fail in
failure-mode-shaped ways that no single tier can catch, and cost-graded
verification is the way to keep coverage broad without making cost ruinous.
