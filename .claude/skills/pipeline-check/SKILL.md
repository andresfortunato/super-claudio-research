---
name: pipeline-check
description: (r2p) Check whether an evidence doc's recorded numbers still hold — trace it to its producing script through the provenance trail, re-run that script, and diff what comes back against `## Measured`. Use when the user says "/pipeline-check #71", "/pipeline-check --stale", "are these numbers still current", "re-run the evidence behind this claim", or after data/raw/ changes. User-invoked; executes scripts, so read *Preconditions* first.
allowed-tools: Read, Bash, Glob, Grep
---

# pipeline-check

Answer one question: **do the numbers written in this evidence doc still hold?**

Principle 9 of the constitution demands *verifiable freshness anchors* — every
freshness timestamp paired with a concrete, re-runnable value. An evidence doc's
`## Measured` block **already is one**: concrete numbers produced by a documented
procedure, and kept verdict-free by lint invariant 5, which is what makes it
mechanically comparable. This skill treats it as the anchor it is.

**This is the one r2p skill that writes.** `/verify`, `/cite-check` and
`/deliverable-review` are read-only; this re-runs analytical scripts. The four
bounds that permit that are in `docs/audience-and-philosophy.md` principle 7 and
are restated under *Execution* below. Do not exceed them.

## When to invoke

- `/pipeline-check #71` — one evidence doc.
- `/pipeline-check C12` — a claim; checks every doc its `Rests on:` names.
- `/pipeline-check --stale` — every doc lint invariant 10 flagged.
- "`data/raw/` was refreshed — what's now out of date?"

## When NOT to invoke

- **To find out whether a number is *right*.** This asks whether it still
  *reproduces*. A pipeline reproduces a wrong number perfectly. That is `/verify`.
- **To check a deliverable's citations** — `/cite-check`.
- **On a dirty working tree.** See *Preconditions*; this is a refusal, not a
  warning.

## Preconditions — all four, before anything runs

1. **The repo is a git repo.** The whole trace is `git log`; without it there is
   no provenance and nothing to do.
2. **The target artifacts are committed and clean.** `git status --porcelain` must
   be empty for every path the run will write. **This is the undo.** Re-running
   overwrites the artifact in place, and git is the only thing that gets the old
   one back — so an uncommitted artifact would be destroyed with no recovery.
   Refuse, name the dirty paths, and say `git stash` or commit first.
3. **The script's header is readable and complete** (`provenance.md` half 1).
4. **`Seed:` is present and is not `none`.** No seed means no reproducible
   comparison, so a diff would be indistinguishable from sampling noise and
   would generate false alarms forever. **Refuse the comparison and say why** —
   do not run the script anyway and caveat the result.

## The trace

Walk it in this order and stop at the first break:

```
evidence doc ──artifacts:──→ artifact path
             ──git log -1 -- <artifact>──→ commit
             ──commit message `Run:`──→ script path
             ──script header──→ Inputs: · Outputs: · Seed: · Env:
```

Reuse the settled readers rather than re-deriving them: `artifacts:` is a YAML
**block** list and the key is **optional** — absent means "not stated", never
"no charts exist". `Run:` and `Out:` are both required when a script ran; an
artifact changed without a re-run carries `Out:` alone with a parenthetical, and
that is a legitimate state, not a break.

## The comparison, and its granularity

**The correct granularity is not the finest.** The pilot's own staleness gate
ruled on three designs before it was abandoned, and the ruling stands: date-only
catches the real failure but screams whenever `git checkout` rewrites mtimes;
date-plus-content looks the most rigorous and is the one a prior lesson already
proved to be noise, because bare years match anything. Compare **numbers**, not
bytes and not timestamps.

| Output shape | What to compare |
|---|---|
| machine-readable (`.json`, `.csv`, a regression table, a printed summary) | the numbers in `## Measured`, value by value |
| image only (`.png`, `.pdf`, `.svg`) | **cannot compare numbers.** Say so — see below |

**An image-only script is a "cannot compare", not a pass.** The numbers in
`## Measured` are not recoverable from a PNG, and byte-diffing the image reports
every palette and font change as a finding — exactly the noise the ruling
rejects. Look upstream first: if the script's `Inputs:` name a machine-readable
intermediate that another script wrote, check *that*. If nothing numeric exists
anywhere in the chain, report `cannot compare — image-only output` and stop.
**Never report "unchanged" on the strength of a chart that merely re-rendered.**

