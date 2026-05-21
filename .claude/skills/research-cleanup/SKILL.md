---
name: research-cleanup
description: (r2p) Audit a research project for accumulated cruft — orphan scripts older than 30 days, intermediate CSVs older than data/raw/'s most recent change, charts not referenced by any insight or deliverable, and notebook cells marked as scratch. Use when the user says "clean up the project", "/research-cleanup", "what can I delete", "audit the repo for orphans", or before a milestone (close-out, hand-off, open-sourcing). Produces a markdown proposal at `cleanup-proposal.md`; the researcher reviews and acts manually. NEVER deletes, moves, or modifies anything itself.
allowed-tools: Read, Write, Bash, Glob, Grep
---

# research-cleanup

Static audit of a research project's working tree. Identifies likely-deletable artifacts, writes a proposal, and stops. The researcher signs off on each item by hand. This skill never deletes, never moves, never rewrites — its only output is `cleanup-proposal.md` at the project root.

## When to invoke

- Before a project close-out, milestone hand-off, or open-sourcing the repo.
- After a long stretch of exploratory work where you suspect orphan scripts and unused charts have accumulated.
- When `git status` shows dozens of untracked files and you've lost track of what's load-bearing.
- The user says "clean up", "audit", "what can I delete", "/research-cleanup".

## When NOT to invoke

- Mid-analysis. A "stale" intermediate CSV may be the input to the script you're about to write next; don't propose deleting it.
- On a freshly-cloned repo. Nothing has aged yet.
- As a recurring background task. This is invoked deliberately, like a code review — not a cron job.

## Preconditions

- Run from the project root. The skill assumes the standard layout: `data/raw/`, `data/`, `output/` (or `figures/`, `charts/`), `scripts/` (or `src/`, `code/`, `analysis/`), `notebooks/`, `evidence/`, optionally `deliverables/` and `wiki/`.
- If `data/raw/` does not exist, note it in the proposal but continue — staleness checks against `data/raw/` mtime simply won't fire.
- If `evidence/` and `deliverables/` are both absent, the chart-orphan check has nothing to cross-reference; report that limitation in the proposal rather than silently degrading.

## Workflow

1. **Locate working directories.** Glob the project for `scripts/`, `src/`, `code/`, `analysis/`, `notebooks/`, `output/`, `figures/`, `charts/`, `data/`, `data/raw/`, `evidence/`, `deliverables/`, `wiki/`. Record which exist; the audit adapts to what's present.
2. **Compute the `data/raw/` watermark.** Get the most recent mtime under `data/raw/` (recursively). This is the staleness reference for intermediate data: any derived CSV/Parquet older than the latest raw input is suspect — the raw it depends on may have been updated and the derivative not regenerated.
3. **Run the four audits below.** Each populates a section of the proposal.
4. **Write `cleanup-proposal.md`** at the project root. Overwrite if it exists; the previous proposal is presumed to have been acted on or discarded.
5. **Report to the user.** One-paragraph summary: how many items in each category, where the proposal lives, the reminder that nothing has been deleted.

## Audits

### 1. Orphan scripts (>30 days, not referenced)

A script is an orphan candidate if **all** hold:
- Lives in `scripts/`, `src/`, `code/`, `analysis/`, or project root with extension `.R`, `.py`, `.do`, `.sh`, `.jl`.
- Last modified >30 days ago (use `find -mtime +30` or equivalent `stat`).
- Not referenced by any other tracked file in the repo: `grep -r` its filename across `scripts/`, `notebooks/`, `evidence/`, `deliverables/`, `plan/`, `wiki/`, `Makefile`, `*.yml`, `*.yaml`. Zero non-self hits → orphan candidate.
- Optional strengthener: `git log --grep="Run: <script>"` returns no commits in the last 30 days. Per the analytical-commit-format convention, every analytical run is recorded in a commit message; absence of recent `Run:` commits is suggestive (but not dispositive — the convention may not have been adopted from day one).

