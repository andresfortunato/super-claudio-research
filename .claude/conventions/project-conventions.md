# Project Conventions — Protocol

**Trigger**: Whenever the project is about to make — or relies on
— a recurring stylistic or process call that lives below the
threshold for a peer-reviewable decision but above the threshold
for "figure it out each time." Visualization color rules,
chart-naming patterns, writing voice, citation style, slide
design, naming idioms. The kind of choice a researcher would
otherwise re-debate every chart, or worse, drift on silently
across notebooks.

This convention defines a folder of lightweight, domain-scoped
convention docs — one per domain — read on demand by Claude when
work touches that domain. Each file says "this is how *this
project* handles X." The folder is project-shared; every
collaborator picks up the same conventions.

## Boundary with neighbors

Three folders look adjacent and would be confusing if the
boundaries were left implicit:

- **`research/sources/<source>_<thing>.md`** documents *external
  systems* — APIs, codebooks, dataset mechanics. Carries
  `Status: verified <date>` plus a re-fetchable headline anchor.
  The protocol is in `.claude/conventions/sources.md`.
- **`research/methods/<topic>.md`** documents *operational
  project-internal compute rules* — cohort definitions, sample
  restrictions, threshold filters — paired with diagnostic
  counts that prove the rule is in force. The protocol is in
  `.claude/conventions/methods.md`.
- **`.claude/conventions/<name>.md`** documents *framework-shared
  protocols* — the same set of files lives in every project that
  installs research-to-policy. `.claude/conventions/project/` is
  the *project-specific* counterpart: project-scoped style and
  process rules that the framework deliberately does not
  prescribe.

The cleanest test: would another team running a similar diagnostic
arrive at the same rule by reading domain literature or external
docs? If yes, it's a `research/wiki/concepts/`,
`research/sources/`, or `research/methods/` matter. If the rule is genuinely a *project decision*
about how this engagement does its work, it belongs here.

## Where project-convention docs live

- Single folder: `.claude/conventions/project/`, alongside the
  framework's own conventions.
- One file per domain: `<domain>.md` (`visualization.md`,
  `writing_guidelines.md`, `slide_design.md`, `naming.md`).
- The folder is **flat** — no subdirectories. Most engagements
  will have 1–5 files; a flat listing scans in seconds.
- `.claude/conventions/project/INDEX.md` is required. It carries a
  quick-nav table ("if you're working on X, read Y") plus a
  short "how to add a convention" footer. Researchers update
  the INDEX when adding files.
- The folder is **committed**. Conventions are project-shared;
  every collaborator and every Claude session needs the same
  picture.

## The two enforced rules

Unlike `research/sources/` (What it gives you / Access / Headline
anchor / Gotchas / Coverage limits — five required sections) and
`research/methods/` (Rule / Why this and not the alternatives /
Traps / Diagnostic counts / Scope and limits / Changelog — six),
`.claude/conventions/project/` does
**not** prescribe internal structure. Visualization rules need
color tables and plotting helpers; writing rules need voice and
citation guidance; slide rules need layout and density notes.
A single template would be wrong for all three.

What the convention enforces instead:

1. **Naming.** One file per domain. Lowercase snake_case.
   Filename matches the row in `INDEX.md`. Match
   `visualization.md`, not `Visualization.md` or
   `visualization-rules.md`.
2. **Triggering language.** Every file opens with a one-line
   directive of the form "Use this document whenever
   \<situation\>." This is the cue Claude reads to decide
   whether the convention applies to the work in front of it.
   Without the trigger sentence, on-demand loading degrades to
   "load everything, just in case."

Beyond these two rules, the contents of each file are
domain-shaped. Be concrete — concrete examples beat abstract
principles — but don't bolt on sections that don't fit.

## Why Principle 9 does NOT bind

`docs/audience-and-philosophy.md` in the framework repo (not
installed here) — Principle 9, verifiable
freshness anchors) requires reference docs about external
systems to pair `Status: verified <date>` with a re-fetchable
headline anchor. That principle binds `research/sources/` and
`research/methods/` because their claims age out: an API endpoint
quietly retires; a cohort rule's diagnostic counts drift when
the panel updates.