## Execution

Decision C: this skill **re-runs the script directly**, without a second
confirmation. Reporting staleness and handing over a command makes the researcher
a copy-paste relay for a decision the check already made.

**The four bounds, from principle 7. These are not style:**

1. **Re-runs existing, human-inspectable code.** Never writes or edits a script.
2. **Writes only what the script's header declares under `Outputs:`.** If a run
   writes a path the header does not name, that is a header defect — report it,
   and do not treat the extra file as a result.
3. **User-invoked.** Never auto-fires, never on a clock, never from a hook.
4. **Reports what it ran** — the command, the seed, the wall-clock, the paths
   touched. Execution without a record is what `provenance.md` exists to prevent.

Run scripts **one at a time**, and stop the batch on the first non-zero exit —
report the failure rather than pressing on. A pipeline whose step 3 failed makes
every later comparison meaningless.

## Refusal cases — enumerate, never guess

A confidently wrong answer is worse than a blank one: it gets trusted, and then
manufactures a contradiction that costs more to unpick than the original gap.
Each of these is reported by name, with the step that broke:

| Case | Report |
|---|---|
| no `artifacts:` key | `cannot trace — doc binds no artifact` |
| `artifacts:` path not on disk | `cannot trace — bound path missing` (lint invariant 12 owns this; say so) |
| no commit touches the artifact | `cannot trace — artifact never committed` |
| commit has no `Run:` line | `cannot trace — no Run: in <sha>` (legitimate if `Out:` says "no script re-run") |
| script named by `Run:` no longer exists | `cannot trace — script deleted since <sha>` |
| script has no header | `cannot trace — no provenance header` |
| `Seed:` missing or `none` | `cannot compare — unseeded run` |
| image-only outputs | `cannot compare — image-only output` |
| non-zero exit | `run failed — <exit code>`, plus the last lines of stderr |

**"Cannot trace" is a finding, not a gap in this skill.** On the pilot the
untraceable docs were the ones worth looking at.

## Report format

```markdown
# /pipeline-check <target> — YYYY-MM-DD

**Scope:** <n> evidence doc(s) · <n> traced · <n> re-run · <n> refused

## Numbers that moved — <n>
| Doc | Measured says | Re-run says | Script |

## Reproduced unchanged — <n>
<one compressed line-list: id, script, seed>

## Could not check — <n>
| Doc | Broke at | Reason |

## Ran
| Script | Seed | Wall-clock | Paths written |
```

All four sections always, `(none)` where empty. **A doc that reproduced is not
silence** — the same rule the lint applies to inapplicable invariants: an
omission reads as a pass, and here a pass is the expensive thing to get wrong.

Cap every list and **print the dropped count**. Token cost must stay low even
when wall-clock is high — those are different axes and only one of them is the
budget.

## Rules

- **Never edits a script, a deliverable, an evidence doc, or `data/raw/`.** It
  re-runs; it does not repair. A moved number is the researcher's call — the doc
  may be stale, or the pipeline may have regressed, and this skill cannot tell
  which.
- **Refuse rather than caveat.** An unseeded comparison is not a weak result, it
  is not a result.
- **Report every path written**, including ones that turned out identical.
- **One script at a time; stop on first failure.**

## Cross-references

- `.claude/conventions/provenance.md` — the header schema and the `Run:` / `Out:`
  commit format this whole trace walks.
- `.claude/conventions/evidence.md` — `## Measured`, and `artifacts:`.
- `.claude/hooks/lint-research.sh` — invariant 10 is what `--stale` reads;
  invariant 12 owns "bound path missing". Do not reimplement either.
- `docs/audience-and-philosophy.md` principle 7 — the side-effect axis and the
  four bounds above.

## What this skill does NOT do

- **Not a correctness proof.** It answers *do the recorded numbers still hold?*,
  never *are they right?* A pipeline can reproduce a wrong number perfectly, and
  a green report here is not a green report from `/verify`.
- Does not check citations (`/cite-check`) or review a draft (`/deliverable-review`).
- Does not repair a stale doc, rewrite a header, or fix a script.
- Does not run on a dirty tree, an unseeded script, or a broken trace.
- Does not auto-fire.
