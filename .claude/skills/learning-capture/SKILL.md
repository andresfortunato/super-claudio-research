---
name: learning-capture
description: (r2p) Capture learnings from the current session — gotchas, insights, or discoveries worth preserving for future sessions. Use when the pre-compact hook reminds you, when the user asks to save a learning, or when you notice something worth remembering.
---

# Learning Capture

Capture institutional knowledge so future sessions don't repeat mistakes or miss discoveries. Learnings are the third bucket alongside `research/evidence/` (formal evidence-based findings) and `research/methods/` (peer-reviewable methodology calls): they hold the *tacit* gotchas and discoveries — the kind of thing a colleague would warn you about over coffee.

## When to use

- The pre-compact hook reminds you to capture learnings
- The user says "save a learning", "remember this", "capture this gotcha", or similar
- You notice something surprising, counterintuitive, or hard-won during any session

Common research-shaped triggers:

- A variable you assumed was present in a survey wave turned out to break in a particular vintage (PONDII didn't exist in 2014 EPH waves; CASEN's `o15` recoded between 2015 and 2017).
- A deflator series version diverges from peer-published numbers in a known way (PWT `rgdpe` vs `rgdpo` diverging by ~40% for oil exporters).
- A sample restriction had a side effect that wasn't visible until a later step (dropping `educ == NA` silently halved the rural sample).
- An asking-vs-transaction price gap, a respondent self-classification quirk, or an underreporting pattern the dataset's documentation doesn't surface.

## How it works (v2 — there is no `learnings/` directory)

v1 wrote every learning to `learnings/<slug>.md` plus a row in
`learnings/index.yaml`. That produced 70 files on the pilot engagement of which
**7 followed the prescribed format**, and a forgotten index row made a learning
invisible to retrieval. v2 routes the trap to wherever it will actually be read,
and the retrieval trigger lives in that same file.

1. **Identify what was learned.** Ask the user if it is not obvious. One trap at
   a time.
2. **Route it.** This is the only real decision:

   | If the trap would bite… | It goes in |
   |---|---|
   | anyone touching a **dataset or API** (expiring token, silent HTTP 200, a variable blank in one vintage) | `research/sources/<source>.md` → `## Gotchas` |
   | anyone applying a **specific method** (a pooling rule, a deflator seam, a classification break) | `research/methods/<topic>.md` → `## Traps` |
   | any **numerical or reasoning** work, with no single home (`rolling(center=True)` NaNs, two ×2 margins summing to ×3) | `research/methods/_craft.md` |
   | anyone using **r2p itself** (id collisions across worktrees, fan-out hygiene, agents sharing a git index) | the **framework repo**, `docs/field-notes/` — not this project |

3. **Append, symptom first.** `### <the trap as a claim>`, then the symptom that
   reveals it, then the fix. Be specific: "PWT rgdpo inflates oil-exporter
   productivity ~40% in 2010–2019 vs rgdpe" is useful; "be careful with PWT" is
   not.
4. **Check the `triggers:` line.** The destination file's frontmatter carries
   4–8 concrete keywords (variable names, dataset acronyms, codes, year ranges).
   If the new trap introduces a term someone would actually type — `pondiio`,
   `pp04b`, `cognito` — add it. That single line is the whole retrieval contract;
   there is no separate index to forget.
5. **If the trap is load-bearing, say so in the destination's `## Scope and
   limits`** rather than inventing a severity field. A trap that invalidated a
   published number belongs in the method's limits, where a chart caption writer
   will see it.

**Do not create a new file per trap.** That is what produced the 70-entry
directory v2 dissolved. If a trap genuinely has no home, it goes in `_craft.md`.

## Learning types

### Gotcha

Something went wrong or was counterintuitive. Future sessions should avoid the same mistake.

```yaml
---
title: [Short descriptive title]
type: gotcha
tags: []
severity: low | medium | high
date: YYYY-MM-DD
---

## Problem

[What went wrong or what was discovered. Include the dataset/variable/year and what symptom surfaced.]

## Solution

[What fixed it or what the correct approach is. Concrete: which variable to use instead, which sample window to restrict to, which deflator vintage to cite.]

## Prevention

[How to avoid this in the future. The signal a future session should watch for before falling into the same trap.]
```

### Insight

Something discovered that's worth knowing — a pattern, a capability, an architectural observation. Not a bug or mistake, just useful knowledge.

```yaml
---
title: [Short descriptive title]
type: insight
tags: []
date: YYYY-MM-DD
---

## Discovery

[What was learned.]

## Why it matters

[How this affects future work — which analyses become easier, which assumptions need revisiting.]

## When to apply

[Situations where this knowledge is relevant — datasets, country-windows, deliverable types.]
```

## The `triggers:` line

There is no index. The destination file's own frontmatter carries the retrieval
contract, and v1's separate `learnings/index.yaml` is gone — a forgotten index
row made a learning invisible to retrieval, which is half of why 63 of the
pilot's 70 learnings never reached a future session:

```yaml
triggers: "keyword1 keyword2 keyword3 keyword4"
```

Triggers are words that would appear in a user's prompt when this learning is relevant. The retrieval hook (`.claude/hooks/retrieve-learnings.sh`) matches prompts against these keywords and surfaces a learning only when **at least 2 trigger words** appear in the prompt. Choose 4–8 specific, concrete keywords — variable names, dataset acronyms, country codes, year ranges — not generic words like "data" or "fix."

Good: `"PONDII EPH 2014 panel attrition vintage"` — concrete; will only fire when the user mentions a relevant context.

Bad: `"data error wave fix"` — generic; will misfire on unrelated work.

## Guidelines

- **One trap per append.** Don't bundle unrelated things into a single `### ` section. A multi-symptom write-up belongs in `research/evidence/NN_*.md`, not in a `## Traps` section. (v1 said "one learning per *file*"; v2 appends into a shared topic file, so the unit is the section, not the file.)
- **Be specific.** "PWT rgdpo inflates oil-exporter productivity by ~40% in 2010–2019 (vs rgdpe)" is useful. "Be careful with PWT" is not.
- **Include the context that makes it actionable.** A future session reading this learning should know exactly what to do differently — which variable, which year, which sample.
- **Don't duplicate what belongs in `research/methods/` or `research/evidence/`.** A peer-reviewable methodology call (chose `rgdpe` over `rgdpo`) goes in `research/methods/`; an evidence-based finding (Argentina's productivity slowdown decomposes 60/40 within/between sectors) goes in `research/evidence/`. A learning is the *gotcha* — the thing you'd want a future session to know *before* it tries the same step.
- **Severity** (gotchas only): `high` = cost hours of debugging or invalidated a published result; `medium` = cost significant time; `low` = minor surprise worth noting.

## Boundary with neighboring artifacts

- **`research/evidence/`** is project-wide formal findings: numbered docs (`research/evidence/NN_*.md`), evidence-based, with a chart or panel CSV behind every claim. Learnings don't replace evidence — a learning may *prompt* a follow-up evidence doc, but the learning itself is the operational warning, not the citable finding.
- **`research/methods/`** is peer-reviewable methodology calls (`research/methods/<topic>.md`). A learning that surfaces a methodology choice (use `rgdpe`, not `rgdpo`) graduates to a decision record once the team agrees. The learning records the discovery; the decision record is the citable form.
- **`plan/brainstorms/`** is decisions-pre-planning (the conversation that produces a `research/methods/` record). Learnings are not brainstorms — they're tacit knowledge from execution, not deliberation.

Full rationale and the three-bucket model: `docs/learning-capture-mechanism-v1.md`. Format and retrieval contract: `.claude/conventions/methods.md`.
