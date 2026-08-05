# Provenance — Protocol (v2, merges script-header and analytical-commit-format)

**Trigger**: every analytical script, and every commit that writes an
analytical artifact.

The two halves were always one mechanism: the header records **intent** inside
the script; the commit records the **event** of running it. Together,
`git log -- output/<file>` finds the commit, the commit message names the
script, and the script's header documents its inputs, seed and environment. No
separate audit log, no `manifest.jsonl`, no language-specific machinery.

## Half 1 — the script header

Every analytical script (R, Python, Stata, or a shell pipeline that drives
analysis) opens with these lines, in this order:

```
# Script:   <relative path of this file>
# Inputs:   <comma-separated input files>
# Outputs:  <comma-separated files written>
# Seed:     <int, or "none">
# Env:      <language + version + 1-2 critical packages>
```

If a field doesn't apply, write `none` — **do not omit the line.** The fixed
shape is what makes headers greppable across a repo.

```r
# Script:   analysis/spatial_equilibrium/06c_wage_gradient.R
# Inputs:   data/processed/eph/eph_panel_longrun.rds
# Outputs:  output/spatial_equilibrium/06c_wage_gradient.png
# Seed:     42
# Env:      R 4.3.1, tidyverse 2.0.0, fixest 0.11
```

**Optional `Supersedes:`** — when a script replaces an earlier one:

```
# Supersedes: analysis/.../04_baseline_v0.R (method: research/methods/price-normalization.md)
```

This replaces ad-hoc `_v2` / `_fixed` / `_extended` filename suffixes, which
collide, drift, and lose history. The new script keeps the real name; the
method doc explains why it changed.

## Half 2 — the commit message

```
<short subject — what this step produced or fixed>

<optional 1-2 lines of context>

Run: <script(s) that produced these outputs>
Out: <artifact path(s) written by the run>
```

Both lines required when a script ran. When an artifact changed *without* a
re-run (a hand-edited caption, a rename), drop `Run:` and use `Out:` with a
parenthetical:

```
Rename FDI-at-entry chart for clarity

Out: output/06c_fdi_at_entry.png (renamed; no script re-run)
```

### Applies to

- Commits touching `output/*` produced by a script.
- Commits touching `research/evidence/NN_*.md` — often the same commit.
- Commits touching `deliverables/<name>/charts/*`.

### Does not apply to

- Prose-only commits (memo edits with no chart change), plans, brainstorms,
  conventions, framework scaffolding — `Run:`/`Out:` would be noise.
- Pure environment changes (`renv.lock`, `uv.lock`).

### Commit by pathspec, never stage-then-commit

The git index is **per-worktree, not per-session**. When two sessions share a
worktree, `git add` then `git commit` hands your staged files to whichever
session commits first, **under its message** — so `git log -- output/<file>`
resolves to a stranger's rationale, which is the one thing this convention
exists to prevent. Nothing is lost; provenance is.

```bash
git commit -F - -- output/06c.png research/evidence/125_foo.md  # SAFE — index-independent
git add output/06c.png && git commit -F -                       # UNSAFE — shared-index race
```

- **New files**: `git add <paths> && git commit -F - -- <paths>`, which still
  scopes the commit to those paths even if the index is polluted. Skip the
  pathspec form only when you deliberately staged partial hunks.
- **`no changes added to commit` right after staging is the tripwire.** Run
  `git diff --stat HEAD -- <your paths>`; empty means your files are already
  committed under someone else's message. Record the misattribution in a
  follow-up commit — **never** rewrite pushed history while another session is
  live on the branch.

## Using the trail

```bash
# What produced this chart?
git log -- output/spatial_equilibrium/06c_wage_gradient.png
# → read the Run: line → open the script → read its header for inputs/seed/env

# Everything ever produced from one script
git log --all --grep='Run: analysis/spatial_equilibrium/06c_wage_gradient.R'

# Reproduction check
git show <sha>:analysis/.../06c_wage_gradient.R
git show <sha>:output/.../06c_wage_gradient.png | sha256sum
sha256sum output/.../06c_wage_gradient.png
```

## Discipline

- **Never retrofit a `Run:` line onto a commit that didn't run a script.** The
  line asserts "I ran this here". The parenthetical form is the honest record.
- **Multiple scripts per commit is fine; incoherent bundles are not.** Six
  unrelated reruns in one commit destroys the trail.
- **Both halves or neither.** `Run: foo.R` against a header-less script is a
  half-trail, and `/verify` will report it as one.
- **A chart that porting forced you to re-read data for is a new artifact.**
  Re-running an old analysis on a new toolchain is when you discover the source
  moved underneath you — re-verify the numbers, don't assume the port is
  cosmetic.

## Cross-references

- `.claude/skills/verify/SKILL.md` — `/verify` walks `git log` → commit message
  → script header to locate any artifact's provenance.
- `.claude/conventions/evidence.md` — the evidence doc's `## Provenance`
  section is this convention applied at the finding level. Its `artifacts:` key
  is the **complement, not a duplicate**: this convention answers *how* an
  artifact was made, `artifacts:` answers *which finding it carries*. Neither
  subsumes the other, and collapsing them re-opens the `manifest.jsonl` question
  v1 settled — git plus a script header already gives the *how* at zero install
  cost, which is exactly why the missing piece was the *which*.
- `.claude/conventions/citation-discipline.md` — the full
  `deliverable → claim → evidence → artifact → script → source` chain, of which
  `Run:`/`Out:` is the artifact → script link.
