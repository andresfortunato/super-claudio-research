# Framework v3 — the checkable chain

Completed: 2026-09-09

## What was built

v2 established `deliverable → claim → evidence → artifact → script → source` as
the citation chain and checked none of it — the Córdoba audit's highest-value
finding was three headline memo numbers with no evidence doc, invisible for six
months. v3 adds the three mechanisms that check the three unchecked links, each
graded cheap-lint-first / expensive-skill-second: `citation-discipline`
(`artifacts:` frontmatter key + invariants 8–18), `/cite-check` (the
deliverable-to-evidence walk no grep can do), and `/pipeline-check` (staleness
detection that re-runs the producing script directly, the framework's first
side-effecting tier). Alongside that, `docs/field-notes/` stopped being a
write-only backlog — all nine notes now carry an `Encoded in:` line naming the
convention or skill that acts on them — and the v2 carry-over (migration
hardening, `migrate-source` repath, an `--upgrade` integration test, stale v1
docs) closed out. Shipped as `package.json` `0.3.0`.

## Key decisions

1. **`chart-registry` is an `artifacts:` frontmatter key, not `save_fig(findings={...})`.**
   The TODO's Python-helper framing failed principle 6 (language-neutral core)
   and re-opened principle 7's settled `manifest.jsonl` question. A hand-authored
   key on the evidence doc that already holds the finding costs nothing per
   chart and works in any language. Full argument, plus the rejected per-chart
   sidecar: `docs/citation-chain-mechanism.md` §*Redesign 1*.
2. **Every mechanism's cheap half is a lint invariant; the expensive half is
   user-invoked.** No mechanism ships only the expensive half.
3. **`pipeline-check` is compute-graded, not token-graded — a new axis, not a
   new tier between existing ones.** `docs/verification-architecture.md` now
   states token cost and side-effect cost as two independent axes.
4. **Field notes need an `Encoded in:` line or they are not done.** A note whose
   lesson lives only in prose repeats the exact defect it exists to prevent.
5. **Decision A — `/cite-check` ships as its own skill, not folded into
   `/verify`.** Answered as recommended: `/verify` is 3–5 judgement checks on
   one artifact; `/cite-check` is a mechanical, exhaustive sweep of a whole
   document. Same token tier, different shape — the boundary is now written
   into `/verify` itself.
6. **Decision B — delete `docs/*-mechanism.md`, against the recommendation
   (move to `docs/v1/`).** Cost more than the recommendation would have:
   enumerating the 14 files found 8 documenting merged-away v2 conventions and
   6 documenting *live* ones, one of which (`docs/extending.md`) prescribes that
   exact filename as every convention's rationale slot — Phase 7 was about to
   create a new file in the pattern it was deleting. Corrected mid-execution to
   **8 deletions + 6 repaths**, every dangling citation repointed in the same
   commits (`4a7e4fe`, `d351edf`, `978de28`, `1fad4b1`). The generalizable
   lesson, not just this instance: *a decision naming a file set by pattern is a
   decision about the pattern — enumerate and read the set before executing it,
   not before asking.*
7. **Decision C — `/pipeline-check` runs the stale script directly, against the
   recommendation (report-and-hand-over).** Reporting staleness and printing a
   command makes the researcher a copy-paste relay for a decision already made.
   This is the more expensive reversal: it required amending the constitution
   (principle 7) *before* any code, per the constitution's own rule.
8. **Decision D — no bulk `#nn → [C<n>]` converter.** 573 bare references, 0
   claim references, across three memo drafts on the pilot — a real adoption
   gap — but an id can back several claims and only the sentence knows which,
   so a script can only propose one unreviewable diff. `citation-discipline.md`
   carries convert-on-touch instead.
9. **Decision E — thematic subfolders under `research/evidence/` are permitted;
   invariant 1 becomes recursive.** The pilot's one instance
   (`access_to_finance/`) turned out deliberate, not broken — but the lint's
   non-recursive glob returned a confident PASS over three docs it never
   opened. The check was the defect, not the folder.

