# Project-conventions mechanism — design rationale

## The problem this solves

Every engagement accumulates project-bespoke style and process
choices that are too specific for the framework to prescribe and
too durable to leave to per-session improvisation:

- Cambodia is red, peers are blue — every scatter, every line
  chart.
- Bar charts are y-axis-categorical, ordered highest-to-lowest.
- Briefing memos are 800–1200 words; deck slides take an
  assertion-style title.
- Notebooks are numbered `01_`, `02_`, `03b_` — never
  `analysis_v3_FINAL_revised.ipynb`.

Without scaffolding, these decisions either:

- **Drift across notebooks.** The first scatter uses
  `#D62728`; the third uses `#FF0000` because that's the
  matplotlib default the third notebook reached for. Three
  months in, the deck has four reds.
- **Live as tribal knowledge.** New collaborators reinvent the
  rules — sometimes producing the same answer, sometimes not.
  Claude sessions, with no project memory, reinvent them
  every time.
- **Bloat CLAUDE.md.** The temptation is to dump the rules
  inline: "Color rules: Cambodia red, peers blue, ...". A
  twelve-rule visualization block is fifty lines that load
  every session whether the work touches charts or not.

The project-conventions convention sits between these.
Lightweight markdown files, one per domain, in
`project_conventions/`. Claude loads them on demand when work
touches the domain. Researchers update them in place when the
rule changes.

## Why a separate folder, not inline in CLAUDE.md

Considered and rejected: keep visualization + naming + slide
rules as inline sections of `CLAUDE.md`. The original framework
template even shipped a `## Visualization Conventions`
placeholder section.

Two problems with the inline approach:

1. **Token cost.** CLAUDE.md is loaded into every session.
   Fifty lines of color rules cost ~500 tokens per session
   whether the work is touching charts or not. Per Principle 5
   (Short CLAUDE.md), the framework's biggest token-cost lever
   is reading protocols on demand, not keeping them resident.
2. **Per-domain access.** A researcher (or Claude) about to
   write a slide should read the slide-design rules, not the
   visualization rules and the writing rules and the naming
   rules. One-file-per-domain means smaller, focused reads.

The CLAUDE.md pointer block — five lines — names the folder
and points at `.claude/conventions/project-conventions.md`.
The individual rule files are loaded only when the work
matches their triggering language.

## Why no enforced internal sections

Considered and rejected: a fixed template for project-
conventions files, mirroring the six required sections in
`data_sources/` and the seven in `methods/`. The case for it:
consistency across files; a reader scans more easily when every
file has the same shape.

The case against, which won:

- **The shape varies by domain.** A visualization file needs
  color tables, plotting helpers, chart-type rules.
  A writing file needs voice, tone, citation style, register
  guidance. A naming file might be a one-page list of
  patterns. Forcing all three into "Status / Trigger / Rules /
  Examples / Pitfalls / ..." would mean either empty sections
  in some files or rules awkwardly squeezed into the wrong
  bucket.
- **Style rules aren't ref docs.** `data_sources/` and
  `methods/` impose structure because their claims need to be
  re-verifiable (anchor) and re-implementable (rule + counts).
  Project conventions are *decisions* — the file IS the rule.
  No re-verification step needed.
- **Pilot precedent.** Cambodia's `project_conventions/visualization.md`
  evolved organically into "Color Rules" and "Plotting
  Conventions" — two sections, no Status, no anchor, no
  Pitfalls. It works. Forcing the v1 shape backward onto it
  would either break the file or carve out per-domain
  exceptions that defeat the consistency the structure was
  meant to enforce.

The convention enforces the *two* things that actually need
enforcement: file naming (so the INDEX maps cleanly) and
triggering language (so on-demand loading works). Everything
else stays domain-shaped.

## Why Principle 9 (freshness anchors) does not bind here

The freshness-anchor pattern in `docs/audience-and-philosophy.md`
addresses one specific failure mode: reference documentation
about *external* systems whose state changes silently. An IMF
endpoint rotates; a cohort rule's diagnostic counts drift; the
doc still reads correct but no longer describes reality.

Project conventions don't have this failure mode. They are
*team decisions*, not *claims about external systems*. The rule
"Cambodia is red, peers are blue" doesn't drift over time — it
changes only when the team deliberately changes it. That change
is itself the new truth, recorded in the doc and timestamped by
git.

A `Status: verified <date>` line on a project-conventions doc
would be performative. There is no smoke-test to re-run; the
project's chart-color discipline is self-evidently the rule.
A "headline anchor" — a concrete value to re-fetch — has nothing
to point at because the rule isn't a claim about an external
system.

What still applies is the spirit of the principle: keep the
doc current. When the rule changes, edit the doc. Git history
is the audit trail.

## Why no `/project-conventions-lint` skill

Considered and rejected for v1. A lint skill could check that:

- Every file in `project_conventions/` opens with "Use this
  document whenever ...".
- Every file appears in the INDEX.
- File names are lowercase snake_case.
- The folder is flat (no subdirectories).

These are useful checks, but they are also *trivially failable*
in a way that's loud at the next access. A missing trigger line
shows up the next time Claude tries to load on demand and has
no signal of when the rule applies. A missing INDEX row is
caught the next time someone hunts for it. The discipline is
the convention, not a tool.

