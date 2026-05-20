# Data Access — Protocol

**Trigger**: Whenever the project needs to *run code that touches an
external data source* — a Postgres database, an authed API, a public
API with rate limits — or when secrets, env vars, or wrapper
functions enter the picture. This convention defines the **runtime
layer** of the project's data pipeline: env-var pattern, utility
module shape, the bridge between code and reference docs, and the
on-disk cache.

The sibling convention `.claude/conventions/data-sources.md` covers
the **documentation layer** (the `data_sources/<source>_<thing>.md`
reference docs). The two are designed to be read together: this one
prescribes the code, that one prescribes the docs, and the INDEX
table wires them.

## Boundary with neighbors

- **`data_sources/`** — *reference docs* (how the API works,
  pitfalls, headline anchors). Markdown, committed, hand-written.
- **`<project>_utils.py`** (this convention) — *runtime wrappers*
  that front each documented source. Python, committed.
- **`.env`** — *secrets* for the local machine. Gitignored.
- **`.env.example`** — *the list of expected env-var names* with
  placeholder values. Committed.
- **`data/`** — *local cache* of fetched data. Large binaries
  gitignored; `data/README.md` is the inventory of what's on disk.

A documented source without a wrapper is fine (manual download,
one-off pull). A wrapper without a documented source is a smell
— wrap means "callers will use it again," and re-use needs docs.

## The pieces

### 1. Secrets — `.env` + `.env.example`

- `.env` lives at project root and is **gitignored** (the framework
  block adds this automatically; verify with `git check-ignore .env`).
- `.env.example` lives beside it and **is committed**. It enumerates
  every env-var name the project reads, grouped by source, with
  placeholder values and a one-line comment per group explaining
  where to obtain credentials.
- **One prefix per source family**: `ATLAS_DB_HOST`, `ATLAS_DB_USER`,
  `ATLAS_DB_PASSWORD`, … (not `DB_HOST` — too generic if a second
  database lands). The prefix is also the data-sources doc's filename
  stem when possible (`atlas_postgres.md` ↔ `ATLAS_*`).
- Public APIs that need no credentials get no env vars. Don't invent
  `WB_KEY=` for sources that don't have keys.
- **`.env.example` must enumerate the same names the utility module
  reads.** Drift between the two is a configuration bug; treat it as
  a build break, not a style nit.

### 2. The utility module — `<project>_utils.py`

A single Python file at project root that fronts every documented
external source. Importable as `from <project>_utils import …` from
notebooks via a `sys.path` insert. R/Stata projects substitute
analogously (`<project>_utils.R` with `.Renviron`) — the convention's
shape transfers; the framework's worked example is Python.

**Required shape:**

```python
# <project>_utils.py
from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / '.env')   # once, at import time

# ── Atlas of Economic Complexity (PostgreSQL) ────────────────────
ATLAS_DB_CONFIG = dict(
    host=os.environ['ATLAS_DB_HOST'],          # required → KeyError if missing
    dbname=os.environ['ATLAS_DB_NAME'],
    user=os.environ['ATLAS_DB_USER'],
    password=os.environ['ATLAS_DB_PASSWORD'],
    port=int(os.environ.get('ATLAS_DB_PORT', 5432)),   # optional → default
)

def atlas_query(sql, params=None):
    """Run a parameterized SQL query against Atlas; return a DataFrame.

    Full guide: data_sources/atlas_postgres.md
    """
    import psycopg2, pandas as pd
    with psycopg2.connect(**ATLAS_DB_CONFIG) as conn:
        return pd.read_sql(sql, conn, params=params)
```

**Rules:**

- **One wrapper per source-and-purpose.** `atlas_query`, `wb_fetch`,
  `imf_sdmx_fetch`, `bis_sdmx_fetch` — named so the source family is
  obvious from the function name.
- **Required env vars use `os.environ['X']`, not `.get()`.** A missing
  required var should crash loudly at import time, not silently
  default to `None` and surface as a confusing error two hours later.
  Optional vars use `os.environ.get('X', default)`.
- **Each wrapper's docstring back-links to its data-sources doc** with
  a one-liner: `Full guide: data_sources/<source>_<thing>.md`. This
  is how a future session navigates from a function it found in a
  notebook to the API mechanics that documented it.
- **Wrappers return long-format DataFrames** by default (one row per
  observation, columns like `iso`, `year`, `value`, `indicator`).
  Wide variants are fine as separate functions (`wb_fetch_wide`).
- **No business logic in wrappers.** A wrapper fetches and decodes;
  analysis lives in notebooks or methods. If a transformation is
  reused across notebooks, it goes in a *separate* utility section
  (e.g., `period_means`), not bolted onto a fetch function.
- **Edit, don't accumulate.** When an API changes, update the wrapper
  in place and bump the doc's `Status:` line. No `_v2` suffixes.

### 3. The INDEX bridge — `data_sources/INDEX.md`