Each finding records: path, last-modified date, age in days, what was searched (so the researcher can verify the negative).

### 2. Stale intermediate data

A file is a stale-intermediate candidate if **all** hold:
- Lives under `data/` but **not** under `data/raw/`. Anything in `data/raw/` is canonically immutable; never propose deleting it.
- Extension is `.csv`, `.parquet`, `.feather`, `.rds`, `.dta`, `.xlsx`, or `.json` (data-shaped, not code-shaped).
- Last modified **before** the most recent mtime under `data/raw/` (computed in step 2 above). The raw input has changed since this derivative was built.
- Not referenced by any script, notebook, insight, or deliverable that has been modified after the raw watermark. (If the most-recent script using it is even more stale, the whole pipeline branch may be dead.)

Each finding records: path, mtime, raw-watermark date, age delta in days, the most-recent referencing file (or "no inbound references found").

### 3. Orphan charts

A chart file is an orphan candidate if **all** hold:
- Lives in `output/`, `figures/`, `charts/`, or any directory with `>5` image files.
- Extension is `.png`, `.pdf`, `.svg`, `.jpg`, `.jpeg`, or `.html` (for plotly/leaflet exports).
- **Not referenced by any file in `evidence/`, `deliverables/`, or `wiki/`** — grep the basename across those trees.
- Optional weak signal: not referenced from any markdown file in the repo (broader sweep). Use only if the strict check produced too few hits to be useful.

Each finding records: path, last-modified date, what was searched. Charts that fail the strict check but pass the broader sweep get a `(maybe — referenced from non-canonical location)` annotation rather than being omitted.

### 4. Scratch-marked notebook cells

For each `.ipynb` file under `notebooks/` (and the project root, if present):
- Parse JSON cells.
- Flag any cell whose source begins with `# scratch`, `# SCRATCH`, `# tmp`, `# TMP`, `# DELETE ME`, `# todo: delete`, or contains a top-level `# scratch — ...` style marker on any line in the first 5 lines.
- Also flag cells with `metadata.tags` containing `scratch`, `tmp`, or `delete`.

Each finding records: notebook path, cell index, first non-blank line of the cell, and the marker that triggered it. Do not flag entire notebooks for deletion — only individual cells, since researchers commonly leave one scratch cell among many production cells.

## Proposal format

Write `cleanup-proposal.md` at project root. Schema:

```markdown
# Cleanup proposal — YYYY-MM-DD

Generated by `/research-cleanup`. **Nothing here has been deleted.** Review each
section, decide what to act on, then run the deletes/moves yourself. When
finished, delete this file (or leave it as an audit log — your call).

## Summary
- Orphan scripts: <n>
- Stale intermediate data: <n>
- Orphan charts: <n>
- Scratch notebook cells: <n>
- `data/raw/` watermark: YYYY-MM-DD HH:MM (most recent mtime under data/raw/)

## 1. Orphan scripts (>30 days, no inbound references)

- `scripts/old_exploration.R` — modified 2026-01-04 (121 days ago); searched scripts/, notebooks/, evidence/, deliverables/, plan/, wiki/, Makefile, *.yml — zero hits. No recent `Run:` commits. **Likely safe to delete.**
- `scripts/munge_v2.py` — modified 2026-02-15 (79 days); zero hits in tracked files; one hit in `.gitignore` (excluded output dir). **Probably safe; double-check the v3 superseded it.**

(If zero findings: write `(none)` under this header.)

## 2. Stale intermediate data (older than data/raw/ watermark)

- `data/processed/panel_v1.parquet` — modified 2026-01-22, raw watermark is 2026-04-30 (98 days older); last referenced by `scripts/build_panel.py` which is itself dated 2026-01-20. **Whole branch may be dead — investigate before deleting.**

## 3. Orphan charts (not referenced by insight, deliverable, or wiki)

- `output/explore_07.png` — modified 2026-03-10; not referenced in evidence/, deliverables/, or wiki/. **Likely safe to delete.**
- `output/fdi_ratio_v3.png` — modified 2026-04-22; referenced from a non-canonical README.md but not from any insight or deliverable. **Decide whether the README usage is load-bearing.**

## 4. Scratch-marked notebook cells

- `notebooks/03_explore.ipynb` cell 14 — opens with `# scratch — debug Q3 outlier`; tagged `scratch`. **Likely safe to clear or delete.**
- `notebooks/05_panel.ipynb` cell 7 — opens with `# TMP fix path`; no tag. **Decide whether the fix has been promoted to the main script.**

