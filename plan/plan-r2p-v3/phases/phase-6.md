# Phase 6 — Harden the migration tooling and the second installer

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** nothing · **Parallel with:** Phase 1
**Self-contained.** A worker on this phase needs no other file. Corrections after
launch are patched *here*, marked `⚠ CORRECTED <date>` — never into `handoff.md`.

## Status — ✅ ALL SIX ITEMS DONE 2026-09-09

| Item | Commit | Note |
|---|---|---|
| 6e lint runtime | `6a0086d` | 11.0s → 2.0s, output byte-identical |
| 6f pointer resolver → invariant 15 | `411ec33` | found 4 live defects beyond the inventory |
| 6g/6h/6i invariants 16, 17, 18 | `fe96465` | + `89d6ba0`, invariants 4 and 5 rescoped |
| 6a linkcheck | `41a68d9` | found a third collapse instance, live in README.md |
| 6b methods merge | `ddd74ae` | heading tree + three audit rules; no silent cap |
| 6c migrate-source | `3e20032` | repathed; smoke test given a criterion that can pass |
| 6d `--upgrade` test | `d195621` | 21 assertions, shown red on four reverted fixes |

## ✚ ADDED 2026-09-09 — the phase grew from four items to six

`handoff.md` (2026-09-09) carried five new candidates, ranked, none of which was
in any task list. **They are recorded here rather than left in the handoff,
because this file is the one a worker on this phase reads** — the rule at the top
of this file exists for exactly that reason and the handoff broke it.

Ranked as the handoff ranked them, renamed to not collide with 6a–6d:

- **6e — the lint's runtime.** ⚠ Re-measured: **11.0s on the pilot, not the ~9s
  on record.** Profiled: 4.32s in the per-doc frontmatter loop, 1.26s in
  invariant 10's git calls, ~1.0s re-parsing `artifacts:` three times.
  **Executed FIRST, out of rank order.** The other four candidates add checks to
  this script; adding them before paying the per-document process cost once
  would have multiplied it into four more places.
- **6f — a convention-pointer resolver** → **invariant 15**. Widened during
  execution to every `.claude/**` and `docs/**` pointer, which is what makes
  Phase 7's documentation *deletion* safe.
- **6g — `status: retired` under a cited claim** → **invariant 16**.
- **6h — a claim with no `Rests on:` ids** → **invariant 17**.
- **6i — the ids after the first `·`** → **invariant 18**.

## Intent

Four carry-overs from the v2 ship, plus five items added mid-phase (above). The
original four were already diagnosed, so those were execution, not design. Each
traces to a defect that actually shipped.

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

**✅ DONE `41a68d9`.** Verified against a worktree of `c133bc2^` — both known
instances fire. **⚠ There was a third, live in `README.md:24` since v2**, listing
`research/methods/` three times where v1 read `methods/`, `decisions/`,
`learnings/`. Fixed in the same commit; the same line was also wrong about
`research/wiki/`, which v2 gates behind `--with-wiki`.

**⚠ CORRECTED 2026-09-09 — "does not fire on a legitimate repeat" cannot be met
by the rule as this file states it.** "2+ matches with fewer distinct values than
matches" fires on 11 lines here and 8 legitimately name a path twice across a
sentence. Measured separator lengths: real collapses 4, 4, 7, 10, 18;
legitimate 16, 48, 48, 70, 83, 86, 102, 148, 164, 209, 661. **Gap alone does not
separate them — the 16 is closer than the 18.** Gap ≤20 *and* no sentence
boundary in between separates all fourteen. Everything failing either criterion
is still printed under `noted`, with its gap.

**Also fixed:** the report path was hardcoded into the archived
`plan/plan-r2p-v2-consolidation/mapping/`, so the script crashed on write.
Default is now `linkcheck.md` at the repo root, `--out` to override.

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

**✅ DONE `ddd74ae`.** Fixture built exactly as specced; verified red on each
defect and green on the correct version. The report prints in full — no cap at
all rather than a stated one, since it is a once-run script whose output is the
point.

