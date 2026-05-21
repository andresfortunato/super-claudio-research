# Script Header — Protocol

**Trigger**: Every analytical script in `scripts/` (R, Python, Stata, or
shell pipelines that drive analysis) starts with a header comment block
that documents what the script reads, what it writes, the random seed if
any, and a loose environment fingerprint. The header lives in the script
itself, so it travels with the code through git.

This convention replaces an earlier `manifest.jsonl` audit-log mechanism.
The argument: `git log -- output/<file>` plus a header in the script that
produced it gives you the same reproducibility trail at zero install cost
and with no language-specific machinery.

## Required fields

Every analytical script starts with these comment lines, in this order:

```
# Script:   <relative path of this file>
# Inputs:   <comma-separated list of input files this script reads>
# Outputs:  <comma-separated list of files this script writes>
# Seed:     <int, or "none" if non-stochastic>
# Env:      <language + version + 1-2 critical packages, e.g. "R 4.3.1, tidyverse 2.0">
```

If a field doesn't apply, write `none` (do not omit the line — the fixed
shape is what makes the header greppable).

## Optional fields

When a script *replaces* an earlier script (a new specification, a
refactor, a corrected pipeline), add a `Supersedes:` line pointing at
the old script and the decision record that motivated the swap:

```
# Supersedes: scripts/04_baseline_v0.R (decision: decisions/2026-04-12_baseline-redesign.md)
```

This pattern replaces ad-hoc `_v2` / `_fixed` / `_extended` filename
suffixes — those collide, drift, and lose history. The new script lives
under its real name; the old one stays as a numbered sibling until it's
deleted; the decision record explains why.

## Format examples

### R

```r
# Script:   scripts/06c_fdi_at_entry.R
# Inputs:   data/clean/wdi.csv, data/raw/wdi_2024.csv
# Outputs:  output/06c_fdi_at_entry.png, output/06c_fdi_at_entry.csv
# Seed:     42
# Env:      R 4.3.1, tidyverse 2.0.0, fixest 0.11

library(here)
library(tidyverse)
library(fixest)
set.seed(42)

wdi <- read_csv(here("data/clean/wdi.csv"))
# ... rest of the script
```

### Python

```python
# Script:   scripts/06c_fdi_at_entry.py
# Inputs:   data/clean/wdi.csv
# Outputs:  output/06c_fdi_at_entry.png
# Seed:     42
# Env:      Python 3.11, pandas 2.1, statsmodels 0.14

from pathlib import Path
import pandas as pd
import numpy as np

REPO = Path(__file__).resolve().parent.parent
np.random.seed(42)

wdi = pd.read_csv(REPO / "data/clean/wdi.csv")
# ... rest of the script
```

### Stata

```stata
* Script:   scripts/06c_fdi_at_entry.do
* Inputs:   data/clean/wdi.dta
* Outputs:  output/06c_fdi_at_entry.png
* Seed:     42
* Env:      Stata 18

use "data/clean/wdi.dta", clear
set seed 42
* ... rest of the script
```

## What counts as "analytical"

Scripts that:
- Read data and produce **outputs that show up in deliverables, evidence docs, or memos** (charts, regression tables, summary CSVs).
- Are reproducible end-to-end (you can re-run them later).

Scripts that don't need a header:
- Build / setup scripts that only configure the environment.
- One-line wrappers (`Rscript -e 'install.packages("foo")'`).
- Pure data-cleaning scripts whose output is itself an input to another script — but adding the header anyway costs nothing and helps trace the chain.

## Why this works

Given a chart `output/06c_fdi_at_entry.png` and a question "how was this made?":

```bash
# 1. Find the commit that last touched it
git log -- output/06c_fdi_at_entry.png

# 2. Read the commit message — the analytical-commit-format convention requires
#    `Run: scripts/06c_fdi_at_entry.R` and `Out: output/06c_fdi_at_entry.png`

# 3. Read the script header — confirms inputs, seed, env

# 4. Check out the commit; reproduce
git checkout <sha>
Rscript scripts/06c_fdi_at_entry.R
sha256sum output/06c_fdi_at_entry.png
# Compare against current; mismatch = something changed (env, input data, code)
```

The header is the per-run record of *intent*; git is the per-run record
of *result*. Together they replace `manifest.jsonl`.

## Discipline

- **Update the header when you change the script.** If the script grows a new input or output, the header reflects it. A drifted header is worse than no header.
- **Don't lie about seeds.** If a script uses `set.seed(NULL)` or no seed, write `Seed: none`. Tools that scan for missing seeds rely on this.
- **One pair of eyes is enough.** This is not a peer-review checklist. The header is for the future-you who's six months out.
- **Do not make the header longer.** No "purpose" or "author" or "version" lines — git carries those. The fixed five fields are the contract.

## Repo-relative paths

Every path inside an analytical script is relative to the project root,
resolved via the language's repo-aware idiom:

- **R**: `here::here("data/clean/wdi.csv")` — anchors on the project's
  `.Rproj` or `.here` marker.
- **Python**: `Path(__file__).resolve().parent.parent / "data/clean/wdi.csv"`,
  or a small `repo_root()` helper. `pathlib`, never `os.path.join` with
  raw strings.

Absolute paths (`setwd("/home/researcher/projects/cordoba")`,
`/Users/<name>/...`, `C:\\...`) are an anti-pattern. They break for
every other collaborator and for future-you on a different machine.
The header's `Inputs:` / `Outputs:` lines are also repo-relative — the
script body and the header agree.

## Shared utilities

Helper functions used by more than one script live in the project's
shared-utilities directory and are *imported*, not copy-pasted:

- **R**: put helpers in `R/<topic>.R` and load with
  `source(here::here("R/<topic>.R"))` at the top of each consumer.
  This is the R-idiomatic location (the same one `devtools::load_all()`
  picks up if the project later becomes a package).
- **Python**: put helpers in `scripts/_lib/<topic>.py` and import as
  `from scripts._lib.<topic> import <fn>`. The `_lib` prefix keeps
  them visually separate from the numbered analytical scripts.

A helper duplicated across three scripts is three places to fix when
the helper is wrong. Move it the first time you copy it; the second
copy is the signal.

## One project, one env

A project has *one* environment definition at the project root:

- **R**: `renv.lock` at the root.
- **Python**: a single `pyproject.toml` (with `uv` / `poetry` /
  `hatch` lockfile) or `requirements.txt` + lock at the root.

Sub-tools with their own `.venv` / `pyproject.toml` per scraper, per
notebook, or per pipeline stage (`scrapers/foo/.venv` +
`scrapers/bar/.venv`) is an anti-pattern. It splits the dependency
graph, hides version skew, and makes the `Env:` field lie. If two
parts of the project genuinely need incompatible deps, that's a sign
they belong in different repos.

## Cross-references

- `.claude/conventions/analytical-commit-format.md` — the matching commit-message convention; together they form the audit trail.
- `.claude/skills/verify/SKILL.md` — `/verify` reads the header to confirm an artifact's parent script and inputs.
- `docs/verification-architecture.md` — design rationale for the verification stack (`/verify` + `/deliverable-review`) without an automatic manifest.
