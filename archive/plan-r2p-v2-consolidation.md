# Framework v2 — Consolidation

Completed: 2026-08-04

**Note on provenance.** Unlike every other entry in this archive, the plan that
produced v2 (`plan-r2p-v2-consolidation`) was executed in the *pilot project's*
repository, not here — it was an audit of a live engagement that then promoted its
findings into the framework. There is no `plan/plan-r2p-v2-consolidation/` directory
in this repo to archive. This entry is written from the three shipped commits
(`dfacab5`, `ce022d8`, `ed591a0`) and the two documents they landed, so the release
has a record in the same place as the others.

## What was built

A consolidation, not a feature release. v1 was audited against the first r2p
engagement to run six months at full intensity — Córdoba: 151 evidence docs, 43
decision records, 70 learnings, 60 source docs, 26 root directories — and every
change answers something measured there.

- **Conventions 13 → 7 mandatory + 2 optional.** `evidence.md` (rewritten),
  `claims.md` (new), `methods.md` (absorbs decision-records + learning-capture),
  `sources.md` (absorbs data-access), `plan-lifecycle.md` (absorbs
  brainstorm-format + plan-structure + handoff-format), `provenance.md` (absorbs
  script-header + analytical-commit-format), `project-conventions.md`.
  `source-registry` and the wiki ship un-promoted behind `r2p init --with-wiki`.
- **Layout 15 scaffolded dirs → 8.** `research/{claims.md,evidence,methods,sources}`,
  `plan/{archive,brainstorms}`, `deliverables/{memos,decks}`,
  `reference/{literature,notes,internal,external}`.
- **CLAUDE.md template 14 sections → 7**, under the rule that produced it: a
  mechanism earns a section only once it has artifacts.
- **`docs/field-notes/`** — seven lessons recovered from the pilot's `learnings/`
  that were never about the pilot at all. They were bugs in r2p.
- **`templates/migration/`** — the six scripts used on the pilot, written to be
  read and adapted rather than run blind.

## Key decisions

1. **Split measurement from verdict in evidence docs.** v1 asked for `**claim** —
   number — implication` in one bullet, so authors wrote verdicts: 338 verdict
   words across 93 of 151 docs. *Measurements do not contradict each other;
   verdicts do.* v2 splits `## Measured` from `## Reading` and lints the boundary.

2. **Scope keys go in frontmatter, never prose.** Unit, period and weighting in
   paragraphs made a province number and a metro number on the same topic read as
   a conflict. Moving `unit` / `geography` / `period` into frontmatter turns "these
   disagree" into a mechanical test.

3. **Add a curated layer (`claims.md`) above the append-only corpus, mandatory
   past 40 evidence docs.** The v1 index reached 330 KB with a median title of
   1,554 chars. The decisive evidence was not the size: the pilot had *already
   built* the claims layer by hand — `mapa_evidencia.md` (1,568 lines),
   `retracciones.md` (40 retractions), `flags_narrativa_vs_evidencia.md` (128
   flags) — inside a single plan folder, marked "GENERADO. No editar a mano",
   stating in its own header that it existed so no drafting session would have to
   reopen a 317 KB index. The mechanism was missing, so a researcher invented it in
   the wrong place and it died with the plan. Alternative considered: cap the index
   and stop there. Rejected — the cap (330 KB → 33 KB) was necessary but does not
   supply synthesis.

4. **Merge by topic, not by genre.** v1 split `decisions/` (why), `methods/` (the
   rule) and `learnings/` (the traps) into three directories. Research arrives by
   *topic*, and one topic needs all three. 43 + 28 + 70 records became 28 topic
   files. Alternative: keep the genres and cross-link. Rejected — the cross-links
   are what nobody maintained.

5. **Gate the wiki behind a flag rather than deleting it.** Zero pages and zero
   scrapes in six months, at a cost of two CLAUDE.md sections every session. It
   works; it is just wrong to scaffold by default. `--with-wiki` for projects whose
   primary input is a *stream* (news, filings, bulletins) rather than datasets.

6. **Keep historical records on their v1 paths deliberately.** `archive/`,
   `brainstorms/` and `docs/*-mechanism.md` describe v1 accurately, so repathing
   them would make them wrong. The consequence is a live docs set that still
   documents merged conventions — accepted, and flagged as a pre-release cleanup.

7. **Size-dependent rules must be expressed as ranks or shares, never absolute
   counts.** Learned inside the migration: the first tier rule for which docs to
   rewrite was `cited ≥3×`, which on a corpus where citation counts run 80–180
   admitted 145 of 151. Every v1 size range was wrong by 3–10× — v2 restates them
   and changes their form.

## Methods landed

None in this repo. v2 changed conventions, templates, the installer and hooks;
`research/methods/` files are project artifacts, not framework ones.

## Files added or modified

Grouped by directory. (✚ new, ✎ modified, ✗ deleted). 109 files changed,
4,176 insertions, 2,648 deletions.

