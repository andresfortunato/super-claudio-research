---
name: deliverable-review
description: (r2p) Forked parallel review of an advanced deliverable draft (memo, briefing, paper) — spawns one subagent per lens (data validity, identification/reasoning, robustness, framing, audience-fit, political-economy realism, peer-Lab plausibility), each in a separate context, then synthesizes. Use when the user says "/deliverable-review <path>", "review this draft", "do a seven-pass review", "fork-review the memo before I send it", or otherwise asks for a heavy multi-lens audit on a near-final deliverable. Run only on advanced drafts. Budget ≤12k tokens total.
allowed-tools: Read, Bash, Glob, Grep, Task
---

# deliverable-review

A forked parallel review for advanced policy-research drafts. Adapts the
seven-pass review pattern (each pass an independent reading, no shared
state) to the specific failure modes of policy-research deliverables:
weak data, sloppy identification, brittle robustness, off-key framing,
wrong audience register, naive political economy, peer-Lab implausibility.

The point of forked review is **independence**. Seven sequential passes
done by the same context contaminate each other — pass three sees pass
two's flags and tends to confirm them. Seven parallel passes, each in
its own subagent context, each reading only the deliverable + its lens
brief, produce genuinely separate readings. The synthesizer then
reconciles agreements (high-confidence findings) and disagreements
(researcher-decision points).

## When to invoke

The user types one of:

- `/deliverable-review <path>` — point at a full draft
  (`deliverables/cordoba-diagnostic.md`, `briefings/minister-energy.md`).
- "Do a forked review of this memo before I send it."
- "Run a seven-pass review on the draft."
- "Fork-review with audience-fit and political-economy lenses."

## When NOT to invoke

- The draft is mid-composition (sections empty, headers TBD, numbers
  marked `[CHECK]`). Run /deliverable-review *only on advanced drafts*
  — the budget is too high to spend on incomplete work.
- The user wants a single artifact checked. Use `/verify` instead
  (≤2k tokens vs ≤12k).
- The user wants a quick proofread. Forked review is structural and
  substantive; copy-edit is a different job.
- No deliverable profile exists for the document type and the user
  hasn't named which lenses to run. Ask once before fanning out.

## Preconditions

- The target file exists and is non-trivial (≥800 words / ≥3 sections).
  Below this, parallel review is overkill — point the user at `/verify`.
- A deliverable profile (`templates/deliverables/<type>/PROFILE.md`)
  optionally exists. If yes, read it first — it names the recommended
  lenses, length target, audience, and success criteria. If no, default
  to the full seven-lens set.

## The seven lenses

Each lens is a separate subagent. Each runs in its own context, reading
only the deliverable + its lens brief + the supporting files the brief
points it at. Lenses do not see each other's work until the synthesizer
runs.

### 1. Data validity

Are the numbers in the deliverable real? Trace every numeric claim
back to `output/`, `research/evidence/NN_*.md`, or a cited external source.
Flag: numbers without a chain of evidence; numbers that disagree
with the underlying CSV or regression JSON; outdated numbers
(supporting file has a more recent commit than the deliverable's
chart was last regenerated); missing units; suspect rounding.

### 2. Identification / reasoning

Does the causal language match the analytical strategy? "X causes Y"
language requires identification (DiD, IV, RDD, RCT, structural).
Correlational evidence requires correlational language. Flag: causal
claims under correlational evidence; "treatment effect" framing on
descriptive panel work; mechanism stories not supported by mediation
analysis; selection bias unaddressed; reverse-causality alternatives
not ruled out.

### 3. Robustness

Are the headline findings stable? Look for: alternative specifications
run and reported, sensitivity to sample restrictions, sensitivity to
choice of controls, outlier checks, country/region drop-one tests
when relevant. Flag: a single specification reported as the result;
no robustness section; robustness section that doesn't actually
stress-test the claim.

### 4. Framing

Is the deliverable framed for its declared question? Check the title,
the executive summary, and the recommendations against the body.
Flag: title promises X but body answers Y; executive summary
overclaims relative to evidence; recommendations don't follow from
findings; framing dismisses a strong alternative without addressing it.

### 5. Audience-fit

Does the register, length, and structure match the audience named in
the deliverable's profile (or in its "Audience" section)? A ministerial
briefing should be ≤4 pages with a one-paragraph TL;DR; a peer Lab
research memo can be 20 pages with full methods. Flag: jargon density
mismatched to audience; length wildly off target; no executive summary
when the audience reads only that; methods buried where a peer-Lab
audience would read first.

### 6. Political-economy realism

For policy recommendations: would a real minister, ministry, or agency
actually adopt this? Flag: recommendations that ignore implementation
capacity (no budget line, no agency named, no timeline); recommendations
that assume political will the country lacks; recommendations that
copy-paste another country's experience without considering institutional
differences; technically correct recommendations that any senior
politician would dismiss in 30 seconds.

### 7. Peer-Lab plausibility