Project conventions are different. They are *decisions*, not
*claims about external systems*. A rule like "Cambodia is red,
peers are blue" doesn't rot — it changes only when the team
deliberately changes it, and that change is itself the new
truth. Slapping a `Status:` line on a project-conventions doc
would be theater; demanding a re-fetchable anchor would be
non-sensical (there is nothing external to re-fetch). The
discipline that *does* apply: edit the doc when the rule
changes, and let `git log -- .claude/conventions/project/<file>` carry
the history.

## INDEX.md schema

`.claude/conventions/project/INDEX.md` carries:

1. **Quick navigation table** — `If you're working on X | Read
   Y`. One row per file. Sorted by likely access frequency.
2. *(Optional)* **Files in this folder** — short one-line
   gloss per file if the quick-nav doesn't already make the
   purpose obvious.
3. **How to add a new convention** — three or four bullets.
   Same shape as `research/sources/INDEX.md`'s recipe, adapted to
   the looser internal structure here.

## Discipline rules

- **One domain per file.** Resist combining "visualization +
  slide design" into one file. Claude loads on demand; small
  focused files mean small loads. Two files of 80 lines each
  read better than one file of 160.
- **Keep each file scannable.** A project-conventions file
  past ~150 lines is a smell. Either the domain has split
  (visualization rules vs. interactive-dashboard rules) and
  should be two files, or the file has accumulated tangents
  that belong in a `research/wiki/concepts/` page or a
  `research/methods/` record.
- **Edit, don't accumulate.** When the rule changes, edit the
  doc in place — don't append "UPDATE: now we use blue." Git
  history is the version log; the doc reads as current truth.
  This mirrors the sources convention.
- **Cross-link from CLAUDE.md only at the top level.** The
  CLAUDE.md pointer block names the folder and its purpose;
  individual files are not cross-linked from CLAUDE.md. The
  INDEX carries them all.
- **Avoid sub-folders.** A flat folder with 3–5 well-named
  files scans faster than a hierarchy. If you're tempted to
  add a sub-folder, the file probably belongs in `wiki/` or
  `methods/` instead.
- **No engagement-specific content in the framework-installed
  EXAMPLE file.** When customizing, replace the example with
  real project rules; do not edit-in-place the EXAMPLE so it
  ships back upstream as engagement content.

## Adding a new convention — recipe

1. Identify the *domain*: visualization, writing, slide design,
   naming, citation style, etc. One file per domain.
2. Create `.claude/conventions/project/<domain>.md`. Open with the
   triggering line: "Use this document whenever \<situation\>."
3. Write the rules in whatever shape the domain calls for.
   Include concrete examples (color hex codes, file naming
   patterns, sample sentences) so a reader can apply the rule
   without re-deriving it.
4. Add a row to `.claude/conventions/project/INDEX.md`'s navigation
   table.
5. If the convention is project-defining (a Claude session
   would silently violate it without knowing), add a one-line
   mention in `CLAUDE.md`'s appropriate section. Most
   conventions don't need a CLAUDE.md mention — the INDEX
   carries them.

## What this convention does NOT cover

- **Framework-shared protocols** — those live in
  `.claude/conventions/<name>.md` and ship with
  research-to-policy. `.claude/conventions/project/` is for the rules
  *this engagement* makes locally.
- **Peer-reviewable methodology calls** — deflator choice,
  identification strategy, sample restriction. Those go in
  `research/methods/<topic>.md` (see
  `.claude/conventions/methods.md`, which absorbed the v1
  `decision-records` convention).
- **External-system reference docs** — APIs and codebooks go
  in `research/sources/` with anchors.
- **Operational compute rules with diagnostic counts** —
  cohort definitions and threshold filters go in
  `research/methods/`.
- **Distilled domain claims with citations** — "the Balassa
  RCA index has a known small-economy bias" goes in
  `research/wiki/concepts/`, not here.