Same logic as for `data-sources` and `methods`: ship the
convention; if pilot use shows the discipline slipping
(triggering language drifting, files going untracked from the
INDEX, or duplicated rules across files), revisit and ship a
lint skill in v1.x.

## Why `project_conventions/`, not `style/` or `house_style/`

Considered: shorter folder names — `style/`, `house_style/`,
`conventions/` (project-level). The case for `style/`: punchier,
faster to type, more familiar from web-development idioms.

The case against, which won:

- **Scope.** "Style" implies *visual* style — color rules,
  typography, layout. Project conventions extend past visual:
  writing voice, citation patterns, naming idioms, slide
  density. A folder named `style/` would either be misleading
  (when writing rules land in it) or would force an awkward
  split (`style/` for visual, `house_style/` for prose).
  `project_conventions/` accurately scopes to "decisions this
  project made about how it does work."
- **Pilot precedent.** Cambodia is already on
  `project_conventions/`. A v1 framework shipping `style/`
  would force a migration that adds zero value.
- **Disambiguation from `.claude/conventions/`.** The framework
  already has `.claude/conventions/` for shared protocols. The
  project-level analogue naturally wants the same word with a
  scope qualifier. `project_conventions/` reads as "the
  conventions, but at project scope" — clearer than yet
  another vocabulary word.

## Why `INDEX.md` is required

Considered and rejected: rely on the directory listing alone.
The case for: 1–3 files scan from `ls` cleanly; an INDEX is
boilerplate.

The case against, which won (mirroring the data-sources case):
once the folder grows past ~3 files, a researcher hunting for
"is there a writing-style doc?" ends up grepping titles. The
INDEX is a 30-second write that pays back on every subsequent
lookup. And — distinct from the methods convention, which
deliberately uses the directory listing as the index — every
project-conventions file is its own domain with its own access
pattern; a quick-nav table is the right primitive.

The INDEX has two required parts:

1. **Quick navigation table** — "If you're working on X, read
   Y." One row per file. Sorted by likely access frequency.
2. **How to add a new convention** — the recipe, three or
   four bullets.

A third part (a per-file gloss) is optional; the quick-nav
typically makes the purpose obvious.

## The pieces

### 1. The convention file (`.claude/conventions/project-conventions.md`)

Documents the boundary with `data_sources/`, `methods/`, and
`.claude/conventions/`; the two enforced rules (naming and
triggering language); why no internal sections; why Principle
9 doesn't bind; the INDEX schema; the recipe for adding a
convention. Read on demand by Claude when the user mentions
visualization, writing voice, slide design, naming, or asks
"where do I document the X rule for this project."

### 2. The templates (`templates/project_conventions/{INDEX.md,README.md,EXAMPLE_visualization.md}`)

Seeded by `r2p init` into target projects.

- `INDEX.md` — empty quick-nav with one example row pointing at
  `EXAMPLE_visualization.md`, plus the "how to add a convention"
  recipe.
- `README.md` — one-liner pointing at the convention.
- `EXAMPLE_visualization.md` — generic worked example: color-
  rule guidance, chart-naming, plotting helpers. Generic
  placeholders only — no project-specific brand colors, no
  utility-module names, no peer-country lists. The shape is
  what the framework ships; the content is what the project
  fills in.

### 3. The CLAUDE.md pointer (~5 lines)

Tells Claude that `project_conventions/` exists, names the
domain (project-bespoke style and process), and points at the
convention file for the protocol.

### 4. Audit trail (git, not a separate log)

Project conventions evolve in place; their history lives in
git:

```bash
git log -- .claude/conventions/project/visualization.md   # this rule's history
git log -- .claude/conventions/project/                   # all of them
```

No anchor, no `Status` line, no separate log. The doc reads
as current truth; git carries the genealogy.

## Tradeoffs accepted

- **No structural enforcement of file content.** A researcher
  could in principle write a project-conventions file that's
  one paragraph of vague hand-waving. The convention asks for
  concrete examples but doesn't lint for them. Pilot use will
  surface whether this is a problem.
- **The triggering-language rule is convention, not lint.** A
  file without "Use this document whenever ..." still loads
  if Claude hits it, but loses the on-demand discipline. We
  rely on the EXAMPLE file modeling the pattern.
- **Folder name is a long word.** `project_conventions/` is
  19 characters; `style/` is 5. The cost is occasional typing;
  the benefit is scope clarity and pilot continuity.
- **No top-level required sections is a departure from the
  data-sources/methods pattern.** A reader scanning all three
  conventions sees one with structure (data-sources, methods)
  and one without (project-conventions). The asymmetry is
  intentional and documented; the cost is occasional
  "wait, why is this one different?" friction.

## Provenance

The pattern is a port of the working setup in
`~/cambodia-growth/project_conventions/`, where two files —
`INDEX.md` (quick-nav with one row) and `visualization.md`
(color rules + plotting conventions) — emerged organically
during the first six weeks of the engagement. The shape was
proven before the framework codified it. The framework's
contribution is the boundary work (separating these from
`data_sources/`, `methods/`, `decisions/`, and
`wiki/concepts/`) and the on-demand-loading discipline (the
triggering-language rule).

What pilot use surfaces next — additional examples for
writing voice, slide design, naming — will land in v1.x as
the patterns prove out. v1 ships the *folder* with one
worked example; the next examples ship when their content
is real.
