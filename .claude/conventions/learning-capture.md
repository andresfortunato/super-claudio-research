# Learning Capture — Protocol

**Trigger**: A surprise, gotcha, or hard-won discovery surfaces during the
work — a variable that broke in a particular survey vintage, a deflator
series with known divergence, a sample restriction with an unexpected side
effect. The kind of thing a colleague would warn you about over coffee.

The learning-capture skill (`.claude/skills/learning-capture/SKILL.md`)
drives the write. This file documents the **file shape**, the **index
format**, the **retrieval contract**, and the **boundary** with
`evidence/` and `decisions/`.

## Where learnings live

- One file per learning: `learnings/<short-slug>.md`.
- `learnings/` lives at project root. The directory is **committed** —
  learnings are durable, project-shared knowledge (collaborators inherit
  them on clone).
- Slug is short, content-bearing kebab-case: `pondii-eph-2014-vintage.md`,
  not `gotcha_2026_05_08.md` or `learning1.md`.
- Index: `learnings/index.yaml` — one entry per learning with a
  `triggers:` keyword string. The retrieval hook
  (`.claude/hooks/retrieve-learnings.sh`) reads this file on every user
  prompt; entries without an index row are invisible.
- **Project-wide, not theme-aware.** Even in projects using the opt-in
  theme-parallel layout for `evidence/` and `output/`, learnings stay
  flat. A gotcha about a survey wave is universal — trigger-keyword
  matching does the routing, not directory structure.

## File format

Two types: **gotcha** (something went wrong) and **insight** (something
worth knowing). Frontmatter and body shape follow the skill exactly:

### Gotcha

```markdown
---
title: <Short descriptive title>
type: gotcha
tags: []
severity: low | medium | high
date: YYYY-MM-DD
---

## Problem
<What went wrong. Include dataset/variable/year and the symptom.>

## Solution
<What fixed it. Concrete: which variable instead, which window, which vintage.>

## Prevention
<How to avoid this in the future. The signal to watch for.>
```

### Insight

```markdown
---
title: <Short descriptive title>
type: insight
tags: []
date: YYYY-MM-DD
---

## Discovery
<What was learned.>

## Why it matters
<How this affects future work.>

## When to apply
<Datasets, country-windows, deliverable types where this is relevant.>
```

Severity (gotchas only): `high` cost hours of debugging or invalidated a
published number; `medium` cost significant time; `low` was a minor
surprise worth noting.

## Index format

`learnings/index.yaml`:

```yaml
learnings:
  - file: pondii-eph-2014-vintage.md
    triggers: "PONDII EPH 2014 panel attrition vintage"
  - file: pwt-rgdpe-rgdpo-oil-exporters.md
    triggers: "PWT rgdpe rgdpo oil productivity divergence"
```

Triggers are **whitespace-separated keyword strings**, all lowercased
during matching. Choose 4–8 specific concrete keywords — variable names,
dataset acronyms, country codes, year ranges. Avoid generic words
("data", "fix", "error", "wave") that produce false positives.

## Retrieval contract

The `retrieve-learnings.sh` hook fires on every `UserPromptSubmit`. It:

1. Reads `learnings/index.yaml`. Silent if missing or empty.
2. Lowercases the user's prompt and splits it into words.
3. For each entry, counts how many trigger keywords appear in the
   prompt. **Minimum 2 matches** required to fire — single-keyword
   matches are too noisy.
4. Sorts matched entries by match count (most matches first), reads
   the top **3 learning files**, and emits their concatenated content
   as `additionalContext`.
5. Silent if zero matches meet the threshold, or if matched files are
   missing.

The threshold and cap are why specific triggers matter: a learning
triggered on `"PONDII EPH 2014 panel attrition vintage"` will fire when
a researcher writes "Why does PONDII fail in EPH 2014 wave?" (4 hits)
but stay quiet for "What time is it?" (0 hits).

## Atomicity

Writing a learning is a **two-file write**: the `.md` file and the
`index.yaml` row. Skip the index row and the learning is invisible to
retrieval. The skill enforces both writes; this convention restates the
rule. If you discover a `learnings/*.md` without a corresponding index
entry, add the entry — don't delete the file.

## Discipline

- **One learning per file.** Don't bundle unrelated gotchas. A
  multi-symptom write-up belongs in `evidence/NN_*.md`, not here.
- **Be specific.** "PWT rgdpo inflates oil-exporter productivity by ~40%
  in 2010–2019 vs rgdpe" is useful. "Be careful with PWT" is not.
- **Triggers, not titles.** The title summarizes; the triggers route.
  Keywords that *appear in user prompts when the learning is relevant*
  are different from keywords that *describe the topic generically*.
- **Severity is a signal, not a sort key.** `high` flags learnings that
  cost the project; future sessions should treat them as load-bearing.
  `low` is a footnote.
- **Append-only.** Don't rewrite a learning — supersede with a new file
  and reference the old one if a later discovery refines the picture.
  Audit trails depend on the original surviving.

## Distinct from neighboring conventions

- **`evidence-logging`** captures *findings from the data* — numbered
  evidence-based docs (`evidence/NN_*.md`) with charts behind every
  claim. Learnings are *operational warnings* — "before you try to
  build a panel from EPH 2014 onward, note that PONDII isn't there".
  A learning may *prompt* an insight, but the learning itself is not
  the citable finding.
- **`decision-records`** captures *peer-reviewable methodology calls*
  (`decisions/YYYY-MM-DD_<slug>.md`). A learning that surfaces a
  methodology choice graduates to a decision record once the team
  agrees: the learning recorded the discovery; the record makes it
  citable.
- **`brainstorm-format`** captures *decisions-pre-planning* — the
  conversation that produces a decision record. Learnings come from
  *execution*, not deliberation. Don't conflate.
- **`/verify`** sanity-checks a single existing artifact. It may
  surface a gotcha worth capturing as a learning, but `/verify`
  itself is the inspection, not the durable record.

## What this does NOT do

- **Doesn't enforce a length.** A two-paragraph gotcha is fine; a
  longer write-up with code examples is fine. Match the shape to the
  discovery.
- **Doesn't auto-graduate to `decisions/`.** A high-severity learning
  about a methodology choice *should* prompt a decision record, but
  the researcher writes the record. Auto-promotion would produce
  shallow records.
- **Doesn't replace project documentation.** Learnings are tacit
  warnings, not reference docs. How-to-access knowledge for an API
  belongs in `data_sources/`; operational rules belong in `methods/`;
  style choices belong in `project_conventions/`.

## Provenance

This convention codifies a gap surfaced during an audit of an
applied-research project that ran without r2p conventions. The
project produced excellent evidence and a handful of decision records
but had no place for tacit warnings — "PONDII didn't exist in 2014
EPH waves", "asking-vs-transaction price gap is ~10%",
"housing-share assumption uncertainty bands swing the headline".
These warnings either lived in researcher heads (lost on handoff)
or were buried in commit messages (invisible at retrieval time).
The learnings/ + retrieval-hook split was the smallest change that
closed the gap without inventing new categories.

The skill, file format, and retrieval mechanic are research-adapted
ports from `super-claudio-code`. The retrieval hook is a bash
re-implementation of scc's `user-prompt-submit.js` (the v1 framework
constitution forbids JS leakage outside the `r2p` CLI).

Rationale and the three-bucket model: `docs/learning-capture-mechanism.md`.
