# Theme-parallel layout — design rationale

## The problem this solves

Some research projects carry one big question (a country diagnostic, a
single decomposition, a focused causal claim). Others carry several at
once — distinct lines of inquiry that happen to share a project repo
because they share data, infrastructure, or a counterpart. The
diagnostic case for the second pattern: a Buenos Aires program ran
four parallel themes (spatial equilibrium, labor markets, fiscal
incidence, productivity decomposition) for the same counterpart over
the same year. Each theme had its own audience and its own
deliverable target; each accumulated its own charts, panels, and
findings. Forcing all four through one flat `evidence/NN_*.md`
sequence collided in two ways:

1. **Numbering was opaque.** `evidence/07_*.md` could be the third
   spatial-equilibrium finding or the first fiscal one. Readers
   couldn't tell from the index without opening the file.
2. **Cross-theme navigation was lossy.** A reader looking only for
   labor-markets evidence had to scan the whole index. The flat
   sequence rewarded the project's chronology, not its structure.

## What the framework does

Permit a one-level subfolder per theme as an **opt-in** layout —
flat stays default, no declaration is required, hooks accept both
shapes:

```
evidence/
├── INDEX.md
├── 01_overall_macro_priors.md          # cross-cutting
├── spatial-equilibrium/
│   ├── 01_amenity_gradient.md
│   └── 02_within_metro_dispersion.md
└── labor-markets/
    └── 01_eph_panel_attrition.md
```

The same opt-in extends to `output/<theme>/0[0-9]_*` artifacts. The
`check-evidence.sh` Stop hook globs both flat and subfolder paths;
the `INDEX.md` template includes an optional `Theme` column.

## Why opt-in, not required

Most research projects are single-theme — one diagnostic, one paper,
one decomposition. Forcing every project to declare a theme adds
friction at the start of work, when the smallest possible scaffolding
is the right scaffolding. Single-theme projects would have to invent
a theme name ("`main/`"?) and wrap their flat sequence in a folder
that adds nothing.

The opt-in shape says: start flat, lift to subfolders when the flat
sequence starts colliding. The cost of migrating partway through is
low (move N files into a folder; update the INDEX paths) because the
hook already accepts both layouts — there's no big-bang switchover.

## Why subfolder, not declaration

The alternative considered: a `themes.md` file at project root that
enumerates valid themes, with hooks validating new files against the
list. Rejected. The framework's constitution favors silent-by-default
discipline over enforced schemas. A `themes.md` file is an upfront
commitment that drifts: themes get renamed, retired, or split, and
the declaration file becomes either a chore to maintain or a
silent liar.

Subfolders make the theme set self-documenting — `ls evidence/`
shows the live themes, no second source of truth. Adding a theme is
`mkdir`; retiring one is leaving an empty folder (or removing it if
nothing references it). Theme strings stay free-form
(lowercase-snake-case suggested but not enforced); the hook doesn't
care what they spell.

## What "theme" means operationally

A theme is **a line of inquiry that has its own audience and its own
deliverable target** — usually a separate memo, briefing, or paper.
That definition rules out finer-grained groupings (a "regression
chapter" or "robustness section") that should stay flat within a
single theme.

The boundary test: would the cross-theme reader want a separate index
view of just this theme's findings? If yes, subfolder. If no, the
finer grouping is structure inside one theme's flat sequence and
doesn't need its own folder.

## Cross-cutting evidence

Some findings span themes — a macro prior that frames every theme,
a data-quality note that bites all of them, a methodological choice
shared across deliverables. Those stay at `evidence/NN_*.md` (top
level, no subfolder). The convention is: **if a finding is referenced
by deliverables in two or more themes, it's cross-cutting** — file
it flat and link to it from each theme's working notes.

## Tradeoffs accepted

- **Two valid layouts in the same convention.** The convention prose
  has to describe both, which is mildly heavier than mandating one.
  Mitigation: flat is the default for single-theme projects, and the
  rules section is short.
- **Numbering ambiguity.** Per-theme numbering (`spatial-equilibrium/01_*`,
  `labor-markets/01_*`) can collide *within* a single project's view
  ("what's `01_`?"). Pick one shape per project — usually per-theme is
  less friction. Document the choice in the project's CLAUDE.md if
  ambiguity arises.
- **Hook regex slightly looser.** `output/([^/]+/)?0[0-9][a-z]?_*`
  technically matches `output/anything-at-all/01_chart.png`. In
  practice projects don't accidentally create non-theme subfolders
  with notebook-prefixed artifacts; the looseness costs nothing.
- **No automated validation.** A typo in a theme name
  (`spatial_eqilibrium/`) creates a new folder rather than failing.
  Caught by the same human review that catches any other typo.

## What this does NOT do

- **Doesn't enforce per-theme INDEX files.** A single `evidence/INDEX.md`
  with a `Theme` column suffices. Per-theme indexes are extra ceremony
  for no extra signal; project owners can add them if they want, but
  the framework doesn't require them.
- **Doesn't mandate matching `output/` and `evidence/` themes.** A
  project can use theme subfolders in `output/` only (where the
  collision pressure is highest from chart filenames) and stay flat
  in `evidence/`. Or vice versa. The hook tripwires accept either
  half independently.
- **Doesn't extend to `wiki/`, `methods/`, `data_sources/`,
  `decisions/`.** Those are project-level reference layers; cross-theme
  reuse is expected and theme subfolders would obscure it. Theme
  parallelism is bounded to evidence accumulation (`evidence/`,
  `output/`).

## Provenance

This pattern was identified by auditing a four-theme Buenos Aires
research project (the cordoba audit) where flat `evidence/` numbering
had degraded to the point that the index couldn't be used for
navigation. The constraint that hooks accept both shapes — rather
than forcing a migration — comes from the v1 framework constitution:
new conventions must compose with existing ones, not replace them.
