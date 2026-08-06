# Graduating the Córdoba r2p fixes to production

**Status:** scoping note, written 2026-08-05. **Not a phase.** The next session's
job is to *study*, not to implement.

## Why

`~/cordoba-growth-narrative` did not just use r2p — it **fixed r2p** repeatedly,
under real deadline pressure, and the fixes worked. Most never came back to the
framework. The goal is to graduate the ones that survived contact.

This is `docs/v2-case-study-cordoba.md` §6.8 applied to the pilot's own repo:
*read what your users built in the wrong place — complaints are rare, workarounds
are everywhere and they are precise.*

## What this conversation already established

Confirmed by measurement, so the next session need not re-derive it:

- **Claims are written `### C<n>` under `## §N` sections**, not `## C<n>`. 42 of
  them. Already fixed in `claims.md` and `citation-discipline.md`.
- **Deliverables cite evidence directly at scale** — 573 bare `#nn` and zero
  claim references across three drafts of one memo. → decision D.
- **`check-evidence.sh` is still live and wired** in the pilot's `settings.json`;
  `--upgrade` never warns about an orphaned hook. → phase 6d.
- **The index was genuinely fixed**: 330 KB → 33 KB on 2026-08-04
  (`6a7da12`). Today 40 KB / 187 rows / 177 docs. It is healthy.
- **`research/evidence/access_to_finance/` is deliberate, not a bug.** Its
  README explains it: the docs came from a branch whose ids 20/21/22 were already
  taken, and renumbering would break the byte-identical diff against the source
  branch. What *is* real is that `lint-research.sh` cannot see inside it.
- **Two reusable inventions** worth graduating on current evidence: a **coverage
  gate** (prove every evidence doc was consciously routed before drafting — it
  is what found the load-bearing exhibit with no evidence doc) and **cite by
  filename, never bare `#nn`, when ids collide**.

**Deliberately dropped: `mapa_evidencia.md`.** Examined and rejected as a
framework mechanism — it was a July-31 workaround for an index that was fixed on
August 4, and a session that needs a map will build one. Do not re-propose it.

## What was NOT studied — this is the actual task

I read the pilot's **current state** and only skimmed its history. That was the
mistake. The next session should read **the diffs**, not the tree.

Start here:

```
plan/plan-r2p-v2-consolidation/     case-study.md · for-r2p/ · for-project-conventions/
                                    mapping/ · migration/
plan/plan-narrativa-final-memo/     the gate scripts + digest_evidence.py
```

Framework-changing commits, oldest first:

| Date | Commit | What |
|---|---|---|
| 2026-05-11 | `0a47e5e` | install r2p scaffolding (+ the `adopt:` series that follows) |
| 2026-06-29 | `797a767` | migrate to the new r2p layout |
| 2026-08-04 | `1360b06` | v2 conventions; root 26 dirs → 8 |
| 2026-08-04 | `6a7da12` | evidence gets machine-readable scope; INDEX 330 KB → 33 KB |
| 2026-08-04 | `9a0ae94` | 113 files in 3 dirs → 28 topic files; `learnings/` dissolves |
| 2026-08-04 | `19e9085` | rewire retrieval, add the lint, write the case study |

Also unexamined: `for-project-conventions/` (9 files — visualization, slide
design, one on pandoc/docx production that may generalize), and the other
worktrees, which hold branches this one never sees.

## What to produce

A list of **candidate graduations**, each with: what the pilot changed, the
evidence it worked, and whether it belongs in a convention, a skill, the lint, or
nowhere. Not edits. The point is to decide what earns promotion — several will
not, and saying so is a result.

Ask before writing anything into the plan.