## Methods landed (framework equivalent: conventions, invariants, constitution)

- `.claude/conventions/citation-discipline.md` — the chain stated once, new.
- `.claude/conventions/{evidence,claims,provenance,plan-lifecycle,project-conventions}.md`
  — `artifacts:` key, claim-reference resolution, `scope_authored:`,
  collision-recovery, the Stage-4 promotion rule this very archival ran against.
- `.claude/hooks/lint-research.sh` — 7 → 18 invariants, 11.0s → 2.3s on the pilot.
- `docs/audience-and-philosophy.md` — principle 5's line budgets dropped
  (37% compliance in r2p's own repo); principle 7 gains the side-effect axis;
  **principle 10, "silence reads as a pass," added.**
- `docs/verification-architecture.md` — the compute-graded / side-effect-graded
  distinction, five tiers.
- `docs/extending.md` — step 2 states lint-invariant-before-skill-before-hook;
  step 2a requires three corpora (mature project, this repo, fresh `r2p init`)
  before any new invariant ships.
- `docs/citation-chain-mechanism.md` — design rationale and the rejected shapes.

## Files added or modified

**.claude/conventions/** — ✚ `citation-discipline.md`; ✎ `evidence.md`,
`claims.md`, `provenance.md`, `plan-lifecycle.md`, `project-conventions.md`
(9 files now ship; README's tree gloss at `README.md:205` still says "7
mandatory + 2 optional" — stale, flagged below rather than fixed here since
`README.md` is outside archival's scope).

**.claude/hooks/** — ✎ `lint-research.sh` (invariants 8–18, WARN tier, `plan/**`
permanent-WARN tier, performance pass).

**.claude/skills/** — ✚ `cite-check/`, `pipeline-check/`; ✎ `verify/`,
`agent-teams/`, `migrate-source/` (v2 repath + redesigned smoke test).

**src/** — ✚ `lib/evidence-new.js`, `commands/evidence.js` (`r2p evidence new
<slug>`); ✎ `cli.js` (registers it; version string); ✎ `lib/install-project.js`
(gitignore the id-allocator lock); ✎ `lib/upgrade.js` (`REQUIRED_GITIGNORE_LINES`
still held v1 `internal_docs/`/`literature/` — the fourth two-installer defect,
found only on the `--upgrade` path again).

**templates/** — ✎ `CLAUDE.md.template` (one *Where Things Go* line, no new
section); ✎ `research/evidence/EXAMPLE_01_slug.md`, `research/sources/EXAMPLE_world_bank_api.md`
(both failed the framework's own invariants on first fresh copy); ✎
`migration/02_repath.py` (bare-path-segment guard), `migration/03_linkcheck.py`
(`--baseline` mode, duplicate-path detector, excludes its own report from
`tracked_md()`), `migration/05_methods_merge.py` (prints the heading tree).

**test/** — ✚ `upgrade-integration.sh` (21 assertions; none existed before).

**docs/** — ✚ `v2-to-v3.md`, `citation-chain-mechanism.md`,
`field-notes/a-linter-must-be-run-against-a-fresh-install.md`; ✎
`audience-and-philosophy.md`, `verification-architecture.md`, `extending.md`,
all eight `field-notes/*.md` (`Encoded in:` lines); ✘ 8 of 14
`docs/*-mechanism.md` files (decision B); ✎ 6 repathed.

**README.md, TODO.md, package.json** — ✎ describe v3; `0.2.0` → `0.3.0` (was
hardcoded in two places — `package.json` and `src/cli.js`'s `.version()` call —
and only one was being bumped; nothing checks they agree, a candidate invariant
if it recurs).

**CLAUDE.md** (this repo's own) — ✎ by this archival: "nine principles" → ten,
"7 mandatory + 2 optional" → 8 mandatory + 2 optional, both stale the moment
7.4 and Phase 2 landed and left uncaught until now.

## Rejected shapes (recorded so nobody re-proposes them)

- **`save_fig(findings={...})`** for chart-registry — Python-specific, and
  duplicated a question principle 7 already settled. `docs/citation-chain-mechanism.md` §*Redesign 1*.
- **A whole-pipeline regression harness** for `pipeline-check` — implies a
  fixture corpus and a runner the framework doesn't own; the actual mechanism
  is a doc-to-script trace plus a numeric re-run. Same doc, §*Redesign 2*.
- **A bulk `#nn → [C<n>]` converter** — one id can back several claims; a
  script can only guess which, producing one unreviewable diff. Decision D.
- **A gap-only duplicate-path rule** for the linkcheck detector — gap alone
  doesn't separate legitimate repeats from real collapses (tightest legitimate
  gap was *closer* than the widest real one); needed gap ≤20 *and* no sentence
  boundary between. Landed as both conditions in `03_linkcheck.py`.
- **Bootstrapping a venv for the `migrate-source` smoke test** — a venv in
  someone else's project is a side effect nobody asked for, and a target
  without one resembles no actual user. Redesigned into a two-stage check: an
  `ast`-parse stage needing nothing installed (the one that counts), and a real
  import as informational second stage. Landed in `migrate-source/SKILL.md`.

## Learnings

**A hand-built inventory of invisible defects is always short, and this
recurred at two different scales in the same plan.** D5 counted five dangling
convention pointers; the next session's mechanical sweep found seven; the one
after that found ten here and seven more on the pilot, and the two sevens
weren't the same seven. One level up: D10 found that a *task line* written
months earlier ("delete the 14 mechanism docs", "README needs a conventions
list and version") was its own kind of stale inventory — the README's `docs/`
tree named nine files that no longer existed and none of the four that did.
Both are the same failure — enumerate the *actual* set before trusting a count
taken earlier — and it kept paying off because nobody stopped re-measuring.

**A framework cannot check itself against itself, and — separately — it cannot
check itself against its own users.** Both this repo and the Córdoba pilot are
*mature, populated* corpora; the first `r2p init` run of the completed linter,
done for the first time after 11 of 18 invariants had already shipped, exited 1
on a tree with no research at all. Two of three findings were the check asking
the wrong question (a `~/`-prefixed path is a global install; a prose-qualified
`docs/` pointer is deliberate); the third was the shipped `claims.md` seed's own
placeholder claim. Encoded as a required third corpus in `docs/extending.md`
step 2a — this is a framework-level lesson, not an engagement one, so it lives
in `docs/field-notes/` rather than here.

**A generated report, committed once, becomes its own input.** `linkcheck.md`
was swept up by an over-broad `git add -A` twice across two phases, and each
time the next run read a previous run's table rows as new findings. Fixed by
excluding the tool's own output from what it scans — a narrow fix, but the
repetition is the point: the same tool-reads-its-own-artifact shape hit twice
without anyone recognizing it the second time until the symptom looked
suspiciously familiar.

**Verification criteria found more defects than the task list did, consistently
enough to be a pattern rather than luck.** "Green and silent on a fresh
scaffold" and "build the broken fixture, watch it go red" each surfaced a
shipped defect no diff-reading would have — including a defect in the
*fixture itself* (a first invariant-13 test was red for two unrelated reasons,
which would have read as confirmation while proving nothing).

## Metrics

- Phases: 8 completed (1, 2, 2b, 3, 4, 5, 6, 7 — 2b inserted mid-plan)
- Sessions: 7 (2026-08-05 ×3 log entries, 2026-08-17, then four more on 2026-09-09)
- Commits: 72 from `b1c88bb` to the handoff commit, plus this archival
- Lint: 7 → 18 checks; 11.0s → 2.3s on the pilot corpus (285 docs)
- `docs/*-mechanism.md`: 14 files (2,695 lines) → 6
- `--upgrade` test coverage: none → 21 assertions
- Version: `0.2.0` → `0.3.0`
- Last content commit before archival: `67a5398`. An archive entry cannot name
  the commit that adds it; `git log --oneline -- archive/plan-r2p-v3.md` does.