Would this hold up at a Growth Lab, World Bank, or comparable peer
review? Flag: methods choices a senior peer would query (e.g. "why
this exact panel window?"); claims that ignore a well-known prior in
the literature; framing that hasn't been benchmarked against the
two or three most-cited recent papers; deliverable presents itself
as novel when the result is well-known.

## Lens selection

If the deliverable has a profile (`templates/deliverables/<type>/PROFILE.md`
or its installed equivalent), read its `recommended_lenses` field. A
ministerial briefing weights political-economy-realism heavily and
peer-Lab-plausibility lightly; an internal research memo is the inverse;
a country-diagnostic-memo runs all seven.

If no profile exists, default to all seven. Do not silently drop lenses
without telling the user.

## Workflow

1. **Read the deliverable** once at the parent level (just enough to
   confirm it's an advanced draft and identify its profile / type).
2. **Read the deliverable profile** if present. Note the recommended
   lens set, the length target, the audience, the success criteria.
3. **Spawn one subagent per lens via the Task tool, in parallel, in
   the same turn.** Each subagent gets:
   - the deliverable path,
   - the lens brief (one of the seven sections above),
   - the relevant supporting files (`output/`, `research/evidence/`,
     `research/wiki/index.md`, the deliverable profile),
   - a strict ≤1.5k-token budget per lens (so 7 lenses × 1.5k ≈ 10.5k,
     leaving ~1.5k for the synthesizer).
   - a fixed report format (below) so the synthesizer can parse them.
4. **Wait for all subagents to return.** Do not start the synthesizer
   until every lens has reported.
5. **Run the synthesizer.** This is the parent skill, not a subagent.
   Read all seven reports. Produce the consolidated report (format
   below). Reconcile: lenses that agree on a finding are high-confidence;
   lenses that disagree become researcher-decision points.

## Per-lens report format

Each subagent must emit exactly this:

```markdown
## Lens: <name>

### Findings
- [HIGH] <one-sentence finding> — <one sentence of evidence>.
- [MED]  <...>
- [LOW]  <...>

### Open questions for the researcher
- <question> — <why it matters>.

### Lens scope
- Files read: <list>
- Files NOT read: <list of would-have-helped-but-out-of-budget>
```

`HIGH` / `MED` / `LOW` reflect the subagent's confidence, not the
severity of the issue. A high-confidence low-severity flag is more
useful than a low-confidence speculation.

## Synthesizer report format

The parent skill emits one consolidated report:

```markdown
# /deliverable-review <path> — YYYY-MM-DD

**Deliverable type**: <from profile, or "uncategorized">
**Lenses run**: <list — note any skipped and why>
**Total findings**: <n high, n med, n low>

## Cross-lens agreements (high confidence)
Findings flagged by ≥2 lenses, ranked by aggregate severity.

1. **<one-sentence consolidated finding>** — flagged by <lens A>, <lens B>.
   Evidence: <one sentence each>. Suggested action: <one line>.

## Single-lens findings
Findings raised by exactly one lens. Lower confidence; researcher's
call whether to act.

### Data validity
- ...

### Identification / reasoning
- ...

[... one subsection per lens ...]

## Researcher-decision points
Issues where lenses disagree, or where the lens flagged a tradeoff
(not a defect) requiring researcher judgment.

- <one-sentence framing of the choice> — <lens A> says X; <lens B> says Y.

## Lens scope and skipped checks
- <lens X> skipped <check Y> because <reason>.
```

Always emit all four sections, even if a section is `(none)`.

## Rules

- **Independence is the whole point.** Lenses must not share context.
  Spawn them in parallel via Task; the synthesizer is the only place
  state merges.
- **Advanced drafts only.** If the document is incomplete, refuse with
  a one-line explanation pointing at `/verify` for partial checks.
- **Budget discipline.** Total run ≤12k tokens. Per lens ≤1.5k.
  Synthesizer ≤1.5k. If a lens needs more, drop it and say so in the
  report rather than blowing the budget silently.
- **Read-only.** Never edit the deliverable. Never edit supporting files.
- **Surface disagreement.** If two lenses disagree, that's signal — put
  it in researcher-decision-points, don't average it away.

## Invocation example

```
User: /deliverable-review deliverables/cordoba-diagnostic.md
```

Skill will:
1. Read the deliverable (~3000 words, advanced draft).
2. Look for `templates/deliverables/country-diagnostic-memo/PROFILE.md`.
   Found. Read recommended lenses: all seven.
3. Spawn 7 parallel subagents via Task — one per lens — each with
   the deliverable path, the lens brief, and pointers to
   `research/evidence/INDEX.md`, `research/wiki/index.md`. Each capped at 1.5k tokens.
4. Receive 7 lens reports.
5. Synthesize: 3 cross-lens agreements (data validity + framing both
   flagged a stale chart citation; identification + peer-Lab both
   flagged a causal-language overreach), 5 single-lens findings,
   1 researcher-decision point (audience-fit says shorten exec summary;
   framing says expand it).
6. Emit consolidated report. Total ≈10.8k tokens.

```
User: /deliverable-review briefings/minister-energy.md
```

Skill will:
1. Read profile `templates/deliverables/ministerial-briefing/PROFILE.md`.
2. Note recommended lenses: data-validity, framing, audience-fit,
   political-economy-realism, peer-Lab-plausibility (5 of 7 — skip
   robustness and identification because the briefing is descriptive,
   not causal).
3. Spawn 5 lenses in parallel.
4. Synthesize. Report flags two political-economy-realism issues and
   one audience-fit length overrun.

## Cross-references

- `templates/deliverables/<type>/PROFILE.md` — recommended-lens metadata
  per deliverable type (Phase 6).
- `.claude/skills/verify/SKILL.md` — single-artifact alternative.
- `docs/verification-architecture.md` — how the four verification
  layers compose.

## What this skill does NOT do

- Does not run on incomplete drafts. Advanced-draft-only by design.
- Does not edit the deliverable. Read-only.
- Does not auto-fire. User-invoked only.
- Does not replace `/verify` for single-artifact checks. Use the
  cheaper tool when the question is narrow.
- Does not enforce a fixed seven-lens run — lens selection respects
  the deliverable profile, with all-seven as the default fallback.
