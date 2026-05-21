# learnings/

Tacit gotchas and discoveries — the kind of thing a colleague would warn
you about over coffee. The third bucket alongside `evidence/` (formal
evidence-based findings) and `decisions/` (peer-reviewable methodology
calls).

One file per learning: `learnings/<slug>.md`. Two types: **gotcha**
(something went wrong) and **insight** (something worth knowing).
Frontmatter and body shape: `.claude/conventions/learning-capture.md`.

## How retrieval works

`learnings/index.yaml` lists every learning with a `triggers:` keyword
string. The `retrieve-learnings.sh` UserPromptSubmit hook fires on every
prompt: it lowercases the prompt, splits into words, and counts trigger
overlap per entry. Entries with **≥2 matching keywords** are surfaced as
`additionalContext` (top 3 by match count). Specific concrete keywords
(variable names, dataset acronyms, country codes, year ranges) route
well; generic words ("data", "fix") misfire.

A learning without an `index.yaml` row is invisible — the skill enforces
both writes; this README is the reminder if you find yourself editing
files by hand.

## When to capture

- A variable broke in a particular survey vintage that you'll trip over
  again (PONDII not in EPH 2014; CASEN's `o15` recoded between 2015 and
  2017).
- A deflator series version diverges from peer-published numbers in a
  known way (PWT `rgdpe` vs `rgdpo` in oil-exporters).
- A sample restriction had a side effect that wasn't visible until later
  (`educ == NA` silently halved the rural sample).
- An API quirk, a respondent self-classification artifact, or an
  underreporting pattern the dataset's documentation doesn't surface.

## When NOT to capture

- A formal finding with a chart behind it → `evidence/NN_<slug>.md`.
- A peer-reviewable methodology call → `decisions/YYYY-MM-DD_<slug>.md`.
- A reference doc for an external API → `data_sources/<slug>.md`.
- An operational rule with diagnostic counts → `methods/<slug>/rule.md`.

Full protocol: `.claude/conventions/learning-capture.md`.
Rationale and three-bucket model: `docs/learning-capture-mechanism.md`.