**✚ ADDED — a third audit rule this file did not anticipate.** Verifying the two
obvious rules (H1 count, stray H2) exposed a case neither sees: breaking *only*
the H1 strip does not leave a stray H1, because the surviving H1 is demoted to
`####` and lands directly under the `### <title>` the wrapper already wrote.
Duplicated, wrong, invisible. Rule 3 flags **two consecutive headings with the
same text**, scoped to consecutive on purpose — two merged decision records can
legitimately both contribute a `#### Validation` under one section.

*Note on the diagnosis in this section:* the two symptoms are **one** bug, not
two. A broken demotion regex leaves inner `##` at top level; there is no separate
"H1s left in place" defect unless the strip is broken too.

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

**✅ DONE `3e20032`.** Repathed (15 occurrences) and re-read end to end. All six
preconditions pass against `~/research/cordoba` as a real v2 donor; the
pre-repath gates 3 and 4 refuse on that same donor, which is the bug. All five
apply-gate invariants still stated verbatim; Phase D still gated on explicit
approval.

**⚠ CORRECTED — the smoke test needed redesigning, not a venv.** This file
inherited the archive's fix ("bootstrap a venv at the test target"). Rejected: a
venv in someone's project is a side effect nobody asked for, and every real r2p
project already has one — a target without a venv resembles no actual user,
which was the original planning gap. The criterion itself was the problem.

Two stages now, and **which half counts is stated**, per the archive's own
learning that "classified correctly" is not "succeeded":
- **Stage 1**, structural, must pass: `ast`-parses the utility module and answers
  the only three questions a transplant can break — does it parse, did every
  wrapper arrive as a module-level `def`, is a `TODO_TARGET_*` sitting where
  import will hit it. Needs no venv, no `.env`, no network. Verified red and
  green with nothing installed.
- **Stage 2**, the real import, informational only. Env vars set to dummies in
  the subprocess environment (never `.env`) so an eager `os.environ[...]` at
  module scope does not read as a migration failure.

**A grep for `data_sources` returning zero was indeed not sufficient.** The
repath also had to fix the v2 source-doc shape the skill was ignorant of:
`status:` is a frontmatter key not a `Status:` prose line, the required sections
are the v2 five not v1's six, and `triggers:` is load-bearing for retrieval.
`templates/research/sources/INDEX.md`'s add-a-source recipe was naming v1's six
sections too — a shipped instruction contradicting a shipped convention.

**⚠ LEFT UNDONE, for Phase 7.**
`templates/research/sources/EXAMPLE_world_bank_api.md` has v2 frontmatter and v1
section headings, so the framework's own worked example fails its own required
shape. Reshaping it is editorial work about the World Bank API rather than a
repath. The INDEX recipe now says in one line to follow the list and not that
file, so nobody copies the wrong shape meanwhile.

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

**✅ DONE `d195621`.** `test/upgrade-integration.sh`, 21 assertions over five
scenarios, wired to `npm test`. Shown red on **four** reverted fixes, not one,
and the failures are narrow rather than a cascade:

| Reverted | Fails |
|---|---|
| pre-v2 EXCLUDE list | 5 — staleExcludes non-empty, all seven append-only files sidecar'd |
| prefix-strip instead of TEMPLATE_DIR_MAP | 2 — root dir list drifted |
| wiki gate removed | 1 — wiki reinstated into an opted-out project |
| orphan warning neutralised | 2 — hook not named, wiring not reported |

`staleExcludes()` is asserted, not re-implemented. Orphaned-hook warning keyed on
an explicit `REMOVED_HOOKS` map with its own staleness guard
(`resurrectedHooks()`) — "any hook we do not ship" would call a researcher's own
hook obsolete, which is how a warning earns being ignored.

**⚠ Invariant 15 detects the same orphaned hook independently**, from the other
direction: `check-evidence.sh` carries six dangling convention pointers, so it
shows up in the pilot's lint whether or not anyone runs `--upgrade`.

### ⚠ ADDED 2026-08-05 — a fourth upgrade defect, measured on the pilot

`~/research/cordoba` **still has `check-evidence.sh`, and its
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
