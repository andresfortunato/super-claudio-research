# Data-access mechanism — design rationale

## The problem this solves

The sibling `data-sources` convention captures *how to access* each
external source — in markdown. It deliberately does not say anything
about the *code* that does the accessing: where credentials live,
how the wrapper functions are organized, where cached data lands. It
explicitly defers those questions ("No project-utility-module rules
in v1").

That deferral was the right call at v1 — there was no validated
pattern to ship. But projects do not have the luxury of deferring:
every research project that touches an authed Postgres DB or a
public API has to make those decisions in the first session, and
without scaffolding the decisions diverge wildly:

- One project loads `.env` in every notebook. Another puts secrets
  in a config file checked into git. A third reads `os.environ`
  with silent string-default fallbacks (and silently returns empty
  DataFrames on every run after the keys expire).
- One project bundles fetch + transform + plot into 200-line
  notebook cells. Another factors fetches into a utility module
  but leaves SQL inline in five different notebooks.
- One project tracks `data/` files in git ("just this once"); the
  repo balloons past 500MB.

The cambodia-growth pilot converged on a clean three-layer pattern
(secrets → wrappers → cache, plus an INDEX bridge to the
data-sources reference docs). This convention promotes that pattern
to framework-level so future projects start there instead of
re-deriving it.

## Why three layers, not one

Considered and rejected: bundle everything into the data-sources
convention. Pros: one mental model, one folder. Cons: data-sources
is *documentation discipline* (markdown shape, headline anchors,
INDEX); this is *code discipline* (env-var pattern, function
signatures, on-disk inventory). They share a folder boundary but
not a mental model. A researcher reading the data-sources convention
to add an API reference doc shouldn't have to scroll past sections
on `psycopg2` patterns.

Split keeps each convention to its concern. The two cross-link via
the `data_sources/INDEX.md` "Helper functions" table — that table is
the only place where the two layers explicitly touch.

## Why `.env` + `.env.example`, not config files

Considered and rejected: a committed `config.yaml` with secret
substitution (`password: ${ATLAS_DB_PASSWORD}`). Common in larger
projects, but it adds parsing infrastructure and a second file
researchers can confuse with the real config. `.env` is
already the dominant pattern in Python research stacks, `python-dotenv`
ships in every reasonable Python install, and editors highlight
`.env*` natively.

The `.env.example` half is the load-bearing piece. Without it, a
fresh clone of a project doesn't know which env vars the utility
module expects until import-time `KeyError`s say so. With it, a new
researcher does `cp .env.example .env`, fills in the placeholders,
and is unblocked.

The rule "every var the utility module reads must appear in
`.env.example`" is the convention's only enforced invariant — drift
breaks new-environment setup silently.

## Why one utility module, not a package

Considered and rejected: `<project>/data/atlas.py`,
`<project>/data/imf.py`, etc. — a Python package with one module per
source. Cleaner in theory; in practice, research projects rarely
grow past ~10 sources, and a flat `<project>_utils.py` is searchable
with one grep. The package layout adds `__init__.py` bureaucracy and
imports get longer (`from project.data.imf import imf_sdmx_fetch`
vs. `from project_utils import imf_sdmx_fetch`).

A package becomes the right answer past ~15 sources or when the
wrappers grow non-trivial helper hierarchies. The convention's
"What this does NOT cover" section flags this as the upgrade path.

## Why required (not silent-fallback) env vars

The temptation, every time, is to write:

```python
ATLAS_DB_HOST = os.environ.get('ATLAS_DB_HOST', 'localhost')
```

…on the theory that "I'll figure out missing config when I see
weird results." That's exactly the failure mode the convention
exists to prevent. A wrapper that runs with `localhost` when the
real Atlas DB is on a remote host either fails to connect (loud) or
connects to a different DB and returns subtly-wrong data (silent
and dangerous). Crash loudly at import time.

Optional vars (timeouts, default ports) are different — they have
sensible defaults and missing them isn't ambiguous. `.get()` with a
default is fine for those.

## Why the INDEX bridge is required, not optional

The data-sources convention shipped the "Helper functions" table as
optional. In the cambodia-growth pilot, that table turned out to be
the single most-used piece of the data-sources folder — researchers
opening a notebook to a strange function name jump to the INDEX,
find the row, and click through to the reference doc, all without
reading the utility module's source.

Without the table, a function name in a notebook is a dead end:
either grep the utility module (which is fine for the wrapper but
doesn't surface the doc) or grep `data_sources/` for the function
name (which mostly doesn't match because docs describe the API, not
the wrapper). Promoting the table to required keeps the bridge
live.

## Why `data/README.md` is the on-disk inventory

Considered and rejected: trust git history + `ls data/`. Works for
two files; breaks at five. The README answers "what is this CSV
for, and how do I regenerate it?" — questions that recur every
session a new analyst joins.

The README is short by design (target: 40 lines for a
medium-sized project; 100 lines is too many). It mirrors the
data-sources INDEX in spirit: a navigation document, not a
substitute for reading the data itself.

## What this does NOT do

- **No pipeline orchestration.** Notebooks are the orchestrator. A
  notebook fetches via wrappers, transforms in memory, and emits
  PNGs / CSVs. There is no DAG. This breaks at ~20 sources or with
  long-running fetches; the convention's escape hatch is to migrate
  to dbt / Dagster / Prefect at that point.
- **No automated `.env.example` lint.** A simple regex over
  `<project>_utils.py` could check that every `os.environ['X']` has
  a matching line in `.env.example`. Useful, but trivially failable
  by hand (researchers feel the pain on the next clone). Ship a
  `data-access-lint` skill in v1.x if drift becomes a recurring
  problem.
- **No wrapper unit tests.** Live-API tests flake; mocked tests miss
  upstream changes. The headline anchor in each data-sources doc is
  the smoke test — and `/verify` covers per-artifact checks.
- **No R / Stata template.** The pattern transfers (`.Renviron` +
  `<project>_utils.R`), but the framework's validated pilot is
  Python. R-first projects adopt the *shape* and document
  deviations.

## Tradeoffs accepted

- **`.env.example` can drift from the utility module.** No lint
  enforces parity. A researcher who adds a new env var without
  updating `.env.example` breaks the next clone silently. The
  convention's discipline rule names this; only practice enforces
  it.
- **Flat utility module gets unwieldy past ~15 sources.** Python
  files of 1000+ lines are searchable but harder to navigate. The
  convention names the migration path (split into a package) but
  doesn't prescribe when.
- **Notebook `sys.path` insert is ugly.** Notebooks live in
  `notebooks/`; the utility module lives in `..`. Every notebook
  starts with `sys.path.insert(0, '..')`. A `pyproject.toml`
  editable install fixes this cleanly but adds bureaucracy the
  convention chose not to require.
- **Wrapper docstring back-links rot.** If a reference doc is
  renamed, every wrapper docstring that points to it goes stale.
  `grep -r 'data_sources/<old-name>' .` catches it; no lint does.

## Provenance

The cambodia-growth pilot evolved this pattern over ~6 months of
work touching Atlas Postgres, World Bank wbgapi, IMF SDMX 3.0, BIS
SDMX 2.1, FDI bilateral ledgers, PWT, and CEPII. The early
sessions had each notebook re-deriving connection strings;
mid-project the pattern crystallized into `cambodia_utils.py` +
`.env`; the INDEX table appeared last, as the bridge between the
already-written reference docs and the already-written wrappers.

The convention captures the crystallized form, so the next project
starts where cambodia-growth ended up instead of repeating the
arc.

## Extension points

- **`data-access-lint` skill** — check `.env.example` ↔ utility
  module parity; check every wrapper docstring resolves to a real
  `data_sources/` file; check every wrapper has a row in the INDEX.
  Defer to v1.x; trip-wire on first drift report from pilot.
- **`.env.example` generator** — `r2p data-access scaffold` could
  read `data_sources/*.md` files looking for env-var mentions
  ("documented env vars: `ATLAS_DB_*`") and seed `.env.example`
  accordingly. Speculative; would need an enforced format for
  env-var declarations in reference docs.
- **R-pilot adoption** — once an R-based research project adopts
  the framework, validate the `.Renviron` + `<project>_utils.R`
  shape and add it as a parallel example in the convention. Today
  the convention names the substitution; it does not validate it.
