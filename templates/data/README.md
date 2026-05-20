# data/

Local cached data for this project. **Large binaries are gitignored**;
this README is the committed inventory of what's expected to be here
and where each file came from.

This file documents *what's on disk*. For *how to fetch more*, see
`data_sources/INDEX.md`. For *the methodology that decided what to
fetch*, see `decisions/`. For *the code that does the fetching*, see
`<project>_utils.py`.

Full protocol: `.claude/conventions/data-access.md` (read on demand).

---

## Inventory

(One section per source family. Each entry: filename / path +
upstream source + which wrapper produced it. `manual download` is
fine for one-shot bulk pulls; `live-queried` is fine for sources that
don't cache.)

### Atlas of Economic Complexity (PostgreSQL — `ATLAS_DB_*`)

Live-queried via `atlas_query()` in `<project>_utils.py` — no local
cache. Schema reference: `data_sources/atlas_postgres.md`.

### World Bank (public, no auth)

- *(none cached yet — `wb_fetch()` pulls on demand)*

Reference: `data_sources/world_bank_wbgapi.md` (or
`world_bank_data360_api.md`).

### IMF / BIS (SDMX APIs, no auth)

- *(none cached yet — `imf_sdmx_fetch()` and `bis_sdmx_fetch()` pull
  on demand)*

References: `data_sources/imf_sdmx_api.md`,
`data_sources/bis_sdmx_api.md`.

### Manual / bulk downloads

- `data/EXAMPLE_pwt110.xlsx` — Penn World Tables 11.0 (manual
  download from <https://www.rug.nl/ggdc/productivity/pwt/>; refresh
  annually). *Delete this line and add real entries.*

---

## Rules

- `data/` is **gitignored except this README** (and small
  hand-curated files like ISO code lists, peer-country tables, etc.
  — list those above).
- Files >50MB stay out of the repo regardless of `.gitignore` rules;
  document the source URL above so a fresh clone can re-fetch.
- **Live-queried** sources get a `live-queried` entry, not silence.
  The reader needs to know that source is intentional and where to
  find the wrapper.
- **When a wrapper changes its cache path**, update this README in
  the same commit. Drift between code and inventory is silent rot.
