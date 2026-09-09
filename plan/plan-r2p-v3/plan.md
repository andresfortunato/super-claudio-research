# Plan: r2p-v3 — the checkable chain

v2 made the research record *readable*. v3 makes it *checkable end to end*, and
drains the framework's own bug backlog into the conventions where it belongs.

## Goal

Ship research-to-policy v3 (`package.json` 0.3.0). Three deliverables:

1. **The chain becomes verifiable.** v2 established
   `deliverable → claim → evidence → artifact → script → source` as the
   citation chain, but nothing checks any link. The Córdoba audit's
   highest-value finding — *three load-bearing memo numbers with no evidence doc
   at all, invisible for six months* (`docs/v2-case-study-cordoba.md` §4) — is a
   broken link that no mechanism could see. v3 adds the three mechanisms that
   check the three unchecked links, each graded cheap-lint-first,
   expensive-skill-second.

2. **`docs/field-notes/` stops being a backlog.** v2 created the directory as
   the home for lessons about r2p itself — then encoded only some of them. Seven
   notes sit there as prose; the operational entry points a working agent reads
   (`agent-teams/SKILL.md`, `provenance.md`, `evidence.md`) are silent on most.
   That is the case study's own §6.8 failure mode — *a mechanism invented and
   filed where it cannot act* — recurring one level up, inside the framework
   that named it.

3. **The v2 carry-over closes.** Migration-script hardening, the `migrate-source`
   repath, an `--upgrade` integration test, and the stale v1 docs.

Feeds from `docs/v2-case-study-cordoba.md`, `docs/lessons-ai-assisted-research.md`,
`docs/v1-to-v2-migration.md`, all seven files in `docs/field-notes/`, and the
v2.1 / v1.3 sections of `TODO.md`. No brainstorm — the design space was settled
by the audit, and the open calls are listed under *Decisions To Confirm* below.

### The three unchecked links

| Link | Córdoba symptom | v3 mechanism |
|---|---|---|
| deliverable → claim | memos and decks cited **122 evidence ids directly**; three headline numbers cited nothing at all | **citation-discipline** — lint + `/cite-check` |
| claim → evidence → artifact | the three-lens growth-gap exhibit carrying §1 "lives in a plan handoff and a render script" — no evidence doc | **artifact binding** — `artifacts:` key + lint |
| evidence → script → source | a chart port forced a data re-read and the source had published a **new wave**; the evidence doc had been stale for weeks (`docs/field-notes/porting-a-chart-…`) | **pipeline-check** — staleness lint + user-invoked re-run |

## Constraints

**The nine principles in `docs/audience-and-philosophy.md` bind every addition.**
Any proposal here that fails one must revise the constitution explicitly, in that
document, before landing. Two already forced redesigns — see *Decisions Made*.

**Case-study lessons that bind this plan specifically:**

- **Express size rules as ranks or shares, never absolute counts** (§1). No new
  threshold in v3 may be an absolute document count. The one existing exception
  — `claims.md` mandatory past 40 evidence docs — is a floor for a mechanism's
  *existence*, not a selection rule, and stays.
- **A mechanism with zero artifacts gets no `CLAUDE.md` section** (§6.7). All
  three new mechanisms enter as one line under *Where Things Go* and are
  promoted only once a project has used them. The wiki cost two sections a
  session for six months and produced zero pages.
- **Codify what survives contact** (§6.6). A prescribed format with 10%
  compliance is wrong, not disobeyed. Every new rule here must be checkable
  mechanically, or it will go the way of `learnings/index.yaml` (7 of 71).
- **Never infer a field whose wrongness is worse than its absence** (§5.3). The
  new `artifacts:` key is hand-authored or absent. No heuristic may populate it.
- **Print the heading tree after any document merge** (§5.6), and **measure a
  baseline before claiming you broke nothing** (§5.2). Both become script
  behaviour in Phase 6, not advice in a doc.

**What is explicitly NOT changing:**

- **No layout change.** `research/{claims.md,evidence,methods,sources}` and the
  eight scaffolded dirs stay exactly as v2 shipped them. v3 adds keys and
  checks, never directories. A second migration one release after the first
  would burn the credibility v2 bought.
- **No new always-fire hook.** `check-evidence.sh` was removed in v2 for firing
  unconditionally after a path refactor; every v3 check lands in
  `lint-research.sh` (manual/CI) or in a user-invoked skill.
- **No plugin migration.** Restructuring into `.claude-plugin/` moves every file
  this plan edits and would collide throughout. It stays queued in `TODO.md`
  for v4, and lands cleanly *after* the convention surface settles.
- **No new mechanism may execute project code without the researcher asking.**
  `pipeline-check` is the only thing here that can run scripts, and it must
  print what it intends to run and stop.
