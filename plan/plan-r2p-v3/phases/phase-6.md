# Phase 6 — Harden the migration tooling and the second installer

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** nothing · **Parallel with:** Phase 1
**Self-contained.** A worker on this phase needs no other file. Corrections after
launch are patched *here*, marked `⚠ CORRECTED <date>` — never into `handoff.md`.

## Intent

Four carry-overs from the v2 ship. All four are already diagnosed, so this is
execution, not design. Each traces to a defect that actually shipped.

**Current state was verified by reading the files on 2026-08-04, and it differs
from `TODO.md`'s summary in three places.** Those are marked ⚠ below — trust this
file over `TODO.md` for them.

## 6a — `03_linkcheck.py`: a real baseline, and the duplicate-path detector

**⚠ `TODO.md` implies there is no baseline. There is one, but it is the wrong
kind.** `BASELINE_PAT` (line ~30) is a hardcoded *regex of unresolvable patterns*
— templates, globs, `<slug>` placeholders, URLs. That filters noise; it does not
measure pre-existing breakage.

The case-study lesson (§5.2) is a different mechanism: the checker reported **238
dangling references after the migration**, which reads as catastrophic until the
same checker run against a `git worktree` of the pre-migration commit reported
**405**. Most dangling links predated the migration and the repath *fixed* more
than it touched. Without that comparison there was no way to separate your
breakage from the repo's.

Add `--baseline <git-ref>`: check out the ref into a temporary worktree, run the
same extraction there, and report the **delta** — new breaks, fixed breaks, and
pre-existing ones — not a raw count. Keep `BASELINE_PAT` for what it is good at.
Clean up the worktree even on failure.

Then the duplicate-path-per-line detector. `02_repath.py`'s `EXCLUDE_PREFIXES`
guard structurally *cannot* catch a many-to-one collapse: when three v1
directories map to one v2 directory, an enumerating sentence becomes the same
**valid** path three times, so linkcheck passes on every one of them. Two
instances shipped in v2 and were fixed by hand. The check: flag any line where a
path pattern matches 2+ times with fewer distinct values than matches. It belongs
here, not in `02_repath.py`, because it is a property of the *result*.

**Verification.** Fires on both known v2 instances (recover the pre-fix lines
from git history — do not synthesise a fixture when the real one exists). Does
not fire on a line that legitimately repeats a path. `--baseline` against
`HEAD~1` on a clean tree reports a zero delta.

## 6b — `05_methods_merge.py`: print the heading tree

Case study §5.6: two merge defects were **invisible in the summary counts and
obvious in the heading tree**. An over-escaped regex (`r'^#\s+.+$'` written as
`r'^#\\s+.+$'`) left every H1 in place, and inner `##` headings from merged
learnings silently re-opened top-level sections — collapsing the structure of
every topic file the merge produced. The rule that came out of it: *after any
document merge, print the heading tree.*

**⚠ There is a second, related defect in this file.** Line ~304 does
`print("\n".join(rep[:12]))` — the report is silently truncated to 12 entries.
A cap that is not announced reads as "that was everything," which is precisely
how a merge defect survives its own report. Either print all of it or print the
count that was dropped.

**Verification.** Run the merge on a fixture with (i) a source whose H1 must be
demoted and (ii) a source containing an inner `##`. The printed tree shows the
defect before the fix and the correct nesting after. No truncation without a
stated count.

## 6c — `migrate-source/SKILL.md`: repath to v2

The skill ships **broken on every v2 project**: its preflight gates require
`.claude/conventions/data-access.md` (merged into `sources.md` in v2) and
`<donor>/data_sources/INDEX.md` (now `research/sources/INDEX.md`), so it
hard-refuses before doing anything.

**⚠ It is not uniformly v1 — it is half-repathed, which is worse.** Line 44
already reads `research/sources/INDEX.md` while lines 57, 62, 101, 111, 150,
232, 250, 287 and the manifest table at 439–440 still say `data_sources/`. An
internally inconsistent skill will pass a spot-check and fail in the middle of a
migration. Repath **all** of it, then re-read the whole file for consistency —
a grep for `data_sources` returning zero is necessary, not sufficient.

**Read `archive/plan-migrate-source-skill.md` first.** Both prior plans were
archived as superseded on 2026-08-04 and the entry records the decisions plus
five discovery findings. Re-deriving them is pure waste.

