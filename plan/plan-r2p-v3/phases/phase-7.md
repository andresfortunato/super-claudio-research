# Phase 7 — Docs, constitution, release

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** all phases
**✅ DONE 2026-09-09** — `d351edf` … `e396392`, one session. Outcomes at the
bottom of this file; the direction changes are `log.md` **D10**.
**Decision B** was answered *delete*, and its scope was corrected during
execution — see 7.6's outcome.
**Session scope:** one session · **Estimated context:** ~45%

## Intent

Not bookkeeping. Three distinct jobs, and the middle one is bug-fixing:

1. **Write the release down once** — the change table and the traps, in the shape
   of `docs/v1-to-v2-migration.md`, which is the best doc in this repo and the
   template to imitate.
2. **Fix live docs that reference files which no longer exist.** v2 merged
   thirteen conventions into seven and did not chase every reference.
3. **Revise the constitution where v3 changed it**, explicitly — the one rule
   `audience-and-philosophy.md` states about itself is that a proposal failing a
   principle revises the document *first*, never silently.

## The measured inventory

`grep -rln` for references to deleted v1 conventions (`script-header`,
`analytical-commit-format`, `data-sources`, `decision-records`, `evidence-logging`,
`handoff-format`, `plan-structure`, `learnings`) hits **eight files**, and they
are not all the same kind of problem:

| File | Kind |
|---|---|
| `.claude/conventions/project-conventions.md` | **live v2 convention** — a real bug; an agent reads this and follows a dead pointer |
| `docs/audience-and-philosophy.md` | **the constitution** — also lists v1's ten `CLAUDE.md` pointer blocks, now seven |
| `docs/verification-architecture.md` | live design doc — and it still presents the **removed** `check-evidence.sh` as "Layer 1" |
| `docs/r2p-adopt.md` | live adoption guide |
| `docs/{evidence-and-claims,migrate-source,data-sources}-mechanism.md` | the v1 shelf question (decision B) |
| `archive/plan-refdocs-conventions.md` | archived — **leave it**; an archive entry describing v1 paths is correct |

## Tasks

**7.1 — `docs/v2-to-v3.md`** ✚ Change table, why each change, and the traps.

**7.2 — `docs/citation-chain-mechanism.md`** ✚ Design rationale for the three
mechanisms, per `docs/extending.md` step 3. Must record the two redesigns and
their reasons — `chart-registry` → `artifacts:` key (principles 6 and 7), and
`pipeline-check` as principle 9 generalized. A future contributor who does not
know why `save_fig(findings={...})` was rejected will propose it again.

**7.3 — Fix the dangling references.** `project-conventions.md` first: it is live
and an agent acts on it. Then `r2p-adopt.md` and `verification-architecture.md`.

**7.3b — ⚠ ADDED 2026-08-05: the v1 methods path is still live in eight files.**
`methods.md:35` specifies `research/methods/<topic-slug>.md` — one **flat** file
per object, with `_adjuncts/<topic>/` for companions — and the pilot matches it
exactly (37 flat files + `_adjuncts/`). But the v1 directory form
`research/methods/<slug>/rule.md` still appears in files an agent acts on:

```
.claude/skills/planning/SKILL.md                       ×3 (incl. 2 worked examples)
.claude/skills/planning/references/multi-session.md    ×2
.claude/skills/implementation/SKILL.md                 :37
.claude/skills/implementation/references/escalation-reference.md
templates/plan/plan.md                                 :23
templates/plan_dir/archive/README.md                   :21 (and :25/:43 use the flat form)
```

**This is worse than a dangling reference.** A dangling ref fails visibly when
followed; this one instructs an agent to *create* `research/methods/<slug>/rule.md`,
which succeeds, and silently produces a layout the convention, the lint
(`lint-research.sh:96` globs `research/methods/*.md`) and every INDEX row disagree
with. `implementation/SKILL.md` contradicts itself in one file — `:37` directory,
`:64` and `:148` flat.