**.claude/conventions/** — 13 files → 9
- ✚ `claims.md`, `evidence.md`, `plan-lifecycle.md`, `provenance.md`, `sources.md`
- ✎ `methods.md` — absorbs decision-records + learning-capture
- ✗ `analytical-commit-format.md`, `brainstorm-format.md`, `data-access.md`,
  `data-sources.md`, `decision-records.md`, `evidence-logging.md`,
  `handoff-format.md`, `learning-capture.md`, `plan-structure.md`,
  `script-header.md`

**.claude/hooks/**
- ✚ `lint-research.sh` — seven invariants, each one a defect that actually happened
- ✎ `retrieve-learnings.sh` — reads `triggers:` frontmatter instead of
  `learnings/index.yaml`; 120-line per-doc cap

**.claude/skills/** — 13 skills repathed to the v2 layout

**docs/**
- ✚ `v2-case-study-cordoba.md` (337 lines) — the full audit
- ✚ `v1-to-v2-migration.md` (132 lines) — the change table, the four evidence
  defects, the calibration table, four traps in running the migration
- ✚ `lessons-ai-assisted-research.md` (262 lines) — general-audience companion,
  assumes no knowledge of r2p
- ✚ `field-notes/` + 7 notes
- ✎ renamed: `evidence-mechanism.md` → `evidence-and-claims-mechanism.md`;
  `learning-capture-mechanism.md` and `methods-mechanism.md` → `*-v1.md`

**templates/** — restructured; `research/`, `reference/`, `plan_dir/`,
`deliverables/{memos,decks}`, `claude_conventions_project/`, `migration/`

**src/**
- ✎ `lib/install-project.js` — `--with-wiki`; two ordering bugs fixed
- ✎ `cli.js`, `commands/init.js`; `package.json` → 0.2.0

## Learnings

**A framework working as designed is not the same as a framework calibrated
correctly, and the second failure is harder to see.** Nothing in v1 broke. Every
convention was followed. The corpus still became unreadable, because the sizes v1
anticipated were wrong by 3–10× and its formats degraded gracefully into
uselessness rather than failing loudly.

**Users don't complain; they build workarounds, and the workarounds are precise.**
The hand-built claims layer is a better specification for `claims.md` than anything
that could have been designed from the convention docs. Look for the files marked
"generated, do not edit by hand" that no generator produced.

**A learning about the framework has to leave the project repo or it recurs.**
Seven of the pilot's 70 learnings were bugs in r2p, not findings about Córdoba. The
evidence-id collision was filed *twice*, months apart, and recurred because the
first filing had nowhere to go that would change the framework. Hence
`docs/field-notes/`.

**Migration scripts must be idempotent by rebuild, not by skip.**
`04_evidence_frontmatter.py` first skipped docs that already had frontmatter, which
silently froze a bad heuristic run in place. The same class of bug hit the
installer: `mkdir research/evidence/` before mirroring made the mirror skip it as
"exists" and ship an empty tree.

**Measure a baseline before claiming you broke nothing.** `03_linkcheck.py`
reported 238 dangling references post-migration, which looks alarming until you run
it against a worktree of the pre-migration commit and get 405.

**A confidently wrong scope key is worse than a blank one.** Heuristics tagged a
24-province panel as `metro | 1960–2026` — the year regex swept every number in the
first 6 KB. Author `unit` and `period`; let the fallback be `unknown`.

**The upgrade path is a second installer, and v2 only moved the first one.**
`upgrade.js` held its own answers to two questions `install-project.js` had already
answered — which templates are project state (`EXCLUDE`) and where each template
lands (`toProjectRel`) — plus no answer at all to a third (is the wiki opted in).
All three broke on the v2 layout move, and none of them failed loudly: a stale
exclusion is inert, a wrong path mapping creates a directory rather than erroring,
and a missing gate just installs something. Found in the v2 bookkeeping pass by
integration-testing `--upgrade` rather than `init`. The structural fix was
`lib/template-map.js`, one table with two consumers. **When a framework has both an
install and an upgrade path, a layout change is two changes.**

**Trap 1 bites the documentation about the trap.** A mechanical repath rewrites the
text that exists to preserve the old paths — demonstrated live when the port turned
`02_repath.py`'s own rule table into `("research/sources/", "research/sources/")`.
The script gained an `EXCLUDE_PREFIXES` guard. Two instances still shipped in
`templates/research/{README.md,methods/INDEX.md}` and were fixed in the v2
bookkeeping pass: exclusion lists don't catch this, because a many-to-one collapse
leaves a *valid* path behind. It needs a duplicate-path-per-line detector.

## Metrics

- Conventions: 13 → 7 mandatory + 2 optional
- Scaffolded directories: 15 → 8
- CLAUDE.md template sections: 14 → 7
- Evidence index size on the pilot corpus: 330 KB → 33 KB
- Pilot inputs audited: 151 evidence docs, 43 decision records, 70 learnings, 60 source docs
- v1 records merged into topic files: 141 → 28
- Commits: `dfacab5` (the consolidation), `ce022d8` (case study), `ed591a0` (lessons)
- Merged to `main`: 2026-08-04, fast-forward from `v2-consolidation`