## Audits skipped (preconditions not met)

(List any audits the skill couldn't run because expected directories were missing — e.g. "chart audit skipped: no evidence/ or deliverables/ to cross-reference.")
```

If every audit returned zero findings, still write the file with `(none)` under each section and a Summary saying so — the researcher can confirm the audit ran.

## Rules

- **Never delete.** Not even with `--confirm`. The skill produces a markdown file and stops.
- **Never move files.** Even into a `_trash/` staging area. Suggesting moves is fine; doing them is not.
- **Never edit a notebook.** Even to clear a flagged scratch cell. Researcher does that by hand or with a separate tool.
- **Be concrete.** Every finding cites a path, a date, and what was searched. A finding the researcher can't audit in 30 seconds is a bad finding.
- **Prefer false positives over false negatives** for the proposal — but mark borderline cases with hedges (`Probably safe`, `Decide whether…`) rather than `Likely safe`. The researcher's read of the proposal is calibrated by your hedges.
- **Don't recurse into `.git/`, `node_modules/`, `.venv/`, `venv/`, `renv/library/`, `.Rproj.user/`, `__pycache__/`.** These are tooling state, not project content.

## Invocation example

```
User: /research-cleanup
```

Skill walks the project, runs four audits, writes `cleanup-proposal.md`, and reports:

> Wrote `cleanup-proposal.md`. Found 3 orphan scripts (oldest from Jan 2026), 1 stale intermediate (data/processed/panel_v1.parquet — 98 days behind raw watermark), 8 orphan charts in output/, and 4 scratch cells across 2 notebooks. Nothing has been deleted. Review the proposal and act manually.

## What this skill does NOT do

- Does not delete, move, or rename anything.
- Does not modify notebooks, scripts, charts, or data files.
- Does not commit. The proposal is uncommitted markdown; the researcher decides whether to commit it as an audit record or discard it after acting.
- Does not cross into `wiki/` for content checks. `/wiki-lint` handles wiki-internal cleanup.
- Does not lint code style, fix bugs, or refactor. Cleanup is about removal, not improvement.

## Boundary with the archivist agent

Per-plan archival — synthesizing `archive/plan-<slug>.md` from a completed plan, deleting the plan directory, updating `CLAUDE.md` if architecture changed — is the **archivist** agent's job (`~/.claude/agents/archivist.md`), invoked automatically by the Stop hook when a `plan/plan-<slug>/.completed` marker appears. This skill does **not** look inside active or completed `plan/` directories, does **not** propose archiving plans, and does **not** delete or modify `archive/` entries.

Conversely, the archivist is scope-bounded: it touches only the plan being archived, `archive/`, and `CLAUDE.md`. Project-wide cruft — orphan scripts under `scripts/`, stale intermediates under `data/`, unreferenced charts under `output/`, scratch notebook cells — is out of its scope. After the archivist finishes a plan that materially touched source files, it recommends the user run `/research-cleanup` to sweep the rest.

The split is deliberate: per-plan archival is automated (Stop hook → agent → done) and bounded; project-wide cleanup is user-invoked (you read `cleanup-proposal.md` and act manually) and decision-laden. Mixing them would either overreach (the archivist deletes a script that *looked* orphaned) or underreach (this skill skips a plan-shaped cleanup that needed plan context). Each side defers to the other; no logic is duplicated.