**Verification.** The old blocker was that the post-apply smoke test *never
literally passed* — so "it should work now" does not close this item. Run it
against a real v2 donor with a venv at the test target, through to a written
`MIGRATION_PROPOSAL.md`. Nothing lands on disk until approval; confirm that
property still holds after the repath.

## 6d — `test/upgrade-integration.sh`: cover the second installer

r2p has **two installers**, and `--upgrade` is the one that gets forgotten: a
layout change must be made twice. Three v2 defects lived *only* in the upgrade
path — a stale `EXCLUDE` list, unmapped `templates/plan_dir` +
`claude_conventions_project`, and an ungated wiki — and all three were invisible
to an `r2p init` test.

**⚠ One of the three is already guarded.** `src/lib/upgrade.js:104–114` now has
`staleExcludes()`, added precisely because "a non-matching EXCLUDE entry is
silently inert." Do not re-implement it; assert on it — the test should prove
the guard fires.

Shape: `r2p init` a throwaway repo, **dirty the append-only files** (append rows
to `research/evidence/INDEX.md`, bump `.next-id`, edit `claims.md`), run
`--upgrade`, then assert: no dirtied file was clobbered, the sidecar count is
right, the root-directory list matches the eight v2 dirs, `research/wiki/` is
absent without `--with-wiki` and present with it, and `staleExcludes()` reports
empty.

**Verification.** The test must be shown to *fail* — revert one v2 upgrade fix
in a scratch commit, watch it go red, restore. A green test that has never been
red proves nothing. Pure bash, no new runtime dependency.

### ⚠ ADDED 2026-08-05 — a fourth upgrade defect, measured on the pilot

`~/cordoba-growth-narrative` **still has `check-evidence.sh`, and its
`settings.json` still fires it.** `check-archival.sh` — the v2 replacement — is
absent. So the hook v2 deleted *for firing unconditionally after a path refactor*
is still firing, months later, in the framework's own proving ground.

This is documented behaviour, not an accident: `upgrade.js:174–180` explains that
the orphan is "left in place for the researcher to delete" and that "a project's
own settings.json is never rewritten by `--upgrade`." Never auto-deleting is the
right call — clobbering a researcher's config would be worse.

**The defect is that it warns about everything except this.** `--upgrade` prints
a warning for an obsolete `.claude/skills/` directory (`upgrade.js:351–360`) and
for stale `EXCLUDE` paths (`:246–254`), but emits **nothing** for a hook the
framework no longer ships that the project is still wired to run. Grepping its
`console.log` calls for hook-related output returns zero matches. Silent
deprecation is how a removed hook survives a full release cycle in production.

**Add to 6d:**

1. **`upgrade.js` gains an orphaned-hook warning** — for each `.claude/hooks/*.sh`
   the framework no longer ships, name it, say it is obsolete, and say whether the
   project's `settings.json` still references it. Still never auto-delete.
2. **The test asserts the warning fires** — plant a `check-evidence.sh` and a
   `settings.json` referencing it in the throwaway repo, run `--upgrade`, assert
   both the file and the wiring are called out by name.
3. **Related but out of scope, and stated so it is not lost:** a project's own
   `CLAUDE.md` also goes stale — the pilot's still lists `.claude/skills/` (skills
   are global now) and still describes "a Stop hook" that no longer exists.
   `--upgrade` does not touch project CLAUDE.md and probably should not. A
   *warning* is the same cheap fix as (1) if the researcher wants it.

## Constraints

- **Migration scripts are read-and-adapt artifacts, not a library.** They are
  shipped to be read before running (`docs/v1-to-v2-migration.md`). Keep them
  single-file, stdlib-only, with the `Inputs / Outputs / Seed / Env` header
  intact.
- **Idempotent by rebuild, not by skip** (§5.4). If a change touches how a script
  re-runs, it strips and rebuilds. Skipping "already done" work is what froze a
  bad heuristic run into 151 evidence docs and what shipped an empty `research/`
  tree to every new project.
- **No silent caps** anywhere you touch. If output is bounded, print what was
  dropped. 6b exists because of one.
- **Do not touch** `.claude/conventions/*`, `.claude/skills/agent-teams/`,
  `docs/field-notes/` — Phase 1 owns those, possibly concurrently.

## Commit discipline

Commit **by pathspec**, in one command — never `git add` then `git commit`.
Phase 1 may be running in this same worktree, and the git index is per-worktree,
not per-session: staging and then committing hands your files to whichever
session commits first, under its message.

```
git commit -m "<msg>" -- templates/migration/03_linkcheck.py
```

One commit per item (6a–6d). 6c is the largest and should not be bundled.
