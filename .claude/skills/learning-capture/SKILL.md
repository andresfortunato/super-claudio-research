---
name: learning-capture
description: (r2p) Capture learnings from the current session — gotchas, insights, or discoveries worth preserving for future sessions. Use when the pre-compact hook reminds you, when the user asks to save a learning, or when you notice something worth remembering.
---

# Learning Capture

Capture institutional knowledge so future sessions don't repeat mistakes or miss discoveries. Learnings are the third bucket alongside `evidence/` (formal evidence-based findings) and `decisions/` (peer-reviewable methodology calls): they hold the *tacit* gotchas and discoveries — the kind of thing a colleague would warn you about over coffee.

## When to use

- The pre-compact hook reminds you to capture learnings
- The user says "save a learning", "remember this", "capture this gotcha", or similar
- You notice something surprising, counterintuitive, or hard-won during any session

Common research-shaped triggers:

- A variable you assumed was present in a survey wave turned out to break in a particular vintage (PONDII didn't exist in 2014 EPH waves; CASEN's `o15` recoded between 2015 and 2017).
- A deflator series version diverges from peer-published numbers in a known way (PWT `rgdpe` vs `rgdpo` diverging by ~40% for oil exporters).
- A sample restriction had a side effect that wasn't visible until a later step (dropping `educ == NA` silently halved the rural sample).
- An asking-vs-transaction price gap, a respondent self-classification quirk, or an underreporting pattern the dataset's documentation doesn't surface.

## How it works

1. **Identify what was learned** — ask the user if it's not obvious. One learning per file.
2. **Pick the type** — gotcha or insight (see formats below).
3. **Choose a filename** — short, kebab-case, descriptive. Examples: `pondii-eph-2014-vintage.md`, `pwt-rgdpe-rgdpo-oil-exporters.md`, `educ-na-rural-attrition.md`.
4. **Write the file** to `learnings/<filename>.md`.
5. **Append to `learnings/index.yaml`** — always do both atomically. The index is what makes the corpus retrievable; a learning without an index entry is invisible to the retrieval hook.

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

## index.yaml entry

Every learning MUST have a corresponding entry:

```yaml
- file: <filename>.md
  triggers: "keyword1 keyword2 keyword3 keyword4"
```

Triggers are words that would appear in a user's prompt when this learning is relevant. The retrieval hook (`.claude/hooks/retrieve-learnings.sh`) matches prompts against these keywords and surfaces a learning only when **at least 2 trigger words** appear in the prompt. Choose 4–8 specific, concrete keywords — variable names, dataset acronyms, country codes, year ranges — not generic words like "data" or "fix."

Good: `"PONDII EPH 2014 panel attrition vintage"` — concrete; will only fire when the user mentions a relevant context.

Bad: `"data error wave fix"` — generic; will misfire on unrelated work.

## Guidelines

- **One learning per file.** Don't bundle unrelated things. A multi-symptom write-up belongs in `evidence/NN_*.md` or a methodology section, not in `learnings/`.
- **Be specific.** "PWT rgdpo inflates oil-exporter productivity by ~40% in 2010–2019 (vs rgdpe)" is useful. "Be careful with PWT" is not.
- **Include the context that makes it actionable.** A future session reading this learning should know exactly what to do differently — which variable, which year, which sample.
- **Don't duplicate what belongs in `decisions/` or `evidence/`.** A peer-reviewable methodology call (chose `rgdpe` over `rgdpo`) goes in `decisions/`; an evidence-based finding (Argentina's productivity slowdown decomposes 60/40 within/between sectors) goes in `evidence/`. A learning is the *gotcha* — the thing you'd want a future session to know *before* it tries the same step.
- **Severity** (gotchas only): `high` = cost hours of debugging or invalidated a published result; `medium` = cost significant time; `low` = minor surprise worth noting.

## Boundary with neighboring artifacts

- **`evidence/`** is project-wide formal findings: numbered docs (`evidence/NN_*.md`), evidence-based, with a chart or panel CSV behind every claim. Learnings don't replace evidence — a learning may *prompt* a follow-up evidence doc, but the learning itself is the operational warning, not the citable finding.
- **`decisions/`** is peer-reviewable methodology calls (`decisions/YYYY-MM-DD_<slug>.md`). A learning that surfaces a methodology choice (use `rgdpe`, not `rgdpo`) graduates to a decision record once the team agrees. The learning records the discovery; the decision record is the citable form.
- **`brainstorms/`** is decisions-pre-planning (the conversation that produces a `decisions/` record). Learnings are not brainstorms — they're tacit knowledge from execution, not deliberation.

Full rationale and the three-bucket model: `docs/learning-capture-mechanism.md`. Format and retrieval contract: `.claude/conventions/learning-capture.md`.
