# Analytical Commit Format — Protocol

**Trigger**: Any commit that produces or modifies analytical artifacts
under `output/`, `evidence/`, or `deliverables/<name>/charts/`. The
commit message includes `Run:` and `Out:` lines so future-you can trace
"what produced this chart" through `git log` alone.

This convention is the partner of `script-header`. The header records
intent inside the script; the commit message records the *event* of
running the script. Together: `git log -- output/<file>` finds the
commit, the commit message names the script, the script's header
documents inputs/seed/env. No separate audit log needed.

## Format

```
<short subject — what this analytical step produced or fixed>

<optional 1-2 line context if the subject doesn't carry it>

Run: <relative path of script(s) that produced these outputs>
Out: <relative path(s) of analytical artifacts written by the run>
```

`Run:` and `Out:` are required. `Run:` may list multiple scripts when
a coherent change ran several. `Out:` may list multiple files.

If a commit changes an analytical artifact *without* re-running a script
(e.g. you hand-edited a deliverable's chart caption, or you renamed a
file), drop `Run:` and use `Out:` alone with a parenthetical:

```
Rename FDI-at-entry chart for clarity

Out: output/06c_fdi_at_entry.png (renamed; no script re-run)
```

## Examples

```
Add FDI-at-entry chart for Phase 3 diagnostic

Run: scripts/06c_fdi_at_entry.R
Out: output/06c_fdi_at_entry.png, output/06c_fdi_at_entry.csv
```

```
Refresh growth-decomposition table after WDI 2024 update

WDI dropped 2024 figures yesterday; rerun the structural-transformation
shift-share with the longer panel.

Run: scripts/04_decomposition.R
Out: output/04_decomposition.csv, output/04_decomposition.png
```

```
Bundle three diagnostic charts for the ministerial briefing

Run: scripts/12_briefing_charts.R
Out: output/12a_growth_path.png, output/12b_sector_shares.png, output/12c_fdi_flows.png
```

## When this convention applies

- Any commit touching `output/*` produced by an analytical script.
- Any commit touching `evidence/NN_<slug>.md` (the evidence doc records evidence; the commit should record what ran to produce it — frequently the underlying analytical commit and the evidence commit are the same).
- Any commit touching `deliverables/<name>/charts/*` or charts pulled from `output/` into a deliverable.

When this convention does **not** apply:

- Commits that are purely about prose (memo edits with no chart changes), planning files (`plan/`, `brainstorms/`), conventions, or framework scaffolding. Use whatever commit style fits — `Run:` and `Out:` would be noise.
- Commits that are pure environment changes (`renv.lock` updates, `requirements.txt`).

## How to use the trail

```bash
# What produced this chart?
git log -- output/06c_fdi_at_entry.png

# Most recent commit that produced it; read the Run: line in the message → script path
# Read the script header → inputs, seed, env

# What's been produced from this script across history?
git log --all --grep='Run: scripts/06c_fdi_at_entry.R'

# Reproduction
git show <sha>:scripts/06c_fdi_at_entry.R    # the exact script at that point
sha256sum output/06c_fdi_at_entry.png        # current hash
git show <sha>:output/06c_fdi_at_entry.png | sha256sum    # hash at that commit
```

## Discipline

- **Do not retrofit `Run:` lines onto commits that didn't run a script.** The line means "I ran this script in this commit." If it's a pure file-rename, the parenthetical form is the honest record.
- **Multiple-script commits are allowed but should be coherent.** Bundling six unrelated reruns into one commit obscures the trail. One coherent change per commit.
- **Pair this with `script-header`.** A commit that says `Run: scripts/foo.R` against a script with no header is a half-trail. Both halves matter.

## Cross-references

- `.claude/conventions/script-header.md` — the matching script-side convention.
- `.claude/skills/verify/SKILL.md` — `/verify` uses `git log` + commit message + script header to locate an artifact's provenance.
- `docs/verification-architecture.md` — verification stack design.