- **`evidence-ledger` is cancelled, not deferred.** The TODO entry predates v2;
  `research/claims.md` *is* it. Delete the line rather than let it look pending.

## Decisions Made

Settled. Do not re-debate during execution.

**1. `chart-registry` becomes an `artifacts:` frontmatter key on the evidence
doc — not a `save_fig()` helper and not a per-chart sidecar.** The TODO framing
(`save_fig(findings={...})`) fails principle 6 (Python-specific, and the core is
language-neutral) and re-opens principle 7's settled question (the
`manifest.jsonl` PostToolUse hook was removed in v1 because git plus a script
header already gives ~80% of the audit value at zero install cost). What git
does *not* record is **which finding a chart carries** — that is the actual
Córdoba hole. One optional frontmatter key on the doc that already holds the
finding costs nothing per chart, works in R, Python or Stata, and makes
"chart exists with no evidence doc" a `test -f` rather than a judgement call.

**2. The cheap half of every mechanism is a lint invariant; the expensive half
is user-invoked.** This is principle 7 (stakes-graded verification) applied to
the chain. Concretely: link resolution and staleness are bash in
`lint-research.sh`; walking a deliverable's numbers and re-running a pipeline
are skills. No mechanism ships only its expensive half.

**3. `pipeline-check` is compute-graded, not token-graded, and that is a new
tier.** `docs/verification-architecture.md` warns that a skill wanting a budget
*between* `/verify` (2k) and `/deliverable-review` (12k) is a yellow flag. This
one is not between them — it is cheap in tokens and expensive in wall-clock,
which is a different axis. The architecture doc gains that axis explicitly in
Phase 7; it does not get silently bypassed.

**4. Field notes get an `Encoded in:` line, or they are not done.** A note whose
lesson lives only in `docs/field-notes/` has the same defect as the pilot's
framework bugs filed as project learnings: it is filed where it cannot act. Each
of the seven either names the convention that now carries it, or says in one
line why it stays advisory.

**5. Version `0.3.0` = framework v3.** `package.json` has been 0.2.0 since
before v2 shipped with a hook removed, a hook added and a changed `--upgrade`
path. The bump lands in Phase 7 with the release notes, not opportunistically.

## Decisions To Confirm

Flagged for the researcher before the phase that depends on each. Execution may
proceed on the recommendation if unanswered; each is reversible within its phase.

- **A. `/cite-check` as its own skill, or a fourth check menu inside `/verify`?**
  *Recommend: its own skill.* `/verify`'s contract is 3–5 judgement-shaped checks
  on one artifact; the chain walk is mechanical and enumerates every number in a
  document. Different shape, same ≤2k tier. Blocks Phase 4.
- **B. Do the stale v1 `docs/*-mechanism.md` files move to `docs/v1/`, or get
  deleted?** *Recommend: `docs/v1/` with a one-paragraph README.* They are the
  only record of why v1 was shaped that way, and the case study cites them. But
  note this is not purely cosmetic: `.claude/conventions/project-conventions.md`
  — a **live v2 convention** — references conventions that no longer exist, and
  so do `docs/audience-and-philosophy.md` and `docs/verification-architecture.md`.
  Those are bugs regardless of where the v1 docs land. Blocks Phase 7.
- **C. Should `pipeline-check` ever run a script, or only ever report what is
  stale and hand the researcher the command?** *Recommend: report-and-hand-over
  by default, execute only on an explicit second confirmation.* Blocks Phase 5.
- **D. ✚ ADDED 2026-08-05 — does v3 ship a `#nn → [C<n>]` conversion aid?**
  Measured on the pilot: **573 bare evidence references and zero claim references**
  across three drafts of one memo, against a ledger that already holds 42 claims.
  So `[C<n>]` has a real adoption gap, and every existing deliverable in every
  installed project is in the old form by construction. Each claim's `Rests on:`
  makes `#71 → C12` a derivable lookup, but an id can support several claims and
  the right one depends on what the sentence asserts — so a script can only ever
  *propose*. *Recommend: no script in v3.* `citation-discipline.md` now carries a
  **convert-on-touch** rule, which is the version that survives contact; a
  bulk-rewrite tool would produce one unreviewable diff against the ledger. Revisit
  in v4 if convert-on-touch measurably stalls. Blocks nothing; would extend Phase 6.

