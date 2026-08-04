# v1 → v2 migration

v2 is a consolidation, not a feature release. It came out of auditing the first
r2p engagement to run six months at full intensity (Córdoba: 151 evidence docs,
43 decision records, 70 learnings, 60 source docs, 26 root directories). Every
change below is a response to something that measurably broke there.

## What changed

| v1 | v2 | Why |
|---|---|---|
| `evidence/` | `research/evidence/` + **`research/claims.md`** | An append-only corpus at 151 docs cannot be read. It needs a curated layer above it. |
| `decisions/` + `methods/` + `learnings/` | **`research/methods/<topic>.md`** | Three directories split by *genre*; research arrives by *topic*, and one topic needs all three. |
| `data_sources/` + `<p>_utils.py` docs | `research/sources/<source>.md` | Two conventions and two CLAUDE.md sections for one object. |
| `learnings/index.yaml` + hook | `triggers:` frontmatter + hook | A two-file write, and a forgotten index row made a learning invisible. |
| `wiki/` + registry, scaffolded | `research/wiki/`, `r2p init --with-wiki` | Zero pages and zero scrapes in six months, at the cost of two CLAUDE.md sections per session. |
| 15 scaffolded dirs | 8 | No orientation at 26 root directories. |
| 13 conventions | 7 (+2 optional) | Half of them were read together and restated each other's boundaries. |
| `slides/`, `internal_docs/`, `literature/`, `archive/`, `brainstorms/`, `project_conventions/` | folded into `deliverables/`, `reference/`, `plan/`, `.claude/conventions/project/` | — |

## The four defects v2 fixes in evidence

Recorded here because they will recur in any project that writes a lot of it.

1. **Verdict/measurement fusion.** v1 asked for `**claim** — number —
   implication` in one bullet, so authors wrote verdicts: 338 verdict words
   ("confirms", "REFUTED", "VERDICT") across 93 of 151 docs. *Measurements do
   not contradict each other; verdicts do.* v2 splits `## Measured` from
   `## Reading` and lints the boundary.
2. **Scope as prose.** Unit, period and weighting lived in paragraphs, so a
   province number and a metro number on the same topic read as a conflict. v2
   puts `unit` / `geography` / `period` in frontmatter, which makes "these
   disagree" a mechanical test.
3. **Status as a prose banner.** 25 docs carried `⚠ … RETIRED …` text prepended
   to their index title. Nothing was filterable, so retired legs kept getting
   cited — and in two cases a doc retired a number in one finding and kept
   asserting it in another. v2 uses `status: live | revised | retired`.
4. **Nothing curated.** The index reached **330 KB** with a median title of
   1,554 chars and a longest of 10,410. Every synthesis session rebuilt a
   distillation from scratch, differently. v2 caps the index headline at 120
   chars (330 KB → 33 KB) and adds `claims.md`.

**The strongest evidence for (4):** the pilot had *already built* the claims
layer by hand — `mapa_evidencia.md` (1,568 lines), `retracciones.md` (40 live
retractions), `flags_narrativa_vs_evidencia.md` (128 flags) — inside a single
plan folder, marked "GENERADO. No editar a mano". Its own header says why:
*"para que ninguna sesión de redacción tenga que volver a abrir
`evidence/INDEX.md` (317 KB de abstracts completos)"*. The mechanism was
missing, so a researcher invented it in the wrong place and it died with the
plan.

## Calibration: every v1 size range was wrong

v1 stated ranges that reality exceeded by 3–10×. v2 restates them and, more
importantly, changes their *form*.

| Convention | v1 said | Actual | v2 says |
|---|---|---|--:|
| decision records | "5–15; >30 means over-recording" | 43 | (merged into methods) |
| methods | ">10 means refocus the engagement" | 28 after merge | 20–35 is normal |
| data sources | "flat, ~5–15 scans in seconds" | 60 | 40–70; group the INDEX past 20 |
| evidence | nothing stated | 151 | no cap; `claims.md` mandatory past 40 |

**The general rule, learned inside the migration itself.** The first tier rule
for which docs to rewrite was `cited ≥3×`. On a corpus where citation counts run
80–180 it admitted 145 of 151. **Size-dependent rules must be expressed as ranks
or shares, never absolute counts** — an absolute threshold that is right at 20
docs is all-or-nothing at 150.

## Running the migration

`templates/migration/` ships the scripts used on the pilot. They are written to
be read and adapted, not run blind.

```bash
python3 templates/migration/audit.py                    # inventory; writes mapping/*.csv
# author mapping/{decisions_map,learnings_map}.csv by hand — routing is a judgement call
bash    templates/migration/01_layout.sh                # git mv into the v2 layout
python3 templates/migration/02_repath.py --check        # ALWAYS dry-run first
python3 templates/migration/02_repath.py
python3 templates/migration/03_linkcheck.py             # verification gate
# author mapping/headlines.tsv and mapping/scope.tsv — 2 values per evidence doc
python3 templates/migration/04_evidence_frontmatter.py --check
python3 templates/migration/04_evidence_frontmatter.py
python3 templates/migration/05_methods_merge.py
bash    .claude/hooks/lint-research.sh
```

### Four traps in the migration itself

1. **The repath rewrites the documentation *about* the repath.** `02_repath.py`
   will happily turn `methods/<slug>/rule.md` into `research/methods/<slug>/rule.md`
   inside the v1-vs-v2 comparison table that exists to preserve the old path.
   Exclude `.claude/conventions/` and your migration plan, or fix by hand after.
2. **Measure a baseline before claiming you broke nothing.** `03_linkcheck.py`
   reported 238 dangling references after the migration, which looks alarming
   until you run it against a `git worktree` of the pre-migration commit and get
   **405**. Most dangling links predate any migration.
3. **Do not infer scope keys.** Heuristics tagged a 24-province panel as
   `metro | 1960–2026` (the year regex swept every number in the first 6 KB). A
   confidently wrong scope key is *worse than a blank one*: it manufactures the
   exact false contradictions the field exists to prevent. Author `unit` and
   `period`; let the fallback be `unknown`.
4. **Migration scripts must be idempotent by rebuild, not by skip.**
   `04_evidence_frontmatter.py` first *skipped* docs that already had
   frontmatter, which silently froze a bad heuristic run in place. Strip and
   rebuild. The same class of bug hit the installer: `mkdir research/evidence/`
   before mirroring made the mirror skip it as "exists" and shipped an empty
   tree.

## Adopting v2 on a new project

`r2p init` scaffolds it. Nothing else to do. Add `--with-wiki` only if the
project's primary input is a *stream* (news, filings, bulletins) rather than
datasets and papers.

## The full audit

`docs/v2-case-study-cordoba.md` is the write-up of the engagement this
version came out of: the measurements, the four evidence defects, the five genres
hiding in one `learnings/` directory, and six lessons from running the migration
itself.

## Field notes

`docs/field-notes/` holds seven lessons recovered from the pilot's `learnings/`
that were never about the pilot at all — they were bugs in r2p: evidence-id
collisions across parallel worktrees (twice), parallel fan-out hygiene, two
agents sharing one git index, digest retention varying with heading style, and
gap-checks that miss unchecked branches. They had been sitting in a project repo
where no future project could see them. **When a learning is about the
framework, it belongs here.**