Leave the two occurrences in `docs/v2-case-study-cordoba.md` and
`docs/v1-to-v2-migration.md` alone: those describe the v1 shape as history and are
correct. *Verification:* after the fix,
`grep -rn 'methods/<slug>/rule\.md\|methods/[a-z-]*/rule\.md' .claude/ templates/`
returns nothing.

**⚠ CORRECTED 2026-09-09 — the inventory above was short by three, and the
verification grep cannot return zero.**

Three more files carry the v1 form and are not in the list: `agent-teams/SKILL.md:131`
(a teammate's self-verification step), `README.md:252` (the scaffold listing claims
`EXAMPLE_method/rule.md`; `templates/` ships `EXAMPLE_topic.md`), and
`audience-and-philosophy.md:120` (principle 9's anchor list — fixed under 7.4).
`multi-session.md:49` carries the *other* v1 form, a date-prefixed
`research/methods/2026-05-07_eph_panel_id.md`, which is v1 `decisions/` repathed
rather than renamed; v2 is kebab-case topic slugs, so it is the same defect.

The grep returns **one** line after the fix, and it is correct:
`.claude/conventions/methods.md:13`, the *"what changed in v2"* history table, is
the same class as the two `docs/` occurrences excluded above. Excluded out loud,
in the spirit of `03_linkcheck.py`'s `BASELINE_PAT` — not silently.
`README.md:252` is fixed in 7.7 with the rest of the stale scaffold listing, not
here, because one corrected line inside a wholly-v1 block reads as a worse lie
than the block did.

**7.4 — Revise the constitution.** Three edits: generalize principle 9 to cover
evidence `## Measured` blocks as anchors; add the compute-graded tier to the
stakes-graded table in principle 7 (and to `verification-architecture.md`); fix
principle 5's v1 pointer-block list. Add the new mechanisms to the
"How the principles bind future additions" table if any needs a new row.

**7.5 — `docs/extending.md`** ✎ Add the pattern v3 actually used —
*cheap lint invariant + user-invoked skill*, in place of the hook that used to be
step 2. And record the trap from `context/installer-map.md`: **a new hook is
mirrored but not wired**, because `--upgrade` never rewrites a project's
`settings.json`. That is the reason v3 adds no hook, and step 2 should say so.

**7.6 — Resolve decision B.** If shelving: `docs/v1/` plus a one-paragraph README
saying these describe v1 and are kept because the case study cites them.

**7.7 — Release.** `README.md` conventions list and version. `package.json` →
`0.3.0` — **after** Phase 6d's `--upgrade` test is green, never before.
`TODO.md`: close v2.1, **cancel** `evidence-ledger` as already shipped-as-`claims.md`
rather than leaving it looking pending, move the plugin migration to v4, and add
the two items this plan generated — the framework repo has no `.claude/settings.json`
of its own (its hooks are unwired here), and it had no `CLAUDE.md` until
2026-08-05. Both are the framework not running the framework; decide deliberately
rather than fixing them in a release commit.

## Verification

- **The Phase 6a link checker, pointed at this repo, reports zero dangling
  references from any live convention or doc.** This is the test; do not
  hand-audit what a tool built in this same release can check.
- `templates/CLAUDE.md.template` gains **zero new sections**. Three new
  mechanisms, one line under *Where Things Go*. §6.7: a mechanism with no
  artifacts does not get a section in the file that loads every session — the
  wiki held two for six months and produced nothing.
- `r2p init` into a throwaway repo: clean scaffold, `lint-research.sh` green and
  silent on the empty tree (all five new invariants must no-op on an empty
  corpus — a linter that fails a fresh install is worse than no linter).
- Then `--upgrade` over a v2 project, per Phase 6d.
- Version bumped exactly once, in the release commit.

## Commit discipline

By pathspec, one command. Keep 7.3 (bug fixes) in commits separate from 7.7
(release) — a reader tracing why a dead pointer was fixed should not land on a
version bump.


---

## Outcomes — 2026-09-09

Eleven commits, `d351edf` … `e396392`. Every task landed. Three things were
found during execution that were in no task list, and they are the entries worth
reading.

| Task | Commit | Outcome |
|---|---|---|
| 7.3b | `1fad4b1` | Nine repaths, not six — the inventory was short by three, and `multi-day` forms of the same defect existed. Correction patched into this file, marked. |
| 7.3 | `d351edf` | **`r2p-adopt.md` was not five dangling pointers; it was an entirely v1 document.** Full repath, three of them conceptual. |
| 7.3 + C | `978de28` | `verification-architecture.md`: Layer 1 → Tier 1 (`lint-research.sh`), tiers 3 and 4 added, the side-effect axis, a new *Why nothing fires automatically*. |
| 7.4 | `8d21a59` | Principles 5, 7 and 9 fixed; **principle 10 added**. |
| 7.6 | `4a7e4fe` | **8 deleted, 6 kept — not 14.** See below. |
| 7.1 | `2faea66` | `docs/v2-to-v3.md`. |
| 7.2 | `28f6a19` | `docs/citation-chain-mechanism.md`. |
| 7.5 | `a6af00b` | `extending.md` step 2 becomes 2a/2b/2c in preference order. |
| item 5 | `6ac46cb` | `EXAMPLE_world_bank_api.md` reshaped to the required five sections. |
| 7.7 | `a964e42`, `e396392` | README + TODO rewritten; `0.3.0` in **two** places. |
| item 4 | `625b48e` | Invariant 15's doc tier → FAIL; `plan/**` split off as permanent WARN. |
| — | `7aedef8` | **A fresh `r2p init` failed its own linter.** Not in any task list. |

### 1. Decision B's scope was wrong, and the phase file said so before the deletion

Decision B said "delete the 14 `docs/*-mechanism.md` files". Only **eight** are
what that decision described — design docs for conventions v2 merged away. The
other six document conventions that are still live, and this same phase's task
7.2 *creates* a new `docs/<name>-mechanism.md`, which `extending.md` still
prescribes as the rationale slot for every convention. Deleting all fourteen
would have retired the pattern in the act of using it.

Escalated before any deletion; researcher chose *delete 8, repath 6*. The six
carried 0–3 stale path mentions each — eight line-fixes in total — so keeping
them cost almost nothing. **`migrate-source-mechanism.md` was in the approved
delete list and was kept**, because the rule the researcher approved with that
list puts it in the keep bucket: the skill is live and 6c repathed it.

*The generalizable part: a decision taken from a file list is a decision about
the list, not about the files. Read them before executing it.*

### 2. A fresh install failed the linter, and two of three findings were the check

The phase's own verification criterion — *green and silent on the empty tree, a
linter that fails a fresh install is worse than no linter* — was the thing that
found it, on the first run against `r2p init` after eleven of eighteen
invariants had shipped. Full write-up:
`docs/field-notes/a-linter-must-be-run-against-a-fresh-install.md`. The rule is
encoded in `extending.md` step 2a.

### 3. The invariant-15 promotion needed a third tier, not a promotion

Item 4 read "promote the WARN tier to FAIL". Done literally, it would leave the
repo red for as long as any plan is open — the seven remaining findings all live
in `plan/`, where quoting a dead convention *while describing the defect* is
correct and no edit makes it both accurate and resolvable. `plan/**` is now its
own permanent WARN tier, and that split is what made the promotion reachable.

### 4. Corrections to this file, marked

- **7.3b's inventory was short by three** and its verification grep cannot
  return zero. Patched in place above, `⚠ CORRECTED 2026-09-09`.
- **7.6's "if shelving: `docs/v1/` plus a README"** is moot; decision B chose
  delete, and the scope split is item 1 above.
- **7.7's two generated items** — the framework repo having no
  `.claude/settings.json` and no `CLAUDE.md` until 2026-08-05 — were added to
  `TODO.md` as open rather than fixed in a release commit, as the task
  instructed. A third was added beside them: `lint-research.sh` has no CI job in
  either repo.