- **E. ✚ ADDED 2026-08-05, ⚠ CORRECTED same day — are thematic subfolders allowed
  inside `research/evidence/`?** The pilot has one, `access_to_finance/`: 3
  evidence docs, a `charts/` dir and a memo, tracked. **It is deliberate and
  documented, not a defect** — its README explains that the docs came from another
  branch whose ids 20/21/22 were already taken here, and that renumbering would
  break the byte-identical diff against their source. The subfolder is a
  namespace, chosen on purpose. *(An earlier version of this entry called it
  "already broken" on a ninety-second read. It wasn't.)*
  **The real finding is narrower and still live:** `lint-research.sh` globs
  `"$EV"/[0-9]*_*.md` (`:49`, `:80`) — non-recursive — so it returns a confident
  PASS over three documents it never opened, and those three are absent from
  `INDEX.md`. *Recommend: permit subfolders, and make invariant 1 recursive so
  they are actually checked.* `evidence.md:17` gives the flat path without
  forbidding subdirectories, and at 177 docs the pressure to group is real. What
  must not break is `NN` staying unique project-wide — it is the key `claims.md`,
  every deliverable and `.next-id` resolve against. Whichever way E lands,
  **Phase 3 must make invariant 1 recursive**; a check that silently skips a
  directory is worse than no check. Blocks nothing; extends Phase 3.

## File Manifest

```
plan/plan-r2p-v3/
├── plan.md                                     ✚ this file
├── phases/phase-1.md                           ✚ self-contained — required before the 1‖6 fan-out
├── phases/phase-6.md                           ✚ self-contained — required before the 1‖6 fan-out
├── handoff.md                                  ✚ at first execution session (never before — it records
│                                                  `Last commit`, and the convention forbids fabricating it)
└── log.md                                      ✚ on the first direction change, not before

.claude/conventions/
├── evidence.md                                 ✎ artifacts: key; digest-safe header style; staleness rule
│                                               ✎ 2b: scope_authored: (G4)
├── claims.md                                   ✎ Rests on: must resolve; deliverable-cites-claims made checkable
├── provenance.md                               ✎ commit by pathspec (field note); artifact→evidence binding
│                                               ✎ 2b: a counting script's header states its unit (G7)
├── plan-lifecycle.md                           ✎ point fan-out rules at agent-teams; gap-check breadth
│                                               ✎ 2b: Stage 4 promotion trigger, archivist-checked (meta-finding)
├── citation-discipline.md                      ✚ the chain, stated once (no line cap — log.md D1)
│                                               ✎ 2b: id-collision recovery (G5) — zero coverage today
└── project-conventions.md                      ✎ fix dangling refs to deleted v1 conventions

.claude/hooks/
└── lint-research.sh                            ✎ invariants 8–12 (see Phase 3)
                                                ✎ 3: WARN tier (G3) — before 3.4b; #nn resolution (G2)

.claude/skills/
├── cite-check/SKILL.md                         ✚ deliverable → claim → evidence walk (≤2k)
├── pipeline-check/SKILL.md                     ✚ anchor-diff regression (compute-graded)
├── agent-teams/SKILL.md                        ✎ fan-out hygiene from the field notes
│                                               ✎ 2b: an unranked output is the defect (G8)
├── verify/SKILL.md                             ✎ cross-ref to /cite-check
└── migrate-source/SKILL.md                     ✎ repath v1 → v2 (TODO v2.1)

src/
├── cli.js                                      ✎ register `evidence` subcommand
├── commands/evidence.js                        ✚ `r2p evidence new <slug>` — atomic id from .next-id
└── lib/upgrade.js                              ✎ ship the new convention + skills on --upgrade

templates/
├── CLAUDE.md.template                          ✎ one line under Where Things Go — no new section
├── research/evidence/EXAMPLE_01_slug.md        ✎ show artifacts:
├── migration/02_repath.py                      ✅ bare-segment guard (G1) — LANDED 2026-08-17, ahead of Phase 6
├── migration/03_linkcheck.py                   ✎ --baseline mode; duplicate-path-per-line detector
└── migration/05_methods_merge.py               ✎ print the heading tree after merging

test/
└── upgrade-integration.sh                      ✚ init → dirty → upgrade → assert (TODO v2.1)

docs/
├── v2-to-v3.md                                 ✚ change table + rationale
├── citation-chain-mechanism.md                 ✚ design rationale for the three mechanisms
├── verification-architecture.md                ✎ the compute-graded tier; remove refs to deleted conventions
├── audience-and-philosophy.md                  ✎ principle 9 generalized; fix the v1 pointer-block list
├── field-notes/*.md                            ✎ Encoded in: line on each of the seven
├── field-notes/migration-repaths-the-docstring-not-the-code.md   ✅ LANDED 2026-08-17 (the eighth)
├── v1/                                         ✚ shelf for the superseded mechanism docs (pending B)
└── extending.md                                ✎ the lint-invariant-plus-skill pattern

README.md                                       ✎ conventions list, version
TODO.md                                         ✎ close v2.1; cancel evidence-ledger; v4 = plugin migration
package.json                                    ✎ 0.3.0
```

## Phases

**Detail lives in `phases/phase-N.md`.** Each is independently readable and is the
only phase file a session needs to load. The Goal, Constraints and Decisions
above apply to every phase and are deliberately not restated in them.

| # | Phase | Adds / changes | Sessions | Est. context | Gate |
|---|---|---|:--:|:--:|:--:|
| 1 | Drain the field notes | 7 notes → 4 conventions/skills, `Encoded in:` stamps | 1 | ~40% | — |
| 2 | State the chain once | `citation-discipline.md` ✚, `artifacts:` key, claim-reference syntax | 1 | ~35% | — |
| 2b | **Graduate the Córdoba fixes** ✚ | `scope_authored:`, collision recovery, script-header unit, ranked fan-out, the promotion trigger | 1 | ~40% | — |
| 3 | Lint the chain | invariants 8–12 **+ the WARN tier**, `r2p evidence new <slug>` | 2 | ~55% + ~25% | — |
| 4 | `/cite-check` | skill ✚ (deliverable → claim → evidence walk) | 1 | ~30% | **A** |
| 5 | `/pipeline-check` | skill ✚ (`## Measured` as a re-runnable anchor) | 1 | ~35% | **C** |
| 6 | Harden the tooling | linkcheck `--baseline` + dup-path, merge heading tree, migrate-source repath, `--upgrade` test | 2 | ~50% + ~30% | — |
| 7 | Docs, constitution, release | `v2-to-v3.md`, dangling refs in live docs, constitution edits, 0.3.0 | 1 | ~45% | **B** |

`context/installer-map.md` covers both installers, the shared template map and
how a new convention / skill / hook / CLI command reaches a project. Read it
before touching anything under `src/` — it replaces reading five files, and it
already answers one question the manifest above gets wrong (a new skill needs no
installer edit).

## Phase Order + Dependencies

```
Phase 1 (field notes) ─┐
                       ├─→ Phase 2 ─→ Phase 2b ─→ Phase 3 (lint) ─┬─→ Phase 4 (/cite-check)
Phase 6 (tooling) ─────┘   (rules)    (rules)                     └─→ Phase 5 (/pipeline-check)
                                                                        │
                                        all ───────────────────────────→ Phase 7 (docs, release)
```

- **1, 2 and 6 are unblocked.** 1 and 6 are independent of each other and of
  everything else — safe first session, or a two-agent fan-out.
- **2b blocks 3, for the same reason 2 does.** Its four items are *rules*;
  Phase 3's invariants are the *checks* on them, and invariant G2 checks the
  rule 2b writes. It is a separate phase rather than a reopened Phase 2 because
  Phase 2 is verified `done` and reopening it would cost the status table its
  meaning. It also carries one item belonging to closed Phase 1
  (`agent-teams/SKILL.md`), for the same reason.
- **If 1 and 6 are fanned out:** their phase files are self-contained by design,
  so any correction arriving after launch must be patched *into the phase files*
  before the launch, marked `⚠ CORRECTED <date>`. A fix stored only in
  `handoff.md` cannot reach a worker who never reads it. File ownership is
  disjoint and stated in both. Both commit **by pathspec** — that the plan for
  encoding this lesson is the first place to obey it is the point.
- **2 blocks 3.** A check for a rule not yet written is a guess about what the
  rule would have said.
- **3 blocks 4 and 5.** Both skills read what the lint defines as broken.
- **4 and 5 are independent of each other**, both decision-gated (A, C).
- **7 is last**, and the version bump must not precede Phase 6d going green.

### Session boundaries

- Scope a session to ~50–60% context. Past 60%: finish the current task, write
  `handoff.md`, stop. Starting a new task at 70% is the worst pattern — no room
  to debug.
- **Never start a phase whose predecessor is not committed and verified.**
- Two split points are named in advance, both at clean boundaries: **Phase 3 at
  task 3.6** (the CLI, after the five invariants) and **Phase 6 at 6c**
  (`migrate-source`, the largest of the four items).
- `handoff.md` is rewritten in place each session, never appended. Its
  **Surprises** section is the part that pays — it carries what the plan did not
  anticipate and the code does not make obvious.
- Direction changes go in `log.md`, appended. `plan.md` itself stays stable
  unless the researcher approves a change.

## Open Items Deferred

- **Plugin migration → v4.** Moves every file this plan touches.
- **LaTeX/Beamer, Stata first-class, multi-project dashboard, mode-registry,
  globalized conventions.** Unchanged in `TODO.md`; none is implicated by the
  Córdoba audit.
- **The pilot repo's own §7 follow-ups** — 57 tier-1 evidence rewrites, 28
  synthesised leads, three missing evidence docs, 45 filename-derived triggers.
  Not framework work. But note the dependency runs the other way than it looks:
  Phase 3's invariant 9 is precisely the check that *finds* those three missing
  docs, so running v3's lint against the pilot is the cheapest possible
  validation that the invariant is real — and the honest test of whether v3
  would have caught the defect that motivated it.
