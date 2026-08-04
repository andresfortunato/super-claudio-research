# World Bank API — usage guide

> **This is a template / worked example.** Replace with your project's
> actual `<source>_<thing>.md` files, or delete once real sources are
> documented. The indicator value below is illustrative — re-fetch
> before relying on it.

**Status**: verified 2026-05-06 against the World Bank Open Data API
v2. No registration or API key required for the public indicators.
Replaces nothing (initial doc).

**Authoritative spec**: <https://datahelpdesk.worldbank.org/knowledgebase/topics/125589>

**Companion docs in `research/sources/`**:

- `INDEX.md` — top-level index
- (add WB-specific deep-dives here as they accumulate — e.g.
  `world_bank_wdi_indicators.md` for indicator-code cheatsheets)

---

## Headline anchor (illustrative)

| Indicator | Country | Year | Value |
|---|---|---|---|
| `NY.GDP.PCAP.CD` (GDP per capita, current US$) | `VNM` (Vietnam) | 2022 | ≈ 4,164 |

This triple — indicator code + ISO3 + year — is the smoke test future
sessions re-run to confirm this doc still describes the live API
correctly. A stale `Status:` date paired with a drifted value is the
signal that the doc needs a refresh. See "Verifiable freshness
anchors" in `docs/audience-and-philosophy.md`.

The anchor is best chosen as a stable historical value (a 2010s GDP
per capita figure won't be revised much) rather than a fresh
estimate (2024 figures might be).

---

## 1. Endpoints

Base URL: `https://api.worldbank.org/v2`

The two endpoint families you'll actually use:

| Family | Path | Purpose |
|---|---|---|
| **Indicator data** | `/country/{ISO}/indicator/{indicator}` | Time series for one (or many) ISO country code(s) on one indicator. |
| **Indicator metadata** | `/indicator/{indicator}` | Name, description, source, unit. |

Plus: `/country`, `/source`, `/topic`, `/region`, `/incomeLevel`
endpoints for browsing the catalog. Add `?format=json` to almost
every request — the default is XML.

**No auth header required** for public indicators. Rate limits are
unpublished but generous; back off on `429` if it happens.

---

## 2. Query shape

The path takes one or many semicolon-joined ISO3 codes and one or
many semicolon-joined indicators:

```
GET /v2/country/{ISO}/indicator/{indicator}?format=json&date=2010:2023&per_page=200
```

| Param | Purpose | Default |
|---|---|---|
| `format` | `json` (almost always) or `xml` | `xml` |
| `date` | Year (`2022`) or range (`2010:2023`) or month (`2024M03`) | all years |
| `per_page` | Page size; max ~32,500 | 50 (paginated!) |
| `page` | 1-indexed page number | 1 |
| `mrv` | "Most recent value" — request the last N obs | — |
| `gapfill` | `Y` to forward-fill missing years from prior obs | `N` |

**Worked example:**

```
GET https://api.worldbank.org/v2/country/VNM/indicator/NY.GDP.PCAP.CD?format=json&date=2000:2023&per_page=200
```

Returns ~24 annual observations for Vietnam in a two-element JSON
array: `[meta, data]`. The first element is metadata
(`page`, `pages`, `per_page`, `total`); the second is the array of
observations.

### Multi-country, multi-indicator shortcut

Join with semicolons. Use `all` for "every country":

```
/v2/country/VNM;THA;PHL/indicator/NY.GDP.PCAP.CD?format=json
/v2/country/all/indicator/NY.GDP.PCAP.CD;SP.POP.TOTL?format=json&source=2
```

The `source=` filter pins indicators to a specific source database
(e.g. `2` = WDI) — useful when an indicator code exists in multiple
sources with different vintages.

---

## 3. Parsing / decoding

The response is a length-2 array: `[meta_dict, list_of_obs]`. The
smallest decoder pattern (Python; mirror in R as needed):

```python
import requests, pandas as pd

URL = ('https://api.worldbank.org/v2/country/VNM/indicator/'
       'NY.GDP.PCAP.CD?format=json&date=2000:2023&per_page=200')
resp = requests.get(URL, timeout=60)
meta, obs = resp.json()

rows = [
    {
        'iso3':       o['countryiso3code'],
        'indicator':  o['indicator']['id'],
        'year':       int(o['date']),
        'value':      o['value'],   # may be None for missing obs
    }
    for o in obs
]
df = pd.DataFrame(rows).dropna(subset=['value'])
df['value'] = pd.to_numeric(df['value'])
```

**`wbgapi` wrapper.** The `wbgapi` Python package (and similar R
packages — `wbstats`, `WDI`) wraps the same API and is usually less
boilerplate than raw `requests`. Use the raw API only when `wbgapi`
doesn't expose the parameter you need (e.g. `gapfill`, `source`
pinning).

---

## 4. Pitfalls

- **Pagination defaults to 50 rows** — easy to silently truncate a
  long series. Always pass `per_page=200` (or higher) for
  full-history pulls, and check `meta['total']` against the row
  count you got back.
- **Missing observations come back as `value: null`**, not omitted
  rows. Filter / impute deliberately; don't assume the response
  array is dense.
- **The same indicator code can appear in multiple sources** with
  different vintages or country coverage. WDI (`source=2`) is the
  default for most macro indicators; if a value disagrees with
  another reference, check whether you accidentally pulled from an
  REO database (`source=11`, `source=15`) instead.
- **ISO3 vs the WB's internal codes.** Most WB endpoints accept
  ISO3 (`VNM`, `KHM`) but a handful of legacy aggregates use WB
  codes (`EAS` = East Asia & Pacific, `LMC` = Lower Middle Income).
  The `/v2/country` endpoint enumerates them.
- **Aggregates are mixed in with country lists.** `/country/all`
  returns ~265 entries; ~217 are individual countries and the rest
  are aggregates (income groups, regions). Filter on
  `region.id != 'NA'` or use the explicit ISO3 list.
- **Year-only dates ignore mid-year revisions.** A figure tagged
  `2022` may have been published in late 2023 and revised in 2024;
  the API serves the latest. Pin to a specific WB Statistical
  Performance Indicators (SPI) vintage if reproducibility against a
  publication date matters.

---

## 5. Reference files in the repo

- `research/sources/INDEX.md` — top-level index
- `research/sources/EXAMPLE_world_bank_api.md` — this file (template;
  delete or replace with the project's real WB doc)