The "Helper functions" table in `data_sources/INDEX.md` is
**required** (it is `(Optional)` in older copies of the data-sources
convention; this convention promotes it to load-bearing). Every
wrapper in `<project>_utils.py` has one row:

| Helper | Source |
|---|---|
| `atlas_query(sql, params)` | Atlas PostgreSQL DB — `data_sources/atlas_postgres.md` |
| `wb_fetch(indicator, ...)` | World Bank wbgapi — `data_sources/world_bank_wbgapi.md` |
| `imf_sdmx_fetch(dataflow, key)` | IMF SDMX 3.0 — `data_sources/imf_sdmx_api.md` |

This is the bidirectional bridge: a researcher reading a notebook
finds `imf_sdmx_fetch(...)`, looks it up in the INDEX, and lands on
the reference doc — without needing to read the utility module's
source.

### 4. The on-disk cache — `data/` + `data/README.md`

`data/` holds files that landed on disk: cached pulls, manual
downloads, raw CSVs / Excel files from upstream portals. The
framework's `.gitignore` block keeps large binaries out of the repo;
`data/README.md` is committed and lists *what's expected to be
there*, grouped by source family, with the wrapper that produces
each entry (or `manual download` for one-off pulls). See
`templates/data/README.md` for the shape.

**Rule:** when a wrapper changes its cache path or filename, update
`data/README.md` in the same commit. Drift between code and the
inventory is silent rot.

### 5. Upstream specs co-located with docs

If the upstream API publishes an OpenAPI / Swagger / JSON-schema
spec, commit it next to its reference doc:

```
data_sources/
├── imf_sdmx_api.md
├── imf_sdmx_openapi_3_0.yaml      # ← upstream spec, committed
├── bis_sdmx_api.md
└── bis_sdmx_openapi_2_1.yaml
```

A future session can grep the YAML for endpoint definitions when the
markdown is silent. Don't paraphrase the spec into the doc — link to
the file.

## Naming

- Utility module: `<project>_utils.py` (snake_case project slug). At
  project root.
- Env vars: `SCREAMING_SNAKE_CASE`, source-prefixed
  (`ATLAS_DB_*`, `IMF_*`, `FAOSTAT_API_KEY`).
- Wrapper functions: `snake_case`, source-prefixed verbs
  (`atlas_query`, `wb_fetch`, `imf_sdmx_fetch`, `bis_sdmx_fetch`).

## Discipline rules

- **Never commit secrets.** Verify `.env` is gitignored on every new
  clone. `.env.example` is committed; `.env` is not.
- **`.env.example` is the contract.** Every env var the utility
  module reads must appear in `.env.example` with a placeholder. Vars
  in `.env.example` not read by any code are dormant (acceptable
  short-term; flag for cleanup).
- **No silent fallbacks for required credentials.** If `ATLAS_DB_HOST`
  is missing, the import should `KeyError`. A wrapper that returns
  `None` because credentials were missing is a debugging trap.
- **Don't bypass the utility module from notebooks.** If a notebook
  needs a slightly-different fetch, extend the wrapper (or add a new
  one) rather than inlining `psycopg2.connect(...)` in the cell.
  Inline DB code in notebooks defeats the doc bridge.
- **Wrapper docstrings always point at the reference doc.** One-line
  back-link minimum.

## Adding a new source — recipe

1. **Document the source** in `data_sources/<source>_<thing>.md`
   following `.claude/conventions/data-sources.md`. Record a
   headline anchor.
2. **Add env vars** to `.env.example` (committed, placeholder values)
   and `.env` (local, real values). Use the source-prefixed naming.
3. **Add a wrapper** to `<project>_utils.py`. Docstring back-links to
   the reference doc.
4. **Add a row** to the "Helper functions" table in
   `data_sources/INDEX.md`.
5. **If the wrapper caches to disk**, add an entry to
   `data/README.md` naming the cache path and the wrapper that
   produces it.

> **Transplanting from another r2p project?** Use
> `/r2p-migrate-source --from <donor-path> --source <slug>` instead
> of writing from scratch — it lifts the ref doc, wrapper, env
> vars, INDEX row, and `data/README.md` entry in one
> proposal-then-apply cycle.

## What this convention does NOT cover

- **Pipeline orchestration** (Airflow, Dagster, dbt, Prefect). If a
  project grows past ~20 wrappers or develops inter-source
  dependencies, consider these. The convention's shape is
  intentionally orchestration-free — notebooks are the orchestrator.
- **Auto-anchor verification** — the sibling data-sources convention
  defers this to `/verify`.
- **R / Stata utility modules.** The pattern transfers (substitute
  `.Renviron` for `.env`, `<project>_utils.R` for the Python module),
  but the framework's validated pilot is Python. R/Stata projects
  should adopt the *shape* and document any deviations as
  `project_conventions/`.
- **Wrapper unit tests.** Live-API tests are flaky; mocking them
  defeats the point. The "headline anchor" in the reference doc is
  the smoke test — call the wrapper once, confirm the value, paste
  it in.
